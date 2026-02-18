-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.367011
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE organizations_status AS ENUM ('Free', 'Basic', 'Pro', 'Enterprise');
CREATE TYPE projects_status AS ENUM ('Active', 'Paused', 'Archived');
CREATE TYPE data_streams_status AS ENUM ('JSON', 'Avro', 'Protobuf', 'CSV', 'Parquet');
CREATE TYPE stream_pipelines_status AS ENUM ('Tumbling', 'Sliding', 'Session', 'None');
CREATE TYPE stream_events_status AS ENUM ('Pending', 'Processing', 'Processed', 'Failed');
CREATE TYPE feature_definitions_status AS ENUM ('Raw', 'Aggregation', 'Transformation', 'Embedding', 'Derived');
CREATE TYPE experiments_status AS ENUM ('Planning', 'Running', 'Completed', 'Failed', 'Aborted');
CREATE TYPE experiment_runs_status AS ENUM ('Started', 'Running', 'Completed', 'Failed', 'Killed');
CREATE TYPE models_status AS ENUM ('Training', 'Trained', 'Validated', 'Staged', 'Deployed', 'Deprecated', 'Archived');
CREATE TYPE model_evaluations_status AS ENUM ('Training', 'Validation', 'Test', 'Production');
CREATE TYPE model_deployments_status AS ENUM ('Healthy', 'Degraded', 'Unhealthy', 'Unknown');
CREATE TYPE ab_tests_status AS ENUM ('Planning', 'Running', 'Paused', 'Completed', 'Aborted');
CREATE TYPE ground_truth_status AS ENUM ('Explicit', 'Implicit', 'System');
CREATE TYPE drift_detection_status AS ENUM ('Data', 'Concept', 'Prediction', 'Performance');
CREATE TYPE model_alerts_status AS ENUM ('Info', 'Warning', 'Critical');
CREATE TYPE compute_resources_status AS ENUM ('Available', 'In Use', 'Maintenance', 'Offline');
CREATE TYPE resource_allocations_status AS ENUM ('Training', 'Deployment', 'Pipeline', 'Experiment');
CREATE TYPE data_lineage_status AS ENUM ('Feature', 'Model', 'Prediction', 'Dataset', 'Report');
CREATE TYPE data_quality_rules_status AS ENUM ('Info', 'Warning', 'Error');
CREATE TYPE data_quality_violations_status AS ENUM ('Info', 'Warning', 'Error');
CREATE TYPE user_activity_status AS ENUM ('Login', 'Model Training', 'Model Deployment', 'Data Access', 'Configuration Change', 'API Call', 'Export', 'Other');

DROP DATABASE IF EXISTS streaming_ml;
-- Create database (run as superuser)
-- CREATE DATABASE streaming_ml;
-- \c streaming_ml

