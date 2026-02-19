-- ============================================================================
-- Streaming ML Platform Indexes
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Stream Processing Indexes
-- ============================================================================

-- Stream lookup and filtering
CREATE INDEX idx_stream_active
    ON data_streams(project_id, is_active, stream_type);

CREATE INDEX idx_stream_connection
    ON data_streams(last_connected DESC, is_active);

-- Pipeline processing
CREATE INDEX idx_pipeline_active
    ON stream_pipelines(stream_id, is_active, processing_type);

-- Event processing queue
CREATE INDEX idx_events_pending
    ON stream_events(stream_id, processing_status, event_timestamp);

CREATE INDEX idx_events_failed
    ON stream_events(processing_status, event_timestamp DESC);

-- ============================================================================
-- Feature Store Indexes
-- ============================================================================

-- Feature lookup
CREATE INDEX idx_feature_lookup
    ON feature_definitions(project_id, feature_group, computation_type, is_online);

CREATE INDEX idx_feature_version
    ON feature_definitions(project_id, feature_name, version DESC);

-- Raw feature retrieval
CREATE INDEX idx_raw_feature_entity
    ON raw_features(entity_id, feature_id, event_timestamp DESC);

CREATE INDEX idx_raw_feature_time
    ON raw_features(feature_id, event_timestamp DESC);

-- Computed feature lookup
CREATE INDEX idx_computed_feature
    ON feature_computations(feature_id, entity_id, window_end DESC);

CREATE INDEX idx_computed_recent
    ON feature_computations(computed_at DESC);

-- Feature set management
CREATE INDEX idx_feature_set_version
    ON feature_sets(project_id, set_name, version DESC);

-- ============================================================================
-- Experiment Tracking Indexes
-- ============================================================================

-- Experiment search
CREATE INDEX idx_experiment_status
    ON experiments(project_id, status, start_time DESC);

-- Run tracking
CREATE INDEX idx_run_status
    ON experiment_runs(experiment_id, status, start_time DESC);

CREATE INDEX idx_run_active
    ON experiment_runs(status, start_time DESC);

-- Metrics search
CREATE INDEX idx_metrics_lookup
    ON run_metrics(run_id, metric_name, timestamp DESC);

CREATE INDEX idx_metrics_comparison
    ON run_metrics(metric_name, metric_value DESC, timestamp DESC);

-- ============================================================================
-- Model Registry Indexes
-- ============================================================================

-- Model search and filtering
CREATE INDEX idx_model_search
    ON models(project_id, model_type, status, created_at DESC);

CREATE INDEX idx_model_active
    ON models(project_id, status, model_version DESC);

CREATE INDEX idx_model_framework
    ON models(framework, model_type, created_at DESC);

-- Model evaluation lookup
CREATE INDEX idx_evaluation_lookup
    ON model_evaluations(model_id, evaluation_type, evaluation_timestamp DESC);

-- Model comparison
CREATE INDEX idx_comparison_models
    ON model_comparisons(project_id, created_at DESC);

-- ============================================================================
-- Deployment Management Indexes
-- ============================================================================

-- Active deployments
CREATE INDEX idx_deployment_active
    ON model_deployments(environment, status, health_status);

CREATE INDEX idx_deployment_model
    ON model_deployments(model_id, status, deployed_at DESC);

-- Deployment health monitoring
CREATE INDEX idx_deployment_health
    ON model_deployments(health_status, status);

-- A/B test management
CREATE INDEX idx_ab_test_active
    ON ab_tests(project_id, status, start_time DESC);

CREATE INDEX idx_ab_test_deployment
    ON ab_tests(control_deployment_id, treatment_deployment_id, status);

-- ============================================================================
-- Prediction and Inference Indexes
-- ============================================================================

-- Prediction lookup
CREATE INDEX idx_prediction_lookup
    ON predictions(deployment_id, prediction_timestamp DESC);

