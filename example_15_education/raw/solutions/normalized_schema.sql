-- Normalized schema generated from raw denormalized table
USE education;

DROP TABLE IF EXISTS fact_student_activity;
DROP TABLE IF EXISTS dim_student;
DROP TABLE IF EXISTS dim_course;

CREATE TABLE dim_student (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255),
    full_name VARCHAR(255),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_student_natural (email, full_name, first_name, last_name),
    INDEX idx_dim_student_natural (email, full_name, first_name, last_name)
) ENGINE=InnoDB;

CREATE TABLE dim_course (
    course_id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(255),
    name VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_dim_course_natural (code, name),
    INDEX idx_dim_course_natural (code, name)
) ENGINE=InnoDB;

CREATE TABLE fact_student_activity (
    fact_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    source_row_id INT,
    UNIQUE KEY uq_fact_student_activity_source (source_row_id),
    instructor_name VARCHAR(255),
    activity_time VARCHAR(255),
    activity_type ENUM('assignment', 'quiz'),
    score VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE fact_student_activity
    ADD CONSTRAINT fk_fact_student_activity_student FOREIGN KEY (student_id)
    REFERENCES dim_student (student_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE fact_student_activity
    ADD CONSTRAINT fk_fact_student_activity_course FOREIGN KEY (course_id)
    REFERENCES dim_course (course_id)
    ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX idx_fact_student_activity_student ON fact_student_activity (student_id);
CREATE INDEX idx_fact_student_activity_course ON fact_student_activity (course_id);
CREATE INDEX idx_fact_student_activity_source ON fact_student_activity (source_row_id);
