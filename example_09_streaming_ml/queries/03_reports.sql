-- ============================================================================
-- Streaming ML Platform Executive Reports
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Platform Executive Dashboard
-- ============================================================================

-- Platform-wide KPIs and metrics
SELECT
    -- Organization metrics
    COUNT(DISTINCT o.org_id) AS total_organizations,
    COUNT(DISTINCT CASE WHEN o.subscription_tier = 'Enterprise' THEN o.org_id END) AS enterprise_orgs,
    COUNT(DISTINCT p.project_id) AS total_projects,
    COUNT(DISTINCT CASE WHEN p.status = 'Active' THEN p.project_id END) AS active_projects,

    -- Model metrics
    COUNT(DISTINCT m.model_id) AS total_models,
    COUNT(DISTINCT CASE WHEN m.status = 'Deployed' THEN m.model_id END) AS deployed_models,
    AVG(CASE WHEN m.status = 'Deployed' THEN JSON_EXTRACT(m.metrics, '$.accuracy') END) AS avg_deployed_accuracy,

    -- Deployment metrics
    COUNT(DISTINCT md.deployment_id) AS total_deployments,
    COUNT(DISTINCT CASE WHEN md.status = 'Active' THEN md.deployment_id END) AS active_deployments,
    AVG(CASE WHEN md.health_status = 'Healthy' THEN 1 ELSE 0 END) * 100 AS deployment_health_pct,

    -- Stream metrics
    COUNT(DISTINCT ds.stream_id) AS total_streams,
    COUNT(DISTINCT CASE WHEN ds.is_active = TRUE THEN ds.stream_id END) AS active_streams,

    -- Prediction metrics (30 days)
    COUNT(DISTINCT pr.prediction_id) AS predictions_30d,
    AVG(pr.response_time_ms) AS avg_prediction_latency_ms,

    -- Resource metrics
    SUM(cr.total_capacity) AS total_compute_capacity,
    AVG((cr.total_capacity - cr.available_capacity) / cr.total_capacity * 100) AS resource_utilization_pct,

    -- Financial metrics (30 days)
    SUM(ra.actual_cost) AS total_cost_30d
FROM organizations o
LEFT JOIN projects p ON o.org_id = p.org_id
LEFT JOIN models m ON p.project_id = m.project_id
LEFT JOIN model_deployments md ON m.model_id = md.model_id
LEFT JOIN data_streams ds ON p.project_id = ds.project_id
LEFT JOIN predictions pr ON md.deployment_id = pr.deployment_id
    AND pr.prediction_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN compute_resources cr ON cr.status IN ('Available', 'In Use')
LEFT JOIN resource_allocations ra ON ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- Monthly Performance Report
-- ============================================================================

