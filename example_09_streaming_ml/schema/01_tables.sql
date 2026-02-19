-- ============================================================================
-- Streaming ML Platform Tables
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Organizations and Projects
-- ============================================================================

-- Organizations using the platform
CREATE TABLE organizations (
    org_id INT AUTO_INCREMENT PRIMARY KEY,
    org_name VARCHAR(200) NOT NULL UNIQUE,
    org_type ENUM('Enterprise', 'Startup', 'Research', 'Education') NOT NULL,
    contact_email VARCHAR(100),
    api_key VARCHAR(64) UNIQUE,
    subscription_tier ENUM('Free', 'Basic', 'Pro', 'Enterprise') DEFAULT 'Free',
    max_models INT DEFAULT 10,
    max_deployments INT DEFAULT 5,
    max_streams INT DEFAULT 10,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_org_api_key (api_key),
    INDEX idx_org_tier (subscription_tier)
) ENGINE=InnoDB;

-- ML projects within organizations
CREATE TABLE projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    org_id INT NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    project_description TEXT,
    project_type ENUM('Classification', 'Regression', 'Clustering', 'Anomaly Detection',
                     'Recommendation', 'NLP', 'Computer Vision', 'Time Series', 'Other') NOT NULL,
    status ENUM('Active', 'Paused', 'Archived') DEFAULT 'Active',
    created_by VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_org_project (org_id, project_name),
    INDEX idx_project_status (status),
    INDEX idx_project_type (project_type)
) ENGINE=InnoDB;

-- ============================================================================
-- Data Streams Management
-- ============================================================================

-- Data stream definitions
CREATE TABLE data_streams (
    stream_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    stream_name VARCHAR(200) NOT NULL,
    stream_type ENUM('Kafka', 'Kinesis', 'PubSub', 'WebSocket', 'HTTP', 'File', 'Database') NOT NULL,
    connection_config JSON NOT NULL,
    schema_definition JSON,
    data_format ENUM('JSON', 'Avro', 'Protobuf', 'CSV', 'Parquet') DEFAULT 'JSON',
    batch_size INT DEFAULT 100,
    buffer_time_ms INT DEFAULT 1000,
    is_active BOOLEAN DEFAULT TRUE,
    last_connected DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_project_stream (project_id, stream_name),
    INDEX idx_stream_active (is_active, project_id),
    INDEX idx_stream_type (stream_type)
) ENGINE=InnoDB;

-- Stream processing pipelines
CREATE TABLE stream_pipelines (
    pipeline_id INT AUTO_INCREMENT PRIMARY KEY,
    stream_id INT NOT NULL,
    pipeline_name VARCHAR(200) NOT NULL,
    pipeline_config JSON NOT NULL,
    processing_type ENUM('Batch', 'Micro-batch', 'Real-time') DEFAULT 'Micro-batch',
    window_type ENUM('Tumbling', 'Sliding', 'Session', 'None') DEFAULT 'None',
    window_size_seconds INT,
    watermark_delay_seconds INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_pipeline_stream (stream_id, is_active),
    INDEX idx_pipeline_type (processing_type)
) ENGINE=InnoDB;

-- Stream events (partitioned by month)
CREATE TABLE stream_events (
    event_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    stream_id INT NOT NULL,
    event_timestamp DATETIME(3) NOT NULL,
    event_data JSON NOT NULL,
    event_metadata JSON,
    processing_status ENUM('Pending', 'Processing', 'Processed', 'Failed') DEFAULT 'Pending',
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_events_stream (stream_id, event_timestamp DESC),
    INDEX idx_events_status (processing_status, event_timestamp)
) ENGINE=InnoDB;

-- ============================================================================
-- Feature Store
-- ============================================================================

