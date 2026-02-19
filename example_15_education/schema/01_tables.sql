-- Education & Learning Management System (LMS)
-- Comprehensive schema for online and traditional education

-- Create database
CREATE DATABASE IF NOT EXISTS education_db;
USE education;

-- ========================================
-- USER MANAGEMENT & AUTHENTICATION
-- ========================================

-- Institutions (Schools, Universities, Companies)
CREATE TABLE institutions (
    institution_id INT PRIMARY KEY AUTO_INCREMENT,
    institution_code VARCHAR(50) UNIQUE NOT NULL,
    institution_name VARCHAR(200) NOT NULL,
    institution_type ENUM('K12', 'UNIVERSITY', 'COLLEGE', 'CORPORATE', 'TRAINING_CENTER', 'ONLINE') NOT NULL,
    website_url VARCHAR(500),
    logo_url VARCHAR(500),
    primary_color VARCHAR(7),
    secondary_color VARCHAR(7),
    timezone VARCHAR(50) DEFAULT 'UTC',
    academic_year_start INT DEFAULT 9,  -- Month number
    grading_scale JSON,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code CHAR(2),
    student_count INT DEFAULT 0,
    instructor_count INT DEFAULT 0,
    course_count INT DEFAULT 0,
    subscription_tier ENUM('FREE', 'BASIC', 'PROFESSIONAL', 'ENTERPRISE') DEFAULT 'FREE',
    subscription_expires DATE,
    storage_used_gb DECIMAL(10, 2) DEFAULT 0,
    storage_limit_gb DECIMAL(10, 2) DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_institution_type (institution_type),
    INDEX idx_subscription (subscription_tier, subscription_expires)
);

-- Users (Students, Instructors, Administrators)
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    institution_id INT,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    display_name VARCHAR(100),
    user_type ENUM('STUDENT', 'INSTRUCTOR', 'ADMIN', 'PARENT', 'GUEST') NOT NULL,
    student_id VARCHAR(50),
    employee_id VARCHAR(50),
    date_of_birth DATE,
    gender ENUM('MALE', 'FEMALE', 'OTHER', 'PREFER_NOT_TO_SAY'),
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url VARCHAR(500),
    bio TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50),
    notification_preferences JSON,
    last_login_at DATETIME,
    last_activity_at DATETIME,
    login_count INT DEFAULT 0,
    failed_login_attempts INT DEFAULT 0,
    account_locked_until DATETIME,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    status ENUM('PENDING', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'GRADUATED') DEFAULT 'PENDING',
    graduation_year INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id),
    INDEX idx_user_type (user_type, status),
    INDEX idx_institution_users (institution_id, user_type),
    INDEX idx_email (email),
    INDEX idx_student_id (student_id),
    FULLTEXT idx_user_search (first_name, last_name, email)
);

-- User Profiles (Extended information)
CREATE TABLE user_profiles (
    profile_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,

    -- Academic Information
    major VARCHAR(100),
    minor VARCHAR(100),
    gpa DECIMAL(3, 2),
    credits_earned INT DEFAULT 0,
    credits_required INT,
    expected_graduation DATE,
    academic_standing ENUM('GOOD', 'PROBATION', 'SUSPENSION'),

    -- Professional Information
    occupation VARCHAR(100),
    employer VARCHAR(200),
    years_experience INT,
    linkedin_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    resume_url VARCHAR(500),

    -- Learning Preferences
    learning_style ENUM('VISUAL', 'AUDITORY', 'READING', 'KINESTHETIC', 'MIXED'),
    preferred_pace ENUM('SELF_PACED', 'INSTRUCTOR_PACED', 'FLEXIBLE'),
    interests JSON,
    skills JSON,
    certifications JSON,

    -- Accessibility Needs
    accessibility_needs JSON,
    accommodations_required BOOLEAN DEFAULT FALSE,
    accommodations_details TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_academic_standing (academic_standing),
    INDEX idx_graduation (expected_graduation)
);

-- Roles and Permissions
CREATE TABLE roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    role_description TEXT,
    permissions JSON,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Role Assignments
