-- ============================================================================
-- Streaming ML Platform Advanced Analytics & Predictions
-- ============================================================================

USE streaming_ml;

-- ============================================================================
-- Anomaly Detection in Model Performance
-- ============================================================================

-- Detect anomalous model behavior using statistical methods
WITH performance_baseline AS (
    SELECT
        deployment_id,
        AVG(accuracy) AS mean_accuracy,
        STD(accuracy) AS std_accuracy,
        AVG(f1_score) AS mean_f1,
        STD(f1_score) AS std_f1,
        AVG(avg_response_time_ms) AS mean_latency,
        STD(avg_response_time_ms) AS std_latency,
        COUNT(*) AS sample_count
    FROM performance_metrics
    WHERE metric_window_end >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
      AND metric_window_end < DATE_SUB(CURDATE(), INTERVAL 1 DAY)
    GROUP BY deployment_id
    HAVING sample_count >= 7
),
recent_performance AS (
    SELECT
        pm.deployment_id,
        pm.accuracy,
        pm.f1_score,
        pm.avg_response_time_ms,
        pm.prediction_count,
        pm.metric_window_end
    FROM performance_metrics pm
    WHERE pm.metric_window_end >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
)
SELECT
    d.deployment_name,
    m.model_name,
    m.model_version,
    rp.metric_window_end AS measurement_date,
    rp.accuracy AS current_accuracy,
    pb.mean_accuracy AS baseline_accuracy,
    ROUND((rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0), 2) AS accuracy_z_score,
    rp.f1_score AS current_f1,
    pb.mean_f1 AS baseline_f1,
    ROUND((rp.f1_score - pb.mean_f1) / NULLIF(pb.std_f1, 0), 2) AS f1_z_score,
    rp.avg_response_time_ms AS current_latency,
    pb.mean_latency AS baseline_latency,
    ROUND((rp.avg_response_time_ms - pb.mean_latency) / NULLIF(pb.std_latency, 0), 2) AS latency_z_score,
    CASE
        WHEN ABS((rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0)) > 3 THEN 'CRITICAL - Accuracy anomaly'
        WHEN ABS((rp.f1_score - pb.mean_f1) / NULLIF(pb.std_f1, 0)) > 3 THEN 'CRITICAL - F1 score anomaly'
        WHEN (rp.avg_response_time_ms - pb.mean_latency) / NULLIF(pb.std_latency, 0) > 3 THEN 'WARNING - Latency spike'
        WHEN ABS((rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0)) > 2 THEN 'MONITOR - Unusual performance'
        ELSE 'NORMAL'
    END AS anomaly_status,
    -- Recommended actions
    CASE
        WHEN (rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0) < -3 THEN
            'Investigate data drift, retrain model, or rollback deployment'
        WHEN (rp.avg_response_time_ms - pb.mean_latency) / NULLIF(pb.std_latency, 0) > 3 THEN
            'Check resource allocation, optimize model, or scale infrastructure'
        ELSE 'Continue monitoring'
    END AS recommended_action
FROM recent_performance rp
INNER JOIN performance_baseline pb ON rp.deployment_id = pb.deployment_id
INNER JOIN model_deployments d ON rp.deployment_id = d.deployment_id
INNER JOIN models m ON d.model_id = m.model_id
WHERE d.status = 'Active'
  AND (ABS((rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0)) > 2
       OR ABS((rp.f1_score - pb.mean_f1) / NULLIF(pb.std_f1, 0)) > 2
       OR (rp.avg_response_time_ms - pb.mean_latency) / NULLIF(pb.std_latency, 0) > 2)
ORDER BY
    GREATEST(
        ABS((rp.accuracy - pb.mean_accuracy) / NULLIF(pb.std_accuracy, 0)),
        ABS((rp.f1_score - pb.mean_f1) / NULLIF(pb.std_f1, 0)),
        (rp.avg_response_time_ms - pb.mean_latency) / NULLIF(pb.std_latency, 0)
    ) DESC;

-- ============================================================================
-- Feature Importance Evolution
-- ============================================================================

