#!/usr/bin/env python3
"""
Template for creating new data generators

This template provides a starting point for creating new generators
that follow the project's best practices and conventions.
"""

import random
import json
from datetime import datetime, timedelta
from faker import Faker
from pathlib import Path

# Configuration - Adjust these values for your domain
CONFIG = {
    # Core entities
    "primary_entities": 1000,      # e.g., users, customers, products
    "secondary_entities": 5000,    # e.g., orders, transactions, events

    # Time series
    "days_of_history": 30,         # Historical data generation period
    "events_per_day": 100,         # Average daily event volume

    # Relationships
    "avg_relationships": 10,       # Average relationships per entity
    "max_relationships": 50,        # Maximum relationships per entity

    # Business rules
    "business_hours": (9, 17),     # Operating hours (if applicable)
    "peak_hours": (11, 14),        # Peak activity hours
    "weekend_factor": 0.3,         # Weekend activity multiplier

    # Data quality
    "null_percentage": 0.05,       # Percentage of optional fields to leave null
    "error_rate": 0.01,            # Simulated error/anomaly rate
}

class YourDomainGenerator:
    """
    Generator for [YOUR DOMAIN] data

    This generator creates realistic data for a [DESCRIPTION] system
    including [KEY FEATURES].
    """

    def __init__(self):
        """Initialize the generator with Faker and data collections"""
        self.fake = Faker()
        Faker.seed(42)  # For reproducible data
        random.seed(42)

        # Define time boundaries
        self.end_date = datetime.now()
        self.start_date = self.end_date - timedelta(days=CONFIG["days_of_history"])

        # Initialize data collections
        self.primary_entities = []
        self.secondary_entities = []
        self.relationships = []
        self.time_series_data = []

        # Statistics tracking
        self.stats = {
            "total_records": 0,
            "tables_generated": 0,
            "generation_time": 0
        }

        # Output directory
        self.output_dir = Path("output")
        self.output_dir.mkdir(exist_ok=True)

    def generate_all(self):
        """Main entry point - generates all data"""
        start_time = datetime.now()

        print(f"\n{self.__class__.__name__} Starting...")
        print(f"Configuration:")
        print(f"  Primary Entities: {CONFIG['primary_entities']}")
        print(f"  Days of History: {CONFIG['days_of_history']}")
        print(f"  Output Directory: {self.output_dir}")

        # Generate data in logical order
        self.generate_primary_entities()
        self.generate_secondary_entities()
        self.generate_relationships()
        self.generate_time_series_data()
        self.generate_derived_data()

        # Calculate statistics
        self.stats["generation_time"] = (datetime.now() - start_time).total_seconds()

        # Print summary
        self.print_summary()

    def generate_primary_entities(self):
        """Generate the main entities for your domain"""
        print(f"\nGenerating {CONFIG['primary_entities']} primary entities...")

        for i in range(CONFIG["primary_entities"]):
            entity = {
                "id": i + 1,
                "uuid": self.fake.uuid4(),
                "name": self.fake.company() if random.random() > 0.5 else self.fake.name(),
                "email": self.fake.email(),
                "phone": self.fake.phone_number(),
                "address": self.fake.address().replace('\n', ', '),
                "created_at": self.fake.date_time_between(
                    start_date=self.start_date,
                    end_date=self.end_date
                ),
                "status": random.choice(["active", "inactive", "pending"]),
                "metadata": json.dumps({
                    "source": random.choice(["web", "mobile", "api"]),
                    "version": f"{random.randint(1, 5)}.{random.randint(0, 9)}"
                })
            }

            # Add optional fields with null probability
            if random.random() > CONFIG["null_percentage"]:
                entity["description"] = self.fake.text(max_nb_chars=200)
            else:
                entity["description"] = None

            self.primary_entities.append(entity)

        # Save to file
        self.save_to_file(
            "01_primary_entities.sql",
            "primary_entities",
            self.primary_entities,
            ["id", "uuid", "name", "email", "phone", "address", "created_at", "status", "metadata", "description"]
        )

    def generate_secondary_entities(self):
        """Generate secondary entities that depend on primary entities"""
        print(f"Generating {CONFIG['secondary_entities']} secondary entities...")

        for i in range(CONFIG["secondary_entities"]):
            # Link to a primary entity
            primary_id = random.choice(self.primary_entities)["id"]

            entity = {
                "id": i + 1,
                "primary_entity_id": primary_id,
                "type": random.choice(["type_a", "type_b", "type_c"]),
                "value": round(random.uniform(10, 1000), 2),
                "quantity": random.randint(1, 100),
                "timestamp": self.fake.date_time_between(
                    start_date=self.start_date,
                    end_date=self.end_date
                ),
                "status": random.choice(["pending", "processing", "completed", "cancelled"]),
                "notes": self.fake.sentence() if random.random() > 0.7 else None
            }

            self.secondary_entities.append(entity)

        self.save_to_file(
            "02_secondary_entities.sql",
            "secondary_entities",
            self.secondary_entities,
            ["id", "primary_entity_id", "type", "value", "quantity", "timestamp", "status", "notes"]
        )

    def generate_relationships(self):
        """Generate many-to-many relationships between entities"""
        print(f"Generating entity relationships...")

        relationship_set = set()  # Prevent duplicates

        for entity in self.primary_entities:
            # Generate random number of relationships
            num_relationships = min(
                random.randint(1, CONFIG["avg_relationships"] * 2),
                CONFIG["max_relationships"]
            )

            # Create relationships with other entities
            possible_targets = [e["id"] for e in self.primary_entities if e["id"] != entity["id"]]

            if len(possible_targets) >= num_relationships:
                targets = random.sample(possible_targets, num_relationships)
            else:
                targets = possible_targets

            for target_id in targets:
                # Ensure unique and ordered pairs
                rel_tuple = tuple(sorted([entity["id"], target_id]))

                if rel_tuple not in relationship_set:
                    relationship_set.add(rel_tuple)

                    self.relationships.append({
                        "entity_a_id": rel_tuple[0],
                        "entity_b_id": rel_tuple[1],
                        "relationship_type": random.choice(["follows", "likes", "connects", "references"]),
                        "strength": round(random.random(), 2),
                        "created_at": self.fake.date_time_between(
                            start_date=self.start_date,
                            end_date=self.end_date
                        )
                    })

        self.save_to_file(
            "03_relationships.sql",
            "entity_relationships",
            self.relationships,
            ["entity_a_id", "entity_b_id", "relationship_type", "strength", "created_at"]
        )

    def generate_time_series_data(self):
        """Generate time-series data (events, metrics, logs)"""
        print(f"Generating time-series data...")

        current_date = self.start_date

        while current_date <= self.end_date:
            # Adjust volume based on day of week
            is_weekend = current_date.weekday() >= 5
            day_multiplier = CONFIG["weekend_factor"] if is_weekend else 1.0

            # Generate events for this day
            num_events = int(random.randint(
                int(CONFIG["events_per_day"] * 0.7),
                int(CONFIG["events_per_day"] * 1.3)
            ) * day_multiplier)

            for _ in range(num_events):
                # Distribute events throughout the day with peak hours
                hour = self.get_weighted_hour()
                event_time = current_date.replace(
                    hour=hour,
                    minute=random.randint(0, 59),
                    second=random.randint(0, 59)
                )

                event = {
                    "id": len(self.time_series_data) + 1,
                    "entity_id": random.choice(self.primary_entities)["id"],
                    "event_type": random.choice(["view", "click", "action", "update", "delete"]),
                    "event_time": event_time,
                    "value": round(random.uniform(0, 100), 2) if random.random() > 0.5 else None,
                    "metadata": json.dumps({
                        "ip": self.fake.ipv4(),
                        "user_agent": self.fake.user_agent(),
                        "session_id": self.fake.uuid4()
                    }),
                    "success": random.random() > CONFIG["error_rate"]
                }

                self.time_series_data.append(event)

            current_date += timedelta(days=1)

        self.save_to_file(
            "04_time_series_data.sql",
            "events",
            self.time_series_data,
            ["id", "entity_id", "event_type", "event_time", "value", "metadata", "success"]
        )

    def generate_derived_data(self):
        """Generate any derived or calculated data"""
        print(f"Generating derived data...")

        # Example: Aggregated statistics
        aggregations = []

        for entity in self.primary_entities[:100]:  # Limit for performance
            entity_events = [e for e in self.time_series_data if e["entity_id"] == entity["id"]]

            if entity_events:
                aggregation = {
                    "entity_id": entity["id"],
                    "total_events": len(entity_events),
                    "first_event": min(e["event_time"] for e in entity_events),
                    "last_event": max(e["event_time"] for e in entity_events),
                    "success_rate": sum(1 for e in entity_events if e["success"]) / len(entity_events),
                    "avg_value": sum(e["value"] for e in entity_events if e["value"]) / max(1, sum(1 for e in entity_events if e["value"])),
                    "calculated_at": self.end_date
                }
                aggregations.append(aggregation)

        if aggregations:
            self.save_to_file(
                "05_aggregations.sql",
                "entity_aggregations",
                aggregations,
                ["entity_id", "total_events", "first_event", "last_event", "success_rate", "avg_value", "calculated_at"]
            )

    def get_weighted_hour(self):
        """Get a random hour weighted towards business/peak hours"""
        business_start, business_end = CONFIG["business_hours"]
        peak_start, peak_end = CONFIG["peak_hours"]

        # Weight distribution
        weights = []
        for hour in range(24):
            if peak_start <= hour < peak_end:
                weight = 3.0  # Peak hours
            elif business_start <= hour < business_end:
                weight = 2.0  # Business hours
            else:
                weight = 0.5  # Off hours
            weights.append(weight)

        # Normalize weights
        total_weight = sum(weights)
        weights = [w / total_weight for w in weights]

        return random.choices(range(24), weights=weights)[0]

    def save_to_file(self, filename, table_name, data, columns):
        """Save data to SQL file"""
        filepath = self.output_dir / filename

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(f"-- {table_name} table data\n")
            f.write(f"-- Generated: {datetime.now()}\n")
            f.write(f"-- Records: {len(data)}\n\n")

            if data:
                # Write INSERT statements in batches
                batch_size = 100
                for i in range(0, len(data), batch_size):
                    batch = data[i:i + batch_size]
                    f.write(f"INSERT INTO `{table_name}` ({', '.join([f'`{col}`' for col in columns])}) VALUES\n")

                    for j, record in enumerate(batch):
                        values = []
                        for col in columns:
                            val = record.get(col)
                            if val is None:
                                values.append("NULL")
                            elif isinstance(val, (int, float, bool)):
                                values.append(str(val))
                            elif isinstance(val, datetime):
                                values.append(f"'{val.strftime('%Y-%m-%d %H:%M:%S')}'")
                            else:
                                # Escape single quotes and handle special characters
                                val_str = str(val).replace("'", "''").replace("\\", "\\\\")
                                values.append(f"'{val_str}'")

                        f.write(f"({', '.join(values)})")

                        if j < len(batch) - 1:
                            f.write(",\n")
                        else:
                            f.write(";\n\n")

        print(f"  Saved {len(data)} records to {filename}")
        self.stats["total_records"] += len(data)
        self.stats["tables_generated"] += 1

    def print_summary(self):
        """Print generation summary"""
        print(f"\n{'='*50}")
        print(f"Generation Summary")
        print(f"{'='*50}")
        print(f"Tables Generated: {self.stats['tables_generated']}")
        print(f"Total Records: {self.stats['total_records']:,}")
        print(f"Generation Time: {self.stats['generation_time']:.2f} seconds")

        # Table-specific statistics
        print(f"\nTable Breakdown:")
        print(f"  Primary Entities: {len(self.primary_entities):,}")
        print(f"  Secondary Entities: {len(self.secondary_entities):,}")
        print(f"  Relationships: {len(self.relationships):,}")
        print(f"  Time-Series Events: {len(self.time_series_data):,}")

        # Business metrics
        if self.time_series_data:
            success_events = sum(1 for e in self.time_series_data if e["success"])
            print(f"\nBusiness Metrics:")
            print(f"  Success Rate: {(success_events/len(self.time_series_data)*100):.1f}%")
            print(f"  Avg Events/Entity: {len(self.time_series_data)/len(self.primary_entities):.1f}")
            print(f"  Avg Relationships/Entity: {len(self.relationships)*2/len(self.primary_entities):.1f}")

        print(f"{'='*50}\n")


def main():
    """Main entry point"""
    print(f"Starting {__file__} generator...")
    generator = YourDomainGenerator()
    generator.generate_all()
    print("[SUCCESS] Data generation complete!")


if __name__ == "__main__":
    main()