CREATE TABLE user_roles (
    user_role_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_by INT,
    valid_from DATETIME DEFAULT CURRENT_TIMESTAMP,
    valid_until DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    FOREIGN KEY (assigned_by) REFERENCES users(user_id),
    UNIQUE KEY uk_user_role (user_id, role_id),
    INDEX idx_user_roles (user_id),
    INDEX idx_valid_dates (valid_from, valid_until)
);

-- ========================================
-- COURSE MANAGEMENT
-- ========================================

-- Academic Departments
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    institution_id INT NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    department_head_id INT,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id),
    FOREIGN KEY (department_head_id) REFERENCES users(user_id),
    UNIQUE KEY uk_dept_code (institution_id, department_code),
    INDEX idx_institution_dept (institution_id)
);

-- Academic Terms/Semesters
CREATE TABLE academic_terms (
    term_id INT PRIMARY KEY AUTO_INCREMENT,
    institution_id INT NOT NULL,
    term_code VARCHAR(20) NOT NULL,
    term_name VARCHAR(100) NOT NULL,
    term_type ENUM('SEMESTER', 'QUARTER', 'TRIMESTER', 'SUMMER', 'WINTER') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_start DATE,
    registration_end DATE,
    add_drop_deadline DATE,
    withdrawal_deadline DATE,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id),
    UNIQUE KEY uk_term_code (institution_id, term_code),
    INDEX idx_term_dates (start_date, end_date),
    INDEX idx_active_term (institution_id, is_active)
);

-- Courses (Master catalog)
CREATE TABLE courses (
    course_id INT PRIMARY KEY AUTO_INCREMENT,
    institution_id INT NOT NULL,
    department_id INT,
    course_code VARCHAR(20) NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    course_description TEXT,
    syllabus_url VARCHAR(500),
    credits INT DEFAULT 3,
    course_level ENUM('INTRODUCTORY', 'INTERMEDIATE', 'ADVANCED', 'GRADUATE') NOT NULL,
    format ENUM('IN_PERSON', 'ONLINE', 'HYBRID', 'SELF_PACED') NOT NULL,
    duration_weeks INT,
    hours_per_week DECIMAL(4, 1),
    max_students INT DEFAULT 30,
    min_students INT DEFAULT 5,
    prerequisites JSON,
    corequisites JSON,
    learning_outcomes JSON,
    required_materials JSON,
    tags JSON,
    is_active BOOLEAN DEFAULT TRUE,
    version INT DEFAULT 1,
    created_by INT,
    approved_by INT,
    approved_date DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id),
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    FOREIGN KEY (approved_by) REFERENCES users(user_id),
    UNIQUE KEY uk_course_code (institution_id, course_code),
    INDEX idx_department (department_id),
    INDEX idx_course_level (course_level),
    INDEX idx_format (format),
    FULLTEXT idx_course_search (course_name, course_description)
);

