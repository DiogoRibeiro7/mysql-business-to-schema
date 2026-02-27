"""
Test Suite for ML Pipeline Infrastructure
Tests all ML models and pipelines
"""

import unittest
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import tempfile
import os
from unittest.mock import Mock, patch

from ml_pipeline import (
    MLPipeline,
    RecommendationSystem,
    AnomalyDetector,
    TimeSeriesForecaster,
    CustomerSegmentation,
    EcommercePredictiveAnalytics,
    FintechFraudDetection,
    ModelServer,
)


class TestMLPipeline(unittest.TestCase):
    """Test base ML pipeline functionality"""

    def setUp(self):
        """Set up test fixtures"""
        # Create sample dataset
        np.random.seed(42)
        self.df = pd.DataFrame(
            {
                "feature1": np.random.randn(100),
                "feature2": np.random.randn(100),
                "feature3": np.random.randn(100),
                "target": np.random.choice([0, 1], 100),
            }
        )

        self.pipeline = MLPipeline(
            model_type="random_forest",
            task_type="classification",
            features=["feature1", "feature2", "feature3"],
            target="target",
        )

    def test_initialization(self):
        """Test pipeline initialization"""
        self.assertEqual(self.pipeline.model_type, "random_forest")
        self.assertEqual(self.pipeline.task_type, "classification")
        self.assertEqual(len(self.pipeline.features), 3)
        self.assertEqual(self.pipeline.target, "target")

    def test_preprocess_data(self):
        """Test data preprocessing"""
        X, y = self.pipeline.preprocess_data(self.df)

        self.assertEqual(X.shape[0], 100)
        self.assertEqual(X.shape[1], 3)
        self.assertEqual(len(y), 100)

        # Check for no missing values after preprocessing
        self.assertFalse(pd.DataFrame(X).isnull().any().any())

    def test_train_classification(self):
        """Test training classification model"""
        metrics = self.pipeline.train(self.df)

        self.assertIn("accuracy", metrics)
        self.assertIn("precision", metrics)
        self.assertIn("recall", metrics)
        self.assertIn("f1_score", metrics)

        # Check metrics are in valid range
        for metric, value in metrics.items():
            if metric != "feature_importance":
                self.assertGreaterEqual(value, 0)
                self.assertLessEqual(value, 1)

    def test_train_regression(self):
        """Test training regression model"""
        # Create regression dataset
        df = self.df.copy()
        df["target"] = np.random.randn(100)

        pipeline = MLPipeline(
            model_type="gradient_boosting",
            task_type="regression",
            features=["feature1", "feature2", "feature3"],
            target="target",
        )

        metrics = pipeline.train(df)

        self.assertIn("rmse", metrics)
        self.assertIn("mae", metrics)
        self.assertIn("r2_score", metrics)

    def test_predict(self):
        """Test prediction"""
        # Train model first
        self.pipeline.train(self.df)

        # Make predictions
        test_df = self.df.iloc[:10].copy()
        predictions = self.pipeline.predict(test_df)

        self.assertEqual(len(predictions), 10)

        # Check predictions are valid classes for classification
        unique_preds = np.unique(predictions)
        self.assertTrue(all(p in [0, 1] for p in unique_preds))

    def test_cross_validate(self):
        """Test cross-validation"""
        cv_scores = self.pipeline.cross_validate(self.df)

        self.assertIn("mean_score", cv_scores)
        self.assertIn("std_score", cv_scores)
        self.assertIn("scores", cv_scores)

        self.assertEqual(len(cv_scores["scores"]), 5)  # 5-fold CV