-- Monthly operational and performance metrics
WITH monthly_metrics AS (
    SELECT
        DATE_FORMAT(m.created_at, '%Y-%m') AS month,
        COUNT(DISTINCT m.model_id) AS models_created,
        COUNT(DISTINCT md.deployment_id) AS deployments_created,
        COUNT(DISTINCT e.experiment_id) AS experiments_run,
        AVG(JSON_EXTRACT(m.metrics, '$.accuracy')) AS avg_model_accuracy
    FROM models m
    LEFT JOIN model_deployments md ON m.model_id = md.model_id
        AND DATE_FORMAT(md.created_at, '%Y-%m') = DATE_FORMAT(m.created_at, '%Y-%m')
    LEFT JOIN experiments e ON m.project_id = e.project_id
        AND DATE_FORMAT(e.start_time, '%Y-%m') = DATE_FORMAT(m.created_at, '%Y-%m')
    WHERE m.created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(m.created_at, '%Y-%m')
),
monthly_predictions AS (
    SELECT
        DATE_FORMAT(p.prediction_timestamp, '%Y-%m') AS month,
        COUNT(*) AS prediction_count,
        AVG(p.response_time_ms) AS avg_latency,
        COUNT(DISTINCT p.deployment_id) AS active_deployments
    FROM predictions p
    WHERE p.prediction_timestamp >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(p.prediction_timestamp, '%Y-%m')
),
monthly_costs AS (
    SELECT
        DATE_FORMAT(ra.allocation_start, '%Y-%m') AS month,
        SUM(ra.actual_cost) AS total_cost,
        SUM(CASE WHEN ra.allocated_to_type = 'Training' THEN ra.actual_cost ELSE 0 END) AS training_cost,
        SUM(CASE WHEN ra.allocated_to_type = 'Deployment' THEN ra.actual_cost ELSE 0 END) AS deployment_cost
    FROM resource_allocations ra
    WHERE ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(ra.allocation_start, '%Y-%m')
)
SELECT
    mm.month,
    mm.models_created,
    mm.deployments_created,
    mm.experiments_run,
    ROUND(mm.avg_model_accuracy, 4) AS avg_accuracy,
    mp.prediction_count,
    mp.active_deployments,
    ROUND(mp.avg_latency, 2) AS avg_latency_ms,
    FORMAT(mc.total_cost, 2) AS total_cost,
    FORMAT(mc.training_cost, 2) AS training_cost,
    FORMAT(mc.deployment_cost, 2) AS deployment_cost,
    ROUND(mc.total_cost / NULLIF(mp.prediction_count, 0), 4) AS cost_per_prediction
FROM monthly_metrics mm
LEFT JOIN monthly_predictions mp ON mm.month = mp.month
LEFT JOIN monthly_costs mc ON mm.month = mc.month
ORDER BY mm.month DESC;

-- ============================================================================
-- Project Performance Report
-- ============================================================================

-- Comprehensive project performance summary
WITH project_metrics AS (
    SELECT
        p.project_id,
        COUNT(DISTINCT m.model_id) AS total_models,
        COUNT(DISTINCT CASE WHEN m.status = 'Deployed' THEN m.model_id END) AS deployed_models,
        AVG(JSON_EXTRACT(m.metrics, '$.accuracy')) AS avg_accuracy,
        MAX(JSON_EXTRACT(m.metrics, '$.accuracy')) AS best_accuracy,
        COUNT(DISTINCT e.experiment_id) AS experiments,
        COUNT(DISTINCT ds.stream_id) AS data_streams,
        COUNT(DISTINCT fd.feature_id) AS features
    FROM projects p
    LEFT JOIN models m ON p.project_id = m.project_id
    LEFT JOIN experiments e ON p.project_id = e.project_id
    LEFT JOIN data_streams ds ON p.project_id = ds.project_id
    LEFT JOIN feature_definitions fd ON p.project_id = fd.project_id
    GROUP BY p.project_id
),
project_activity AS (
    SELECT
        m.project_id,
        COUNT(DISTINCT pr.prediction_id) AS predictions_30d,
        AVG(pr.response_time_ms) AS avg_latency,
        COUNT(DISTINCT ma.alert_id) AS alerts_30d
    FROM models m
    INNER JOIN model_deployments md ON m.model_id = md.model_id
    LEFT JOIN predictions pr ON md.deployment_id = pr.deployment_id
        AND pr.prediction_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    LEFT JOIN model_alerts ma ON md.deployment_id = ma.deployment_id
        AND ma.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY m.project_id
),
project_costs AS (
    SELECT
        er.experiment_id,
        e.project_id,
        SUM(ra.actual_cost) AS experiment_cost
    FROM experiment_runs er
    INNER JOIN experiments e ON er.experiment_id = e.experiment_id
    LEFT JOIN resource_allocations ra ON ra.allocated_to_type = 'Experiment'
        AND ra.allocated_to_id = er.experiment_id
    GROUP BY e.project_id
)
SELECT
    o.org_name,
    p.project_name,
    p.project_type,
    p.status,
    DATEDIFF(NOW(), p.created_at) AS project_age_days,
    pm.total_models,
    pm.deployed_models,
    ROUND(pm.deployed_models / NULLIF(pm.total_models, 0) * 100, 1) AS deployment_rate,
    ROUND(pm.avg_accuracy, 4) AS avg_model_accuracy,
    ROUND(pm.best_accuracy, 4) AS best_model_accuracy,
    pm.experiments AS experiments_count,
    pm.data_streams AS streams_count,
    pm.features AS features_count,
    pa.predictions_30d,
    ROUND(pa.avg_latency, 2) AS avg_latency_ms,
    pa.alerts_30d,
    FORMAT(COALESCE(pc.experiment_cost, 0), 2) AS total_experiment_cost,
    RANK() OVER (ORDER BY pa.predictions_30d DESC) AS activity_rank,
    RANK() OVER (ORDER BY pm.best_accuracy DESC) AS performance_rank
