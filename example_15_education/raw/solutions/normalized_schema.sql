-- Normalized schema generated from raw denormalized table
USE education;

DROP TABLE IF EXISTS fact_student_activity;
DROP TABLE IF EXISTS dim_student;
DROP TABLE IF EXISTS dim_course;

CREATE TABLE dim_student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    name VARCHAR(255),
    UNIQUE KEY uq_dim_student_natural (email, name)
) ENGINE=InnoDB;

CREATE TABLE dim_course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255),
    name VARCHAR(255),
    UNIQUE KEY uq_dim_course_natural (code, name)
) ENGINE=InnoDB;

CREATE TABLE fact_student_activity (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_student_activity_source (source_row_id),
    instructor_name VARCHAR(255),
    activity_time VARCHAR(255),
    activity_type VARCHAR(255),
    score VARCHAR(255)
) ENGINE=InnoDB;

ALTER TABLE fact_student_activity
    ADD CONSTRAINT fk_fact_student_activity_student FOREIGN KEY (student_id)
    REFERENCES dim_student (student_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE fact_student_activity
    ADD CONSTRAINT fk_fact_student_activity_course FOREIGN KEY (course_id)
    REFERENCES dim_course (course_id)
    ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX idx_fact_student_activity_student ON fact_student_activity (student_id);
CREATE INDEX idx_fact_student_activity_course ON fact_student_activity (course_id);
CREATE INDEX idx_fact_student_activity_source ON fact_student_activity (source_row_id);
