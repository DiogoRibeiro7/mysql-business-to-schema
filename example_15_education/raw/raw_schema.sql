-- Raw denormalized table for normalization exercises
USE education;

DROP TABLE IF EXISTS raw_student_activity;

CREATE TABLE raw_student_activity (
    row_id INT AUTO_INCREMENT PRIMARY KEY,
    student_email VARCHAR(255),
    student_name VARCHAR(255),
    course_code VARCHAR(255),
    course_name VARCHAR(255),
    instructor_name VARCHAR(255),
    activity_time VARCHAR(255),
    activity_type VARCHAR(255),
    score VARCHAR(255)
) ENGINE=InnoDB;