FROM projects p
INNER JOIN organizations o ON p.org_id = o.org_id
LEFT JOIN project_metrics pm ON p.project_id = pm.project_id
LEFT JOIN project_activity pa ON p.project_id = pa.project_id
LEFT JOIN project_costs pc ON p.project_id = pc.project_id
WHERE p.status = 'Active'
ORDER BY pa.predictions_30d DESC;

-- ============================================================================
-- Model Performance Report
-- ============================================================================

-- Model lifecycle and performance report
WITH model_lifecycle AS (
    SELECT
        m.model_id,
        m.model_name,
        m.model_version,
        m.created_at AS created_date,
        MIN(md.deployed_at) AS first_deployed,
        MAX(md.retired_at) AS last_retired,
        COUNT(DISTINCT md.deployment_id) AS total_deployments,
        SUM(CASE WHEN md.status = 'Active' THEN 1 ELSE 0 END) AS active_deployments
    FROM models m
    LEFT JOIN model_deployments md ON m.model_id = md.model_id
    GROUP BY m.model_id
),
model_performance AS (
    SELECT
        md.model_id,
        COUNT(DISTINCT p.prediction_id) AS total_predictions,
        AVG(p.response_time_ms) AS avg_latency,
        COUNT(DISTINCT gt.ground_truth_id) AS labeled_predictions,
        SUM(CASE WHEN JSON_EXTRACT(p.prediction_result, '$.class') = JSON_EXTRACT(gt.true_label, '$.class')
            THEN 1 ELSE 0 END) AS correct_predictions
    FROM model_deployments md
    LEFT JOIN predictions p ON md.deployment_id = p.deployment_id
    LEFT JOIN ground_truth gt ON p.prediction_id = gt.prediction_id
    GROUP BY md.model_id
)
SELECT
    p.project_name,
    ml.model_name,
    ml.model_version,
    m.algorithm,
    m.framework,
    ml.created_date,
    ml.first_deployed,
    DATEDIFF(ml.first_deployed, ml.created_date) AS days_to_deployment,
    DATEDIFF(NOW(), ml.created_date) AS model_age_days,
    ml.total_deployments,
    ml.active_deployments,
    JSON_EXTRACT(m.metrics, '$.accuracy') AS training_accuracy,
    JSON_EXTRACT(m.metrics, '$.f1_score') AS training_f1,
    mp.total_predictions,
    ROUND(mp.avg_latency, 2) AS avg_latency_ms,
    mp.labeled_predictions,
    ROUND(mp.correct_predictions / NULLIF(mp.labeled_predictions, 0) * 100, 2) AS production_accuracy,
    m.model_size_bytes / 1048576 AS model_size_mb,
    m.status AS current_status,
    CASE
        WHEN ml.active_deployments > 0 THEN 'IN PRODUCTION'
        WHEN m.status = 'Archived' THEN 'ARCHIVED'
        WHEN mp.total_predictions = 0 THEN 'UNUSED'
        ELSE 'INACTIVE'
    END AS lifecycle_stage
FROM model_lifecycle ml
INNER JOIN models m ON ml.model_id = m.model_id
INNER JOIN projects p ON m.project_id = p.project_id
LEFT JOIN model_performance mp ON ml.model_id = mp.model_id
ORDER BY mp.total_predictions DESC;

