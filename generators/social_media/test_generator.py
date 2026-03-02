#!/usr/bin/env python3

"""Test the social media generator with reduced data volume."""

import generators.social_media.generator as generator

# Modify configuration for faster testing

# Reduce data volume for testing
generator.CONFIG = {
    "users": 100,  # Reduced from 1000
    "avg_followers": 20,  # Reduced from 150
    "posts_per_user": (2, 10),  # Reduced from (5, 50)
    "comments_per_post": (0, 5),  # Reduced from (0, 20)
    "hashtags": 20,  # Reduced from 100
    "conversations": 20,  # Reduced from 200
    "days_of_history": 7,  # Reduced from 30
    "daily_active_users": 0.3,
}

print("Test Configuration:")
print(f"  Users: {generator.CONFIG['users']}")
print(f"  Days of history: {generator.CONFIG['days_of_history']}")
print("")

if __name__ == "__main__":
    gen = generator.SocialMediaGenerator()
    gen.generate_all()
    print("\n[SUCCESS] Social Media test generation complete!")
