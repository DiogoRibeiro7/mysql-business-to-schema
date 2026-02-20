-- ETL from raw denormalized table into normalized tables
USE education;

INSERT INTO dim_student (email, name)
SELECT DISTINCT r.student_email, r.student_name
FROM raw_student_activity r;

INSERT INTO dim_course (code, name)
SELECT DISTINCT r.course_code, r.course_name
FROM raw_student_activity r;

INSERT INTO fact_student_activity (student_id, course_id, instructor_name, activity_time, activity_type, score)
SELECT
    d_student.student_id,
    d_course.course_id,
    r.instructor_name,
    r.activity_time,
    r.activity_type,
    r.score
FROM raw_student_activity r
LEFT JOIN dim_student d_student ON r.student_email <=> d_student.email AND r.student_name <=> d_student.name
LEFT JOIN dim_course d_course ON r.course_code <=> d_course.code AND r.course_name <=> d_course.name
;
