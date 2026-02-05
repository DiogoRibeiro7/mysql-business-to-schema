-- ============================================================================
-- Streaming ML Platform Analytics Queries
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Model Performance Analytics
-- ============================================================================

-- Model performance comparison across versions
WITH model_metrics AS (
    SELECT
        m.model_id,
        m.model_name,
        m.model_version,
        m.algorithm,
        m.framework,
        JSON_EXTRACT(m.metrics, '$.accuracy') AS training_accuracy,
        JSON_EXTRACT(m.metrics, '$.f1_score') AS training_f1,
        JSON_EXTRACT(m.metrics, '$.auc_roc') AS training_auc,
        me.evaluation_type,
        JSON_EXTRACT(me.metrics, '$.accuracy') AS eval_accuracy,
        JSON_EXTRACT(me.metrics, '$.f1_score') AS eval_f1,
        JSON_EXTRACT(me.metrics, '$.precision') AS eval_precision,
        JSON_EXTRACT(me.metrics, '$.recall') AS eval_recall
    FROM models m
    LEFT JOIN model_evaluations me ON m.model_id = me.model_id
        AND me.evaluation_type = 'Production'
        AND me.evaluation_timestamp = (
            SELECT MAX(evaluation_timestamp)
            FROM model_evaluations
            WHERE model_id = m.model_id AND evaluation_type = 'Production'
        )
    WHERE m.status IN ('Validated', 'Deployed', 'Staged')
)
SELECT
    p.project_name,
    mm.model_name,
    mm.model_version,
    mm.algorithm,
    mm.framework,
    ROUND(mm.training_accuracy, 4) AS training_accuracy,
    ROUND(mm.training_f1, 4) AS training_f1,
    ROUND(mm.eval_accuracy, 4) AS production_accuracy,
    ROUND(mm.eval_f1, 4) AS production_f1,
    ROUND(mm.eval_precision, 4) AS production_precision,
    ROUND(mm.eval_recall, 4) AS production_recall,
    ROUND(mm.eval_accuracy - mm.training_accuracy, 4) AS accuracy_degradation,
    -- Deployment status
    COUNT(DISTINCT md.deployment_id) AS active_deployments,
    GROUP_CONCAT(DISTINCT md.environment SEPARATOR ', ') AS deployed_environments,
    -- Prediction volume
    COUNT(DISTINCT p2.prediction_id) AS predictions_30d
FROM model_metrics mm
INNER JOIN models m ON mm.model_id = m.model_id
INNER JOIN projects p ON m.project_id = p.project_id
LEFT JOIN model_deployments md ON m.model_id = md.model_id AND md.status = 'Active'
LEFT JOIN predictions p2 ON md.deployment_id = p2.deployment_id
    AND p2.prediction_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY mm.model_id
ORDER BY p.project_name, mm.model_name, mm.model_version DESC;

-- Model drift analysis over time
WITH drift_metrics AS (
    SELECT
        dd.deployment_id,
        DATE(dd.detected_at) AS detection_date,
        dd.drift_type,
        AVG(dd.drift_score) AS avg_drift_score,
        MAX(dd.drift_score) AS max_drift_score,
        COUNT(DISTINCT dd.feature_name) AS drifted_features,
        SUM(CASE WHEN dd.is_significant THEN 1 ELSE 0 END) AS significant_drifts
    FROM drift_detection dd
    WHERE dd.detected_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dd.deployment_id, DATE(dd.detected_at), dd.drift_type
)
SELECT
    d.deployment_name,
    m.model_name,
    dm.detection_date,
    dm.drift_type,
    ROUND(dm.avg_drift_score, 3) AS avg_drift_score,
    ROUND(dm.max_drift_score, 3) AS max_drift_score,
    dm.drifted_features,
    dm.significant_drifts,
    -- Performance correlation
    pm.accuracy AS same_day_accuracy,
    pm.f1_score AS same_day_f1,
    CASE
        WHEN dm.max_drift_score > 0.7 AND pm.accuracy < 0.8 THEN 'HIGH RISK - Drift affecting performance'
        WHEN dm.max_drift_score > 0.5 THEN 'MONITOR - Moderate drift detected'
        ELSE 'STABLE'
    END AS drift_risk_assessment