CREATE INDEX idx_prediction_request
    ON predictions(request_id);

-- Prediction performance
CREATE INDEX idx_prediction_latency
    ON predictions(deployment_id, response_time_ms DESC);

-- Ground truth matching
CREATE INDEX idx_ground_truth_lookup
    ON ground_truth(prediction_id, received_at DESC);

CREATE INDEX idx_ground_truth_feedback
    ON ground_truth(feedback_type, received_at DESC);

-- ============================================================================
-- Monitoring and Alerting Indexes
-- ============================================================================

-- Drift detection
CREATE INDEX idx_drift_significant
    ON drift_detection(deployment_id, detected_at DESC, is_significant);

CREATE INDEX idx_drift_type
    ON drift_detection(drift_type, detected_at DESC, drift_score DESC);

-- Performance monitoring
CREATE INDEX idx_performance_deployment
    ON performance_metrics(deployment_id, metric_window_end DESC);

CREATE INDEX idx_performance_accuracy
    ON performance_metrics(accuracy DESC, metric_window_end DESC);

-- Alert management
CREATE INDEX idx_alert_unresolved
    ON model_alerts(deployment_id, severity, triggered_at DESC);

CREATE INDEX idx_alert_critical
    ON model_alerts(severity, triggered_at DESC);

CREATE INDEX idx_alert_type_time
    ON model_alerts(alert_type, triggered_at DESC);

-- ============================================================================
-- Resource Management Indexes
-- ============================================================================

-- Resource availability
CREATE INDEX idx_resource_available
    ON compute_resources(resource_type, status, available_capacity DESC);

CREATE INDEX idx_resource_provider
    ON compute_resources(provider, resource_type, status);

-- Active allocations
CREATE INDEX idx_allocation_active
    ON resource_allocations(resource_id, allocation_start, allocation_end);

CREATE INDEX idx_allocation_type
    ON resource_allocations(allocated_to_type, allocated_to_id, allocation_start DESC);

-- ============================================================================
-- Data Lineage and Governance Indexes
-- ============================================================================

-- Lineage tracking
CREATE INDEX idx_lineage_forward
    ON data_lineage(source_type, source_id);

CREATE INDEX idx_lineage_backward
    ON data_lineage(target_type, target_id);

-- Data quality monitoring
CREATE INDEX idx_quality_rule_active
    ON data_quality_rules(applies_to_type, applies_to_id, is_active);

CREATE INDEX idx_quality_rule_type
    ON data_quality_rules(rule_type, severity, is_active);

-- Quality violations
CREATE INDEX idx_violation_unresolved
    ON data_quality_violations(rule_id, resolved, severity);

CREATE INDEX idx_violation_time
    ON data_quality_violations(violation_timestamp DESC, severity);

-- ============================================================================
-- User Activity and Audit Indexes
-- ============================================================================

-- User activity tracking
CREATE INDEX idx_activity_user_time
    ON user_activity(user_id, activity_timestamp DESC);

CREATE INDEX idx_activity_org_time
    ON user_activity(org_id, activity_timestamp DESC);

CREATE INDEX idx_activity_type_time
    ON user_activity(activity_type, activity_timestamp DESC);

-- API usage monitoring
CREATE INDEX idx_api_org_time
    ON api_usage(org_id, request_timestamp DESC);

CREATE INDEX idx_api_endpoint_time
    ON api_usage(endpoint, request_timestamp DESC);

CREATE INDEX idx_api_errors
    ON api_usage(response_status, request_timestamp DESC);

-- ============================================================================
-- Full-Text Search Indexes
-- ============================================================================

-- Project search
CREATE FULLTEXT INDEX ft_project_search
    ON projects(project_name, project_description);

-- Model search
CREATE FULLTEXT INDEX ft_model_search
    ON models(model_name, tags);

-- Experiment search
CREATE FULLTEXT INDEX ft_experiment_search
    ON experiments(experiment_name, description, hypothesis);