-- ============================================================================
-- Data Quality Report
-- ============================================================================

-- Data quality metrics and violations summary
WITH quality_summary AS (
    SELECT
        dqr.applies_to_type,
        dqr.rule_type,
        COUNT(DISTINCT dqr.rule_id) AS total_rules,
        COUNT(DISTINCT dqv.violation_id) AS total_violations,
        SUM(dqv.affected_records) AS affected_records,
        SUM(CASE WHEN dqv.resolved = FALSE THEN 1 ELSE 0 END) AS unresolved_violations,
        AVG(CASE WHEN dqv.resolved = TRUE
            THEN TIMESTAMPDIFF(HOUR, dqv.violation_timestamp, dqv.resolved_at)
            ELSE NULL END) AS avg_resolution_hours
    FROM data_quality_rules dqr
    LEFT JOIN data_quality_violations dqv ON dqr.rule_id = dqv.rule_id
        AND dqv.violation_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    WHERE dqr.is_active = TRUE
    GROUP BY dqr.applies_to_type, dqr.rule_type
)
SELECT
    applies_to_type,
    rule_type,
    total_rules,
    total_violations,
    affected_records,
    unresolved_violations,
    ROUND(total_violations / NULLIF(total_rules, 0) / 30, 2) AS violations_per_rule_per_day,
    ROUND(avg_resolution_hours, 1) AS avg_resolution_hours,
    CASE
        WHEN unresolved_violations > 10 THEN 'CRITICAL - Many unresolved issues'
        WHEN total_violations / NULLIF(total_rules, 0) > 5 THEN 'WARNING - High violation rate'
        WHEN total_violations > 0 THEN 'MONITOR - Some violations detected'
        ELSE 'HEALTHY - No recent violations'
    END AS quality_status
FROM quality_summary
ORDER BY unresolved_violations DESC, total_violations DESC;

-- ============================================================================
-- Cost Analysis Report
-- ============================================================================

-- Detailed cost breakdown and analysis
WITH cost_breakdown AS (
    SELECT
        ra.allocated_to_type AS resource_usage_type,
        cr.resource_type,
        cr.provider,
        COUNT(DISTINCT ra.allocation_id) AS allocation_count,
        SUM(ra.allocated_amount) AS total_allocated,
        SUM(ra.cost_estimate) AS estimated_cost,
        SUM(ra.actual_cost) AS actual_cost,
        AVG(TIMESTAMPDIFF(HOUR, ra.allocation_start, COALESCE(ra.allocation_end, NOW()))) AS avg_duration_hours
    FROM resource_allocations ra
    INNER JOIN compute_resources cr ON ra.resource_id = cr.resource_id
    WHERE ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY ra.allocated_to_type, cr.resource_type, cr.provider
),
project_costs AS (
    SELECT
        p.project_name,
        SUM(CASE WHEN ra.allocated_to_type = 'Training' THEN ra.actual_cost ELSE 0 END) AS training_cost,
        SUM(CASE WHEN ra.allocated_to_type = 'Deployment' THEN ra.actual_cost ELSE 0 END) AS deployment_cost,
        SUM(CASE WHEN ra.allocated_to_type = 'Experiment' THEN ra.actual_cost ELSE 0 END) AS experiment_cost,
        SUM(ra.actual_cost) AS total_cost
    FROM projects p
    LEFT JOIN models m ON p.project_id = m.project_id
    LEFT JOIN model_deployments md ON m.model_id = md.model_id
    LEFT JOIN resource_allocations ra ON
        (ra.allocated_to_type = 'Deployment' AND ra.allocated_to_id = md.deployment_id) OR
        (ra.allocated_to_type = 'Training' AND ra.allocated_to_id = m.model_id)
    WHERE ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY p.project_id
)
SELECT
    'Cost by Type' AS report_section,
    cb.resource_usage_type AS category,
    cb.resource_type AS subcategory,
    cb.provider,
    cb.allocation_count AS transactions,
    FORMAT(cb.estimated_cost, 2) AS estimated_cost,
    FORMAT(cb.actual_cost, 2) AS actual_cost,
    ROUND((cb.actual_cost - cb.estimated_cost) / NULLIF(cb.estimated_cost, 0) * 100, 1) AS variance_pct,
    ROUND(cb.avg_duration_hours, 1) AS avg_duration_hours,
    FORMAT(cb.actual_cost / NULLIF(cb.avg_duration_hours, 0), 2) AS cost_per_hour