FROM drift_metrics dm
INNER JOIN model_deployments d ON dm.deployment_id = d.deployment_id
INNER JOIN models m ON d.model_id = m.model_id
LEFT JOIN performance_metrics pm ON d.deployment_id = pm.deployment_id
    AND DATE(pm.metric_window_start) = dm.detection_date
ORDER BY dm.detection_date DESC, dm.max_drift_score DESC;

-- ============================================================================
-- Experiment Analytics
-- ============================================================================

-- Experiment success rates and best practices
WITH experiment_summary AS (
    SELECT
        e.experiment_id,
        e.experiment_name,
        COUNT(DISTINCT er.run_id) AS total_runs,
        SUM(CASE WHEN er.status = 'Completed' THEN 1 ELSE 0 END) AS successful_runs,
        AVG(er.duration_seconds) AS avg_duration_seconds,
        MAX(JSON_EXTRACT(er.metrics, '$.accuracy')) AS best_accuracy,
        MAX(JSON_EXTRACT(er.metrics, '$.f1_score')) AS best_f1_score,
        MIN(JSON_EXTRACT(er.metrics, '$.loss')) AS best_loss,
        COUNT(DISTINCT m.model_id) AS models_produced,
        COUNT(DISTINCT md.deployment_id) AS models_deployed
    FROM experiments e
    LEFT JOIN experiment_runs er ON e.experiment_id = er.experiment_id
    LEFT JOIN models m ON e.experiment_id = m.experiment_id
    LEFT JOIN model_deployments md ON m.model_id = md.model_id AND md.status = 'Active'
    WHERE e.status = 'Completed'
      AND e.end_time >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY e.experiment_id
)
SELECT
    p.project_name,
    es.experiment_name,
    es.total_runs,
    es.successful_runs,
    ROUND(es.successful_runs / NULLIF(es.total_runs, 0) * 100, 1) AS success_rate,
    ROUND(es.avg_duration_seconds / 3600, 2) AS avg_duration_hours,
    es.best_accuracy,
    es.best_f1_score,
    es.best_loss,
    es.models_produced,
    es.models_deployed,
    ROUND(es.models_deployed / NULLIF(es.models_produced, 0) * 100, 1) AS deployment_rate,
    -- Extract hyperparameters that led to best model
    (SELECT JSON_EXTRACT(parameters, '$')
     FROM experiment_runs
     WHERE experiment_id = es.experiment_id
       AND JSON_EXTRACT(metrics, '$.accuracy') = es.best_accuracy
     LIMIT 1) AS best_hyperparameters
FROM experiment_summary es
INNER JOIN experiments e ON es.experiment_id = e.experiment_id
INNER JOIN projects p ON e.project_id = p.project_id
ORDER BY es.best_accuracy DESC;

-- Hyperparameter impact analysis
WITH param_analysis AS (
    SELECT
        e.experiment_id,
        e.experiment_name,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.learning_rate')) AS learning_rate,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.batch_size')) AS batch_size,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.epochs')) AS epochs,
        JSON_EXTRACT(er.metrics, '$.accuracy') AS accuracy,
        JSON_EXTRACT(er.metrics, '$.f1_score') AS f1_score,
        er.duration_seconds
    FROM experiments e
    INNER JOIN experiment_runs er ON e.experiment_id = er.experiment_id
    WHERE er.status = 'Completed'
      AND e.end_time >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
)
SELECT
    experiment_name,
    learning_rate,
    batch_size,
    epochs,
    COUNT(*) AS run_count,
    ROUND(AVG(accuracy), 4) AS avg_accuracy,
    ROUND(STD(accuracy), 4) AS std_accuracy,
    ROUND(MAX(accuracy), 4) AS max_accuracy,
    ROUND(AVG(f1_score), 4) AS avg_f1,
    ROUND(AVG(duration_seconds / 60), 1) AS avg_duration_minutes
FROM param_analysis
GROUP BY experiment_name, learning_rate, batch_size, epochs
HAVING run_count >= 3
ORDER BY avg_accuracy DESC;

-- ============================================================================
-- Feature Engineering Analytics
-- ============================================================================

