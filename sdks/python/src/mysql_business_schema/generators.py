"""
Data and schema generators for MySQL Business-to-Schema SDK
"""

import json
import random
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional, Union
from faker import Faker
import pandas as pd

from .models import Database, Table, Column, Index, ForeignKey
from .exceptions import ValidationError


class DataGenerator:
    """
    Generate test data for database schemas.
    """

    def __init__(self, client=None):
        """
        Initialize data generator.

        Args:
            client: MySQLSchemaClient instance
        """
        self.client = client
        self.faker = Faker()
        self.generated_data = {}

    def generate(
        self,
        schema_name: str,
        rows: int = 1000,
        format: str = "sql",
        seed: Optional[int] = None
    ) -> Union[str, pd.DataFrame, Dict]:
        """
        Generate test data for a schema.

        Args:
            schema_name: Name of schema/example to generate
            rows: Number of rows to generate
            format: Output format (sql, csv, json, dataframe)
            seed: Random seed for reproducibility

        Returns:
            Generated data in specified format

        Raises:
            ValidationError: If schema or format is invalid
        """
        if seed:
            random.seed(seed)
            Faker.seed(seed)

        # Get schema configuration
        schema_config = self._get_schema_config(schema_name)

        # Generate data for each table
        data = {}
        for table_name, table_config in schema_config.get("tables", {}).items():
            data[table_name] = self._generate_table_data(
                table_config, rows
            )

        # Format output
        return self._format_output(data, format, schema_name)

    def _get_schema_config(self, schema_name: str) -> Dict:
        """Get schema configuration from predefined examples."""
        schemas = {
            "clinic": self._get_clinic_schema(),
            "ecommerce": self._get_ecommerce_schema(),
            "iot": self._get_iot_schema(),
            "social_media": self._get_social_media_schema(),
        }

        if schema_name not in schemas:
            raise ValidationError(
                f"Unknown schema: {schema_name}. "
                f"Available: {', '.join(schemas.keys())}"
            )

        return schemas[schema_name]

    def _get_clinic_schema(self) -> Dict:
        """Get clinic schema configuration."""
        return {
            "name": "clinic",
            "tables": {
                "patients": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "first_name": {"type": "first_name"},
                        "last_name": {"type": "last_name"},
                        "date_of_birth": {"type": "date_of_birth"},
                        "gender": {"type": "choice", "choices": ["M", "F", "O"]},
                        "email": {"type": "email"},
                        "phone": {"type": "phone"},
                        "address": {"type": "address"},
                        "created_at": {"type": "datetime"},
                    }
                },
                "doctors": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "first_name": {"type": "first_name"},
                        "last_name": {"type": "last_name"},
                        "specialization": {
                            "type": "choice",
                            "choices": [
                                "Cardiology", "Neurology", "Pediatrics",
                                "Orthopedics", "Dermatology", "Psychiatry"
                            ]
                        },
                        "email": {"type": "email"},
                        "phone": {"type": "phone"},
                        "license_number": {"type": "uuid"},
                        "created_at": {"type": "datetime"},
                    }
                },
                "appointments": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "patient_id": {"type": "foreign_key", "reference": "patients"},
                        "doctor_id": {"type": "foreign_key", "reference": "doctors"},
                        "appointment_date": {"type": "future_datetime"},
                        "status": {
                            "type": "choice",
                            "choices": ["scheduled", "completed", "cancelled"]
                        },
                        "notes": {"type": "text"},
                        "created_at": {"type": "datetime"},
                    }
                }
            }
        }

    def _get_ecommerce_schema(self) -> Dict:
        """Get e-commerce schema configuration."""
        return {
            "name": "ecommerce",
            "tables": {
                "customers": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "username": {"type": "username"},
                        "email": {"type": "email"},
                        "first_name": {"type": "first_name"},
                        "last_name": {"type": "last_name"},
                        "created_at": {"type": "datetime"},
                    }
                },
                "products": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "name": {"type": "product_name"},
                        "description": {"type": "text"},
                        "price": {"type": "decimal", "min": 1, "max": 1000},
                        "stock": {"type": "int", "min": 0, "max": 1000},
                        "category": {
                            "type": "choice",
                            "choices": ["Electronics", "Clothing", "Food", "Books", "Toys"]
                        },
                        "created_at": {"type": "datetime"},
                    }
                },
                "orders": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "customer_id": {"type": "foreign_key", "reference": "customers"},
                        "order_date": {"type": "datetime"},
                        "total": {"type": "decimal", "min": 10, "max": 5000},
                        "status": {
                            "type": "choice",
                            "choices": ["pending", "processing", "shipped", "delivered", "cancelled"]
                        },
                        "shipping_address": {"type": "address"},
                    }
                }
            }
        }

    def _get_iot_schema(self) -> Dict:
        """Get IoT schema configuration."""
        return {
            "name": "iot",
            "tables": {
                "devices": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "device_id": {"type": "uuid"},
                        "name": {"type": "device_name"},
                        "type": {
                            "type": "choice",
                            "choices": ["sensor", "actuator", "gateway", "controller"]
                        },
                        "location": {"type": "city"},
                        "status": {
                            "type": "choice",
                            "choices": ["online", "offline", "maintenance"]
                        },
                        "created_at": {"type": "datetime"},
                    }
                },
                "readings": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "device_id": {"type": "foreign_key", "reference": "devices"},
                        "timestamp": {"type": "datetime"},
                        "temperature": {"type": "float", "min": -20, "max": 50},
                        "humidity": {"type": "float", "min": 0, "max": 100},
                        "pressure": {"type": "float", "min": 900, "max": 1100},
                        "battery": {"type": "float", "min": 0, "max": 100},
                    }
                }
            }
        }

    def _get_social_media_schema(self) -> Dict:
        """Get social media schema configuration."""
        return {
            "name": "social_media",
            "tables": {
                "users": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "username": {"type": "username"},
                        "email": {"type": "email"},
                        "display_name": {"type": "name"},
                        "bio": {"type": "text"},
                        "avatar_url": {"type": "url"},
                        "verified": {"type": "boolean"},
                        "created_at": {"type": "datetime"},
                    }
                },
                "posts": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "user_id": {"type": "foreign_key", "reference": "users"},
                        "content": {"type": "text"},
                        "likes": {"type": "int", "min": 0, "max": 10000},
                        "shares": {"type": "int", "min": 0, "max": 1000},
                        "created_at": {"type": "datetime"},
                    }
                },
                "comments": {
                    "columns": {
                        "id": {"type": "int", "primary": True},
                        "post_id": {"type": "foreign_key", "reference": "posts"},
                        "user_id": {"type": "foreign_key", "reference": "users"},
                        "content": {"type": "text"},
                        "created_at": {"type": "datetime"},
                    }
                }
            }
        }

    def _generate_table_data(self, table_config: Dict, rows: int) -> pd.DataFrame:
        """Generate data for a single table."""
        data = {}

        for column_name, column_config in table_config.get("columns", {}).items():
            data[column_name] = self._generate_column_data(
                column_config, rows
            )

        return pd.DataFrame(data)

    def _generate_column_data(self, config: Dict, rows: int) -> List[Any]:
        """Generate data for a single column."""
        data_type = config.get("type", "string")

        generators = {
            "int": lambda: [i + 1 if config.get("primary") else random.randint(
                config.get("min", 1), config.get("max", 1000000)
            ) for i in range(rows)],
            "float": lambda: [random.uniform(
                config.get("min", 0), config.get("max", 100)
            ) for _ in range(rows)],
            "decimal": lambda: [round(random.uniform(
                config.get("min", 0), config.get("max", 1000)
            ), 2) for _ in range(rows)],
            "string": lambda: [self.faker.word() for _ in range(rows)],
            "text": lambda: [self.faker.text(max_nb_chars=200) for _ in range(rows)],
            "boolean": lambda: [random.choice([True, False]) for _ in range(rows)],
            "datetime": lambda: [self.faker.date_time_between(
                start_date="-1y", end_date="now"
            ) for _ in range(rows)],
            "date": lambda: [self.faker.date_between(
                start_date="-1y", end_date="today"
            ) for _ in range(rows)],
            "future_datetime": lambda: [self.faker.date_time_between(
                start_date="now", end_date="+1y"
            ) for _ in range(rows)],
            "date_of_birth": lambda: [self.faker.date_of_birth(
                minimum_age=18, maximum_age=90
            ) for _ in range(rows)],
            "email": lambda: [self.faker.email() for _ in range(rows)],
            "username": lambda: [self.faker.user_name() for _ in range(rows)],
            "first_name": lambda: [self.faker.first_name() for _ in range(rows)],
            "last_name": lambda: [self.faker.last_name() for _ in range(rows)],
            "name": lambda: [self.faker.name() for _ in range(rows)],
            "phone": lambda: [self.faker.phone_number() for _ in range(rows)],
            "address": lambda: [self.faker.address().replace("\n", ", ") for _ in range(rows)],
            "city": lambda: [self.faker.city() for _ in range(rows)],
            "country": lambda: [self.faker.country() for _ in range(rows)],
            "url": lambda: [self.faker.url() for _ in range(rows)],
            "uuid": lambda: [self.faker.uuid4() for _ in range(rows)],
            "product_name": lambda: [self.faker.catch_phrase() for _ in range(rows)],
            "device_name": lambda: [f"Device-{self.faker.bothify('??##')}" for _ in range(rows)],
            "choice": lambda: [random.choice(config["choices"]) for _ in range(rows)],
            "foreign_key": lambda: [random.randint(1, rows) for _ in range(rows)],
        }

        generator = generators.get(data_type, generators["string"])
        return generator()

    def _format_output(
        self,
        data: Dict[str, pd.DataFrame],
        format: str,
        schema_name: str
    ) -> Union[str, Dict, pd.DataFrame]:
        """Format generated data for output."""
        if format == "sql":
            return self._to_sql(data, schema_name)
        elif format == "csv":
            return self._to_csv(data)
        elif format == "json":
            return self._to_json(data)
        elif format == "dataframe":
            return data
        else:
            raise ValidationError(f"Unsupported format: {format}")

    def _to_sql(self, data: Dict[str, pd.DataFrame], schema_name: str) -> str:
        """Convert data to SQL INSERT statements."""
        sql = f"-- Generated data for {schema_name} schema\n"
        sql += f"-- Generated at {datetime.now()}\n\n"

        for table_name, df in data.items():
            sql += f"-- Table: {table_name}\n"
            for _, row in df.iterrows():
                columns = ", ".join([f"`{col}`" for col in df.columns])
                values = ", ".join([self._format_sql_value(val) for val in row])
                sql += f"INSERT INTO `{table_name}` ({columns}) VALUES ({values});\n"
            sql += "\n"

        return sql

    def _format_sql_value(self, value: Any) -> str:
        """Format value for SQL."""
        if pd.isna(value) or value is None:
            return "NULL"
        elif isinstance(value, (int, float)):
            return str(value)
        elif isinstance(value, bool):
            return "1" if value else "0"
        elif isinstance(value, datetime):
            return f"'{value.strftime('%Y-%m-%d %H:%M:%S')}'"
        else:
            # Escape single quotes
            value = str(value).replace("'", "''")
            return f"'{value}'"

    def _to_csv(self, data: Dict[str, pd.DataFrame]) -> Dict[str, str]:
        """Convert data to CSV format."""
        csv_data = {}
        for table_name, df in data.items():
            csv_data[table_name] = df.to_csv(index=False)
        return csv_data

    def _to_json(self, data: Dict[str, pd.DataFrame]) -> str:
        """Convert data to JSON format."""
        json_data = {}
        for table_name, df in data.items():
            # Convert datetime objects to strings
            df_copy = df.copy()
            for col in df_copy.columns:
                if df_copy[col].dtype == 'datetime64[ns]' or isinstance(df_copy[col].iloc[0], datetime):
                    df_copy[col] = df_copy[col].astype(str)
            json_data[table_name] = df_copy.to_dict(orient="records")
        return json.dumps(json_data, indent=2, default=str)


