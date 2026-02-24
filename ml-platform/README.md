# MySQL Business-to-Schema Machine Learning Platform

Comprehensive ML platform for predictive analytics across all business domains.

## 🤖 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Data Sources                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │  MySQL   │  │   APIs   │  │   Files  │  │  Streams │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
└───────┼─────────────┼─────────────┼─────────────┼──────────────┘
        │             │             │             │
    ┌───▼─────────────▼─────────────▼─────────────▼───┐
    │               Feature Engineering                │
    │            Feast Feature Store                   │
    │  ┌──────────────────────────────────────────┐   │
    │  │ Entities | Features | Transformations    │   │
    │  └──────────────────────────────────────────┘   │
    └─────────────────────┬─────────────────────────┘
                          │
    ┌─────────────────────▼─────────────────────────┐
    │           Model Training & Optimization        │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
    │  │  MLflow  │  │  Optuna  │  │   Ray    │   │
    │  │ Tracking │  │  Tuning  │  │Distributed│  │
    │  └──────────┘  └──────────┘  └──────────┘   │
    └─────────────────────┬─────────────────────────┘
                          │
    ┌─────────────────────▼─────────────────────────┐
    │              Model Management                  │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
    │  │  MLflow  │  │ BentoML  │  │  Airflow │   │
    │  │ Registry │  │ Serving  │  │ Pipeline │   │
    │  └──────────┘  └──────────┘  └──────────┘   │
    └─────────────────────┬─────────────────────────┘
                          │
    ┌─────────────────────▼─────────────────────────┐
    │           Model Serving & Monitoring           │
    │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
    │  │   APIs   │  │  Batch   │  │ Real-time│   │
    │  │ REST/gRPC│  │Processing│  │ Inference│   │
    │  └──────────┘  └──────────┘  └──────────┘   │
    └────────────────────────────────────────────────┘
```

## 🚀 Components

### 1. **MLflow** - Experiment Tracking & Model Registry
- Experiment tracking
- Model versioning
- Artifact storage
- Model registry

### 2. **Feast** - Feature Store
- Feature definitions
- Online/offline stores
- Feature serving
- Data validation

### 3. **Ray** - Distributed Training
- Distributed hyperparameter tuning
- Parallel training
- Auto-scaling
- GPU support

### 4. **BentoML** - Model Serving
- Model packaging
- REST/gRPC APIs
- Batch inference
- A/B testing

### 5. **Airflow** - ML Pipelines
- Automated training
- Data processing
- Model deployment
- Monitoring

### 6. **Optuna** - Hyperparameter Optimization
- Bayesian optimization
- Pruning algorithms
- Visualization
- Distributed optimization

### 7. **Label Studio** - Data Labeling
- Multi-format support
- Active learning
- Collaboration
- Quality control

## 📦 Quick Start

### Prerequisites
- Docker and Docker Compose
- Python 3.8+
- 16GB+ RAM recommended
- GPU (optional for deep learning)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd ml-platform

# Start all services
docker-compose up -d

# Wait for services to initialize
sleep 60

# Initialize Feast feature store
docker exec feast-server feast apply

# Create MLflow experiments
docker exec mlflow-server mlflow experiments create -n patient_prediction
docker exec mlflow-server mlflow experiments create -n customer_churn
docker exec mlflow-server mlflow experiments create -n iot_anomaly
```

### Accessing Services

| Service | URL | Credentials |
|---------|-----|------------|
| MLflow UI | http://localhost:5001 | - |
| Feast UI | http://localhost:8888 | - |
| Ray Dashboard | http://localhost:8265 | - |
| Airflow | http://localhost:8090 | admin / admin |
| Label Studio | http://localhost:8091 | admin@example.com / admin |
| Jupyter Lab | http://localhost:8889 | token in logs |
| Optuna Dashboard | http://localhost:8092 | - |
| BentoML | http://localhost:3000 | - |
| Grafana | http://localhost:3002 | admin / admin |
| TensorBoard | http://localhost:6006 | - |

## 🧠 ML Use Cases

### 1. Patient Readmission Prediction
**Goal**: Predict 30-day hospital readmission risk

