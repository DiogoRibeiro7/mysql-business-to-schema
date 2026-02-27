#!/usr/bin/env python3
"""
Social Media Platform Data Generator

Generates realistic social media data including:
- Users with profiles and settings
- Social graph relationships (followers/friends)
- Posts with various content types
- Engagements (likes, comments, shares)
- Hashtags and trending topics
- Messages and notifications
"""

import csv
import random
import hashlib
import json
from datetime import datetime, timedelta
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import yaml
from faker import Faker

# Load configuration
with open("config.yaml", "r") as f:
    config = yaml.safe_load(f)

# Initialize Faker with seed
faker = Faker()
Faker.seed(config["seed"])
random.seed(config["seed"])

# Create output directory
output_dir = Path(config["output_dir"])
output_dir.mkdir(parents=True, exist_ok=True)


class SocialMediaDataGenerator:
    def __init__(self):
        self.users = []
        self.user_profiles = []
        self.relationships = []
        self.posts = []
        self.comments = []
        self.reactions = []
        self.hashtags = {}
        self.messages = []
        self.notifications = []
        self.start_date = datetime.now() - timedelta(
            days=config["counts"]["days_of_activity"]
        )

    def generate_all(self):
        """Generate all data for the social media platform."""
        print("Generating Social Media platform data...")

        # Generate base entities
        self.generate_users()
        self.generate_relationships()
        self.generate_posts()
        self.generate_engagements()
        self.generate_hashtags()
        self.generate_messages()

        # Write all data to CSV files
        self.write_all_to_csv()

        print(f"Data generation complete. Files written to {output_dir}")

    def generate_users(self):
        """Generate users with profiles."""
        num_users = config["counts"]["users"]

        # Generate power-law distribution for followers
        follower_counts = self._generate_power_law_distribution(
            num_users, config["engagement"]["power_law_alpha"]
        )

        for i in range(1, num_users + 1):
            # Determine user type and activity level
            user_type = random.choices(
                list(config["distributions"]["user_types"].keys()),
                weights=list(config["distributions"]["user_types"].values()),
            )[0]

            activity_level = random.choices(
                list(config["distributions"]["user_activity_levels"].keys()),
                weights=list(config["distributions"]["user_activity_levels"].values()),
            )[0]

            # Generate user data
            username = self._generate_username(i, user_type)
            email = faker.email()
            created_at = faker.date_time_between(
                start_date=self.start_date, end_date="now"
            )

            user = {
                "user_id": i,
                "username": username,
                "email": email,
                "email_verified": random.random() > 0.2,
                "password_hash": faker.sha256(),
                "phone_number": (
                    faker.phone_number()[:20] if random.random() > 0.5 else None
                ),
                "phone_verified": random.random() > 0.5,
                "status": random.choices(
                    ["active", "suspended", "banned", "deleted"],
                    weights=[0.95, 0.03, 0.01, 0.01],
                )[0],
                "account_type": user_type,
                "created_at": created_at,
                "last_active": created_at
                + timedelta(days=random.randint(0, (datetime.now() - created_at).days)),
            }

            self.users.append(user)

            # Generate user profile
            profile = {
                "user_id": i,
                "display_name": (
                    faker.name() if user_type == "personal" else faker.company()
                ),
                "bio": faker.text(max_nb_chars=200) if random.random() > 0.3 else None,
                "profile_picture_url": (
                    f"https://avatars.example.com/{i}.jpg"
                    if random.random() > 0.3
                    else None
                ),
                "cover_picture_url": (
                    f"https://covers.example.com/{i}.jpg"
                    if random.random() > 0.6
                    else None
                ),
                "website": (
                    faker.url()
                    if user_type in ["business", "creator", "verified"]
                    else None
                ),
                "location": faker.city() if random.random() > 0.4 else None,
                "birth_date": (
                    faker.date_of_birth(minimum_age=13, maximum_age=80)
                    if user_type == "personal"
                    else None
                ),
                "gender": (
                    random.choice(["male", "female", "other", "prefer_not_to_say"])
                    if random.random() > 0.3
                    else None
                ),
                "language": random.choice(["en", "es", "fr", "de", "ja", "zh"]),
                "timezone": faker.timezone(),
                "is_private": random.choices([True, False], weights=[0.2, 0.8])[0],
                "verified_badge": user_type == "verified"
                or (user_type == "creator" and random.random() > 0.7),
                "follower_count": follower_counts[i - 1],
                "following_count": random.randint(
                    10, min(1000, follower_counts[i - 1] * 2)
                ),
                "post_count": 0,  # Will be updated when generating posts
                "activity_level": activity_level,
            }

            self.user_profiles.append(profile)

    def generate_relationships(self):
        """Generate follower/friend relationships."""
        print("Generating relationships...")

        for user in self.users[
            : config["counts"]["users"] // 2
        ]:  # Generate for half the users to avoid too many relationships
            user_id = user["user_id"]
            profile = self.user_profiles[user_id - 1]

            # Number of relationships based on activity level
            activity_multiplier = {
                "very_active": 2.0,
                "active": 1.5,
                "moderate": 1.0,
                "casual": 0.5,
                "lurker": 0.2,
            }

            base_relationships = random.randint(
                config["counts"]["relationships_per_user"]["min"],
                config["counts"]["relationships_per_user"]["max"],
            )

            num_relationships = int(
                base_relationships
                * activity_multiplier.get(profile["activity_level"], 1.0)
            )

            # Generate relationships
            potential_targets = [
                u["user_id"]
                for u in self.users
                if u["user_id"] != user_id and u["status"] == "active"
            ]

            if not potential_targets:
                continue

            targets = random.sample(
                potential_targets, min(num_relationships, len(potential_targets))
            )

            for target_id in targets:
                rel_type = random.choices(
                    list(config["distributions"]["relationship_types"].keys()),
                    weights=list(
                        config["distributions"]["relationship_types"].values()
                    ),
                )[0]

                # Friend relationships should be mutual
                if rel_type == "friend":
                    # Create bidirectional friendship
                    self.relationships.append(
                        {
                            "from_user_id": user_id,
                            "to_user_id": target_id,
                            "relationship_type": "friend",
                            "status": "active",
                            "created_at": faker.date_time_between(
                                start_date=user["created_at"], end_date="now"
                            ),
                        }
                    )
                    self.relationships.append(
                        {
                            "from_user_id": target_id,
                            "to_user_id": user_id,
                            "relationship_type": "friend",
                            "status": "active",
                            "created_at": faker.date_time_between(
                                start_date=user["created_at"], end_date="now"
                            ),
                        }
                    )
                else:
                    self.relationships.append(
                        {
                            "from_user_id": user_id,
                            "to_user_id": target_id,
                            "relationship_type": rel_type,
                            "status": "active" if rel_type != "block" else "active",
                            "created_at": faker.date_time_between(
                                start_date=user["created_at"], end_date="now"
                            ),
                        }
                    )

    def generate_posts(self):
        """Generate posts for users."""
        print("Generating posts...")
        post_id = 1

        for user in self.users:
            if user["status"] != "active":
                continue

            profile = self.user_profiles[user["user_id"] - 1]

            # Number of posts based on activity level
            posts_multiplier = {
                "very_active": 2.0,
                "active": 1.5,
                "moderate": 1.0,
                "casual": 0.5,
                "lurker": 0.1,
            }

            base_posts = random.randint(
                config["counts"]["posts_per_user"]["min"],
                config["counts"]["posts_per_user"]["max"],
            )

            num_posts = int(
                base_posts * posts_multiplier.get(profile["activity_level"], 1.0)
            )

            for _ in range(num_posts):
                post_type = random.choices(
                    list(config["distributions"]["post_types"].keys()),
                    weights=list(config["distributions"]["post_types"].values()),
                )[0]

                # Generate post content
                content = self._generate_post_content(post_type)

                # Extract hashtags
                hashtags_in_post = [
                    word for word in content.split() if word.startswith("#")
                ]

                # Calculate engagement based on follower count and other factors
                base_engagement = (
                    profile["follower_count"] * config["counts"]["engagement_rate"]
                )

                if profile["verified_badge"]:
                    base_engagement *= config["engagement"]["network_effects"][
                        "verified_engagement_boost"
                    ]

                post = {
                    "post_id": post_id,
                    "user_id": user["user_id"],
                    "parent_post_id": None,  # Could add repost logic here
                    "content": content,
                    "post_type": post_type,
                    "visibility": random.choices(
                        ["public", "friends", "private"], weights=[0.7, 0.25, 0.05]
                    )[0],
                    "is_edited": random.random() > 0.9,
                    "location": faker.city() if random.random() > 0.7 else None,
                    "latitude": faker.latitude() if random.random() > 0.8 else None,
                    "longitude": faker.longitude() if random.random() > 0.8 else None,
                    "view_count": int(base_engagement * random.uniform(1, 10)),
                    "share_count": int(base_engagement * random.uniform(0, 0.2)),
                    "comment_count": int(base_engagement * random.uniform(0, 0.3)),
                    "like_count": int(base_engagement * random.uniform(0.5, 1.5)),
                    "engagement_score": 0,  # Would be calculated
                    "is_promoted": random.random() > 0.95,
                    "is_archived": False,
                    "created_at": faker.date_time_between(
                        start_date=user["created_at"], end_date="now"
                    ),
                    "hashtags": hashtags_in_post,
                }

                # Update engagement score
                post["engagement_score"] = (
                    post["like_count"] * 1
                    + post["comment_count"] * 2
                    + post["share_count"] * 3
                ) / max(post["view_count"], 1)

                self.posts.append(post)
                post_id += 1

            # Update post count in profile
            profile["post_count"] = num_posts

    def generate_engagements(self):
        """Generate likes, comments, and shares."""
        print("Generating engagements...")

        # Generate reactions (likes, etc.)
        for post in self.posts[:1000]:  # Limit to first 1000 posts for performance
            num_reactions = min(post["like_count"], 50)  # Cap at 50 reactions per post

            reacting_users = random.sample(
                [u["user_id"] for u in self.users if u["user_id"] != post["user_id"]],
                min(num_reactions, len(self.users) - 1),
            )

            for user_id in reacting_users:
                reaction_type = random.choices(
                    list(config["distributions"]["reaction_types"].keys()),
                    weights=list(config["distributions"]["reaction_types"].values()),
                )[0]

                self.reactions.append(
                    {
                        "user_id": user_id,
                        "target_type": "post",
                        "target_id": post["post_id"],
                        "reaction_type": reaction_type,
                        "created_at": faker.date_time_between(
                            start_date=post["created_at"], end_date="now"
                        ),
                    }
                )

        # Generate comments
        comment_id = 1
        for post in self.posts[:500]:  # Limit to first 500 posts
            num_comments = min(post["comment_count"], 20)  # Cap at 20 comments

            for _ in range(num_comments):
                commenter = random.choice(self.users)

                self.comments.append(
                    {
                        "comment_id": comment_id,
                        "post_id": post["post_id"],
                        "user_id": commenter["user_id"],
                        "parent_comment_id": None,  # Could add nested comments
                        "content": faker.text(max_nb_chars=200),
                        "like_count": random.randint(0, 10),
                        "is_edited": random.random() > 0.9,
                        "is_hidden": random.random() > 0.95,
                        "created_at": faker.date_time_between(
                            start_date=post["created_at"], end_date="now"
                        ),
                    }
                )
                comment_id += 1

    def generate_hashtags(self):
        """Generate hashtag data."""
        print("Generating hashtags...")

        # Collect all hashtags from posts
        hashtag_counts = {}
        for post in self.posts:
            for tag in post.get("hashtags", []):
                normalized = tag.lower().replace("#", "")
                if normalized not in hashtag_counts:
                    hashtag_counts[normalized] = {"tag": tag, "count": 0, "posts": []}
                hashtag_counts[normalized]["count"] += 1
                hashtag_counts[normalized]["posts"].append(post["post_id"])

        # Create hashtag records
        hashtag_id = 1
        for normalized, data in hashtag_counts.items():
            self.hashtags[hashtag_id] = {
                "hashtag_id": hashtag_id,
                "tag": data["tag"],
                "tag_normalized": normalized,
                "post_count": data["count"],
                "weekly_count": int(data["count"] * 0.3),
                "daily_count": int(data["count"] * 0.1),
                "created_at": min(
                    p["created_at"]
                    for p in self.posts
                    if data["tag"] in p.get("hashtags", [])
                ),
                "posts": data["posts"],
            }
            hashtag_id += 1

    def generate_messages(self):
        """Generate direct messages between users."""
        print("Generating messages...")

        # Create some conversations
        num_conversations = min(100, len(self.users) // 10)

        for _ in range(num_conversations):
            participants = random.sample(self.users, 2)

            # Generate a few messages
            num_messages = random.randint(2, 20)

            for _ in range(num_messages):
                sender = random.choice(participants)

                self.messages.append(
                    {
                        "sender_user_id": sender["user_id"],
                        "receiver_user_id": [
                            p["user_id"]
                            for p in participants
                            if p["user_id"] != sender["user_id"]
                        ][0],
                        "message_type": random.choices(
                            ["text", "image", "video"], weights=[0.8, 0.15, 0.05]
                        )[0],
                        "content": faker.text(max_nb_chars=200),
                        "is_read": random.random() > 0.2,
                        "created_at": faker.date_time_between(
                            start_date=self.start_date, end_date="now"
                        ),
                    }
                )

    def _generate_username(self, user_id: int, user_type: str) -> str:
        """Generate a username based on user type."""
        if user_type == "business":
            return faker.company().lower().replace(" ", "_")[:30]
        elif user_type == "creator":
            return f"{faker.user_name()}_creator"[:30]
        elif user_type == "verified":
            return faker.user_name()[:30]
        else:
            return faker.user_name()[:30]

    def _generate_post_content(self, post_type: str) -> str:
        """Generate post content based on type."""
        templates = config["content"]["post_templates"]
        template = random.choice(templates)

        replacements = {
            "{location}": faker.city(),
            "{topic}": faker.catch_phrase(),
            "{time}": faker.time(),
            "{emoji}": random.choice(["😊", "🎉", "💪", "🔥", "❤️", "👍"]),
            "{hashtag}": random.choice(config["content"]["hashtags"]["trending"]),
            "{mention}": f"@{faker.user_name()}",
            "{link}": faker.url(),
            "{thing}": faker.word(),
            "{quote}": faker.sentence(),
        }

        content = template
        for key, value in replacements.items():
            content = content.replace(key, value)

        return content

    def _generate_power_law_distribution(self, n: int, alpha: float) -> List[int]:
        """Generate power-law distribution for follower counts."""
        # Generate power-law distributed values
        values = []
        for i in range(1, n + 1):
            value = int(10000 * (i / n) ** (-1 / alpha))
            values.append(max(0, value))

        # Shuffle to avoid correlation with user_id
        random.shuffle(values)
        return values

    def write_all_to_csv(self):
        """Write all generated data to CSV files."""
        # Write users
        with open(output_dir / "users.csv", "w", newline="", encoding="utf-8") as f:
            if self.users:
                writer = csv.DictWriter(
                    f,
                    fieldnames=[
                        "user_id",
                        "username",
                        "email",
                        "email_verified",
                        "password_hash",
                        "phone_number",
                        "phone_verified",
                        "status",
                        "account_type",
                        "created_at",
                        "last_active",
                    ],
                )
                writer.writeheader()
                writer.writerows(self.users)

        # Write user profiles
        with open(
            output_dir / "user_profiles.csv", "w", newline="", encoding="utf-8"
        ) as f:
            if self.user_profiles:
                writer = csv.DictWriter(
                    f,
                    fieldnames=[
                        "user_id",
                        "display_name",
                        "bio",
                        "profile_picture_url",
                        "cover_picture_url",
                        "website",
                        "location",
                        "birth_date",
                        "gender",
                        "language",
                        "timezone",
                        "is_private",
                        "verified_badge",
                        "follower_count",
                        "following_count",
                        "post_count",
                    ],
                    extrasaction="ignore",
                )
                writer.writeheader()
                writer.writerows(self.user_profiles)

        # Write relationships
        with open(
            output_dir / "relationships.csv", "w", newline="", encoding="utf-8"
        ) as f:
            if self.relationships:
                writer = csv.DictWriter(f, fieldnames=self.relationships[0].keys())
                writer.writeheader()
                writer.writerows(self.relationships)

        # Write posts
        with open(output_dir / "posts.csv", "w", newline="", encoding="utf-8") as f:
            if self.posts:
                fieldnames = [k for k in self.posts[0].keys() if k != "hashtags"]
                writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
                writer.writeheader()
                writer.writerows(self.posts)

        # Write comments
        with open(output_dir / "comments.csv", "w", newline="", encoding="utf-8") as f:
            if self.comments:
                writer = csv.DictWriter(f, fieldnames=self.comments[0].keys())
                writer.writeheader()
                writer.writerows(self.comments)

        # Write reactions
        with open(output_dir / "reactions.csv", "w", newline="", encoding="utf-8") as f:
            if self.reactions:
                writer = csv.DictWriter(f, fieldnames=self.reactions[0].keys())
                writer.writeheader()
                writer.writerows(self.reactions)

        # Write hashtags
        hashtag_list = []
        for hashtag in self.hashtags.values():
            hashtag_copy = hashtag.copy()
            hashtag_copy.pop("posts", None)
            hashtag_list.append(hashtag_copy)

        with open(output_dir / "hashtags.csv", "w", newline="", encoding="utf-8") as f:
            if hashtag_list:
                writer = csv.DictWriter(f, fieldnames=hashtag_list[0].keys())
                writer.writeheader()
                writer.writerows(hashtag_list)

        print(f"Generated data summary:")
        print(f"  - Users: {len(self.users)}")
        print(f"  - Relationships: {len(self.relationships)}")
        print(f"  - Posts: {len(self.posts)}")
        print(f"  - Comments: {len(self.comments)}")
        print(f"  - Reactions: {len(self.reactions)}")
        print(f"  - Hashtags: {len(self.hashtags)}")


if __name__ == "__main__":
    generator = SocialMediaDataGenerator()
    generator.generate_all()
