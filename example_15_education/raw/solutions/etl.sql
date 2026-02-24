-- ETL from raw denormalized table into normalized tables
USE education;

INSERT INTO dim_student (email, full_name, first_name, last_name, created_at, updated_at)
SELECT DISTINCT r.student_email, r.student_name, SUBSTRING_INDEX(r.student_name, ' ', 1), CASE WHEN INSTR(r.student_name, ' ') > 0 THEN SUBSTRING(r.student_name, INSTR(r.student_name, ' ') + 1) ELSE '' END, NOW(), NOW()
FROM raw_student_activity r;

INSERT INTO dim_course (code, name, created_at, updated_at)
SELECT DISTINCT r.course_code, r.course_name, NOW(), NOW()
FROM raw_student_activity r;

INSERT INTO fact_student_activity (student_id, course_id, source_row_id, instructor_name, activity_time, activity_type, score, created_at, updated_at)
SELECT
    d_student.student_id,
    d_course.course_id,
    r.row_id,
    r.instructor_name,
    r.activity_time,
    r.activity_type,
    r.score,
    NOW(),
    NOW()
FROM raw_student_activity r
LEFT JOIN dim_student d_student ON r.student_email <=> d_student.email AND r.student_name <=> d_student.full_name AND SUBSTRING_INDEX(r.student_name, ' ', 1) <=> d_student.first_name AND CASE WHEN INSTR(r.student_name, ' ') > 0 THEN SUBSTRING(r.student_name, INSTR(r.student_name, ' ') + 1) ELSE '' END <=> d_student.last_name
LEFT JOIN dim_course d_course ON r.course_code <=> d_course.code AND r.course_name <=> d_course.name
;