class TestRecommendationSystem(unittest.TestCase):
    """Test recommendation system"""

    def setUp(self):
        """Set up test fixtures"""
        # Create sample interaction data
        np.random.seed(42)
        self.df = pd.DataFrame(
            {
                "user_id": np.random.choice(range(1, 21), 100),
                "item_id": np.random.choice(range(1, 51), 100),
                "rating": np.random.uniform(1, 5, 100),
                "timestamp": [datetime.now() - timedelta(days=x) for x in range(100)],
            }
        )

        self.rec_system = RecommendationSystem(algorithm="als")

    def test_build_user_item_matrix(self):
        """Test user-item matrix construction"""
        matrix = self.rec_system._build_user_item_matrix(self.df)

        self.assertIsNotNone(matrix)
        self.assertEqual(matrix.shape[0], len(self.df["user_id"].unique()))
        self.assertEqual(matrix.shape[1], len(self.df["item_id"].unique()))

    def test_train_als(self):
        """Test ALS training"""
        metrics = self.rec_system.train(self.df)

        self.assertIn("mse", metrics)
        self.assertIn("coverage", metrics)
        self.assertIn("diversity", metrics)

        self.assertIsNotNone(self.rec_system.model)

    def test_train_content_based(self):
        """Test content-based training"""
        # Add item features
        df = self.df.copy()
        item_features = pd.DataFrame(
            {
                "item_id": range(1, 51),
                "category": np.random.choice(["A", "B", "C"], 50),
                "price": np.random.uniform(10, 100, 50),
            }
        )
        df = df.merge(item_features, on="item_id", how="left")

        rec_system = RecommendationSystem(
            algorithm="content_based", item_features=["category", "price"]
        )

        metrics = rec_system.train(df)
        self.assertIsNotNone(rec_system.item_profiles)

    def test_get_recommendations(self):
        """Test getting recommendations"""
        self.rec_system.train(self.df)

        recommendations = self.rec_system.get_recommendations(user_id=1, n_items=5)

        self.assertEqual(len(recommendations), 5)
        self.assertIn("item_id", recommendations.columns)
        self.assertIn("score", recommendations.columns)

        # Check scores are sorted descending
        scores = recommendations["score"].values
        self.assertTrue(all(scores[i] >= scores[i + 1] for i in range(len(scores) - 1)))


class TestAnomalyDetector(unittest.TestCase):
    """Test anomaly detection"""

    def setUp(self):
        """Set up test fixtures"""
        np.random.seed(42)
        # Create normal data with some outliers
        normal_data = np.random.randn(90, 3)
        outliers = np.random.randn(10, 3) * 5  # Larger variance for outliers

        data = np.vstack([normal_data, outliers])
        self.df = pd.DataFrame(data, columns=["feature1", "feature2", "feature3"])

        self.detector = AnomalyDetector(
            method="isolation_forest", features=["feature1", "feature2", "feature3"]
        )

    def test_train_isolation_forest(self):
        """Test Isolation Forest training"""
        metrics = self.detector.train(self.df)

        self.assertIn("n_anomalies", metrics)
        self.assertIn("contamination", metrics)

        self.assertIsNotNone(self.detector.model)

    def test_train_autoencoder(self):
        """Test autoencoder training"""
        detector = AnomalyDetector(
            method="autoencoder", features=["feature1", "feature2", "feature3"]
        )

        metrics = detector.train(self.df)

        self.assertIn("reconstruction_error", metrics)
        self.assertIn("threshold", metrics)

        self.assertIsNotNone(detector.model)

    def test_detect_anomalies(self):
        """Test anomaly detection"""
        self.detector.train(self.df)

        # Detect on same data
        anomalies = self.detector.detect_anomalies(self.df)

        self.assertEqual(len(anomalies), len(self.df))
        self.assertIn("is_anomaly", anomalies.columns)
        self.assertIn("anomaly_score", anomalies.columns)

        # Check we detected some anomalies
        n_anomalies = anomalies["is_anomaly"].sum()
        self.assertGreater(n_anomalies, 0)
        self.assertLess(n_anomalies, len(anomalies))

    def test_statistical_detection(self):
        """Test statistical anomaly detection"""
        detector = AnomalyDetector(
            method="statistical",
            features=["feature1", "feature2", "feature3"],
            statistical_params={"z_threshold": 3},
        )

        metrics = detector.train(self.df)
        anomalies = detector.detect_anomalies(self.df)

        self.assertIn("mean", detector.statistical_params)
        self.assertIn("std", detector.statistical_params)


