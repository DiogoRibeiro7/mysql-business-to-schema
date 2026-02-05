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

DELIMITER $$

-- Auto-generate API key for organizations
CREATE TRIGGER trg_org_api_key
BEFORE INSERT ON organizations
FOR EACH ROW
BEGIN
    IF NEW.api_key IS NULL THEN
        SET NEW.api_key = SHA2(CONCAT(NEW.org_name, NOW(), RAND()), 256);
    END IF;
END$$

-- Update stream last_connected timestamp
CREATE TRIGGER trg_stream_connection
AFTER INSERT ON stream_events
FOR EACH ROW
BEGIN
    UPDATE data_streams
    SET last_connected = NOW()
    WHERE stream_id = NEW.stream_id;
END$$

-- Update experiment status when runs complete
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

-- Update model status based on evaluation
CREATE TRIGGER trg_model_validation
AFTER INSERT ON model_evaluations
FOR EACH ROW
BEGIN
    DECLARE accuracy_threshold DECIMAL(5,4);
    SET accuracy_threshold = 0.80; -- Configurable threshold

    IF NEW.evaluation_type = 'Validation' THEN
        IF JSON_EXTRACT(NEW.metrics, '$.accuracy') >= accuracy_threshold THEN
            UPDATE models
            SET status = 'Validated'
            WHERE model_id = NEW.model_id
              AND status = 'Trained';
        END IF;
    END IF;
END$$

-- Track deployment health based on predictions
CREATE TRIGGER trg_deployment_health
AFTER INSERT ON predictions
FOR EACH ROW
BEGIN
    DECLARE recent_errors INT;
    DECLARE avg_response_time DECIMAL(10,2);

    -- Check recent prediction errors and response times
    SELECT
        COUNT(CASE WHEN response_time_ms > 1000 THEN 1 END),
        AVG(response_time_ms)
    INTO recent_errors, avg_response_time
    FROM predictions
    WHERE deployment_id = NEW.deployment_id
      AND prediction_timestamp >= NOW() - INTERVAL 5 MINUTE;

    -- Update health status
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

-- Generate drift alert when significant drift detected
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

-- Calculate and update performance metrics when ground truth received
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

    -- Get deployment and prediction info
    SELECT p.deployment_id, p.prediction_result
    INTO deployment_id, prediction_result
    FROM predictions p
    WHERE p.prediction_id = NEW.prediction_id;

    -- Simple binary classification metrics (extend for multi-class)
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

    -- Update or insert performance metrics
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

-- Update resource availability when allocated
CREATE TRIGGER trg_resource_allocation
AFTER INSERT ON resource_allocations
FOR EACH ROW
BEGIN
    UPDATE compute_resources
    SET available_capacity = available_capacity - NEW.allocated_amount
    WHERE resource_id = NEW.resource_id;
END$$

-- Release resources when allocation ends
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

-- Track API usage limits
CREATE TRIGGER trg_api_usage_limits
AFTER INSERT ON api_usage
FOR EACH ROW
BEGIN
    DECLARE monthly_calls INT;
    DECLARE max_calls INT;

    -- Get monthly API calls and limit
    SELECT COUNT(*), o.max_models * 1000 -- Simplified: 1000 calls per model
    INTO monthly_calls, max_calls
    FROM api_usage a
    INNER JOIN organizations o ON a.org_id = o.org_id
    WHERE a.org_id = NEW.org_id
      AND a.request_timestamp >= DATE_FORMAT(NOW(), '%Y-%m-01');

    -- Alert if approaching limit
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

-- Validate data quality rules
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

        -- Simplified validation (extend based on rule type)
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

-- ============================================================================
-- Unique Constraints
-- ============================================================================

-- Ensure unique active deployment per model per environment
CREATE UNIQUE INDEX uk_active_deployment
    ON model_deployments(model_id, environment, status)
    WHERE status = 'Active';

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