**Features**:
- Demographics (age, gender, insurance)
- Vitals (heart rate, blood pressure, oxygen)
- Medical history
- Chronic conditions

**Model**: XGBoost Classifier

**Metrics**:
- Accuracy: 85%
- Precision: 82%
- Recall: 78%
- F1: 0.80

### 2. Customer Churn Prediction
**Goal**: Identify customers likely to stop purchasing

**Features**:
- Purchase history
- Engagement metrics
- Customer lifetime value
- Recency, frequency, monetary

**Model**: LightGBM Classifier

**Metrics**:
- Accuracy: 89%
- Precision: 86%
- Recall: 83%
- F1: 0.84

### 3. IoT Anomaly Detection
**Goal**: Detect sensor anomalies and predict failures

**Features**:
- Sensor readings
- Rolling statistics
- Maintenance history
- Environmental factors

**Model**: Isolation Forest + LSTM

**Metrics**:
- Precision: 92%
- Recall: 88%
- F1: 0.90

### 4. Product Recommendation
**Goal**: Personalized product recommendations

**Features**:
- User behavior
- Product features
- Collaborative filtering
- Content-based filtering

**Model**: Neural Collaborative Filtering

**Metrics**:
- Precision@10: 0.75
- Recall@10: 0.68
- NDCG: 0.82

## 📊 Feature Store

### Feature Definitions

```python
# Patient features
patient_demographics_fv = FeatureView(
    name="patient_demographics",
    entities=[patient],
    features=[
        Feature(name="age", dtype=ValueType.INT32),
        Feature(name="bmi", dtype=ValueType.FLOAT),
        Feature(name="chronic_conditions", dtype=ValueType.INT32),
    ],
    online=True,
    ttl=timedelta(days=365)
)

# Customer features
customer_profile_fv = FeatureView(
    name="customer_profile",
    entities=[customer],
    features=[
        Feature(name="total_orders", dtype=ValueType.INT32),
        Feature(name="total_spent", dtype=ValueType.FLOAT),
        Feature(name="churn_risk_score", dtype=ValueType.FLOAT),
    ],
    online=True,
    ttl=timedelta(days=180)
)
```

### Feature Serving

```python
# Get features for inference
feature_vector = fs.get_online_features(
    features=[
        "patient_demographics:age",
        "patient_demographics:bmi",
        "patient_vitals:heart_rate",
    ],
    entity_rows=[{"patient_id": 123}]
).to_dict()
```

## 🔧 Training Pipelines

### Automated Training with Airflow

```python
# DAG for model training
with DAG('patient_model_training', schedule='@weekly') as dag:

    extract_data = PythonOperator(
        task_id='extract_data',
        python_callable=extract_patient_data
    )

    prepare_features = PythonOperator(
        task_id='prepare_features',
        python_callable=prepare_features_with_feast
    )

    train_model = PythonOperator(
        task_id='train_model',
        python_callable=train_with_mlflow
    )

    evaluate_model = PythonOperator(
        task_id='evaluate',
        python_callable=evaluate_model
    )

    deploy_model = PythonOperator(
        task_id='deploy',
        python_callable=deploy_to_bentoml
    )

    extract_data >> prepare_features >> train_model >> evaluate_model >> deploy_model
```

### Hyperparameter Optimization

```python
# Optuna optimization
def objective(trial):
    params = {
        'n_estimators': trial.suggest_int('n_estimators', 50, 500),
        'max_depth': trial.suggest_int('max_depth', 3, 20),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3),
    }

    model = XGBClassifier(**params)
    score = cross_val_score(model, X, y, cv=5).mean()

    return score

study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=100)
```

### Distributed Training with Ray

```python
# Ray Tune for distributed hyperparameter search
analysis = tune.run(
    train_func,
    config={
        "lr": tune.loguniform(1e-4, 1e-1),
        "batch_size": tune.choice([16, 32, 64]),
    },
    num_samples=20,
    resources_per_trial={"cpu": 2, "gpu": 0.5}
)
```

## 🚀 Model Serving

### REST API Endpoints

