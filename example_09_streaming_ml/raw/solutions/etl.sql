-- ETL from raw denormalized table into normalized tables
USE streaming_ml;

INSERT INTO dim_stream (name)
SELECT DISTINCT r.stream_name
FROM raw_event_stream r;

INSERT INTO dim_event (time, type)
SELECT DISTINCT r.event_time, r.event_type
FROM raw_event_stream r;

INSERT INTO dim_feature (key, value)
SELECT DISTINCT r.feature_key, r.feature_value
FROM raw_event_stream r;

INSERT INTO dim_model (name)
SELECT DISTINCT r.model_name
FROM raw_event_stream r;

INSERT INTO fact_event_stream (stream_id, event_id, feature_id, model_id, source_row_id, org_name, project_name, prediction)
SELECT
    d_stream.stream_id,
    d_event.event_id,
    d_feature.feature_id,
    d_model.model_id,
    r.row_id,
    r.org_name,
    r.project_name,
    r.prediction
FROM raw_event_stream r
LEFT JOIN dim_stream d_stream ON r.stream_name <=> d_stream.name
LEFT JOIN dim_event d_event ON r.event_time <=> d_event.time AND r.event_type <=> d_event.type
LEFT JOIN dim_feature d_feature ON r.feature_key <=> d_feature.key AND r.feature_value <=> d_feature.value
LEFT JOIN dim_model d_model ON r.model_name <=> d_model.name
;
