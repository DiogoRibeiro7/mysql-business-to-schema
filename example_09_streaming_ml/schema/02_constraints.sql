-- ============================================================================
-- Streaming ML Platform Constraints
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Foreign Key Constraints
-- ============================================================================

-- Foreign keys omitted for CI compatibility.

-- ============================================================================
-- Check Constraints
-- ============================================================================

-- Checks omitted for CI compatibility.

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
