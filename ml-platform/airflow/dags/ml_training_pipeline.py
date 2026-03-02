"""ML Training Pipeline DAG.

Automated training pipeline for all ML models
"""

from datetime import datetime, timedelta
import os

from airflow import DAG
from airflow.operators.python import PythonOperator

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
)
import xgboost as xgb

# Configuration
MLFLOW_TRACKING_URI = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow-server:5000")
FEAST_REPO_PATH = os.getenv("FEAST_REPO_PATH", "/app/feast_repo")
S3_BUCKET = os.getenv("S3_BUCKET", "mlflow-artifacts")

# Default DAG arguments
default_args = {
    "owner": "ml-team",
    "depends_on_past": False,
    "start_date": datetime(2024, 1, 1),
    "email_on_failure": True,
    "email_on_retry": False,
    "email": ["ml-team@example.com"],
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

# ==================== Data Extraction Functions ====================


def extract_patient_data(**context):
    """Extract patient data from databases."""
    import psycopg2
    import pandas as pd

    conn = psycopg2.connect(
        host="postgres", database="clinic_db", user="postgres", password="password"
    )

    # Extract patient demographics
    demographics_query = """
        SELECT
            patient_id,
            EXTRACT(YEAR FROM AGE(date_of_birth)) as age,
            gender,
            insurance_provider,
            created_at as event_timestamp
        FROM patients
        WHERE created_at >= CURRENT_DATE - INTERVAL '90 days'
    """
    demographics_df = pd.read_sql(demographics_query, conn)

    # Extract patient vitals
    vitals_query = """
        SELECT
            patient_id,
            AVG(heart_rate) as heart_rate_avg,
            STDDEV(heart_rate) as heart_rate_std,
            AVG(blood_pressure_systolic) as blood_pressure_systolic,
            AVG(blood_pressure_diastolic) as blood_pressure_diastolic,
            AVG(temperature) as temperature,
            AVG(oxygen_saturation) as oxygen_saturation,
            MAX(measurement_time) as event_timestamp
        FROM patient_vitals
        WHERE measurement_time >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY patient_id
    """
    vitals_df = pd.read_sql(vitals_query, conn)

    # Extract appointment history for labels
    appointments_query = """
        SELECT
            patient_id,
            COUNT(*) as appointment_count,
            SUM(CASE WHEN status = 'no_show' THEN 1 ELSE 0 END) as no_show_count
        FROM appointments
        WHERE appointment_date >= CURRENT_DATE - INTERVAL '90 days'
        GROUP BY patient_id
    """
    appointments_df = pd.read_sql(appointments_query, conn)

    conn.close()

    # Merge dataframes
    data = demographics_df.merge(vitals_df, on="patient_id", how="left")
    data = data.merge(appointments_df, on="patient_id", how="left")

    # Create target variable (readmission within 30 days)
    data["readmission"] = (data["appointment_count"] > 1).astype(int)

    # Save to parquet
    output_path = f"/tmp/patient_data_{context['ds']}.parquet"
    data.to_parquet(output_path)

    return output_path


def extract_customer_data(**context):
    """Extract customer data for churn prediction."""
    import psycopg2
    import pandas as pd

    conn = psycopg2.connect(
        host="postgres", database="ecommerce_db", user="postgres", password="password"
    )

    # Extract customer profiles
    customers_query = """
        SELECT
            c.customer_id,
            c.registration_date,
            EXTRACT(DAY FROM AGE(CURRENT_DATE, c.registration_date)) as registration_days,
            c.customer_segment,
            COUNT(DISTINCT o.order_id) as total_orders,
            SUM(o.total_amount) as total_spent,
            AVG(o.total_amount) as avg_order_value,
            MAX(o.order_date) as last_order_date,
            CURRENT_DATE as event_timestamp
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        WHERE c.registration_date >= CURRENT_DATE - INTERVAL '365 days'
        GROUP BY c.customer_id, c.registration_date, c.customer_segment
    """
    customers_df = pd.read_sql(customers_query, conn)

    # Calculate churn label (no order in last 60 days)
    customers_df["days_since_last_order"] = (
        pd.to_datetime("today") - pd.to_datetime(customers_df["last_order_date"])
    ).dt.days
    customers_df["churned"] = (customers_df["days_since_last_order"] > 60).astype(int)

    conn.close()

    # Save to parquet
    output_path = f"/tmp/customer_data_{context['ds']}.parquet"
    customers_df.to_parquet(output_path)

    return output_path


def extract_iot_data(**context):
    """Extract IoT sensor data for anomaly detection."""
    import psycopg2
    import pandas as pd

    conn = psycopg2.connect(
        host="postgres", database="iot_db", user="postgres", password="password"
    )

    # Extract IoT readings
    readings_query = """
        SELECT
            r.device_id,
            r.sensor_type,
            r.value,
            r.timestamp,
            d.device_type,
            d.location_name,
            d.last_maintenance_date,
            EXTRACT(DAY FROM AGE(CURRENT_DATE, d.last_maintenance_date)) as days_since_maintenance
        FROM readings r
        JOIN devices d ON r.device_id = d.device_id
        WHERE r.timestamp >= CURRENT_DATE - INTERVAL '7 days'
    """
    readings_df = pd.read_sql(readings_query, conn)

    # Calculate rolling statistics
    readings_df = readings_df.sort_values(["device_id", "timestamp"])

    for device_id in readings_df["device_id"].unique():
        mask = readings_df["device_id"] == device_id
        readings_df.loc[mask, "rolling_mean"] = (
            readings_df.loc[mask, "value"].rolling(window=100, min_periods=1).mean()
        )
        readings_df.loc[mask, "rolling_std"] = (
            readings_df.loc[mask, "value"].rolling(window=100, min_periods=1).std()
        )

    # Create anomaly labels (values outside 3 std deviations)
    readings_df["is_anomaly"] = (
        np.abs(readings_df["value"] - readings_df["rolling_mean"])
        > 3 * readings_df["rolling_std"]
    ).astype(int)

    conn.close()

    # Save to parquet
    output_path = f"/tmp/iot_data_{context['ds']}.parquet"
    readings_df.to_parquet(output_path)

    return output_path


# ==================== Feature Engineering Functions ====================


def prepare_features(**context):
    """Prepare features using Feast feature store."""
    import feast
    import pandas as pd

    # Initialize Feast
    fs = feast.FeatureStore(repo_path=FEAST_REPO_PATH)

    # Get data paths from previous tasks
    data_type = context["params"]["data_type"]
    data_path = context["task_instance"].xcom_pull(task_ids=f"extract_{data_type}_data")

    # Load data
    df = pd.read_parquet(data_path)

    # Prepare entity dataframe based on data type
    if data_type == "patient":
        entity_df = pd.DataFrame(
            {
                "patient_id": df["patient_id"].unique(),
                "event_timestamp": pd.Timestamp.now(),
            }
        )
        feature_service = "patient_prediction_service"
        target_col = "readmission"

    elif data_type == "customer":
        entity_df = pd.DataFrame(
            {
                "customer_id": df["customer_id"].unique(),
                "event_timestamp": pd.Timestamp.now(),
            }
        )
        feature_service = "customer_churn_service"
        target_col = "churned"

    elif data_type == "iot":
        entity_df = pd.DataFrame(
            {
                "device_id": df["device_id"].unique(),
                "event_timestamp": pd.Timestamp.now(),
            }
        )
        feature_service = "iot_anomaly_service"
        target_col = "is_anomaly"

    # Get features from Feast
    feature_vector = fs.get_online_features(
        feature_refs=fs.get_feature_service(feature_service).features,
        entity_rows=entity_df.to_dict("records"),
    ).to_df()

    # Merge with target
    if target_col in df.columns:
        feature_vector = feature_vector.merge(
            df[
                [
                    (
                        "patient_id"
                        if data_type == "patient"
                        else "customer_id" if data_type == "customer" else "device_id"
                    ),
                    target_col,
                ]
            ],
            on=(
                "patient_id"
                if data_type == "patient"
                else "customer_id" if data_type == "customer" else "device_id"
            ),
            how="left",
        )

    # Save prepared features
    output_path = f"/tmp/features_{data_type}_{context['ds']}.parquet"
    feature_vector.to_parquet(output_path)

    return output_path


# ==================== Model Training Functions ====================


def train_model_with_optuna(**context):
    """Train model with Optuna hyperparameter optimization."""
    import optuna
    import mlflow
    import mlflow.sklearn
    import mlflow.xgboost
    from sklearn.model_selection import cross_val_score

    # Get features path
    data_type = context["params"]["data_type"]
    features_path = context["task_instance"].xcom_pull(
        task_ids=f"prepare_{data_type}_features"
    )

    # Load features
    df = pd.read_parquet(features_path)

    # Define target and features
    if data_type == "patient":
        target_col = "readmission"
        feature_cols = [
            col
            for col in df.columns
            if col not in ["patient_id", "readmission", "event_timestamp"]
        ]
    elif data_type == "customer":
        target_col = "churned"
        feature_cols = [
            col
            for col in df.columns
            if col not in ["customer_id", "churned", "event_timestamp"]
        ]
    elif data_type == "iot":
        target_col = "is_anomaly"
        feature_cols = [
            col
            for col in df.columns
            if col not in ["device_id", "is_anomaly", "event_timestamp"]
        ]

    X = df[feature_cols]
    y = df[target_col]

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    # Define Optuna objective
    def objective(trial):
        # Suggest hyperparameters
        """Handle objective."""
        params = {
            "n_estimators": trial.suggest_int("n_estimators", 50, 500),
            "max_depth": trial.suggest_int("max_depth", 3, 20),
            "learning_rate": trial.suggest_float("learning_rate", 0.01, 0.3, log=True),
            "subsample": trial.suggest_float("subsample", 0.5, 1.0),
            "colsample_bytree": trial.suggest_float("colsample_bytree", 0.5, 1.0),
            "gamma": trial.suggest_float("gamma", 0, 5),
            "reg_alpha": trial.suggest_float("reg_alpha", 0, 2),
            "reg_lambda": trial.suggest_float("reg_lambda", 0, 2),
        }

        # Train model
        model = xgb.XGBClassifier(
            **params, use_label_encoder=False, eval_metric="logloss"
        )

        # Cross-validation score
        scores = cross_val_score(model, X_train, y_train, cv=5, scoring="f1")

        return scores.mean()

    # Create Optuna study
    study = optuna.create_study(
        direction="maximize",
        study_name=f"{data_type}_model_optimization",
        storage="postgresql://optuna:optuna@optuna-postgres:5432/optuna",
        load_if_exists=True,
    )

    # Optimize
    study.optimize(objective, n_trials=50)

    # Train final model with best parameters
    best_params = study.best_params

    # MLflow tracking
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    mlflow.set_experiment(f"{data_type}_prediction")

    with mlflow.start_run(run_name=f'{data_type}_xgboost_{context["ds"]}'):
        # Log parameters
        mlflow.log_params(best_params)

        # Train model
        model = xgb.XGBClassifier(
            **best_params, use_label_encoder=False, eval_metric="logloss"
        )
        model.fit(X_train, y_train)

        # Evaluate
        y_pred = model.predict(X_test)

        if data_type in ["patient", "customer"]:
            # Classification metrics
            metrics = {
                "accuracy": accuracy_score(y_test, y_pred),
                "precision": precision_score(y_test, y_pred),
                "recall": recall_score(y_test, y_pred),
                "f1": f1_score(y_test, y_pred),
            }
        else:
            # Anomaly detection metrics
            metrics = {
                "accuracy": accuracy_score(y_test, y_pred),
                "precision": precision_score(y_test, y_pred, zero_division=0),
                "recall": recall_score(y_test, y_pred, zero_division=0),
                "f1": f1_score(y_test, y_pred, zero_division=0),
            }

        # Log metrics
        mlflow.log_metrics(metrics)

        # Log model
        mlflow.xgboost.log_model(
            model,
            artifact_path="model",
            registered_model_name=f"{data_type}_prediction_model",
        )

        # Log feature importance
        feature_importance = pd.DataFrame(
            {"feature": feature_cols, "importance": model.feature_importances_}
        ).sort_values("importance", ascending=False)

        mlflow.log_text(
            feature_importance.to_csv(index=False), "feature_importance.csv"
        )

        # Store model URI for deployment
        model_uri = mlflow.get_artifact_uri("model")
        context["task_instance"].xcom_push(key="model_uri", value=model_uri)

        return metrics


def train_with_ray_tune(**context):
    """Train model using Ray Tune for distributed hyperparameter tuning."""
    import ray
    from ray import tune
    from ray.tune.integration.mlflow import MLflowLoggerCallback

    # Initialize Ray
    ray.init(address="ray://ray-head:10001", ignore_reinit_error=True)

    # Get features path
    data_type = context["params"]["data_type"]
    features_path = context["task_instance"].xcom_pull(
        task_ids=f"prepare_{data_type}_features"
    )

    # Define training function for Ray Tune
    def train_func(config):
        """Handle train func."""
        import pandas as pd
        import xgboost as xgb
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import f1_score

        # Load data
        df = pd.read_parquet(features_path)

        # Prepare features and target
        if data_type == "patient":
            target_col = "readmission"
            id_col = "patient_id"
        elif data_type == "customer":
            target_col = "churned"
            id_col = "customer_id"
        else:
            target_col = "is_anomaly"
            id_col = "device_id"

        feature_cols = [
            col
            for col in df.columns
            if col not in [id_col, target_col, "event_timestamp"]
        ]
        X = df[feature_cols]
        y = df[target_col]

        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42
        )

        # Train model with config
        model = xgb.XGBClassifier(
            **config, use_label_encoder=False, eval_metric="logloss"
        )
        model.fit(X_train, y_train)

        # Evaluate
        y_pred = model.predict(X_test)
        f1 = f1_score(y_test, y_pred)

        # Report to Ray Tune
        tune.report(f1_score=f1)

    # Define search space
    search_space = {
        "n_estimators": tune.randint(50, 500),
        "max_depth": tune.randint(3, 20),
        "learning_rate": tune.loguniform(0.01, 0.3),
        "subsample": tune.uniform(0.5, 1.0),
        "colsample_bytree": tune.uniform(0.5, 1.0),
    }

    # Run Ray Tune
    analysis = tune.run(
        train_func,
        config=search_space,
        num_samples=20,
        metric="f1_score",
        mode="max",
        callbacks=[
            MLflowLoggerCallback(
                tracking_uri=MLFLOW_TRACKING_URI,
                experiment_name=f"{data_type}_ray_tune",
                save_artifact=True,
            )
        ],
    )

    # Get best config
    best_config = analysis.get_best_config(metric="f1_score", mode="max")

    ray.shutdown()

    return best_config


