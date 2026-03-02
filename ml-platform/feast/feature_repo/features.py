"""Feature definitions for MySQL Business-to-Schema ML Platform.

Defines features for all business domains
"""

from datetime import timedelta
from feast import (
    Entity,
    FeatureView,
    FileSource,
    ValueType,
    Field,
    FeatureService,
    PushSource,
)
from feast.types import Float32, Float64, Int32, Int64, String, Bool
from feast.on_demand_feature_view import on_demand_feature_view
from feast.stream_feature_view import stream_feature_view
import pandas as pd

# ==================== Entities ====================

# Patient Entity
patient = Entity(
    name="patient",
    description="Patient in the clinic system",
    join_keys=["patient_id"],
    value_type=ValueType.INT64,
)

# Customer Entity
customer = Entity(
    name="customer",
    description="Customer in the e-commerce system",
    join_keys=["customer_id"],
    value_type=ValueType.INT64,
)

# Device Entity
device = Entity(
    name="device",
    description="IoT device",
    join_keys=["device_id"],
    value_type=ValueType.STRING,
)

# User Entity (Social Media)
user = Entity(
    name="user",
    description="Social media user",
    join_keys=["user_id"],
    value_type=ValueType.INT64,
)

# Product Entity
product = Entity(
    name="product",
    description="Product in e-commerce",
    join_keys=["product_id"],
    value_type=ValueType.INT64,
)

# ==================== Data Sources ====================