-- Feature importance and usage analysis
WITH feature_usage AS (
    SELECT
        fd.feature_id,
        fd.feature_name,
        fd.feature_group,
        fd.computation_type,
        COUNT(DISTINCT fs.feature_set_id) AS used_in_sets,
        COUNT(DISTINCT m.model_id) AS used_in_models,
        COUNT(DISTINCT rf.entity_id) AS unique_entities,
        COUNT(rf.raw_feature_id) AS total_values
    FROM feature_definitions fd
    LEFT JOIN feature_sets fs ON JSON_CONTAINS(fs.feature_ids, CAST(fd.feature_id AS JSON))
    LEFT JOIN models m ON fs.feature_set_id = m.feature_set_id
    LEFT JOIN raw_features rf ON fd.feature_id = rf.feature_id
        AND rf.event_timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY fd.feature_id
),
feature_importance_agg AS (
    SELECT
        fd.feature_id,
        AVG(JSON_EXTRACT(me.feature_importance, CONCAT('$."', fd.feature_name, '"'))) AS avg_importance
    FROM feature_definitions fd
    INNER JOIN feature_sets fs ON JSON_CONTAINS(fs.feature_ids, CAST(fd.feature_id AS JSON))
    INNER JOIN models m ON fs.feature_set_id = m.feature_set_id
    INNER JOIN model_evaluations me ON m.model_id = me.model_id
    WHERE me.feature_importance IS NOT NULL
    GROUP BY fd.feature_id
)
SELECT
    p.project_name,
    fu.feature_name,
    fu.feature_group,
    fu.computation_type,
    fu.used_in_sets AS feature_sets_count,
    fu.used_in_models AS models_count,
    fu.unique_entities AS entities_7d,
    fu.total_values AS values_7d,
    ROUND(fia.avg_importance, 4) AS avg_feature_importance,
    CASE
        WHEN fia.avg_importance >= 0.1 THEN 'HIGH'
        WHEN fia.avg_importance >= 0.05 THEN 'MEDIUM'
        WHEN fia.avg_importance >= 0.01 THEN 'LOW'
        ELSE 'MINIMAL'
    END AS importance_level,
    CASE
        WHEN fu.used_in_models = 0 THEN 'UNUSED - Consider removing'
        WHEN fu.total_values = 0 THEN 'NO DATA - Check pipeline'
        WHEN fia.avg_importance < 0.01 AND fu.computation_type != 'Raw' THEN 'LOW VALUE - Review necessity'
        ELSE 'ACTIVE'
    END AS recommendation
FROM feature_usage fu
INNER JOIN feature_definitions fd ON fu.feature_id = fd.feature_id
INNER JOIN projects p ON fd.project_id = p.project_id
LEFT JOIN feature_importance_agg fia ON fu.feature_id = fia.feature_id
ORDER BY fu.used_in_models DESC, fia.avg_importance DESC;

-- ============================================================================
-- Streaming Data Analytics
-- ============================================================================

-- Stream processing efficiency
WITH stream_stats AS (
    SELECT
        s.stream_id,
        s.stream_name,
        DATE(e.event_timestamp) AS event_date,
        COUNT(*) AS event_count,
        SUM(CASE WHEN e.processing_status = 'Processed' THEN 1 ELSE 0 END) AS processed,
        SUM(CASE WHEN e.processing_status = 'Failed' THEN 1 ELSE 0 END) AS failed,
        AVG(TIMESTAMPDIFF(MICROSECOND, e.event_timestamp, e.created_at) / 1000) AS avg_latency_ms,
        MAX(TIMESTAMPDIFF(MICROSECOND, e.event_timestamp, e.created_at) / 1000) AS max_latency_ms
    FROM data_streams s
    LEFT JOIN stream_events e ON s.stream_id = e.stream_id
    WHERE e.event_timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY s.stream_id, DATE(e.event_timestamp)
)
SELECT
    p.project_name,
    ss.stream_name,
    ss.event_date,
    ss.event_count,
    ss.processed,
    ss.failed,
    ROUND(ss.processed / NULLIF(ss.event_count, 0) * 100, 2) AS success_rate,
    ROUND(ss.avg_latency_ms, 2) AS avg_latency_ms,
    ss.max_latency_ms,
    s.stream_type,
    s.batch_size,
    ROUND(ss.event_count / 86400, 2) AS events_per_second,
    CASE
        WHEN ss.failed / NULLIF(ss.event_count, 0) > 0.05 THEN 'HIGH ERROR RATE'
        WHEN ss.max_latency_ms > 5000 THEN 'HIGH LATENCY'
        WHEN ss.event_count < 100 THEN 'LOW VOLUME'
        ELSE 'HEALTHY'
    END AS stream_health
