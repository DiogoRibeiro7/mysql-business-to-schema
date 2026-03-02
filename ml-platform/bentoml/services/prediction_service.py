"""BentoML Prediction Service.

Unified model serving for all ML models
"""

import numpy as np
import pandas as pd
import bentoml
from bentoml.io import JSON, PandasDataFrame
from pydantic import BaseModel
from typing import Dict, List
import logging

logger = logging.getLogger(__name__)

# ==================== Request/Response Models ====================


class PatientPredictionRequest(BaseModel):
    """Request model for patient predictions."""

    patient_id: int
    age: int
    gender: str
    bmi: float
    chronic_conditions_count: int
    heart_rate: float
    blood_pressure_systolic: float
    blood_pressure_diastolic: float
    temperature: float
    oxygen_saturation: float


class PatientPredictionResponse(BaseModel):
    """Response model for patient predictions."""

    patient_id: int
    readmission_probability: float
    readmission_risk: str
    health_score: float
    recommendations: List[str]


class CustomerChurnRequest(BaseModel):
    """Request model for customer churn prediction."""

    customer_id: int
    registration_days: int
    total_orders: int
    total_spent: float
    avg_order_value: float
    days_since_last_order: int
    preferred_category: str
    customer_segment: str


class CustomerChurnResponse(BaseModel):
    """Response model for customer churn prediction."""

    customer_id: int
    churn_probability: float
    churn_risk: str
    retention_score: float
    recommended_actions: List[str]


class IoTAnomalyRequest(BaseModel):
    """Request model for IoT anomaly detection."""

    device_id: str
    sensor_type: str
    current_value: float
    rolling_avg: float
    rolling_std: float
    last_maintenance_days: int


class IoTAnomalyResponse(BaseModel):
    """Response model for IoT anomaly detection."""

    device_id: str
    is_anomaly: bool
    anomaly_score: float
    maintenance_urgency: float
    recommended_action: str


# ==================== Feature Engineering ====================


class FeatureEngineer:
    """Feature engineering for model inputs."""

    @staticmethod
    def engineer_patient_features(data: Dict) -> np.ndarray:
        """Engineer features for patient prediction."""
        features = []

        # Basic demographics
        features.append(data["age"] / 100.0)  # Normalize age
        features.append(1 if data["gender"] == "Male" else 0)
        features.append(data["bmi"] / 50.0)  # Normalize BMI
        features.append(data["chronic_conditions_count"] / 10.0)

        # Vital signs
        features.append((data["heart_rate"] - 70) / 30.0)  # Normalize around normal
        features.append((data["blood_pressure_systolic"] - 120) / 40.0)
        features.append((data["blood_pressure_diastolic"] - 80) / 20.0)
        features.append((data["temperature"] - 37) / 2.0)
        features.append(data["oxygen_saturation"] / 100.0)

        # Risk indicators
        risk_score = 0
        if data["age"] > 65:
            risk_score += 0.2
        if data["chronic_conditions_count"] > 2:
            risk_score += 0.3
        if data["oxygen_saturation"] < 95:
            risk_score += 0.3
        if data["blood_pressure_systolic"] > 140:
            risk_score += 0.2

        features.append(risk_score)

        return np.array(features).reshape(1, -1)

    @staticmethod
    def engineer_customer_features(data: Dict) -> np.ndarray:
        """Engineer features for customer churn prediction."""
        features = []

        # Customer tenure and activity
        features.append(data["registration_days"] / 365.0)
        features.append(data["total_orders"] / 100.0)
        features.append(data["total_spent"] / 10000.0)
        features.append(data["avg_order_value"] / 1000.0)

        # Recency
        features.append(data["days_since_last_order"] / 365.0)

        # Categorical encodings
        category_map = {
            "Electronics": 0,
            "Clothing": 1,
            "Books": 2,
            "Home": 3,
            "Other": 4,
        }
        features.append(category_map.get(data["preferred_category"], 4) / 4.0)

        segment_map = {"Premium": 0, "Regular": 1, "New": 2}
        features.append(segment_map.get(data["customer_segment"], 2) / 2.0)

        # Derived features
        if data["registration_days"] > 0:
            purchase_frequency = data["total_orders"] / (
                data["registration_days"] / 30.0
            )
        else:
            purchase_frequency = 0
        features.append(purchase_frequency)

        # Engagement score
        engagement_score = 0
        if data["total_orders"] > 10:
            engagement_score += 0.3
        if data["avg_order_value"] > 100:
            engagement_score += 0.3
        if data["days_since_last_order"] < 30:
            engagement_score += 0.4

        features.append(engagement_score)

        return np.array(features).reshape(1, -1)

    @staticmethod
    def engineer_iot_features(data: Dict) -> np.ndarray:
        """Engineer features for IoT anomaly detection."""
        features = []

        # Sensor readings
        features.append(data["current_value"] / 1000.0)  # Normalize
        features.append(data["rolling_avg"] / 1000.0)
        features.append(data["rolling_std"] / 100.0)

        # Deviation metrics
        if data["rolling_avg"] > 0:
            deviation = (
                abs(data["current_value"] - data["rolling_avg"]) / data["rolling_avg"]
            )
        else:
            deviation = 0
        features.append(deviation)

        # Z-score
        if data["rolling_std"] > 0:
            z_score = (data["current_value"] - data["rolling_avg"]) / data[
                "rolling_std"
            ]
        else:
            z_score = 0
        features.append(abs(z_score) / 3.0)  # Normalize by 3-sigma

        # Maintenance features
        features.append(data["last_maintenance_days"] / 365.0)

        # Sensor type encoding
        sensor_type_map = {"temperature": 0, "pressure": 1, "flow": 2, "vibration": 3}
        features.append(sensor_type_map.get(data["sensor_type"], 0) / 3.0)

        # Risk factors
        maintenance_risk = min(data["last_maintenance_days"] / 180.0, 1.0)
        features.append(maintenance_risk)

        return np.array(features).reshape(1, -1)


