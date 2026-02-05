-- ============================================================================
-- Streaming ML Platform Real-time Monitoring Queries
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Active Model Deployments Dashboard
-- ============================================================================

-- Real-time deployment status and health
SELECT
    d.deployment_id,
    d.deployment_name,
    m.model_name,
    m.model_version,
    d.environment,
    d.deployment_type,
    d.status AS deployment_status,
    d.health_status,
    d.traffic_percentage,
    d.deployed_at,
    TIMESTAMPDIFF(HOUR, d.deployed_at, NOW()) AS hours_deployed,
    -- Recent prediction metrics
    COUNT(DISTINCT p.prediction_id) AS predictions_last_hour,
    AVG(p.response_time_ms) AS avg_response_time_ms,
    MAX(p.response_time_ms) AS max_response_time_ms,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY p.response_time_ms) AS p95_response_time_ms,
    -- Recent alerts
    COUNT(DISTINCT a.alert_id) AS active_alerts,
    MAX(a.severity) AS max_alert_severity
FROM model_deployments d
INNER JOIN models m ON d.model_id = m.model_id
LEFT JOIN predictions p ON d.deployment_id = p.deployment_id
    AND p.prediction_timestamp >= NOW() - INTERVAL 1 HOUR
LEFT JOIN model_alerts a ON d.deployment_id = a.deployment_id
    AND a.resolved_at IS NULL
WHERE d.status = 'Active'
GROUP BY d.deployment_id
ORDER BY d.environment, d.deployed_at DESC;

-- ============================================================================
-- Stream Processing Status
-- ============================================================================

-- Active data streams and processing status
WITH stream_metrics AS (
    SELECT
        s.stream_id,
        COUNT(e.event_id) AS events_last_hour,
        SUM(CASE WHEN e.processing_status = 'Processed' THEN 1 ELSE 0 END) AS processed_events,
        SUM(CASE WHEN e.processing_status = 'Failed' THEN 1 ELSE 0 END) AS failed_events,
        SUM(CASE WHEN e.processing_status = 'Pending' THEN 1 ELSE 0 END) AS pending_events,
        MAX(e.event_timestamp) AS last_event_time
    FROM data_streams s
    LEFT JOIN stream_events e ON s.stream_id = e.stream_id
        AND e.event_timestamp >= NOW() - INTERVAL 1 HOUR
    WHERE s.is_active = TRUE
    GROUP BY s.stream_id
)
SELECT
    p.project_name,
    s.stream_name,
    s.stream_type,
    s.data_format,
    s.last_connected,
    TIMESTAMPDIFF(MINUTE, s.last_connected, NOW()) AS minutes_since_connected,
    CASE
        WHEN s.last_connected IS NULL THEN 'Never Connected'
        WHEN TIMESTAMPDIFF(MINUTE, s.last_connected, NOW()) > 60 THEN 'OFFLINE'
        WHEN TIMESTAMPDIFF(MINUTE, s.last_connected, NOW()) > 10 THEN 'STALE'
        ELSE 'ACTIVE'
    END AS connection_status,
    sm.events_last_hour,
    sm.processed_events,
    sm.failed_events,
    sm.pending_events,
    ROUND(sm.processed_events / NULLIF(sm.events_last_hour, 0) * 100, 1) AS processing_rate_pct,
    sm.last_event_time,
    COUNT(DISTINCT sp.pipeline_id) AS active_pipelines
FROM data_streams s
INNER JOIN projects p ON s.project_id = p.project_id
LEFT JOIN stream_metrics sm ON s.stream_id = sm.stream_id
LEFT JOIN stream_pipelines sp ON s.stream_id = sp.stream_id AND sp.is_active = TRUE
WHERE s.is_active = TRUE
GROUP BY s.stream_id, sm.stream_id
ORDER BY
    CASE
        WHEN TIMESTAMPDIFF(MINUTE, s.last_connected, NOW()) > 60 THEN 1
        WHEN sm.failed_events > 0 THEN 2
        ELSE 3
    END,
    sm.events_last_hour DESC;