-- Track how feature importance changes across model versions
WITH feature_importance_history AS (
    SELECT
        m.project_id,
        m.model_name,
        m.model_version,
        m.created_at,
        fd.feature_name,
        JSON_EXTRACT(me.feature_importance, CONCAT('$."', fd.feature_name, '"')) AS importance_score,
        ROW_NUMBER() OVER (PARTITION BY m.model_name, fd.feature_name ORDER BY m.created_at) AS version_rank
    FROM models m
    INNER JOIN model_evaluations me ON m.model_id = me.model_id
    INNER JOIN feature_sets fs ON m.feature_set_id = fs.feature_set_id
    INNER JOIN feature_definitions fd ON JSON_CONTAINS(fs.feature_ids, CAST(fd.feature_id AS JSON))
    WHERE me.feature_importance IS NOT NULL
      AND m.status IN ('Validated', 'Deployed')
),
feature_trends AS (
    SELECT
        project_id,
        model_name,
        feature_name,
        MIN(importance_score) AS min_importance,
        AVG(importance_score) AS avg_importance,
        MAX(importance_score) AS max_importance,
        STD(importance_score) AS importance_variance,
        FIRST_VALUE(importance_score) OVER (
            PARTITION BY model_name, feature_name
            ORDER BY version_rank
        ) AS initial_importance,
        LAST_VALUE(importance_score) OVER (
            PARTITION BY model_name, feature_name
            ORDER BY version_rank
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS latest_importance,
        COUNT(*) OVER (PARTITION BY model_name, feature_name) AS version_count
    FROM feature_importance_history
)
SELECT
    p.project_name,
    ft.model_name,
    ft.feature_name,
    ft.version_count AS versions_analyzed,
    ROUND(ft.initial_importance, 4) AS initial_importance,
    ROUND(ft.latest_importance, 4) AS latest_importance,
    ROUND(ft.latest_importance - ft.initial_importance, 4) AS importance_change,
    ROUND((ft.latest_importance - ft.initial_importance) / NULLIF(ft.initial_importance, 0) * 100, 2) AS change_percentage,
    ROUND(ft.avg_importance, 4) AS avg_importance,
    ROUND(ft.importance_variance, 4) AS stability_score,
    CASE
        WHEN ft.latest_importance > ft.avg_importance * 1.5 THEN 'INCREASING - Feature becoming more important'
        WHEN ft.latest_importance < ft.avg_importance * 0.5 THEN 'DECREASING - Feature becoming less important'
        WHEN ft.importance_variance > 0.1 THEN 'VOLATILE - Unstable importance'
        ELSE 'STABLE'
    END AS trend_analysis,
    CASE
        WHEN ft.latest_importance < 0.01 AND ft.version_count > 3 THEN 'Consider removing - consistently low importance'
        WHEN ft.importance_variance > 0.2 THEN 'Investigate - high variance in importance'
        WHEN ft.latest_importance > 0.3 THEN 'Critical feature - ensure quality'
        ELSE 'Monitor'
    END AS recommendation
FROM feature_trends ft
INNER JOIN projects p ON ft.project_id = p.project_id
WHERE ft.version_count >= 2
ORDER BY ABS(ft.latest_importance - ft.initial_importance) DESC;

-- ============================================================================
-- Predictive Model Retraining Needs
-- ============================================================================

-- Predict when models will need retraining based on degradation patterns
WITH degradation_analysis AS (
    SELECT
        d.deployment_id,
        d.model_id,
        d.deployed_at,
        DATEDIFF(NOW(), d.deployed_at) AS days_deployed,
        -- Performance metrics over time
        MIN(pm.accuracy) AS min_accuracy,
        MAX(pm.accuracy) AS max_accuracy,
        AVG(pm.accuracy) AS avg_accuracy,
        -- Linear regression coefficients (simplified)
        (COUNT(*) * SUM(DATEDIFF(pm.metric_window_end, d.deployed_at) * pm.accuracy) -
         SUM(DATEDIFF(pm.metric_window_end, d.deployed_at)) * SUM(pm.accuracy)) /
        (COUNT(*) * SUM(POWER(DATEDIFF(pm.metric_window_end, d.deployed_at), 2)) -
         POWER(SUM(DATEDIFF(pm.metric_window_end, d.deployed_at)), 2)) AS degradation_rate,
        COUNT(DISTINCT dd.drift_id) AS drift_events,
        MAX(dd.drift_score) AS max_drift_score
    FROM model_deployments d
    LEFT JOIN performance_metrics pm ON d.deployment_id = pm.deployment_id
    LEFT JOIN drift_detection dd ON d.deployment_id = dd.deployment_id
        AND dd.is_significant = TRUE
    WHERE d.status = 'Active'
      AND pm.metric_window_end >= d.deployed_at
    GROUP BY d.deployment_id
    HAVING COUNT(pm.metric_id) >= 7  -- At least a week of data
)
SELECT
    m.model_name,
    m.model_version,
    d.deployment_name,
    d.environment,
    da.days_deployed,
    ROUND(da.avg_accuracy, 4) AS current_avg_accuracy,
    ROUND(da.degradation_rate * 1000, 4) AS daily_accuracy_loss,
    da.drift_events,
    ROUND(da.max_drift_score, 3) AS max_drift_score,
    -- Predict days until accuracy drops below threshold (0.7)
    CASE
        WHEN da.degradation_rate >= 0 THEN NULL  -- Model improving
        WHEN da.avg_accuracy - (ABS(da.degradation_rate) * 30) < 0.7 THEN
            ROUND((da.avg_accuracy - 0.7) / ABS(da.degradation_rate), 0)
        ELSE NULL
    END AS days_until_threshold,
    -- Retraining urgency score (0-100)
    LEAST(100,
        (CASE WHEN da.avg_accuracy < 0.75 THEN 40 ELSE 0 END) +
        (CASE WHEN da.degradation_rate < -0.001 THEN 30 ELSE 0 END) +
        (CASE WHEN da.drift_events > 5 THEN 20 ELSE da.drift_events * 4 END) +
        (CASE WHEN da.max_drift_score > 0.5 THEN 20 ELSE da.max_drift_score * 40 END) +
        (CASE WHEN da.days_deployed > 90 THEN 10 ELSE 0 END)
    ) AS retraining_urgency_score,
    CASE
        WHEN da.avg_accuracy < 0.7 THEN 'IMMEDIATE - Below threshold'
        WHEN da.avg_accuracy - (ABS(da.degradation_rate) * 7) < 0.7 THEN 'URGENT - Will fail within a week'
        WHEN da.avg_accuracy - (ABS(da.degradation_rate) * 30) < 0.7 THEN 'PLANNED - Schedule within month'
        WHEN da.drift_events > 10 THEN 'RECOMMENDED - Significant drift detected'
        ELSE 'MONITOR - Stable performance'
    END AS retraining_recommendation
FROM degradation_analysis da
INNER JOIN model_deployments d ON da.deployment_id = d.deployment_id
INNER JOIN models m ON da.model_id = m.model_id
ORDER BY retraining_urgency_score DESC;

-- ============================================================================
-- Optimal Hyperparameter Discovery
-- ============================================================================

-- Analyze hyperparameter combinations for optimal performance
WITH hyperparameter_results AS (
    SELECT
        e.experiment_id,
        e.experiment_name,
        er.run_id,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.learning_rate')) AS learning_rate,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.batch_size')) AS batch_size,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.epochs')) AS epochs,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.optimizer')) AS optimizer,
        JSON_UNQUOTE(JSON_EXTRACT(er.parameters, '$.dropout_rate')) AS dropout_rate,
        JSON_EXTRACT(er.metrics, '$.accuracy') AS accuracy,
        JSON_EXTRACT(er.metrics, '$.f1_score') AS f1_score,
        JSON_EXTRACT(er.metrics, '$.loss') AS loss,
        er.duration_seconds / 60 AS training_minutes
    FROM experiments e
    INNER JOIN experiment_runs er ON e.experiment_id = er.experiment_id
    WHERE er.status = 'Completed'
      AND e.status = 'Completed'
      AND er.metrics IS NOT NULL
),
pareto_frontier AS (
    SELECT
        h1.*,
        -- Check if this point is on the Pareto frontier (not dominated by any other point)
        CASE
            WHEN NOT EXISTS (
                SELECT 1 FROM hyperparameter_results h2
                WHERE h2.experiment_id = h1.experiment_id
                  AND h2.accuracy > h1.accuracy
                  AND h2.training_minutes < h1.training_minutes
            ) THEN TRUE
            ELSE FALSE
        END AS is_pareto_optimal
    FROM hyperparameter_results h1
)
SELECT
    p.project_name,
    pf.experiment_name,
    pf.learning_rate,
    pf.batch_size,
    pf.epochs,
    pf.optimizer,
    pf.dropout_rate,
    ROUND(pf.accuracy, 4) AS accuracy,
    ROUND(pf.f1_score, 4) AS f1_score,
    ROUND(pf.loss, 4) AS loss,
    ROUND(pf.training_minutes, 1) AS training_minutes,
    pf.is_pareto_optimal,
    -- Efficiency score (accuracy per minute of training)
    ROUND(pf.accuracy / NULLIF(pf.training_minutes, 0), 4) AS efficiency_score,
    RANK() OVER (PARTITION BY pf.experiment_id ORDER BY pf.accuracy DESC) AS accuracy_rank,
    RANK() OVER (PARTITION BY pf.experiment_id ORDER BY pf.training_minutes) AS speed_rank,
    CASE
        WHEN pf.is_pareto_optimal AND pf.accuracy = MAX(pf.accuracy) OVER (PARTITION BY pf.experiment_id) THEN
            'BEST ACCURACY - Optimal for maximum performance'
        WHEN pf.is_pareto_optimal AND pf.training_minutes = MIN(pf.training_minutes) OVER (PARTITION BY pf.experiment_id) THEN
            'FASTEST - Optimal for quick training'
        WHEN pf.is_pareto_optimal THEN
            'BALANCED - Good trade-off between speed and accuracy'
        ELSE 'SUBOPTIMAL'
    END AS recommendation