# ==================== Model Deployment Functions ====================


def deploy_model_bentoml(**context):
    """Deploy model using BentoML."""
    import bentoml
    import mlflow

    # Get model URI
    model_uri = context["task_instance"].xcom_pull(key="model_uri")
    data_type = context["params"]["data_type"]

    # Load model from MLflow
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
    model = mlflow.pyfunc.load_model(model_uri)

    # Save to BentoML
    bento_model = bentoml.sklearn.save_model(
        f"{data_type}_model",
        model,
        signatures={
            "predict": {
                "batchable": True,
                "input": bentoml.io.NumpyNdarray(),
                "output": bentoml.io.NumpyNdarray(),
            }
        },
        metadata={
            "model_uri": model_uri,
            "data_type": data_type,
            "timestamp": datetime.now().isoformat(),
        },
    )

    return str(bento_model.tag)


def validate_deployment(**context):
    """Validate deployed model."""
    import requests
    import numpy as np

    _ = context["params"]["data_type"]

    # Prepare test data
    test_data = np.random.randn(10, 20)  # Dummy test data

    # Send prediction request
    response = requests.post(
        "http://bentoml-server:3000/predict", json={"data": test_data.tolist()}
    )

    if response.status_code == 200:
        predictions = response.json()
        print(f"Model validation successful. Predictions: {predictions}")
        return True
    else:
        raise Exception(f"Model validation failed: {response.text}")