-- ============================================================================
-- Model Performance Monitoring
-- ============================================================================

-- Real-time model performance metrics
WITH recent_predictions AS (
    SELECT
        deployment_id,
        COUNT(*) AS prediction_count,
        AVG(response_time_ms) AS avg_latency,
        MAX(response_time_ms) AS max_latency,
        AVG(prediction_probability) AS avg_confidence
    FROM predictions
    WHERE prediction_timestamp >= NOW() - INTERVAL 1 HOUR
    GROUP BY deployment_id
),
recent_ground_truth AS (
    SELECT
        p.deployment_id,
        COUNT(gt.ground_truth_id) AS labeled_count,
        SUM(CASE WHEN JSON_EXTRACT(p.prediction_result, '$.class') = JSON_EXTRACT(gt.true_label, '$.class')
            THEN 1 ELSE 0 END) AS correct_predictions
    FROM ground_truth gt
    INNER JOIN predictions p ON gt.prediction_id = p.prediction_id
    WHERE gt.received_at >= NOW() - INTERVAL 1 HOUR
    GROUP BY p.deployment_id
)
SELECT
    d.deployment_name,
    m.model_name,
    m.model_version,
    d.environment,
    rp.prediction_count AS predictions_last_hour,
    ROUND(rp.avg_latency, 1) AS avg_latency_ms,
    rp.max_latency AS max_latency_ms,
    ROUND(rp.avg_confidence, 3) AS avg_confidence,
    rgt.labeled_count AS ground_truth_received,
    ROUND(rgt.correct_predictions / NULLIF(rgt.labeled_count, 0) * 100, 1) AS real_time_accuracy,
    pm.accuracy AS last_computed_accuracy,
    pm.f1_score AS last_f1_score,
    TIMESTAMPDIFF(MINUTE, pm.created_at, NOW()) AS minutes_since_metric_update
FROM model_deployments d
INNER JOIN models m ON d.model_id = m.model_id
LEFT JOIN recent_predictions rp ON d.deployment_id = rp.deployment_id
LEFT JOIN recent_ground_truth rgt ON d.deployment_id = rgt.deployment_id
LEFT JOIN performance_metrics pm ON d.deployment_id = pm.deployment_id
    AND pm.metric_window_end = (
        SELECT MAX(metric_window_end)
        FROM performance_metrics
        WHERE deployment_id = d.deployment_id
    )
WHERE d.status = 'Active'
ORDER BY d.environment, rp.prediction_count DESC;

-- ============================================================================
-- Drift Detection Monitoring
-- ============================================================================

-- Recent drift detections
SELECT
    d.deployment_name,
    m.model_name,
    dd.drift_type,
    dd.feature_name,
    dd.drift_score,
    CASE
        WHEN dd.drift_score >= 0.8 THEN 'CRITICAL'
        WHEN dd.drift_score >= 0.5 THEN 'HIGH'
        WHEN dd.drift_score >= 0.3 THEN 'MODERATE'
        ELSE 'LOW'
    END AS drift_severity,
    dd.statistical_test,
    dd.p_value,
    dd.is_significant,
    dd.current_window_start,
    dd.current_window_end,
    dd.detected_at,
    TIMESTAMPDIFF(HOUR, dd.detected_at, NOW()) AS hours_since_detection
FROM drift_detection dd
INNER JOIN model_deployments d ON dd.deployment_id = d.deployment_id
INNER JOIN models m ON d.model_id = m.model_id
WHERE dd.detected_at >= NOW() - INTERVAL 24 HOUR
  AND dd.is_significant = TRUE
ORDER BY dd.drift_score DESC, dd.detected_at DESC;

-- ============================================================================
-- Active Experiments Monitoring
-- ============================================================================

