-- PostgreSQL Schema
-- Converted from MySQL on 2026-02-17T23:11:17.400223
-- Generator: MySQL to PostgreSQL Converter

-- Enum Types
CREATE TYPE institutions_status AS ENUM ('FREE', 'BASIC', 'PROFESSIONAL', 'ENTERPRISE');
CREATE TYPE users_status AS ENUM ('PENDING', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'GRADUATED');
CREATE TYPE user_profiles_status AS ENUM ('SELF_PACED', 'INSTRUCTOR_PACED', 'FLEXIBLE');
CREATE TYPE academic_terms_status AS ENUM ('SEMESTER', 'QUARTER', 'TRIMESTER', 'SUMMER', 'WINTER');
CREATE TYPE courses_status AS ENUM ('IN_PERSON', 'ONLINE', 'HYBRID', 'SELF_PACED');
CREATE TYPE course_sections_status AS ENUM ('PLANNING', 'PUBLISHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');
CREATE TYPE lessons_status AS ENUM ('VIDEO', 'TEXT', 'INTERACTIVE', 'QUIZ', 'ASSIGNMENT', 'DISCUSSION', 'EXTERNAL');
CREATE TYPE learning_resources_status AS ENUM ('VIDEO', 'DOCUMENT', 'LINK', 'EBOOK', 'TOOL', 'DATASET');
CREATE TYPE enrollments_status AS ENUM ('ENROLLED', 'WAITLISTED', 'DROPPED', 'WITHDRAWN', 'COMPLETED');
CREATE TYPE lesson_progress_status AS ENUM ('NOT_STARTED', 'IN_PROGRESS', 'COMPLETED');
CREATE TYPE learning_paths_status AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT');
CREATE TYPE user_learning_paths_status AS ENUM ('ACTIVE', 'PAUSED', 'COMPLETED', 'ABANDONED');
CREATE TYPE assignments_status AS ENUM ('DRAFT', 'PUBLISHED', 'CLOSED');
CREATE TYPE questions_status AS ENUM ('EASY', 'MEDIUM', 'HARD', 'EXPERT');
CREATE TYPE question_bank_status AS ENUM ('EASY', 'MEDIUM', 'HARD', 'EXPERT');
CREATE TYPE submissions_status AS ENUM ('DRAFT', 'SUBMITTED', 'GRADING', 'GRADED', 'RETURNED');
CREATE TYPE gradebook_status AS ENUM ('IN_PROGRESS', 'FINAL', 'INCOMPLETE', 'WITHDRAWN');
CREATE TYPE discussions_status AS ENUM ('GENERAL', 'QUESTION', 'ASSIGNMENT', 'ANNOUNCEMENT');
CREATE TYPE messages_status AS ENUM ('LOW', 'NORMAL', 'HIGH', 'URGENT');
CREATE TYPE announcements_status AS ENUM ('ALL', 'STUDENTS', 'INSTRUCTORS', 'SPECIFIC_SECTION', 'SPECIFIC_USERS');
CREATE TYPE attendance_status AS ENUM ('PRESENT', 'ABSENT', 'LATE', 'EXCUSED', 'LEFT_EARLY');
CREATE TYPE activity_logs_status AS ENUM ('LOGIN', 'LOGOUT', 'VIEW', 'SUBMIT', 'DOWNLOAD', 'UPLOAD', 'POST', 'GRADE', 'ENROLL');
CREATE TYPE learning_analytics_status AS ENUM ('LOW', 'MEDIUM', 'HIGH');
CREATE TYPE certificates_status AS ENUM ('COMPLETION', 'ACHIEVEMENT', 'PARTICIPATION', 'HONOR');

-- Create database (run as superuser)
-- CREATE DATABASE education_db;
-- \c education_db