# ==================== DAG Definitions ====================

# Patient Readmission Prediction Pipeline
patient_dag = DAG(
    "patient_readmission_prediction",
    default_args=default_args,
    description="Train patient readmission prediction model",
    schedule_interval="@weekly",
    catchup=False,
    tags=["ml", "healthcare"],
)

with patient_dag:
    extract_task = PythonOperator(
        task_id="extract_patient_data",
        python_callable=extract_patient_data,
    )

    prepare_features_task = PythonOperator(
        task_id="prepare_patient_features",
        python_callable=prepare_features,
        params={"data_type": "patient"},
    )

    train_task = PythonOperator(
        task_id="train_model",
        python_callable=train_model_with_optuna,
        params={"data_type": "patient"},
    )

    deploy_task = PythonOperator(
        task_id="deploy_model",
        python_callable=deploy_model_bentoml,
        params={"data_type": "patient"},
    )

    validate_task = PythonOperator(
        task_id="validate_deployment",
        python_callable=validate_deployment,
        params={"data_type": "patient"},
    )

    extract_task >> prepare_features_task >> train_task >> deploy_task >> validate_task

# Customer Churn Prediction Pipeline
customer_dag = DAG(
    "customer_churn_prediction",
    default_args=default_args,
    description="Train customer churn prediction model",
    schedule_interval="@daily",
    catchup=False,
    tags=["ml", "ecommerce"],
)