-- Currently running experiments and their progress
WITH run_metrics AS (
    SELECT
        er.experiment_id,
        COUNT(DISTINCT er.run_id) AS total_runs,
        SUM(CASE WHEN er.status = 'Completed' THEN 1 ELSE 0 END) AS completed_runs,
        SUM(CASE WHEN er.status = 'Failed' THEN 1 ELSE 0 END) AS failed_runs,
        SUM(CASE WHEN er.status IN ('Started', 'Running') THEN 1 ELSE 0 END) AS active_runs,
        MAX(JSON_EXTRACT(er.metrics, '$.accuracy')) AS best_accuracy,
        MAX(JSON_EXTRACT(er.metrics, '$.f1_score')) AS best_f1_score,
        AVG(er.duration_seconds) AS avg_duration_seconds
    FROM experiment_runs er
    WHERE er.start_time >= NOW() - INTERVAL 24 HOUR
    GROUP BY er.experiment_id
)
SELECT
    p.project_name,
    e.experiment_name,
    e.status,
    e.start_time,
    TIMESTAMPDIFF(HOUR, e.start_time, NOW()) AS hours_running,
    rm.total_runs,
    rm.completed_runs,
    rm.failed_runs,
    rm.active_runs,
    ROUND(rm.completed_runs / NULLIF(rm.total_runs, 0) * 100, 1) AS completion_rate,
    rm.best_accuracy,
    rm.best_f1_score,
    ROUND(rm.avg_duration_seconds / 60, 1) AS avg_run_duration_minutes,
    e.created_by
FROM experiments e
INNER JOIN projects p ON e.project_id = p.project_id
LEFT JOIN run_metrics rm ON e.experiment_id = rm.experiment_id
WHERE e.status IN ('Planning', 'Running')
   OR e.start_time >= NOW() - INTERVAL 24 HOUR
ORDER BY e.status, e.start_time DESC;

-- ============================================================================
-- Alert Management Dashboard
-- ============================================================================

-- Active unresolved alerts
SELECT
    a.alert_id,
    d.deployment_name,
    m.model_name,
    a.alert_type,
    a.severity,
    a.alert_message,
    a.triggered_at,
    TIMESTAMPDIFF(MINUTE, a.triggered_at, NOW()) AS minutes_unresolved,
    CASE
        WHEN a.acknowledged_at IS NULL THEN 'UNACKNOWLEDGED'
        ELSE CONCAT('Acknowledged by ', a.acknowledged_by)
    END AS acknowledgment_status,
    a.alert_details
FROM model_alerts a
INNER JOIN model_deployments d ON a.deployment_id = d.deployment_id
INNER JOIN models m ON d.model_id = m.model_id
WHERE a.resolved_at IS NULL
ORDER BY
    CASE a.severity
        WHEN 'Critical' THEN 1
        WHEN 'Warning' THEN 2
        ELSE 3
    END,
    a.triggered_at ASC;

-- ============================================================================
-- Feature Store Activity
-- ============================================================================