CREATE TABLE IF NOT EXISTS institutions (
    institution_name VARCHAR(200) NOT NULL,
    institution_type institutions_status NOT NULL,
    website_url VARCHAR(500),
    logo_url VARCHAR(500),
    secondary_color VARCHAR(7),
    timezone VARCHAR(50) DEFAULT 'UTC',
    academic_year_start INTEGER DEFAULT 9,
    contact_email VARCHAR(100),
    contact_phone VARCHAR(20),
    address_line1 VARCHAR(200),
    address_line2 VARCHAR(200),
    city VARCHAR(100),
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country_code CHAR(2),
    student_count INTEGER DEFAULT 0,
    instructor_count INTEGER DEFAULT 0,
    course_count INTEGER DEFAULT 0,
    subscription_tier institutions_status DEFAULT 'FREE',
    subscription_expires DATE,
    storage_used_gb DECIMAL(10, 2) DEFAULT 0,
    storage_limit_gb DECIMAL(10, 2) DEFAULT 100,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    institution_id INTEGER,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    display_name VARCHAR(100),
    user_type users_status NOT NULL,
    student_id VARCHAR(50),
    employee_id VARCHAR(50),
    date_of_birth DATE,
    gender users_status,
    phone_number VARCHAR(20),
    phone_verified BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE,
    profile_picture_url VARCHAR(500),
    bio TEXT,
    preferred_language VARCHAR(10) DEFAULT 'en',
    timezone VARCHAR(50),
    notification_preferences JSONB,
    last_login_at TIMESTAMP,
    last_activity_at TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    two_factor_secret VARCHAR(255),
    status users_status DEFAULT 'PENDING',
    graduation_year INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (first_name, last_name, email)
);