FROM cost_breakdown cb

UNION ALL

SELECT
    'Cost by Project' AS report_section,
    project_name AS category,
    'All Resources' AS subcategory,
    'Mixed' AS provider,
    NULL AS transactions,
    NULL AS estimated_cost,
    FORMAT(total_cost, 2) AS actual_cost,
    NULL AS variance_pct,
    NULL AS avg_duration_hours,
    FORMAT(total_cost / 30, 2) AS cost_per_day
FROM project_costs
WHERE total_cost > 0
ORDER BY report_section, actual_cost DESC;

-- ============================================================================
-- API Usage Report
-- ============================================================================

-- API usage patterns and statistics
WITH api_summary AS (
    SELECT
        o.org_name,
        o.subscription_tier,
        COUNT(*) AS total_requests,
        COUNT(DISTINCT DATE(au.request_timestamp)) AS active_days,
        COUNT(DISTINCT au.endpoint) AS unique_endpoints,
        AVG(au.response_time_ms) AS avg_response_time,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY au.response_time_ms) AS p95_response_time,
        SUM(CASE WHEN au.response_status < 400 THEN 1 ELSE 0 END) AS successful_requests,
        SUM(CASE WHEN au.response_status >= 400 THEN 1 ELSE 0 END) AS failed_requests,
        SUM(au.request_size_bytes) / 1048576 AS total_request_mb,
        SUM(au.response_size_bytes) / 1048576 AS total_response_mb
    FROM organizations o
    LEFT JOIN api_usage au ON o.org_id = au.org_id
        AND au.request_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY o.org_id
),
endpoint_stats AS (
    SELECT
        endpoint,
        method,
        COUNT(*) AS request_count,
        AVG(response_time_ms) AS avg_response_time,
        SUM(CASE WHEN response_status >= 400 THEN 1 ELSE 0 END) AS error_count
    FROM api_usage
    WHERE request_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY endpoint, method
)
SELECT
    'Organization Summary' AS report_type,
    org_name AS entity,
    subscription_tier AS tier,
    total_requests AS requests_30d,
    ROUND(total_requests / NULLIF(active_days, 0), 0) AS avg_daily_requests,
    unique_endpoints AS endpoints_used,
    ROUND(avg_response_time, 1) AS avg_response_ms,
    ROUND(p95_response_time, 1) AS p95_response_ms,
    ROUND(successful_requests / NULLIF(total_requests, 0) * 100, 2) AS success_rate,
    ROUND(total_request_mb + total_response_mb, 2) AS total_bandwidth_mb
FROM api_summary
WHERE total_requests > 0

UNION ALL

SELECT
    'Top Endpoints' AS report_type,
    CONCAT(method, ' ', endpoint) AS entity,
    NULL AS tier,
    request_count AS requests_30d,
    ROUND(request_count / 30, 0) AS avg_daily_requests,
    error_count AS endpoints_used,
    ROUND(avg_response_time, 1) AS avg_response_ms,
    NULL AS p95_response_ms,
    ROUND((request_count - error_count) / NULLIF(request_count, 0) * 100, 2) AS success_rate,
    NULL AS total_bandwidth_mb
FROM endpoint_stats
ORDER BY report_type, requests_30d DESC
LIMIT 20;

-- ============================================================================
-- Compliance and Governance Report
-- ============================================================================