-- Feature definitions
CREATE TABLE feature_definitions (
    feature_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    feature_name VARCHAR(200) NOT NULL,
    feature_group VARCHAR(100),
    description TEXT,
    data_type ENUM('INT', 'FLOAT', 'STRING', 'BOOLEAN', 'TIMESTAMP', 'ARRAY', 'OBJECT') NOT NULL,
    computation_type ENUM('Raw', 'Aggregation', 'Transformation', 'Embedding', 'Derived') NOT NULL,
    computation_logic TEXT,
    dependencies JSON,
    is_online BOOLEAN DEFAULT TRUE,
    is_offline BOOLEAN DEFAULT TRUE,
    ttl_seconds INT,
    version INT DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_project_feature (project_id, feature_name, version),
    INDEX idx_feature_group (feature_group),
    INDEX idx_feature_type (computation_type)
) ENGINE=InnoDB;

-- Raw features (high-frequency ingestion)
CREATE TABLE raw_features (
    raw_feature_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    feature_id INT NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    feature_value JSON NOT NULL,
    event_timestamp DATETIME(3) NOT NULL,
    ingestion_timestamp DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3),
    INDEX idx_raw_feature_lookup (feature_id, entity_id, event_timestamp DESC),
    INDEX idx_raw_feature_entity (entity_id, event_timestamp DESC)
) ENGINE=InnoDB;

-- Computed features (aggregated/transformed)
CREATE TABLE feature_computations (
    computation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    feature_id INT NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    window_start DATETIME NOT NULL,
    window_end DATETIME NOT NULL,
    feature_value JSON NOT NULL,
    statistics JSON,
    computed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_feature_window (feature_id, entity_id, window_start, window_end),
    INDEX idx_computed_lookup (feature_id, entity_id, window_end DESC),
    INDEX idx_computed_time (computed_at)
) ENGINE=InnoDB;

-- Feature sets for model training
CREATE TABLE feature_sets (
    feature_set_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    set_name VARCHAR(200) NOT NULL,
    description TEXT,
    feature_ids JSON NOT NULL,
    label_definition JSON,
    split_config JSON,
    validation_rules JSON,
    version INT DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_project_set (project_id, set_name, version),
    INDEX idx_set_project (project_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Experiment Tracking
-- ============================================================================

-- ML experiments
CREATE TABLE experiments (
    experiment_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    experiment_name VARCHAR(200) NOT NULL,
    description TEXT,
    hypothesis TEXT,
    status ENUM('Planning', 'Running', 'Completed', 'Failed', 'Aborted') DEFAULT 'Planning',
    start_time DATETIME,
    end_time DATETIME,
    created_by VARCHAR(100),
    tags JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_experiment_project (project_id, status),
    INDEX idx_experiment_time (start_time, end_time)
) ENGINE=InnoDB;

-- Experiment runs
CREATE TABLE experiment_runs (
    run_id VARCHAR(64) PRIMARY KEY,
    experiment_id INT NOT NULL,
    run_name VARCHAR(200),
    status ENUM('Started', 'Running', 'Completed', 'Failed', 'Killed') DEFAULT 'Started',
    parameters JSON,
    metrics JSON,
    artifacts JSON,
    environment JSON,
    start_time DATETIME NOT NULL,
    end_time DATETIME,
    duration_seconds INT GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, start_time, end_time)) STORED,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_run_experiment (experiment_id, status),
    INDEX idx_run_time (start_time, end_time)
) ENGINE=InnoDB;

-- Run metrics time series
CREATE TABLE run_metrics (
    metric_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    run_id VARCHAR(64) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,6) NOT NULL,
    step INT,
    timestamp DATETIME(3) NOT NULL,
    INDEX idx_metric_run (run_id, metric_name, timestamp),
    INDEX idx_metric_name (metric_name, timestamp DESC)
) ENGINE=InnoDB;

-- ============================================================================
-- Model Registry
-- ============================================================================

