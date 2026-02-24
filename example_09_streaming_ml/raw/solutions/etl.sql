-- ETL from raw denormalized table into normalized tables
USE streaming_ml;

INSERT INTO dim_stream (name, created_at, updated_at)
SELECT DISTINCT r.stream_name, NOW(), NOW()
FROM raw_event_stream r;

INSERT INTO dim_event (time, type, created_at, updated_at)
SELECT DISTINCT r.event_time, r.event_type, NOW(), NOW()
FROM raw_event_stream r;

INSERT INTO dim_feature (key, value, created_at, updated_at)
SELECT DISTINCT r.feature_key, r.feature_value, NOW(), NOW()
FROM raw_event_stream r;

INSERT INTO dim_model (name, created_at, updated_at)
SELECT DISTINCT r.model_name, NOW(), NOW()
FROM raw_event_stream r;

INSERT INTO fact_event_stream (stream_id, event_id, feature_id, model_id, source_row_id, org_name, project_name, prediction, created_at, updated_at)
SELECT
    d_stream.stream_id,
    d_event.event_id,
    d_feature.feature_id,
    d_model.model_id,
    r.row_id,
    r.org_name,
    r.project_name,
    r.prediction,
    NOW(),
    NOW()
FROM raw_event_stream r
LEFT JOIN dim_stream d_stream ON r.stream_name <=> d_stream.name
LEFT JOIN dim_event d_event ON r.event_time <=> d_event.time AND r.event_type <=> d_event.type
LEFT JOIN dim_feature d_feature ON r.feature_key <=> d_feature.key AND r.feature_value <=> d_feature.value
LEFT JOIN dim_model d_model ON r.model_name <=> d_model.name
;