-- Course Sections (Actual class instances)
CREATE TABLE course_sections (
    section_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    term_id INT NOT NULL,
    section_code VARCHAR(20) NOT NULL,
    instructor_id INT NOT NULL,
    co_instructor_id INT,
    teaching_assistants JSON,

    -- Schedule Information
    meeting_pattern ENUM('MWF', 'TTH', 'MW', 'DAILY', 'WEEKLY', 'CUSTOM') DEFAULT 'CUSTOM',
    meeting_days SET('MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'),
    start_time TIME,
    end_time TIME,
    location VARCHAR(100),
    room_number VARCHAR(50),
    is_online BOOLEAN DEFAULT FALSE,
    meeting_url VARCHAR(500),

    -- Enrollment Information
    enrollment_capacity INT DEFAULT 30,
    enrollment_count INT DEFAULT 0,
    waitlist_capacity INT DEFAULT 10,
    waitlist_count INT DEFAULT 0,

    -- Section Settings
    allow_auditing BOOLEAN DEFAULT FALSE,
    allow_late_enrollment BOOLEAN DEFAULT FALSE,
    require_attendance BOOLEAN DEFAULT FALSE,
    record_lectures BOOLEAN DEFAULT FALSE,

    status ENUM('PLANNING', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED') DEFAULT 'PLANNING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (term_id) REFERENCES academic_terms(term_id),
    FOREIGN KEY (instructor_id) REFERENCES users(user_id),
    FOREIGN KEY (co_instructor_id) REFERENCES users(user_id),
    UNIQUE KEY uk_section_code (term_id, section_code),
    INDEX idx_course_term (course_id, term_id),
    INDEX idx_instructor (instructor_id),
    INDEX idx_status_enrollment (status, enrollment_count, enrollment_capacity)
);

-- Course Modules/Units
CREATE TABLE course_modules (
    module_id INT PRIMARY KEY AUTO_INCREMENT,
    course_id INT NOT NULL,
    module_number INT NOT NULL,
    module_name VARCHAR(200) NOT NULL,
    module_description TEXT,
    learning_objectives JSON,
    estimated_hours DECIMAL(4, 1),
    is_published BOOLEAN DEFAULT FALSE,
    unlock_date DATETIME,
    due_date DATETIME,
    sort_order INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE,
    UNIQUE KEY uk_module (course_id, module_number),
    INDEX idx_course_modules (course_id, sort_order)
);

-- Lessons within Modules
CREATE TABLE lessons (
    lesson_id INT PRIMARY KEY AUTO_INCREMENT,
    module_id INT NOT NULL,
    lesson_number INT NOT NULL,
    lesson_name VARCHAR(200) NOT NULL,
    lesson_type ENUM('VIDEO', 'TEXT', 'INTERACTIVE', 'QUIZ', 'ASSIGNMENT', 'DISCUSSION', 'EXTERNAL') NOT NULL,
    content_url VARCHAR(500),
    content_html TEXT,
    duration_minutes INT,
    is_required BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT FALSE,
    allow_comments BOOLEAN DEFAULT TRUE,
    completion_criteria JSON,
    points_possible INT DEFAULT 0,
    sort_order INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (module_id) REFERENCES course_modules(module_id) ON DELETE CASCADE,
    UNIQUE KEY uk_lesson (module_id, lesson_number),
    INDEX idx_module_lessons (module_id, sort_order),
    INDEX idx_lesson_type (lesson_type)
);

-- Learning Resources
CREATE TABLE learning_resources (
    resource_id INT PRIMARY KEY AUTO_INCREMENT,
    resource_type ENUM('VIDEO', 'DOCUMENT', 'LINK', 'EBOOK', 'TOOL', 'DATASET') NOT NULL,
    resource_name VARCHAR(200) NOT NULL,
    description TEXT,
    url VARCHAR(500),
    file_path VARCHAR(500),
    file_size_mb DECIMAL(10, 2),
    mime_type VARCHAR(100),
    duration_seconds INT,
    thumbnail_url VARCHAR(500),
    tags JSON,
    usage_count INT DEFAULT 0,
    created_by INT,
    is_public BOOLEAN DEFAULT FALSE,
    license_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_resource_type (resource_type),
    INDEX idx_created_by (created_by),
    FULLTEXT idx_resource_search (resource_name, description)
);

-- Lesson Resources (Many-to-Many)
CREATE TABLE lesson_resources (
    lesson_resource_id INT PRIMARY KEY AUTO_INCREMENT,
    lesson_id INT NOT NULL,
    resource_id INT NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    sort_order INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id) ON DELETE CASCADE,
    FOREIGN KEY (resource_id) REFERENCES learning_resources(resource_id),
    UNIQUE KEY uk_lesson_resource (lesson_id, resource_id),
    INDEX idx_lesson (lesson_id)
);

-- ========================================
-- ENROLLMENT & REGISTRATION
-- ========================================

-- Course Enrollments
CREATE TABLE enrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    user_id INT NOT NULL,
    enrollment_type ENUM('REGULAR', 'AUDIT', 'OBSERVER', 'TEACHING_ASSISTANT') DEFAULT 'REGULAR',
    enrollment_status ENUM('ENROLLED', 'WAITLISTED', 'DROPPED', 'WITHDRAWN', 'COMPLETED') DEFAULT 'ENROLLED',
    enrollment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    drop_date DATETIME,
    completion_date DATETIME,
    final_grade VARCHAR(5),
    grade_points DECIMAL(3, 2),
    credits_earned DECIMAL(4, 2),
    attendance_percentage DECIMAL(5, 2),
    last_accessed DATETIME,
    access_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY uk_enrollment (section_id, user_id),
    INDEX idx_user_enrollments (user_id, enrollment_status),
    INDEX idx_section_enrollments (section_id, enrollment_status),
    INDEX idx_enrollment_date (enrollment_date)
);

