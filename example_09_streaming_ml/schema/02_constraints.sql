-- ============================================================================
-- Streaming ML Platform Constraints
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Projects -> Organizations
ALTER TABLE projects
    ADD CONSTRAINT fk_project_org
    FOREIGN KEY (org_id) REFERENCES organizations(org_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Data streams -> Projects
ALTER TABLE data_streams
    ADD CONSTRAINT fk_stream_project
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Stream pipelines -> Streams
ALTER TABLE stream_pipelines
    ADD CONSTRAINT fk_pipeline_stream
    FOREIGN KEY (stream_id) REFERENCES data_streams(stream_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Stream events -> Streams
ALTER TABLE stream_events
    ADD CONSTRAINT fk_event_stream
    FOREIGN KEY (stream_id) REFERENCES data_streams(stream_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Feature definitions -> Projects
ALTER TABLE feature_definitions
    ADD CONSTRAINT fk_feature_project
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Raw features -> Feature definitions
ALTER TABLE raw_features
    ADD CONSTRAINT fk_raw_feature_definition
    FOREIGN KEY (feature_id) REFERENCES feature_definitions(feature_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Feature computations -> Feature definitions
ALTER TABLE feature_computations
    ADD CONSTRAINT fk_computation_feature
    FOREIGN KEY (feature_id) REFERENCES feature_definitions(feature_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Feature sets -> Projects
ALTER TABLE feature_sets
    ADD CONSTRAINT fk_feature_set_project
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Experiments -> Projects
ALTER TABLE experiments
    ADD CONSTRAINT fk_experiment_project
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Experiment runs -> Experiments
ALTER TABLE experiment_runs
    ADD CONSTRAINT fk_run_experiment
    FOREIGN KEY (experiment_id) REFERENCES experiments(experiment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Run metrics -> Experiment runs
ALTER TABLE run_metrics
    ADD CONSTRAINT fk_metric_run
    FOREIGN KEY (run_id) REFERENCES experiment_runs(run_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Models -> Projects, Experiments, Runs, Feature sets
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

-- Model evaluations -> Models
ALTER TABLE model_evaluations
    ADD CONSTRAINT fk_evaluation_model
    FOREIGN KEY (model_id) REFERENCES models(model_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Model comparisons -> Projects and Models
ALTER TABLE model_comparisons
    ADD CONSTRAINT fk_comparison_project
    FOREIGN KEY (project_id) REFERENCES projects(project_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_comparison_winner
    FOREIGN KEY (winner_model_id) REFERENCES models(model_id)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- Model deployments -> Models
ALTER TABLE model_deployments
    ADD CONSTRAINT fk_deployment_model
    FOREIGN KEY (model_id) REFERENCES models(model_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- A/B tests -> Projects and Deployments
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

-- Predictions -> Deployments
ALTER TABLE predictions
    ADD CONSTRAINT fk_prediction_deployment
    FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Ground truth -> Predictions
ALTER TABLE ground_truth
    ADD CONSTRAINT fk_ground_truth_prediction
    FOREIGN KEY (prediction_id) REFERENCES predictions(prediction_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Drift detection -> Deployments
ALTER TABLE drift_detection
    ADD CONSTRAINT fk_drift_deployment
    FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Performance metrics -> Deployments
ALTER TABLE performance_metrics
    ADD CONSTRAINT fk_performance_deployment
    FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Model alerts -> Deployments
ALTER TABLE model_alerts
    ADD CONSTRAINT fk_alert_deployment
    FOREIGN KEY (deployment_id) REFERENCES model_deployments(deployment_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- Resource allocations -> Resources
ALTER TABLE resource_allocations
    ADD CONSTRAINT fk_allocation_resource
    FOREIGN KEY (resource_id) REFERENCES compute_resources(resource_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- Data quality rules -> Various entities (no FK due to polymorphic relationship)

-- Data quality violations -> Rules
ALTER TABLE data_quality_violations
    ADD CONSTRAINT fk_violation_rule
    FOREIGN KEY (rule_id) REFERENCES data_quality_rules(rule_id)
    ON DELETE CASCADE ON UPDATE CASCADE;

-- User activity -> Organizations
ALTER TABLE user_activity
    ADD CONSTRAINT fk_activity_org
    FOREIGN KEY (org_id) REFERENCES organizations(org_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- API usage -> Organizations
ALTER TABLE api_usage
    ADD CONSTRAINT fk_api_usage_org
    FOREIGN KEY (org_id) REFERENCES organizations(org_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Ensure valid subscription limits
ALTER TABLE organizations
    ADD CONSTRAINT chk_org_limits CHECK (
        max_models > 0 AND max_deployments > 0 AND max_streams > 0
    );

-- Ensure valid window sizes
ALTER TABLE stream_pipelines
    ADD CONSTRAINT chk_pipeline_window CHECK (
        (window_type = 'None' AND window_size_seconds IS NULL) OR
        (window_type != 'None' AND window_size_seconds > 0)
    );

-- Ensure valid feature TTL
ALTER TABLE feature_definitions
    ADD CONSTRAINT chk_feature_ttl CHECK (
        ttl_seconds IS NULL OR ttl_seconds > 0
    );

-- Ensure valid experiment times
ALTER TABLE experiments
    ADD CONSTRAINT chk_experiment_times CHECK (
        end_time IS NULL OR end_time >= start_time
    );

-- Ensure valid run times
ALTER TABLE experiment_runs
    ADD CONSTRAINT chk_run_times CHECK (
        end_time IS NULL OR end_time >= start_time
    );

-- Ensure valid model size
ALTER TABLE models
    ADD CONSTRAINT chk_model_size CHECK (
        model_size_bytes IS NULL OR model_size_bytes > 0
    );

-- Ensure valid traffic percentage
ALTER TABLE model_deployments
    ADD CONSTRAINT chk_deployment_traffic CHECK (
        traffic_percentage BETWEEN 0 AND 100
    );

-- Ensure valid significance level
ALTER TABLE ab_tests
    ADD CONSTRAINT chk_ab_test_significance CHECK (
        significance_level BETWEEN 0.001 AND 0.1
    );

-- Ensure valid prediction probability
ALTER TABLE predictions
    ADD CONSTRAINT chk_prediction_probability CHECK (
        prediction_probability IS NULL OR prediction_probability BETWEEN 0 AND 1
    );

-- Ensure valid drift score
ALTER TABLE drift_detection
    ADD CONSTRAINT chk_drift_score CHECK (
        drift_score BETWEEN 0 AND 1
    );

-- Ensure valid resource capacity
ALTER TABLE compute_resources
    ADD CONSTRAINT chk_resource_capacity CHECK (
        available_capacity <= total_capacity AND
        available_capacity >= 0 AND
        total_capacity > 0
    );

-- ============================================================================
-- Triggers for Business Logic
-- ============================================================================


-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique active deployment per model per environment
ALTER TABLE model_deployments
    ADD COLUMN active_model_id INT GENERATED ALWAYS AS (
        CASE WHEN status = 'Active' THEN model_id ELSE NULL END
    ) STORED,
    ADD COLUMN active_environment VARCHAR(50) GENERATED ALWAYS AS (
        CASE WHEN status = 'Active' THEN environment ELSE NULL END
    ) STORED;

CREATE UNIQUE INDEX uk_active_deployment
    ON model_deployments(active_model_id, active_environment);

-- Ensure unique request ID for predictions
ALTER TABLE predictions
    ADD CONSTRAINT uk_prediction_request
    UNIQUE KEY (request_id);

-- Ensure unique ground truth per prediction
ALTER TABLE ground_truth
    ADD CONSTRAINT uk_ground_truth_prediction
    UNIQUE KEY (prediction_id);

-- ============================================================================
-- Default Value Constraints
-- ============================================================================

-- Set default timestamps
ALTER TABLE stream_events
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE raw_features
    MODIFY COLUMN ingestion_timestamp DATETIME(3) DEFAULT CURRENT_TIMESTAMP(3);

ALTER TABLE predictions
    MODIFY COLUMN created_at DATETIME DEFAULT CURRENT_TIMESTAMP;
