#!/usr/bin/env python3
"""
Streaming ML Platform Data Generator

Generates synthetic data for a streaming platform with ML features:
- User behavior and engagement data
- Content metadata and performance metrics
- A/B testing experiments
- Recommendation system data
- Feature engineering for ML models
- Revenue and subscription data
"""

import csv
import random
import json
import yaml
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Tuple
import hashlib
import math
from faker import Faker

class StreamingMLGenerator:
    def __init__(self, config_path: str = "config.yaml"):
        """Initialize the Streaming ML data generator"""
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)

        self.seed = self.config['seed']
        random.seed(self.seed)
        self.fake = Faker("en_US")
        self.fake.seed_instance(self.seed)

        # Create output directory
        self.output_dir = Path(self.config['output_dir'])
        self.output_dir.mkdir(exist_ok=True)

        # Initialize data containers
        self.users = []
        self.creators = []
        self.content_items = []
        self.categories = []
        self.user_sessions = []
        self.events = []
        self.recommendations = []
        self.ab_test_assignments = []
        self.ml_features = []
        self.revenue_events = []

        # Date ranges
        self.platform_launch = datetime.strptime(
            self.config['date_ranges']['platform_launch'], '%Y-%m-%d'
        )
        self.data_start = datetime.strptime(
            self.config['date_ranges']['data_start'], '%Y-%m-%d'
        )
        self.data_end = datetime.strptime(
            self.config['date_ranges']['data_end'], '%Y-%m-%d'
        )

    def generate_all(self):
        """Generate all data"""
        print("Starting Streaming ML data generation...")

        # Generate static data
        print("Generating categories...")
        self.generate_categories()

        print("Generating creators...")
        self.generate_creators()

        print("Generating content items...")
        self.generate_content_items()

        print("Generating users...")
        self.generate_users()

        print("Assigning A/B tests...")
        self.generate_ab_test_assignments()

        # Generate time-series data
        print("Generating user sessions and events...")
        self.generate_user_sessions_and_events()

        print("Generating recommendations...")
        self.generate_recommendations()

        print("Generating ML features...")
        self.generate_ml_features()

        print("Generating revenue events...")
        self.generate_revenue_events()

        # Write all data
        print("Writing data files...")
        self.write_all_data()

        print("[OK] Data generation complete!")

    def generate_categories(self):
        """Generate content categories"""
        categories = [
            "Music", "Video", "Podcast", "Gaming", "News",
            "Education", "Sports", "Comedy", "Drama", "Documentary",
            "Technology", "Science", "Travel", "Food", "Fashion",
            "Fitness", "Art", "Business", "Politics", "Kids"
        ]

        for i, name in enumerate(categories[:self.config['counts']['categories']]):
            self.categories.append({
                'category_id': i + 1,
                'name': name,
                'description': f"Content related to {name.lower()}",
                'parent_category_id': None if i < 10 else random.randint(1, 10),
                'is_premium': random.random() < 0.3,
                'min_age': 0 if name == "Kids" else (18 if name in ["Politics", "Business"] else 13)
            })

    def generate_creators(self):
        """Generate content creators"""
        creator_types = ['individual', 'studio', 'network', 'brand', 'aggregator']

        for i in range(self.config['counts']['creators']):
            join_date = self.fake.date_between(
                self.platform_launch,
                self.data_start - timedelta(days=30)
            )

            # Popularity follows power law
            popularity_score = max(0.1, min(1.0, random.paretovariate(1.5) / 10))

            self.creators.append({
                'creator_id': i + 1,
                'username': self.fake.user_name() + str(random.randint(100, 999)),
                'display_name': self.fake.company() if random.random() < 0.3 else self.fake.name(),
                'creator_type': random.choice(creator_types),
                'join_date': join_date,
                'verified': popularity_score > 0.7,
                'follower_count': int(10 ** (popularity_score * 6)),  # 10 to 1M
                'total_content': random.randint(1, 500),
                'popularity_score': round(popularity_score, 3)
            })

    def generate_content_items(self):
        """Generate content metadata"""
        content_types = list(self.config['content_distribution']['categories'].keys())
        quality_tiers = list(self.config['content_distribution']['quality_tiers'].keys())

        for i in range(self.config['counts']['content_items']):
            content_type = random.choices(
                content_types,
                weights=list(self.config['content_distribution']['categories'].values())
            )[0]

            # Determine duration based on content type
            if content_type in ['music', 'news']:
                duration = random.randint(1, 5)
            elif content_type in ['podcast', 'video']:
                duration = random.randint(5, 60)
            else:
                duration = random.randint(10, 120)

            creator = random.choice(self.creators)
            category = random.choice(self.categories)

            publish_date = self.fake.date_between(
                self.platform_launch,
                self.data_end
            )

            # Views follow power law distribution
            age_days = (self.data_end.date() - publish_date).days + 1
            base_views = int(random.paretovariate(1.2) * 1000)
            total_views = base_views * min(age_days, 30)  # Growth over time

            self.content_items.append({
                'content_id': i + 1,
                'creator_id': creator['creator_id'],
                'category_id': category['category_id'],
                'title': self.fake.catch_phrase(),
                'description': self.fake.text(max_nb_chars=200),
                'content_type': content_type,
                'duration_seconds': duration * 60,
                'quality_tier': random.choices(
                    quality_tiers,
                    weights=list(self.config['content_distribution']['quality_tiers'].values())
                )[0],
                'publish_date': publish_date,
                'is_live': random.random() < 0.05,
                'is_premium': category['is_premium'] or random.random() < 0.2,
                'total_views': total_views,
                'avg_rating': round(random.uniform(3.0, 5.0), 1),
                'trending_score': round(random.random() ** 2, 3)  # Most content not trending
            })

    def generate_users(self):
        """Generate user profiles"""
        segments = list(self.config['user_distribution']['segments'].keys())
        segment_weights = list(self.config['user_distribution']['segments'].values())
        regions = list(self.config['user_distribution']['regions'].keys())
        region_weights = list(self.config['user_distribution']['regions'].values())
        devices = list(self.config['user_distribution']['devices'].keys())
        device_weights = list(self.config['user_distribution']['devices'].values())

        for i in range(self.config['counts']['users']):
            segment = random.choices(segments, weights=segment_weights)[0]

            # Registration date based on segment
            if segment == 'new':
                registration_date = self.fake.date_between(
                    self.data_start - timedelta(days=30),
                    self.data_end
                )
            else:
                registration_date = self.fake.date_between(
                    self.platform_launch,
                    self.data_start - timedelta(days=31)
                )

            # Subscription tier based on segment
            if segment == 'power_user':
                subscription_tier = random.choices(
                    ['free', 'basic', 'premium', 'enterprise'],
                    weights=[0.2, 0.3, 0.4, 0.1]
                )[0]
            elif segment == 'regular':
                subscription_tier = random.choices(
                    ['free', 'basic', 'premium', 'enterprise'],
                    weights=[0.5, 0.3, 0.18, 0.02]
                )[0]
            else:
                subscription_tier = random.choices(
                    ['free', 'basic', 'premium', 'enterprise'],
                    weights=[0.8, 0.15, 0.04, 0.01]
                )[0]

            self.users.append({
                'user_id': i + 1,
                'email': self.fake.email(),
                'username': self.fake.user_name() + str(random.randint(100, 9999)),
                'segment': segment,
                'registration_date': registration_date,
                'birth_year': random.randint(1950, 2010),
                'gender': random.choice(['M', 'F', 'O', None]),
                'region': random.choices(regions, weights=region_weights)[0],
                'primary_device': random.choices(devices, weights=device_weights)[0],
                'subscription_tier': subscription_tier,
                'subscription_start': registration_date if subscription_tier != 'free' else None,
                'lifetime_value': round(random.paretovariate(1.5) * 100, 2),
                'churn_risk_score': round(random.random(), 3)
            })

    def generate_ab_test_assignments(self):
        """Assign users to A/B tests"""
        for test_config in self.config['ab_testing']['active_tests']:
            test_name = test_config['name']
            variants = test_config['variants']
            split = test_config['split']

            # Assign each user to a variant
            for user in self.users:
                # Some users might not be in the test
                if random.random() < 0.8:  # 80% of users in each test
                    variant = random.choices(variants, weights=split)[0]

                    self.ab_test_assignments.append({
                        'test_id': test_name,
                        'user_id': user['user_id'],
                        'variant': variant,
                        'assignment_date': self.data_start,
                        'is_active': True
                    })

    def generate_user_sessions_and_events(self):
        """Generate user sessions and interaction events"""
        event_types = list(self.config['engagement_patterns']['interaction_weights'].keys())

        session_id = 1
        event_id = 1

        # Process each day
        current_date = self.data_start
        while current_date <= self.data_end:
            print(f"  Processing {current_date.date()}...")

            # Sample active users for this day
            daily_users = []
            for user in self.users:
                # Activity probability based on segment
                segment = user['segment']
                if segment == 'power_user':
                    active_prob = 0.95
                elif segment == 'regular':
                    active_prob = 0.7
                elif segment == 'casual':
                    active_prob = 0.3
                elif segment == 'new':
                    active_prob = 0.5
                else:  # dormant
                    active_prob = 0.1

                if random.random() < active_prob:
                    daily_users.append(user)

            # Generate sessions for active users
            for user in daily_users[:1000]:  # Limit for performance
                segment = user['segment']

                # Number of sessions per day
                if segment == 'power_user':
                    num_sessions = random.randint(3, 8)
                elif segment == 'regular':
                    num_sessions = random.randint(1, 3)
                else:
                    num_sessions = 1

                for _ in range(num_sessions):
                    # Session time based on hourly patterns
                    hour = random.choices(
                        [2, 8, 10, 13, 16, 20, 23],
                        weights=[0.05, 0.15, 0.10, 0.15, 0.20, 0.30, 0.05]
                    )[0]
                    session_start = current_date.replace(
                        hour=hour,
                        minute=random.randint(0, 59),
                        second=random.randint(0, 59)
                    )

                    # Session duration
                    duration_range = self.config['session_patterns']['duration'][segment]
                    session_duration = random.randint(*duration_range)
                    session_end = session_start + timedelta(minutes=session_duration)

                    # Device for this session
                    device = user['primary_device']
                    if random.random() < 0.2:  # 20% chance of different device
                        device = random.choice(['mobile', 'desktop', 'tablet', 'smart_tv'])

                    # Create session
                    self.user_sessions.append({
                        'session_id': session_id,
                        'user_id': user['user_id'],
                        'start_time': session_start,
                        'end_time': session_end,
                        'device_type': device,
                        'ip_address': self.fake.ipv4(),
                        'user_agent': f"{device}_{self.fake.user_agent()}",
                        'page_views': random.randint(
                            *self.config['session_patterns']['depth'][segment]
                        ),
                        'bounce': random.random() < (0.1 if segment == 'power_user' else 0.3)
                    })

                    # Generate events for this session
                    num_events = random.randint(
                        *self.config['counts']['events_per_user_per_day']
                    )

                    for _ in range(min(num_events, 20)):  # Cap at 20 events per session
                        # Random content interaction
                        content = random.choice(self.content_items)

                        # Event type based on engagement pattern
                        if segment == 'power_user':
                            event_weights = [1.0, 0.8, 0.4, 0.6, 0.3, 0.1]
                        else:
                            event_weights = [1.0, 0.3, 0.1, 0.1, 0.05, 0.02]

                        event_type = random.choices(event_types, weights=event_weights)[0]

                        # Event time within session
                        event_offset = random.randint(0, session_duration * 60)
                        event_time = session_start + timedelta(seconds=event_offset)

                        # Watch time for view events
                        if event_type == 'view':
                            completion_rate = self.config['engagement_patterns']['completion_rates'][segment]
                            watch_time = int(content['duration_seconds'] * random.uniform(0, completion_rate))
                        else:
                            watch_time = None

                        self.events.append({
                            'event_id': event_id,
                            'session_id': session_id,
                            'user_id': user['user_id'],
                            'content_id': content['content_id'],
                            'event_type': event_type,
                            'event_time': event_time,
                            'watch_time_seconds': watch_time,
                            'quality_score': random.uniform(0.5, 1.0) if event_type == 'view' else None,
                            'is_offline': random.random() < 0.05
                        })
                        event_id += 1

                    session_id += 1

            current_date += timedelta(days=1)

    def generate_recommendations(self):
        """Generate recommendation system data"""
        algorithms = list(self.config['recommendation_system']['algorithms'].keys())
        algorithm_weights = list(self.config['recommendation_system']['algorithms'].values())
        ctr_rates = self.config['recommendation_system']['ctr_rates']

        rec_id = 1

        # Generate recommendations for a subset of events
        view_events = [e for e in self.events if e['event_type'] == 'view']

        for event in random.sample(view_events, min(len(view_events), 5000)):
            # Generate a recommendation list
            num_recommendations = random.randint(5, 20)
            algorithm = random.choices(algorithms, weights=algorithm_weights)[0]

            # Get candidate content items
            candidates = random.sample(self.content_items, min(50, len(self.content_items)))

            # Score and rank based on algorithm
            for i, content in enumerate(candidates[:num_recommendations]):
                # Calculate relevance score based on algorithm
                if algorithm == 'collaborative_filtering':
                    relevance_score = random.uniform(0.6, 0.95)
                elif algorithm == 'content_based':
                    relevance_score = random.uniform(0.5, 0.85)
                elif algorithm == 'hybrid':
                    relevance_score = random.uniform(0.65, 0.95)
                elif algorithm == 'popularity':
                    relevance_score = content['trending_score']
                else:  # random
                    relevance_score = random.uniform(0.1, 0.5)

                # Determine if clicked
                ctr = ctr_rates[algorithm]
                clicked = random.random() < (ctr * relevance_score)

                self.recommendations.append({
                    'recommendation_id': rec_id,
                    'user_id': event['user_id'],
                    'content_id': content['content_id'],
                    'algorithm': algorithm,
                    'relevance_score': round(relevance_score, 3),
                    'position': i + 1,
                    'timestamp': event['event_time'],
                    'clicked': clicked,
                    'click_timestamp': event['event_time'] + timedelta(seconds=random.randint(1, 30)) if clicked else None,
                    'context': json.dumps({
                        'time_of_day': event['event_time'].hour,
                        'day_of_week': event['event_time'].weekday(),
                        'device': 'mobile',  # Simplified
                        'previous_content_id': event['content_id']
                    })
                })
                rec_id += 1

    def generate_ml_features(self):
        """Generate ML feature vectors for users"""
        # Calculate features for each user
        for user in self.users[:1000]:  # Limit for performance
            user_events = [e for e in self.events if e['user_id'] == user['user_id']]
            user_sessions = [s for s in self.user_sessions if s['user_id'] == user['user_id']]

            if not user_events:
                continue

            # Calculate user features
            registration_days = (self.data_end.date() - user['registration_date']).days
            total_sessions = len(user_sessions)
            total_time_spent = sum(
                (s['end_time'] - s['start_time']).total_seconds()
                for s in user_sessions
            )
            avg_session_duration = total_time_spent / max(total_sessions, 1)

            # Content diversity
            unique_content = len(set(e['content_id'] for e in user_events))
            content_diversity = unique_content / max(len(user_events), 1)

            # Peak usage hour
            event_hours = [e['event_time'].hour for e in user_events]
            peak_hour = max(set(event_hours), key=event_hours.count) if event_hours else 12

            # Weekend vs weekday
            weekend_events = sum(1 for e in user_events if e['event_time'].weekday() >= 5)
            weekday_events = len(user_events) - weekend_events
            weekend_ratio = weekend_events / max(weekday_events, 1)

            # Engagement metrics
            like_count = sum(1 for e in user_events if e['event_type'] == 'like')
            share_count = sum(1 for e in user_events if e['event_type'] == 'share')
            engagement_rate = (like_count + share_count * 2) / max(len(user_events), 1)

            # Churn indicators
            last_event = max(user_events, key=lambda e: e['event_time'])
            days_since_last = (self.data_end - last_event['event_time']).days

            self.ml_features.append({
                'user_id': user['user_id'],
                'feature_date': self.data_end.date(),
                'age_days': registration_days,
                'total_sessions': total_sessions,
                'total_time_spent_hours': round(total_time_spent / 3600, 2),
                'avg_session_duration_min': round(avg_session_duration / 60, 2),
                'days_active_last_30': min(30, total_sessions),
                'content_diversity_score': round(content_diversity, 3),
                'peak_usage_hour': peak_hour,
                'weekend_vs_weekday_ratio': round(weekend_ratio, 3),
                'engagement_rate': round(engagement_rate, 3),
                'like_rate': round(like_count / max(len(user_events), 1), 3),
                'share_rate': round(share_count / max(len(user_events), 1), 3),
                'days_since_last_activity': days_since_last,
                'churn_probability': round(
                    min(0.9, days_since_last * 0.1 * (1 - engagement_rate)),
                    3
                ),
                'predicted_ltv': round(user['lifetime_value'] * (1 + engagement_rate), 2),
                'segment_prediction': user['segment'],
                'is_high_value': engagement_rate > 0.5 and total_sessions > 10
            })

    def generate_revenue_events(self):
        """Generate revenue and transaction events"""
        tier_prices = self.config['revenue_model']['tier_prices']

        revenue_id = 1

        for user in self.users:
            if user['subscription_tier'] != 'free':
                # Generate monthly subscription payments
                start_date = max(user['subscription_start'], self.data_start.date())
                current = datetime.combine(start_date, datetime.min.time())

                while current <= self.data_end:
                    self.revenue_events.append({
                        'revenue_id': revenue_id,
                        'user_id': user['user_id'],
                        'revenue_type': 'subscription',
                        'amount': tier_prices[user['subscription_tier']],
                        'currency': 'USD',
                        'transaction_date': current,
                        'payment_method': random.choice(['credit_card', 'paypal', 'apple_pay', 'google_pay']),
                        'status': 'completed' if random.random() > 0.05 else 'failed',
                        'metadata': json.dumps({
                            'tier': user['subscription_tier'],
                            'billing_cycle': 'monthly',
                            'auto_renew': True
                        })
                    })
                    revenue_id += 1

                    # Move to next month
                    if current.month == 12:
                        current = current.replace(year=current.year + 1, month=1)
                    else:
                        current = current.replace(month=current.month + 1)

            # Generate in-app purchases for some users
            if user['segment'] in ['power_user', 'regular'] and random.random() < 0.3:
                num_purchases = random.randint(1, 5)
                for _ in range(num_purchases):
                    purchase_date = self.fake.date_time_between(
                        self.data_start, self.data_end
                    )

                    purchase_type = random.choice(['virtual_currency', 'premium_content', 'features', 'gifts'])
                    if purchase_type == 'virtual_currency':
                        amount = random.choice([4.99, 9.99, 19.99, 49.99])
                    elif purchase_type == 'premium_content':
                        amount = random.choice([2.99, 4.99, 9.99])
                    else:
                        amount = random.choice([0.99, 1.99, 4.99])

                    self.revenue_events.append({
                        'revenue_id': revenue_id,
                        'user_id': user['user_id'],
                        'revenue_type': 'in_app_purchase',
                        'amount': amount,
                        'currency': 'USD',
                        'transaction_date': purchase_date,
                        'payment_method': random.choice(['credit_card', 'paypal', 'apple_pay', 'google_pay']),
                        'status': 'completed',
                        'metadata': json.dumps({
                            'purchase_type': purchase_type,
                            'item_id': random.randint(1000, 9999)
                        })
                    })
                    revenue_id += 1

    def write_all_data(self):
        """Write all generated data to CSV files"""
        # Categories
        self._write_csv('categories.csv', self.categories, [
            'category_id', 'name', 'description', 'parent_category_id',
            'is_premium', 'min_age'
        ])

        # Creators
        self._write_csv('creators.csv', self.creators, [
            'creator_id', 'username', 'display_name', 'creator_type',
            'join_date', 'verified', 'follower_count', 'total_content',
            'popularity_score'
        ])

        # Content Items
        self._write_csv('content_items.csv', self.content_items, [
            'content_id', 'creator_id', 'category_id', 'title', 'description',
            'content_type', 'duration_seconds', 'quality_tier', 'publish_date',
            'is_live', 'is_premium', 'total_views', 'avg_rating', 'trending_score'
        ])

        # Users
        self._write_csv('users.csv', self.users, [
            'user_id', 'email', 'username', 'segment', 'registration_date',
            'birth_year', 'gender', 'region', 'primary_device',
            'subscription_tier', 'subscription_start', 'lifetime_value',
            'churn_risk_score'
        ])

        # A/B Test Assignments
        self._write_csv('ab_test_assignments.csv', self.ab_test_assignments, [
            'test_id', 'user_id', 'variant', 'assignment_date', 'is_active'
        ])

        # User Sessions
        self._write_csv('user_sessions.csv', self.user_sessions, [
            'session_id', 'user_id', 'start_time', 'end_time', 'device_type',
            'ip_address', 'user_agent', 'page_views', 'bounce'
        ])

        # Events (limited for size)
        self._write_csv('events.csv', self.events[:50000], [  # Limit to 50k events
            'event_id', 'session_id', 'user_id', 'content_id', 'event_type',
            'event_time', 'watch_time_seconds', 'quality_score', 'is_offline'
        ])

        # Recommendations
        self._write_csv('recommendations.csv', self.recommendations, [
            'recommendation_id', 'user_id', 'content_id', 'algorithm',
            'relevance_score', 'position', 'timestamp', 'clicked',
            'click_timestamp', 'context'
        ])

        # ML Features
        self._write_csv('ml_features.csv', self.ml_features, [
            'user_id', 'feature_date', 'age_days', 'total_sessions',
            'total_time_spent_hours', 'avg_session_duration_min',
            'days_active_last_30', 'content_diversity_score', 'peak_usage_hour',
            'weekend_vs_weekday_ratio', 'engagement_rate', 'like_rate',
            'share_rate', 'days_since_last_activity', 'churn_probability',
            'predicted_ltv', 'segment_prediction', 'is_high_value'
        ])

        # Revenue Events
        self._write_csv('revenue_events.csv', self.revenue_events, [
            'revenue_id', 'user_id', 'revenue_type', 'amount', 'currency',
            'transaction_date', 'payment_method', 'status', 'metadata'
        ])

        # Write summary statistics
        self.write_summary()

    def _write_csv(self, filename: str, data: List[Dict], fieldnames: List[str]):
        """Helper to write CSV files"""
        filepath = self.output_dir / filename
        with open(filepath, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
            writer.writeheader()
            writer.writerows(data)
        print(f"  Wrote {len(data):,} records to {filename}")

    def write_summary(self):
        """Write generation summary"""
        summary = {
            'generation_timestamp': datetime.now().isoformat(),
            'seed': self.seed,
            'counts': {
                'users': len(self.users),
                'creators': len(self.creators),
                'content_items': len(self.content_items),
                'categories': len(self.categories),
                'sessions': len(self.user_sessions),
                'events': len(self.events),
                'recommendations': len(self.recommendations),
                'ml_features': len(self.ml_features),
                'revenue_events': len(self.revenue_events)
            },
            'date_range': {
                'start': str(self.data_start.date()),
                'end': str(self.data_end.date())
            },
            'user_segments': {
                segment: sum(1 for u in self.users if u['segment'] == segment)
                for segment in self.config['user_distribution']['segments'].keys()
            },
            'revenue_summary': {
                'total_subscription_revenue': sum(
                    r['amount'] for r in self.revenue_events
                    if r['revenue_type'] == 'subscription' and r['status'] == 'completed'
                ),
                'total_iap_revenue': sum(
                    r['amount'] for r in self.revenue_events
                    if r['revenue_type'] == 'in_app_purchase'
                ),
                'paying_users': len(set(
                    r['user_id'] for r in self.revenue_events
                    if r['status'] == 'completed'
                ))
            }
        }

        summary_path = self.output_dir / 'generation_summary.json'
        with open(summary_path, 'w') as f:
            json.dump(summary, f, indent=2, default=str)

        print("\n[OK] Generation Summary:")
        print(f"  Users: {summary['counts']['users']:,}")
        print(f"  Content Items: {summary['counts']['content_items']:,}")
        print(f"  Sessions: {summary['counts']['sessions']:,}")
        print(f"  Events: {summary['counts']['events']:,}")
        print(f"  ML Features: {summary['counts']['ml_features']:,}")
        print(f"  Total Revenue: ${summary['revenue_summary']['total_subscription_revenue'] + summary['revenue_summary']['total_iap_revenue']:,.2f}")

def main():
    parser = argparse.ArgumentParser(description='Generate Streaming ML platform data')
    parser.add_argument('--config', default='config.yaml', help='Path to config.yaml')
    args = parser.parse_args()

    generator = StreamingMLGenerator(config_path=args.config)
    generator.generate_all()

if __name__ == "__main__":
    main()