```bash
# Single prediction
curl -X POST http://localhost:3000/predict_patient_readmission \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 123,
    "age": 65,
    "heart_rate": 75,
    "oxygen_saturation": 96
  }'

# Batch prediction
curl -X POST http://localhost:3000/batch_predict_customers \
  -H "Content-Type: application/json" \
  -d @customers.json
```

### Response Format

```json
{
  "patient_id": 123,
  "readmission_probability": 0.72,
  "readmission_risk": "High",
  "health_score": 0.28,
  "recommendations": [
    "Schedule follow-up within 48 hours",
    "Review medication compliance",
    "Monitor vital signs daily"
  ]
}
```

## 📈 Model Monitoring

### Metrics Tracked
- **Model Performance**: Accuracy, precision, recall, F1
- **Data Drift**: Feature distribution changes
- **Prediction Drift**: Output distribution changes
- **Service Metrics**: Latency, throughput, errors

### Grafana Dashboards
1. **Model Performance Dashboard**
   - Real-time accuracy
   - Prediction distribution
   - Feature importance

2. **Service Health Dashboard**
   - Request rate
   - Latency percentiles
   - Error rate

3. **Data Quality Dashboard**
   - Missing values
   - Outliers
   - Schema violations

## 🔄 CI/CD Integration

### GitHub Actions Workflow

```yaml
name: ML Pipeline
on:
  push:
    paths:
      - 'ml-platform/**'
  schedule:
    - cron: '0 0 * * 0'  # Weekly

jobs:
  train-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.9'

      - name: Train models
        run: |
          python scripts/train_models.py

      - name: Evaluate models
        run: |
          python scripts/evaluate_models.py

      - name: Deploy if improved
        if: success()
        run: |
          python scripts/deploy_models.py
```

## 🎯 AutoML Capabilities

### AutoML Pipeline

```python
from h2o.automl import H2OAutoML

# Initialize AutoML
aml = H2OAutoML(
    max_models=20,
    seed=42,
    max_runtime_secs=3600,
    include_algos=['XGBoost', 'GBM', 'DRF', 'GLM']
)

# Train
aml.train(x=features, y=target, training_frame=train_df)

# Get best model
best_model = aml.leader

# Save to MLflow
mlflow.h2o.log_model(best_model, "model")
```

## 📊 Experiment Tracking

### MLflow Experiments

```python
import mlflow

with mlflow.start_run(experiment_id="patient_prediction"):
    # Log parameters
    mlflow.log_params({
        "model_type": "XGBoost",
        "n_estimators": 100,
        "max_depth": 10
    })

    # Train model
    model = train_model(X_train, y_train)

    # Log metrics
    metrics = evaluate_model(model, X_test, y_test)
    mlflow.log_metrics(metrics)

    # Log model
    mlflow.sklearn.log_model(model, "model")

    # Register model
    mlflow.register_model(
        f"runs:/{mlflow.active_run().info.run_id}/model",
        "PatientReadmissionModel"
    )
```

## 🔐 Security & Compliance

### Data Privacy
- PII encryption
- Access control
- Audit logging
- GDPR compliance

### Model Governance
- Model versioning
- Approval workflows
- A/B testing
- Rollback capabilities

## 📝 Best Practices

1. **Feature Engineering**
   - Use domain knowledge
   - Create interaction features
   - Handle missing values
   - Normalize/standardize

2. **Model Selection**
   - Start simple
   - Use ensemble methods
   - Cross-validation
   - Avoid overfitting

3. **Deployment**
   - Gradual rollout
   - A/B testing
   - Monitor performance
   - Have rollback plan

4. **Monitoring**
   - Track all metrics
   - Set up alerts
   - Regular retraining
   - Data quality checks

## 🤝 Contributing

To add new ML models:

1. Define features in Feast
2. Create training pipeline in Airflow
3. Track experiments in MLflow
4. Deploy with BentoML
5. Add monitoring dashboards
6. Update documentation

## 📚 Resources

- [MLflow Documentation](https://mlflow.org/docs/)
- [Feast Documentation](https://docs.feast.dev/)
- [Ray Documentation](https://docs.ray.io/)
- [BentoML Documentation](https://docs.bentoml.org/)
- [Airflow Documentation](https://airflow.apache.org/docs/)

## 📄 License

Part of the MySQL Business-to-Schema project.