FROM pareto_frontier pf
INNER JOIN experiments e ON pf.experiment_id = e.experiment_id
INNER JOIN projects p ON e.project_id = p.project_id
WHERE pf.accuracy > 0.7  -- Minimum acceptable accuracy
ORDER BY pf.is_pareto_optimal DESC, pf.accuracy DESC;

-- ============================================================================
-- Stream Processing Optimization
-- ============================================================================

-- Identify optimal batch sizes and processing windows for streams
WITH stream_performance AS (
    SELECT
        s.stream_id,
        s.stream_name,
        s.batch_size,
        s.buffer_time_ms,
        sp.window_type,
        sp.window_size_seconds,
        DATE(se.event_timestamp) AS process_date,
        COUNT(se.event_id) AS events_processed,
        SUM(CASE WHEN se.processing_status = 'Failed' THEN 1 ELSE 0 END) AS failed_events,
        AVG(TIMESTAMPDIFF(MICROSECOND, se.event_timestamp, se.created_at) / 1000) AS avg_latency_ms,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY
            TIMESTAMPDIFF(MICROSECOND, se.event_timestamp, se.created_at) / 1000
        ) AS p95_latency_ms
    FROM data_streams s
    INNER JOIN stream_pipelines sp ON s.stream_id = sp.stream_id
    LEFT JOIN stream_events se ON s.stream_id = se.stream_id
        AND se.event_timestamp >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    WHERE s.is_active = TRUE
    GROUP BY s.stream_id, sp.pipeline_id, DATE(se.event_timestamp)
),
optimal_config AS (
    SELECT
        stream_id,
        stream_name,
        batch_size,
        buffer_time_ms,
        window_type,
        window_size_seconds,
        AVG(events_processed) AS avg_daily_events,
        AVG(failed_events / NULLIF(events_processed, 0)) AS avg_failure_rate,
        AVG(avg_latency_ms) AS overall_avg_latency,
        AVG(p95_latency_ms) AS overall_p95_latency,
        -- Calculate efficiency score
        (1000 / (1 + AVG(p95_latency_ms))) * (1 - AVG(failed_events / NULLIF(events_processed, 0))) AS efficiency_score
    FROM stream_performance
    GROUP BY stream_id, batch_size, buffer_time_ms, window_type, window_size_seconds
)
SELECT
    oc.stream_name,
    oc.batch_size AS current_batch_size,
    oc.buffer_time_ms AS current_buffer_ms,
    oc.window_type,
    oc.window_size_seconds,
    ROUND(oc.avg_daily_events, 0) AS avg_daily_events,
    ROUND(oc.avg_failure_rate * 100, 2) AS failure_rate_pct,
    ROUND(oc.overall_avg_latency, 2) AS avg_latency_ms,
    ROUND(oc.overall_p95_latency, 2) AS p95_latency_ms,
    ROUND(oc.efficiency_score, 2) AS efficiency_score,
    -- Optimization recommendations
    CASE
        WHEN oc.avg_daily_events > 100000 AND oc.batch_size < 1000 THEN
            CONCAT('Increase batch size to ', LEAST(5000, oc.batch_size * 5))
        WHEN oc.avg_daily_events < 1000 AND oc.batch_size > 100 THEN
            CONCAT('Decrease batch size to ', GREATEST(10, oc.batch_size / 2))
        ELSE 'Current batch size optimal'
    END AS batch_size_recommendation,
    CASE
        WHEN oc.overall_p95_latency > 5000 AND oc.buffer_time_ms > 500 THEN
            'Reduce buffer time for lower latency'
        WHEN oc.avg_failure_rate > 0.05 AND oc.buffer_time_ms < 1000 THEN
            'Increase buffer time for better reliability'
        ELSE 'Buffer time acceptable'
    END AS buffer_recommendation,
    RANK() OVER (ORDER BY oc.efficiency_score DESC) AS efficiency_rank