FROM stream_stats ss
INNER JOIN data_streams s ON ss.stream_id = s.stream_id
INNER JOIN projects p ON s.project_id = p.project_id
ORDER BY ss.event_date DESC, ss.event_count DESC;

-- ============================================================================
-- Deployment Efficiency Analytics
-- ============================================================================

-- Deployment lifecycle and efficiency metrics
WITH deployment_metrics AS (
    SELECT
        d.deployment_id,
        d.deployment_name,
        d.environment,
        d.deployed_at,
        COALESCE(d.retired_at, NOW()) AS end_time,
        TIMESTAMPDIFF(DAY, d.deployed_at, COALESCE(d.retired_at, NOW())) AS days_active,
        COUNT(DISTINCT p.prediction_id) AS total_predictions,
        AVG(p.response_time_ms) AS avg_response_time,
        COUNT(DISTINCT DATE(p.prediction_timestamp)) AS active_days
    FROM model_deployments d
    LEFT JOIN predictions p ON d.deployment_id = p.deployment_id
    WHERE d.deployed_at IS NOT NULL
    GROUP BY d.deployment_id
),
deployment_costs AS (
    SELECT
        ra.allocated_to_id AS deployment_id,
        SUM(ra.actual_cost) AS total_cost
    FROM resource_allocations ra
    WHERE ra.allocated_to_type = 'Deployment'
    GROUP BY ra.allocated_to_id
)
SELECT
    m.model_name,
    m.model_version,
    dm.deployment_name,
    dm.environment,
    dm.days_active,
    dm.active_days,
    ROUND(dm.active_days / NULLIF(dm.days_active, 0) * 100, 1) AS utilization_rate,
    dm.total_predictions,
    ROUND(dm.total_predictions / NULLIF(dm.days_active, 0), 0) AS predictions_per_day,
    ROUND(dm.avg_response_time, 2) AS avg_response_ms,
    dc.total_cost,
    ROUND(dc.total_cost / NULLIF(dm.total_predictions, 0), 4) AS cost_per_prediction,
    ROUND(dc.total_cost / NULLIF(dm.days_active, 0), 2) AS cost_per_day,
    CASE
        WHEN dm.total_predictions / NULLIF(dm.days_active, 0) < 100 THEN 'UNDERUTILIZED'
        WHEN dm.avg_response_time > 1000 THEN 'PERFORMANCE ISSUES'
        WHEN dc.total_cost / NULLIF(dm.total_predictions, 0) > 0.1 THEN 'HIGH COST'
        ELSE 'EFFICIENT'
    END AS efficiency_status
FROM deployment_metrics dm
INNER JOIN model_deployments d ON dm.deployment_id = d.deployment_id
INNER JOIN models m ON d.model_id = m.model_id
LEFT JOIN deployment_costs dc ON dm.deployment_id = dc.deployment_id
WHERE dm.total_predictions > 0
ORDER BY dm.total_predictions DESC;

-- ============================================================================
-- A/B Test Analytics
-- ============================================================================