-- Trained models
CREATE TABLE models (
    model_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    experiment_id INT,
    run_id VARCHAR(64),
    model_name VARCHAR(200) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    algorithm VARCHAR(100),
    framework ENUM('TensorFlow', 'PyTorch', 'Scikit-learn', 'XGBoost', 'LightGBM', 'H2O', 'Custom') NOT NULL,
    model_type ENUM('Classification', 'Regression', 'Clustering', 'Anomaly', 'Recommendation', 'NLP', 'Vision', 'Other') NOT NULL,
    feature_set_id INT,
    training_dataset JSON,
    hyperparameters JSON,
    model_size_bytes BIGINT,
    model_location VARCHAR(500),
    metrics JSON,
    tags JSON,
    status ENUM('Training', 'Trained', 'Validated', 'Staged', 'Deployed', 'Deprecated', 'Archived') DEFAULT 'Training',
    created_by VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_model_version (project_id, model_name, model_version),
    INDEX idx_model_status (status),
    INDEX idx_model_type (model_type),
    INDEX idx_model_experiment (experiment_id)
) ENGINE=InnoDB;

-- Model evaluations
CREATE TABLE model_evaluations (
    evaluation_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT NOT NULL,
    evaluation_type ENUM('Training', 'Validation', 'Test', 'Production') NOT NULL,
    dataset_info JSON,
    metrics JSON NOT NULL,
    confusion_matrix JSON,
    roc_curve JSON,
    precision_recall_curve JSON,
    feature_importance JSON,
    evaluation_timestamp DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_evaluation_model (model_id, evaluation_type),
    INDEX idx_evaluation_time (evaluation_timestamp)
) ENGINE=InnoDB;

-- Model comparisons
CREATE TABLE model_comparisons (
    comparison_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    comparison_name VARCHAR(200),
    model_ids JSON NOT NULL,
    comparison_metrics JSON,
    winner_model_id INT,
    comparison_notes TEXT,
    created_by VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_comparison_project (project_id),
    INDEX idx_comparison_winner (winner_model_id)
) ENGINE=InnoDB;

-- ============================================================================
-- Model Deployment
-- ============================================================================

-- Model deployments
CREATE TABLE model_deployments (
    deployment_id INT AUTO_INCREMENT PRIMARY KEY,
    model_id INT NOT NULL,
    deployment_name VARCHAR(200) NOT NULL,
    environment ENUM('Development', 'Staging', 'Production', 'Canary', 'Shadow') NOT NULL,
    deployment_type ENUM('REST API', 'Streaming', 'Batch', 'Edge', 'Embedded') NOT NULL,
    endpoint_url VARCHAR(500),
    deployment_config JSON,
    resource_config JSON,
    scaling_config JSON,
    traffic_percentage INT DEFAULT 100,
    status ENUM('Deploying', 'Active', 'Inactive', 'Failed', 'Retiring') DEFAULT 'Deploying',
    health_status ENUM('Healthy', 'Degraded', 'Unhealthy', 'Unknown') DEFAULT 'Unknown',
    deployed_at DATETIME,
    retired_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_deployment_model (model_id, status),
    INDEX idx_deployment_env (environment, status),
    INDEX idx_deployment_health (health_status)
) ENGINE=InnoDB;

-- A/B testing configurations
CREATE TABLE ab_tests (
    ab_test_id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    control_deployment_id INT NOT NULL,
    treatment_deployment_id INT NOT NULL,
    traffic_split JSON,
    success_metrics JSON,
    significance_level DECIMAL(3,2) DEFAULT 0.05,
    minimum_sample_size INT,
    status ENUM('Planning', 'Running', 'Paused', 'Completed', 'Aborted') DEFAULT 'Planning',
    start_time DATETIME,
    end_time DATETIME,
    winner_deployment_id INT,
    results JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ab_test_project (project_id, status),
    INDEX idx_ab_test_time (start_time, end_time)
) ENGINE=InnoDB;

-- ============================================================================
-- Predictions and Inference
-- ============================================================================