-- Prerequisites Tracking
CREATE TABLE prerequisite_overrides (
    override_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    course_id INT NOT NULL,
    overridden_by INT NOT NULL,
    reason TEXT,
    valid_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    FOREIGN KEY (overridden_by) REFERENCES users(user_id),
    UNIQUE KEY uk_user_course_override (user_id, course_id)
);

-- ========================================
-- LEARNING PROGRESS & TRACKING
-- ========================================

-- Lesson Progress Tracking
CREATE TABLE lesson_progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    lesson_id INT NOT NULL,
    section_id INT NOT NULL,
    status ENUM('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED') DEFAULT 'NOT_STARTED',
    progress_percentage INT DEFAULT 0,
    time_spent_seconds INT DEFAULT 0,
    last_position INT DEFAULT 0,  -- For video/content position
    completion_date DATETIME,
    attempts INT DEFAULT 0,
    score DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id),
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    UNIQUE KEY uk_user_lesson (user_id, lesson_id, section_id),
    INDEX idx_user_progress (user_id, status),
    INDEX idx_lesson_completion (lesson_id, status)
);

-- Learning Paths (Personalized sequences)
CREATE TABLE learning_paths (
    path_id INT PRIMARY KEY AUTO_INCREMENT,
    path_name VARCHAR(200) NOT NULL,
    path_description TEXT,
    target_role VARCHAR(100),
    skill_level ENUM('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT') DEFAULT 'BEGINNER',
    estimated_hours INT,
    courses JSON,  -- Ordered list of course IDs
    is_public BOOLEAN DEFAULT TRUE,
    created_by INT,
    enrollment_count INT DEFAULT 0,
    completion_count INT DEFAULT 0,
    rating DECIMAL(3, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_public_paths (is_public, rating),
    FULLTEXT idx_path_search (path_name, path_description, target_role)
);

-- User Learning Path Enrollments
CREATE TABLE user_learning_paths (
    user_path_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    path_id INT NOT NULL,
    enrollment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    target_completion_date DATE,
    actual_completion_date DATE,
    progress_percentage INT DEFAULT 0,
    current_course_index INT DEFAULT 0,
    status ENUM('ACTIVE', 'PAUSED', 'COMPLETED', 'ABANDONED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (path_id) REFERENCES learning_paths(path_id),
    UNIQUE KEY uk_user_path (user_id, path_id),
    INDEX idx_user_paths (user_id, status),
    INDEX idx_path_enrollments (path_id, status)
);

-- ========================================
-- ASSESSMENTS & ASSIGNMENTS
-- ========================================

-- Assignments (All types of assessments)
CREATE TABLE assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    assignment_type ENUM('HOMEWORK', 'QUIZ', 'EXAM', 'PROJECT', 'PAPER', 'PRESENTATION', 'PARTICIPATION') NOT NULL,
    title VARCHAR(200) NOT NULL,
    instructions TEXT,
    attachments JSON,
    points_possible DECIMAL(8, 2) NOT NULL,
    weight_percentage DECIMAL(5, 2),
    due_date DATETIME,
    available_from DATETIME,
    available_until DATETIME,
    time_limit_minutes INT,
    attempt_limit INT DEFAULT 1,
    show_correct_answers BOOLEAN DEFAULT TRUE,
    show_correct_answers_at DATETIME,
    shuffle_questions BOOLEAN DEFAULT FALSE,
    shuffle_answers BOOLEAN DEFAULT FALSE,
    require_lockdown_browser BOOLEAN DEFAULT FALSE,
    require_proctoring BOOLEAN DEFAULT FALSE,
    late_submission_allowed BOOLEAN DEFAULT TRUE,
    late_penalty_percentage DECIMAL(5, 2) DEFAULT 0,
    grace_period_hours INT DEFAULT 0,
    group_assignment BOOLEAN DEFAULT FALSE,
    peer_review_required BOOLEAN DEFAULT FALSE,
    rubric_id INT,
    status ENUM('DRAFT', 'PUBLISHED', 'CLOSED') DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    INDEX idx_section_assignments (section_id, assignment_type),
    INDEX idx_due_date (due_date),
    INDEX idx_status (status)
);

-- Quiz/Exam Questions
CREATE TABLE questions (
    question_id INT PRIMARY KEY AUTO_INCREMENT,
    assignment_id INT,
    question_type ENUM('MULTIPLE_CHOICE', 'TRUE_FALSE', 'SHORT_ANSWER', 'ESSAY', 'MATCHING', 'FILL_BLANK', 'NUMERIC', 'FILE_UPLOAD') NOT NULL,
    question_text TEXT NOT NULL,
    question_html TEXT,
    media_url VARCHAR(500),
    correct_answer JSON,
    answer_options JSON,
    answer_explanation TEXT,
    points DECIMAL(6, 2) NOT NULL,
    difficulty ENUM('EASY', 'MEDIUM', 'HARD', 'EXPERT') DEFAULT 'MEDIUM',
    time_estimate_seconds INT,
    tags JSON,
    sort_order INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id) ON DELETE CASCADE,
    INDEX idx_assignment_questions (assignment_id, sort_order),
    INDEX idx_question_type (question_type),
    FULLTEXT idx_question_search (question_text)
);

