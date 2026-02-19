#!/usr/bin/env python3
"""
ML-based Anomaly Detection and Prediction System for MySQL Databases
Uses various ML algorithms for detecting anomalies and predicting performance issues
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest, RandomForestRegressor
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error, mean_squared_error
import joblib
import mysql.connector
from datetime import datetime, timedelta
import logging
from typing import Dict, List, Tuple, Optional, Any
import warnings
import json
from dataclasses import dataclass, asdict

# Deep learning imports
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, Model
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset

# Time series specific
from statsmodels.tsa.seasonal import seasonal_decompose
from statsmodels.tsa.stattools import adfuller
from prophet import Prophet
import pmdarima as pm

# Anomaly detection
from pyod.models.iforest import IForest
from pyod.models.lof import LOF
from pyod.models.auto_encoder import AutoEncoder
from pyod.models.vae import VAE

warnings.filterwarnings('ignore')
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@dataclass
class Anomaly:
    """Represents a detected anomaly"""
    timestamp: datetime
    metric: str
    value: float
    expected_value: float
    deviation: float
    severity: str
    confidence: float
    description: str
    recommended_action: str


class QueryPerformancePredictor:
    """Predicts query execution time and resource usage"""

    def __init__(self):
        self.model = None
        self.scaler = StandardScaler()
        self.feature_columns = []
        self.label_encoders = {}

    def extract_features(self, query: str, table_stats: Dict) -> np.ndarray:
        """Extract features from SQL query and table statistics"""
        features = {}

        # Query complexity features
        query_upper = query.upper()
        features['query_length'] = len(query)
        features['join_count'] = query_upper.count('JOIN')
        features['where_count'] = query_upper.count('WHERE')
        features['group_by'] = 1 if 'GROUP BY' in query_upper else 0
        features['order_by'] = 1 if 'ORDER BY' in query_upper else 0
        features['having'] = 1 if 'HAVING' in query_upper else 0
        features['subquery_count'] = query_upper.count('SELECT') - 1
        features['union_count'] = query_upper.count('UNION')
        features['distinct'] = 1 if 'DISTINCT' in query_upper else 0
        features['limit'] = 1 if 'LIMIT' in query_upper else 0

        # Table statistics features
        features['table_rows'] = table_stats.get('rows', 0)
        features['table_size_mb'] = table_stats.get('size_mb', 0)
        features['index_count'] = table_stats.get('index_count', 0)
        features['avg_row_length'] = table_stats.get('avg_row_length', 0)

        # Time-based features
        now = datetime.now()
        features['hour_of_day'] = now.hour
        features['day_of_week'] = now.weekday()
        features['is_weekend'] = 1 if now.weekday() >= 5 else 0

        return np.array(list(features.values())).reshape(1, -1)

    def train(self, training_data: pd.DataFrame):
        """Train the query performance prediction model"""
        logger.info("Training query performance predictor...")

        # Prepare features and target
        X = training_data.drop(['execution_time', 'query_text'], axis=1)
        y = training_data['execution_time']

        # Scale features
        X_scaled = self.scaler.fit_transform(X)

        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X_scaled, y, test_size=0.2, random_state=42
        )

        # Train Random Forest model
        self.model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            min_samples_split=5,
            random_state=42,
            n_jobs=-1
        )
        self.model.fit(X_train, y_train)

        # Evaluate
        y_pred = self.model.predict(X_test)
        mae = mean_absolute_error(y_test, y_pred)
        rmse = np.sqrt(mean_squared_error(y_test, y_pred))

        logger.info(f"Model trained. MAE: {mae:.2f}ms, RMSE: {rmse:.2f}ms")

        # Feature importance
        feature_importance = pd.DataFrame({
            'feature': X.columns,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)

        logger.info(f"Top features:\n{feature_importance.head()}")

        return self.model

    def predict(self, query: str, table_stats: Dict) -> Dict[str, float]:
        """Predict query execution time and confidence"""
        if not self.model:
            raise ValueError("Model not trained")

        features = self.extract_features(query, table_stats)
        features_scaled = self.scaler.transform(features)

        # Get prediction with uncertainty
        predictions = []
        for tree in self.model.estimators_:
            predictions.append(tree.predict(features_scaled)[0])

        pred_mean = np.mean(predictions)
        pred_std = np.std(predictions)
        confidence = 1 / (1 + pred_std / pred_mean) if pred_mean > 0 else 0

        return {
            'predicted_time_ms': pred_mean,
            'confidence': confidence,
            'uncertainty_ms': pred_std,
            'lower_bound_ms': pred_mean - 2 * pred_std,
            'upper_bound_ms': pred_mean + 2 * pred_std
        }


class DatabaseAnomalyDetector:
    """Detects anomalies in database metrics using multiple ML algorithms"""

    def __init__(self):
        self.models = {}
        self.scalers = {}
        self.thresholds = {}
        self.history = []

    def initialize_models(self):
        """Initialize different anomaly detection models"""
        # Isolation Forest for general anomalies
        self.models['isolation_forest'] = IForest(
            contamination=0.1,
            random_state=42
        )

        # Local Outlier Factor for density-based anomalies
        self.models['lof'] = LOF(
            n_neighbors=20,
            contamination=0.1
        )

        # AutoEncoder for complex pattern anomalies
        self.models['autoencoder'] = self._build_autoencoder()

        # Variational AutoEncoder
        self.models['vae'] = VAE(
            encoder_neurons=[128, 64, 32],
            decoder_neurons=[32, 64, 128],
            contamination=0.1,
            random_state=42
        )

    def _build_autoencoder(self) -> Model:
        """Build autoencoder model for anomaly detection"""
        input_dim = 20  # Number of metrics

        # Encoder
        encoder_input = layers.Input(shape=(input_dim,))
        encoded = layers.Dense(64, activation='relu')(encoder_input)
        encoded = layers.Dropout(0.2)(encoded)
        encoded = layers.Dense(32, activation='relu')(encoded)
        encoded = layers.Dense(16, activation='relu')(encoded)

        # Decoder
        decoded = layers.Dense(32, activation='relu')(encoded)
        decoded = layers.Dropout(0.2)(decoded)
        decoded = layers.Dense(64, activation='relu')(decoded)
        decoder_output = layers.Dense(input_dim, activation='linear')(decoded)

        # Model
        autoencoder = Model(encoder_input, decoder_output)
        autoencoder.compile(optimizer='adam', loss='mse')

        return autoencoder

    def collect_metrics(self, connection) -> pd.DataFrame:
        """Collect current database metrics"""
        cursor = connection.cursor(dictionary=True)

        metrics = {}

        # Performance metrics
        cursor.execute("""
            SELECT
                Variable_name,
                Variable_value
            FROM performance_schema.global_status
            WHERE Variable_name IN (
                'Queries', 'Slow_queries', 'Connections',
                'Threads_connected', 'Threads_running',
                'Table_locks_waited', 'Table_locks_immediate',
                'Innodb_buffer_pool_reads', 'Innodb_buffer_pool_read_requests',
                'Innodb_row_lock_waits', 'Innodb_row_lock_time',
                'Com_select', 'Com_insert', 'Com_update', 'Com_delete'
            )
        """)

        for row in cursor.fetchall():
            metrics[row['Variable_name'].lower()] = float(row['Variable_value'])

        # Calculate derived metrics
        if 'innodb_buffer_pool_read_requests' in metrics:
            hit_ratio = 1 - (metrics.get('innodb_buffer_pool_reads', 0) /
                           max(metrics.get('innodb_buffer_pool_read_requests', 1), 1))
            metrics['buffer_pool_hit_ratio'] = hit_ratio

        if 'table_locks_immediate' in metrics:
            lock_wait_ratio = metrics.get('table_locks_waited', 0) / \
                            max(metrics.get('table_locks_immediate', 1) +
                               metrics.get('table_locks_waited', 0), 1)
            metrics['table_lock_wait_ratio'] = lock_wait_ratio

        # System metrics
        cursor.execute("""
            SELECT
                COUNT(*) as active_connections,
                AVG(TIME) as avg_query_time,
                MAX(TIME) as max_query_time
            FROM information_schema.PROCESSLIST
            WHERE COMMAND != 'Sleep'
        """)

        result = cursor.fetchone()
        if result:
            metrics.update(result)

        cursor.close()

        # Add timestamp
        metrics['timestamp'] = datetime.now()

        return pd.DataFrame([metrics])

    def detect_anomalies(self, metrics_df: pd.DataFrame) -> List[Anomaly]:
        """Detect anomalies using ensemble of models"""
        anomalies = []

        # Prepare data
        feature_cols = [col for col in metrics_df.columns
                       if col not in ['timestamp']]
        X = metrics_df[feature_cols].values

        # Scale data
        if 'main' not in self.scalers:
            self.scalers['main'] = StandardScaler()
            X_scaled = self.scalers['main'].fit_transform(X)
        else:
            X_scaled = self.scalers['main'].transform(X)

        # Ensemble anomaly detection
        anomaly_scores = {}

        # Isolation Forest
        if 'isolation_forest' in self.models:
            if_scores = self.models['isolation_forest'].decision_function(X_scaled)
            anomaly_scores['isolation_forest'] = if_scores

        # LOF
        if 'lof' in self.models:
            lof_scores = self.models['lof'].decision_function(X_scaled)
            anomaly_scores['lof'] = lof_scores

        # Combine scores
        ensemble_score = np.mean(list(anomaly_scores.values()), axis=0)

        # Determine anomalies
        threshold = np.percentile(np.abs(ensemble_score), 95)

        for i, score in enumerate(ensemble_score):
            if np.abs(score) > threshold:
                # Find which metrics are anomalous
                for j, col in enumerate(feature_cols):
                    value = X[i, j]

                    # Calculate expected value from history
                    if len(self.history) > 0:
                        historical_values = [h[col] for h in self.history[-100:]
                                           if col in h]
                        if historical_values:
                            expected = np.mean(historical_values)
                            std = np.std(historical_values)

                            if np.abs(value - expected) > 3 * std:
                                anomaly = Anomaly(
                                    timestamp=metrics_df.iloc[i]['timestamp'],
                                    metric=col,
                                    value=value,
                                    expected_value=expected,
                                    deviation=(value - expected) / std if std > 0 else 0,
                                    severity=self._calculate_severity(
                                        value, expected, std
                                    ),
                                    confidence=min(0.95, np.abs(score) / threshold),
                                    description=self._generate_description(
                                        col, value, expected
                                    ),
                                    recommended_action=self._recommend_action(
                                        col, value, expected
                                    )
                                )
                                anomalies.append(anomaly)

        # Update history
        self.history.extend(metrics_df.to_dict('records'))
        if len(self.history) > 10000:
            self.history = self.history[-10000:]

        return anomalies

    def _calculate_severity(self, value: float, expected: float,
                           std: float) -> str:
        """Calculate anomaly severity"""
        if std == 0:
            return 'LOW'

        deviation = np.abs(value - expected) / std

        if deviation > 5:
            return 'CRITICAL'
        elif deviation > 3:
            return 'HIGH'
        elif deviation > 2:
            return 'MEDIUM'
        else:
            return 'LOW'

    def _generate_description(self, metric: str, value: float,
                             expected: float) -> str:
        """Generate human-readable anomaly description"""
        descriptions = {
            'slow_queries': f"Slow query rate is {value:.0f}, expected {expected:.0f}",
            'threads_connected': f"Connected threads: {value:.0f}, normal range around {expected:.0f}",
            'table_locks_waited': f"Table lock waits increased to {value:.0f}",
            'buffer_pool_hit_ratio': f"Buffer pool hit ratio dropped to {value:.2%}",
            'queries': f"Query rate: {value:.0f}/sec, expected {expected:.0f}/sec"
        }

        return descriptions.get(
            metric,
            f"{metric} value {value:.2f} deviates from expected {expected:.2f}"
        )

    def _recommend_action(self, metric: str, value: float,
                         expected: float) -> str:
        """Recommend action based on anomaly"""
        recommendations = {
            'slow_queries': "Review slow query log and optimize problematic queries",
            'threads_connected': "Check for connection leaks or increase max_connections",
            'table_locks_waited': "Consider using InnoDB instead of MyISAM, or optimize locking queries",
            'buffer_pool_hit_ratio': "Increase innodb_buffer_pool_size or optimize queries",
            'queries': "Monitor for potential DDoS or application issues"
        }

        return recommendations.get(
            metric,
            "Monitor the metric and investigate if it persists"
        )


class TimeSeriesForecaster:
    """Forecasts database metrics using time series models"""

    def __init__(self):
        self.models = {}
        self.prophet_models = {}

    def prepare_timeseries_data(self, metrics_df: pd.DataFrame,
                               metric_name: str) -> pd.DataFrame:
        """Prepare data for time series forecasting"""
        ts_df = pd.DataFrame({
            'ds': pd.to_datetime(metrics_df['timestamp']),
            'y': metrics_df[metric_name]
        })
        return ts_df.dropna()

    def train_prophet_model(self, ts_df: pd.DataFrame,
                           metric_name: str) -> Prophet:
        """Train Prophet model for forecasting"""
        model = Prophet(
            daily_seasonality=True,
            weekly_seasonality=True,
            yearly_seasonality=False,
            changepoint_prior_scale=0.05,
            seasonality_prior_scale=10,
            interval_width=0.95
        )

        # Add additional regressors if needed
        if 'hour' in ts_df.columns:
            model.add_regressor('hour')

        model.fit(ts_df)
        self.prophet_models[metric_name] = model

        return model

    def forecast(self, metric_name: str, periods: int = 24) -> pd.DataFrame:
        """Generate forecasts for a metric"""
        if metric_name not in self.prophet_models:
            raise ValueError(f"No model trained for {metric_name}")

        model = self.prophet_models[metric_name]

        # Create future dataframe
        future = model.make_future_dataframe(periods=periods, freq='H')

        # Add regressors
        future['hour'] = future['ds'].dt.hour

        # Generate forecast
        forecast = model.predict(future)

        return forecast[['ds', 'yhat', 'yhat_lower', 'yhat_upper']]

    def detect_forecast_anomalies(self, actual: pd.DataFrame,
                                 forecast: pd.DataFrame) -> List[Anomaly]:
        """Detect anomalies based on forecast"""
        anomalies = []

        merged = pd.merge(
            actual,
            forecast,
            left_on='timestamp',
            right_on='ds',
            how='inner'
        )

        for _, row in merged.iterrows():
            if row['value'] < row['yhat_lower'] or row['value'] > row['yhat_upper']:
                anomaly = Anomaly(
                    timestamp=row['timestamp'],
                    metric='forecasted_metric',
                    value=row['value'],
                    expected_value=row['yhat'],
                    deviation=(row['value'] - row['yhat']) / row['yhat'],
                    severity='HIGH' if abs(row['value'] - row['yhat']) >
                            2 * (row['yhat_upper'] - row['yhat']) else 'MEDIUM',
                    confidence=0.95,
                    description=f"Value {row['value']} outside forecast range "
                              f"[{row['yhat_lower']:.2f}, {row['yhat_upper']:.2f}]",
                    recommended_action="Investigate unusual activity"
                )
                anomalies.append(anomaly)

        return anomalies


class IndexRecommendationML:
    """ML-based index recommendation system"""

    def __init__(self):
        self.model = None
        self.feature_extractor = None

    def extract_query_features(self, query: str,
                              execution_plan: Dict) -> np.ndarray:
        """Extract features from query and execution plan"""
        features = {}

        # Query features
        query_upper = query.upper()
        features['query_length'] = len(query)
        features['table_count'] = query_upper.count('FROM') + query_upper.count('JOIN')

        # WHERE clause analysis
        where_match = query_upper.find('WHERE')
        if where_match != -1:
            where_clause = query_upper[where_match:]
            features['where_conditions'] = where_clause.count('AND') + \
                                          where_clause.count('OR') + 1
            features['where_equality'] = where_clause.count('=')
            features['where_inequality'] = where_clause.count('>') + \
                                          where_clause.count('<')
            features['where_like'] = where_clause.count('LIKE')
            features['where_in'] = where_clause.count('IN')
        else:
            features['where_conditions'] = 0
            features['where_equality'] = 0
            features['where_inequality'] = 0
            features['where_like'] = 0
            features['where_in'] = 0

        # Execution plan features
        features['rows_examined'] = execution_plan.get('rows_examined', 0)
        features['rows_sent'] = execution_plan.get('rows_sent', 0)
        features['execution_time_ms'] = execution_plan.get('execution_time', 0)
        features['using_index'] = 1 if execution_plan.get('key') else 0
        features['using_filesort'] = 1 if 'filesort' in \
                                         execution_plan.get('Extra', '') else 0
        features['using_temporary'] = 1 if 'temporary' in \
                                          execution_plan.get('Extra', '') else 0

        return np.array(list(features.values()))

    def train_index_recommender(self, training_data: List[Dict]):
        """Train ML model to recommend indexes"""
        # Prepare training data
        X = []
        y = []  # 1 if index improved performance, 0 otherwise

        for sample in training_data:
            features = self.extract_query_features(
                sample['query'],
                sample['execution_plan']
            )
            X.append(features)
            y.append(1 if sample['index_helped'] else 0)

        X = np.array(X)
        y = np.array(y)

        # Train XGBoost classifier
        from xgboost import XGBClassifier

        self.model = XGBClassifier(
            n_estimators=100,
            max_depth=5,
            learning_rate=0.1,
            random_state=42
        )

        self.model.fit(X, y)

        logger.info("Index recommendation model trained")

    def recommend_index(self, query: str, execution_plan: Dict,
                       table_schema: Dict) -> List[Dict]:
        """Recommend indexes for a query"""
        if not self.model:
            raise ValueError("Model not trained")

        features = self.extract_query_features(query, execution_plan)
        probability = self.model.predict_proba(features.reshape(1, -1))[0, 1]

        recommendations = []

        if probability > 0.7:
            # Extract columns from WHERE clause
            columns = self._extract_where_columns(query, table_schema)

            if columns:
                recommendations.append({
                    'columns': columns,
                    'type': 'BTREE',
                    'confidence': probability,
                    'estimated_improvement': f"{(probability * 100):.0f}%",
                    'reason': 'ML model predicts significant performance improvement',
                    'create_statement': self._generate_create_index(
                        table_schema['name'], columns
                    )
                })

        return recommendations

    def _extract_where_columns(self, query: str, table_schema: Dict) -> List[str]:
        """Extract column names from WHERE clause"""
        columns = []
        query_upper = query.upper()

        # Simple extraction (in production, use proper SQL parser)
        for column in table_schema['columns']:
            if column['name'].upper() in query_upper:
                columns.append(column['name'])

        return columns[:3]  # Limit to 3 columns for composite index

    def _generate_create_index(self, table_name: str, columns: List[str]) -> str:
        """Generate CREATE INDEX statement"""
        index_name = f"idx_{table_name}_{'_'.join(columns)}"[:64]
        column_list = ', '.join([f"`{col}`" for col in columns])
        return f"CREATE INDEX `{index_name}` ON `{table_name}` ({column_list});"


def main():
    """Main entry point for testing"""
    # Connect to database
    connection = mysql.connector.connect(
        host='localhost',
        user='root',
        password='password',
        database='clinic_db'
    )

    # Initialize systems
    anomaly_detector = DatabaseAnomalyDetector()
    anomaly_detector.initialize_models()

    query_predictor = QueryPerformancePredictor()
    forecaster = TimeSeriesForecaster()

    # Collect metrics
    metrics_df = anomaly_detector.collect_metrics(connection)

    # Detect anomalies
    anomalies = anomaly_detector.detect_anomalies(metrics_df)

    for anomaly in anomalies:
        logger.warning(f"Anomaly detected: {anomaly.description}")
        logger.info(f"Recommended action: {anomaly.recommended_action}")

    connection.close()


if __name__ == "__main__":
    main()