FROM optimal_config oc
ORDER BY oc.efficiency_score DESC;

-- ============================================================================
-- Cost Prediction and Optimization
-- ============================================================================

-- Predict future costs based on usage patterns
WITH cost_history AS (
    SELECT
        DATE_FORMAT(ra.allocation_start, '%Y-%m') AS month,
        ra.allocated_to_type,
        SUM(ra.actual_cost) AS monthly_cost,
        COUNT(DISTINCT ra.allocation_id) AS allocation_count,
        AVG(ra.allocated_amount) AS avg_allocation_size
    FROM resource_allocations ra
    WHERE ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(ra.allocation_start, '%Y-%m'), ra.allocated_to_type
),
cost_trends AS (
    SELECT
        allocated_to_type,
        AVG(monthly_cost) AS avg_monthly_cost,
        STD(monthly_cost) AS cost_variance,
        -- Linear regression for trend (simplified)
        (COUNT(*) * SUM(PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')),
                                    EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 12 MONTH))) * monthly_cost) -
         SUM(PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')),
                        EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 12 MONTH)))) * SUM(monthly_cost)) /
        NULLIF((COUNT(*) * SUM(POWER(PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')),
                                                 EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 12 MONTH))), 2)) -
         POWER(SUM(PERIOD_DIFF(EXTRACT(YEAR_MONTH FROM STR_TO_DATE(CONCAT(month, '-01'), '%Y-%m-%d')),
                               EXTRACT(YEAR_MONTH FROM DATE_SUB(CURDATE(), INTERVAL 12 MONTH)))), 2)), 0) AS monthly_growth_rate
    FROM cost_history
    GROUP BY allocated_to_type
),
resource_efficiency AS (
    SELECT
        cr.resource_type,
        AVG((cr.total_capacity - cr.available_capacity) / cr.total_capacity) AS avg_utilization,
        SUM(ra.actual_cost) / SUM(ra.allocated_amount) AS cost_per_unit
    FROM compute_resources cr
    LEFT JOIN resource_allocations ra ON cr.resource_id = ra.resource_id
        AND ra.allocation_start >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY cr.resource_type
)
SELECT
    'Cost Forecast' AS analysis_type,
    ct.allocated_to_type AS category,
    ROUND(ct.avg_monthly_cost, 2) AS avg_monthly_cost,
    ROUND(ct.monthly_growth_rate, 2) AS monthly_growth,
    ROUND(ct.avg_monthly_cost + (ct.monthly_growth_rate * 1), 2) AS next_month_forecast,
    ROUND(ct.avg_monthly_cost + (ct.monthly_growth_rate * 3), 2) AS three_month_forecast,
    ROUND(ct.avg_monthly_cost + (ct.monthly_growth_rate * 12), 2) AS annual_forecast,
    CASE
        WHEN ct.monthly_growth_rate > ct.avg_monthly_cost * 0.1 THEN 'HIGH GROWTH - Review resource usage'
        WHEN ct.monthly_growth_rate > ct.avg_monthly_cost * 0.05 THEN 'MODERATE GROWTH - Monitor closely'
        ELSE 'STABLE'
    END AS trend_alert