class TestTimeSeriesForecaster(unittest.TestCase):
    """Test time series forecasting"""

    def setUp(self):
        """Set up test fixtures"""
        np.random.seed(42)
        # Create time series data
        dates = pd.date_range(start="2023-01-01", periods=365, freq="D")
        trend = np.linspace(100, 200, 365)
        seasonal = 10 * np.sin(2 * np.pi * np.arange(365) / 365)
        noise = np.random.randn(365) * 5

        self.df = pd.DataFrame({"ds": dates, "y": trend + seasonal + noise})

        self.forecaster = TimeSeriesForecaster(
            method="prophet", target_column="y", date_column="ds"
        )

    def test_train_prophet(self):
        """Test Prophet training"""
        metrics = self.forecaster.train(self.df)

        self.assertIn("mape", metrics)
        self.assertIn("rmse", metrics)

        self.assertIsNotNone(self.forecaster.model)

    @patch("ml_pipeline.ARIMA")
    def test_train_arima(self, mock_arima):
        """Test ARIMA training"""
        # Mock ARIMA to avoid long training times in tests
        mock_model = Mock()
        mock_model.fit.return_value = mock_model
        mock_model.forecast.return_value = np.array([100, 101, 102])
        mock_arima.return_value = mock_model

        forecaster = TimeSeriesForecaster(
            method="arima", target_column="y", date_column="ds"
        )

        metrics = forecaster.train(self.df)
        self.assertIsNotNone(forecaster.model)

    def test_forecast(self):
        """Test forecasting"""
        self.forecaster.train(self.df)

        forecast = self.forecaster.forecast(periods=30)

        self.assertEqual(len(forecast), 30)
        self.assertIn("ds", forecast.columns)
        self.assertIn("yhat", forecast.columns)
        self.assertIn("yhat_lower", forecast.columns)
        self.assertIn("yhat_upper", forecast.columns)

    def test_lstm_forecast(self):
        """Test LSTM forecasting"""
        forecaster = TimeSeriesForecaster(
            method="lstm", target_column="y", date_column="ds", sequence_length=30
        )

        # Train with smaller epochs for testing
        with patch.object(forecaster, "_train_lstm") as mock_train:
            mock_train.return_value = {"mape": 0.1, "rmse": 5.0}
            metrics = forecaster.train(self.df)

            self.assertIn("mape", metrics)
            self.assertIn("rmse", metrics)


class TestCustomerSegmentation(unittest.TestCase):
    """Test customer segmentation"""

    def setUp(self):
        """Set up test fixtures"""
        np.random.seed(42)
        # Create customer data
        self.df = pd.DataFrame(
            {
                "customer_id": range(1, 101),
                "recency": np.random.randint(1, 365, 100),
                "frequency": np.random.randint(1, 50, 100),
                "monetary": np.random.uniform(10, 1000, 100),
                "age": np.random.randint(18, 70, 100),
                "tenure": np.random.randint(1, 60, 100),
            }
        )

        self.segmentation = CustomerSegmentation(
            method="kmeans", features=["recency", "frequency", "monetary"], n_clusters=4
        )

    def test_train_kmeans(self):
        """Test K-means clustering"""
        metrics = self.segmentation.train(self.df)

        self.assertIn("silhouette_score", metrics)
        self.assertIn("inertia", metrics)
        self.assertIn("n_clusters", metrics)

        self.assertEqual(metrics["n_clusters"], 4)
        self.assertIsNotNone(self.segmentation.model)

    def test_train_hierarchical(self):
        """Test hierarchical clustering"""
        segmentation = CustomerSegmentation(
            method="hierarchical",
            features=["recency", "frequency", "monetary"],
            n_clusters=3,
        )

        metrics = segmentation.train(self.df)

        self.assertIn("n_clusters", metrics)
        self.assertEqual(metrics["n_clusters"], 3)

    def test_segment_customers(self):
        """Test customer segmentation"""
        self.segmentation.train(self.df)

        segments = self.segmentation.segment_customers(self.df)

        self.assertEqual(len(segments), len(self.df))
        self.assertIn("segment", segments.columns)
        self.assertIn("segment_name", segments.columns)

        # Check all customers are assigned a segment
        self.assertEqual(segments["segment"].isnull().sum(), 0)

        # Check correct number of unique segments
        n_unique_segments = segments["segment"].nunique()
        self.assertEqual(n_unique_segments, 4)

    def test_rfm_segmentation(self):
        """Test RFM segmentation"""
        segmentation = CustomerSegmentation(
            method="rfm", features=["recency", "frequency", "monetary"]
        )

        metrics = segmentation.train(self.df)
        segments = segmentation.segment_customers(self.df)

        self.assertIn("rfm_score", segments.columns)
        self.assertIn("segment_name", segments.columns)