class SchemaGenerator:
    """
    Generate database schemas from templates or specifications.
    """

    def __init__(self, client=None):
        """
        Initialize schema generator.

        Args:
            client: MySQLSchemaClient instance
        """
        self.client = client

    def generate_from_template(
        self,
        template_name: str,
        database_name: str,
        **kwargs
    ) -> Database:
        """
        Generate schema from predefined template.

        Args:
            template_name: Name of template
            database_name: Name for generated database
            **kwargs: Template-specific parameters

        Returns:
            Generated Database object
        """
        templates = {
            "microservice": self._generate_microservice_schema,
            "data_warehouse": self._generate_data_warehouse_schema,
            "time_series": self._generate_time_series_schema,
            "multi_tenant": self._generate_multi_tenant_schema,
        }

        if template_name not in templates:
            raise ValidationError(
                f"Unknown template: {template_name}. "
                f"Available: {', '.join(templates.keys())}"
            )

        return templates[template_name](database_name, **kwargs)

    def _generate_microservice_schema(
        self,
        database_name: str,
        include_audit: bool = True,
        **kwargs
    ) -> Database:
        """Generate microservice database schema."""
        tables = []

        # Base entity table
        tables.append(Table(
            name="entities",
            columns=[
                Column(name="id", type="BIGINT", is_primary=True, auto_increment=True),
                Column(name="uuid", type="VARCHAR(36)", is_unique=True, nullable=False),
                Column(name="type", type="VARCHAR(50)", nullable=False),
                Column(name="data", type="JSON"),
                Column(name="version", type="INT", default_value=1),
                Column(name="created_at", type="TIMESTAMP", default_value="CURRENT_TIMESTAMP"),
                Column(name="updated_at", type="TIMESTAMP", default_value="CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"),
            ],
            indexes=[
                Index(name="idx_uuid", columns=["uuid"]),
                Index(name="idx_type", columns=["type"]),
                Index(name="idx_created", columns=["created_at"]),
            ]
        ))

        # Events table for event sourcing
        tables.append(Table(
            name="events",
            columns=[
                Column(name="id", type="BIGINT", is_primary=True, auto_increment=True),
                Column(name="aggregate_id", type="VARCHAR(36)", nullable=False),
                Column(name="event_type", type="VARCHAR(100)", nullable=False),
                Column(name="event_data", type="JSON"),
                Column(name="event_version", type="INT", nullable=False),
                Column(name="created_at", type="TIMESTAMP", default_value="CURRENT_TIMESTAMP"),
            ],
            indexes=[
                Index(name="idx_aggregate", columns=["aggregate_id"]),
                Index(name="idx_event_type", columns=["event_type"]),
            ]
        ))

        # Audit log table
        if include_audit:
            tables.append(Table(
                name="audit_log",
                columns=[
                    Column(name="id", type="BIGINT", is_primary=True, auto_increment=True),
                    Column(name="user_id", type="VARCHAR(50)"),
                    Column(name="action", type="VARCHAR(50)", nullable=False),
                    Column(name="entity_type", type="VARCHAR(50)"),
                    Column(name="entity_id", type="VARCHAR(36)"),
                    Column(name="old_data", type="JSON"),
                    Column(name="new_data", type="JSON"),
                    Column(name="ip_address", type="VARCHAR(45)"),
                    Column(name="user_agent", type="TEXT"),
                    Column(name="created_at", type="TIMESTAMP", default_value="CURRENT_TIMESTAMP"),
                ],
                indexes=[
                    Index(name="idx_user", columns=["user_id"]),
                    Index(name="idx_entity", columns=["entity_type", "entity_id"]),
                    Index(name="idx_created_audit", columns=["created_at"]),
                ]
            ))

        return Database(
            name=database_name,
            tables=tables,
            charset="utf8mb4",
            collation="utf8mb4_unicode_ci"
        )

    def _generate_data_warehouse_schema(
        self,
        database_name: str,
        **kwargs
    ) -> Database:
        """Generate data warehouse schema with fact and dimension tables."""
        # Implementation for data warehouse schema
        pass

    def _generate_time_series_schema(
        self,
        database_name: str,
        **kwargs
    ) -> Database:
        """Generate time series database schema."""
        # Implementation for time series schema
        pass

    def _generate_multi_tenant_schema(
        self,
        database_name: str,
        **kwargs
    ) -> Database:
        """Generate multi-tenant database schema."""
        # Implementation for multi-tenant schema
        pass