-- Prediction requests and results
CREATE TABLE predictions (
    prediction_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    deployment_id INT NOT NULL,
    request_id VARCHAR(64) UNIQUE,
    input_features JSON NOT NULL,
    prediction_result JSON NOT NULL,
    prediction_probability DECIMAL(5,4),
    prediction_timestamp DATETIME(3) NOT NULL,
    response_time_ms INT,
    model_version VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_prediction_deployment (deployment_id, prediction_timestamp DESC),
    INDEX idx_prediction_request (request_id),
    INDEX idx_prediction_time (prediction_timestamp)
) ENGINE=InnoDB;

-- Ground truth labels for predictions
CREATE TABLE ground_truth (
    ground_truth_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    prediction_id BIGINT NOT NULL UNIQUE,
    true_label JSON NOT NULL,
    feedback_type ENUM('Explicit', 'Implicit', 'System') DEFAULT 'Explicit',
    feedback_source VARCHAR(100),
    received_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ground_truth_prediction (prediction_id),
    INDEX idx_ground_truth_time (received_at)
) ENGINE=InnoDB;

-- ============================================================================
-- Model Monitoring
-- ============================================================================

-- Data drift monitoring
CREATE TABLE drift_detection (
    drift_id INT AUTO_INCREMENT PRIMARY KEY,
    deployment_id INT NOT NULL,
    feature_name VARCHAR(200),
    drift_type ENUM('Data', 'Concept', 'Prediction', 'Performance') NOT NULL,
    reference_window_start DATETIME NOT NULL,
    reference_window_end DATETIME NOT NULL,
    current_window_start DATETIME NOT NULL,
    current_window_end DATETIME NOT NULL,
    drift_score DECIMAL(5,4) NOT NULL,
    statistical_test VARCHAR(50),
    p_value DECIMAL(10,8),
    is_significant BOOLEAN,
    detected_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_drift_deployment (deployment_id, detected_at DESC),
    INDEX idx_drift_type (drift_type, is_significant)
) ENGINE=InnoDB;

-- Model performance monitoring
CREATE TABLE performance_metrics (
    metric_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    deployment_id INT NOT NULL,
    metric_window_start DATETIME NOT NULL,
    metric_window_end DATETIME NOT NULL,
    prediction_count INT,
    avg_response_time_ms DECIMAL(10,2),
    p50_response_time_ms DECIMAL(10,2),
    p95_response_time_ms DECIMAL(10,2),
    p99_response_time_ms DECIMAL(10,2),
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4),
    auc_roc DECIMAL(5,4),
    confusion_matrix JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_deployment_window (deployment_id, metric_window_start, metric_window_end),
    INDEX idx_performance_deployment (deployment_id, metric_window_end DESC),
    INDEX idx_performance_metrics (accuracy, f1_score)
) ENGINE=InnoDB;

-- Model alerts
CREATE TABLE model_alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    deployment_id INT NOT NULL,
    alert_type ENUM('Drift', 'Performance', 'Error', 'Latency', 'Traffic', 'Resource') NOT NULL,
    severity ENUM('Info', 'Warning', 'Critical') NOT NULL,
    alert_message TEXT NOT NULL,
    alert_details JSON,
    triggered_at DATETIME NOT NULL,
    acknowledged_at DATETIME,
    acknowledged_by VARCHAR(100),
    resolved_at DATETIME,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_alert_deployment (deployment_id, triggered_at DESC),
    INDEX idx_alert_unresolved (severity, acknowledged_at),
    INDEX idx_alert_type (alert_type, triggered_at DESC)
) ENGINE=InnoDB;

-- ============================================================================
-- Infrastructure and Resources
-- ============================================================================

-- Compute resources
CREATE TABLE compute_resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(200) NOT NULL UNIQUE,
    resource_type ENUM('CPU', 'GPU', 'TPU', 'Memory', 'Storage') NOT NULL,
    provider ENUM('AWS', 'GCP', 'Azure', 'On-Premise', 'Other') NOT NULL,
    specifications JSON,
    total_capacity DECIMAL(20,2),
    available_capacity DECIMAL(20,2),
    unit VARCHAR(20),
    cost_per_unit DECIMAL(10,4),
    location VARCHAR(100),
    status ENUM('Available', 'In Use', 'Maintenance', 'Offline') DEFAULT 'Available',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_resource_type (resource_type, status),
    INDEX idx_resource_provider (provider)
) ENGINE=InnoDB;

