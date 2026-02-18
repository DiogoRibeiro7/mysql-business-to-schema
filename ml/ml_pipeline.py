#!/usr/bin/env python3
"""
Machine Learning Pipeline for MySQL Business-to-Schema

Provides ML capabilities for all database examples including:
- Predictive analytics
- Recommendation systems
- Anomaly detection
- Time series forecasting
- Customer segmentation
- Fraud detection
"""

import os
import sys
import json
import pickle
import logging
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple, Union
from dataclasses import dataclass
from enum import Enum
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler, LabelEncoder, MinMaxScaler
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor, IsolationForest
from sklearn.cluster import KMeans, DBSCAN
from sklearn.decomposition import PCA
from sklearn.metrics import (
    accuracy_score, precision_recall_fscore_support, mean_squared_error,
    mean_absolute_error, r2_score, silhouette_score, classification_report
)
import xgboost as xgb
import lightgbm as lgb
from prophet import Prophet
import joblib

# Deep Learning imports (optional)
try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers, models, callbacks
    DEEP_LEARNING_AVAILABLE = True
except ImportError:
    DEEP_LEARNING_AVAILABLE = False
    print("TensorFlow not available. Deep learning models disabled.")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ==============================================================================
# Core Classes
# ==============================================================================

class ModelType(Enum):
    """Supported ML model types"""
    CLASSIFICATION = "classification"
    REGRESSION = "regression"
    CLUSTERING = "clustering"
    ANOMALY_DETECTION = "anomaly_detection"
    TIME_SERIES = "time_series"
    RECOMMENDATION = "recommendation"
    NLP = "nlp"

@dataclass
class ModelConfig:
    """Configuration for ML models"""
    model_type: ModelType
    algorithm: str
    hyperparameters: Dict[str, Any]
    feature_columns: List[str]
    target_column: Optional[str]
    validation_split: float = 0.2
    random_state: int = 42

@dataclass
class ModelMetrics:
    """Container for model performance metrics"""
    model_name: str
    model_type: ModelType
    training_time: float
    metrics: Dict[str, float]
    feature_importance: Optional[Dict[str, float]] = None
    confusion_matrix: Optional[np.ndarray] = None
    predictions: Optional[np.ndarray] = None

# ==============================================================================
# Base ML Pipeline
# ==============================================================================