ALTER TABLE users ADD CONSTRAINT fk_users_institution_id FOREIGN KEY (institution_id) REFERENCES institutions(institution_id);
CREATE TABLE IF NOT EXISTS user_profiles (
    major VARCHAR(100),
    minor VARCHAR(100),
    gpa DECIMAL(3, 2),
    credits_earned INTEGER DEFAULT 0,
    credits_required INTEGER,
    expected_graduation DATE,
    academic_standing user_profiles_status,
    occupation VARCHAR(100),
    employer VARCHAR(200),
    years_experience INTEGER,
    linkedin_url VARCHAR(500),
    portfolio_url VARCHAR(500),
    resume_url VARCHAR(500),
    learning_style user_profiles_status,
    preferred_pace user_profiles_status,
    interests JSONB,
    skills JSONB,
    certifications JSONB,
    accessibility_needs JSONB,
    accommodations_required BOOLEAN DEFAULT FALSE,
    accommodations_details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE user_profiles ADD CONSTRAINT fk_user_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS roles (
    role_description TEXT,
    permissions JSONB,
    is_system_role BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_roles (
    user_id INTEGER NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_by INTEGER,
    valid_from TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    valid_until TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, role_id)
);

ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_role_id FOREIGN KEY (role_id) REFERENCES roles(role_id);
ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_assigned_by FOREIGN KEY (assigned_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS departments (
    institution_id INTEGER NOT NULL,
    department_code VARCHAR(20) NOT NULL,
    department_name VARCHAR(200) NOT NULL,
    department_head_id INTEGER,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (institution_id, department_code)
);

ALTER TABLE departments ADD CONSTRAINT fk_departments_institution_id FOREIGN KEY (institution_id) REFERENCES institutions(institution_id);
ALTER TABLE departments ADD CONSTRAINT fk_departments_department_head_id FOREIGN KEY (department_head_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS academic_terms (
    institution_id INTEGER NOT NULL,
    term_code VARCHAR(20) NOT NULL,
    term_name VARCHAR(100) NOT NULL,
    term_type academic_terms_status NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    registration_start DATE,
    registration_end DATE,
    add_drop_deadline DATE,
    withdrawal_deadline DATE,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (institution_id, term_code)
);

ALTER TABLE academic_terms ADD CONSTRAINT fk_academic_terms_institution_id FOREIGN KEY (institution_id) REFERENCES institutions(institution_id);
CREATE TABLE IF NOT EXISTS courses (
    institution_id INTEGER NOT NULL,
    department_id INTEGER,
    course_code VARCHAR(20) NOT NULL,
    course_name VARCHAR(200) NOT NULL,
    course_description TEXT,
    syllabus_url VARCHAR(500),
    credits INTEGER DEFAULT 3,
    course_level courses_status NOT NULL,
    format courses_status NOT NULL,
    duration_weeks INTEGER,
    hours_per_week DECIMAL(4, 1),
    max_students INTEGER DEFAULT 30,
    min_students INTEGER DEFAULT 5,
    prerequisites JSONB,
    corequisites JSONB,
    learning_outcomes JSONB,
    required_materials JSONB,
    tags JSONB,
    is_active BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    created_by INTEGER,
    approved_by INTEGER,
    approved_date TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (institution_id, course_code),
    FULLTEXT TEXT (course_name, course_description)
);

ALTER TABLE courses ADD CONSTRAINT fk_courses_institution_id FOREIGN KEY (institution_id) REFERENCES institutions(institution_id);
ALTER TABLE courses ADD CONSTRAINT fk_courses_department_id FOREIGN KEY (department_id) REFERENCES departments(department_id);
ALTER TABLE courses ADD CONSTRAINT fk_courses_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
ALTER TABLE courses ADD CONSTRAINT fk_courses_approved_by FOREIGN KEY (approved_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS course_sections (
    course_id INTEGER NOT NULL,
    term_id INTEGER NOT NULL,
    section_code VARCHAR(20) NOT NULL,
    instructor_id INTEGER NOT NULL,
    co_instructor_id INTEGER,
    teaching_assistants JSONB,
    meeting_pattern course_sections_status DEFAULT 'CUSTOM',
    meeting_days TEXT[],
    start_time TIME,
    end_time TIME,
    location VARCHAR(100),
    room_number VARCHAR(50),
    is_online BOOLEAN DEFAULT FALSE,
    meeting_url VARCHAR(500),
    enrollment_capacity INTEGER DEFAULT 30,
    enrollment_count INTEGER DEFAULT 0,
    waitlist_capacity INTEGER DEFAULT 10,
    waitlist_count INTEGER DEFAULT 0,
    allow_auditing BOOLEAN DEFAULT FALSE,
    allow_late_enrollment BOOLEAN DEFAULT FALSE,
    require_attendance BOOLEAN DEFAULT FALSE,
    record_lectures BOOLEAN DEFAULT FALSE,
    status course_sections_status DEFAULT 'PLANNING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (term_id, section_code)
);

ALTER TABLE course_sections ADD CONSTRAINT fk_course_sections_course_id FOREIGN KEY (course_id) REFERENCES courses(course_id);
ALTER TABLE course_sections ADD CONSTRAINT fk_course_sections_term_id FOREIGN KEY (term_id) REFERENCES academic_terms(term_id);
ALTER TABLE course_sections ADD CONSTRAINT fk_course_sections_instructor_id FOREIGN KEY (instructor_id) REFERENCES users(user_id);
ALTER TABLE course_sections ADD CONSTRAINT fk_course_sections_co_instructor_id FOREIGN KEY (co_instructor_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS course_modules (
    course_id INTEGER NOT NULL,
    module_number INTEGER NOT NULL,
    module_name VARCHAR(200) NOT NULL,
    module_description TEXT,
    learning_objectives JSONB,
    estimated_hours DECIMAL(4, 1),
    is_published BOOLEAN DEFAULT FALSE,
    unlock_date TIMESTAMP,
    due_date TIMESTAMP,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (course_id, module_number)
);

ALTER TABLE course_modules ADD CONSTRAINT fk_course_modules_course_id FOREIGN KEY (course_id) REFERENCES courses(course_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS lessons (
    module_id INTEGER NOT NULL,
    lesson_number INTEGER NOT NULL,
    lesson_name VARCHAR(200) NOT NULL,
    lesson_type lessons_status NOT NULL,
    content_url VARCHAR(500),
    content_html TEXT,
    duration_minutes INTEGER,
    is_required BOOLEAN DEFAULT TRUE,
    is_published BOOLEAN DEFAULT FALSE,
    allow_comments BOOLEAN DEFAULT TRUE,
    completion_criteria JSONB,
    points_possible INTEGER DEFAULT 0,
    sort_order INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (module_id, lesson_number)
);

ALTER TABLE lessons ADD CONSTRAINT fk_lessons_module_id FOREIGN KEY (module_id) REFERENCES course_modules(module_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS learning_resources (
    resource_type learning_resources_status NOT NULL,
    resource_name VARCHAR(200) NOT NULL,
    description TEXT,
    url VARCHAR(500),
    file_path VARCHAR(500),
    file_size_mb DECIMAL(10, 2),
    mime_type VARCHAR(100),
    duration_seconds INTEGER,
    thumbnail_url VARCHAR(500),
    tags JSONB,
    usage_count INTEGER DEFAULT 0,
    created_by INTEGER,
    is_public BOOLEAN DEFAULT FALSE,
    license_type VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (resource_name, description)
);

ALTER TABLE learning_resources ADD CONSTRAINT fk_learning_resources_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS lesson_resources (
    lesson_id INTEGER NOT NULL,
    resource_id INTEGER NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    sort_order INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (lesson_id, resource_id)
);

ALTER TABLE lesson_resources ADD CONSTRAINT fk_lesson_resources_lesson_id FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id) ON DELETE CASCADE;
ALTER TABLE lesson_resources ADD CONSTRAINT fk_lesson_resources_resource_id FOREIGN KEY (resource_id) REFERENCES learning_resources(resource_id);
CREATE TABLE IF NOT EXISTS enrollments (
    section_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    enrollment_type enrollments_status DEFAULT 'REGULAR',
    enrollment_status enrollments_status DEFAULT 'ENROLLED',
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    drop_date TIMESTAMP,
    completion_date TIMESTAMP,
    final_grade VARCHAR(5),
    grade_points DECIMAL(3, 2),
    credits_earned DECIMAL(4, 2),
    attendance_percentage DECIMAL(5, 2),
    last_accessed TIMESTAMP,
    access_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (section_id, user_id)
);

ALTER TABLE enrollments ADD CONSTRAINT fk_enrollments_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
ALTER TABLE enrollments ADD CONSTRAINT fk_enrollments_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS prerequisite_overrides (
    user_id INTEGER NOT NULL,
    course_id INTEGER NOT NULL,
    overridden_by INTEGER NOT NULL,
    reason TEXT,
    valid_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, course_id)
);

ALTER TABLE prerequisite_overrides ADD CONSTRAINT fk_prerequisite_overrides_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE prerequisite_overrides ADD CONSTRAINT fk_prerequisite_overrides_course_id FOREIGN KEY (course_id) REFERENCES courses(course_id);
ALTER TABLE prerequisite_overrides ADD CONSTRAINT fk_prerequisite_overrides_overridden_by FOREIGN KEY (overridden_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS lesson_progress (
    user_id INTEGER NOT NULL,
    lesson_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    status lesson_progress_status DEFAULT 'NOT_STARTED',
    progress_percentage INTEGER DEFAULT 0,
    time_spent_seconds INTEGER DEFAULT 0,
    last_position INTEGER DEFAULT 0,
    attempts INTEGER DEFAULT 0,
    score DECIMAL(5, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, lesson_id, section_id)
);

ALTER TABLE lesson_progress ADD CONSTRAINT fk_lesson_progress_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE lesson_progress ADD CONSTRAINT fk_lesson_progress_lesson_id FOREIGN KEY (lesson_id) REFERENCES lessons(lesson_id);
ALTER TABLE lesson_progress ADD CONSTRAINT fk_lesson_progress_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
CREATE TABLE IF NOT EXISTS learning_paths (
    path_name VARCHAR(200) NOT NULL,
    path_description TEXT,
    target_role VARCHAR(100),
    skill_level learning_paths_status DEFAULT 'BEGINNER',
    estimated_hours INTEGER,
    courses JSONB,
    created_by INTEGER,
    enrollment_count INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    rating DECIMAL(3, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (path_name, path_description, target_role)
);

ALTER TABLE learning_paths ADD CONSTRAINT fk_learning_paths_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS user_learning_paths (
    user_id INTEGER NOT NULL,
    path_id INTEGER NOT NULL,
    enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    target_completion_date DATE,
    actual_completion_date DATE,
    progress_percentage INTEGER DEFAULT 0,
    status user_learning_paths_status DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, path_id)
);

ALTER TABLE user_learning_paths ADD CONSTRAINT fk_user_learning_paths_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE user_learning_paths ADD CONSTRAINT fk_user_learning_paths_path_id FOREIGN KEY (path_id) REFERENCES learning_paths(path_id);
CREATE TABLE IF NOT EXISTS assignments (
    section_id INTEGER NOT NULL,
    assignment_type assignments_status NOT NULL,
    title VARCHAR(200) NOT NULL,
    instructions TEXT,
    attachments JSONB,
    points_possible DECIMAL(8, 2) NOT NULL,
    weight_percentage DECIMAL(5, 2),
    due_date TIMESTAMP,
    available_from TIMESTAMP,
    available_until TIMESTAMP,
    time_limit_minutes INTEGER,
    attempt_limit INTEGER DEFAULT 1,
    show_correct_answers BOOLEAN DEFAULT TRUE,
    show_correct_answers_at TIMESTAMP,
    shuffle_questions BOOLEAN DEFAULT FALSE,
    shuffle_answers BOOLEAN DEFAULT FALSE,
    require_lockdown_browser BOOLEAN DEFAULT FALSE,
    require_proctoring BOOLEAN DEFAULT FALSE,
    late_submission_allowed BOOLEAN DEFAULT TRUE,
    late_penalty_percentage DECIMAL(5, 2) DEFAULT 0,
    grace_period_hours INTEGER DEFAULT 0,
    group_assignment BOOLEAN DEFAULT FALSE,
    peer_review_required BOOLEAN DEFAULT FALSE,
    rubric_id INTEGER,
    status assignments_status DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE assignments ADD CONSTRAINT fk_assignments_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
CREATE TABLE IF NOT EXISTS questions (
    assignment_id INTEGER,
    question_type questions_status NOT NULL,
    question_text TEXT NOT NULL,
    question_html TEXT,
    media_url VARCHAR(500),
    correct_answer JSONB,
    answer_options JSONB,
    answer_explanation TEXT,
    points DECIMAL(6, 2) NOT NULL,
    difficulty questions_status DEFAULT 'MEDIUM',
    time_estimate_seconds INTEGER,
    tags JSONB,
    sort_order INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (question_text)
);

ALTER TABLE questions ADD CONSTRAINT fk_questions_assignment_id FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id) ON DELETE CASCADE;
CREATE TABLE IF NOT EXISTS question_bank (
    created_by INTEGER NOT NULL,
    subject VARCHAR(100),
    topic VARCHAR(100),
    question_type question_bank_status NOT NULL,
    question_text TEXT NOT NULL,
    correct_answer JSONB,
    answer_options JSONB,
    difficulty question_bank_status DEFAULT 'MEDIUM',
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(5, 2),
    is_public BOOLEAN DEFAULT FALSE,
    tags JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (question_text, subject, topic)
);

ALTER TABLE question_bank ADD CONSTRAINT fk_question_bank_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS rubrics (
    rubric_name VARCHAR(200) NOT NULL,
    description TEXT,
    created_by INTEGER NOT NULL,
    is_public BOOLEAN DEFAULT FALSE,
    criteria JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE rubrics ADD CONSTRAINT fk_rubrics_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS submissions (
    assignment_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    group_id INTEGER,
    attempt_number INTEGER DEFAULT 1,
    submission_type submissions_status NOT NULL,
    submission_text TEXT,
    submission_files JSONB,
    submission_url VARCHAR(500),
    quiz_answers JSONB,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    late_submission BOOLEAN DEFAULT FALSE,
    time_spent_seconds INTEGER,
    ip_address VARCHAR(45),
    browser_info VARCHAR(500),
    score DECIMAL(8, 2),
    grade VARCHAR(5),
    graded_by INTEGER,
    graded_at TIMESTAMP,
    feedback TEXT,
    rubric_scores JSONB,
    similarity_score DECIMAL(5, 2),
    similarity_report_url VARCHAR(500),
    status submissions_status DEFAULT 'DRAFT',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (assignment_id, user_id, attempt_number)
);

ALTER TABLE submissions ADD CONSTRAINT fk_submissions_assignment_id FOREIGN KEY (assignment_id) REFERENCES assignments(assignment_id);
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE submissions ADD CONSTRAINT fk_submissions_graded_by FOREIGN KEY (graded_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS gradebook (
    section_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    homework_score DECIMAL(5, 2),
    quiz_score DECIMAL(5, 2),
    exam_score DECIMAL(5, 2),
    project_score DECIMAL(5, 2),
    participation_score DECIMAL(5, 2),
    total_points_earned DECIMAL(10, 2),
    total_points_possible DECIMAL(10, 2),
    percentage_score DECIMAL(5, 2),
    letter_grade VARCHAR(5),
    grade_points DECIMAL(3, 2),
    assignments_completed INTEGER DEFAULT 0,
    assignments_total INTEGER DEFAULT 0,
    attendance_score DECIMAL(5, 2),
    extra_credit DECIMAL(6, 2) DEFAULT 0,
    grade_status gradebook_status DEFAULT 'IN_PROGRESS',
    last_calculated TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (section_id, user_id)
);

ALTER TABLE gradebook ADD CONSTRAINT fk_gradebook_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
ALTER TABLE gradebook ADD CONSTRAINT fk_gradebook_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS grade_history (
    submission_id INTEGER NOT NULL,
    changed_by INTEGER NOT NULL,
    old_score DECIMAL(8, 2),
    new_score DECIMAL(8, 2),
    old_grade VARCHAR(5),
    new_grade VARCHAR(5),
    change_reason TEXT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE grade_history ADD CONSTRAINT fk_grade_history_submission_id FOREIGN KEY (submission_id) REFERENCES submissions(submission_id);
ALTER TABLE grade_history ADD CONSTRAINT fk_grade_history_changed_by FOREIGN KEY (changed_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS discussions (
    section_id INTEGER,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    discussion_type discussions_status DEFAULT 'GENERAL',
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE,
    allow_anonymous BOOLEAN DEFAULT FALSE,
    require_post_before_view BOOLEAN DEFAULT FALSE,
    created_by INTEGER NOT NULL,
    post_count INTEGER DEFAULT 0,
    last_post_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (title, description)
);

ALTER TABLE discussions ADD CONSTRAINT fk_discussions_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
ALTER TABLE discussions ADD CONSTRAINT fk_discussions_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS discussion_posts (
    discussion_id INTEGER NOT NULL,
    parent_post_id INTEGER,
    user_id INTEGER NOT NULL,
    post_content TEXT NOT NULL,
    is_anonymous BOOLEAN DEFAULT FALSE,
    is_answer BOOLEAN DEFAULT FALSE,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP,
    deleted_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (post_content)
);

ALTER TABLE discussion_posts ADD CONSTRAINT fk_discussion_posts_discussion_id FOREIGN KEY (discussion_id) REFERENCES discussions(discussion_id) ON DELETE CASCADE;
ALTER TABLE discussion_posts ADD CONSTRAINT fk_discussion_posts_parent_post_id FOREIGN KEY (parent_post_id) REFERENCES discussion_posts(post_id);
ALTER TABLE discussion_posts ADD CONSTRAINT fk_discussion_posts_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE discussion_posts ADD CONSTRAINT fk_discussion_posts_deleted_by FOREIGN KEY (deleted_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS messages (
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    subject VARCHAR(200),
    message_body TEXT NOT NULL,
    attachments JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    is_deleted_sender BOOLEAN DEFAULT FALSE,
    is_deleted_recipient BOOLEAN DEFAULT FALSE,
    priority messages_status DEFAULT 'NORMAL',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FULLTEXT TEXT (subject, message_body)
);

ALTER TABLE messages ADD CONSTRAINT fk_messages_sender_id FOREIGN KEY (sender_id) REFERENCES users(user_id);
ALTER TABLE messages ADD CONSTRAINT fk_messages_recipient_id FOREIGN KEY (recipient_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS announcements (
    section_id INTEGER,
    institution_id INTEGER,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    announcement_type announcements_status DEFAULT 'INFO',
    target_audience announcements_status DEFAULT 'ALL',
    target_users JSONB,
    publish_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expire_date TIMESTAMP,
    created_by INTEGER NOT NULL,
    view_count INTEGER DEFAULT 0,
    acknowledgment_required BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE announcements ADD CONSTRAINT fk_announcements_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
ALTER TABLE announcements ADD CONSTRAINT fk_announcements_institution_id FOREIGN KEY (institution_id) REFERENCES institutions(institution_id);
ALTER TABLE announcements ADD CONSTRAINT fk_announcements_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS attendance (
    section_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    attendance_date DATE NOT NULL,
    status attendance_status NOT NULL,
    duration_minutes INTEGER,
    location_verified BOOLEAN DEFAULT FALSE,
    ip_address VARCHAR(45),
    notes TEXT,
    recorded_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (section_id, user_id, attendance_date)
);

ALTER TABLE attendance ADD CONSTRAINT fk_attendance_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
ALTER TABLE attendance ADD CONSTRAINT fk_attendance_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE attendance ADD CONSTRAINT fk_attendance_recorded_by FOREIGN KEY (recorded_by) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS activity_logs (
    user_id INTEGER NOT NULL,
    activity_type activity_logs_status NOT NULL,
    resource_type VARCHAR(50),
    resource_id INTEGER,
    details JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    session_id VARCHAR(100),
    duration_seconds INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PARTITION TEXT VALUES LESS THAN (2025),
    PARTITION TEXT VALUES LESS THAN (2026),
    PARTITION TEXT VALUES LESS THAN MAXVALUE
);

ALTER TABLE activity_logs ADD CONSTRAINT fk_activity_logs_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
CREATE TABLE IF NOT EXISTS learning_analytics (
    user_id INTEGER NOT NULL,
    section_id INTEGER NOT NULL,
    week_number INTEGER NOT NULL,
    login_count INTEGER DEFAULT 0,
    total_time_minutes INTEGER DEFAULT 0,
    content_views INTEGER DEFAULT 0,
    video_watch_minutes INTEGER DEFAULT 0,
    discussion_posts INTEGER DEFAULT 0,
    assignment_submissions INTEGER DEFAULT 0,
    average_score DECIMAL(5, 2),
    completion_rate DECIMAL(5, 2),
    on_time_submission_rate DECIMAL(5, 2),
    risk_level learning_analytics_status DEFAULT 'LOW',
    predicted_grade VARCHAR(5),
    engagement_score DECIMAL(5, 2),
    calculated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, section_id, week_number)
);

ALTER TABLE learning_analytics ADD CONSTRAINT fk_learning_analytics_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE learning_analytics ADD CONSTRAINT fk_learning_analytics_section_id FOREIGN KEY (section_id) REFERENCES course_sections(section_id);
CREATE TABLE IF NOT EXISTS certificates (
    user_id INTEGER NOT NULL,
    course_id INTEGER,
    certificate_type certificates_status NOT NULL,
    certificate_name VARCHAR(200) NOT NULL,
    certificate_url VARCHAR(500),
    issued_date DATE NOT NULL,
    expiry_date DATE,
    issuer_name VARCHAR(200),
    issuer_signature_url VARCHAR(500),
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE certificates ADD CONSTRAINT fk_certificates_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE certificates ADD CONSTRAINT fk_certificates_course_id FOREIGN KEY (course_id) REFERENCES courses(course_id);
-- Indexes