-- Question Bank (Reusable questions)
CREATE TABLE question_bank (
    bank_question_id INT PRIMARY KEY AUTO_INCREMENT,
    created_by INT NOT NULL,
    subject VARCHAR(100),
    topic VARCHAR(100),
    question_type ENUM('MULTIPLE_CHOICE', 'TRUE_FALSE', 'SHORT_ANSWER', 'ESSAY', 'MATCHING', 'FILL_BLANK', 'NUMERIC') NOT NULL,
    question_text TEXT NOT NULL,
    correct_answer JSON,
    answer_options JSON,
    difficulty ENUM('EASY', 'MEDIUM', 'HARD', 'EXPERT') DEFAULT 'MEDIUM',
    usage_count INT DEFAULT 0,
    success_rate DECIMAL(5, 2),
    is_public BOOLEAN DEFAULT FALSE,
    tags JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_creator (created_by),
    INDEX idx_subject_topic (subject, topic),
    FULLTEXT idx_bank_search (question_text, subject, topic)
);

-- Rubrics
CREATE TABLE rubrics (
    rubric_id INT PRIMARY KEY AUTO_INCREMENT,
    rubric_name VARCHAR(200) NOT NULL,
    description TEXT,
    created_by INT NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    criteria JSON,  -- Array of criteria with levels and points
    total_points DECIMAL(8, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_created_by (created_by),
    INDEX idx_public (is_public)
);

-- ========================================
-- SUBMISSIONS & GRADING
-- ========================================

-- Assignment Submissions
CREATE TABLE submissions (
    submission_id INT PRIMARY KEY AUTO_INCREMENT,
    assignment_id INT NOT NULL,
    user_id INT NOT NULL,
    group_id INT,
    attempt_number INT DEFAULT 1,
    submission_type ENUM('TEXT', 'FILE', 'URL', 'QUIZ_ANSWERS', 'MEDIA') NOT NULL,
    submission_text TEXT,
    submission_files JSON,
    submission_url VARCHAR(500),
    quiz_answers JSON,
    submitted_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    late_submission BOOLEAN DEFAULT FALSE,
    time_spent_seconds INT,
    ip_address VARCHAR(45),
    browser_info VARCHAR(500),

    -- Grading Information
    score DECIMAL(8, 2),
    grade VARCHAR(5),
    graded_by INT,
    graded_at DATETIME,
    feedback TEXT,
    rubric_scores JSON,

    -- Plagiarism Check
    similarity_score DECIMAL(5, 2),
    similarity_report_url VARCHAR(500),

    status ENUM('DRAFT', 'SUBMITTED', 'GRADING', 'GRADED', 'RETURNED') DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (graded_by) REFERENCES users(user_id),
    UNIQUE KEY uk_submission_attempt (assignment_id, user_id, attempt_number),
    INDEX idx_user_submissions (user_id, status),
    INDEX idx_assignment_submissions (assignment_id, status),
    INDEX idx_grading_queue (status, submitted_at)
);

-- Gradebook
CREATE TABLE gradebook (
    gradebook_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    user_id INT NOT NULL,

    -- Category Scores
    homework_score DECIMAL(5, 2),
    quiz_score DECIMAL(5, 2),
    exam_score DECIMAL(5, 2),
    project_score DECIMAL(5, 2),
    participation_score DECIMAL(5, 2),

    -- Overall Scores
    total_points_earned DECIMAL(10, 2),
    total_points_possible DECIMAL(10, 2),
    percentage_score DECIMAL(5, 2),
    letter_grade VARCHAR(5),
    grade_points DECIMAL(3, 2),

    -- Additional Metrics
    assignments_completed INT DEFAULT 0,
    assignments_total INT DEFAULT 0,
    attendance_score DECIMAL(5, 2),
    extra_credit DECIMAL(6, 2) DEFAULT 0,

    grade_status ENUM('IN_PROGRESS', 'FINAL', 'INCOMPLETE', 'WITHDRAWN') DEFAULT 'IN_PROGRESS',
    last_calculated DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    UNIQUE KEY uk_section_user (section_id, user_id),
    INDEX idx_user_grades (user_id),
    INDEX idx_section_grades (section_id, letter_grade)
);

-- Grade History (Audit trail)
CREATE TABLE grade_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    submission_id INT NOT NULL,
    changed_by INT NOT NULL,
    old_score DECIMAL(8, 2),
    new_score DECIMAL(8, 2),
    old_grade VARCHAR(5),
    new_grade VARCHAR(5),
    change_reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES submissions(submission_id),
    FOREIGN KEY (changed_by) REFERENCES users(user_id),
    INDEX idx_submission_history (submission_id),
    INDEX idx_change_date (changed_at)
);

