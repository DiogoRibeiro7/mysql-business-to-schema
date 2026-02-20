-- ETL from raw denormalized table into normalized tables
USE social_media;

INSERT INTO dim_user (handle)
SELECT DISTINCT r.user_handle
FROM raw_social_events r;

INSERT INTO dim_event (time, type)
SELECT DISTINCT r.event_time, r.event_type
FROM raw_social_events r;

INSERT INTO dim_post (text)
SELECT DISTINCT r.post_text
FROM raw_social_events r;

INSERT INTO dim_comment (count)
SELECT DISTINCT r.comment_count
FROM raw_social_events r;

INSERT INTO dim_device (type)
SELECT DISTINCT r.device_type
FROM raw_social_events r;

INSERT INTO fact_social_events (user_id, event_id, post_id, comment_id, device_id, target_handle, like_count)
SELECT
    d_user.user_id,
    d_event.event_id,
    d_post.post_id,
    d_comment.comment_id,
    d_device.device_id,
    r.target_handle,
    r.like_count
FROM raw_social_events r
LEFT JOIN dim_user d_user ON r.user_handle <=> d_user.handle
LEFT JOIN dim_event d_event ON r.event_time <=> d_event.time AND r.event_type <=> d_event.type
LEFT JOIN dim_post d_post ON r.post_text <=> d_post.text
LEFT JOIN dim_comment d_comment ON r.comment_count <=> d_comment.count
LEFT JOIN dim_device d_device ON r.device_type <=> d_device.type
;
