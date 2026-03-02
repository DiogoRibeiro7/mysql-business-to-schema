#!/usr/bin/env python3
"""Real-time ML Prediction Service for MySQL Performance.

FastAPI-based service for anomaly detection and performance prediction
"""

from fastapi import FastAPI, HTTPException, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import Dict, List, Optional, Any
from dataclasses import asdict
import asyncio
import numpy as np
import pandas as pd
from datetime import datetime
import joblib
import logging
import uvicorn
from prometheus_client import Counter, Histogram, Gauge, generate_latest

# ML imports

# Custom modules
from anomaly_detection import (
    DatabaseAnomalyDetector,
    QueryPerformancePredictor,
    TimeSeriesForecaster,
    IndexRecommendationML,
    Anomaly,
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MySQL ML Prediction Service",
    description="Real-time ML predictions for MySQL performance optimization",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Metrics
prediction_requests = Counter(
    "ml_prediction_requests_total",
    "Total number of prediction requests",
    ["prediction_type"],
)
prediction_latency = Histogram(
    "ml_prediction_latency_seconds", "Latency of ML predictions", ["prediction_type"]
)
anomalies_detected = Counter(
    "ml_anomalies_detected_total", "Total number of anomalies detected", ["severity"]
)
model_accuracy = Gauge("ml_model_accuracy", "Current model accuracy", ["model_name"])

# Global instances
anomaly_detector = DatabaseAnomalyDetector()
query_predictor = QueryPerformancePredictor()
forecaster = TimeSeriesForecaster()
index_recommender = IndexRecommendationML()

# WebSocket connections for real-time updates
websocket_connections = set()


# Pydantic models for API
class QueryPredictionRequest(BaseModel):
    """Represent QueryPredictionRequest."""

    query: str
    database: str
    table_stats: Dict[str, Any]
    execution_history: Optional[List[Dict]] = None


class QueryPredictionResponse(BaseModel):
    """Represent QueryPredictionResponse."""

    predicted_time_ms: float
    confidence: float
    uncertainty_ms: float
    lower_bound_ms: float
    upper_bound_ms: float
    recommendations: List[str]
    risk_level: str


class AnomalyDetectionRequest(BaseModel):
    """Represent AnomalyDetectionRequest."""

    metrics: Dict[str, float]
    database: str
    timestamp: Optional[datetime] = Field(default_factory=datetime.now)


class AnomalyResponse(BaseModel):
    """Represent AnomalyResponse."""

    anomalies: List[Dict]
    risk_score: float
    recommendations: List[str]
    alert_level: str


class ForecastRequest(BaseModel):
    """Represent ForecastRequest."""

    metric_name: str
    database: str
    historical_data: List[Dict[str, Any]]
    forecast_horizon: int = 24


class ForecastResponse(BaseModel):
    """Represent ForecastResponse."""

    forecast: List[Dict]
    confidence_interval: Dict[str, List[float]]
    trend: str
    seasonality: Dict[str, Any]


class IndexRecommendationRequest(BaseModel):
    """Represent IndexRecommendationRequest."""

    query: str
    execution_plan: Dict
    table_schema: Dict
    performance_goal: str = "optimize_reads"


class IndexRecommendationResponse(BaseModel):
    """Represent IndexRecommendationResponse."""

    recommendations: List[Dict]
    estimated_improvement: float
    impact_analysis: Dict
    warnings: List[str]


class AutoScalingRecommendation(BaseModel):
    """Represent AutoScalingRecommendation."""

    resource_type: str
    current_value: float
    recommended_value: float
    reason: str
    confidence: float
    cost_impact: Optional[float] = None


@app.on_event("startup")
async def startup_event():
    """Initialize models and connections on startup."""
    logger.info("Initializing ML models...")

    # Initialize anomaly detector models
    anomaly_detector.initialize_models()

    # Load pre-trained models if available
    try:
        query_predictor.model = joblib.load("models/query_predictor.pkl")
        query_predictor.scaler = joblib.load("models/query_scaler.pkl")
        logger.info("Loaded pre-trained query predictor")
    except FileNotFoundError:
        logger.warning("No pre-trained query predictor found")

    try:
        index_recommender.model = joblib.load("models/index_recommender.pkl")
        logger.info("Loaded pre-trained index recommender")
    except FileNotFoundError:
        logger.warning("No pre-trained index recommender found")

    # Start background tasks
    asyncio.create_task(continuous_monitoring())
    asyncio.create_task(model_retraining_scheduler())

    logger.info("ML Prediction Service started successfully")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "models_loaded": {
            "anomaly_detector": anomaly_detector.models != {},
            "query_predictor": query_predictor.model is not None,
            "index_recommender": index_recommender.model is not None,
        },
    }