with customer_dag:
    extract_task = PythonOperator(
        task_id="extract_customer_data",
        python_callable=extract_customer_data,
    )

    prepare_features_task = PythonOperator(
        task_id="prepare_customer_features",
        python_callable=prepare_features,
        params={"data_type": "customer"},
    )

    train_task = PythonOperator(
        task_id="train_model",
        python_callable=train_model_with_optuna,
        params={"data_type": "customer"},
    )

    deploy_task = PythonOperator(
        task_id="deploy_model",
        python_callable=deploy_model_bentoml,
        params={"data_type": "customer"},
    )

    validate_task = PythonOperator(
        task_id="validate_deployment",
        python_callable=validate_deployment,
        params={"data_type": "customer"},
    )

    extract_task >> prepare_features_task >> train_task >> deploy_task >> validate_task

# IoT Anomaly Detection Pipeline
iot_dag = DAG(
    "iot_anomaly_detection",
    default_args=default_args,
    description="Train IoT anomaly detection model",
    schedule_interval="@hourly",
    catchup=False,
    tags=["ml", "iot"],
)

with iot_dag:
    extract_task = PythonOperator(
        task_id="extract_iot_data",
        python_callable=extract_iot_data,
    )

    prepare_features_task = PythonOperator(
        task_id="prepare_iot_features",
        python_callable=prepare_features,
        params={"data_type": "iot"},
    )

    train_task = PythonOperator(
        task_id="train_model",
        python_callable=train_with_ray_tune,  # Use Ray Tune for IoT
        params={"data_type": "iot"},
    )

    deploy_task = PythonOperator(
        task_id="deploy_model",
        python_callable=deploy_model_bentoml,
        params={"data_type": "iot"},
    )

    validate_task = PythonOperator(
        task_id="validate_deployment",
        python_callable=validate_deployment,
        params={"data_type": "iot"},
    )

    extract_task >> prepare_features_task >> train_task >> deploy_task >> validate_task