-- ========================================
-- COMMUNICATION & COLLABORATION
-- ========================================

-- Discussion Forums
CREATE TABLE discussions (
    discussion_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    discussion_type ENUM('GENERAL', 'QUESTION', 'ASSIGNMENT', 'ANNOUNCEMENT') DEFAULT 'GENERAL',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    allow_anonymous BOOLEAN DEFAULT FALSE,
    require_post_before_view BOOLEAN DEFAULT FALSE,
    created_by INT NOT NULL,
    post_count INT DEFAULT 0,
    last_post_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_section_discussions (section_id, is_pinned),
    INDEX idx_discussion_type (discussion_type),
    FULLTEXT idx_discussion_search (title, description)
);

-- Discussion Posts
CREATE TABLE discussion_posts (
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    discussion_id INT NOT NULL,
    parent_post_id INT,
    user_id INT NOT NULL,
    post_content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_answer BOOLEAN DEFAULT FALSE,
    upvotes INT DEFAULT 0,
    downvotes INT DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at DATETIME,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at DATETIME,
    deleted_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (discussion_id) REFERENCES discussions(discussion_id) ON DELETE CASCADE,
    FOREIGN KEY (parent_post_id) REFERENCES discussion_posts(post_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (deleted_by) REFERENCES users(user_id),
    INDEX idx_discussion_posts (discussion_id, created_at),
    INDEX idx_parent_replies (parent_post_id),
    FULLTEXT idx_post_search (post_content)
);

-- Direct Messages
CREATE TABLE messages (
    message_id INT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,
    recipient_id INT NOT NULL,
    subject VARCHAR(200),
    message_body TEXT NOT NULL,
    attachments JSON,
    is_read BOOLEAN DEFAULT FALSE,
    read_at DATETIME,
    is_deleted_sender BOOLEAN DEFAULT FALSE,
    is_deleted_recipient BOOLEAN DEFAULT FALSE,
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'URGENT') DEFAULT 'NORMAL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(user_id),
    FOREIGN KEY (recipient_id) REFERENCES users(user_id),
    INDEX idx_recipient_messages (recipient_id, is_read, is_deleted_recipient),
    INDEX idx_sender_messages (sender_id, is_deleted_sender),
    FULLTEXT idx_message_search (subject, message_body)
);

