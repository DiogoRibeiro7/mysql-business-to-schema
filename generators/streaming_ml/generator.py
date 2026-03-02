#!/usr/bin/env python3
"""
Streaming ML Platform Data Generator
Generates realistic data for machine learning pipelines with feature stores,
model registry, experiments, and streaming data processing
"""

import csv
import json
import random
import hashlib
import uuid
from datetime import datetime, timedelta, date
from decimal import Decimal
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
    "organizations": 5,
    "projects_per_org": 3,
    "streams_per_project": 4,
    "features_per_project": 20,
    "experiments_per_project": 10,
    "models_per_project": 5,
    "ab_tests_per_project": 3,
    "days_of_history": 30,
    "events_per_stream_per_day": 1000,
    "predictions_per_model_per_day": 500,
}


class StreamingMLGenerator:
    def __init__(self):
        # Organizations and projects
        self.organizations: List[Any] = []
        self.projects: List[Any] = []

        # Data streams
        self.data_streams: List[Any] = []
        self.stream_pipelines: List[Any] = []
        self.stream_events: List[Any] = []

        # Feature store
        self.feature_definitions: List[Any] = []
        self.raw_features: List[Any] = []
        self.feature_computations: List[Any] = []
        self.feature_sets: List[Any] = []

        # Experiments and models
        self.experiments: List[Any] = []
        self.experiment_runs: List[Any] = []
        self.run_metrics: List[Any] = []
        self.models: List[Any] = []
        self.model_evaluations: List[Any] = []
        self.model_comparisons: List[Any] = []
        self.model_deployments: List[Any] = []

        # A/B testing
        self.ab_tests: List[Any] = []

        # Predictions and monitoring
        self.predictions: List[Any] = []
        self.ground_truth: List[Any] = []
        self.drift_detection: List[Any] = []
        self.performance_metrics: List[Any] = []
        self.model_alerts: List[Any] = []

        # Infrastructure
        self.compute_resources: List[Any] = []
        self.resource_allocations: List[Any] = []

        # Data governance
        self.data_lineage: List[Any] = []
        self.data_quality_rules: List[Any] = []
        self.data_quality_violations: List[Any] = []

        # Usage tracking
        self.user_activity: List[Any] = []
        self.api_usage: List[Any] = []

        # Counters
        self.project_id = 0
        self.stream_id = 0
        self.pipeline_id = 0
        self.event_id = 0
        self.feature_id = 0
        self.raw_feature_id = 0
        self.computation_id = 0
        self.feature_set_id = 0
        self.experiment_id = 0
        self.run_id = 0
        self.metric_id = 0
        self.model_id = 0
        self.evaluation_id = 0
        self.comparison_id = 0
        self.deployment_id = 0
        self.test_id = 0
        self.prediction_id = 0
        self.ground_truth_id = 0
        self.drift_id = 0
        self.perf_metric_id = 0
        self.alert_id = 0
        self.resource_id = 0
        self.allocation_id = 0
        self.lineage_id = 0
        self.rule_id = 0
        self.violation_id = 0
        self.activity_id = 0
        self.api_usage_id = 0

        # Start date for historical data
        self.start_date = datetime.now() - timedelta(days=CONFIG["days_of_history"])

    def generate_all(self):
        """Generate all streaming ML platform data"""
        print("Starting Streaming ML Platform Data Generation...")
        print(f"Configuration:")
        print(f"  Organizations: {CONFIG['organizations']}")
        print(
            f"  Total projects: {CONFIG['organizations'] * CONFIG['projects_per_org']}"
        )
        print(
            f"  Total streams: {CONFIG['organizations'] * CONFIG['projects_per_org'] * CONFIG['streams_per_project']}"
        )
        print(f"  Days of history: {CONFIG['days_of_history']}")

        # Core infrastructure
        self.generate_organizations()
        self.generate_projects()

        # Data streams
        self.generate_data_streams()
        self.generate_stream_pipelines()
        self.generate_stream_events()

        # Feature engineering
        self.generate_feature_definitions()
        self.generate_raw_features()
        self.generate_feature_computations()
        self.generate_feature_sets()

        # ML experiments
        self.generate_experiments()
        self.generate_experiment_runs()
        self.generate_run_metrics()

        # Models
        self.generate_models()
        self.generate_model_evaluations()
        self.generate_model_comparisons()
        self.generate_model_deployments()

        # A/B testing
        self.generate_ab_tests()

        # Predictions and monitoring
        self.generate_predictions()
        self.generate_ground_truth()
        self.generate_drift_detection()
        self.generate_performance_metrics()
        self.generate_model_alerts()

        # Infrastructure
        self.generate_compute_resources()
        self.generate_resource_allocations()

        # Data governance
        self.generate_data_lineage()
        self.generate_data_quality_rules()
        self.generate_data_quality_violations()

        # Usage tracking
        self.generate_user_activity()
        self.generate_api_usage()

        # Save all data
        self.save_all()

    def generate_organizations(self):
        """Generate organizations"""
        print(f"Generating {CONFIG['organizations']} organizations...")

        org_names = [
            "DataCorp AI",
            "ML Innovations",
            "Analytics Pro",
            "DeepTech Solutions",
            "AI Research Lab",
        ]
        tiers = ["Free", "Basic", "Pro", "Enterprise"]

        for i in range(CONFIG["organizations"]):
            org_type = random.choice(["Enterprise", "Startup", "Research", "Education"])
            tier = "Enterprise" if org_type == "Enterprise" else random.choice(tiers)

            self.organizations.append(
                {
                    "org_id": i + 1,
                    "org_name": (
                        org_names[i] if i < len(org_names) else f"ML Organization {i+1}"
                    ),
                    "org_type": org_type,
                    "contact_email": fake.company_email(),
                    "api_key": hashlib.sha256(f"API{i+1}".encode()).hexdigest(),
                    "subscription_tier": tier,
                    "max_models": (
                        100
                        if tier == "Enterprise"
                        else 50 if tier == "Pro" else 20 if tier == "Basic" else 10
                    ),
                    "max_deployments": (
                        50
                        if tier == "Enterprise"
                        else 20 if tier == "Pro" else 10 if tier == "Basic" else 5
                    ),
                    "max_streams": (
                        100
                        if tier == "Enterprise"
                        else 50 if tier == "Pro" else 20 if tier == "Basic" else 10
                    ),
                    "created_at": datetime.now()
                    - timedelta(days=random.randint(100, 500)),
                    "updated_at": datetime.now(),
                }
            )

    def generate_projects(self):
        """Generate ML projects"""
        print("Generating ML projects...")

        project_types = [
            "Classification",
            "Regression",
            "Clustering",
            "Anomaly Detection",
            "Recommendation",
            "NLP",
            "Computer Vision",
            "Time Series",
        ]

        for org in self.organizations:
            for j in range(CONFIG["projects_per_org"]):
                self.project_id += 1

                project_type = random.choice(project_types)

                # Generate project name based on type
                if project_type == "Classification":
                    name = random.choice(
                        [
                            "Customer Churn Prediction",
                            "Fraud Detection",
                            "Email Classification",
                        ]
                    )
                elif project_type == "Regression":
                    name = random.choice(
                        ["Sales Forecasting", "Price Prediction", "Demand Estimation"]
                    )
                elif project_type == "Recommendation":
                    name = random.choice(
                        [
                            "Product Recommendations",
                            "Content Personalization",
                            "User Matching",
                        ]
                    )
                elif project_type == "NLP":
                    name = random.choice(
                        [
                            "Sentiment Analysis",
                            "Text Classification",
                            "Named Entity Recognition",
                        ]
                    )
                elif project_type == "Computer Vision":
                    name = random.choice(
                        ["Object Detection", "Image Classification", "Face Recognition"]
                    )
                elif project_type == "Time Series":
                    name = random.choice(
                        [
                            "Stock Price Prediction",
                            "Weather Forecasting",
                            "Traffic Prediction",
                        ]
                    )
                elif project_type == "Anomaly Detection":
                    name = random.choice(
                        [
                            "System Anomaly Detection",
                            "Fraud Detection",
                            "Network Intrusion",
                        ]
                    )
                else:
                    name = f"{project_type} Project {j+1}"

                self.projects.append(
                    {
                        "project_id": self.project_id,
                        "org_id": org["org_id"],
                        "project_name": f"{name} v{j+1}",
                        "project_description": f"ML project for {name.lower()} using {project_type.lower()} techniques",
                        "project_type": project_type,
                        "status": random.choices(
                            ["Active", "Paused", "Archived"], weights=[0.7, 0.2, 0.1]
                        )[0],
                        "created_by": fake.name(),
                        "created_at": org["created_at"]
                        + timedelta(days=random.randint(1, 30)),
                        "updated_at": datetime.now(),
                    }
                )

    def generate_data_streams(self):
        """Generate data stream configurations"""
        print("Generating data streams...")

        stream_types = ["Kafka", "Kinesis", "PubSub", "WebSocket", "HTTP", "Database"]
        data_formats = ["JSON", "Avro", "Protobuf", "CSV", "Parquet"]

        for project in self.projects:
            for s in range(CONFIG["streams_per_project"]):
                self.stream_id += 1

                stream_type = random.choice(stream_types)

                # Generate connection config based on stream type
                if stream_type == "Kafka":
                    config = {
                        "bootstrap_servers": "kafka1:9092,kafka2:9092",
                        "topic": f"ml_data_{self.stream_id}",
                        "consumer_group": f"ml_consumer_{self.stream_id}",
                    }
                elif stream_type == "Kinesis":
                    config = {
                        "stream_name": f"ml-stream-{self.stream_id}",
                        "region": "us-east-1",
                        "access_key": "AKIA...",
                        "secret_key": "***",
                    }
                elif stream_type == "Database":
                    config = {
                        "host": "db.example.com",
                        "database": f"analytics_{project['project_id']}",
                        "table": f"events_{self.stream_id}",
                        "poll_interval_ms": 5000,
                    }
                else:
                    config = {
                        "endpoint": f"https://api.example.com/stream/{self.stream_id}",
                        "auth_token": "***",
                    }

                # Generate schema definition
                schema = {
                    "fields": [
                        {"name": "timestamp", "type": "timestamp"},
                        {"name": "user_id", "type": "string"},
                        {"name": "event_type", "type": "string"},
                        {"name": "properties", "type": "object"},
                    ]
                }

                self.data_streams.append(
                    {
                        "stream_id": self.stream_id,
                        "project_id": project["project_id"],
                        "stream_name": f"Stream_{stream_type}_{s+1}",
                        "stream_type": stream_type,
                        "connection_config": json.dumps(config),
                        "schema_definition": json.dumps(schema),
                        "data_format": random.choice(data_formats),
                        "batch_size": random.choice([100, 500, 1000]),
                        "buffer_time_ms": random.choice([1000, 5000, 10000]),
                        "is_active": random.random() > 0.1,
                        "last_connected": datetime.now()
                        - timedelta(hours=random.randint(0, 24)),
                        "created_at": project["created_at"]
                        + timedelta(days=random.randint(1, 7)),
                        "updated_at": datetime.now(),
                    }
                )

    def generate_stream_pipelines(self):
        """Generate stream processing pipelines"""
        print("Generating stream pipelines...")

        processing_types = ["Batch", "Micro-batch", "Real-time"]
        window_types = ["Tumbling", "Sliding", "Session", "None"]

        for stream in self.data_streams:
            # 1-2 pipelines per stream
            num_pipelines = random.randint(1, 2)

            for p in range(num_pipelines):
                self.pipeline_id += 1

                processing_type = random.choice(processing_types)
                window_type = random.choice(window_types)

                # Generate pipeline configuration
                config = {
                    "transformations": [
                        {"type": "filter", "condition": "event_type != null"},
                        {"type": "map", "function": "extract_features"},
                        {"type": "aggregate", "function": "sum", "window": "5min"},
                    ],
                    "output": {"sink": "feature_store", "format": "parquet"},
                }

                self.stream_pipelines.append(
                    {
                        "pipeline_id": self.pipeline_id,
                        "stream_id": stream["stream_id"],
                        "pipeline_name": f"Pipeline_{processing_type}_{p+1}",
                        "pipeline_config": json.dumps(config),
                        "processing_type": processing_type,
                        "window_type": window_type,
                        "window_size_seconds": (
                            random.choice([60, 300, 600])
                            if window_type != "None"
                            else None
                        ),
                        "watermark_delay_seconds": (
                            random.choice([10, 30, 60])
                            if window_type != "None"
                            else None
                        ),
                        "is_active": stream["is_active"],
                        "created_at": stream["created_at"] + timedelta(days=1),
                        "updated_at": datetime.now(),
                    }
                )

    def generate_stream_events(self):
        """Generate stream events (limited for demo)"""
        print("Generating stream events (limited for demo)...")

        # Generate events for active streams only, limited quantity
        active_streams = [s for s in self.data_streams if s["is_active"]][:5]

        current_date = self.start_date
        end_date = datetime.now()

        for stream in active_streams:
            # Generate 100 events per stream for demo
            for _ in range(100):
                self.event_id += 1

                event_time = fake.date_time_between(
                    start_date=current_date, end_date=end_date
                )

                # Generate event data based on project type
                project = next(
                    p for p in self.projects if p["project_id"] == stream["project_id"]
                )

                if project["project_type"] == "Classification":
                    event_data = {
                        "user_id": f"user_{random.randint(1, 1000)}",
                        "features": {
                            "age": random.randint(18, 80),
                            "activity_score": random.uniform(0, 100),
                            "days_since_signup": random.randint(1, 365),
                        },
                        "label": random.choice([0, 1]),
                    }
                elif project["project_type"] == "Time Series":
                    event_data = {
                        "sensor_id": f"sensor_{random.randint(1, 100)}",
                        "value": random.uniform(0, 100),
                        "temperature": random.uniform(15, 35),
                        "humidity": random.uniform(30, 80),
                    }
                else:
                    event_data = {
                        "id": str(uuid.uuid4()),
                        "value": random.uniform(0, 1000),
                        "category": random.choice(["A", "B", "C"]),
                    }

                self.stream_events.append(
                    {
                        "event_id": self.event_id,
                        "stream_id": stream["stream_id"],
                        "event_timestamp": event_time,
                        "event_data": json.dumps(event_data),
                        "event_metadata": json.dumps(
                            {"source": "generator", "version": "1.0"}
                        ),
                        "processing_status": random.choices(
                            ["Processed", "Processing", "Pending", "Failed"],
                            weights=[0.7, 0.1, 0.15, 0.05],
                        )[0],
                        "error_message": (
                            "Processing timeout" if random.random() < 0.05 else None
                        ),
                        "created_at": event_time,
                    }
                )

    def generate_feature_definitions(self):
        """Generate feature definitions"""
        print("Generating feature definitions...")

        data_types = ["INT", "FLOAT", "STRING", "BOOLEAN", "TIMESTAMP", "ARRAY"]
        computation_types = [
            "Raw",
            "Aggregation",
            "Transformation",
            "Embedding",
            "Derived",
        ]

        feature_groups = {
            "user": ["age", "gender", "location", "signup_date", "activity_score"],
            "transaction": [
                "amount",
                "merchant",
                "category",
                "time_of_day",
                "day_of_week",
            ],
            "product": ["price", "category", "brand", "rating", "reviews_count"],
            "behavioral": ["click_rate", "view_time", "bounce_rate", "conversion_rate"],
            "temporal": ["hour", "day", "week", "month", "season"],
        }

        for project in self.projects:
            # Select relevant feature groups based on project type
            if project["project_type"] in ["Classification", "Regression"]:
                groups = ["user", "behavioral", "temporal"]
            elif project["project_type"] == "Recommendation":
                groups = ["user", "product", "behavioral"]
            elif project["project_type"] == "Time Series":
                groups = ["temporal", "transaction"]
            else:
                groups = random.sample(list(feature_groups.keys()), 2)

            for group in groups:
                for feature_name in feature_groups[group]:
                    self.feature_id += 1

                    # Determine data type based on feature name
                    if "date" in feature_name or "time" in feature_name:
                        data_type = "TIMESTAMP"
                    elif (
                        "score" in feature_name
                        or "rate" in feature_name
                        or "price" in feature_name
                    ):
                        data_type = "FLOAT"
                    elif "count" in feature_name or "age" in feature_name:
                        data_type = "INT"
                    elif feature_name in [
                        "gender",
                        "location",
                        "category",
                        "merchant",
                        "brand",
                    ]:
                        data_type = "STRING"
                    else:
                        data_type = random.choice(data_types)

                    self.feature_definitions.append(
                        {
                            "feature_id": self.feature_id,
                            "project_id": project["project_id"],
                            "feature_name": f"{group}_{feature_name}",
                            "feature_group": group,
                            "description": f"{feature_name.replace('_', ' ').title()} feature for {group}",
                            "data_type": data_type,
                            "computation_type": random.choice(computation_types),
                            "computation_logic": json.dumps(
                                {
                                    "source": f"{group}_stream",
                                    "field": feature_name,
                                    "transformation": (
                                        "normalize" if data_type == "FLOAT" else None
                                    ),
                                }
                            ),
                            "version": 1,
                            "is_active": True,
                            "created_at": project["created_at"]
                            + timedelta(days=random.randint(1, 10)),
                            "updated_at": datetime.now(),
                        }
                    )

    def generate_raw_features(self):
        """Generate raw feature values"""
        print("Generating raw features...")

        # Generate raw features for each feature definition (limited for demo)
        for feature in self.feature_definitions[:50]:
            # Generate daily values for the history period
            current_date = self.start_date

            while current_date <= datetime.now():
                self.raw_feature_id += 1

                # Generate value based on data type
                if feature["data_type"] == "INT":
                    value = str(random.randint(0, 100))
                elif feature["data_type"] == "FLOAT":
                    value = str(round(random.uniform(0, 100), 4))
                elif feature["data_type"] == "STRING":
                    value = random.choice(["A", "B", "C", "D"])
                elif feature["data_type"] == "BOOLEAN":
                    value = str(random.choice([True, False]))
                elif feature["data_type"] == "TIMESTAMP":
                    value = current_date.isoformat()
                else:
                    value = str(random.uniform(0, 1))

                self.raw_features.append(
                    {
                        "raw_feature_id": self.raw_feature_id,
                        "feature_id": feature["feature_id"],
                        "entity_id": f"entity_{random.randint(1, 100)}",
                        "feature_value": value,
                        "timestamp": current_date,
                        "quality_score": random.uniform(0.8, 1.0),
                        "created_at": current_date,
                    }
                )

                current_date += timedelta(hours=random.randint(1, 24))

    def generate_feature_computations(self):
        """Generate feature computation jobs"""
        print("Generating feature computations...")

        computation_statuses = ["Running", "Completed", "Failed", "Scheduled"]

        for feature in self.feature_definitions:
            # Generate computation jobs
            num_computations = random.randint(1, 3)

            for _ in range(num_computations):
                self.computation_id += 1

                start_time = fake.date_time_between(
                    start_date=self.start_date, end_date="now"
                )
                status = random.choice(computation_statuses)

                if status == "Completed":
                    end_time = start_time + timedelta(minutes=random.randint(5, 60))
                    records = random.randint(1000, 100000)
                elif status == "Failed":
                    end_time = start_time + timedelta(minutes=random.randint(1, 10))
                    records = 0
                else:
                    end_time = None
                    records = 0

                self.feature_computations.append(
                    {
                        "computation_id": self.computation_id,
                        "feature_id": feature["feature_id"],
                        "start_time": start_time,
                        "end_time": end_time,
                        "status": status,
                        "records_processed": records,
                        "error_message": (
                            "Memory limit exceeded" if status == "Failed" else None
                        ),
                        "compute_cost": (
                            round(random.uniform(0.01, 1.0), 4)
                            if status == "Completed"
                            else 0
                        ),
                        "created_at": start_time,
                    }
                )

    def generate_feature_sets(self):
        """Generate feature sets for training"""
        print("Generating feature sets...")

        for project in self.projects:
            project_features = [
                f
                for f in self.feature_definitions
                if f["project_id"] == project["project_id"]
            ]

            if not project_features:
                continue

            # Create 2-3 feature sets per project
            num_sets = random.randint(2, 3)

            for s in range(num_sets):
                self.feature_set_id += 1

                # Select random subset of features
                selected_features = random.sample(
                    project_features, min(len(project_features), random.randint(5, 15))
                )

                self.feature_sets.append(
                    {
                        "feature_set_id": self.feature_set_id,
                        "project_id": project["project_id"],
                        "set_name": f"FeatureSet_v{s+1}",
                        "description": f"Feature set version {s+1} for {project['project_name']}",
                        "feature_ids": json.dumps(
                            [f["feature_id"] for f in selected_features]
                        ),
                        "version": s + 1,
                        "is_active": s == num_sets - 1,  # Latest version is active
                        "created_by": fake.name(),
                        "created_at": project["created_at"] + timedelta(days=s * 10),
                    }
                )

    def generate_experiments(self):
        """Generate ML experiments"""
        print("Generating experiments...")

        for project in self.projects:
            for e in range(CONFIG["experiments_per_project"]):
                self.experiment_id += 1

                # Get feature sets for this project
                project_sets = [
                    fs
                    for fs in self.feature_sets
                    if fs["project_id"] == project["project_id"]
                ]
                feature_set = random.choice(project_sets) if project_sets else None

                # Generate experiment config based on project type
                if project["project_type"] == "Classification":
                    algorithms = [
                        "LogisticRegression",
                        "RandomForest",
                        "XGBoost",
                        "NeuralNetwork",
                    ]
                    metrics = ["accuracy", "precision", "recall", "f1", "auc"]
                elif project["project_type"] == "Regression":
                    algorithms = [
                        "LinearRegression",
                        "RandomForest",
                        "GradientBoosting",
                        "NeuralNetwork",
                    ]
                    metrics = ["mse", "rmse", "mae", "r2"]
                elif project["project_type"] == "Clustering":
                    algorithms = ["KMeans", "DBSCAN", "HierarchicalClustering"]
                    metrics = ["silhouette", "davies_bouldin", "calinski_harabasz"]
                else:
                    algorithms = ["CustomModel1", "CustomModel2"]
                    metrics = ["custom_metric"]

                config = {
                    "algorithm": random.choice(algorithms),
                    "hyperparameters": {
                        "learning_rate": random.uniform(0.001, 0.1),
                        "max_depth": random.randint(3, 10),
                        "n_estimators": random.randint(50, 200),
                    },
                    "validation_split": 0.2,
                    "cross_validation_folds": 5,
                }

                self.experiments.append(
                    {
                        "experiment_id": self.experiment_id,
                        "project_id": project["project_id"],
                        "experiment_name": f"Exp_{e+1}_{config['algorithm']}",
                        "description": f"Experiment with {config['algorithm']} algorithm",
                        "feature_set_id": (
                            feature_set["feature_set_id"] if feature_set else None
                        ),
                        "model_type": config["algorithm"],
                        "experiment_config": json.dumps(config),
                        "target_metric": random.choice(metrics),
                        "status": random.choice(
                            ["Completed", "Running", "Failed", "Scheduled"]
                        ),
                        "created_by": fake.name(),
                        "created_at": project["created_at"] + timedelta(days=e * 3),
                        "updated_at": datetime.now(),
                    }
                )

    def generate_experiment_runs(self):
        """Generate experiment runs"""
        print("Generating experiment runs...")

        for experiment in self.experiments:
            # Generate 1-5 runs per experiment
            num_runs = random.randint(1, 5)

            for r in range(num_runs):
                self.run_id += 1

                start_time = experiment["created_at"] + timedelta(hours=r * 2)

                if experiment["status"] == "Completed":
                    end_time = start_time + timedelta(hours=random.uniform(0.5, 4))
                    status = "Completed"
                elif experiment["status"] == "Failed":
                    end_time = start_time + timedelta(minutes=random.randint(5, 30))
                    status = "Failed"
                else:
                    end_time = None
                    status = experiment["status"]

                # Generate run parameters
                parameters = {
                    "learning_rate": round(random.uniform(0.001, 0.1), 4),
                    "batch_size": random.choice([32, 64, 128, 256]),
                    "epochs": random.randint(10, 100),
                    "optimizer": random.choice(["adam", "sgd", "rmsprop"]),
                }

                self.experiment_runs.append(
                    {
                        "run_id": self.run_id,
                        "experiment_id": experiment["experiment_id"],
                        "run_name": f"Run_{r+1}",
                        "parameters": json.dumps(parameters),
                        "start_time": start_time,
                        "end_time": end_time,
                        "status": status,
                        "git_commit": hashlib.sha1(
                            f"commit_{self.run_id}".encode()
                        ).hexdigest()[:8],
                        "artifact_location": f"s3://ml-artifacts/exp_{experiment['experiment_id']}/run_{self.run_id}/",
                        "created_at": start_time,
                    }
                )

    def generate_run_metrics(self):
        """Generate metrics for experiment runs"""
        print("Generating run metrics...")

        for run in self.experiment_runs:
            if run["status"] != "Completed":
                continue

            experiment = next(
                e
                for e in self.experiments
                if e["experiment_id"] == run["experiment_id"]
            )
            project = next(
                p for p in self.projects if p["project_id"] == experiment["project_id"]
            )

            # Generate metrics based on project type
            if project["project_type"] == "Classification":
                metrics = {
                    "accuracy": random.uniform(0.7, 0.95),
                    "precision": random.uniform(0.6, 0.95),
                    "recall": random.uniform(0.6, 0.95),
                    "f1_score": random.uniform(0.65, 0.95),
                    "auc_roc": random.uniform(0.7, 0.99),
                }
            elif project["project_type"] == "Regression":
                metrics = {
                    "mse": random.uniform(0.01, 1.0),
                    "rmse": random.uniform(0.1, 1.0),
                    "mae": random.uniform(0.05, 0.8),
                    "r2": random.uniform(0.6, 0.99),
                }
            else:
                metrics = {
                    "metric_1": random.uniform(0, 100),
                    "metric_2": random.uniform(0, 1),
                }

            for metric_name, metric_value in metrics.items():
                self.metric_id += 1

                self.run_metrics.append(
                    {
                        "metric_id": self.metric_id,
                        "run_id": run["run_id"],
                        "metric_name": metric_name,
                        "metric_value": round(metric_value, 4),
                        "step": random.randint(1, 100),
                        "timestamp": (
                            run["end_time"] if run["end_time"] else datetime.now()
                        ),
                        "created_at": run["created_at"],
                    }
                )

    def generate_models(self):
        """Generate ML models"""
        print("Generating models...")

        for project in self.projects:
            # Get completed experiments for this project
            completed_experiments = [
                e
                for e in self.experiments
                if e["project_id"] == project["project_id"]
                and e["status"] == "Completed"
            ]

            if not completed_experiments:
                continue

            for m in range(
                min(CONFIG["models_per_project"], len(completed_experiments))
            ):
                self.model_id += 1

                experiment = completed_experiments[m % len(completed_experiments)]
                best_run = random.choice(
                    [
                        r
                        for r in self.experiment_runs
                        if r["experiment_id"] == experiment["experiment_id"]
                        and r["status"] == "Completed"
                    ]
                )

                self.models.append(
                    {
                        "model_id": self.model_id,
                        "project_id": project["project_id"],
                        "model_name": f"{project['project_name']}_Model_v{m+1}",
                        "model_version": m + 1,
                        "experiment_id": experiment["experiment_id"],
                        "run_id": best_run["run_id"] if best_run else None,
                        "model_type": experiment["model_type"],
                        "framework": random.choice(
                            ["TensorFlow", "PyTorch", "Scikit-learn", "XGBoost"]
                        ),
                        "model_size_mb": round(random.uniform(10, 1000), 2),
                        "model_location": f"s3://models/project_{project['project_id']}/model_{self.model_id}/",
                        "tags": json.dumps(
                            ["production-ready", "validated"]
                            if m == 0
                            else ["experimental"]
                        ),
                        "status": random.choice(["Active", "Archived", "Deprecated"]),
                        "created_by": fake.name(),
                        "created_at": experiment["created_at"]
                        + timedelta(days=random.randint(1, 10)),
                    }
                )

    def generate_model_evaluations(self):
        """Generate model evaluations"""
        print("Generating model evaluations...")

        for model in self.models:
            # Generate 1-3 evaluations per model
            num_evaluations = random.randint(1, 3)

            for e in range(num_evaluations):
                self.evaluation_id += 1

                eval_date = model["created_at"] + timedelta(days=e * 7)

                # Generate evaluation metrics
                project = next(
                    p for p in self.projects if p["project_id"] == model["project_id"]
                )

                if project["project_type"] == "Classification":
                    metrics = {
                        "test_accuracy": random.uniform(0.7, 0.95),
                        "test_precision": random.uniform(0.6, 0.95),
                        "test_recall": random.uniform(0.6, 0.95),
                        "confusion_matrix": [
                            [random.randint(100, 1000) for _ in range(2)]
                            for _ in range(2)
                        ],
                    }
                else:
                    metrics = {
                        "test_mse": random.uniform(0.01, 1.0),
                        "test_r2": random.uniform(0.6, 0.99),
                    }

                self.model_evaluations.append(
                    {
                        "evaluation_id": self.evaluation_id,
                        "model_id": model["model_id"],
                        "evaluation_date": eval_date,
                        "dataset_name": f"test_dataset_v{e+1}",
                        "dataset_size": random.randint(1000, 100000),
                        "metrics": json.dumps(metrics),
                        "evaluation_notes": f"Evaluation on {random.choice(['production', 'staging', 'test'])} data",
                        "created_by": fake.name(),
                        "created_at": eval_date,
                    }
                )

    def generate_model_comparisons(self):
        """Generate model comparisons"""
        print("Generating model comparisons...")

        for project in self.projects:
            project_models = [
                m for m in self.models if m["project_id"] == project["project_id"]
            ]

            if len(project_models) < 2:
                continue

            # Compare pairs of models
            for i in range(min(3, len(project_models) - 1)):
                self.comparison_id += 1

                model_a = project_models[i]
                model_b = project_models[i + 1]

                comparison_date = max(
                    model_a["created_at"], model_b["created_at"]
                ) + timedelta(days=1)

                # Generate comparison results
                winner = random.choice([model_a["model_id"], model_b["model_id"], None])

                self.model_comparisons.append(
                    {
                        "comparison_id": self.comparison_id,
                        "model_a_id": model_a["model_id"],
                        "model_b_id": model_b["model_id"],
                        "comparison_date": comparison_date,
                        "comparison_metrics": json.dumps(
                            {
                                "metric": "accuracy",
                                "model_a_score": random.uniform(0.7, 0.95),
                                "model_b_score": random.uniform(0.7, 0.95),
                                "p_value": random.uniform(0.01, 0.1),
                            }
                        ),
                        "winner_model_id": winner,
                        "comparison_notes": "Statistical significance test performed",
                        "created_by": fake.name(),
                        "created_at": comparison_date,
                    }
                )

    def generate_model_deployments(self):
        """Generate model deployments"""
        print("Generating model deployments...")

        deployment_environments = ["Production", "Staging", "Development", "Testing"]
        deployment_strategies = ["Blue-Green", "Canary", "Rolling", "Direct"]

        for model in self.models:
            if model["status"] != "Active":
                continue

            # Deploy active models
            self.deployment_id += 1

            deployment_date = model["created_at"] + timedelta(days=random.randint(1, 7))

            self.model_deployments.append(
                {
                    "deployment_id": self.deployment_id,
                    "model_id": model["model_id"],
                    "deployment_name": f"Deploy_{model['model_name']}",
                    "environment": random.choice(deployment_environments),
                    "deployment_strategy": random.choice(deployment_strategies),
                    "endpoint_url": f"https://ml-api.example.com/predict/{model['model_id']}",
                    "replicas": random.randint(1, 10),
                    "cpu_request": random.choice(["500m", "1", "2"]),
                    "memory_request": random.choice(["1Gi", "2Gi", "4Gi"]),
                    "deployment_date": deployment_date,
                    "status": random.choice(["Active", "Inactive", "Failed"]),
                    "last_health_check": datetime.now()
                    - timedelta(minutes=random.randint(1, 60)),
                    "created_at": deployment_date,
                }
            )

    def generate_ab_tests(self):
        """Generate A/B tests"""
        print("Generating A/B tests...")

        for project in self.projects:
            project_models = [
                m for m in self.models if m["project_id"] == project["project_id"]
            ]

            if len(project_models) < 2:
                continue

            for t in range(
                min(CONFIG["ab_tests_per_project"], len(project_models) - 1)
            ):
                self.test_id += 1

                control_model = project_models[t]
                treatment_model = project_models[t + 1]

                start_date = max(
                    control_model["created_at"], treatment_model["created_at"]
                ) + timedelta(days=1)
                end_date = start_date + timedelta(days=random.randint(7, 30))

                self.ab_tests.append(
                    {
                        "test_id": self.test_id,
                        "project_id": project["project_id"],
                        "test_name": f"AB_Test_{t+1}",
                        "control_model_id": control_model["model_id"],
                        "treatment_model_id": treatment_model["model_id"],
                        "traffic_split": random.choice([50, 20, 10]),
                        "start_date": start_date,
                        "end_date": end_date if end_date < datetime.now() else None,
                        "status": (
                            "Completed" if end_date < datetime.now() else "Running"
                        ),
                        "winner_model_id": (
                            treatment_model["model_id"]
                            if random.random() > 0.5
                            else control_model["model_id"]
                        ),
                        "statistical_significance": random.uniform(0.9, 0.99),
                        "created_by": fake.name(),
                        "created_at": start_date,
                    }
                )

    def generate_predictions(self):
        """Generate model predictions (limited for demo)"""
        print("Generating predictions (limited for demo)...")

        # Generate predictions for deployed models
        deployed_models = [d for d in self.model_deployments if d["status"] == "Active"]

        for deployment in deployed_models[:5]:  # Limit to 5 deployments
            model = next(
                m for m in self.models if m["model_id"] == deployment["model_id"]
            )
            project = next(
                p for p in self.projects if p["project_id"] == model["project_id"]
            )

            # Generate 100 predictions per deployment for demo
            for _ in range(100):
                self.prediction_id += 1

                prediction_time = fake.date_time_between(
                    start_date=deployment["deployment_date"], end_date="now"
                )

                # Generate prediction based on project type
                if project["project_type"] == "Classification":
                    prediction = random.choice([0, 1])
                    confidence = random.uniform(0.5, 1.0)
                elif project["project_type"] == "Regression":
                    prediction = random.uniform(0, 1000)
                    confidence = random.uniform(0.7, 0.95)
                else:
                    prediction = random.uniform(0, 1)
                    confidence = random.uniform(0.5, 1.0)

                self.predictions.append(
                    {
                        "prediction_id": self.prediction_id,
                        "model_id": model["model_id"],
                        "deployment_id": deployment["deployment_id"],
                        "request_id": str(uuid.uuid4()),
                        "input_data": json.dumps(
                            {"features": [random.uniform(0, 1) for _ in range(10)]}
                        ),
                        "prediction": prediction,
                        "confidence": confidence,
                        "prediction_time": prediction_time,
                        "response_time_ms": random.randint(10, 500),
                        "created_at": prediction_time,
                    }
                )

    def generate_ground_truth(self):
        """Generate ground truth for predictions"""
        print("Generating ground truth...")

        # Generate ground truth for some predictions
        sampled_predictions = random.sample(
            self.predictions, min(50, len(self.predictions))
        )

        for prediction in sampled_predictions:
            self.ground_truth_id += 1

            model = next(
                m for m in self.models if m["model_id"] == prediction["model_id"]
            )
            project = next(
                p for p in self.projects if p["project_id"] == model["project_id"]
            )

            # Generate ground truth based on project type
            if project["project_type"] == "Classification":
                actual_value = random.choice([0, 1])
            elif project["project_type"] == "Regression":
                actual_value = prediction["prediction"] + random.uniform(-100, 100)
            else:
                actual_value = random.uniform(0, 1)

            self.ground_truth.append(
                {
                    "ground_truth_id": self.ground_truth_id,
                    "prediction_id": prediction["prediction_id"],
                    "actual_value": actual_value,
                    "collection_time": prediction["prediction_time"]
                    + timedelta(days=random.randint(1, 7)),
                    "source": random.choice(
                        ["manual_label", "automated", "user_feedback"]
                    ),
                    "created_at": prediction["prediction_time"]
                    + timedelta(days=random.randint(1, 7)),
                }
            )

    def generate_drift_detection(self):
        """Generate drift detection records"""
        print("Generating drift detection...")

        drift_types = ["Feature", "Prediction", "Concept", "Data Quality"]

        for model in self.models:
            if model["status"] != "Active":
                continue

            # Generate drift detection checks
            num_checks = random.randint(1, 5)

            for _ in range(num_checks):
                self.drift_id += 1

                check_time = fake.date_time_between(
                    start_date=model["created_at"], end_date="now"
                )

                drift_score = random.uniform(0, 1)
                is_drift = drift_score > 0.7

                self.drift_detection.append(
                    {
                        "drift_id": self.drift_id,
                        "model_id": model["model_id"],
                        "drift_type": random.choice(drift_types),
                        "check_time": check_time,
                        "drift_score": round(drift_score, 4),
                        "is_drift_detected": is_drift,
                        "affected_features": json.dumps(
                            ["feature_1", "feature_2"] if is_drift else []
                        ),
                        "recommendation": (
                            "Retrain model" if is_drift else "Continue monitoring"
                        ),
                        "created_at": check_time,
                    }
                )

    def generate_performance_metrics(self):
        """Generate model performance metrics"""
        print("Generating performance metrics...")

        for deployment in self.model_deployments:
            if deployment["status"] != "Active":
                continue

            # Generate daily metrics
            current = deployment["deployment_date"]

            while current <= datetime.now():
                self.perf_metric_id += 1

                self.performance_metrics.append(
                    {
                        "metric_id": self.perf_metric_id,
                        "model_id": deployment["model_id"],
                        "deployment_id": deployment["deployment_id"],
                        "metric_date": current.date(),
                        "total_predictions": random.randint(100, 10000),
                        "average_latency_ms": round(random.uniform(10, 200), 2),
                        "p95_latency_ms": round(random.uniform(50, 500), 2),
                        "p99_latency_ms": round(random.uniform(100, 1000), 2),
                        "error_rate": round(random.uniform(0, 0.05), 4),
                        "throughput_qps": round(random.uniform(10, 1000), 2),
                        "created_at": current,
                    }
                )

                current += timedelta(days=1)

    def generate_model_alerts(self):
        """Generate model alerts"""
        print("Generating model alerts...")

        alert_types = [
            "Performance Degradation",
            "High Error Rate",
            "Data Drift",
            "System Failure",
            "Low Accuracy",
        ]
        severities = ["Low", "Medium", "High", "Critical"]

        for model in self.models:
            # Generate 0-3 alerts per model
            num_alerts = random.randint(0, 3)

            for _ in range(num_alerts):
                self.alert_id += 1

                alert_time = fake.date_time_between(
                    start_date=model["created_at"], end_date="now"
                )

                self.model_alerts.append(
                    {
                        "alert_id": self.alert_id,
                        "model_id": model["model_id"],
                        "alert_type": random.choice(alert_types),
                        "severity": random.choice(severities),
                        "alert_message": f"Alert for model {model['model_name']}",
                        "alert_time": alert_time,
                        "resolved_time": (
                            alert_time + timedelta(hours=random.randint(1, 24))
                            if random.random() > 0.3
                            else None
                        ),
                        "resolution_notes": (
                            "Issue resolved by restarting service"
                            if random.random() > 0.5
                            else None
                        ),
                        "created_at": alert_time,
                    }
                )

    def generate_compute_resources(self):
        """Generate compute resource definitions"""
        print("Generating compute resources...")

        resource_types = ["GPU", "CPU", "Memory", "Storage"]
        instance_types = [
            "ml.t2.medium",
            "ml.m5.large",
            "ml.m5.xlarge",
            "ml.p3.2xlarge",
            "ml.g4dn.xlarge",
        ]

        for org in self.organizations:
            for r in range(5):  # 5 resources per org
                self.resource_id += 1

                self.compute_resources.append(
                    {
                        "resource_id": self.resource_id,
                        "org_id": org["org_id"],
                        "resource_name": f"Resource_{resource_types[r % len(resource_types)]}_{r+1}",
                        "resource_type": resource_types[r % len(resource_types)],
                        "instance_type": random.choice(instance_types),
                        "region": random.choice(
                            ["us-east-1", "us-west-2", "eu-west-1"]
                        ),
                        "capacity": random.randint(1, 100),
                        "cost_per_hour": round(random.uniform(0.1, 10.0), 2),
                        "is_reserved": random.random() > 0.5,
                        "created_at": org["created_at"],
                    }
                )

    def generate_resource_allocations(self):
        """Generate resource allocations"""
        print("Generating resource allocations...")

        for run in self.experiment_runs[:50]:  # Limit to 50 runs
            if run["status"] in ["Completed", "Running"]:
                self.allocation_id += 1

                resource = random.choice(self.compute_resources)

                self.resource_allocations.append(
                    {
                        "allocation_id": self.allocation_id,
                        "resource_id": resource["resource_id"],
                        "allocation_type": "experiment_run",
                        "allocation_id_ref": run["run_id"],
                        "start_time": run["start_time"],
                        "end_time": run["end_time"] if run["end_time"] else None,
                        "allocated_capacity": random.randint(1, resource["capacity"]),
                        "cost": round(random.uniform(1, 100), 2),
                        "created_at": run["start_time"],
                    }
                )

    def generate_data_lineage(self):
        """Generate data lineage"""
        print("Generating data lineage...")

        entity_types = ["stream", "feature", "model", "dataset"]

        for feature in self.feature_definitions[:30]:  # Limit to 30 features
            self.lineage_id += 1

            # Link feature to stream
            stream = random.choice(self.data_streams)

            self.data_lineage.append(
                {
                    "lineage_id": self.lineage_id,
                    "source_entity_type": "stream",
                    "source_entity_id": stream["stream_id"],
                    "target_entity_type": "feature",
                    "target_entity_id": feature["feature_id"],
                    "transformation_type": "feature_extraction",
                    "transformation_logic": json.dumps(
                        {"operation": "aggregate", "window": "1h"}
                    ),
                    "created_at": feature["created_at"],
                }
            )

    def generate_data_quality_rules(self):
        """Generate data quality rules"""
        print("Generating data quality rules...")

        rule_types = [
            "Completeness",
            "Uniqueness",
            "Validity",
            "Consistency",
            "Accuracy",
        ]

        for stream in self.data_streams:
            # 2-4 rules per stream
            num_rules = random.randint(2, 4)

            for r in range(num_rules):
                self.rule_id += 1

                rule_type = random.choice(rule_types)

                if rule_type == "Completeness":
                    condition = "field IS NOT NULL"
                elif rule_type == "Uniqueness":
                    condition = "COUNT(DISTINCT field) = COUNT(field)"
                elif rule_type == "Validity":
                    condition = "field BETWEEN 0 AND 100"
                elif rule_type == "Consistency":
                    condition = "field1 + field2 = total"
                else:
                    condition = "ABS(field - mean) < 3 * stddev"

                self.data_quality_rules.append(
                    {
                        "rule_id": self.rule_id,
                        "stream_id": stream["stream_id"],
                        "rule_name": f"{rule_type}_Check_{r+1}",
                        "rule_type": rule_type,
                        "rule_condition": condition,
                        "severity": random.choice(["Warning", "Error", "Critical"]),
                        "is_active": True,
                        "created_at": stream["created_at"],
                    }
                )

    def generate_data_quality_violations(self):
        """Generate data quality violations"""
        print("Generating data quality violations...")

        for rule in self.data_quality_rules:
            # Generate 0-5 violations per rule
            num_violations = random.randint(0, 5)

            for _ in range(num_violations):
                self.violation_id += 1

                violation_time = fake.date_time_between(
                    start_date=self.start_date, end_date="now"
                )

                self.data_quality_violations.append(
                    {
                        "violation_id": self.violation_id,
                        "rule_id": rule["rule_id"],
                        "violation_time": violation_time,
                        "violation_count": random.randint(1, 100),
                        "sample_data": json.dumps({"field": "invalid_value"}),
                        "resolution_status": random.choice(
                            ["Pending", "Resolved", "Ignored"]
                        ),
                        "created_at": violation_time,
                    }
                )

    def generate_user_activity(self):
        """Generate user activity logs"""
        print("Generating user activity...")

        activities = [
            "login",
            "create_project",
            "train_model",
            "deploy_model",
            "view_metrics",
            "export_data",
        ]

        for _ in range(500):  # Generate 500 activities
            self.activity_id += 1

            org = random.choice(self.organizations)
            activity_time = fake.date_time_between(
                start_date=self.start_date, end_date="now"
            )

            self.user_activity.append(
                {
                    "activity_id": self.activity_id,
                    "org_id": org["org_id"],
                    "user_email": fake.email(),
                    "activity_type": random.choice(activities),
                    "activity_details": json.dumps(
                        {"ip": fake.ipv4(), "user_agent": "Mozilla/5.0"}
                    ),
                    "activity_time": activity_time,
                    "created_at": activity_time,
                }
            )

    def generate_api_usage(self):
        """Generate API usage logs"""
        print("Generating API usage...")

        endpoints = [
            "/predict",
            "/train",
            "/deploy",
            "/metrics",
            "/features",
            "/models",
        ]
        methods = ["GET", "POST", "PUT", "DELETE"]

        current = self.start_date

        while current <= datetime.now():
            for org in self.organizations:
                # Generate daily API usage
                daily_calls = random.randint(100, 5000)

                for _ in range(min(daily_calls // 100, 50)):  # Sample for demo
                    self.api_usage_id += 1

                    call_time = current + timedelta(
                        hours=random.randint(0, 23), minutes=random.randint(0, 59)
                    )

                    self.api_usage.append(
                        {
                            "usage_id": self.api_usage_id,
                            "org_id": org["org_id"],
                            "api_key": org["api_key"],
                            "endpoint": random.choice(endpoints),
                            "method": random.choice(methods),
                            "request_time": call_time,
                            "response_time_ms": random.randint(10, 1000),
                            "status_code": random.choices(
                                [200, 201, 400, 401, 500],
                                weights=[0.8, 0.1, 0.05, 0.03, 0.02],
                            )[0],
                            "request_size_bytes": random.randint(100, 10000),
                            "response_size_bytes": random.randint(100, 100000),
                            "created_at": call_time,
                        }
                    )

            current += timedelta(days=1)

    def save_all(self):
        """Save all generated data to CSV files"""
        OUTPUT_DIR.mkdir(exist_ok=True)

        print("\nSaving data to CSV files...")

        datasets = [
            ("organizations", self.organizations),
            ("projects", self.projects),
            ("data_streams", self.data_streams),
            ("stream_pipelines", self.stream_pipelines),
            ("stream_events", self.stream_events[:1000]),  # Limit for demo
            ("feature_definitions", self.feature_definitions),
            ("raw_features", self.raw_features[:5000]),  # Limit for demo
            ("feature_computations", self.feature_computations),
            ("feature_sets", self.feature_sets),
            ("experiments", self.experiments),
            ("experiment_runs", self.experiment_runs),
            ("run_metrics", self.run_metrics),
            ("models", self.models),
            ("model_evaluations", self.model_evaluations),
            ("model_comparisons", self.model_comparisons),
            ("model_deployments", self.model_deployments),
            ("ab_tests", self.ab_tests),
            ("predictions", self.predictions[:1000]),  # Limit for demo
            ("ground_truth", self.ground_truth),
            ("drift_detection", self.drift_detection),
            ("performance_metrics", self.performance_metrics[:1000]),  # Limit for demo
            ("model_alerts", self.model_alerts),
            ("compute_resources", self.compute_resources),
            ("resource_allocations", self.resource_allocations),
            ("data_lineage", self.data_lineage),
            ("data_quality_rules", self.data_quality_rules),
            ("data_quality_violations", self.data_quality_violations),
            ("user_activity", self.user_activity),
            ("api_usage", self.api_usage[:1000]),  # Limit for demo
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
        print(f"\nStreaming ML Platform Data Generation Summary")
        print("=" * 50)

        print(f"\nOrganizations & Projects:")
        print(f"  Organizations: {len(self.organizations)}")
        print(f"  Projects: {len(self.projects)}")
        print(
            f"  Active Projects: {len([p for p in self.projects if p['status'] == 'Active'])}"
        )

        print(f"\nData Streams:")
        print(f"  Streams: {len(self.data_streams)}")
        print(f"  Pipelines: {len(self.stream_pipelines)}")
        print(f"  Stream Events: {len(self.stream_events):,}")

        print(f"\nFeature Store:")
        print(f"  Feature Definitions: {len(self.feature_definitions)}")
        print(f"  Raw Features: {len(self.raw_features):,}")
        print(f"  Feature Sets: {len(self.feature_sets)}")
        print(f"  Computations: {len(self.feature_computations)}")

        print(f"\nML Operations:")
        print(f"  Experiments: {len(self.experiments)}")
        print(f"  Experiment Runs: {len(self.experiment_runs)}")
        print(f"  Models: {len(self.models)}")
        print(f"  Deployments: {len(self.model_deployments)}")
        print(f"  A/B Tests: {len(self.ab_tests)}")

        print(f"\nMonitoring:")
        print(f"  Predictions: {len(self.predictions):,}")
        print(f"  Ground Truth: {len(self.ground_truth)}")
        print(f"  Drift Detections: {len(self.drift_detection)}")
        print(f"  Model Alerts: {len(self.model_alerts)}")

        print(f"\nData Governance:")
        print(f"  Quality Rules: {len(self.data_quality_rules)}")
        print(f"  Violations: {len(self.data_quality_violations)}")
        print(f"  Lineage Records: {len(self.data_lineage)}")

        print(f"\nUsage:")
        print(f"  User Activities: {len(self.user_activity)}")
        print(f"  API Calls: {len(self.api_usage):,}")

        # Calculate some statistics
        total_experiments = len(self.experiments)
        successful_experiments = len(
            [e for e in self.experiments if e["status"] == "Completed"]
        )
        if total_experiments > 0:
            success_rate = (successful_experiments / total_experiments) * 100
            print(f"\nExperiment Success Rate: {success_rate:.1f}%")

        deployed_models = len(
            [d for d in self.model_deployments if d["status"] == "Active"]
        )
        print(f"Active Model Deployments: {deployed_models}")

        print(f"\nFiles Generated: 29")


if __name__ == "__main__":
    generator = StreamingMLGenerator()
    generator.generate_all()
    print("\n[SUCCESS] Streaming ML Platform data generation complete!")