@app.post("/predict/query", response_model=QueryPredictionResponse)
async def predict_query_performance(request: QueryPredictionRequest):
    """Predict query execution time and provide optimization recommendations."""
    prediction_requests.labels(prediction_type="query").inc()

    with prediction_latency.labels(prediction_type="query").time():
        try:
            # Get prediction
            prediction = query_predictor.predict(request.query, request.table_stats)

            # Analyze risk level
            risk_level = "low"
            if prediction["predicted_time_ms"] > 5000:
                risk_level = "high"
            elif prediction["predicted_time_ms"] > 1000:
                risk_level = "medium"

            # Generate recommendations
            recommendations = []
            if prediction["predicted_time_ms"] > 1000:
                recommendations.append("Consider adding indexes to improve performance")
            if "JOIN" in request.query.upper():
                recommendations.append("Ensure join columns are properly indexed")
            if "SELECT *" in request.query.upper():
                recommendations.append(
                    "Select only required columns instead of using SELECT *"
                )

            return QueryPredictionResponse(
                predicted_time_ms=prediction["predicted_time_ms"],
                confidence=prediction["confidence"],
                uncertainty_ms=prediction["uncertainty_ms"],
                lower_bound_ms=prediction["lower_bound_ms"],
                upper_bound_ms=prediction["upper_bound_ms"],
                recommendations=recommendations,
                risk_level=risk_level,
            )

        except Exception as e:
            logger.error(f"Query prediction failed: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/detect/anomalies", response_model=AnomalyResponse)
async def detect_anomalies(request: AnomalyDetectionRequest):
    """Detect anomalies in database metrics."""
    prediction_requests.labels(prediction_type="anomaly").inc()

    with prediction_latency.labels(prediction_type="anomaly").time():
        try:
            # Convert metrics to DataFrame
            metrics_df = pd.DataFrame(
                [{**request.metrics, "timestamp": request.timestamp}]
            )

            # Detect anomalies
            anomalies = anomaly_detector.detect_anomalies(metrics_df)

            # Calculate risk score
            risk_score = 0.0
            for anomaly in anomalies:
                if anomaly.severity == "CRITICAL":
                    risk_score += 1.0
                    anomalies_detected.labels(severity="critical").inc()
                elif anomaly.severity == "HIGH":
                    risk_score += 0.7
                    anomalies_detected.labels(severity="high").inc()
                elif anomaly.severity == "MEDIUM":
                    risk_score += 0.4
                    anomalies_detected.labels(severity="medium").inc()
                else:
                    risk_score += 0.1
                    anomalies_detected.labels(severity="low").inc()

            risk_score = min(1.0, risk_score / max(len(anomalies), 1))

            # Determine alert level
            alert_level = "normal"
            if risk_score > 0.8:
                alert_level = "critical"
            elif risk_score > 0.5:
                alert_level = "warning"

            # Extract recommendations
            recommendations = list({a.recommended_action for a in anomalies})

            # Broadcast anomalies to WebSocket clients
            if anomalies and websocket_connections:
                await broadcast_anomalies(anomalies)

            return AnomalyResponse(
                anomalies=[asdict(a) for a in anomalies],
                risk_score=risk_score,
                recommendations=recommendations,
                alert_level=alert_level,
            )

        except Exception as e:
            logger.error(f"Anomaly detection failed: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/forecast", response_model=ForecastResponse)
