-- ETL from raw denormalized table into normalized tables
USE social_media;

INSERT INTO dim_user (handle, created_at, updated_at)
SELECT DISTINCT r.user_handle, NOW(), NOW()
FROM raw_social_events r;

INSERT INTO dim_event (time, type, created_at, updated_at)
SELECT DISTINCT r.event_time, r.event_type, NOW(), NOW()
FROM raw_social_events r;

INSERT INTO dim_post (text, created_at, updated_at)
SELECT DISTINCT r.post_text, NOW(), NOW()
FROM raw_social_events r;

INSERT INTO dim_comment (count, created_at, updated_at)
SELECT DISTINCT r.comment_count, NOW(), NOW()
FROM raw_social_events r;

INSERT INTO dim_device (type, created_at, updated_at)
SELECT DISTINCT r.device_type, NOW(), NOW()
FROM raw_social_events r;

INSERT INTO fact_social_events (user_id, event_id, post_id, comment_id, device_id, source_row_id, target_handle, like_count, created_at, updated_at)
SELECT
    d_user.user_id,
    d_event.event_id,
    d_post.post_id,
    d_comment.comment_id,
    d_device.device_id,
    r.row_id,
    r.target_handle,
    r.like_count,
    NOW(),
    NOW()
FROM raw_social_events r
LEFT JOIN dim_user d_user ON r.user_handle <=> d_user.handle
LEFT JOIN dim_event d_event ON r.event_time <=> d_event.time AND r.event_type <=> d_event.type
LEFT JOIN dim_post d_post ON r.post_text <=> d_post.text
LEFT JOIN dim_comment d_comment ON r.comment_count <=> d_comment.count
LEFT JOIN dim_device d_device ON r.device_type <=> d_device.type
;