# ==================== BentoML Service ====================

# Load models
patient_model = bentoml.sklearn.get("patient_model:latest")
customer_model = bentoml.sklearn.get("customer_model:latest")
iot_model = bentoml.sklearn.get("iot_model:latest")

# Create service
svc = bentoml.Service(
    "ml_prediction_service",
    runners=[
        patient_model.to_runner(name="patient_runner"),
        customer_model.to_runner(name="customer_runner"),
        iot_model.to_runner(name="iot_runner"),
    ],
)

# Feature engineer instance
feature_engineer = FeatureEngineer()


@svc.api(
    input=JSON(pydantic_model=PatientPredictionRequest),
    output=JSON(pydantic_model=PatientPredictionResponse),
)
async def predict_patient_readmission(
    request: PatientPredictionRequest,
) -> PatientPredictionResponse:
    """Predict patient readmission risk."""
    try:
        # Engineer features
        features = feature_engineer.engineer_patient_features(request.dict())

        # Get prediction
        runner = svc.runners[0]
        prediction_proba = await runner.predict.async_run(features)

        # Extract probability for positive class
        readmission_prob = float(prediction_proba[0][1])

        # Determine risk level
        if readmission_prob >= 0.7:
            risk_level = "High"
        elif readmission_prob >= 0.3:
            risk_level = "Medium"
        else:
            risk_level = "Low"

        # Calculate health score (inverse of readmission probability)
        health_score = 1.0 - readmission_prob

        # Generate recommendations
        recommendations = []
        if risk_level == "High":
            recommendations.extend(
                [
                    "Schedule follow-up appointment within 48 hours",
                    "Initiate care coordination protocol",
                    "Review medication compliance",
                ]
            )
        elif risk_level == "Medium":
            recommendations.extend(
                [
                    "Schedule follow-up within 1 week",
                    "Monitor vital signs daily",
                    "Provide patient education materials",
                ]
            )
        else:
            recommendations.append("Continue standard care protocol")

        if request.chronic_conditions_count > 2:
            recommendations.append("Refer to chronic disease management program")

        if request.oxygen_saturation < 95:
            recommendations.append("Monitor oxygen levels closely")

        return PatientPredictionResponse(
            patient_id=request.patient_id,
            readmission_probability=readmission_prob,
            readmission_risk=risk_level,
            health_score=health_score,
            recommendations=recommendations,
        )

    except Exception as e:
        logger.error(f"Error in patient prediction: {str(e)}")
        raise


@svc.api(
    input=JSON(pydantic_model=CustomerChurnRequest),
    output=JSON(pydantic_model=CustomerChurnResponse),
)
async def predict_customer_churn(
    request: CustomerChurnRequest,
) -> CustomerChurnResponse:
    """Predict customer churn risk."""
    try:
        # Engineer features
        features = feature_engineer.engineer_customer_features(request.dict())

        # Get prediction
        runner = svc.runners[1]
        prediction_proba = await runner.predict.async_run(features)

        # Extract churn probability
        churn_prob = float(prediction_proba[0][1])

        # Determine risk level
        if churn_prob >= 0.7:
            risk_level = "High"
        elif churn_prob >= 0.3:
            risk_level = "Medium"
        else:
            risk_level = "Low"

        # Calculate retention score
        retention_score = 1.0 - churn_prob

        # Generate recommended actions
        actions = []
        if risk_level == "High":
            actions.extend(
                [
                    "Send personalized retention offer",
                    "Assign to customer success manager",
                    "Offer loyalty program enrollment",
                ]
            )
        elif risk_level == "Medium":
            actions.extend(
                [
                    "Send re-engagement email campaign",
                    "Provide product recommendations",
                    "Offer limited-time discount",
                ]
            )
        else:
            actions.append("Continue standard engagement")

        if request.days_since_last_order > 60:
            actions.append("Send win-back campaign")

        if request.total_spent > 1000:
            actions.append("Offer VIP status upgrade")

        return CustomerChurnResponse(
            customer_id=request.customer_id,
            churn_probability=churn_prob,
            churn_risk=risk_level,
            retention_score=retention_score,
            recommended_actions=actions,
        )

    except Exception as e:
        logger.error(f"Error in customer churn prediction: {str(e)}")
        raise