-- Feature computation and freshness monitoring
WITH feature_activity AS (
    SELECT
        fd.feature_id,
        fd.feature_name,
        fd.feature_group,
        COUNT(DISTINCT rf.entity_id) AS unique_entities,
        COUNT(rf.raw_feature_id) AS raw_features_ingested,
        MAX(rf.event_timestamp) AS latest_feature_time,
        MIN(rf.event_timestamp) AS oldest_feature_time
    FROM feature_definitions fd
    LEFT JOIN raw_features rf ON fd.feature_id = rf.feature_id
        AND rf.event_timestamp >= NOW() - INTERVAL 1 HOUR
    WHERE fd.is_online = TRUE
    GROUP BY fd.feature_id
),
feature_computations_recent AS (
    SELECT
        feature_id,
        COUNT(*) AS computations_last_hour,
        MAX(computed_at) AS last_computed
    FROM feature_computations
    WHERE computed_at >= NOW() - INTERVAL 1 HOUR
    GROUP BY feature_id
)
SELECT
    p.project_name,
    fa.feature_name,
    fa.feature_group,
    fd.computation_type,
    fa.unique_entities,
    fa.raw_features_ingested AS raw_features_1h,
    fcr.computations_last_hour AS computations_1h,
    fa.latest_feature_time,
    TIMESTAMPDIFF(MINUTE, fa.latest_feature_time, NOW()) AS minutes_since_update,
    CASE
        WHEN fa.latest_feature_time IS NULL THEN 'NO DATA'
        WHEN TIMESTAMPDIFF(MINUTE, fa.latest_feature_time, NOW()) > 60 THEN 'STALE'
        WHEN TIMESTAMPDIFF(MINUTE, fa.latest_feature_time, NOW()) > 15 THEN 'DELAYED'
        ELSE 'FRESH'
    END AS freshness_status,
    fd.ttl_seconds,
    CASE
        WHEN fd.ttl_seconds IS NOT NULL AND
             TIMESTAMPDIFF(SECOND, fa.latest_feature_time, NOW()) > fd.ttl_seconds
        THEN 'EXPIRED'
        ELSE 'VALID'
    END AS ttl_status
FROM feature_activity fa
INNER JOIN feature_definitions fd ON fa.feature_id = fd.feature_id
INNER JOIN projects p ON fd.project_id = p.project_id
LEFT JOIN feature_computations_recent fcr ON fa.feature_id = fcr.feature_id
WHERE fd.is_online = TRUE
ORDER BY
    CASE
        WHEN fa.latest_feature_time IS NULL THEN 1
        WHEN TIMESTAMPDIFF(MINUTE, fa.latest_feature_time, NOW()) > 60 THEN 2
        ELSE 3
    END,
    fa.raw_features_ingested DESC;

-- ============================================================================
-- Resource Utilization Monitoring
-- ============================================================================

-- Current resource allocation and availability
SELECT
    cr.resource_name,
    cr.resource_type,
    cr.provider,
    cr.total_capacity,
    cr.available_capacity,
    ROUND((cr.total_capacity - cr.available_capacity) / cr.total_capacity * 100, 1) AS utilization_pct,
    cr.unit,
    cr.status,
    COUNT(ra.allocation_id) AS active_allocations,
    SUM(ra.allocated_amount) AS total_allocated,
    GROUP_CONCAT(
        CONCAT(ra.allocated_to_type, ':', ra.allocated_to_id)
        SEPARATOR ', '
    ) AS allocations
FROM compute_resources cr
LEFT JOIN resource_allocations ra ON cr.resource_id = ra.resource_id
    AND ra.allocation_end IS NULL
WHERE cr.status IN ('Available', 'In Use')
GROUP BY cr.resource_id
ORDER BY utilization_pct DESC, cr.resource_type;

-- ============================================================================
-- A/B Test Monitoring
-- ============================================================================

-- Active A/B tests and their performance
SELECT
    ab.test_name,
    p.project_name,
    ab.status,
    ab.start_time,
    TIMESTAMPDIFF(HOUR, ab.start_time, NOW()) AS hours_running,
    cd.deployment_name AS control_deployment,
    td.deployment_name AS treatment_deployment,
    JSON_UNQUOTE(JSON_EXTRACT(ab.traffic_split, '$.control')) AS control_traffic_pct,
    JSON_UNQUOTE(JSON_EXTRACT(ab.traffic_split, '$.treatment')) AS treatment_traffic_pct,
    -- Control metrics
    (SELECT COUNT(*) FROM predictions WHERE deployment_id = ab.control_deployment_id
     AND prediction_timestamp >= ab.start_time) AS control_predictions,
    (SELECT AVG(response_time_ms) FROM predictions WHERE deployment_id = ab.control_deployment_id
     AND prediction_timestamp >= ab.start_time) AS control_avg_latency,
    -- Treatment metrics
    (SELECT COUNT(*) FROM predictions WHERE deployment_id = ab.treatment_deployment_id
     AND prediction_timestamp >= ab.start_time) AS treatment_predictions,
    (SELECT AVG(response_time_ms) FROM predictions WHERE deployment_id = ab.treatment_deployment_id
     AND prediction_timestamp >= ab.start_time) AS treatment_avg_latency,
    ab.significance_level,
    ab.minimum_sample_size