-- A/B test results analysis
WITH ab_metrics AS (
    SELECT
        ab.ab_test_id,
        ab.test_name,
        -- Control metrics
        (SELECT COUNT(*) FROM predictions p
         WHERE p.deployment_id = ab.control_deployment_id
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS control_samples,
        (SELECT AVG(response_time_ms) FROM predictions p
         WHERE p.deployment_id = ab.control_deployment_id
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS control_latency,
        (SELECT COUNT(*) FROM predictions p
         INNER JOIN ground_truth gt ON p.prediction_id = gt.prediction_id
         WHERE p.deployment_id = ab.control_deployment_id
           AND JSON_EXTRACT(p.prediction_result, '$.class') = JSON_EXTRACT(gt.true_label, '$.class')
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS control_correct,
        -- Treatment metrics
        (SELECT COUNT(*) FROM predictions p
         WHERE p.deployment_id = ab.treatment_deployment_id
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS treatment_samples,
        (SELECT AVG(response_time_ms) FROM predictions p
         WHERE p.deployment_id = ab.treatment_deployment_id
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS treatment_latency,
        (SELECT COUNT(*) FROM predictions p
         INNER JOIN ground_truth gt ON p.prediction_id = gt.prediction_id
         WHERE p.deployment_id = ab.treatment_deployment_id
           AND JSON_EXTRACT(p.prediction_result, '$.class') = JSON_EXTRACT(gt.true_label, '$.class')
           AND p.prediction_timestamp BETWEEN ab.start_time AND COALESCE(ab.end_time, NOW())) AS treatment_correct
    FROM ab_tests ab
    WHERE ab.status IN ('Running', 'Completed')
)
SELECT
    am.test_name,
    p.project_name,
    ab.status,
    DATEDIFF(COALESCE(ab.end_time, NOW()), ab.start_time) AS test_duration_days,
    am.control_samples,
    am.treatment_samples,
    ROUND(am.control_correct / NULLIF(am.control_samples, 0) * 100, 2) AS control_accuracy,
    ROUND(am.treatment_correct / NULLIF(am.treatment_samples, 0) * 100, 2) AS treatment_accuracy,
    ROUND((am.treatment_correct / NULLIF(am.treatment_samples, 0) -
           am.control_correct / NULLIF(am.control_samples, 0)) * 100, 2) AS accuracy_lift,
    ROUND(am.control_latency, 2) AS control_latency_ms,
    ROUND(am.treatment_latency, 2) AS treatment_latency_ms,
    ROUND((am.control_latency - am.treatment_latency) / NULLIF(am.control_latency, 0) * 100, 2) AS latency_improvement,
    ab.significance_level,
    CASE
        WHEN am.control_samples >= ab.minimum_sample_size
             AND am.treatment_samples >= ab.minimum_sample_size THEN 'SUFFICIENT'
        ELSE CONCAT('NEED ', ab.minimum_sample_size - LEAST(am.control_samples, am.treatment_samples), ' MORE')
    END AS sample_status,
    CASE
        WHEN ab.winner_deployment_id = ab.control_deployment_id THEN 'CONTROL'
        WHEN ab.winner_deployment_id = ab.treatment_deployment_id THEN 'TREATMENT'
        ELSE 'UNDECIDED'
    END AS winner
FROM ab_metrics am
INNER JOIN ab_tests ab ON am.ab_test_id = ab.ab_test_id
INNER JOIN projects p ON ab.project_id = p.project_id
ORDER BY ab.start_time DESC;

-- ============================================================================
-- Resource Utilization Analytics
-- ============================================================================

-- Resource allocation and cost analysis
SELECT
    cr.resource_type,
    cr.provider,
    COUNT(DISTINCT cr.resource_id) AS resource_count,
    SUM(cr.total_capacity) AS total_capacity,
    SUM(cr.available_capacity) AS available_capacity,
    ROUND(AVG((cr.total_capacity - cr.available_capacity) / cr.total_capacity * 100), 1) AS avg_utilization_pct,
    COUNT(DISTINCT ra.allocation_id) AS active_allocations,
    SUM(ra.allocated_amount) AS total_allocated,
    SUM(ra.cost_estimate) AS estimated_cost,
    SUM(ra.actual_cost) AS actual_cost,
    ROUND(SUM(ra.actual_cost) / NULLIF(SUM(ra.cost_estimate), 0), 2) AS cost_accuracy_ratio,
    -- Allocation breakdown
    SUM(CASE WHEN ra.allocated_to_type = 'Training' THEN ra.allocated_amount ELSE 0 END) AS training_allocation,
    SUM(CASE WHEN ra.allocated_to_type = 'Deployment' THEN ra.allocated_amount ELSE 0 END) AS deployment_allocation,
    SUM(CASE WHEN ra.allocated_to_type = 'Pipeline' THEN ra.allocated_amount ELSE 0 END) AS pipeline_allocation,
    SUM(CASE WHEN ra.allocated_to_type = 'Experiment' THEN ra.allocated_amount ELSE 0 END) AS experiment_allocation
FROM compute_resources cr
LEFT JOIN resource_allocations ra ON cr.resource_id = ra.resource_id
    AND ra.allocation_end IS NULL
GROUP BY cr.resource_type, cr.provider
ORDER BY avg_utilization_pct DESC;