@svc.api(
    input=JSON(pydantic_model=IoTAnomalyRequest),
    output=JSON(pydantic_model=IoTAnomalyResponse),
)
async def detect_iot_anomaly(request: IoTAnomalyRequest) -> IoTAnomalyResponse:
    """Detect IoT sensor anomalies."""
    try:
        # Engineer features
        features = feature_engineer.engineer_iot_features(request.dict())

        # Get prediction
        runner = svc.runners[2]
        prediction = await runner.predict.async_run(features)

        # Get anomaly score (probability of being anomalous)
        prediction_proba = await runner.predict_proba.async_run(features)
        anomaly_score = float(prediction_proba[0][1])

        # Determine if anomaly
        is_anomaly = bool(prediction[0] == 1)

        # Calculate maintenance urgency
        maintenance_urgency = min(
            (request.last_maintenance_days / 180.0) * 0.5 + anomaly_score * 0.5, 1.0
        )

        # Determine recommended action
        if is_anomaly and maintenance_urgency > 0.7:
            action = "Schedule immediate maintenance"
        elif is_anomaly:
            action = "Investigate anomaly, schedule maintenance check"
        elif maintenance_urgency > 0.7:
            action = "Schedule preventive maintenance"
        else:
            action = "Continue monitoring"

        return IoTAnomalyResponse(
            device_id=request.device_id,
            is_anomaly=is_anomaly,
            anomaly_score=anomaly_score,
            maintenance_urgency=maintenance_urgency,
            recommended_action=action,
        )

    except Exception as e:
        logger.error(f"Error in IoT anomaly detection: {str(e)}")
        raise


# Batch prediction endpoints
@svc.api(input=PandasDataFrame(), output=PandasDataFrame())
async def batch_predict_patients(df: pd.DataFrame) -> pd.DataFrame:
    """Batch prediction for multiple patients."""
    results = []

    for _, row in df.iterrows():
        request = PatientPredictionRequest(**row.to_dict())
        response = await predict_patient_readmission(request)
        results.append(response.dict())

    return pd.DataFrame(results)


@svc.api(input=PandasDataFrame(), output=PandasDataFrame())
async def batch_predict_customers(df: pd.DataFrame) -> pd.DataFrame:
    """Batch prediction for multiple customers."""
    results = []

    for _, row in df.iterrows():
        request = CustomerChurnRequest(**row.to_dict())
        response = await predict_customer_churn(request)
        results.append(response.dict())

    return pd.DataFrame(results)


@svc.api(input=PandasDataFrame(), output=PandasDataFrame())
async def batch_detect_anomalies(df: pd.DataFrame) -> pd.DataFrame:
    """Batch anomaly detection for IoT devices."""
    results = []

    for _, row in df.iterrows():
        request = IoTAnomalyRequest(**row.to_dict())
        response = await detect_iot_anomaly(request)
        results.append(response.dict())

    return pd.DataFrame(results)


# Health check endpoint
@svc.api(input=JSON(), output=JSON())
async def health_check(request: Dict) -> Dict:
    """Health check endpoint."""
    return {
        "status": "healthy",
        "models": {
            "patient_model": "loaded",
            "customer_model": "loaded",
            "iot_model": "loaded",
        },
        "timestamp": pd.Timestamp.now().isoformat(),
    }


# Model metadata endpoint
@svc.api(input=JSON(), output=JSON())
async def model_info(request: Dict) -> Dict:
    """Get model information."""
    return {
        "patient_model": {
            "version": str(patient_model.tag),
            "framework": "sklearn",
            "features": 10,
            "target": "readmission",
        },
        "customer_model": {
            "version": str(customer_model.tag),
            "framework": "sklearn",
            "features": 9,
            "target": "churn",
        },
        "iot_model": {
            "version": str(iot_model.tag),
            "framework": "sklearn",
            "features": 8,
            "target": "anomaly",
        },
    }