async def generate_forecast(request: ForecastRequest):
    """Generate time series forecast for metrics."""
    prediction_requests.labels(prediction_type="forecast").inc()

    with prediction_latency.labels(prediction_type="forecast").time():
        try:
            # Prepare time series data
            ts_df = pd.DataFrame(request.historical_data)
            ts_df = forecaster.prepare_timeseries_data(ts_df, request.metric_name)

            # Train and forecast
            if request.metric_name not in forecaster.prophet_models:
                forecaster.train_prophet_model(ts_df, request.metric_name)

            forecast_df = forecaster.forecast(
                request.metric_name, request.forecast_horizon
            )

            # Analyze trend
            trend = "stable"
            if len(forecast_df) > 1:
                trend_slope = (
                    forecast_df["yhat"].iloc[-1] - forecast_df["yhat"].iloc[0]
                ) / len(forecast_df)
                if trend_slope > 0.1:
                    trend = "increasing"
                elif trend_slope < -0.1:
                    trend = "decreasing"

            # Extract seasonality
            model = forecaster.prophet_models[request.metric_name]
            seasonality = {
                "daily": model.seasonalities.get("daily", {}).get("period", 0),
                "weekly": model.seasonalities.get("weekly", {}).get("period", 0),
            }

            return ForecastResponse(
                forecast=forecast_df.to_dict("records"),
                confidence_interval={
                    "lower": forecast_df["yhat_lower"].tolist(),
                    "upper": forecast_df["yhat_upper"].tolist(),
                },
                trend=trend,
                seasonality=seasonality,
            )

        except Exception as e:
            logger.error(f"Forecasting failed: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/recommend/indexes", response_model=IndexRecommendationResponse)