-- Resource allocations
CREATE TABLE resource_allocations (
    allocation_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_id INT NOT NULL,
    allocated_to_type ENUM('Training', 'Deployment', 'Pipeline', 'Experiment') NOT NULL,
    allocated_to_id INT NOT NULL,
    allocated_amount DECIMAL(20,2) NOT NULL,
    allocation_start DATETIME NOT NULL,
    allocation_end DATETIME,
    cost_estimate DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_allocation_resource (resource_id, allocation_start),
    INDEX idx_allocation_active (allocation_end),
) ENGINE=InnoDB;

-- ============================================================================
-- Data Lineage and Governance
-- ============================================================================

-- Data lineage tracking
CREATE TABLE data_lineage (
    lineage_id INT AUTO_INCREMENT PRIMARY KEY,
    source_type ENUM('Stream', 'Feature', 'Model', 'Dataset', 'Pipeline') NOT NULL,
    source_id INT NOT NULL,
    target_type ENUM('Feature', 'Model', 'Prediction', 'Dataset', 'Report') NOT NULL,
    target_id INT NOT NULL,
    transformation_type VARCHAR(100),
    transformation_details JSON,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lineage_source (source_type, source_id),
    INDEX idx_lineage_target (target_type, target_id)
) ENGINE=InnoDB;

-- Data quality rules
CREATE TABLE data_quality_rules (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    applies_to_type ENUM('Stream', 'Feature', 'Dataset') NOT NULL,
    applies_to_id INT NOT NULL,
    rule_name VARCHAR(200) NOT NULL,
    rule_type ENUM('Completeness', 'Uniqueness', 'Validity', 'Consistency', 'Timeliness', 'Accuracy') NOT NULL,
    rule_definition JSON NOT NULL,
    severity ENUM('Info', 'Warning', 'Error') DEFAULT 'Warning',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_quality_rule_target (applies_to_type, applies_to_id, is_active),
    INDEX idx_quality_rule_type (rule_type)
) ENGINE=InnoDB;

-- Data quality violations
CREATE TABLE data_quality_violations (
    violation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    rule_id INT NOT NULL,
    violation_timestamp DATETIME NOT NULL,
    affected_records INT,
    violation_details JSON,
    severity ENUM('Info', 'Warning', 'Error') NOT NULL,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_violation_rule (rule_id, violation_timestamp DESC),
    INDEX idx_violation_unresolved (resolved, severity),
) ENGINE=InnoDB;

-- ============================================================================
-- User Activity and Audit
-- ============================================================================

-- User activity logs
CREATE TABLE user_activity (
    activity_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    org_id INT NOT NULL,
    activity_type ENUM('Login', 'Model Training', 'Model Deployment', 'Data Access',
                       'Configuration Change', 'API Call', 'Export', 'Other') NOT NULL,
    activity_details JSON,
    resource_type VARCHAR(50),
    resource_id INT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    activity_timestamp DATETIME NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_activity_user (user_id, activity_timestamp DESC),
    INDEX idx_activity_org (org_id, activity_timestamp DESC),
    INDEX idx_activity_type (activity_type, activity_timestamp DESC)
) ENGINE=InnoDB;

-- API usage tracking
CREATE TABLE api_usage (
    usage_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    org_id INT NOT NULL,
    api_key VARCHAR(64),
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    request_timestamp DATETIME(3) NOT NULL,
    response_status INT,
    response_time_ms INT,
    request_size_bytes INT,
    response_size_bytes INT,
    error_message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_api_usage_org (org_id, request_timestamp DESC),
    INDEX idx_api_usage_endpoint (endpoint, request_timestamp DESC),
    INDEX idx_api_usage_status (response_status, request_timestamp DESC)
) ENGINE=InnoDB;
