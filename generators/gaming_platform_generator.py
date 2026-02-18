#!/usr/bin/env python3
"""
Gaming Platform Data Generator

Generates realistic test data for the gaming platform database.
Includes players, games, matches, tournaments, virtual economy, and social features.
"""

import random
import sys
import os
from datetime import datetime, timedelta
from decimal import Decimal
from typing import List, Dict, Tuple, Optional
import json
import hashlib
import secrets
import string

# Add parent directory to path for base generator
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from generators.base_generator import BaseGenerator


class GamingPlatformGenerator(BaseGenerator):
    """Generator for Gaming Platform data"""

    def __init__(self, host='localhost', port=3338, user='gaming_admin',
                 password='gaming_pass_2024', database='gaming_platform'):
        """Initialize the gaming platform generator"""
        super().__init__(host, port, user, password, database)

        # Gaming data
        self.game_genres = [
            'FPS', 'MOBA', 'RPG', 'Strategy', 'Sports', 'Racing',
            'Fighting', 'Puzzle', 'Simulation', 'Adventure', 'Horror',
            'Platformer', 'Sandbox', 'Card', 'Battle Royale'
        ]

        self.platforms = ['PC', 'PlayStation', 'Xbox', 'Nintendo', 'Mobile', 'VR']

        self.game_modes = ['solo', 'duo', 'squad', 'team_deathmatch', 'capture_flag',
                          'battle_royale', 'ranked', 'casual', 'tournament']

        self.achievement_types = ['milestone', 'skill', 'exploration', 'collection',
                                 'social', 'competitive', 'secret']

        self.item_rarities = ['common', 'uncommon', 'rare', 'epic', 'legendary', 'mythic']

        self.regions = ['NA', 'EU', 'ASIA', 'SA', 'OCE', 'ME']

        # Player ranks for competitive games
        self.ranks = [
            'Bronze I', 'Bronze II', 'Bronze III',
            'Silver I', 'Silver II', 'Silver III',
            'Gold I', 'Gold II', 'Gold III',
            'Platinum I', 'Platinum II', 'Platinum III',
            'Diamond I', 'Diamond II', 'Diamond III',
            'Master', 'Grandmaster', 'Champion'
        ]

    def generate_all_data(self, players: int = 10000, games: int = 50,
                         matches_per_day: int = 5000):
        """Generate all gaming platform data"""
        print("Starting Gaming Platform data generation...")

        # Generate base data
        print("Generating players...")
        self.generate_players(players)

        print("Generating games...")
        self.generate_games(games)

        print("Generating player profiles...")
        self.generate_player_profiles()

        print("Generating friends and friend requests...")
        self.generate_social_connections()

        print("Generating matches...")
        self.generate_matches(matches_per_day)

        print("Generating tournaments...")
        self.generate_tournaments()

        print("Generating achievements...")
        self.generate_achievements()

        print("Generating virtual items...")
        self.generate_virtual_items()

        print("Generating player inventory...")
        self.generate_player_inventory()

        print("Generating marketplace listings...")
        self.generate_marketplace()

        print("Generating chat messages...")
        self.generate_chat_messages()

        print("Generating leaderboards...")
        self.generate_leaderboards()

        print("Generating player reports...")
        self.generate_player_reports()

        print("Generation complete!")

    def generate_players(self, count: int = 10000):
        """Generate player accounts"""
        players = []

        for i in range(count):
            username = self.faker.user_name() + str(random.randint(100, 9999))
            email = self.faker.email()

            # Account types
            account_type = self.faker.random_element([
                ('free', 0.70),
                ('premium', 0.25),
                ('vip', 0.05)
            ])

            # Player status
            status = self.faker.random_element([
                ('active', 0.85),
                ('inactive', 0.10),
                ('banned', 0.03),
                ('suspended', 0.02)
            ])

            player = (
                username,
                email,
                self.generate_password_hash(),
                self.faker.first_name() if random.random() > 0.5 else None,
                self.faker.last_name() if random.random() > 0.5 else None,
                self.faker.date_of_birth(minimum_age=13, maximum_age=65),
                self.faker.country_code(),
                random.choice(self.regions),
                self.faker.random_element(['en', 'es', 'fr', 'de', 'pt', 'zh', 'ja', 'ko']),
                account_type,
                status,
                random.choice([0, 1]),  # email_verified
                random.choice([0, 1]) if account_type != 'free' else 0,  # two_factor_enabled
                random.randint(1, 100),  # player_level
                random.randint(0, 1000000),  # experience_points
                random.randint(0, 100000) if account_type != 'free' else random.randint(0, 10000),  # premium_currency
                random.randint(0, 1000000),  # standard_currency
                random.randint(0, 10000),  # total_playtime_hours
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.3 else None,
                self.faker.ipv4(),
                self.faker.date_time_between('-3 years', 'now'),
                self.faker.date_time_between('-3 years', 'now')
            )
            players.append(player)

            if (i + 1) % 1000 == 0:
                self.bulk_insert('players', players, [
                    'username', 'email', 'password_hash', 'first_name',
                    'last_name', 'date_of_birth', 'country', 'region',
                    'preferred_language', 'account_type', 'account_status',
                    'email_verified', 'two_factor_enabled', 'player_level',
                    'experience_points', 'premium_currency', 'standard_currency',
                    'total_playtime_hours', 'last_login', 'last_ip',
                    'created_at', 'updated_at'
                ])
                players = []
                print(f"  Generated {i + 1}/{count} players...")

        if players:
            self.bulk_insert('players', players, [
                'username', 'email', 'password_hash', 'first_name',
                'last_name', 'date_of_birth', 'country', 'region',
                'preferred_language', 'account_type', 'account_status',
                'email_verified', 'two_factor_enabled', 'player_level',
                'experience_points', 'premium_currency', 'standard_currency',
                'total_playtime_hours', 'last_login', 'last_ip',
                'created_at', 'updated_at'
            ])

    def generate_games(self, count: int = 50):
        """Generate game titles"""
        games = []

        game_names = [
            'Battle Arena', 'Shadow Strike', 'Crystal Quest', 'Neon Racing',
            'Space Commander', 'Dragon Legends', 'Zombie Survival', 'Cyber Wars',
            'Fantasy Kingdom', 'Street Fighter X', 'Speed Demons', 'War Thunder',
            'Ancient Myths', 'Future Combat', 'Ocean Explorer', 'Sky Pirates',
            'Dungeon Master', 'Robot Revolution', 'Magic Realms', 'Star Colonies'
        ]

        for i in range(min(count, len(game_names) * 3)):
            base_name = random.choice(game_names)
            suffix = random.choice(['', ' II', ' III', ' Online', ' VR', ' Mobile', ' Pro', ' Ultimate'])
            game_title = base_name + suffix

            game = (
                game_title,
                self.faker.slug(),
                random.choice(self.game_genres),
                self.faker.company() + ' Games',
                self.faker.company() + ' Studios',
                json.dumps(random.sample(self.platforms, random.randint(1, 3))),
                self.faker.text(max_nb_chars=500),
                random.choice(['E', 'E10+', 'T', 'M', 'AO']),
                random.uniform(0, 59.99) if random.random() > 0.3 else 0,  # price (0 = free-to-play)
                random.randint(0, 1000000),  # active_players
                random.uniform(3.0, 5.0),  # rating
                random.randint(0, 100000),  # total_reviews
                random.choice([0, 1]),  # supports_crossplay
                random.choice([0, 1]),  # has_multiplayer
                random.choice([0, 1]),  # has_coop
                random.choice([0, 1]) if random.random() > 0.7 else 0,  # has_competitive
                2 if random.random() > 0.7 else random.randint(4, 100),  # min_players
                random.randint(4, 100),  # max_players
                self.faker.date_between('-5 years', 'today'),
                self.faker.date_time_between('-5 years', 'now')
            )
            games.append(game)

        self.bulk_insert('games', games, [
            'game_title', 'slug', 'genre', 'publisher', 'developer',
            'platforms', 'description', 'age_rating', 'price',
            'active_players', 'rating', 'total_reviews',
            'supports_crossplay', 'has_multiplayer', 'has_coop',
            'has_competitive', 'min_players', 'max_players',
            'release_date', 'created_at'
        ])

    def generate_player_profiles(self):
        """Generate player profiles for different games"""
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 5000")
        games = self.fetch_all("SELECT game_id FROM games WHERE has_multiplayer = 1")

        profiles = []

        for player in players:
            # Each player plays 1-10 games
            num_games = random.randint(1, min(10, len(games)))
            player_games = random.sample(games, num_games)

            for game in player_games:
                # Generate stats based on playtime
                hours_played = random.randint(0, 2000)
                matches_played = hours_played * random.randint(2, 10)
                matches_won = int(matches_played * random.uniform(0.3, 0.7))

                profile = (
                    player['player_id'],
                    game['game_id'],
                    random.choice(self.ranks) if random.random() > 0.3 else None,
                    random.randint(0, 5000),  # skill_rating
                    hours_played,
                    matches_played,
                    matches_won,
                    random.randint(0, matches_played * 50),  # kills
                    random.randint(0, matches_played * 30),  # deaths
                    random.randint(0, matches_played * 20),  # assists
                    random.uniform(0.5, 3.0) if matches_played > 0 else 0,  # kd_ratio
                    random.uniform(30, 70) if matches_played > 0 else 0,  # win_rate
                    random.randint(0, 100),  # achievements_unlocked
                    random.randint(1, 500) if hours_played > 10 else 1,  # season_level
                    self.faker.date_time_between('-1 year', 'now')
                )
                profiles.append(profile)

                if len(profiles) >= 1000:
                    self.bulk_insert('player_profiles', profiles, [
                        'player_id', 'game_id', 'current_rank', 'skill_rating',
                        'hours_played', 'matches_played', 'matches_won',
                        'total_kills', 'total_deaths', 'total_assists',
                        'kd_ratio', 'win_rate', 'achievements_unlocked',
                        'season_level', 'last_played'
                    ])
                    profiles = []

        if profiles:
            self.bulk_insert('player_profiles', profiles, [
                'player_id', 'game_id', 'current_rank', 'skill_rating',
                'hours_played', 'matches_played', 'matches_won',
                'total_kills', 'total_deaths', 'total_assists',
                'kd_ratio', 'win_rate', 'achievements_unlocked',
                'season_level', 'last_played'
            ])

    def generate_social_connections(self):
        """Generate friends and friend requests"""
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 2000")

        friends = []
        friend_requests = []
        processed_pairs = set()

        for player in players:
            # Each player has 0-50 friends
            num_friends = random.randint(0, min(50, len(players) - 1))

            if num_friends > 0:
                potential_friends = [p for p in players if p['player_id'] != player['player_id']]
                player_friends = random.sample(potential_friends, min(num_friends, len(potential_friends)))

                for friend in player_friends:
                    # Ensure we don't duplicate friendships
                    pair = tuple(sorted([player['player_id'], friend['player_id']]))
                    if pair not in processed_pairs:
                        processed_pairs.add(pair)

                        if random.random() > 0.1:  # 90% are accepted friends
                            friendship = (
                                player['player_id'],
                                friend['player_id'],
                                'accepted',
                                self.faker.date_time_between('-1 year', 'now')
                            )
                            friends.append(friendship)
                        else:  # 10% are pending requests
                            request = (
                                player['player_id'],
                                friend['player_id'],
                                'pending',
                                self.faker.date_time_between('-30 days', 'now')
                            )
                            friend_requests.append(request)

        self.bulk_insert('friends', friends, [
            'player_id', 'friend_id', 'status', 'created_at'
        ])

        self.bulk_insert('friend_requests', friend_requests, [
            'sender_id', 'receiver_id', 'status', 'created_at'
        ])

    def generate_matches(self, matches_per_day: int = 5000):
        """Generate match history"""
        games = self.fetch_all("SELECT game_id, min_players, max_players FROM games WHERE has_multiplayer = 1")
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 5000")

        matches = []
        match_players = []
        match_id = 1

        # Generate matches for last 30 days
        for days_ago in range(30, 0, -1):
            match_date = datetime.now() - timedelta(days=days_ago)
            daily_matches = random.randint(int(matches_per_day * 0.7), int(matches_per_day * 1.3))

            for _ in range(daily_matches):
                game = random.choice(games)

                # Determine match size
                min_players = max(2, game['min_players'])
                max_players = min(100, game['max_players'])
                num_players = random.randint(min_players, min(max_players, 20))

                # Select players for the match
                match_player_list = random.sample(players, min(num_players, len(players)))

                # Create match
                match_mode = random.choice(self.game_modes)
                duration = random.randint(5, 60)  # minutes
                start_time = match_date + timedelta(
                    hours=random.randint(0, 23),
                    minutes=random.randint(0, 59)
                )

                match_record = (
                    game['game_id'],
                    match_mode,
                    random.choice(['ranked', 'casual', 'tournament', 'custom']),
                    random.choice(self.regions),
                    f"server-{random.randint(1, 100)}",
                    'completed',
                    start_time,
                    start_time + timedelta(minutes=duration),
                    duration,
                    num_players,
                    random.choice(match_player_list)['player_id'] if num_players > 0 else None,  # winner_id
                    None  # winner_team
                )
                matches.append(match_record)

                # Create match player records
                for i, player in enumerate(match_player_list):
                    team = (i % 2) + 1 if match_mode in ['team_deathmatch', 'capture_flag'] else None

                    player_record = (
                        match_id,
                        player['player_id'],
                        team,
                        random.randint(0, 50),  # kills
                        random.randint(0, 30),  # deaths
                        random.randint(0, 20),  # assists
                        random.randint(0, 10000),  # score
                        random.randint(0, 10000),  # damage_dealt
                        random.randint(0, 10000),  # damage_taken
                        random.randint(0, 5000),  # healing_done
                        i + 1,  # placement
                        random.uniform(0.5, 2.5),  # performance_rating
                        random.randint(-30, 30),  # rating_change
                        random.randint(10, 500),  # experience_gained
                        random.randint(10, 100) if random.random() > 0.3 else 0  # currency_earned
                    )
                    match_players.append(player_record)

                match_id += 1

                if len(matches) >= 500:
                    self.bulk_insert('matches', matches, [
                        'game_id', 'match_mode', 'match_type', 'server_region',
                        'server_id', 'status', 'started_at', 'ended_at',
                        'duration_minutes', 'player_count', 'winner_id',
                        'winner_team'
                    ])
                    matches = []

                if len(match_players) >= 2000:
                    self.bulk_insert('match_players', match_players, [
                        'match_id', 'player_id', 'team', 'kills', 'deaths',
                        'assists', 'score', 'damage_dealt', 'damage_taken',
                        'healing_done', 'placement', 'performance_rating',
                        'rating_change', 'experience_gained', 'currency_earned'
                    ])
                    match_players = []

            print(f"  Generated matches for {days_ago} days ago...")

        # Insert remaining data
        if matches:
            self.bulk_insert('matches', matches, [
                'game_id', 'match_mode', 'match_type', 'server_region',
                'server_id', 'status', 'started_at', 'ended_at',
                'duration_minutes', 'player_count', 'winner_id',
                'winner_team'
            ])

        if match_players:
            self.bulk_insert('match_players', match_players, [
                'match_id', 'player_id', 'team', 'kills', 'deaths',
                'assists', 'score', 'damage_dealt', 'damage_taken',
                'healing_done', 'placement', 'performance_rating',
                'rating_change', 'experience_gained', 'currency_earned'
            ])

    def generate_tournaments(self):
        """Generate tournaments and participants"""
        games = self.fetch_all("SELECT game_id FROM games WHERE has_competitive = 1")
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 1000")

        tournaments = []
        participants = []

        for game in games[:10]:  # Create tournaments for first 10 competitive games
            for _ in range(random.randint(2, 5)):  # 2-5 tournaments per game
                tournament_name = f"{self.faker.company()} Championship {random.randint(2024, 2025)}"

                tournament = (
                    game['game_id'],
                    tournament_name,
                    self.faker.text(max_nb_chars=500),
                    random.choice(['single_elimination', 'double_elimination', 'round_robin', 'swiss']),
                    random.choice([8, 16, 32, 64, 128]),
                    random.randint(0, 100000),  # prize_pool
                    random.choice(['USD', 'EUR', 'Credits']),
                    random.choice(['open', 'invite_only', 'qualifier']),
                    random.choice(['upcoming', 'ongoing', 'completed', 'cancelled']),
                    self.faker.date_time_between('-30 days', '+30 days'),
                    self.faker.date_time_between('+30 days', '+60 days'),
                    random.randint(50, 128),  # registered_players
                    self.faker.date_time_between('-60 days', 'now')
                )
                tournaments.append(tournament)

        self.bulk_insert('tournaments', tournaments, [
            'game_id', 'tournament_name', 'description', 'tournament_format',
            'max_participants', 'prize_pool', 'prize_currency', 'entry_type',
            'status', 'start_date', 'end_date', 'registered_players', 'created_at'
        ])

        # Generate tournament participants
        tournament_ids = list(range(1, len(tournaments) + 1))

        for tournament_id in tournament_ids:
            num_participants = random.randint(8, min(64, len(players)))
            tournament_players = random.sample(players, num_participants)

            for i, player in enumerate(tournament_players):
                participant = (
                    tournament_id,
                    player['player_id'],
                    None,  # team_id
                    i + 1 if random.random() > 0.5 else None,  # placement
                    random.randint(0, 10),  # matches_played
                    random.randint(0, 8),  # matches_won
                    random.randint(0, 10000) if i < 3 else 0,  # prize_won
                    random.choice(['registered', 'checked_in', 'eliminated', 'winner']),
                    self.faker.date_time_between('-30 days', 'now')
                )
                participants.append(participant)

        self.bulk_insert('tournament_participants', participants, [
            'tournament_id', 'player_id', 'team_id', 'placement',
            'matches_played', 'matches_won', 'prize_won', 'status',
            'registered_at'
        ])

    def generate_achievements(self):
        """Generate achievements for games"""
        games = self.fetch_all("SELECT game_id FROM games")

        achievements = []
        player_achievements = []

        achievement_names = [
            'First Blood', 'Veteran', 'Champion', 'Collector', 'Explorer',
            'Speedrunner', 'Perfectionist', 'Team Player', 'Lone Wolf',
            'Comeback King', 'Untouchable', 'Destroyer', 'Survivor',
            'Master Strategist', 'Risk Taker'
        ]

        # Generate achievements for each game
        for game in games:
            num_achievements = random.randint(10, 30)

            for i in range(num_achievements):
                achievement = (
                    game['game_id'],
                    random.choice(achievement_names) + f" {i+1}",
                    self.faker.sentence(),
                    random.choice(self.achievement_types),
                    random.choice(['bronze', 'silver', 'gold', 'platinum']),
                    random.randint(10, 100),  # points
                    random.choice([0, 1]) if random.random() > 0.8 else 0,  # is_hidden
                    self.faker.date_time_between('-2 years', 'now')
                )
                achievements.append(achievement)

        self.bulk_insert('achievements', achievements, [
            'game_id', 'achievement_name', 'description', 'achievement_type',
            'tier', 'points', 'is_hidden', 'created_at'
        ])

        # Generate player achievements (unlocked achievements)
        players_with_profiles = self.fetch_all("""
            SELECT DISTINCT pp.player_id, pp.game_id
            FROM player_profiles pp
            WHERE pp.hours_played > 5
            LIMIT 1000
        """)

        achievement_list = self.fetch_all("SELECT achievement_id, game_id FROM achievements")
        achievements_by_game = {}
        for ach in achievement_list:
            game_id = ach['game_id']
            if game_id not in achievements_by_game:
                achievements_by_game[game_id] = []
            achievements_by_game[game_id].append(ach['achievement_id'])

        for profile in players_with_profiles:
            if profile['game_id'] in achievements_by_game:
                game_achievements = achievements_by_game[profile['game_id']]
                num_unlocked = random.randint(1, min(15, len(game_achievements)))
                unlocked = random.sample(game_achievements, num_unlocked)

                for achievement_id in unlocked:
                    player_achievement = (
                        profile['player_id'],
                        achievement_id,
                        self.faker.date_time_between('-1 year', 'now'),
                        random.uniform(0.01, 100) if random.random() > 0.5 else None  # completion_percentage
                    )
                    player_achievements.append(player_achievement)

        self.bulk_insert('player_achievements', player_achievements, [
            'player_id', 'achievement_id', 'unlocked_at', 'progress_percentage'
        ])

    def generate_virtual_items(self):
        """Generate virtual items for games"""
        games = self.fetch_all("SELECT game_id FROM games")

        items = []

        item_types = ['weapon', 'armor', 'skin', 'emote', 'consumable', 'currency_pack', 'loot_box', 'battle_pass']

        item_names = {
            'weapon': ['Plasma Rifle', 'Dragon Sword', 'Shadow Blade', 'Thunder Hammer'],
            'armor': ['Knight Armor', 'Stealth Suit', 'Power Armor', 'Mystic Robes'],
            'skin': ['Gold Edition', 'Neon Glow', 'Camouflage', 'Rainbow'],
            'emote': ['Victory Dance', 'Taunt', 'Wave', 'Laugh'],
            'consumable': ['Health Potion', 'Speed Boost', 'Shield', 'Experience Booster'],
            'currency_pack': ['Starter Pack', 'Value Bundle', 'Mega Pack', 'Ultimate Bundle'],
            'loot_box': ['Bronze Crate', 'Silver Chest', 'Gold Box', 'Diamond Case'],
            'battle_pass': ['Season Pass', 'Premium Pass', 'Elite Pass', 'Ultimate Pass']
        }

        for game in games:
            num_items = random.randint(20, 100)

            for _ in range(num_items):
                item_type = random.choice(item_types)
                base_name = random.choice(item_names[item_type])
                item_name = f"{base_name} - {game['game_id']}"

                item = (
                    game['game_id'],
                    item_name,
                    self.faker.sentence(),
                    item_type,
                    random.choice(self.item_rarities),
                    random.uniform(0.99, 99.99) if item_type != 'consumable' else random.uniform(0.99, 9.99),
                    random.randint(0, 10000) if item_type == 'consumable' else 0,  # in_game_currency_price
                    random.choice([0, 1]),  # is_tradeable
                    random.choice([0, 1]),  # is_marketable
                    random.choice([0, 1]) if item_type == 'consumable' else 0,  # is_consumable
                    random.randint(1, 100) if item_type == 'consumable' else None,  # stack_size
                    self.faker.date_time_between('-2 years', 'now')
                )
                items.append(item)

                if len(items) >= 1000:
                    self.bulk_insert('virtual_items', items, [
                        'game_id', 'item_name', 'description', 'item_type',
                        'rarity', 'price', 'in_game_currency_price',
                        'is_tradeable', 'is_marketable', 'is_consumable',
                        'stack_size', 'created_at'
                    ])
                    items = []

        if items:
            self.bulk_insert('virtual_items', items, [
                'game_id', 'item_name', 'description', 'item_type',
                'rarity', 'price', 'in_game_currency_price',
                'is_tradeable', 'is_marketable', 'is_consumable',
                'stack_size', 'created_at'
            ])

    def generate_player_inventory(self):
        """Generate player inventory items"""
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 2000")
        items = self.fetch_all("SELECT item_id, is_consumable, stack_size FROM virtual_items")

        inventory = []

        for player in players:
            # Each player has 5-50 items
            num_items = random.randint(5, min(50, len(items)))
            player_items = random.sample(items, num_items)

            for item in player_items:
                quantity = random.randint(1, item['stack_size']) if item['is_consumable'] and item['stack_size'] else 1

                inventory_item = (
                    player['player_id'],
                    item['item_id'],
                    quantity,
                    random.choice([0, 1]),  # is_equipped
                    self.faker.date_time_between('-1 year', 'now'),
                    self.faker.date_time_between('-30 days', 'now') if random.random() > 0.5 else None
                )
                inventory.append(inventory_item)

                if len(inventory) >= 2000:
                    self.bulk_insert('player_inventory', inventory, [
                        'player_id', 'item_id', 'quantity', 'is_equipped',
                        'acquired_at', 'last_used'
                    ])
                    inventory = []

        if inventory:
            self.bulk_insert('player_inventory', inventory, [
                'player_id', 'item_id', 'quantity', 'is_equipped',
                'acquired_at', 'last_used'
            ])

    def generate_marketplace(self):
        """Generate marketplace listings"""
        tradeable_items = self.fetch_all("SELECT item_id, price FROM virtual_items WHERE is_marketable = 1")
        sellers = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 500")

        listings = []
        transactions = []

        for _ in range(1000):
            seller = random.choice(sellers)
            item = random.choice(tradeable_items)

            # Price variation from base price
            base_price = float(item['price'])
            listing_price = base_price * random.uniform(0.5, 2.0)

            listing_status = random.choice(['active', 'sold', 'cancelled', 'expired'])

            listing = (
                seller['player_id'],
                item['item_id'],
                1,  # quantity
                listing_price,
                'USD',
                listing_status,
                self.faker.date_time_between('-30 days', 'now'),
                self.faker.date_time_between('-30 days', 'now') + timedelta(days=7),
                self.faker.date_time_between('-30 days', 'now')
            )
            listings.append(listing)

            # If sold, create a transaction
            if listing_status == 'sold':
                buyer = random.choice([s for s in sellers if s['player_id'] != seller['player_id']])
                transaction = (
                    len(listings),  # listing_id (simplified)
                    buyer['player_id'],
                    seller['player_id'],
                    item['item_id'],
                    1,  # quantity
                    listing_price,
                    listing_price * 0.05,  # marketplace_fee
                    'completed',
                    self.faker.date_time_between('-30 days', 'now')
                )
                transactions.append(transaction)

        self.bulk_insert('marketplace_listings', listings, [
            'seller_id', 'item_id', 'quantity', 'price',
            'currency', 'status', 'listed_at', 'expires_at',
            'updated_at'
        ])

        self.bulk_insert('marketplace_transactions', transactions, [
            'listing_id', 'buyer_id', 'seller_id', 'item_id',
            'quantity', 'price', 'marketplace_fee', 'status',
            'completed_at'
        ])

    def generate_chat_messages(self):
        """Generate chat messages"""
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 500")
        matches = self.fetch_all("SELECT match_id FROM matches LIMIT 100")

        messages = []
        message_content = [
            'gg', 'good game', 'wp', 'well played', 'glhf', 'good luck have fun',
            'nice shot', 'thanks', 'no problem', 'sorry', 'my bad',
            'lets go', 'rush B', 'need backup', 'enemy spotted',
            'nice play', 'clutch', 'ez', 'close one', 'rematch?'
        ]

        # Generate match chat
        for match in matches[:50]:
            num_messages = random.randint(5, 30)

            for _ in range(num_messages):
                sender = random.choice(players)

                message = (
                    'match',
                    match['match_id'],
                    sender['player_id'],
                    random.choice(message_content),
                    'text',
                    False,  # is_deleted
                    False,  # is_reported
                    self.faker.date_time_between('-30 days', 'now')
                )
                messages.append(message)

        # Generate party chat
        for _ in range(500):
            sender = random.choice(players)

            message = (
                'party',
                random.randint(1, 100),  # channel_id (party_id)
                sender['player_id'],
                self.faker.sentence(),
                random.choice(['text', 'voice', 'system']),
                False,  # is_deleted
                random.random() > 0.95,  # is_reported (5% reported)
                self.faker.date_time_between('-7 days', 'now')
            )
            messages.append(message)

        self.bulk_insert('chat_messages', messages, [
            'channel_type', 'channel_id', 'sender_id', 'message_content',
            'message_type', 'is_deleted', 'is_reported', 'sent_at'
        ])

    def generate_leaderboards(self):
        """Generate leaderboard entries"""
        # Get top players per game
        top_players = self.fetch_all("""
            SELECT player_id, game_id, skill_rating, matches_won, kd_ratio
            FROM player_profiles
            WHERE skill_rating > 0
            ORDER BY game_id, skill_rating DESC
        """)

        leaderboards = []
        current_game = None
        rank = 0

        for player in top_players:
            if current_game != player['game_id']:
                current_game = player['game_id']
                rank = 0

            rank += 1
            if rank <= 100:  # Top 100 per game
                leaderboard = (
                    player['game_id'],
                    'global',
                    'season_1',
                    player['player_id'],
                    rank,
                    player['skill_rating'],
                    player['matches_won'],
                    player['kd_ratio'],
                    self.faker.date_time_between('-7 days', 'now')
                )
                leaderboards.append(leaderboard)

        self.bulk_insert('leaderboards', leaderboards, [
            'game_id', 'leaderboard_type', 'season', 'player_id',
            'rank', 'score', 'wins', 'kd_ratio', 'updated_at'
        ])

    def generate_player_reports(self):
        """Generate player reports for moderation"""
        players = self.fetch_all("SELECT player_id FROM players WHERE account_status = 'active' LIMIT 1000")

        reports = []
        report_reasons = ['cheating', 'toxic_behavior', 'harassment', 'spam', 'inappropriate_name', 'griefing']

        for _ in range(500):
            reporter = random.choice(players)
            reported = random.choice([p for p in players if p['player_id'] != reporter['player_id']])

            report = (
                reporter['player_id'],
                reported['player_id'],
                random.choice(report_reasons),
                self.faker.sentence() if random.random() > 0.5 else None,
                random.choice(['pending', 'reviewing', 'resolved', 'dismissed']),
                random.choice(['no_action', 'warning', 'temporary_ban', 'permanent_ban', None]),
                random.randint(1, 10) if random.random() > 0.5 else None,  # moderator_id
                self.faker.date_time_between('-30 days', 'now'),
                self.faker.date_time_between('-30 days', 'now') if random.random() > 0.5 else None
            )
            reports.append(report)

        self.bulk_insert('player_reports', reports, [
            'reporter_id', 'reported_player_id', 'reason', 'description',
            'status', 'action_taken', 'moderator_id', 'created_at',
            'resolved_at'
        ])


def main():
    """Main function to run the generator"""
    import argparse

    parser = argparse.ArgumentParser(description='Generate test data for Gaming Platform')
    parser.add_argument('--host', default='localhost', help='MySQL host')
    parser.add_argument('--port', type=int, default=3338, help='MySQL port')
    parser.add_argument('--user', default='gaming_admin', help='MySQL user')
    parser.add_argument('--password', default='gaming_pass_2024', help='MySQL password')
    parser.add_argument('--database', default='gaming_platform', help='MySQL database')
    parser.add_argument('--players', type=int, default=10000, help='Number of players')
    parser.add_argument('--games', type=int, default=50, help='Number of games')
    parser.add_argument('--matches-per-day', type=int, default=5000, help='Average matches per day')

    args = parser.parse_args()

    generator = GamingPlatformGenerator(
        host=args.host,
        port=args.port,
        user=args.user,
        password=args.password,
        database=args.database
    )

    try:
        generator.connect()
        generator.generate_all_data(
            players=args.players,
            games=args.games,
            matches_per_day=args.matches_per_day
        )
    finally:
        generator.disconnect()


if __name__ == '__main__':
    main()