class TestModelServer(unittest.TestCase):
    """Test model serving infrastructure"""

    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.server = ModelServer(model_registry_path=self.temp_dir)

        # Create a simple model
        self.pipeline = MLPipeline(
            model_type="logistic_regression",
            task_type="classification",
            features=["feature1", "feature2"],
            target="target",
        )

        # Train on sample data
        df = pd.DataFrame(
            {
                "feature1": np.random.randn(50),
                "feature2": np.random.randn(50),
                "target": np.random.choice([0, 1], 50),
            }
        )
        self.pipeline.train(df)

    def test_register_model(self):
        """Test model registration"""
        model_id = self.server.register_model(
            model=self.pipeline,
            name="test_model",
            version="1.0.0",
            metrics={"accuracy": 0.85},
        )

        self.assertIsNotNone(model_id)
        self.assertIn(model_id, self.server.models)

        # Check model metadata
        metadata = self.server.models[model_id]
        self.assertEqual(metadata["name"], "test_model")
        self.assertEqual(metadata["version"], "1.0.0")
        self.assertEqual(metadata["metrics"]["accuracy"], 0.85)

    def test_load_model(self):
        """Test model loading"""
        # Register model first
        model_id = self.server.register_model(
            model=self.pipeline, name="test_model", version="1.0.0"
        )

        # Create new server instance and load
        new_server = ModelServer(model_registry_path=self.temp_dir)
        loaded_model = new_server.load_model(model_id)

        self.assertIsNotNone(loaded_model)
        self.assertEqual(loaded_model.model_type, self.pipeline.model_type)

    def test_predict(self):
        """Test prediction through server"""
        # Register model
        model_id = self.server.register_model(
            model=self.pipeline, name="test_model", version="1.0.0"
        )

        # Make prediction
        data = pd.DataFrame({"feature1": [0.5, -0.5], "feature2": [1.0, -1.0]})

        predictions = self.server.predict(model_id, data)

        self.assertEqual(len(predictions), 2)

    def test_model_versioning(self):
        """Test model versioning"""
        # Register multiple versions
        model_id_v1 = self.server.register_model(
            model=self.pipeline, name="test_model", version="1.0.0"
        )

        model_id_v2 = self.server.register_model(
            model=self.pipeline, name="test_model", version="2.0.0"
        )

        self.assertNotEqual(model_id_v1, model_id_v2)

        # Check both models exist
        self.assertIn(model_id_v1, self.server.models)
        self.assertIn(model_id_v2, self.server.models)

    def test_list_models(self):
        """Test listing models"""
        # Register multiple models
        self.server.register_model(model=self.pipeline, name="model_a", version="1.0.0")

        self.server.register_model(model=self.pipeline, name="model_b", version="1.0.0")

        models = self.server.list_models()

        self.assertEqual(len(models), 2)

        # Filter by name
        models_a = self.server.list_models(name="model_a")
        self.assertEqual(len(models_a), 1)
        self.assertEqual(models_a[0]["name"], "model_a")

    def tearDown(self):
        """Clean up temp directory"""
        import shutil

        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)