-- Alert search
CREATE FULLTEXT INDEX ft_alert_search
    ON model_alerts(alert_message);

-- ============================================================================
-- JSON Field Indexes (MySQL 5.7+)
-- ============================================================================

-- Stream schema fields
ALTER TABLE data_streams ADD INDEX idx_stream_schema
    ((CAST(schema_definition->'$.fields[*].name' AS CHAR(100) ARRAY)));

-- Feature dependencies
ALTER TABLE feature_definitions ADD INDEX idx_feature_deps
    ((CAST(dependencies->'$[*]' AS UNSIGNED ARRAY)));

-- Experiment tags
ALTER TABLE experiments ADD INDEX idx_experiment_tags
    ((CAST(tags->'$[*]' AS CHAR(50) ARRAY)));

-- Model metrics
ALTER TABLE models ADD INDEX idx_model_accuracy
    ((CAST(metrics->'$.accuracy' AS DECIMAL(5,4))));

ALTER TABLE models ADD INDEX idx_model_f1
    ((CAST(metrics->'$.f1_score' AS DECIMAL(5,4))));

-- ============================================================================
-- Covering Indexes for Common Queries
-- ============================================================================

-- Model deployment dashboard
CREATE INDEX idx_deployment_dashboard
    ON model_deployments(
        deployment_id, model_id, environment, status,
        health_status, traffic_percentage, deployed_at;

-- Experiment leaderboard
CREATE INDEX idx_experiment_leaderboard
    ON models(
        experiment_id, model_name, model_version,
        JSON_EXTRACT(metrics, '$.accuracy'),
        JSON_EXTRACT(metrics, '$.f1_score'),
        created_at;

-- Stream health monitoring
CREATE INDEX idx_stream_health
    ON data_streams(
        stream_id, project_id, stream_name,
        is_active, last_connected
    );

-- Feature freshness check
CREATE INDEX idx_feature_freshness
    ON raw_features(
        feature_id, entity_id,
        event_timestamp, ingestion_timestamp
    );

-- ============================================================================
-- Partitioned Table Optimization
-- ============================================================================

-- Create aggregated tables for high-frequency data
CREATE TABLE IF NOT EXISTS predictions_hourly (
    deployment_id INT NOT NULL,
    hour_timestamp DATETIME NOT NULL,
    prediction_count INT,
    avg_response_time_ms DECIMAL(10,2),
    p95_response_time_ms DECIMAL(10,2),
    error_count INT,
    PRIMARY KEY (deployment_id, hour_timestamp),
    INDEX idx_hourly_deployment (deployment_id, hour_timestamp DESC)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS stream_events_daily (
    stream_id INT NOT NULL,
    day_date DATE NOT NULL,
    event_count BIGINT,
    processed_count BIGINT,
    failed_count BIGINT,
    avg_processing_time_ms DECIMAL(10,2),
    PRIMARY KEY (stream_id, day_date),
    INDEX idx_daily_stream (stream_id, day_date DESC)
) ENGINE=InnoDB;

-- ============================================================================
-- System Monitoring Indexes
-- ============================================================================

CREATE INDEX idx_system_metrics_lookup
    ON system_metrics(metric_name, component, timestamp DESC);

CREATE INDEX idx_system_metrics_component
    ON system_metrics(component, timestamp DESC);

-- ============================================================================
-- Statistics Update
-- ============================================================================

-- Update table statistics for optimal query planning
ANALYZE TABLE organizations;
ANALYZE TABLE projects;
ANALYZE TABLE data_streams;
ANALYZE TABLE stream_events;
ANALYZE TABLE feature_definitions;
ANALYZE TABLE raw_features;
ANALYZE TABLE experiments;
ANALYZE TABLE experiment_runs;
ANALYZE TABLE models;
ANALYZE TABLE model_deployments;
ANALYZE TABLE predictions;
ANALYZE TABLE drift_detection;
ANALYZE TABLE model_alerts;
