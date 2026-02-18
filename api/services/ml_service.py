"""
Machine Learning Microservice
Handles all ML operations including training, prediction, and model management
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks, File, UploadFile
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
import os
import sys
import json
import pickle
import joblib
from datetime import datetime
import asyncio
import logging
import pandas as pd
import numpy as np
from pathlib import Path
import uuid

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

# Import ML modules
from ml.ml_pipeline import (
    MLPipeline, RecommendationSystem, AnomalyDetector,
    TimeSeriesForecaster, CustomerSegmentation,
    EcommercePredictiveAnalytics, FintechFraudDetection,
    ModelServer
)
from ml.healthcare_ml import (
    HealthcarePredictiveAnalytics, MedicalImageAnalytics,
    ClinicalTrialAnalytics
)
from ml.iot_smart_city_ml import (
    SmartWasteManagement, SmartEnergyOptimization,
    UrbanTrafficOptimization
)
from ml.social_streaming_ml import (
    SocialMediaAnalytics, StreamingPlatformAnalytics
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="ML Microservice",
    description="Machine Learning model training, prediction, and management service",
    version="1.0.0"
)

# Request/Response Models
class ModelInfo(BaseModel):
    model_id: str
    name: str
    type: str
    version: str
    status: str
    accuracy: Optional[float] = None
    created_at: datetime
    last_used: Optional[datetime] = None


class TrainRequest(BaseModel):
    dataset: str
    model_type: str
    parameters: Optional[Dict[str, Any]] = {}
    test_split: float = Field(default=0.2, ge=0.1, le=0.5)
    cross_validation: bool = True


class TrainResponse(BaseModel):
    model_id: str
    status: str
    metrics: Dict[str, float]
    training_time_seconds: float
    model_path: str


class PredictRequest(BaseModel):
    model_id: Optional[str] = None
    model_name: Optional[str] = None
    data: Dict[str, Any]
    return_probabilities: bool = False


class PredictResponse(BaseModel):
    model_id: str
    predictions: Any
    probabilities: Optional[List[float]] = None
    prediction_time_ms: float
    metadata: Optional[Dict[str, Any]] = None


class BatchPredictRequest(BaseModel):
    model_id: str
    data_path: str
    output_path: Optional[str] = None
    batch_size: int = Field(default=1000, ge=1, le=100000)


class ModelMetricsResponse(BaseModel):
    model_id: str
    metrics: Dict[str, Any]
    confusion_matrix: Optional[List[List[int]]] = None
    feature_importance: Optional[Dict[str, float]] = None
    performance_over_time: Optional[List[Dict]] = None


# Model Registry
model_server = ModelServer(model_registry_path="models/registry")

# Specialized model instances
specialized_models = {
    "ecommerce": EcommercePredictiveAnalytics(),
    "fintech": FintechFraudDetection(),
    "healthcare": HealthcarePredictiveAnalytics(),
    "medical_imaging": MedicalImageAnalytics(),
    "clinical_trials": ClinicalTrialAnalytics(),
    "waste_management": SmartWasteManagement(),
    "energy_optimization": SmartEnergyOptimization(),
    "traffic": UrbanTrafficOptimization(),
    "social_media": SocialMediaAnalytics(),
    "streaming": StreamingPlatformAnalytics()
}


# Helper functions
async def train_model_async(
    dataset: str,
    model_type: str,
    parameters: Dict[str, Any],
    test_split: float
) -> Dict[str, Any]:
    """Train model asynchronously"""
    import time
    start_time = time.time()

    try:
        # Load dataset (simulated)
        df = pd.DataFrame({
            'feature1': np.random.randn(1000),
            'feature2': np.random.randn(1000),
            'feature3': np.random.randn(1000),
            'target': np.random.choice([0, 1], 1000)
        })

        # Create ML pipeline
        pipeline = MLPipeline(
            model_type=model_type,
            task_type=parameters.get('task_type', 'classification'),
            features=['feature1', 'feature2', 'feature3'],
            target='target',
            hyperparameters=parameters.get('hyperparameters', {})
        )

        # Train model
        metrics = pipeline.train(df)

        # Generate model ID
        model_id = str(uuid.uuid4())

        # Register model
        model_server.register_model(
            model=pipeline,
            name=f"{dataset}_{model_type}",
            version="1.0.0",
            metrics=metrics
        )

        training_time = time.time() - start_time

        # Save model
        model_path = Path("models") / f"{model_id}.pkl"
        model_path.parent.mkdir(parents=True, exist_ok=True)
        joblib.dump(pipeline, model_path)

        return {
            "model_id": model_id,
            "status": "completed",
            "metrics": metrics,
            "training_time_seconds": training_time,
            "model_path": str(model_path)
        }

    except Exception as e:
        logger.error(f"Error training model: {e}")
        return {
            "model_id": "",
            "status": f"failed: {str(e)}",
            "metrics": {},
            "training_time_seconds": time.time() - start_time,
            "model_path": ""
        }


# API Endpoints

@app.get("/health")
async def health_check():
    """Service health check"""
    return {
        "service": "ml",
        "status": "healthy",
        "models_loaded": len(model_server.models),
        "timestamp": datetime.now().isoformat()
    }


@app.get("/models", response_model=List[ModelInfo])
async def list_models(
    model_type: Optional[str] = None,
    status: Optional[str] = None
):
    """List available ML models"""
    models = model_server.list_models(name=model_type)

    model_list = []
    for model_meta in models:
        model_list.append(ModelInfo(
            model_id=model_meta["model_id"],
            name=model_meta["name"],
            type=model_meta.get("type", "unknown"),
            version=model_meta["version"],
            status=model_meta.get("status", "active"),
            accuracy=model_meta.get("metrics", {}).get("accuracy"),
            created_at=model_meta["created_at"],
            last_used=model_meta.get("last_used")
        ))

    return model_list


@app.get("/models/{model_id}")
async def get_model_info(model_id: str):
    """Get detailed information about a specific model"""
    if model_id not in model_server.models:
        raise HTTPException(status_code=404, detail=f"Model {model_id} not found")

    model_meta = model_server.models[model_id]
    model = model_server.load_model(model_id)

    return {
        "model_id": model_id,
        "metadata": model_meta,
        "model_type": getattr(model, 'model_type', 'unknown'),
        "features": getattr(model, 'features', []),
        "target": getattr(model, 'target', None),
        "hyperparameters": getattr(model, 'hyperparameters', {})
    }


@app.post("/models/train", response_model=TrainResponse)
async def train_model(
    request: TrainRequest,
    background_tasks: BackgroundTasks
):
    """Train a new ML model"""
    # For long training jobs, run in background
    if request.parameters.get("epochs", 0) > 100:
        model_id = str(uuid.uuid4())
        background_tasks.add_task(
            train_model_async,
            request.dataset,
            request.model_type,
            request.parameters,
            request.test_split
        )
        return TrainResponse(
            model_id=model_id,
            status="training",
            metrics={},
            training_time_seconds=0,
            model_path=""
        )
    else:
        # Train synchronously for small models
        result = await train_model_async(
            request.dataset,
            request.model_type,
            request.parameters,
            request.test_split
        )
        return TrainResponse(**result)


@app.post("/models/{model_name}/predict", response_model=PredictResponse)
async def predict(model_name: str, request: PredictRequest):
    """Make predictions using a model"""
    import time
    start_time = time.time()

    # Handle specialized models
    if model_name in specialized_models:
        model = specialized_models[model_name]

        # Convert input data to DataFrame
        df = pd.DataFrame([request.data])

        # Call appropriate prediction method
        if model_name == "ecommerce":
            if "predict_churn" in request.data.get("task", ""):
                predictions = model.predict_churn(df)
            elif "predict_ltv" in request.data.get("task", ""):
                predictions = model.predict_lifetime_value(df)
            else:
                predictions = model.predict_churn(df)

        elif model_name == "fintech":
            predictions = model.detect_fraud(df)

        elif model_name == "healthcare":
            predictions = model.predict_patient_risk(df)

        elif model_name == "waste_management":
            predictions = model.predict_bin_fill_time(df)

        elif model_name == "social_media":
            if "virality" in request.data.get("task", ""):
                predictions = model.predict_content_virality(df)
            else:
                predictions = model.detect_trending_topics(df)

        else:
            predictions = {"error": f"No prediction method for {model_name}"}

        prediction_time = (time.time() - start_time) * 1000

        return PredictResponse(
            model_id=model_name,
            predictions=predictions.to_dict() if hasattr(predictions, 'to_dict') else predictions,
            prediction_time_ms=prediction_time
        )

    # Handle registered models
    elif request.model_id and request.model_id in model_server.models:
        predictions = model_server.predict(request.model_id, pd.DataFrame([request.data]))

        prediction_time = (time.time() - start_time) * 1000

        return PredictResponse(
            model_id=request.model_id,
            predictions=predictions.tolist() if hasattr(predictions, 'tolist') else predictions,
            prediction_time_ms=prediction_time
        )

    else:
        raise HTTPException(status_code=404, detail=f"Model {model_name} not found")


@app.post("/models/batch_predict")
async def batch_predict(
    request: BatchPredictRequest,
    background_tasks: BackgroundTasks
):
    """Batch prediction on large datasets"""
    if request.model_id not in model_server.models:
        raise HTTPException(status_code=404, detail=f"Model {request.model_id} not found")

    # Run batch prediction in background
    job_id = str(uuid.uuid4())

    async def run_batch_prediction():
        try:
            # Load data
            df = pd.read_csv(request.data_path)

            # Make predictions in batches
            predictions = []
            for i in range(0, len(df), request.batch_size):
                batch = df.iloc[i:i+request.batch_size]
                batch_preds = model_server.predict(request.model_id, batch)
                predictions.extend(batch_preds)

            # Save results
            output_path = request.output_path or f"predictions/{job_id}.csv"
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)

            results_df = df.copy()
            results_df['predictions'] = predictions
            results_df.to_csv(output_path, index=False)

            logger.info(f"Batch prediction {job_id} completed")

        except Exception as e:
            logger.error(f"Batch prediction {job_id} failed: {e}")

    background_tasks.add_task(run_batch_prediction)

    return {
        "job_id": job_id,
        "status": "processing",
        "model_id": request.model_id,
        "data_path": request.data_path,
        "batch_size": request.batch_size
    }


@app.get("/models/{model_id}/metrics", response_model=ModelMetricsResponse)
async def get_model_metrics(model_id: str):
    """Get detailed metrics for a model"""
    if model_id not in model_server.models:
        raise HTTPException(status_code=404, detail=f"Model {model_id} not found")

    model_meta = model_server.models[model_id]

    # Get stored metrics
    metrics = model_meta.get("metrics", {})

    # Add performance over time (simulated)
    performance_over_time = [
        {
            "date": (datetime.now() - timedelta(days=i)).isoformat(),
            "accuracy": metrics.get("accuracy", 0.9) + np.random.uniform(-0.05, 0.05),
            "predictions_count": np.random.randint(100, 1000)
        }
        for i in range(7)
    ]

    return ModelMetricsResponse(
        model_id=model_id,
        metrics=metrics,
        performance_over_time=performance_over_time
    )


@app.post("/models/{model_id}/retrain")
async def retrain_model(
    model_id: str,
    dataset_path: Optional[str] = None,
    background_tasks: BackgroundTasks = None
):
    """Retrain an existing model with new data"""
    if model_id not in model_server.models:
        raise HTTPException(status_code=404, detail=f"Model {model_id} not found")

    # Load existing model
    model = model_server.load_model(model_id)

    async def retrain():
        try:
            # Load new training data
            if dataset_path:
                df = pd.read_csv(dataset_path)
            else:
                # Use synthetic data for demo
                df = pd.DataFrame({
                    'feature1': np.random.randn(1000),
                    'feature2': np.random.randn(1000),
                    'feature3': np.random.randn(1000),
                    'target': np.random.choice([0, 1], 1000)
                })

            # Retrain model
            metrics = model.train(df)

            # Update model registry
            model_server.models[model_id]["metrics"] = metrics
            model_server.models[model_id]["last_trained"] = datetime.now()

            logger.info(f"Model {model_id} retrained successfully")

        except Exception as e:
            logger.error(f"Failed to retrain model {model_id}: {e}")

    background_tasks.add_task(retrain)

    return {
        "model_id": model_id,
        "status": "retraining",
        "message": "Model retraining initiated"
    }


@app.delete("/models/{model_id}")
async def delete_model(model_id: str):
    """Delete a model"""
    if model_id not in model_server.models:
        raise HTTPException(status_code=404, detail=f"Model {model_id} not found")

    # Remove from registry
    del model_server.models[model_id]

    # Delete model file
    model_path = Path("models") / f"{model_id}.pkl"
    if model_path.exists():
        model_path.unlink()

    return {
        "model_id": model_id,
        "status": "deleted",
        "message": f"Model {model_id} has been deleted"
    }


@app.post("/models/upload")
async def upload_model(
    file: UploadFile = File(...),
    name: str = "uploaded_model",
    version: str = "1.0.0"
):
    """Upload a pre-trained model"""
    try:
        # Save uploaded file
        model_id = str(uuid.uuid4())
        model_path = Path("models") / f"{model_id}.pkl"
        model_path.parent.mkdir(parents=True, exist_ok=True)

        content = await file.read()
        with open(model_path, 'wb') as f:
            f.write(content)

        # Load and register model
        model = joblib.load(model_path)

        model_server.register_model(
            model=model,
            name=name,
            version=version
        )

        return {
            "model_id": model_id,
            "status": "uploaded",
            "name": name,
            "version": version,
            "file_size": len(content)
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to upload model: {str(e)}")


@app.get("/algorithms")
async def list_algorithms():
    """List available ML algorithms"""
    return {
        "classification": [
            "random_forest",
            "gradient_boosting",
            "logistic_regression",
            "svm",
            "neural_network"
        ],
        "regression": [
            "linear_regression",
            "random_forest",
            "gradient_boosting",
            "neural_network"
        ],
        "clustering": [
            "kmeans",
            "dbscan",
            "hierarchical",
            "gaussian_mixture"
        ],
        "time_series": [
            "prophet",
            "arima",
            "lstm",
            "exponential_smoothing"
        ],
        "recommendation": [
            "als",
            "content_based",
            "hybrid",
            "deep_learning"
        ],
        "anomaly_detection": [
            "isolation_forest",
            "autoencoder",
            "statistical",
            "one_class_svm"
        ]
    }


@app.get("/datasets")
async def list_datasets():
    """List available datasets for training"""
    return {
        "datasets": [
            {
                "name": "ecommerce_transactions",
                "rows": 100000,
                "features": 15,
                "target": "churned",
                "task": "classification"
            },
            {
                "name": "fintech_fraud",
                "rows": 50000,
                "features": 20,
                "target": "is_fraud",
                "task": "classification"
            },
            {
                "name": "healthcare_vitals",
                "rows": 75000,
                "features": 12,
                "target": "risk_score",
                "task": "regression"
            },
            {
                "name": "social_media_posts",
                "rows": 200000,
                "features": 25,
                "target": "engagement",
                "task": "regression"
            },
            {
                "name": "energy_consumption",
                "rows": 35000,
                "features": 10,
                "target": "consumption",
                "task": "time_series"
            }
        ]
    }


from datetime import timedelta

@app.post("/models/automl")
async def auto_ml(
    dataset: str,
    target: str,
    task_type: str = "classification",
    optimization_metric: str = "accuracy",
    time_limit_minutes: int = 30,
    background_tasks: BackgroundTasks = None
):
    """Automated machine learning - finds best model for dataset"""
    job_id = str(uuid.uuid4())

    async def run_automl():
        try:
            # Simulate AutoML process
            models_to_try = [
                "random_forest",
                "gradient_boosting",
                "logistic_regression",
                "neural_network"
            ]

            best_model = None
            best_score = 0

            for model_type in models_to_try:
                # Train and evaluate each model
                result = await train_model_async(
                    dataset=dataset,
                    model_type=model_type,
                    parameters={"task_type": task_type},
                    test_split=0.2
                )

                score = result["metrics"].get(optimization_metric, 0)
                if score > best_score:
                    best_score = score
                    best_model = result

            logger.info(f"AutoML job {job_id} completed. Best model: {best_model}")

        except Exception as e:
            logger.error(f"AutoML job {job_id} failed: {e}")

    background_tasks.add_task(run_automl)

    return {
        "job_id": job_id,
        "status": "running",
        "dataset": dataset,
        "target": target,
        "task_type": task_type,
        "optimization_metric": optimization_metric,
        "estimated_completion": (datetime.now() + timedelta(minutes=time_limit_minutes)).isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002, log_level="info")