FROM ab_tests ab
INNER JOIN projects p ON ab.project_id = p.project_id
INNER JOIN model_deployments cd ON ab.control_deployment_id = cd.deployment_id
INNER JOIN model_deployments td ON ab.treatment_deployment_id = td.deployment_id
WHERE ab.status IN ('Planning', 'Running')
ORDER BY ab.start_time DESC;

-- ============================================================================
-- API Usage Monitoring
-- ============================================================================

-- Recent API usage patterns
WITH api_metrics AS (
    SELECT
        org_id,
        COUNT(*) AS total_requests,
        AVG(response_time_ms) AS avg_response_time,
        MAX(response_time_ms) AS max_response_time,
        SUM(CASE WHEN response_status >= 500 THEN 1 ELSE 0 END) AS server_errors,
        SUM(CASE WHEN response_status >= 400 AND response_status < 500 THEN 1 ELSE 0 END) AS client_errors,
        SUM(CASE WHEN response_status < 400 THEN 1 ELSE 0 END) AS successful_requests
    FROM api_usage
    WHERE request_timestamp >= NOW() - INTERVAL 1 HOUR
    GROUP BY org_id
)
SELECT
    o.org_name,
    o.subscription_tier,
    am.total_requests AS requests_last_hour,
    ROUND(am.avg_response_time, 1) AS avg_response_ms,
    am.max_response_time AS max_response_ms,
    am.successful_requests,
    am.client_errors,
    am.server_errors,
    ROUND(am.successful_requests / NULLIF(am.total_requests, 0) * 100, 1) AS success_rate,
    o.max_models * 1000 AS api_limit,
    ROUND(am.total_requests / (o.max_models * 1000) * 100, 1) AS usage_pct
FROM organizations o
LEFT JOIN api_metrics am ON o.org_id = am.org_id
WHERE o.org_id IN (SELECT DISTINCT org_id FROM api_usage WHERE request_timestamp >= NOW() - INTERVAL 1 HOUR)
ORDER BY am.total_requests DESC;

-- ============================================================================
-- Data Quality Monitoring
-- ============================================================================

-- Recent data quality violations
SELECT
    dqr.rule_name,
    dqr.rule_type,
    dqr.applies_to_type,
    CASE dqr.applies_to_type
        WHEN 'Stream' THEN (SELECT stream_name FROM data_streams WHERE stream_id = dqr.applies_to_id)
        WHEN 'Feature' THEN (SELECT feature_name FROM feature_definitions WHERE feature_id = dqr.applies_to_id)
        ELSE CONCAT(dqr.applies_to_type, ':', dqr.applies_to_id)
    END AS applies_to,
    dqv.violation_timestamp,
    dqv.affected_records,
    dqv.severity,
    dqv.violation_details,
    CASE
        WHEN dqv.resolved = TRUE THEN 'RESOLVED'
        WHEN TIMESTAMPDIFF(HOUR, dqv.violation_timestamp, NOW()) > 24 THEN 'OVERDUE'
        ELSE 'ACTIVE'
    END AS status
FROM data_quality_violations dqv
INNER JOIN data_quality_rules dqr ON dqv.rule_id = dqr.rule_id
WHERE dqv.violation_timestamp >= NOW() - INTERVAL 24 HOUR
   OR (dqv.resolved = FALSE AND dqv.severity IN ('Error', 'Warning'))
ORDER BY
    CASE dqv.severity
        WHEN 'Error' THEN 1
        WHEN 'Warning' THEN 2
        ELSE 3
    END,
    dqv.violation_timestamp DESC;