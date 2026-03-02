#!/usr/bin/env python3
"""
Social Media Platform Data Generator
Generates realistic data for a social media platform with user relationships,
posts, engagement, messaging, and viral content tracking
"""

import csv
import json
import random
import hashlib
import uuid
from datetime import datetime, timedelta, date
from pathlib import Path
from faker import Faker
import numpy as np
import math

from typing import Any, Dict, List

# Configuration
SEED = 42
OUTPUT_DIR = Path("output")
fake = Faker()
Faker.seed(SEED)
random.seed(SEED)
np.random.seed(SEED)

# Scale configuration
CONFIG = {
    "users": 1000,
    "avg_followers": 150,  # Average followers per user
    "posts_per_user": (5, 50),  # Min and max posts per active user
    "comments_per_post": (0, 20),
    "hashtags": 100,
    "conversations": 200,
    "days_of_history": 30,
    "daily_active_users": 0.3,  # 30% of users active daily
}


class SocialMediaGenerator:
    def __init__(self):
        # User entities
        self.users: List[Any] = []
        self.user_profiles: List[Any] = []
        self.user_settings: List[Any] = []

        # Relationships (graph)
        self.relationships: List[Any] = []
        self.relationship_requests: List[Any] = []

        # Content
        self.posts: List[Any] = []
        self.post_media: List[Any] = []
        self.comments: List[Any] = []
        self.reactions: List[Any] = []
        self.shares: List[Any] = []
        self.bookmarks: List[Any] = []

        # Hashtags and trending
        self.hashtags: List[Any] = []
        self.post_hashtags: List[Any] = []
        self.trending_topics: List[Any] = []

        # Messaging
        self.conversations: List[Any] = []
        self.conversation_participants: List[Any] = []
        self.messages: List[Any] = []

        # Notifications
        self.notifications: List[Any] = []

        # Moderation
        self.reports: List[Any] = []
        self.banned_content: List[Any] = []

        # Analytics
        self.user_activity_logs: List[Any] = []
        self.engagement_metrics: List[Any] = []
        self.viral_content_tracking: List[Any] = []

        # Lists
        self.user_lists: List[Any] = []
        self.list_members: List[Any] = []

        # Counters
        self.user_id = 0
        self.profile_id = 0
        self.settings_id = 0
        self.relationship_id = 0
        self.request_id = 0
        self.post_id = 0
        self.media_id = 0
        self.comment_id = 0
        self.reaction_id = 0
        self.share_id = 0
        self.bookmark_id = 0
        self.hashtag_id = 0
        self.post_hashtag_id = 0
        self.trending_id = 0
        self.conversation_id = 0
        self.participant_id = 0
        self.message_id = 0
        self.notification_id = 0
        self.report_id = 0
        self.banned_id = 0
        self.activity_id = 0
        self.metric_id = 0
        self.viral_id = 0
        self.list_id = 0
        self.list_member_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

        # Track user influence scores for viral content
        self.user_influence: Dict[str, Any] = {}

    def generate_all(self):
        """Generate all social media platform data"""
        print("Starting Social Media Platform Data Generation...")
        print(f"Configuration:")
        print(f"  Users: {CONFIG['users']}")
        print(f"  Average followers: {CONFIG['avg_followers']}")
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Users and profiles
        self.generate_users()
        self.generate_user_profiles()
        self.generate_user_settings()

        # Social graph
        self.generate_relationships()
        self.generate_relationship_requests()

        # Content creation
        self.generate_hashtags()
        self.generate_posts()
        self.generate_post_media()
        self.generate_comments()
        self.generate_reactions()
        self.generate_shares()
        self.generate_bookmarks()
        self.generate_post_hashtags()

        # Trending and viral
        self.generate_trending_topics()
        # Viral content is tracked during post generation

        # Messaging
        self.generate_conversations()
        self.generate_messages()

        # Lists
        self.generate_user_lists()

        # Moderation
        self.generate_reports()
        self.generate_banned_content()

        # Notifications
        self.generate_notifications()

        # Analytics
        self.generate_user_activity_logs()
        self.generate_engagement_metrics()

        # Save all data
        self.save_all()

    def generate_users(self):
        """Generate user accounts"""
        print(f"Generating {CONFIG['users']} users...")

        account_types = ["personal", "business", "creator", "verified"]
        statuses = [
            "active",
            "active",
            "active",
            "suspended",
            "deactivated",
        ]  # Most users are active

        for i in range(CONFIG["users"]):
            self.user_id += 1

            created_date = fake.date_time_between(start_date="-2y", end_date="-1d")

            # Determine user type and influence
            is_influencer = random.random() < 0.05  # 5% are influencers
            account_type = (
                "verified"
                if is_influencer
                else random.choices(
                    ["personal", "business", "creator"], weights=[0.7, 0.2, 0.1]
                )[0]
            )

            username = (
                fake.user_name() + str(random.randint(1, 999))
                if random.random() < 0.3
                else fake.user_name()
            )

            self.users.append(
                {
                    "user_id": self.user_id,
                    "username": username[:50],
                    "email": fake.email(),
                    "password_hash": hashlib.sha256(
                        f"password{self.user_id}".encode()
                    ).hexdigest(),
                    "display_name": fake.name(),
                    "account_type": account_type,
                    "verification_status": (
                        "verified"
                        if account_type == "verified"
                        else random.choice(["unverified", "pending"])
                    ),
                    "status": random.choice(statuses),
                    "created_at": created_date,
                    "last_active": fake.date_time_between(
                        start_date=created_date, end_date="now"
                    ),
                    "follower_count": 0,  # Will be updated when generating relationships
                    "following_count": 0,
                    "post_count": 0,  # Will be updated when generating posts
                    "is_private": random.random() < 0.2,  # 20% have private accounts
                    "two_factor_enabled": random.random() < 0.3,
                }
            )

            # Track influence score
            if is_influencer:
                self.user_influence[self.user_id] = random.uniform(0.7, 1.0)
            else:
                self.user_influence[self.user_id] = random.uniform(0.1, 0.6)

    def generate_user_profiles(self):
        """Generate user profile details"""
        print("Generating user profiles...")

        for user in self.users:
            self.profile_id += 1

            # Generate profile based on account type
            if user["account_type"] == "business":
                bio = fake.company() + " | " + fake.catch_phrase()
                website = fake.url()
                location = fake.city() + ", " + fake.country()
            elif user["account_type"] == "creator":
                bio = (
                    random.choice(
                        ["Content Creator", "Digital Artist", "Photographer", "Writer"]
                    )
                    + " | "
                    + fake.catch_phrase()
                )
                website = f"https://linktr.ee/{user['username']}"
                location = fake.city()
            else:
                bio = fake.text(max_nb_chars=150) if random.random() > 0.3 else None
                website = fake.url() if random.random() < 0.2 else None
                location = fake.city() if random.random() < 0.5 else None

            self.user_profiles.append(
                {
                    "profile_id": self.profile_id,
                    "user_id": user["user_id"],
                    "bio": bio[:500] if bio else None,
                    "website": website[:200] if website else None,
                    "location": location[:100] if location else None,
                    "birth_date": (
                        fake.date_of_birth(minimum_age=13, maximum_age=80)
                        if user["account_type"] == "personal"
                        else None
                    ),
                    "phone_number": (
                        fake.phone_number()[:20] if random.random() < 0.3 else None
                    ),
                    "profile_image_url": f"https://avatars.example.com/user_{user['user_id']}.jpg",
                    "cover_image_url": (
                        f"https://covers.example.com/user_{user['user_id']}.jpg"
                        if random.random() < 0.5
                        else None
                    ),
                    "created_at": user["created_at"],
                    "updated_at": fake.date_time_between(
                        start_date=user["created_at"], end_date="now"
                    ),
                }
            )

    def generate_user_settings(self):
        """Generate user settings"""
        print("Generating user settings...")

        for user in self.users:
            self.settings_id += 1

            self.user_settings.append(
                {
                    "settings_id": self.settings_id,
                    "user_id": user["user_id"],
                    "email_notifications": random.random() > 0.3,
                    "push_notifications": random.random() > 0.2,
                    "sms_notifications": random.random() < 0.1,
                    "notification_new_follower": True,
                    "notification_new_message": True,
                    "notification_mentions": True,
                    "notification_comments": random.random() > 0.3,
                    "notification_likes": random.random() < 0.5,
                    "privacy_show_activity_status": random.random() > 0.4,
                    "privacy_allow_tagging": random.random() > 0.2,
                    "privacy_message_requests": random.choice(
                        ["everyone", "followers", "none"]
                    ),
                    "language": random.choice(["en", "es", "fr", "de", "pt", "ja"]),
                    "timezone": fake.timezone(),
                    "created_at": user["created_at"],
                    "updated_at": datetime.now(),
                }
            )

    def generate_relationships(self):
        """Generate follower/following relationships (social graph)"""
        print("Generating social graph relationships...")

        # Create a more realistic social graph with power-law distribution
        # Some users have many followers (influencers), most have few

        for user in self.users:
            if user["status"] != "active":
                continue

            # Determine number of followers based on influence
            influence = self.user_influence.get(user["user_id"], 0.3)

            if influence > 0.7:  # Influencers
                num_followers = random.randint(
                    min(500, CONFIG["users"] // 2), min(2000, CONFIG["users"] - 1)
                )
            elif influence > 0.5:  # Popular users
                num_followers = random.randint(
                    min(100, CONFIG["users"] // 4), min(500, CONFIG["users"] // 2)
                )
            else:  # Regular users
                num_followers = random.randint(
                    min(10, CONFIG["users"] // 10), min(150, CONFIG["users"] // 3)
                )

            # Limit to available users
            num_followers = min(num_followers, CONFIG["users"] - 1)

            # Select followers
            potential_followers = [
                u
                for u in self.users
                if u["user_id"] != user["user_id"] and u["status"] == "active"
            ]
            followers = random.sample(
                potential_followers, min(num_followers, len(potential_followers))
            )

            for follower in followers:
                self.relationship_id += 1

                follow_date = max(
                    user["created_at"], follower["created_at"]
                ) + timedelta(days=random.randint(1, 30))

                self.relationships.append(
                    {
                        "relationship_id": self.relationship_id,
                        "follower_id": follower["user_id"],
                        "following_id": user["user_id"],
                        "relationship_type": "follow",
                        "created_at": follow_date,
                        "is_close_friend": random.random()
                        < 0.1,  # 10% are close friends
                        "is_muted": random.random() < 0.05,  # 5% are muted
                        "is_blocked": False,  # Blocked users would be in a different table
                    }
                )

                # Update counts
                user["follower_count"] += 1
                follower["following_count"] += 1

    def generate_relationship_requests(self):
        """Generate follow requests for private accounts"""
        print("Generating relationship requests...")

        private_users = [
            u for u in self.users if u["is_private"] and u["status"] == "active"
        ]

        for user in private_users:
            # Generate some pending follow requests
            num_requests = random.randint(0, 10)

            for _ in range(num_requests):
                self.request_id += 1

                requester = random.choice(
                    [
                        u
                        for u in self.users
                        if u["user_id"] != user["user_id"] and u["status"] == "active"
                    ]
                )

                request_date = max(
                    user["created_at"], requester["created_at"]
                ) + timedelta(days=random.randint(1, CONFIG["days_of_history"]))

                status = random.choices(
                    ["pending", "approved", "rejected"], weights=[0.5, 0.3, 0.2]
                )[0]

                self.relationship_requests.append(
                    {
                        "request_id": self.request_id,
                        "requester_id": requester["user_id"],
                        "requested_id": user["user_id"],
                        "status": status,
                        "created_at": request_date,
                        "responded_at": (
                            request_date + timedelta(hours=random.randint(1, 72))
                            if status != "pending"
                            else None
                        ),
                    }
                )

    def generate_hashtags(self):
        """Generate hashtags"""
        print(f"Generating {CONFIG['hashtags']} hashtags...")

        hashtag_categories = [
            "tech",
            "fashion",
            "food",
            "travel",
            "fitness",
            "art",
            "music",
            "photography",
            "news",
            "meme",
        ]

        for i in range(CONFIG["hashtags"]):
            self.hashtag_id += 1

            category = random.choice(hashtag_categories)

            # Generate hashtag name based on category
            if category == "tech":
                name = random.choice(
                    ["AI", "MachineLearning", "Coding", "Tech", "Innovation"]
                ) + str(random.randint(1, 100))
            elif category == "fashion":
                name = (
                    random.choice(["Fashion", "Style", "OOTD", "Outfit", "Trends"])
                    + fake.word().capitalize()
                )
            elif category == "food":
                name = (
                    random.choice(["Food", "Recipe", "Cooking", "Foodie", "Yummy"])
                    + fake.word().capitalize()
                )
            else:
                name = fake.word().capitalize() + random.choice(
                    ["Life", "Daily", "Love", "Vibes", ""]
                )

            self.hashtags.append(
                {
                    "hashtag_id": self.hashtag_id,
                    "hashtag_name": name[:50],
                    "category": category,
                    "usage_count": 0,  # Will be updated when generating posts
                    "created_at": fake.date_time_between(
                        start_date="-1y", end_date="now"
                    ),
                    "is_trending": False,  # Will be updated later
                }
            )

    def generate_posts(self):
        """Generate user posts"""
        print("Generating posts...")

        post_types = ["text", "image", "video", "link", "poll"]

        for user in self.users:
            if user["status"] != "active":
                continue

            # Determine number of posts based on user type
            if user["account_type"] in ["creator", "verified"]:
                num_posts = random.randint(
                    min(20, CONFIG["posts_per_user"][0] * 2),
                    CONFIG["posts_per_user"][1],
                )
            elif user["account_type"] == "business":
                num_posts = random.randint(
                    min(10, CONFIG["posts_per_user"][0]),
                    min(30, CONFIG["posts_per_user"][1]),
                )
            else:
                num_posts = random.randint(*CONFIG["posts_per_user"])

            for _ in range(num_posts):
                self.post_id += 1

                post_date = fake.date_time_between(
                    start_date=user["created_at"], end_date="now"
                )
                post_type = random.choice(post_types)

                # Generate content based on type
                if post_type == "text":
                    content = fake.text(max_nb_chars=280)
                elif post_type == "image":
                    content = fake.sentence() + " 📷"
                elif post_type == "video":
                    content = fake.sentence() + " 🎥"
                elif post_type == "link":
                    content = fake.sentence() + f" {fake.url()}"
                else:  # poll
                    content = fake.sentence() + " [Poll]"

                # Determine virality potential
                influence = self.user_influence.get(user["user_id"], 0.3)
                is_viral = random.random() < (
                    influence * 0.1
                )  # Influenced users have higher viral chance

                self.posts.append(
                    {
                        "post_id": self.post_id,
                        "user_id": user["user_id"],
                        "post_type": post_type,
                        "content": content[:1000],
                        "media_url": (
                            f"https://media.example.com/post_{self.post_id}"
                            if post_type in ["image", "video"]
                            else None
                        ),
                        "location": fake.city() if random.random() < 0.3 else None,
                        "visibility": (
                            "public" if not user["is_private"] else "followers"
                        ),
                        "is_pinned": random.random() < 0.05,  # 5% are pinned
                        "is_archived": random.random() < 0.1,  # 10% are archived
                        "created_at": post_date,
                        "updated_at": (
                            post_date
                            if random.random() > 0.1
                            else post_date + timedelta(minutes=random.randint(1, 60))
                        ),
                        "view_count": (
                            random.randint(10, 10000)
                            if is_viral
                            else random.randint(10, 500)
                        ),
                        "like_count": 0,  # Will be updated with reactions
                        "comment_count": 0,  # Will be updated with comments
                        "share_count": 0,  # Will be updated with shares
                        "engagement_rate": 0.0,  # Will be calculated later
                    }
                )

                # Update user post count
                user["post_count"] += 1

                # Track viral content
                if is_viral:
                    self.viral_id += 1
                    self.viral_content_tracking.append(
                        {
                            "tracking_id": self.viral_id,
                            "post_id": self.post_id,
                            "detection_time": post_date
                            + timedelta(hours=random.randint(1, 24)),
                            "peak_engagement_time": post_date
                            + timedelta(hours=random.randint(24, 72)),
                            "viral_score": random.uniform(0.7, 1.0),
                            "reach_count": random.randint(10000, 100000),
                            "created_at": post_date,
                        }
                    )

    def generate_post_media(self):
        """Generate media attachments for posts"""
        print("Generating post media...")

        media_posts = [p for p in self.posts if p["post_type"] in ["image", "video"]]

        for post in media_posts:
            # Generate 1-4 media items per post
            num_media = random.randint(1, 4) if post["post_type"] == "image" else 1

            for i in range(num_media):
                self.media_id += 1

                if post["post_type"] == "image":
                    media_type = "image"
                    file_ext = random.choice(["jpg", "png", "webp"])
                    duration = None
                else:
                    media_type = "video"
                    file_ext = random.choice(["mp4", "mov", "webm"])
                    duration = random.randint(5, 300)  # 5 seconds to 5 minutes

                self.post_media.append(
                    {
                        "media_id": self.media_id,
                        "post_id": post["post_id"],
                        "media_type": media_type,
                        "media_url": f"https://media.example.com/{media_type}/{self.media_id}.{file_ext}",
                        "thumbnail_url": f"https://media.example.com/thumb/{self.media_id}.jpg",
                        "media_order": i + 1,
                        "width": (
                            random.choice([1080, 1920, 3840])
                            if media_type == "image"
                            else 1920
                        ),
                        "height": (
                            random.choice([1080, 1920, 2160])
                            if media_type == "image"
                            else 1080
                        ),
                        "file_size_bytes": random.randint(100000, 10000000),
                        "duration_seconds": duration,
                        "created_at": post["created_at"],
                    }
                )

    def generate_comments(self):
        """Generate comments on posts"""
        print("Generating comments...")

        for post in self.posts:
            # Popular posts get more comments
            if post["view_count"] > 5000:
                num_comments = random.randint(
                    min(10, CONFIG["comments_per_post"][0]),
                    max(CONFIG["comments_per_post"][1], 10),
                )
            elif post["view_count"] > 1000:
                num_comments = random.randint(
                    min(5, CONFIG["comments_per_post"][0]),
                    max(15, CONFIG["comments_per_post"][1]),
                )
            else:
                num_comments = random.randint(*CONFIG["comments_per_post"])

            # Get potential commenters (followers of post author)
            post_author = next(u for u in self.users if u["user_id"] == post["user_id"])
            potential_commenters = [
                r["follower_id"]
                for r in self.relationships
                if r["following_id"] == post["user_id"]
            ]

            if not potential_commenters:
                potential_commenters = [
                    u["user_id"] for u in self.users if u["user_id"] != post["user_id"]
                ]

            for _ in range(min(num_comments, len(potential_commenters))):
                self.comment_id += 1

                commenter_id = random.choice(potential_commenters)
                comment_time = post["created_at"] + timedelta(
                    minutes=random.randint(1, 24 * 60)
                )

                # Some comments are replies to other comments
                parent_comment_id = None
                if self.comments and random.random() < 0.3:  # 30% are replies
                    post_comments = [
                        c for c in self.comments if c["post_id"] == post["post_id"]
                    ]
                    if post_comments:
                        parent_comment_id = random.choice(post_comments)["comment_id"]

                self.comments.append(
                    {
                        "comment_id": self.comment_id,
                        "post_id": post["post_id"],
                        "user_id": commenter_id,
                        "parent_comment_id": parent_comment_id,
                        "content": (
                            fake.sentence()
                            if random.random() > 0.1
                            else random.choice(["😍", "❤️", "👏", "🔥", "💯"])
                        ),
                        "created_at": comment_time,
                        "updated_at": comment_time,
                        "like_count": random.randint(0, 100),
                        "is_hidden": random.random() < 0.02,  # 2% are hidden
                    }
                )

                # Update post comment count
                post["comment_count"] += 1

    def generate_reactions(self):
        """Generate reactions (likes) on posts"""
        print("Generating reactions...")

        reaction_types = ["like", "love", "haha", "wow", "sad", "angry"]

        for post in self.posts:
            # Number of reactions based on views
            reaction_rate = random.uniform(0.05, 0.3)  # 5-30% of viewers react
            num_reactions = int(post["view_count"] * reaction_rate)
            num_reactions = min(
                num_reactions, CONFIG["users"] // 2
            )  # Cap at half of users

            # Get potential reactors
            potential_reactors = [
                u["user_id"]
                for u in self.users
                if u["user_id"] != post["user_id"] and u["status"] == "active"
            ]

            reactors = random.sample(
                potential_reactors, min(num_reactions, len(potential_reactors))
            )

            for user_id in reactors:
                self.reaction_id += 1

                reaction_time = post["created_at"] + timedelta(
                    minutes=random.randint(1, 24 * 60 * 7)  # Within a week
                )

                self.reactions.append(
                    {
                        "reaction_id": self.reaction_id,
                        "post_id": post["post_id"],
                        "user_id": user_id,
                        "reaction_type": random.choice(reaction_types),
                        "created_at": reaction_time,
                    }
                )

                # Update post like count
                if random.choice(reaction_types) in ["like", "love"]:
                    post["like_count"] += 1

    def generate_shares(self):
        """Generate post shares"""
        print("Generating shares...")

        # Only popular posts get shared
        popular_posts = [p for p in self.posts if p["view_count"] > 1000]

        for post in popular_posts:
            share_rate = random.uniform(0.01, 0.05)  # 1-5% of viewers share
            num_shares = int(post["view_count"] * share_rate)
            num_shares = min(num_shares, 100)  # Cap shares

            for _ in range(num_shares):
                self.share_id += 1

                sharer = random.choice(
                    [
                        u
                        for u in self.users
                        if u["user_id"] != post["user_id"] and u["status"] == "active"
                    ]
                )

                share_time = post["created_at"] + timedelta(hours=random.randint(1, 72))

                self.shares.append(
                    {
                        "share_id": self.share_id,
                        "post_id": post["post_id"],
                        "user_id": sharer["user_id"],
                        "share_type": random.choice(["repost", "quote", "story"]),
                        "share_comment": (
                            fake.sentence() if random.random() < 0.3 else None
                        ),
                        "created_at": share_time,
                    }
                )

                # Update post share count
                post["share_count"] += 1

    def generate_bookmarks(self):
        """Generate bookmarks"""
        print("Generating bookmarks...")

        for user in self.users:
            if user["status"] != "active":
                continue

            # Each user bookmarks 0-20 posts
            num_bookmarks = random.randint(0, 20)

            bookmarked_posts = random.sample(
                self.posts, min(num_bookmarks, len(self.posts))
            )

            for post in bookmarked_posts:
                self.bookmark_id += 1

                self.bookmarks.append(
                    {
                        "bookmark_id": self.bookmark_id,
                        "user_id": user["user_id"],
                        "post_id": post["post_id"],
                        "created_at": post["created_at"]
                        + timedelta(hours=random.randint(1, 24)),
                    }
                )

    def generate_post_hashtags(self):
        """Generate hashtag usage in posts"""
        print("Generating post hashtags...")

        for post in self.posts:
            # 60% of posts have hashtags
            if random.random() < 0.6:
                num_hashtags = random.randint(1, 5)
                selected_hashtags = random.sample(
                    self.hashtags, min(num_hashtags, len(self.hashtags))
                )

                for hashtag in selected_hashtags:
                    self.post_hashtag_id += 1

                    self.post_hashtags.append(
                        {
                            "post_hashtag_id": self.post_hashtag_id,
                            "post_id": post["post_id"],
                            "hashtag_id": hashtag["hashtag_id"],
                            "created_at": post["created_at"],
                        }
                    )

                    # Update hashtag usage count
                    hashtag["usage_count"] += 1

    def generate_trending_topics(self):
        """Generate trending topics"""
        print("Generating trending topics...")

        # Select top used hashtags as trending
        sorted_hashtags = sorted(
            self.hashtags, key=lambda x: x["usage_count"], reverse=True
        )
        trending_hashtags = sorted_hashtags[:20]

        current_date = self.start_date.date()
        end_date = datetime.now().date()

        while current_date <= end_date:
            # Daily trending topics (5-10 per day)
            daily_trending = random.sample(
                trending_hashtags, min(random.randint(5, 10), len(trending_hashtags))
            )

            for rank, hashtag in enumerate(daily_trending, 1):
                self.trending_id += 1

                self.trending_topics.append(
                    {
                        "trending_id": self.trending_id,
                        "hashtag_id": hashtag["hashtag_id"],
                        "trend_date": current_date,
                        "rank": rank,
                        "tweet_volume": hashtag["usage_count"]
                        * random.randint(10, 100),
                        "growth_rate": random.uniform(
                            -0.5, 2.0
                        ),  # -50% to +200% growth
                        "created_at": datetime.combine(
                            current_date, datetime.min.time()
                        ),
                    }
                )

                # Mark hashtag as trending
                hashtag["is_trending"] = True

            current_date += timedelta(days=1)

    def generate_conversations(self):
        """Generate message conversations"""
        print(f"Generating {CONFIG['conversations']} conversations...")

        for i in range(CONFIG["conversations"]):
            self.conversation_id += 1

            # Select 2-5 participants
            num_participants = random.randint(2, 5)
            participants = random.sample(self.users, num_participants)

            is_group = num_participants > 2

            self.conversations.append(
                {
                    "conversation_id": self.conversation_id,
                    "conversation_type": "group" if is_group else "direct",
                    "title": fake.sentence(nb_words=3) if is_group else None,
                    "created_by": participants[0]["user_id"],
                    "created_at": fake.date_time_between(
                        start_date=self.start_date, end_date="now"
                    ),
                    "last_message_at": None,  # Will be updated when generating messages
                    "is_archived": random.random() < 0.1,
                }
            )

            # Add participants
            for participant in participants:
                self.participant_id += 1

                self.conversation_participants.append(
                    {
                        "participant_id": self.participant_id,
                        "conversation_id": self.conversation_id,
                        "user_id": participant["user_id"],
                        "joined_at": self.conversations[-1]["created_at"],
                        "left_at": None,
                        "is_admin": (
                            participant == participants[0] if is_group else False
                        ),
                        "last_read_message_id": None,
                        "is_muted": random.random() < 0.1,
                    }
                )

    def generate_messages(self):
        """Generate messages in conversations"""
        print("Generating messages...")

        for conversation in self.conversations:
            # Get conversation participants
            participants = [
                p
                for p in self.conversation_participants
                if p["conversation_id"] == conversation["conversation_id"]
            ]

            # Generate 5-50 messages per conversation
            num_messages = random.randint(5, 50)

            last_message_time = conversation["created_at"]

            for _ in range(num_messages):
                self.message_id += 1

                sender = random.choice(participants)
                message_time = last_message_time + timedelta(
                    minutes=random.randint(1, 60)
                )

                # Message content
                message_types = ["text", "image", "video", "audio", "file"]
                message_type = random.choices(
                    message_types, weights=[0.7, 0.15, 0.05, 0.05, 0.05]
                )[0]

                if message_type == "text":
                    content = fake.text(max_nb_chars=200)
                    media_url = None
                else:
                    content = f"[{message_type}]"
                    media_url = f"https://media.example.com/messages/{self.message_id}"

                # Some messages are replies
                reply_to = None
                if len(self.messages) > 0 and random.random() < 0.2:  # 20% are replies
                    conv_messages = [
                        m
                        for m in self.messages
                        if m["conversation_id"] == conversation["conversation_id"]
                    ]
                    if conv_messages:
                        reply_to = random.choice(conv_messages)["message_id"]

                self.messages.append(
                    {
                        "message_id": self.message_id,
                        "conversation_id": conversation["conversation_id"],
                        "sender_id": sender["user_id"],
                        "message_type": message_type,
                        "content": content[:1000],
                        "media_url": media_url,
                        "reply_to_message_id": reply_to,
                        "is_edited": random.random() < 0.05,
                        "is_deleted": random.random() < 0.02,
                        "created_at": message_time,
                        "read_by": json.dumps(
                            [
                                p["user_id"]
                                for p in participants
                                if random.random() > 0.3
                            ]
                        ),
                    }
                )

                last_message_time = message_time

            # Update conversation last message time
            conversation["last_message_at"] = last_message_time

    def generate_user_lists(self):
        """Generate user lists (like Twitter lists)"""
        print("Generating user lists...")

        for user in self.users[:100]:  # Top 100 users create lists
            # Each user creates 0-3 lists
            num_lists = random.randint(0, 3)

            for _ in range(num_lists):
                self.list_id += 1

                list_name = random.choice(
                    [
                        "Tech Leaders",
                        "News Sources",
                        "Friends",
                        "Inspirational",
                        "Funny People",
                    ]
                )

                created_list = {
                    "list_id": self.list_id,
                    "user_id": user["user_id"],
                    "list_name": list_name + f" {random.randint(1, 99)}",
                    "description": fake.sentence(),
                    "is_private": random.random() < 0.3,
                    "member_count": 0,
                    "subscriber_count": random.randint(0, 100),
                    "created_at": fake.date_time_between(
                        start_date=user["created_at"], end_date="now"
                    ),
                }
                self.user_lists.append(created_list)

                # Add members to list
                num_members = random.randint(5, 30)
                members = random.sample(self.users, min(num_members, len(self.users)))

                for member in members:
                    self.list_member_id += 1

                    self.list_members.append(
                        {
                            "member_id": self.list_member_id,
                            "list_id": self.list_id,
                            "user_id": member["user_id"],
                            "added_at": created_list["created_at"]
                            + timedelta(days=random.randint(0, 30)),
                        }
                    )

                    created_list["member_count"] += 1

    def generate_reports(self):
        """Generate content reports"""
        print("Generating reports...")

        report_reasons = [
            "spam",
            "harassment",
            "hate_speech",
            "violence",
            "nudity",
            "false_information",
            "other",
        ]

        # Generate reports for some posts
        reported_posts = random.sample(self.posts, min(50, len(self.posts)))

        for post in reported_posts:
            self.report_id += 1

            reporter = random.choice(
                [u for u in self.users if u["user_id"] != post["user_id"]]
            )

            self.reports.append(
                {
                    "report_id": self.report_id,
                    "reporter_id": reporter["user_id"],
                    "content_type": "post",
                    "content_id": post["post_id"],
                    "reason": random.choice(report_reasons),
                    "description": fake.sentence() if random.random() < 0.5 else None,
                    "status": random.choice(
                        ["pending", "reviewed", "resolved", "dismissed"]
                    ),
                    "moderator_id": (
                        random.randint(1, 10) if random.random() < 0.7 else None
                    ),
                    "created_at": post["created_at"]
                    + timedelta(hours=random.randint(1, 48)),
                    "resolved_at": None,
                }
            )

    def generate_banned_content(self):
        """Generate banned content records"""
        print("Generating banned content...")

        # Some reported content gets banned
        resolved_reports = [r for r in self.reports if r["status"] == "resolved"]

        for report in resolved_reports[:20]:  # Limit to 20 bans
            self.banned_id += 1

            self.banned_content.append(
                {
                    "ban_id": self.banned_id,
                    "content_type": report["content_type"],
                    "content_id": report["content_id"],
                    "reason": report["reason"],
                    "banned_by": report["moderator_id"],
                    "ban_date": report["created_at"]
                    + timedelta(hours=random.randint(1, 24)),
                    "appeal_status": random.choice(
                        ["none", "pending", "approved", "rejected"]
                    ),
                    "created_at": report["created_at"],
                }
            )

    def generate_notifications(self):
        """Generate notifications"""
        print("Generating notifications...")

        notification_types = [
            "new_follower",
            "like",
            "comment",
            "mention",
            "share",
            "message",
        ]

        # Generate notifications for recent activities
        for user in self.users:
            if user["status"] != "active":
                continue

            # New follower notifications
            user_followers = [
                r for r in self.relationships if r["following_id"] == user["user_id"]
            ]
            for follower in user_followers[-10:]:  # Last 10 followers
                self.notification_id += 1

                self.notifications.append(
                    {
                        "notification_id": self.notification_id,
                        "user_id": user["user_id"],
                        "type": "new_follower",
                        "content": f"User {follower['follower_id']} started following you",
                        "related_user_id": follower["follower_id"],
                        "related_post_id": None,
                        "is_read": random.random() < 0.7,
                        "created_at": follower["created_at"],
                    }
                )

            # Like notifications (sample)
            user_posts = [p for p in self.posts if p["user_id"] == user["user_id"]]
            for post in user_posts[:5]:  # Last 5 posts
                post_likes = [
                    r for r in self.reactions if r["post_id"] == post["post_id"]
                ]
                for like in post_likes[:3]:  # First 3 likes
                    self.notification_id += 1

                    self.notifications.append(
                        {
                            "notification_id": self.notification_id,
                            "user_id": user["user_id"],
                            "type": "like",
                            "content": f"User {like['user_id']} liked your post",
                            "related_user_id": like["user_id"],
                            "related_post_id": post["post_id"],
                            "is_read": random.random() < 0.8,
                            "created_at": like["created_at"],
                        }
                    )

    def generate_user_activity_logs(self):
        """Generate user activity logs"""
        print("Generating user activity logs...")

        activities = [
            "login",
            "logout",
            "post_created",
            "post_deleted",
            "profile_updated",
            "settings_changed",
        ]

        for user in self.users:
            if user["status"] != "active":
                continue

            # Generate daily activities
            current = max(user["created_at"], self.start_date)

            while current <= datetime.now():
                # Daily login/logout
                if random.random() < CONFIG["daily_active_users"]:
                    self.activity_id += 1

                    login_time = current.replace(
                        hour=random.randint(6, 22), minute=random.randint(0, 59)
                    )

                    self.user_activity_logs.append(
                        {
                            "log_id": self.activity_id,
                            "user_id": user["user_id"],
                            "activity_type": "login",
                            "ip_address": fake.ipv4(),
                            "user_agent": fake.user_agent()[:200],
                            "created_at": login_time,
                        }
                    )

                    # Logout
                    self.activity_id += 1
                    logout_time = login_time + timedelta(
                        minutes=random.randint(10, 300)
                    )

                    self.user_activity_logs.append(
                        {
                            "log_id": self.activity_id,
                            "user_id": user["user_id"],
                            "activity_type": "logout",
                            "ip_address": fake.ipv4(),
                            "user_agent": fake.user_agent()[:200],
                            "created_at": logout_time,
                        }
                    )

                current += timedelta(days=1)

    def generate_engagement_metrics(self):
        """Generate engagement metrics"""
        print("Generating engagement metrics...")

        # Calculate engagement for posts
        for post in self.posts:
            if post["view_count"] > 0:
                engagement = (
                    post["like_count"] + post["comment_count"] + post["share_count"]
                ) / post["view_count"]
                post["engagement_rate"] = round(engagement * 100, 2)

        # Generate daily user engagement metrics
        for user in self.users[:100]:  # Top 100 users
            current = self.start_date.date()

            while current <= date.today():
                self.metric_id += 1

                # Get user's posts for this day
                daily_posts = [
                    p
                    for p in self.posts
                    if p["user_id"] == user["user_id"]
                    and p["created_at"].date() == current
                ]

                if daily_posts:
                    total_views = sum(p["view_count"] for p in daily_posts)
                    total_likes = sum(p["like_count"] for p in daily_posts)
                    total_comments = sum(p["comment_count"] for p in daily_posts)
                    total_shares = sum(p["share_count"] for p in daily_posts)
                else:
                    total_views = total_likes = total_comments = total_shares = 0

                self.engagement_metrics.append(
                    {
                        "metric_id": self.metric_id,
                        "user_id": user["user_id"],
                        "metric_date": current,
                        "posts_created": len(daily_posts),
                        "total_views": total_views,
                        "total_likes": total_likes,
                        "total_comments": total_comments,
                        "total_shares": total_shares,
                        "engagement_rate": round(
                            (total_likes + total_comments + total_shares)
                            / max(total_views, 1)
                            * 100,
                            2,
                        ),
                        "follower_growth": random.randint(-10, 100),
                        "created_at": datetime.combine(current, datetime.min.time()),
                    }
                )

                current += timedelta(days=1)

    def save_all(self):
        """Save all generated data to CSV files"""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ("users", self.users),
            ("user_profiles", self.user_profiles),
            ("user_settings", self.user_settings),
            ("relationships", self.relationships[:5000]),  # Limit for demo
            ("relationship_requests", self.relationship_requests),
            ("posts", self.posts),
            ("post_media", self.post_media),
            ("comments", self.comments[:5000]),  # Limit for demo
            ("reactions", self.reactions[:5000]),  # Limit for demo
            ("shares", self.shares),
            ("bookmarks", self.bookmarks),
            ("hashtags", self.hashtags),
            ("post_hashtags", self.post_hashtags),
            ("trending_topics", self.trending_topics),
            ("conversations", self.conversations),
            ("conversation_participants", self.conversation_participants),
            ("messages", self.messages[:5000]),  # Limit for demo
            ("notifications", self.notifications[:2000]),  # Limit for demo
            ("reports", self.reports),
            ("banned_content", self.banned_content),
            ("user_activity_logs", self.user_activity_logs[:2000]),  # Limit for demo
            ("engagement_metrics", self.engagement_metrics),
            ("viral_content_tracking", self.viral_content_tracking),
            ("user_lists", self.user_lists),
            ("list_members", self.list_members),
        ]

        for name, data in datasets:
            if data:
                filepath = OUTPUT_DIR / f"{name}.csv"
                with open(filepath, "w", newline="", encoding="utf-8") as f:
                    writer = csv.DictWriter(f, fieldnames=data[0].keys())
                    writer.writeheader()
                    writer.writerows(data)
                print(f"  [OK] {name}: {len(data):,} records")

        self.generate_summary()

    def generate_summary(self):
        """Generate summary statistics"""
        print(f"\nSocial Media Platform Data Generation Summary")
        print("=" * 50)

        print(f"\nUsers:")
        print(f"  Total Users: {len(self.users)}")
        print(
            f"  Active Users: {len([u for u in self.users if u['status'] == 'active'])}"
        )
        print(
            f"  Verified Users: {len([u for u in self.users if u['account_type'] == 'verified'])}"
        )
        print(f"  Private Accounts: {len([u for u in self.users if u['is_private']])}")

        print(f"\nSocial Graph:")
        print(f"  Total Relationships: {len(self.relationships)}")
        print(
            f"  Average Followers: {sum(u['follower_count'] for u in self.users) / len(self.users):.1f}"
        )
        print(f"  Max Followers: {max(u['follower_count'] for u in self.users)}")
        print(f"  Relationship Requests: {len(self.relationship_requests)}")

        print(f"\nContent:")
        print(f"  Total Posts: {len(self.posts)}")
        print(f"  Posts with Media: {len([p for p in self.posts if p['media_url']])}")
        print(f"  Comments: {len(self.comments)}")
        print(f"  Reactions: {len(self.reactions)}")
        print(f"  Shares: {len(self.shares)}")
        print(f"  Bookmarks: {len(self.bookmarks)}")

        print(f"\nHashtags & Trending:")
        print(f"  Hashtags: {len(self.hashtags)}")
        print(f"  Trending Topics: {len(self.trending_topics)}")
        print(f"  Viral Content: {len(self.viral_content_tracking)}")

        print(f"\nMessaging:")
        print(f"  Conversations: {len(self.conversations)}")
        print(f"  Messages: {len(self.messages)}")
        print(
            f"  Group Chats: {len([c for c in self.conversations if c['conversation_type'] == 'group'])}"
        )

        print(f"\nEngagement:")
        avg_engagement = (
            sum(p["engagement_rate"] for p in self.posts) / len(self.posts)
            if self.posts
            else 0
        )
        print(f"  Average Engagement Rate: {avg_engagement:.2f}%")
        print(f"  Total Views: {sum(p['view_count'] for p in self.posts):,}")
        print(f"  Total Likes: {sum(p['like_count'] for p in self.posts):,}")

        print(f"\nModeration:")
        print(f"  Reports: {len(self.reports)}")
        print(f"  Banned Content: {len(self.banned_content)}")

        print(f"\nAnalytics:")
        print(f"  Activity Logs: {len(self.user_activity_logs)}")
        print(f"  Engagement Metrics: {len(self.engagement_metrics)}")
        print(f"  Notifications: {len(self.notifications)}")

        print(f"\nFiles Generated: 25")


if __name__ == "__main__":
    generator = SocialMediaGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Social Media Platform data generation complete!")