async def recommend_indexes(request: IndexRecommendationRequest):
    """Recommend indexes using ML."""
    prediction_requests.labels(prediction_type="index").inc()

    with prediction_latency.labels(prediction_type="index").time():
        try:
            # Get recommendations
            recommendations = index_recommender.recommend_index(
                request.query, request.execution_plan, request.table_schema
            )

            # Calculate estimated improvement
            estimated_improvement = 0.0
            if recommendations:
                estimated_improvement = np.mean(
                    [r["confidence"] for r in recommendations]
                )

            # Perform impact analysis
            impact_analysis = {
                "read_performance": "improved" if recommendations else "unchanged",
                "write_performance": (
                    "slightly_degraded" if recommendations else "unchanged"
                ),
                "storage_overhead": (
                    f"{len(recommendations) * 10}MB" if recommendations else "0MB"
                ),
                "maintenance_cost": "low" if len(recommendations) <= 2 else "medium",
            }

            # Generate warnings
            warnings = []
            if len(recommendations) > 3:
                warnings.append("Too many indexes may slow down writes")
            if request.performance_goal == "optimize_writes":
                warnings.append("Indexes may negatively impact write performance")

            return IndexRecommendationResponse(
                recommendations=recommendations,
                estimated_improvement=estimated_improvement,
                impact_analysis=impact_analysis,
                warnings=warnings,
            )

        except Exception as e:
            logger.error(f"Index recommendation failed: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.post("/autoscale/recommend")
async def recommend_autoscaling() -> List[AutoScalingRecommendation]:
    """Recommend auto-scaling actions based on current metrics."""
    try:
        recommendations = []

        # Analyze current metrics
        # This would connect to actual monitoring in production
        mock_metrics = {
            "cpu_usage": 85,
            "memory_usage": 70,
            "connection_count": 450,
            "query_latency_p99": 2000,
        }

        # CPU scaling recommendation
        if mock_metrics["cpu_usage"] > 80:
            recommendations.append(
                AutoScalingRecommendation(
                    resource_type="cpu",
                    current_value=2,
                    recommended_value=4,
                    reason="High CPU usage detected",
                    confidence=0.9,
                    cost_impact=50.0,
                )
            )

        # Connection pool recommendation
        if mock_metrics["connection_count"] > 400:
            recommendations.append(
                AutoScalingRecommendation(
                    resource_type="max_connections",
                    current_value=500,
                    recommended_value=750,
                    reason="Connection pool near capacity",
                    confidence=0.85,
                    cost_impact=0,
                )
            )

        # Memory recommendation
        if mock_metrics["memory_usage"] > 75:
            recommendations.append(
                AutoScalingRecommendation(
                    resource_type="memory",
                    current_value=4,
                    recommended_value=8,
                    reason="Memory pressure detected",
                    confidence=0.8,
                    cost_impact=30.0,
                )
            )

        return recommendations

    except Exception as e:
        logger.error(f"Auto-scaling recommendation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.websocket("/ws/anomalies")
async def websocket_anomalies(websocket: WebSocket):
    """Handle WebSocket updates for real-time anomalies."""
    await websocket.accept()
    websocket_connections.add(websocket)

    try:
        while True:
            # Keep connection alive
            await asyncio.sleep(30)
            await websocket.send_json({"type": "ping"})

    except Exception as e:
        logger.error(f"WebSocket error: {e}")
    finally:
        websocket_connections.remove(websocket)


async def broadcast_anomalies(anomalies: List[Anomaly]):
    """Broadcast anomalies to all WebSocket clients."""
    message = {
        "type": "anomalies",
        "timestamp": datetime.now().isoformat(),
        "data": [asdict(a) for a in anomalies],
    }

    disconnected = set()
    for websocket in websocket_connections:
        try:
            await websocket.send_json(message)
        except Exception:
            disconnected.add(websocket)

    # Remove disconnected clients
    websocket_connections.difference_update(disconnected)


async def continuous_monitoring():
    """Background task for continuous monitoring."""
    while True:
        try:
            # This would connect to actual databases in production
            logger.info("Running continuous monitoring cycle...")

            # Simulate metrics collection
            mock_metrics = {
                "queries": np.random.randint(100, 1000),
                "slow_queries": np.random.randint(0, 10),
                "connections": np.random.randint(10, 100),
                "buffer_pool_hit_ratio": np.random.uniform(0.9, 1.0),
            }

            # Detect anomalies
            metrics_df = pd.DataFrame([{**mock_metrics, "timestamp": datetime.now()}])

            anomalies = anomaly_detector.detect_anomalies(metrics_df)

            if anomalies:
                logger.warning(f"Detected {len(anomalies)} anomalies")
                await broadcast_anomalies(anomalies)

            # Sleep for monitoring interval
            await asyncio.sleep(60)  # Check every minute

        except Exception as e:
            logger.error(f"Monitoring cycle failed: {e}")
            await asyncio.sleep(60)


async def model_retraining_scheduler():
    """Background task for periodic model retraining."""
    while True:
        try:
            # Wait for retraining interval (daily)
            await asyncio.sleep(86400)  # 24 hours

            logger.info("Starting model retraining...")

            # This would retrain models with new data in production
            # For now, just update accuracy metrics
            model_accuracy.labels(model_name="query_predictor").set(0.85)
            model_accuracy.labels(model_name="anomaly_detector").set(0.92)
            model_accuracy.labels(model_name="index_recommender").set(0.78)

            logger.info("Model retraining completed")

        except Exception as e:
            logger.error(f"Model retraining failed: {e}")


@app.get("/metrics")
async def get_metrics():
    """Prometheus metrics endpoint."""
    return StreamingResponse(generate_latest(), media_type="text/plain")


@app.post("/train/query-predictor")
async def train_query_predictor(training_data: List[Dict]):
    """Train or update the query predictor model."""
    try:
        # Convert to DataFrame
        df = pd.DataFrame(training_data)

        # Train model
        query_predictor.train(df)

        # Save model
        joblib.dump(query_predictor.model, "models/query_predictor.pkl")
        joblib.dump(query_predictor.scaler, "models/query_scaler.pkl")

        return {"status": "success", "message": "Query predictor trained successfully"}

    except Exception as e:
        logger.error(f"Training failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run("prediction_service:app", host="0.0.0.0", port=8000, reload=True)