class MLPipeline:
    """Base machine learning pipeline"""

    def __init__(self, config: ModelConfig):
        """Initialize ML pipeline"""
        self.config = config
        self.model = None
        self.scaler = None
        self.encoder = None
        self.feature_names = []
        self.metrics = None
        self.is_trained = False

    def preprocess_data(self, df: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Preprocess data for training"""
        logger.info("Preprocessing data...")

        # Handle missing values
        df = self._handle_missing_values(df)

        # Encode categorical variables
        df = self._encode_categorical(df)

        # Extract features and target
        X = df[self.config.feature_columns].values
        y = None
        if self.config.target_column:
            y = df[self.config.target_column].values

        # Scale features
        if self.scaler is None:
            self.scaler = StandardScaler()
            X = self.scaler.fit_transform(X)
        else:
            X = self.scaler.transform(X)

        return X, y

    def _handle_missing_values(self, df: pd.DataFrame) -> pd.DataFrame:
        """Handle missing values in dataframe"""
        # Numeric columns: fill with median
        numeric_columns = df.select_dtypes(include=[np.number]).columns
        df[numeric_columns] = df[numeric_columns].fillna(df[numeric_columns].median())

        # Categorical columns: fill with mode
        categorical_columns = df.select_dtypes(include=['object']).columns
        for col in categorical_columns:
            df[col] = df[col].fillna(df[col].mode()[0] if not df[col].mode().empty else 'unknown')

        return df

    def _encode_categorical(self, df: pd.DataFrame) -> pd.DataFrame:
        """Encode categorical variables"""
        categorical_columns = df.select_dtypes(include=['object']).columns

        for col in categorical_columns:
            if col in self.config.feature_columns:
                if self.encoder is None:
                    self.encoder = {}

                if col not in self.encoder:
                    self.encoder[col] = LabelEncoder()
                    df[col] = self.encoder[col].fit_transform(df[col])
                else:
                    df[col] = self.encoder[col].transform(df[col])

        return df

    def train(self, df: pd.DataFrame) -> ModelMetrics:
        """Train the model"""
        logger.info(f"Training {self.config.algorithm} model...")

        start_time = datetime.now()

        # Preprocess data
        X, y = self.preprocess_data(df)

        # Split data
        if self.config.model_type in [ModelType.CLASSIFICATION, ModelType.REGRESSION]:
            X_train, X_test, y_train, y_test = train_test_split(
                X, y, test_size=self.config.validation_split,
                random_state=self.config.random_state
            )
        else:
            X_train, X_test = X, X
            y_train, y_test = None, None

        # Initialize and train model
        self.model = self._initialize_model()

        if y_train is not None:
            self.model.fit(X_train, y_train)
        else:
            self.model.fit(X_train)

        # Calculate metrics
        training_time = (datetime.now() - start_time).total_seconds()
        metrics = self._calculate_metrics(X_test, y_test)

        # Get feature importance
        feature_importance = self._get_feature_importance()

        self.is_trained = True

        self.metrics = ModelMetrics(
            model_name=self.config.algorithm,
            model_type=self.config.model_type,
            training_time=training_time,
            metrics=metrics,
            feature_importance=feature_importance
        )

        logger.info(f"Training completed in {training_time:.2f} seconds")
        logger.info(f"Metrics: {metrics}")

        return self.metrics

    def _initialize_model(self):
        """Initialize the ML model based on configuration"""
        if self.config.algorithm == "random_forest_classifier":
            return RandomForestClassifier(**self.config.hyperparameters)
        elif self.config.algorithm == "random_forest_regressor":
            return RandomForestRegressor(**self.config.hyperparameters)
        elif self.config.algorithm == "xgboost_classifier":
            return xgb.XGBClassifier(**self.config.hyperparameters)
        elif self.config.algorithm == "xgboost_regressor":
            return xgb.XGBRegressor(**self.config.hyperparameters)
        elif self.config.algorithm == "lightgbm_classifier":
            return lgb.LGBMClassifier(**self.config.hyperparameters)
        elif self.config.algorithm == "lightgbm_regressor":
            return lgb.LGBMRegressor(**self.config.hyperparameters)
        elif self.config.algorithm == "kmeans":
            return KMeans(**self.config.hyperparameters)
        elif self.config.algorithm == "dbscan":
            return DBSCAN(**self.config.hyperparameters)
        elif self.config.algorithm == "isolation_forest":
            return IsolationForest(**self.config.hyperparameters)
        else:
            raise ValueError(f"Unknown algorithm: {self.config.algorithm}")

    def _calculate_metrics(self, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, float]:
        """Calculate model performance metrics"""
        metrics = {}

        if self.config.model_type == ModelType.CLASSIFICATION and y_test is not None:
            y_pred = self.model.predict(X_test)
            metrics['accuracy'] = accuracy_score(y_test, y_pred)
            precision, recall, f1, _ = precision_recall_fscore_support(y_test, y_pred, average='weighted')
            metrics['precision'] = precision
            metrics['recall'] = recall
            metrics['f1_score'] = f1

        elif self.config.model_type == ModelType.REGRESSION and y_test is not None:
            y_pred = self.model.predict(X_test)
            metrics['mse'] = mean_squared_error(y_test, y_pred)
            metrics['rmse'] = np.sqrt(metrics['mse'])
            metrics['mae'] = mean_absolute_error(y_test, y_pred)
            metrics['r2'] = r2_score(y_test, y_pred)

        elif self.config.model_type == ModelType.CLUSTERING:
            labels = self.model.labels_ if hasattr(self.model, 'labels_') else self.model.predict(X_test)
            if len(np.unique(labels)) > 1:
                metrics['silhouette_score'] = silhouette_score(X_test, labels)
            metrics['n_clusters'] = len(np.unique(labels))

        elif self.config.model_type == ModelType.ANOMALY_DETECTION:
            predictions = self.model.predict(X_test)
            metrics['anomaly_rate'] = (predictions == -1).mean()

        return metrics

    def _get_feature_importance(self) -> Optional[Dict[str, float]]:
        """Get feature importance if available"""
        if hasattr(self.model, 'feature_importances_'):
            importance = self.model.feature_importances_
            return {
                self.config.feature_columns[i]: importance[i]
                for i in range(len(self.config.feature_columns))
            }
        return None

    def predict(self, df: pd.DataFrame) -> np.ndarray:
        """Make predictions on new data"""
        if not self.is_trained:
            raise ValueError("Model must be trained before making predictions")

        X, _ = self.preprocess_data(df)

        if hasattr(self.model, 'predict'):
            return self.model.predict(X)
        else:
            raise ValueError("Model does not support prediction")

    def save_model(self, path: str):
        """Save trained model to disk"""
        if not self.is_trained:
            raise ValueError("Model must be trained before saving")

        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'encoder': self.encoder,
            'config': self.config,
            'metrics': self.metrics
        }

        with open(path, 'wb') as f:
            joblib.dump(model_data, f)

        logger.info(f"Model saved to {path}")

    def load_model(self, path: str):
        """Load trained model from disk"""
        with open(path, 'rb') as f:
            model_data = joblib.load(f)

        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.encoder = model_data['encoder']
        self.config = model_data['config']
        self.metrics = model_data['metrics']
        self.is_trained = True

        logger.info(f"Model loaded from {path}")

# ==============================================================================
# Specialized ML Models
# ==============================================================================

class RecommendationSystem(MLPipeline):
    """Recommendation system using collaborative filtering"""

    def __init__(self, algorithm: str = "matrix_factorization"):
        """Initialize recommendation system"""
        config = ModelConfig(
            model_type=ModelType.RECOMMENDATION,
            algorithm=algorithm,
            hyperparameters={},
            feature_columns=[],
            target_column=None
        )
        super().__init__(config)
        self.user_item_matrix = None
        self.user_features = None
        self.item_features = None

    def build_user_item_matrix(self, df: pd.DataFrame, user_col: str, item_col: str, rating_col: str):
        """Build user-item interaction matrix"""
        self.user_item_matrix = df.pivot_table(
            index=user_col,
            columns=item_col,
            values=rating_col,
            fill_value=0
        )
        return self.user_item_matrix

    def train_collaborative_filtering(self, n_factors: int = 50):
        """Train collaborative filtering model using matrix factorization"""
        from sklearn.decomposition import NMF

        # Apply NMF for matrix factorization
        nmf = NMF(n_components=n_factors, random_state=42)
        self.user_features = nmf.fit_transform(self.user_item_matrix)
        self.item_features = nmf.components_.T

        # Calculate reconstruction error
        reconstructed = np.dot(self.user_features, self.item_features.T)
        error = np.mean((self.user_item_matrix - reconstructed) ** 2)

        logger.info(f"Collaborative filtering trained with reconstruction error: {error:.4f}")

    def get_recommendations(self, user_id: int, n_recommendations: int = 10) -> List[Tuple[int, float]]:
        """Get recommendations for a user"""
        if user_id not in self.user_item_matrix.index:
            return []

        user_idx = self.user_item_matrix.index.get_loc(user_id)
        user_vector = self.user_features[user_idx]

        # Calculate scores for all items
        scores = np.dot(user_vector, self.item_features.T)

        # Get items user hasn't interacted with
        user_items = self.user_item_matrix.loc[user_id]
        unrated_items = user_items[user_items == 0].index

        # Get top recommendations
        recommendations = []
        for item in unrated_items:
            item_idx = self.user_item_matrix.columns.get_loc(item)
            score = scores[item_idx]
            recommendations.append((item, score))

        recommendations.sort(key=lambda x: x[1], reverse=True)
        return recommendations[:n_recommendations]

class AnomalyDetector(MLPipeline):
    """Anomaly detection for fraud and outlier detection"""

    def __init__(self, algorithm: str = "isolation_forest"):
        """Initialize anomaly detector"""
        hyperparameters = {
            'contamination': 0.1,
            'random_state': 42
        }

        config = ModelConfig(
            model_type=ModelType.ANOMALY_DETECTION,
            algorithm=algorithm,
            hyperparameters=hyperparameters,
            feature_columns=[],
            target_column=None
        )
        super().__init__(config)

    def detect_anomalies(self, df: pd.DataFrame, sensitivity: float = 0.1) -> pd.DataFrame:
        """Detect anomalies in data"""
        # Update contamination based on sensitivity
        self.config.hyperparameters['contamination'] = sensitivity

        # Set feature columns
        self.config.feature_columns = df.select_dtypes(include=[np.number]).columns.tolist()

        # Train model
        self.train(df)

        # Get predictions
        X, _ = self.preprocess_data(df)
        predictions = self.model.predict(X)
        scores = self.model.score_samples(X)

        # Add results to dataframe
        df['is_anomaly'] = predictions == -1
        df['anomaly_score'] = scores

        return df

class TimeSeriesForecaster:
    """Time series forecasting using Prophet and LSTM"""

    def __init__(self, algorithm: str = "prophet"):
        """Initialize time series forecaster"""
        self.algorithm = algorithm
        self.model = None
        self.scaler = None

    def prepare_data(self, df: pd.DataFrame, date_col: str, value_col: str) -> pd.DataFrame:
        """Prepare data for time series forecasting"""
        # Prophet requires specific column names
        ts_df = df[[date_col, value_col]].copy()
        ts_df.columns = ['ds', 'y']
        ts_df['ds'] = pd.to_datetime(ts_df['ds'])
        return ts_df

    def train_prophet(self, df: pd.DataFrame, **kwargs):
        """Train Prophet model"""
        self.model = Prophet(**kwargs)
        self.model.fit(df)
        logger.info("Prophet model trained successfully")

    def train_lstm(self, df: pd.DataFrame, sequence_length: int = 30):
        """Train LSTM model for time series"""
        if not DEEP_LEARNING_AVAILABLE:
            raise ImportError("TensorFlow is required for LSTM models")

        # Scale data
        self.scaler = MinMaxScaler()
        scaled_data = self.scaler.fit_transform(df[['y']].values)

        # Create sequences
        X, y = [], []
        for i in range(sequence_length, len(scaled_data)):
            X.append(scaled_data[i-sequence_length:i, 0])
            y.append(scaled_data[i, 0])

        X, y = np.array(X), np.array(y)
        X = np.reshape(X, (X.shape[0], X.shape[1], 1))

        # Build LSTM model
        self.model = models.Sequential([
            layers.LSTM(50, return_sequences=True, input_shape=(sequence_length, 1)),
            layers.LSTM(50, return_sequences=False),
            layers.Dense(25),
            layers.Dense(1)
        ])

        self.model.compile(optimizer='adam', loss='mean_squared_error')

        # Train model
        self.model.fit(
            X, y,
            batch_size=32,
            epochs=10,
            validation_split=0.2,
            verbose=0
        )

        logger.info("LSTM model trained successfully")

    def forecast(self, periods: int) -> pd.DataFrame:
        """Generate forecast"""
        if self.algorithm == "prophet":
            future = self.model.make_future_dataframe(periods=periods)
            forecast = self.model.predict(future)
            return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']]
        elif self.algorithm == "lstm":
            # LSTM forecasting logic
            pass
        else:
            raise ValueError(f"Unknown algorithm: {self.algorithm}")

class CustomerSegmentation(MLPipeline):
    """Customer segmentation using clustering algorithms"""

    def __init__(self, algorithm: str = "kmeans", n_clusters: int = 5):
        """Initialize customer segmentation"""
        hyperparameters = {
            'n_clusters': n_clusters,
            'random_state': 42
        }

        config = ModelConfig(
            model_type=ModelType.CLUSTERING,
            algorithm=algorithm,
            hyperparameters=hyperparameters,
            feature_columns=[],
            target_column=None
        )
        super().__init__(config)

    def segment_customers(self, df: pd.DataFrame, features: List[str]) -> pd.DataFrame:
        """Segment customers based on features"""
        # Set feature columns
        self.config.feature_columns = features

        # Train model
        self.train(df)

        # Get cluster assignments
        X, _ = self.preprocess_data(df)
        df['segment'] = self.model.predict(X)

        # Calculate segment profiles
        for feature in features:
            segment_means = df.groupby('segment')[feature].mean()
            logger.info(f"Segment means for {feature}: {segment_means.to_dict()}")

        return df

# ==============================================================================
# Use Case Specific Models
# ==============================================================================

class EcommercePredictiveAnalytics:
    """Predictive analytics for e-commerce"""

    def __init__(self):
        self.churn_model = None
        self.ltv_model = None
        self.demand_forecaster = None

    def predict_churn(self, df: pd.DataFrame) -> pd.DataFrame:
        """Predict customer churn"""
        # Feature engineering
        features = [
            'days_since_last_order',
            'order_count',
            'total_spent',
            'avg_order_value',
            'product_diversity',
            'return_rate'
        ]

        config = ModelConfig(
            model_type=ModelType.CLASSIFICATION,
            algorithm="xgboost_classifier",
            hyperparameters={
                'n_estimators': 100,
                'max_depth': 5,
                'learning_rate': 0.1
            },
            feature_columns=features,
            target_column='churned'
        )

        self.churn_model = MLPipeline(config)
        metrics = self.churn_model.train(df)

        # Add predictions
        df['churn_probability'] = self.churn_model.model.predict_proba(
            self.churn_model.preprocess_data(df)[0]
        )[:, 1]

        return df

    def predict_ltv(self, df: pd.DataFrame) -> pd.DataFrame:
        """Predict customer lifetime value"""
        features = [
            'age',
            'order_count',
            'avg_order_value',
            'days_as_customer',
            'product_categories_purchased'
        ]

        config = ModelConfig(
            model_type=ModelType.REGRESSION,
            algorithm="lightgbm_regressor",
            hyperparameters={
                'n_estimators': 100,
                'num_leaves': 31,
                'learning_rate': 0.1
            },
            feature_columns=features,
            target_column='lifetime_value'
        )

        self.ltv_model = MLPipeline(config)
        metrics = self.ltv_model.train(df)

        # Add predictions
        df['predicted_ltv'] = self.ltv_model.predict(df)

        return df

class FintechFraudDetection:
    """Fraud detection for fintech applications"""

    def __init__(self):
        self.fraud_detector = None
        self.risk_scorer = None

    def detect_fraud(self, df: pd.DataFrame) -> pd.DataFrame:
        """Detect fraudulent transactions"""
        # Feature engineering
        df['hour'] = pd.to_datetime(df['transaction_time']).dt.hour
        df['day_of_week'] = pd.to_datetime(df['transaction_time']).dt.dayofweek
        df['amount_zscore'] = (df['amount'] - df['amount'].mean()) / df['amount'].std()

        # Anomaly detection
        detector = AnomalyDetector()
        df = detector.detect_anomalies(df, sensitivity=0.05)

        # Supervised fraud detection if labels available
        if 'is_fraud' in df.columns:
            features = [
                'amount', 'amount_zscore', 'hour', 'day_of_week',
                'merchant_risk_score', 'customer_risk_score',
                'days_since_last_transaction'
            ]

            config = ModelConfig(
                model_type=ModelType.CLASSIFICATION,
                algorithm="xgboost_classifier",
                hyperparameters={
                    'n_estimators': 200,
                    'max_depth': 6,
                    'scale_pos_weight': 10  # Handle imbalanced data
                },
                feature_columns=features,
                target_column='is_fraud'
            )

            self.fraud_detector = MLPipeline(config)
            self.fraud_detector.train(df)

            # Add fraud probability
            df['fraud_probability'] = self.fraud_detector.model.predict_proba(
                self.fraud_detector.preprocess_data(df)[0]
            )[:, 1]

        return df

# ==============================================================================
# Model Serving and Deployment
# ==============================================================================

class ModelServer:
    """Model serving infrastructure"""

    def __init__(self, model_registry_path: str = "./models"):
        """Initialize model server"""
        self.model_registry_path = model_registry_path
        self.loaded_models = {}

    def register_model(self, model_name: str, model: MLPipeline, version: str = "v1"):
        """Register a trained model"""
        model_path = os.path.join(self.model_registry_path, f"{model_name}_{version}.pkl")
        os.makedirs(self.model_registry_path, exist_ok=True)
        model.save_model(model_path)
        logger.info(f"Model {model_name} version {version} registered")

    def load_model(self, model_name: str, version: str = "v1") -> MLPipeline:
        """Load a registered model"""
        model_key = f"{model_name}_{version}"

        if model_key not in self.loaded_models:
            model_path = os.path.join(self.model_registry_path, f"{model_key}.pkl")
            model = MLPipeline(ModelConfig(
                model_type=ModelType.CLASSIFICATION,
                algorithm="placeholder",
                hyperparameters={},
                feature_columns=[],
                target_column=None
            ))
            model.load_model(model_path)
            self.loaded_models[model_key] = model

        return self.loaded_models[model_key]

    def predict(self, model_name: str, data: Union[pd.DataFrame, Dict], version: str = "v1"):
        """Make prediction using registered model"""
        model = self.load_model(model_name, version)

        if isinstance(data, dict):
            data = pd.DataFrame([data])

        return model.predict(data)

    def get_model_info(self, model_name: str, version: str = "v1") -> Dict:
        """Get model information"""
        model = self.load_model(model_name, version)

        return {
            'model_name': model_name,
            'version': version,
            'model_type': model.config.model_type.value,
            'algorithm': model.config.algorithm,
            'features': model.config.feature_columns,
            'metrics': model.metrics.metrics if model.metrics else {}
        }

# ==============================================================================
# Main Execution
# ==============================================================================

def main():
    """Example usage of ML pipeline"""

    # Generate sample data
    np.random.seed(42)
    n_samples = 1000

    # E-commerce sample data
    ecommerce_data = pd.DataFrame({
        'customer_id': range(n_samples),
        'days_since_last_order': np.random.exponential(30, n_samples),
        'order_count': np.random.poisson(5, n_samples),
        'total_spent': np.random.gamma(2, 100, n_samples),
        'avg_order_value': np.random.normal(50, 15, n_samples),
        'product_diversity': np.random.uniform(1, 10, n_samples),
        'return_rate': np.random.beta(2, 10, n_samples),
        'churned': np.random.binomial(1, 0.3, n_samples)
    })

    # Customer churn prediction
    print("Training customer churn model...")
    analytics = EcommercePredictiveAnalytics()
    ecommerce_data = analytics.predict_churn(ecommerce_data)
    print(f"Churn predictions: {ecommerce_data['churn_probability'].describe()}")

    # Customer segmentation
    print("\nPerforming customer segmentation...")
    segmentation = CustomerSegmentation(n_clusters=4)
    features = ['order_count', 'total_spent', 'avg_order_value', 'product_diversity']
    ecommerce_data = segmentation.segment_customers(ecommerce_data, features)
    print(f"Segments: {ecommerce_data['segment'].value_counts()}")

    # Anomaly detection
    print("\nDetecting anomalies...")
    detector = AnomalyDetector()
    ecommerce_data = detector.detect_anomalies(ecommerce_data, sensitivity=0.1)
    print(f"Anomalies detected: {ecommerce_data['is_anomaly'].sum()}")

    # Model serving
    print("\nSetting up model server...")
    server = ModelServer()
    server.register_model("churn_predictor", analytics.churn_model)

    # Test prediction
    test_customer = pd.DataFrame([{
        'days_since_last_order': 60,
        'order_count': 2,
        'total_spent': 150,
        'avg_order_value': 75,
        'product_diversity': 3,
        'return_rate': 0.1
    }])

    prediction = server.predict("churn_predictor", test_customer)
    print(f"Churn prediction for test customer: {prediction[0]}")

    print("\nML Pipeline demonstration complete!")

if __name__ == "__main__":
    main()