-- Announcements
CREATE TABLE announcements (
    announcement_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT,
    institution_id INT,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    announcement_type ENUM('INFO', 'WARNING', 'URGENT', 'CELEBRATION') DEFAULT 'INFO',
    target_audience ENUM('ALL', 'STUDENTS', 'INSTRUCTORS', 'SPECIFIC_SECTION', 'SPECIFIC_USERS') DEFAULT 'ALL',
    target_users JSON,
    publish_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    expire_date DATETIME,
    created_by INT NOT NULL,
    view_count INT DEFAULT 0,
    acknowledgment_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    FOREIGN KEY (institution_id) REFERENCES institutions(institution_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_section_announcements (section_id, publish_date),
    INDEX idx_institution_announcements (institution_id, publish_date),
    INDEX idx_active_announcements (publish_date, expire_date)
);

-- ========================================
-- ATTENDANCE & PARTICIPATION
-- ========================================

-- Attendance Records
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    section_id INT NOT NULL,
    user_id INT NOT NULL,
    attendance_date DATE NOT NULL,
    status ENUM('PRESENT', 'ABSENT', 'LATE', 'EXCUSED', 'LEFT_EARLY') NOT NULL,
    check_in_time DATETIME,
    check_out_time DATETIME,
    duration_minutes INT,
    location_verified BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45),
    notes TEXT,
    recorded_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (recorded_by) REFERENCES users(user_id),
    UNIQUE KEY uk_attendance (section_id, user_id, attendance_date),
    INDEX idx_user_attendance (user_id, attendance_date),
    INDEX idx_section_attendance (section_id, attendance_date)
);

-- ========================================
-- ANALYTICS & REPORTING
-- ========================================

-- Activity Logs
CREATE TABLE activity_logs (
    log_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    activity_type ENUM('LOGIN', 'LOGOUT', 'VIEW', 'SUBMIT', 'DOWNLOAD', 'UPLOAD', 'POST', 'GRADE', 'ENROLL') NOT NULL,
    resource_type VARCHAR(50),
    resource_id INT,
    details JSON,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    session_id VARCHAR(100),
    duration_seconds INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_user_activity (user_id, activity_type, created_at),
    INDEX idx_activity_date (created_at),
    INDEX idx_session (session_id)
);

-- Learning Analytics Summary
CREATE TABLE learning_analytics (
    analytics_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    section_id INT NOT NULL,
    week_number INT NOT NULL,

    -- Engagement Metrics
    login_count INT DEFAULT 0,
    total_time_minutes INT DEFAULT 0,
    content_views INT DEFAULT 0,
    video_watch_minutes INT DEFAULT 0,
    discussion_posts INT DEFAULT 0,
    assignment_submissions INT DEFAULT 0,

    -- Performance Metrics
    average_score DECIMAL(5, 2),
    completion_rate DECIMAL(5, 2),
    on_time_submission_rate DECIMAL(5, 2),

    -- Predictive Indicators
    risk_level ENUM('LOW', 'MEDIUM', 'HIGH') DEFAULT 'LOW',
    predicted_grade VARCHAR(5),
    engagement_score DECIMAL(5, 2),

    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (section_id) REFERENCES course_sections(section_id),
    UNIQUE KEY uk_user_section_week (user_id, section_id, week_number),
    INDEX idx_risk_students (section_id, risk_level),
    INDEX idx_user_analytics (user_id, calculated_at)
);

-- Certificates and Badges
CREATE TABLE certificates (
    certificate_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    course_id INT,
    certificate_type ENUM('COMPLETION', 'ACHIEVEMENT', 'PARTICIPATION', 'HONOR') NOT NULL,
    certificate_name VARCHAR(200) NOT NULL,
    certificate_url VARCHAR(500),
    verification_code VARCHAR(50) UNIQUE,
    issued_date DATE NOT NULL,
    expiry_date DATE,
    issuer_name VARCHAR(200),
    issuer_signature_url VARCHAR(500),
    metadata JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (course_id) REFERENCES courses(course_id),
    INDEX idx_user_certificates (user_id, issued_date),
    INDEX idx_verification (verification_code)
);