-- Model governance and compliance metrics
SELECT
    'Model Governance' AS compliance_area,
    COUNT(DISTINCT m.model_id) AS total_items,
    SUM(CASE WHEN m.status IN ('Validated', 'Deployed') THEN 1 ELSE 0 END) AS compliant_items,
    ROUND(AVG(CASE WHEN m.status IN ('Validated', 'Deployed') THEN 1 ELSE 0 END) * 100, 1) AS compliance_rate,
    SUM(CASE WHEN JSON_EXTRACT(m.metrics, '$.accuracy') < 0.7 THEN 1 ELSE 0 END) AS below_threshold,
    'Models below 70% accuracy threshold' AS notes
FROM models m
WHERE m.created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)

UNION ALL

SELECT
    'Data Quality' AS compliance_area,
    COUNT(DISTINCT dqr.rule_id) AS total_items,
    COUNT(DISTINCT dqr.rule_id) - COUNT(DISTINCT dqv.rule_id) AS compliant_items,
    ROUND((COUNT(DISTINCT dqr.rule_id) - COUNT(DISTINCT dqv.rule_id)) /
          NULLIF(COUNT(DISTINCT dqr.rule_id), 0) * 100, 1) AS compliance_rate,
    COUNT(DISTINCT dqv.violation_id) AS below_threshold,
    'Active rules without violations' AS notes
FROM data_quality_rules dqr
LEFT JOIN data_quality_violations dqv ON dqr.rule_id = dqv.rule_id
    AND dqv.violation_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND dqv.resolved = FALSE
WHERE dqr.is_active = TRUE

UNION ALL

SELECT
    'Drift Monitoring' AS compliance_area,
    COUNT(DISTINCT md.deployment_id) AS total_items,
    COUNT(DISTINCT md.deployment_id) - COUNT(DISTINCT dd.deployment_id) AS compliant_items,
    ROUND((COUNT(DISTINCT md.deployment_id) - COUNT(DISTINCT dd.deployment_id)) /
          NULLIF(COUNT(DISTINCT md.deployment_id), 0) * 100, 1) AS compliance_rate,
    COUNT(DISTINCT dd.deployment_id) AS below_threshold,
    'Active deployments without significant drift' AS notes
FROM model_deployments md
LEFT JOIN drift_detection dd ON md.deployment_id = dd.deployment_id
    AND dd.detected_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    AND dd.is_significant = TRUE
WHERE md.status = 'Active'

UNION ALL

SELECT
    'Alert Response' AS compliance_area,
    COUNT(DISTINCT ma.alert_id) AS total_items,
    COUNT(DISTINCT CASE WHEN ma.resolved_at IS NOT NULL THEN ma.alert_id END) AS compliant_items,
    ROUND(AVG(CASE WHEN ma.resolved_at IS NOT NULL THEN 1 ELSE 0 END) * 100, 1) AS compliance_rate,
    COUNT(DISTINCT CASE WHEN ma.severity = 'Critical' AND ma.resolved_at IS NULL THEN ma.alert_id END) AS below_threshold,
    'Unresolved critical alerts' AS notes
FROM model_alerts ma
WHERE ma.triggered_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY);

-- ============================================================================
-- User Activity Report
-- ============================================================================

-- User activity summary
SELECT
    ua.activity_type,
    COUNT(DISTINCT ua.user_id) AS unique_users,
    COUNT(*) AS total_activities,
    COUNT(DISTINCT DATE(ua.activity_timestamp)) AS active_days,
    COUNT(DISTINCT ua.org_id) AS organizations_involved,
    MAX(ua.activity_timestamp) AS last_activity,
    CASE
        WHEN ua.activity_type = 'Model Training' THEN
            (SELECT COUNT(DISTINCT model_id) FROM models WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY))
        WHEN ua.activity_type = 'Model Deployment' THEN
            (SELECT COUNT(DISTINCT deployment_id) FROM model_deployments WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY))
        ELSE NULL
    END AS related_objects_created
FROM user_activity ua
WHERE ua.activity_timestamp >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY ua.activity_type
ORDER BY total_activities DESC;