class TestEcommercePredictiveAnalytics(unittest.TestCase):
    """Test e-commerce predictive analytics"""

    def setUp(self):
        """Set up test fixtures"""
        np.random.seed(42)
        # Create sample e-commerce data
        self.df = pd.DataFrame(
            {
                "customer_id": np.repeat(range(1, 21), 5),
                "order_id": range(1, 101),
                "order_date": pd.date_range(start="2023-01-01", periods=100),
                "total_amount": np.random.uniform(10, 500, 100),
                "product_category": np.random.choice(
                    ["Electronics", "Clothing", "Books"], 100
                ),
                "days_since_last_order": np.random.randint(1, 180, 100),
                "total_orders": np.random.randint(1, 50, 100),
                "avg_order_value": np.random.uniform(20, 200, 100),
                "is_churned": np.random.choice([0, 1], 100, p=[0.7, 0.3]),
            }
        )

        self.analytics = EcommercePredictiveAnalytics()

    def test_predict_churn(self):
        """Test churn prediction"""
        churn_scores = self.analytics.predict_churn(self.df)

        self.assertEqual(len(churn_scores), len(self.df))
        self.assertIn("churn_probability", churn_scores.columns)
        self.assertIn("churn_risk", churn_scores.columns)

        # Check probabilities are in valid range
        probs = churn_scores["churn_probability"].values
        self.assertTrue(all(0 <= p <= 1 for p in probs))

    def test_predict_lifetime_value(self):
        """Test LTV prediction"""
        ltv_predictions = self.analytics.predict_lifetime_value(self.df)

        self.assertEqual(len(ltv_predictions), len(self.df["customer_id"].unique()))
        self.assertIn("predicted_ltv", ltv_predictions.columns)
        self.assertIn("ltv_segment", ltv_predictions.columns)

        # Check LTV values are positive
        ltv_values = ltv_predictions["predicted_ltv"].values
        self.assertTrue(all(v >= 0 for v in ltv_values))

    def test_recommend_products(self):
        """Test product recommendations"""
        # Add interaction data
        df = self.df.copy()
        df["rating"] = np.random.uniform(1, 5, len(df))

        recommendations = self.analytics.recommend_products(
            df, customer_id=1, n_products=5
        )

        self.assertLessEqual(len(recommendations), 5)
        if len(recommendations) > 0:
            self.assertIn("product_id", recommendations.columns)
            self.assertIn("score", recommendations.columns)


class TestFintechFraudDetection(unittest.TestCase):
    """Test fintech fraud detection"""

    def setUp(self):
        """Set up test fixtures"""
        np.random.seed(42)
        # Create sample transaction data
        self.df = pd.DataFrame(
            {
                "transaction_id": range(1, 201),
                "amount": np.random.lognormal(3, 2, 200),
                "merchant_category": np.random.choice(
                    ["grocery", "gas", "restaurant", "online"], 200
                ),
                "hour_of_day": np.random.randint(0, 24, 200),
                "days_since_last_transaction": np.random.exponential(2, 200),
                "location_risk_score": np.random.uniform(0, 1, 200),
                "is_fraud": np.random.choice([0, 1], 200, p=[0.98, 0.02]),
            }
        )

        self.fraud_detector = FintechFraudDetection()

    def test_detect_fraud(self):
        """Test fraud detection"""
        fraud_scores = self.fraud_detector.detect_fraud(self.df)

        self.assertEqual(len(fraud_scores), len(self.df))
        self.assertIn("fraud_probability", fraud_scores.columns)
        self.assertIn("is_suspicious", fraud_scores.columns)
        self.assertIn("risk_factors", fraud_scores.columns)

        # Check probabilities are in valid range
        probs = fraud_scores["fraud_probability"].values
        self.assertTrue(all(0 <= p <= 1 for p in probs))

    def test_risk_scoring(self):
        """Test risk scoring"""
        risk_scores = self.fraud_detector.risk_scoring(self.df)

        self.assertEqual(len(risk_scores), len(self.df))
        self.assertIn("risk_score", risk_scores.columns)
        self.assertIn("risk_level", risk_scores.columns)

        # Check risk levels
        risk_levels = risk_scores["risk_level"].unique()
        valid_levels = ["low", "medium", "high", "critical"]
        self.assertTrue(all(level in valid_levels for level in risk_levels))

    def test_detect_anomalous_patterns(self):
        """Test anomalous pattern detection"""
        anomalies = self.fraud_detector.detect_anomalous_patterns(self.df)

        self.assertEqual(len(anomalies), len(self.df))
        self.assertIn("is_anomaly", anomalies.columns)
        self.assertIn("anomaly_score", anomalies.columns)
        self.assertIn("pattern_type", anomalies.columns)


if __name__ == "__main__":
    unittest.main(verbosity=2)