CREATE USER IF NOT EXISTS 'ml_admin'@'localhost' IDENTIFIED BY 'MLAdm1n!2024';
GRANT ALL PRIVILEGES ON streaming_ml.* TO 'ml_admin'@'localhost';
CREATE USER IF NOT EXISTS 'data_scientist'@'localhost' IDENTIFIED BY 'DSc1ent!st2024';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.* TO 'data_scientist'@'localhost';
CREATE USER IF NOT EXISTS 'ml_engineer'@'localhost' IDENTIFIED BY 'MLEng!neer2024';
GRANT SELECT, INSERT, UPDATE, DELETE ON streaming_ml.models TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT, UPDATE ON streaming_ml.model_deployments TO 'ml_engineer'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.predictions TO 'ml_engineer'@'localhost';
CREATE USER IF NOT EXISTS 'stream_service'@'localhost' IDENTIFIED BY 'Str3am!ng2024';
GRANT SELECT, INSERT ON streaming_ml.data_streams TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.stream_events TO 'stream_service'@'localhost';
GRANT SELECT, INSERT ON streaming_ml.raw_features TO 'stream_service'@'localhost';
CREATE USER IF NOT EXISTS 'ml_analyst'@'localhost' IDENTIFIED BY 'An@lyst2024';
GRANT SELECT ON streaming_ml.* TO 'ml_analyst'@'localhost';
FLUSH PRIVILEGES;
DELIMITER $$
CREATE FUNCTION calculate_accuracy(
true_positives INT,
true_negatives INT,
false_positives INT,
false_negatives INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE total INT;
IF total = 0 THEN
RETURN NULL;
END IF;
RETURN (true_positives + true_negatives) / total;
END$$
CREATE FUNCTION calculate_f1_score(
true_positives INT,
false_positives INT,
false_negatives INT
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE precision_val DECIMAL(5,4);
DECLARE recall_val DECIMAL(5,4);
IF (true_positives + false_positives) = 0 THEN
SET precision_val = 0;
ELSE
SET precision_val = true_positives / (true_positives + false_positives);
END IF;
IF (true_positives + false_negatives) = 0 THEN
SET recall_val = 0;
ELSE
SET recall_val = true_positives / (true_positives + false_negatives);
END IF;
IF (precision_val + recall_val) = 0 THEN
RETURN 0;
END IF;
RETURN 2 * (precision_val * recall_val) / (precision_val + recall_val);
END$$
CREATE FUNCTION calculate_auc_roc(
tpr_values JSON,
fpr_values JSON
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE auc DECIMAL(10,6) DEFAULT 0;
DECLARE i INT DEFAULT 0;
DECLARE n INT;
IF n IS NULL OR n < 2 THEN
RETURN NULL;
END IF;
WHILE i < n - 1 DO
SET auc = auc + (
(JSON_EXTRACT(fpr_values, CONCAT('$[', i + 1, ']')) -
JSON_EXTRACT(fpr_values, CONCAT('$[', i, ']'))) *
(JSON_EXTRACT(tpr_values, CONCAT('$[', i + 1, ']')) +
JSON_EXTRACT(tpr_values, CONCAT('$[', i, ']'))) / 2
);
END WHILE;
RETURN auc;
END$$
CREATE FUNCTION calculate_drift_score(
baseline_mean DECIMAL(10,4),
baseline_std DECIMAL(10,4),
current_mean DECIMAL(10,4),
current_std DECIMAL(10,4)
) RETURNS DECIMAL(5,4)
DETERMINISTIC
BEGIN
DECLARE psi DECIMAL(10,6);
IF baseline_std = 0 OR current_std = 0 THEN
RETURN NULL;
END IF;
RETURN LEAST(psi, 1.0);
END$$
CREATE FUNCTION hash_feature_schema(
schema_json JSON
) RETURNS VARCHAR(64)
DETERMINISTIC
BEGIN
RETURN SHA2(CAST(schema_json AS CHAR), 256);
END$$
DELIMITER ;
DELIMITER $$
CREATE PROCEDURE manage_partitions()
BEGIN
DECLARE partition_date DATE;
DECLARE partition_name VARCHAR(20);
IF NOT EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'streaming_ml'
AND table_name = 'stream_events'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE stream_events ADD PARTITION (PARTITION ',
partition_name, ' VALUES LESS THAN (TO_DAYS(''',
DATE_ADD(partition_date, INTERVAL 1 MONTH), ''')))');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END IF;
IF EXISTS (
SELECT 1 FROM information_schema.partitions
WHERE table_schema = 'streaming_ml'
AND table_name = 'stream_events'
AND partition_name = partition_name
) THEN
SET @sql = CONCAT('ALTER TABLE stream_events DROP PARTITION ', partition_name);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
END IF;
END$$
DELIMITER ;
CREATE EVENT IF NOT EXISTS manage_partitions_monthly
ON SCHEDULE EVERY 1 MONTH
STARTS (DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL 1 MONTH), '%Y-%m-01 00:00:00'))
DO CALL manage_partitions();
DELIMITER $$
CREATE PROCEDURE archive_old_models()
BEGIN
UPDATE models
SET status = 'archived'
WHERE status IN ('trained', 'validated')
AND created_at < DATE_SUB(NOW(), INTERVAL 90 DAY)
AND model_id NOT IN (
SELECT model_id FROM model_deployments
WHERE status = 'active'
);
DELETE FROM predictions
WHERE prediction_timestamp < DATE_SUB(NOW(), INTERVAL 30 DAY);
DELETE FROM feature_computations
WHERE computed_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
END$$
DELIMITER ;
CREATE EVENT IF NOT EXISTS archive_models_weekly
ON SCHEDULE EVERY 1 WEEK
STARTS (DATE_ADD(DATE(NOW()), INTERVAL 1 DAY))
DO CALL archive_old_models();
CREATE TABLE IF NOT EXISTS schema_version (
    version VARCHAR(20) NOT NULL,
    description TEXT,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT USER()
);

INSERT INTO schema_version (version, description)
VALUES ('1.0.0', 'Initial Streaming ML Platform database schema');
CREATE TABLE IF NOT EXISTS system_metrics (
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,6),
    metric_unit VARCHAR(50),
    component VARCHAR(100),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(3),
    tags JSONB
);

CREATE TABLE IF NOT EXISTS organizations (
    org_type organizations_status NOT NULL,
    contact_email VARCHAR(100),
    subscription_tier organizations_status DEFAULT 'Free',
    max_models INTEGER DEFAULT 10,
    max_deployments INTEGER DEFAULT 5,
    max_streams INTEGER DEFAULT 10,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS projects (
    org_id INTEGER NOT NULL,
    project_name VARCHAR(200) NOT NULL,
    project_description TEXT,
    project_type projects_status NOT NULL,
    status projects_status DEFAULT 'Active',
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (org_id, project_name)
);

CREATE TABLE IF NOT EXISTS data_streams (
    project_id INTEGER NOT NULL,
    stream_name VARCHAR(200) NOT NULL,
    stream_type data_streams_status NOT NULL,
    connection_config JSONB NOT NULL,
    schema_definition JSONB,
    data_format data_streams_status DEFAULT 'JSON',
    batch_size INTEGER DEFAULT 100,
    buffer_time_ms INTEGER DEFAULT 1000,
    is_active BOOLEAN DEFAULT TRUE,
    last_connected TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, stream_name)
);

CREATE TABLE IF NOT EXISTS stream_pipelines (
    stream_id INTEGER NOT NULL,
    pipeline_name VARCHAR(200) NOT NULL,
    pipeline_config JSONB NOT NULL,
    processing_type stream_pipelines_status DEFAULT 'Micro-batch',
    window_type stream_pipelines_status DEFAULT 'None',
    window_size_seconds INTEGER,
    watermark_delay_seconds INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS stream_events (
    stream_id INTEGER NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    event_data JSONB NOT NULL,
    event_metadata JSONB,
    processing_status stream_events_status DEFAULT 'Pending',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

CREATE TABLE IF NOT EXISTS feature_definitions (
    project_id INTEGER NOT NULL,
    feature_name VARCHAR(200) NOT NULL,
    feature_group VARCHAR(100),
    description TEXT,
    data_type feature_definitions_status NOT NULL,
    computation_type feature_definitions_status NOT NULL,
    computation_logic TEXT,
    dependencies JSONB,
    is_online BOOLEAN DEFAULT TRUE,
    is_offline BOOLEAN DEFAULT TRUE,
    ttl_seconds INTEGER,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, feature_name, version)
);

CREATE TABLE IF NOT EXISTS raw_features (
    feature_id INTEGER NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    feature_value JSONB NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    ingestion_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(3),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

CREATE TABLE IF NOT EXISTS feature_computations (
    feature_id INTEGER NOT NULL,
    entity_id VARCHAR(100) NOT NULL,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    feature_value JSONB NOT NULL,
    statistics JSONB,
    computed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (feature_id, entity_id, window_start, window_end)
);

CREATE TABLE IF NOT EXISTS feature_sets (
    project_id INTEGER NOT NULL,
    set_name VARCHAR(200) NOT NULL,
    description TEXT,
    feature_ids JSONB NOT NULL,
    label_definition JSONB,
    split_config JSONB,
    validation_rules JSONB,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, set_name, version)
);

CREATE TABLE IF NOT EXISTS experiments (
    project_id INTEGER NOT NULL,
    experiment_name VARCHAR(200) NOT NULL,
    description TEXT,
    hypothesis TEXT,
    status experiments_status DEFAULT 'Planning',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    created_by VARCHAR(100),
    tags JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS experiment_runs (
    experiment_id INTEGER NOT NULL,
    run_name VARCHAR(200),
    status experiment_runs_status DEFAULT 'Started',
    parameters JSONB,
    metrics JSONB,
    artifacts JSONB,
    environment JSONB,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP,
    duration_seconds INTEGER GENERATED ALWAYS AS (TIMESTAMPDIFF(SECOND, start_time, end_time)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS run_metrics (
    run_id VARCHAR(64) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    metric_value DECIMAL(20,6) NOT NULL,
    step INTEGER,
    timestamp TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS models (
    project_id INTEGER NOT NULL,
    experiment_id INTEGER,
    run_id VARCHAR(64),
    model_name VARCHAR(200) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    algorithm VARCHAR(100),
    framework models_status NOT NULL,
    model_type models_status NOT NULL,
    feature_set_id INTEGER,
    training_dataset JSONB,
    hyperparameters JSONB,
    model_size_bytes BIGINT,
    model_location VARCHAR(500),
    metrics JSONB,
    tags JSONB,
    status models_status DEFAULT 'Training',
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (project_id, model_name, model_version)
);

CREATE TABLE IF NOT EXISTS model_evaluations (
    model_id INTEGER NOT NULL,
    evaluation_type model_evaluations_status NOT NULL,
    dataset_info JSONB,
    metrics JSONB NOT NULL,
    confusion_matrix JSONB,
    roc_curve JSONB,
    precision_recall_curve JSONB,
    feature_importance JSONB,
    evaluation_timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS model_comparisons (
    project_id INTEGER NOT NULL,
    comparison_name VARCHAR(200),
    model_ids JSONB NOT NULL,
    comparison_metrics JSONB,
    winner_model_id INTEGER,
    comparison_notes TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS model_deployments (
    model_id INTEGER NOT NULL,
    deployment_name VARCHAR(200) NOT NULL,
    environment model_deployments_status NOT NULL,
    deployment_type model_deployments_status NOT NULL,
    endpoint_url VARCHAR(500),
    deployment_config JSONB,
    resource_config JSONB,
    scaling_config JSONB,
    traffic_percentage INTEGER DEFAULT 100,
    status model_deployments_status DEFAULT 'Deploying',
    health_status model_deployments_status DEFAULT 'Unknown',
    deployed_at TIMESTAMP,
    retired_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ab_tests (
    project_id INTEGER NOT NULL,
    test_name VARCHAR(200) NOT NULL,
    control_deployment_id INTEGER NOT NULL,
    treatment_deployment_id INTEGER NOT NULL,
    traffic_split JSONB,
    success_metrics JSONB,
    significance_level DECIMAL(3,2) DEFAULT 0.05,
    minimum_sample_size INTEGER,
    status ab_tests_status DEFAULT 'Planning',
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    winner_deployment_id INTEGER,
    results JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS predictions (
    deployment_id INTEGER NOT NULL,
    input_features JSONB NOT NULL,
    prediction_result JSONB NOT NULL,
    prediction_probability DECIMAL(5,4),
    prediction_timestamp TIMESTAMP NOT NULL,
    response_time_ms INTEGER,
    model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-03-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-04-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-05-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-06-01')),
    PARTITION TEXT VALUES LESS THAN (TO_DAYS('2024-07-01'))
);

CREATE TABLE IF NOT EXISTS ground_truth (
    true_label JSONB NOT NULL,
    feedback_type ground_truth_status DEFAULT 'Explicit',
    feedback_source VARCHAR(100),
    received_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS drift_detection (
    deployment_id INTEGER NOT NULL,
    feature_name VARCHAR(200),
    drift_type drift_detection_status NOT NULL,
    reference_window_start TIMESTAMP NOT NULL,
    reference_window_end TIMESTAMP NOT NULL,
    current_window_start TIMESTAMP NOT NULL,
    current_window_end TIMESTAMP NOT NULL,
    drift_score DECIMAL(5,4) NOT NULL,
    statistical_test VARCHAR(50),
    p_value DECIMAL(10,8),
    is_significant BOOLEAN,
    detected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS performance_metrics (
    deployment_id INTEGER NOT NULL,
    metric_window_start TIMESTAMP NOT NULL,
    metric_window_end TIMESTAMP NOT NULL,
    prediction_count INTEGER,
    avg_response_time_ms DECIMAL(10,2),
    p50_response_time_ms DECIMAL(10,2),
    p95_response_time_ms DECIMAL(10,2),
    p99_response_time_ms DECIMAL(10,2),
    accuracy DECIMAL(5,4),
    precision_score DECIMAL(5,4),
    recall_score DECIMAL(5,4),
    f1_score DECIMAL(5,4) GENERATED ALWAYS AS (,
    auc_roc DECIMAL(5,4),
    confusion_matrix JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (deployment_id, metric_window_start, metric_window_end)
);

CREATE TABLE IF NOT EXISTS model_alerts (
    deployment_id INTEGER NOT NULL,
    alert_type model_alerts_status NOT NULL,
    severity model_alerts_status NOT NULL,
    alert_message TEXT NOT NULL,
    alert_details JSONB,
    triggered_at TIMESTAMP NOT NULL,
    acknowledged_at TIMESTAMP,
    acknowledged_by VARCHAR(100),
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(100),
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compute_resources (
    resource_type compute_resources_status NOT NULL,
    provider compute_resources_status NOT NULL,
    specifications JSONB,
    total_capacity DECIMAL(20,2),
    available_capacity DECIMAL(20,2),
    unit VARCHAR(20),
    cost_per_unit DECIMAL(10,4),
    location VARCHAR(100),
    status compute_resources_status DEFAULT 'Available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS resource_allocations (
    resource_id INTEGER NOT NULL,
    allocated_to_type resource_allocations_status NOT NULL,
    allocated_to_id INTEGER NOT NULL,
    allocated_amount DECIMAL(20,2) NOT NULL,
    allocation_start TIMESTAMP NOT NULL,
    allocation_end TIMESTAMP,
    cost_estimate DECIMAL(10,2),
    actual_cost DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS data_lineage (
    source_type data_lineage_status NOT NULL,
    source_id INTEGER NOT NULL,
    target_type data_lineage_status NOT NULL,
    target_id INTEGER NOT NULL,
    transformation_type VARCHAR(100),
    transformation_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS data_quality_rules (
    applies_to_type data_quality_rules_status NOT NULL,
    applies_to_id INTEGER NOT NULL,
    rule_name VARCHAR(200) NOT NULL,
    rule_definition JSONB NOT NULL,
    severity data_quality_rules_status DEFAULT 'Warning',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS data_quality_violations (
    rule_id INTEGER NOT NULL,
    violation_timestamp TIMESTAMP NOT NULL,
    affected_records INTEGER,
    violation_details JSONB,
    severity data_quality_violations_status NOT NULL,
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_activity (
    user_id VARCHAR(100) NOT NULL,
    org_id INTEGER NOT NULL,
    activity_type user_activity_status NOT NULL,
    activity_details JSONB,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    ip_address VARCHAR(45),
    user_agent TEXT,
    activity_timestamp TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS api_usage (
    org_id INTEGER NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    request_timestamp TIMESTAMP NOT NULL,
    response_status INTEGER,
    response_time_ms INTEGER,
    request_size_bytes INTEGER,
    response_size_bytes INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE projects
ADD CONSTRAINT fk_project_org
FOREIGN KEY (org_id) REFERENCES organizations(org_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE data_streams
ADD CONSTRAINT fk_stream_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE stream_pipelines
ADD CONSTRAINT fk_pipeline_stream
FOREIGN KEY (stream_id) REFERENCES data_streams(stream_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE stream_events
ADD CONSTRAINT fk_event_stream
FOREIGN KEY (stream_id) REFERENCES data_streams(stream_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE feature_definitions
ADD CONSTRAINT fk_feature_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE raw_features
ADD CONSTRAINT fk_raw_feature_definition
FOREIGN KEY (feature_id) REFERENCES feature_definitions(feature_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE feature_computations
ADD CONSTRAINT fk_computation_feature
FOREIGN KEY (feature_id) REFERENCES feature_definitions(feature_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE feature_sets
ADD CONSTRAINT fk_feature_set_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE experiments
ADD CONSTRAINT fk_experiment_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE experiment_runs
ADD CONSTRAINT fk_run_experiment
FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE run_metrics
ADD CONSTRAINT fk_metric_run
FOREIGN KEY (run_id) REFERENCES experiment_runs(run_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE models
ADD CONSTRAINT fk_model_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_model_experiment
FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_model_run
FOREIGN KEY (run_id) REFERENCES experiment_runs(run_id)
ON DELETE SET NULL ON UPDATE CASCADE,
ADD CONSTRAINT fk_model_feature_set
FOREIGN KEY (feature_set_id) REFERENCES feature_sets(feature_set_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE model_evaluations
ADD CONSTRAINT fk_evaluation_model
FOREIGN KEY (model_id) REFERENCES models(model_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE model_comparisons
ADD CONSTRAINT fk_comparison_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_comparison_winner
FOREIGN KEY (winner_model_id) REFERENCES models(model_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE model_deployments
ADD CONSTRAINT fk_deployment_model
FOREIGN KEY (model_id) REFERENCES models(model_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE ab_tests
ADD CONSTRAINT fk_ab_test_project
FOREIGN KEY (project_id) REFERENCES projects(project_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_ab_test_control
FOREIGN KEY (control_deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_ab_test_treatment
FOREIGN KEY (treatment_deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE RESTRICT ON UPDATE CASCADE,
ADD CONSTRAINT fk_ab_test_winner
FOREIGN KEY (winner_deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE predictions
ADD CONSTRAINT fk_prediction_deployment
FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE ground_truth
ADD CONSTRAINT fk_ground_truth_prediction
FOREIGN KEY (prediction_id) REFERENCES predictions(prediction_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE drift_detection
ADD CONSTRAINT fk_drift_deployment
FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE performance_metrics
ADD CONSTRAINT fk_performance_deployment
FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE model_alerts
ADD CONSTRAINT fk_alert_deployment
FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE resource_allocations
ADD CONSTRAINT fk_allocation_resource
FOREIGN KEY (resource_id) REFERENCES compute_resources(resource_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE data_quality_violations
ADD CONSTRAINT fk_violation_rule
FOREIGN KEY (rule_id) REFERENCES data_quality_rules(rule_id)
ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE user_activity
ADD CONSTRAINT fk_activity_org
FOREIGN KEY (org_id) REFERENCES organizations(org_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE api_usage
ADD CONSTRAINT fk_api_usage_org
FOREIGN KEY (org_id) REFERENCES organizations(org_id)
ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE organizations
ADD CONSTRAINT chk_org_limits CHECK (
max_models > 0 AND max_deployments > 0 AND max_streams > 0
);
ALTER TABLE stream_pipelines
ADD CONSTRAINT chk_pipeline_window CHECK (
(window_type = 'None' AND window_size_seconds IS NULL) OR
(window_type != 'None' AND window_size_seconds > 0)
);
ALTER TABLE feature_definitions
ADD CONSTRAINT chk_feature_ttl CHECK (
ttl_seconds IS NULL OR ttl_seconds > 0
);
ALTER TABLE experiments
ADD CONSTRAINT chk_experiment_times CHECK (
end_time IS NULL OR end_time >= start_time
);
ALTER TABLE experiment_runs
ADD CONSTRAINT chk_run_times CHECK (
end_time IS NULL OR end_time >= start_time
);
ALTER TABLE models
ADD CONSTRAINT chk_model_size CHECK (
model_size_bytes IS NULL OR model_size_bytes > 0
);
ALTER TABLE model_deployments
ADD CONSTRAINT chk_deployment_traffic CHECK (
traffic_percentage BETWEEN 0 AND 100
);
ALTER TABLE ab_tests
ADD CONSTRAINT chk_ab_test_significance CHECK (
significance_level BETWEEN 0.001 AND 0.1
);
ALTER TABLE predictions
ADD CONSTRAINT chk_prediction_probability CHECK (
prediction_probability IS NULL OR prediction_probability BETWEEN 0 AND 1
);
ALTER TABLE drift_detection
ADD CONSTRAINT chk_drift_score CHECK (
drift_score BETWEEN 0 AND 1
);
ALTER TABLE compute_resources
ADD CONSTRAINT chk_resource_capacity CHECK (
available_capacity <= total_capacity AND
available_capacity >= 0 AND
total_capacity > 0
);
DELIMITER $$
CREATE TRIGGER trg_org_api_key
BEFORE INSERT ON organizations
FOR EACH ROW
BEGIN
IF NEW.api_key IS NULL THEN
SET NEW.api_key = SHA2(CONCAT(NEW.org_name, NOW(), RAND()), 256);
END IF;
END$$
CREATE TRIGGER trg_stream_connection
AFTER INSERT ON stream_events
FOR EACH ROW
BEGIN
UPDATE data_streams
SET last_connected = NOW()
WHERE stream_id = NEW.stream_id;
END$$
CREATE TRIGGER trg_experiment_status
AFTER UPDATE ON experiment_runs
FOR EACH ROW
BEGIN
DECLARE total_runs INT;
DECLARE completed_runs INT;
IF OLD.status != 'Completed' AND NEW.status = 'Completed' THEN
SELECT COUNT(*), SUM(CASE WHEN status IN ('Completed', 'Failed') THEN 1 ELSE 0 END)
INTO total_runs, completed_runs
FROM experiment_runs
WHERE experiment_id = NEW.experiment_id;
IF total_runs = completed_runs THEN
UPDATE experiments
SET status = 'Completed',
end_time = NOW()
WHERE experiment_id = NEW.experiment_id
AND status = 'Running';
END IF;
END IF;
END$$
CREATE TRIGGER trg_model_validation
AFTER INSERT ON model_evaluations
FOR EACH ROW
BEGIN
DECLARE accuracy_threshold DECIMAL(5,4);
END IF;
END IF;
END$$
CREATE TRIGGER trg_deployment_health
AFTER INSERT ON predictions
FOR EACH ROW
BEGIN
DECLARE recent_errors INT;
DECLARE avg_response_time DECIMAL(10,2);
SELECT
COUNT(CASE WHEN response_time_ms > 1000 THEN 1 END),
AVG(response_time_ms)
INTO recent_errors, avg_response_time
FROM predictions
WHERE deployment_id = NEW.deployment_id
AND prediction_timestamp >= NOW() - INTERVAL 5 MINUTE;
IF recent_errors > 10 THEN
UPDATE model_deployments
SET health_status = 'Unhealthy'
WHERE deployment_id = NEW.deployment_id;
ELSEIF avg_response_time > 500 THEN
UPDATE model_deployments
SET health_status = 'Degraded'
WHERE deployment_id = NEW.deployment_id;
ELSE
UPDATE model_deployments
SET health_status = 'Healthy'
WHERE deployment_id = NEW.deployment_id;
END IF;
END$$
CREATE TRIGGER trg_drift_alert
AFTER INSERT ON drift_detection
FOR EACH ROW
BEGIN
IF NEW.is_significant = TRUE THEN
INSERT INTO model_alerts (
deployment_id, alert_type, severity, alert_message,
alert_details, triggered_at
) VALUES (
NEW.deployment_id,
'Drift',
CASE
WHEN NEW.drift_score > 0.8 THEN 'Critical'
WHEN NEW.drift_score > 0.5 THEN 'Warning'
ELSE 'Info'
END,
CONCAT('Significant ', NEW.drift_type, ' drift detected for ', COALESCE(NEW.feature_name, 'model')),
JSON_OBJECT(
'drift_score', NEW.drift_score,
'drift_type', NEW.drift_type,
'feature_name', NEW.feature_name,
'p_value', NEW.p_value
),
NEW.detected_at
);
END IF;
END$$
CREATE TRIGGER trg_ground_truth_metrics
AFTER INSERT ON ground_truth
FOR EACH ROW
BEGIN
DECLARE deployment_id INT;
DECLARE prediction_result JSON;
DECLARE true_positive INT DEFAULT 0;
DECLARE true_negative INT DEFAULT 0;
DECLARE false_positive INT DEFAULT 0;
DECLARE false_negative INT DEFAULT 0;
SELECT p.deployment_id, p.prediction_result
INTO deployment_id, prediction_result
FROM predictions p
WHERE p.prediction_id = NEW.prediction_id;
IF JSON_EXTRACT(prediction_result, '$.class') = JSON_EXTRACT(NEW.true_label, '$.class') THEN
IF JSON_EXTRACT(prediction_result, '$.class') = 1 THEN
SET true_positive = 1;
ELSE
SET true_negative = 1;
END IF;
ELSE
IF JSON_EXTRACT(prediction_result, '$.class') = 1 THEN
SET false_positive = 1;
ELSE
SET false_negative = 1;
END IF;
END IF;
INSERT INTO performance_metrics (
deployment_id,
metric_window_start,
metric_window_end,
prediction_count,
confusion_matrix
) VALUES (
deployment_id,
DATE(NEW.received_at),
DATE_ADD(DATE(NEW.received_at), INTERVAL 1 DAY),
1,
JSON_OBJECT(
'true_positives', true_positive,
'true_negatives', true_negative,
'false_positives', false_positive,
'false_negatives', false_negative
)
) ON DUPLICATE KEY UPDATE
prediction_count = prediction_count + 1,
confusion_matrix = JSON_OBJECT(
'true_positives', JSON_EXTRACT(confusion_matrix, '$.true_positives') + true_positive,
'true_negatives', JSON_EXTRACT(confusion_matrix, '$.true_negatives') + true_negative,
'false_positives', JSON_EXTRACT(confusion_matrix, '$.false_positives') + false_positive,
'false_negatives', JSON_EXTRACT(confusion_matrix, '$.false_negatives') + false_negative
);
END$$
CREATE TRIGGER trg_resource_allocation
AFTER INSERT ON resource_allocations
FOR EACH ROW
BEGIN
UPDATE compute_resources
SET available_capacity = available_capacity - NEW.allocated_amount
WHERE resource_id = NEW.resource_id;
END$$
CREATE TRIGGER trg_resource_release
AFTER UPDATE ON resource_allocations
FOR EACH ROW
BEGIN
IF OLD.allocation_end IS NULL AND NEW.allocation_end IS NOT NULL THEN
UPDATE compute_resources
SET available_capacity = available_capacity + NEW.allocated_amount
WHERE resource_id = NEW.resource_id;
END IF;
END$$
CREATE TRIGGER trg_api_usage_limits
AFTER INSERT ON api_usage
FOR EACH ROW
BEGIN
DECLARE monthly_calls INT;
DECLARE max_calls INT;
SELECT COUNT(*), o.max_models * 1000 -- Simplified: 1000 calls per model
INTO monthly_calls, max_calls
FROM api_usage a
INNER JOIN organizations o ON a.org_id = o.org_id
WHERE a.org_id = NEW.org_id
AND a.request_timestamp >= DATE_FORMAT(NOW(), '%Y-%m-01');
IF monthly_calls >= max_calls * 0.9 THEN
INSERT INTO user_activity (
user_id, org_id, activity_type, activity_details, activity_timestamp
) VALUES (
'System', NEW.org_id, 'API Call',
JSON_OBJECT('warning', 'Approaching API usage limit', 'usage', monthly_calls, 'limit', max_calls),
NOW()
);
END IF;
END$$
CREATE TRIGGER trg_data_quality_check
AFTER INSERT ON stream_events
FOR EACH ROW
BEGIN
DECLARE rule_cursor CURSOR FOR
SELECT rule_id, rule_name, rule_definition, severity
FROM data_quality_rules
WHERE applies_to_type = 'Stream'
AND applies_to_id = NEW.stream_id
AND is_active = TRUE;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET @done = TRUE;
DECLARE rule_id INT;
DECLARE rule_name VARCHAR(200);
DECLARE rule_def JSON;
DECLARE severity VARCHAR(10);
OPEN rule_cursor;
read_loop: LOOP
FETCH rule_cursor INTO rule_id, rule_name, rule_def, severity;
IF @done THEN
LEAVE read_loop;
END IF;
IF JSON_EXTRACT(rule_def, '$.required_field') IS NOT NULL
AND JSON_EXTRACT(NEW.event_data, JSON_EXTRACT(rule_def, '$.required_field')) IS NULL THEN
INSERT INTO data_quality_violations (
rule_id, violation_timestamp, affected_records, violation_details, severity
) VALUES (
rule_id, NOW(), 1,
JSON_OBJECT('missing_field', JSON_EXTRACT(rule_def, '$.required_field')),
severity
);
END IF;
END LOOP;
CLOSE rule_cursor;
END$$
DELIMITER ;
CREATE UNIQUE INDEX uk_active_deployment
ON model_deployments(model_id, environment, status)
WHERE status = 'Active';
ALTER TABLE predictions
ADD CONSTRAINT uk_prediction_request
UNIQUE KEY (request_id);
ALTER TABLE ground_truth
ADD CONSTRAINT uk_ground_truth_prediction
UNIQUE KEY (prediction_id);
ALTER TABLE stream_events
MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE raw_features
MODIFY COLUMN ingestion_timestamp DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3);
ALTER TABLE predictions
MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
-- Indexes
CREATE INDEX idx_api_usage_VARCHAR ON api_usage(64);