FROM cost_trends ct

UNION ALL

SELECT
    'Resource Efficiency' AS analysis_type,
    re.resource_type AS category,
    ROUND(re.avg_utilization * 100, 1) AS avg_utilization_pct,
    NULL AS monthly_growth,
    ROUND(re.cost_per_unit, 4) AS cost_per_unit,
    NULL AS three_month_forecast,
    NULL AS annual_forecast,
    CASE
        WHEN re.avg_utilization < 0.3 THEN 'UNDERUTILIZED - Consider reducing capacity'
        WHEN re.avg_utilization > 0.9 THEN 'NEAR CAPACITY - Consider scaling up'
        ELSE 'OPTIMAL'
    END AS efficiency_status
FROM resource_efficiency re
ORDER BY analysis_type, category;

-- ============================================================================
-- Model Deployment Strategy Optimization
-- ============================================================================

-- Recommend optimal deployment strategies based on performance and cost
WITH deployment_analysis AS (
    SELECT
        m.model_id,
        m.model_name,
        m.model_version,
        JSON_EXTRACT(m.metrics, '$.accuracy') AS model_accuracy,
        m.model_size_bytes / 1048576 AS model_size_mb,
        COUNT(DISTINCT md.deployment_id) AS deployment_count,
        AVG(pm.avg_response_time_ms) AS avg_latency,
        SUM(pm.prediction_count) AS total_predictions,
        SUM(ra.actual_cost) AS deployment_cost
    FROM models m
    LEFT JOIN model_deployments md ON m.model_id = md.model_id
    LEFT JOIN performance_metrics pm ON md.deployment_id = pm.deployment_id
    LEFT JOIN resource_allocations ra ON ra.allocated_to_type = 'Deployment'
        AND ra.allocated_to_id = md.deployment_id
    WHERE m.status IN ('Validated', 'Staged', 'Deployed')
    GROUP BY m.model_id
)
SELECT
    p.project_name,
    da.model_name,
    da.model_version,
    ROUND(da.model_accuracy, 4) AS accuracy,
    ROUND(da.model_size_mb, 2) AS size_mb,
    da.deployment_count AS current_deployments,
    da.total_predictions AS total_predictions_served,
    ROUND(da.avg_latency, 2) AS avg_latency_ms,
    FORMAT(da.deployment_cost, 2) AS total_deployment_cost,
    ROUND(da.deployment_cost / NULLIF(da.total_predictions, 0), 6) AS cost_per_prediction,
    -- Deployment strategy recommendation
    CASE
        WHEN da.total_predictions > 1000000 AND da.avg_latency < 100 THEN 'HIGH VOLUME - Use caching and CDN'
        WHEN da.model_size_mb > 500 THEN 'LARGE MODEL - Consider model compression or edge deployment'
        WHEN da.avg_latency > 500 THEN 'HIGH LATENCY - Optimize model or upgrade infrastructure'
        WHEN da.deployment_cost / NULLIF(da.total_predictions, 0) > 0.01 THEN 'HIGH COST - Consider batch processing'
        WHEN da.deployment_count = 0 THEN 'NOT DEPLOYED - Ready for production'
        ELSE 'STANDARD - Current strategy acceptable'
    END AS deployment_strategy,
    -- Scaling recommendation
    CASE
        WHEN da.total_predictions / NULLIF(da.deployment_count, 0) > 100000 THEN 'SCALE OUT - Add more instances'
        WHEN da.avg_latency > 200 AND da.model_size_mb < 100 THEN 'SCALE UP - Use more powerful instances'
        WHEN da.deployment_count > 5 AND da.total_predictions < 10000 THEN 'SCALE DOWN - Reduce deployments'
        ELSE 'MAINTAIN - Current scaling appropriate'
    END AS scaling_recommendation,
    -- Estimated optimal deployment count
    GREATEST(1, ROUND(da.total_predictions / 50000)) AS recommended_instances
FROM deployment_analysis da
INNER JOIN models m ON da.model_id = m.model_id
INNER JOIN projects p ON m.project_id = p.project_id
ORDER BY da.total_predictions DESC;