# Patient Demographics Source
patient_demographics_source = FileSource(
    path="/data/patient_demographics.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Patient Vitals Source
patient_vitals_source = FileSource(
    path="/data/patient_vitals.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Customer Profile Source
customer_profile_source = FileSource(
    path="/data/customer_profiles.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Customer Transactions Source
customer_transactions_source = FileSource(
    path="/data/customer_transactions.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# IoT Readings Source
iot_readings_source = FileSource(
    path="/data/iot_readings.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Social Media Activity Source
social_activity_source = FileSource(
    path="/data/social_activity.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# Product Features Source
product_features_source = FileSource(
    path="/data/product_features.parquet",
    timestamp_field="event_timestamp",
    created_timestamp_column="created_timestamp",
)

# ==================== Feature Views ====================

# Patient Demographics Features
patient_demographics_fv = FeatureView(
    name="patient_demographics",
    entities=[patient],
    ttl=timedelta(days=365),
    schema=[
        Field(name="patient_id", dtype=Int64),
        Field(name="age", dtype=Int32),
        Field(name="gender", dtype=String),
        Field(name="bmi", dtype=Float32),
        Field(name="smoking_status", dtype=Bool),
        Field(name="chronic_conditions_count", dtype=Int32),
        Field(name="insurance_type", dtype=String),
        Field(name="zip_code", dtype=String),
    ],
    online=True,
    source=patient_demographics_source,
    tags={"team": "clinic", "priority": "high"},
)

# Patient Vitals Features
patient_vitals_fv = FeatureView(
    name="patient_vitals",
    entities=[patient],
    ttl=timedelta(days=30),
    schema=[
        Field(name="patient_id", dtype=Int64),
        Field(name="heart_rate_avg", dtype=Float32),
        Field(name="heart_rate_std", dtype=Float32),
        Field(name="blood_pressure_systolic", dtype=Float32),
        Field(name="blood_pressure_diastolic", dtype=Float32),
        Field(name="temperature", dtype=Float32),
        Field(name="oxygen_saturation", dtype=Float32),
        Field(name="respiratory_rate", dtype=Float32),
    ],
    online=True,
    source=patient_vitals_source,
    tags={"team": "clinic", "priority": "critical"},
)

# Customer Profile Features
customer_profile_fv = FeatureView(
    name="customer_profile",
    entities=[customer],
    ttl=timedelta(days=180),
    schema=[
        Field(name="customer_id", dtype=Int64),
        Field(name="registration_days", dtype=Int32),
        Field(name="total_orders", dtype=Int32),
        Field(name="total_spent", dtype=Float64),
        Field(name="avg_order_value", dtype=Float32),
        Field(name="preferred_category", dtype=String),
        Field(name="preferred_payment_method", dtype=String),
        Field(name="customer_segment", dtype=String),
        Field(name="churn_risk_score", dtype=Float32),
    ],
    online=True,
    source=customer_profile_source,
    tags={"team": "ecommerce", "priority": "high"},
)

# Customer Transaction Features
customer_transactions_fv = FeatureView(
    name="customer_transactions",
    entities=[customer],
    ttl=timedelta(days=90),
    schema=[
        Field(name="customer_id", dtype=Int64),
        Field(name="transactions_last_7d", dtype=Int32),
        Field(name="transactions_last_30d", dtype=Int32),
        Field(name="revenue_last_7d", dtype=Float64),
        Field(name="revenue_last_30d", dtype=Float64),
        Field(name="avg_days_between_orders", dtype=Float32),
        Field(name="last_order_days_ago", dtype=Int32),
        Field(name="cart_abandonment_rate", dtype=Float32),
    ],
    online=True,
    source=customer_transactions_source,
    tags={"team": "ecommerce", "priority": "high"},
)

# IoT Device Features
iot_device_fv = FeatureView(
    name="iot_device_features",
    entities=[device],
    ttl=timedelta(days=7),
    schema=[
        Field(name="device_id", dtype=String),
        Field(name="readings_per_hour", dtype=Float32),
        Field(name="avg_value", dtype=Float64),
        Field(name="std_value", dtype=Float64),
        Field(name="min_value", dtype=Float64),
        Field(name="max_value", dtype=Float64),
        Field(name="anomaly_rate", dtype=Float32),
        Field(name="last_maintenance_days", dtype=Int32),
        Field(name="failure_probability", dtype=Float32),
    ],
    online=True,
    source=iot_readings_source,
    tags={"team": "iot", "priority": "high"},
)

# Social Media User Features
social_user_fv = FeatureView(
    name="social_user_features",
    entities=[user],
    ttl=timedelta(days=30),
    schema=[
        Field(name="user_id", dtype=Int64),
        Field(name="follower_count", dtype=Int32),
        Field(name="following_count", dtype=Int32),
        Field(name="posts_count", dtype=Int32),
        Field(name="avg_likes_per_post", dtype=Float32),
        Field(name="avg_comments_per_post", dtype=Float32),
        Field(name="engagement_rate", dtype=Float32),
        Field(name="influence_score", dtype=Float32),
        Field(name="activity_level", dtype=String),
    ],
    online=True,
    source=social_activity_source,
    tags={"team": "social", "priority": "medium"},
)

# Product Features
product_features_fv = FeatureView(
    name="product_features",
    entities=[product],
    ttl=timedelta(days=90),
    schema=[
        Field(name="product_id", dtype=Int64),
        Field(name="price", dtype=Float64),
        Field(name="discount_percentage", dtype=Float32),
        Field(name="rating_avg", dtype=Float32),
        Field(name="rating_count", dtype=Int32),
        Field(name="sales_rank", dtype=Int32),
        Field(name="return_rate", dtype=Float32),
        Field(name="profit_margin", dtype=Float32),
        Field(name="inventory_level", dtype=Int32),
    ],
    online=True,
    source=product_features_source,
    tags={"team": "ecommerce", "priority": "high"},
)

# ==================== On-Demand Features ====================


@on_demand_feature_view(
    sources=[customer_profile_fv, customer_transactions_fv],
    schema=[
        Field(name="customer_lifetime_value", dtype=Float64),
        Field(name="days_since_last_purchase", dtype=Int32),
        Field(name="purchase_frequency", dtype=Float32),
    ],
)
def customer_ltv_features(inputs: pd.DataFrame) -> pd.DataFrame:
    """Calculate customer lifetime value and related features."""
    df = pd.DataFrame()

    # Customer Lifetime Value (simplified CLV calculation)
    df["customer_lifetime_value"] = (
        inputs["total_spent"]
        * inputs["transactions_last_30d"]
        * 12  # Projected annual value
    )

    # Days since last purchase
    df["days_since_last_purchase"] = inputs["last_order_days_ago"]

    # Purchase frequency (orders per month)
    df["purchase_frequency"] = inputs["total_orders"] / (
        inputs["registration_days"] / 30
    )

    return df


@on_demand_feature_view(
    sources=[patient_demographics_fv, patient_vitals_fv],
    schema=[
        Field(name="health_risk_score", dtype=Float32),
        Field(name="vital_signs_stability", dtype=Float32),
        Field(name="readmission_risk", dtype=Float32),
    ],
)
def patient_risk_features(inputs: pd.DataFrame) -> pd.DataFrame:
    """Calculate patient risk scores."""
    df = pd.DataFrame()

    # Health risk score based on demographics and vitals
    df["health_risk_score"] = (
        (inputs["age"] / 100) * 0.3
        + (inputs["chronic_conditions_count"] / 10) * 0.3
        + (inputs["bmi"].clip(0, 50) / 50) * 0.2
        + (1 - inputs["oxygen_saturation"] / 100) * 0.2
    ).clip(0, 1)

    # Vital signs stability (lower is more stable)
    df["vital_signs_stability"] = (
        inputs["heart_rate_std"] / 50 * 0.5
        + abs(inputs["blood_pressure_systolic"] - 120) / 120 * 0.5
    ).clip(0, 1)

    # Readmission risk (simplified model)
    df["readmission_risk"] = (
        df["health_risk_score"] * 0.6 + df["vital_signs_stability"] * 0.4
    ).clip(0, 1)

    return df


@on_demand_feature_view(
    sources=[iot_device_fv],
    schema=[
        Field(name="maintenance_urgency", dtype=Float32),
        Field(name="anomaly_severity", dtype=Float32),
    ],
)
def iot_maintenance_features(inputs: pd.DataFrame) -> pd.DataFrame:
    """Calculate IoT maintenance and anomaly features."""
    df = pd.DataFrame()

    # Maintenance urgency score
    df["maintenance_urgency"] = (
        inputs["failure_probability"] * 0.4
        + (inputs["last_maintenance_days"] / 365) * 0.3
        + inputs["anomaly_rate"] * 0.3
    ).clip(0, 1)

    # Anomaly severity
    df["anomaly_severity"] = (
        inputs["anomaly_rate"] * (inputs["std_value"] / (inputs["avg_value"] + 1))
    ).clip(0, 1)

    return df


# ==================== Stream Feature Views ====================

# Push source for real-time features
push_source = PushSource(
    name="real_time_push_source",
    batch_source=FileSource(path=""),  # Dummy path
)


# Real-time IoT anomaly detection features
@stream_feature_view(
    entities=[device],
    ttl=timedelta(minutes=5),
    mode="spark",
    source=push_source,
    schema=[
        Field(name="device_id", dtype=String),
        Field(name="current_value", dtype=Float64),
        Field(name="rolling_avg_5min", dtype=Float64),
        Field(name="rolling_std_5min", dtype=Float64),
        Field(name="is_anomaly", dtype=Bool),
    ],
)
def realtime_iot_features(df: pd.DataFrame) -> pd.DataFrame:
    """Process real-time IoT data for anomaly detection."""
    # This would be implemented with actual streaming logic
    return df


# ==================== Feature Services ====================

# Patient Prediction Service
patient_prediction_service = FeatureService(
    name="patient_prediction_service",
    features=[
        patient_demographics_fv,
        patient_vitals_fv,
        patient_risk_features,
    ],
    description="Features for patient health predictions",
    tags={"use_case": "healthcare_ml"},
)

# Customer Churn Prediction Service
customer_churn_service = FeatureService(
    name="customer_churn_service",
    features=[
        customer_profile_fv,
        customer_transactions_fv,
        customer_ltv_features,
    ],
    description="Features for customer churn prediction",
    tags={"use_case": "customer_retention"},
)

# IoT Anomaly Detection Service
iot_anomaly_service = FeatureService(
    name="iot_anomaly_service",
    features=[
        iot_device_fv,
        iot_maintenance_features,
        realtime_iot_features,
    ],
    description="Features for IoT anomaly detection and maintenance",
    tags={"use_case": "predictive_maintenance"},
)

# Social Media Recommendation Service
social_recommendation_service = FeatureService(
    name="social_recommendation_service",
    features=[
        social_user_fv,
    ],
    description="Features for social media content recommendation",
    tags={"use_case": "recommendation_system"},
)

# Product Recommendation Service
product_recommendation_service = FeatureService(
    name="product_recommendation_service",
    features=[
        customer_profile_fv,
        product_features_fv,
    ],
    description="Features for product recommendation",
    tags={"use_case": "ecommerce_recommendation"},
)
