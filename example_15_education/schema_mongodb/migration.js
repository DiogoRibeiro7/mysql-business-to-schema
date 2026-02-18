// MongoDB Migration Script
// Generated: 2026-02-17T23:16:48.832684
// From MySQL to MongoDB

use converted_db;

// Create collection: institutions
db.createCollection('institutions');

// Create collection: users
db.createCollection('users');

// Create collection: user_profiles
db.createCollection('user_profiles');

// Create collection: roles
db.createCollection('roles');

// Create collection: user_roles
db.createCollection('user_roles');

// Create collection: departments
db.createCollection('departments');

// Create collection: academic_terms
db.createCollection('academic_terms');

// Create collection: courses
db.createCollection('courses');

// Create collection: course_sections
db.createCollection('course_sections');

// Create collection: course_modules
db.createCollection('course_modules');

// Create collection: lessons
db.createCollection('lessons');

// Create collection: learning_resources
db.createCollection('learning_resources');

// Create collection: lesson_resources
db.createCollection('lesson_resources');

// Create collection: enrollments
db.createCollection('enrollments');

// Create collection: prerequisite_overrides
db.createCollection('prerequisite_overrides');

// Create collection: lesson_progress
db.createCollection('lesson_progress');

// Create collection: learning_paths
db.createCollection('learning_paths');

// Create collection: user_learning_paths
db.createCollection('user_learning_paths');

// Create collection: assignments
db.createCollection('assignments');

// Create collection: questions
db.createCollection('questions');

// Create collection: question_bank
db.createCollection('question_bank');

// Create collection: rubrics
db.createCollection('rubrics');

// Create collection: submissions
db.createCollection('submissions');

// Create collection: gradebook
db.createCollection('gradebook');

// Create collection: grade_history
db.createCollection('grade_history');

// Create collection: discussions
db.createCollection('discussions');

// Create collection: discussion_posts
db.createCollection('discussion_posts');

// Create collection: messages
db.createCollection('messages');

// Create collection: announcements
db.createCollection('announcements');

// Create collection: attendance
db.createCollection('attendance');

// Create collection: activity_logs
db.createCollection('activity_logs');

// Create collection: learning_analytics
db.createCollection('learning_analytics');

// Create collection: certificates
db.createCollection('certificates');

// Indexes for institutions

// Indexes for users
db.users.createIndex({"institution_id": 1}, {"name": "users_institution_id_idx"});
db.users.createIndex({"bio": "text"}, {"name": "users_text"});

// Indexes for user_profiles
db.user_profiles.createIndex({"user_id": 1}, {"name": "user_profiles_user_id_idx"});
db.user_profiles.createIndex({"accommodations_details": "text"}, {"name": "user_profiles_text"});

// Indexes for roles
db.roles.createIndex({"role_description": "text"}, {"name": "roles_text"});

// Indexes for user_roles
db.user_roles.createIndex({"user_id": 1}, {"name": "user_roles_user_id_idx"});
db.user_roles.createIndex({"role_id": 1}, {"name": "user_roles_role_id_idx"});
db.user_roles.createIndex({"assigned_by": 1}, {"name": "user_roles_assigned_by_idx"});

// Indexes for departments
db.departments.createIndex({"institution_id": 1}, {"name": "departments_institution_id_idx"});
db.departments.createIndex({"department_head_id": 1}, {"name": "departments_department_head_id_idx"});
db.departments.createIndex({"description": "text"}, {"name": "departments_text"});

// Indexes for academic_terms
db.academic_terms.createIndex({"institution_id": 1}, {"name": "academic_terms_institution_id_idx"});

// Indexes for courses
db.courses.createIndex({"institution_id": 1}, {"name": "courses_institution_id_idx"});
db.courses.createIndex({"department_id": 1}, {"name": "courses_department_id_idx"});
db.courses.createIndex({"created_by": 1}, {"name": "courses_created_by_idx"});
db.courses.createIndex({"approved_by": 1}, {"name": "courses_approved_by_idx"});
db.courses.createIndex({"course_description": "text"}, {"name": "courses_text"});

// Indexes for course_sections
db.course_sections.createIndex({"course_id": 1}, {"name": "course_sections_course_id_idx"});
db.course_sections.createIndex({"term_id": 1}, {"name": "course_sections_term_id_idx"});
db.course_sections.createIndex({"instructor_id": 1}, {"name": "course_sections_instructor_id_idx"});
db.course_sections.createIndex({"co_instructor_id": 1}, {"name": "course_sections_co_instructor_id_idx"});

// Indexes for course_modules
db.course_modules.createIndex({"course_id": 1}, {"name": "course_modules_course_id_idx"});
db.course_modules.createIndex({"module_description": "text"}, {"name": "course_modules_text"});

// Indexes for lessons
db.lessons.createIndex({"module_id": 1}, {"name": "lessons_module_id_idx"});
db.lessons.createIndex({"content_html": "text"}, {"name": "lessons_text"});

// Indexes for learning_resources
db.learning_resources.createIndex({"created_by": 1}, {"name": "learning_resources_created_by_idx"});
db.learning_resources.createIndex({"description": "text"}, {"name": "learning_resources_text"});

// Indexes for lesson_resources
db.lesson_resources.createIndex({"lesson_id": 1}, {"name": "lesson_resources_lesson_id_idx"});
db.lesson_resources.createIndex({"resource_id": 1}, {"name": "lesson_resources_resource_id_idx"});

// Indexes for enrollments
db.enrollments.createIndex({"section_id": 1}, {"name": "enrollments_section_id_idx"});
db.enrollments.createIndex({"user_id": 1}, {"name": "enrollments_user_id_idx"});

// Indexes for prerequisite_overrides
db.prerequisite_overrides.createIndex({"user_id": 1}, {"name": "prerequisite_overrides_user_id_idx"});
db.prerequisite_overrides.createIndex({"course_id": 1}, {"name": "prerequisite_overrides_course_id_idx"});
db.prerequisite_overrides.createIndex({"overridden_by": 1}, {"name": "prerequisite_overrides_overridden_by_idx"});
db.prerequisite_overrides.createIndex({"reason": "text"}, {"name": "prerequisite_overrides_text"});

// Indexes for lesson_progress
db.lesson_progress.createIndex({"user_id": 1}, {"name": "lesson_progress_user_id_idx"});
db.lesson_progress.createIndex({"lesson_id": 1}, {"name": "lesson_progress_lesson_id_idx"});
db.lesson_progress.createIndex({"section_id": 1}, {"name": "lesson_progress_section_id_idx"});

// Indexes for learning_paths
db.learning_paths.createIndex({"created_by": 1}, {"name": "learning_paths_created_by_idx"});
db.learning_paths.createIndex({"path_description": "text"}, {"name": "learning_paths_text"});

// Indexes for user_learning_paths
db.user_learning_paths.createIndex({"user_id": 1}, {"name": "user_learning_paths_user_id_idx"});
db.user_learning_paths.createIndex({"path_id": 1}, {"name": "user_learning_paths_path_id_idx"});

// Indexes for assignments
db.assignments.createIndex({"section_id": 1}, {"name": "assignments_section_id_idx"});
db.assignments.createIndex({"instructions": "text"}, {"name": "assignments_text"});

// Indexes for questions
db.questions.createIndex({"assignment_id": 1}, {"name": "questions_assignment_id_idx"});
db.questions.createIndex({"question_text": "text", "question_html": "text", "answer_explanation": "text"}, {"name": "questions_text"});

// Indexes for question_bank
db.question_bank.createIndex({"created_by": 1}, {"name": "question_bank_created_by_idx"});
db.question_bank.createIndex({"question_text": "text"}, {"name": "question_bank_text"});

// Indexes for rubrics
db.rubrics.createIndex({"created_by": 1}, {"name": "rubrics_created_by_idx"});
db.rubrics.createIndex({"description": "text"}, {"name": "rubrics_text"});

// Indexes for submissions
db.submissions.createIndex({"assignment_id": 1}, {"name": "submissions_assignment_id_idx"});
db.submissions.createIndex({"user_id": 1}, {"name": "submissions_user_id_idx"});
db.submissions.createIndex({"graded_by": 1}, {"name": "submissions_graded_by_idx"});
db.submissions.createIndex({"submission_text": "text", "feedback": "text"}, {"name": "submissions_text"});

// Indexes for gradebook
db.gradebook.createIndex({"section_id": 1}, {"name": "gradebook_section_id_idx"});
db.gradebook.createIndex({"user_id": 1}, {"name": "gradebook_user_id_idx"});

// Indexes for grade_history
db.grade_history.createIndex({"submission_id": 1}, {"name": "grade_history_submission_id_idx"});
db.grade_history.createIndex({"changed_by": 1}, {"name": "grade_history_changed_by_idx"});
db.grade_history.createIndex({"change_reason": "text"}, {"name": "grade_history_text"});

// Indexes for discussions
db.discussions.createIndex({"section_id": 1}, {"name": "discussions_section_id_idx"});
db.discussions.createIndex({"created_by": 1}, {"name": "discussions_created_by_idx"});
db.discussions.createIndex({"description": "text"}, {"name": "discussions_text"});

// Indexes for discussion_posts
db.discussion_posts.createIndex({"discussion_id": 1}, {"name": "discussion_posts_discussion_id_idx"});
db.discussion_posts.createIndex({"parent_post_id": 1}, {"name": "discussion_posts_parent_post_id_idx"});
db.discussion_posts.createIndex({"user_id": 1}, {"name": "discussion_posts_user_id_idx"});
db.discussion_posts.createIndex({"deleted_by": 1}, {"name": "discussion_posts_deleted_by_idx"});
db.discussion_posts.createIndex({"post_content": "text"}, {"name": "discussion_posts_text"});

// Indexes for messages
db.messages.createIndex({"sender_id": 1}, {"name": "messages_sender_id_idx"});
db.messages.createIndex({"recipient_id": 1}, {"name": "messages_recipient_id_idx"});
db.messages.createIndex({"message_body": "text"}, {"name": "messages_text"});

// Indexes for announcements
db.announcements.createIndex({"section_id": 1}, {"name": "announcements_section_id_idx"});
db.announcements.createIndex({"institution_id": 1}, {"name": "announcements_institution_id_idx"});
db.announcements.createIndex({"created_by": 1}, {"name": "announcements_created_by_idx"});
db.announcements.createIndex({"content": "text"}, {"name": "announcements_text"});

// Indexes for attendance
db.attendance.createIndex({"section_id": 1}, {"name": "attendance_section_id_idx"});
db.attendance.createIndex({"user_id": 1}, {"name": "attendance_user_id_idx"});
db.attendance.createIndex({"recorded_by": 1}, {"name": "attendance_recorded_by_idx"});
db.attendance.createIndex({"notes": "text"}, {"name": "attendance_text"});

// Indexes for activity_logs
db.activity_logs.createIndex({"user_id": 1}, {"name": "activity_logs_user_id_idx"});

// Indexes for learning_analytics
db.learning_analytics.createIndex({"user_id": 1}, {"name": "learning_analytics_user_id_idx"});
db.learning_analytics.createIndex({"section_id": 1}, {"name": "learning_analytics_section_id_idx"});

// Indexes for certificates
db.certificates.createIndex({"user_id": 1}, {"name": "certificates_user_id_idx"});
db.certificates.createIndex({"course_id": 1}, {"name": "certificates_course_id_idx"});

// Validation for institutions
db.runCommand({
  collMod: 'institutions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "institution_name"
    ],
    "properties": {
      "institution_name": {
        "bsonType": "string"
      },
      "institution_type": {
        "bsonType": "string"
      },
      "website_url": {
        "bsonType": "string"
      },
      "logo_url": {
        "bsonType": "string"
      },
      "primary_color": {
        "bsonType": "string"
      },
      "secondary_color": {
        "bsonType": "string"
      },
      "timezone": {
        "bsonType": "string"
      },
      "academic_year_start": {
        "bsonType": "number"
      },
      "grading_scale": {
        "bsonType": "object"
      },
      "contact_email": {
        "bsonType": "string"
      },
      "contact_phone": {
        "bsonType": "string"
      },
      "address_line1": {
        "bsonType": "string"
      },
      "address_line2": {
        "bsonType": "string"
      },
      "city": {
        "bsonType": "string"
      },
      "state_province": {
        "bsonType": "string"
      },
      "postal_code": {
        "bsonType": "string"
      },
      "country_code": {
        "bsonType": "string"
      },
      "student_count": {
        "bsonType": "number"
      },
      "instructor_count": {
        "bsonType": "number"
      },
      "course_count": {
        "bsonType": "number"
      },
      "subscription_tier": {
        "bsonType": "string"
      },
      "subscription_expires": {
        "bsonType": "date"
      },
      "storage_used_gb": {
        "bsonType": "decimal128"
      },
      "storage_limit_gb": {
        "bsonType": "decimal128"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for users
db.runCommand({
  collMod: 'users',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "password_hash",
      "first_name",
      "last_name"
    ],
    "properties": {
      "institution_id": {
        "bsonType": "number"
      },
      "password_hash": {
        "bsonType": "string"
      },
      "first_name": {
        "bsonType": "string"
      },
      "last_name": {
        "bsonType": "string"
      },
      "middle_name": {
        "bsonType": "string"
      },
      "display_name": {
        "bsonType": "string"
      },
      "user_type": {
        "bsonType": "string"
      },
      "student_id": {
        "bsonType": "string"
      },
      "employee_id": {
        "bsonType": "string"
      },
      "date_of_birth": {
        "bsonType": "date"
      },
      "gender": {
        "bsonType": "string"
      },
      "phone_number": {
        "bsonType": "string"
      },
      "phone_verified": {
        "bsonType": "boolean"
      },
      "email_verified": {
        "bsonType": "boolean"
      },
      "profile_picture_url": {
        "bsonType": "string"
      },
      "bio": {
        "bsonType": "string"
      },
      "preferred_language": {
        "bsonType": "string"
      },
      "timezone": {
        "bsonType": "string"
      },
      "notification_preferences": {
        "bsonType": "object"
      },
      "last_login_at": {
        "bsonType": "date"
      },
      "last_activity_at": {
        "bsonType": "date"
      },
      "login_count": {
        "bsonType": "number"
      },
      "failed_login_attempts": {
        "bsonType": "number"
      },
      "account_locked_until": {
        "bsonType": "date"
      },
      "two_factor_enabled": {
        "bsonType": "boolean"
      },
      "two_factor_secret": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "graduation_year": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for user_profiles
db.runCommand({
  collMod: 'user_profiles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "major": {
        "bsonType": "string"
      },
      "minor": {
        "bsonType": "string"
      },
      "gpa": {
        "bsonType": "decimal128"
      },
      "credits_earned": {
        "bsonType": "number"
      },
      "credits_required": {
        "bsonType": "number"
      },
      "expected_graduation": {
        "bsonType": "date"
      },
      "academic_standing": {
        "bsonType": "string"
      },
      "occupation": {
        "bsonType": "string"
      },
      "employer": {
        "bsonType": "string"
      },
      "years_experience": {
        "bsonType": "number"
      },
      "linkedin_url": {
        "bsonType": "string"
      },
      "portfolio_url": {
        "bsonType": "string"
      },
      "resume_url": {
        "bsonType": "string"
      },
      "learning_style": {
        "bsonType": "string"
      },
      "preferred_pace": {
        "bsonType": "string"
      },
      "interests": {
        "bsonType": "object"
      },
      "skills": {
        "bsonType": "object"
      },
      "certifications": {
        "bsonType": "object"
      },
      "accessibility_needs": {
        "bsonType": "object"
      },
      "accommodations_required": {
        "bsonType": "boolean"
      },
      "accommodations_details": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for roles
db.runCommand({
  collMod: 'roles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [],
    "properties": {
      "role_description": {
        "bsonType": "string"
      },
      "permissions": {
        "bsonType": "object"
      },
      "is_system_role": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for user_roles
db.runCommand({
  collMod: 'user_roles',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "role_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "role_id": {
        "bsonType": "number"
      },
      "assigned_by": {
        "bsonType": "number"
      },
      "valid_from": {
        "bsonType": "date"
      },
      "valid_until": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for departments
db.runCommand({
  collMod: 'departments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "institution_id",
      "department_code",
      "department_name"
    ],
    "properties": {
      "institution_id": {
        "bsonType": "number"
      },
      "department_code": {
        "bsonType": "string"
      },
      "department_name": {
        "bsonType": "string"
      },
      "department_head_id": {
        "bsonType": "number"
      },
      "description": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for academic_terms
db.runCommand({
  collMod: 'academic_terms',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "institution_id",
      "term_code",
      "term_name",
      "start_date",
      "end_date"
    ],
    "properties": {
      "institution_id": {
        "bsonType": "number"
      },
      "term_code": {
        "bsonType": "string"
      },
      "term_name": {
        "bsonType": "string"
      },
      "term_type": {
        "bsonType": "string"
      },
      "start_date": {
        "bsonType": "date"
      },
      "end_date": {
        "bsonType": "date"
      },
      "registration_start": {
        "bsonType": "date"
      },
      "registration_end": {
        "bsonType": "date"
      },
      "add_drop_deadline": {
        "bsonType": "date"
      },
      "withdrawal_deadline": {
        "bsonType": "date"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for courses
db.runCommand({
  collMod: 'courses',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "institution_id",
      "course_code",
      "course_name"
    ],
    "properties": {
      "institution_id": {
        "bsonType": "number"
      },
      "department_id": {
        "bsonType": "number"
      },
      "course_code": {
        "bsonType": "string"
      },
      "course_name": {
        "bsonType": "string"
      },
      "course_description": {
        "bsonType": "string"
      },
      "syllabus_url": {
        "bsonType": "string"
      },
      "credits": {
        "bsonType": "number"
      },
      "course_level": {
        "bsonType": "string"
      },
      "format": {
        "bsonType": "string"
      },
      "duration_weeks": {
        "bsonType": "number"
      },
      "hours_per_week": {
        "bsonType": "decimal128"
      },
      "max_students": {
        "bsonType": "number"
      },
      "min_students": {
        "bsonType": "number"
      },
      "prerequisites": {
        "bsonType": "object"
      },
      "corequisites": {
        "bsonType": "object"
      },
      "learning_outcomes": {
        "bsonType": "object"
      },
      "required_materials": {
        "bsonType": "object"
      },
      "tags": {
        "bsonType": "object"
      },
      "is_active": {
        "bsonType": "boolean"
      },
      "version": {
        "bsonType": "number"
      },
      "created_by": {
        "bsonType": "number"
      },
      "approved_by": {
        "bsonType": "number"
      },
      "approved_date": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for course_sections
db.runCommand({
  collMod: 'course_sections',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "course_id",
      "term_id",
      "section_code",
      "instructor_id"
    ],
    "properties": {
      "course_id": {
        "bsonType": "number"
      },
      "term_id": {
        "bsonType": "number"
      },
      "section_code": {
        "bsonType": "string"
      },
      "instructor_id": {
        "bsonType": "number"
      },
      "co_instructor_id": {
        "bsonType": "number"
      },
      "teaching_assistants": {
        "bsonType": "object"
      },
      "meeting_pattern": {
        "bsonType": "string"
      },
      "meeting_days": {
        "bsonType": "array"
      },
      "start_time": {
        "bsonType": "string"
      },
      "end_time": {
        "bsonType": "string"
      },
      "location": {
        "bsonType": "string"
      },
      "room_number": {
        "bsonType": "string"
      },
      "is_online": {
        "bsonType": "boolean"
      },
      "meeting_url": {
        "bsonType": "string"
      },
      "enrollment_capacity": {
        "bsonType": "number"
      },
      "enrollment_count": {
        "bsonType": "number"
      },
      "waitlist_capacity": {
        "bsonType": "number"
      },
      "waitlist_count": {
        "bsonType": "number"
      },
      "allow_auditing": {
        "bsonType": "boolean"
      },
      "allow_late_enrollment": {
        "bsonType": "boolean"
      },
      "require_attendance": {
        "bsonType": "boolean"
      },
      "record_lectures": {
        "bsonType": "boolean"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for course_modules
db.runCommand({
  collMod: 'course_modules',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "course_id",
      "module_number",
      "module_name",
      "sort_order"
    ],
    "properties": {
      "course_id": {
        "bsonType": "number"
      },
      "module_number": {
        "bsonType": "number"
      },
      "module_name": {
        "bsonType": "string"
      },
      "module_description": {
        "bsonType": "string"
      },
      "learning_objectives": {
        "bsonType": "object"
      },
      "estimated_hours": {
        "bsonType": "decimal128"
      },
      "is_published": {
        "bsonType": "boolean"
      },
      "unlock_date": {
        "bsonType": "date"
      },
      "due_date": {
        "bsonType": "date"
      },
      "sort_order": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for lessons
db.runCommand({
  collMod: 'lessons',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "module_id",
      "lesson_number",
      "lesson_name",
      "sort_order"
    ],
    "properties": {
      "module_id": {
        "bsonType": "number"
      },
      "lesson_number": {
        "bsonType": "number"
      },
      "lesson_name": {
        "bsonType": "string"
      },
      "lesson_type": {
        "bsonType": "string"
      },
      "content_url": {
        "bsonType": "string"
      },
      "content_html": {
        "bsonType": "string"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "is_required": {
        "bsonType": "boolean"
      },
      "is_published": {
        "bsonType": "boolean"
      },
      "allow_comments": {
        "bsonType": "boolean"
      },
      "completion_criteria": {
        "bsonType": "object"
      },
      "points_possible": {
        "bsonType": "number"
      },
      "sort_order": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for learning_resources
db.runCommand({
  collMod: 'learning_resources',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "resource_name"
    ],
    "properties": {
      "resource_type": {
        "bsonType": "string"
      },
      "resource_name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "url": {
        "bsonType": "string"
      },
      "file_path": {
        "bsonType": "string"
      },
      "file_size_mb": {
        "bsonType": "decimal128"
      },
      "mime_type": {
        "bsonType": "string"
      },
      "duration_seconds": {
        "bsonType": "number"
      },
      "thumbnail_url": {
        "bsonType": "string"
      },
      "tags": {
        "bsonType": "object"
      },
      "usage_count": {
        "bsonType": "number"
      },
      "created_by": {
        "bsonType": "number"
      },
      "is_public": {
        "bsonType": "boolean"
      },
      "license_type": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for lesson_resources
db.runCommand({
  collMod: 'lesson_resources',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "lesson_id",
      "resource_id"
    ],
    "properties": {
      "lesson_id": {
        "bsonType": "number"
      },
      "resource_id": {
        "bsonType": "number"
      },
      "is_required": {
        "bsonType": "boolean"
      },
      "sort_order": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for enrollments
db.runCommand({
  collMod: 'enrollments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "section_id",
      "user_id"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "enrollment_type": {
        "bsonType": "string"
      },
      "enrollment_status": {
        "bsonType": "string"
      },
      "enrollment_date": {
        "bsonType": "date"
      },
      "drop_date": {
        "bsonType": "date"
      },
      "completion_date": {
        "bsonType": "date"
      },
      "final_grade": {
        "bsonType": "string"
      },
      "grade_points": {
        "bsonType": "decimal128"
      },
      "credits_earned": {
        "bsonType": "decimal128"
      },
      "attendance_percentage": {
        "bsonType": "decimal128"
      },
      "last_accessed": {
        "bsonType": "date"
      },
      "access_count": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for prerequisite_overrides
db.runCommand({
  collMod: 'prerequisite_overrides',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "course_id",
      "overridden_by"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "course_id": {
        "bsonType": "number"
      },
      "overridden_by": {
        "bsonType": "number"
      },
      "reason": {
        "bsonType": "string"
      },
      "valid_until": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for lesson_progress
db.runCommand({
  collMod: 'lesson_progress',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "lesson_id",
      "section_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "lesson_id": {
        "bsonType": "number"
      },
      "section_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "progress_percentage": {
        "bsonType": "number"
      },
      "time_spent_seconds": {
        "bsonType": "number"
      },
      "last_position": {
        "bsonType": "number"
      },
      "completion_date": {
        "bsonType": "date"
      },
      "attempts": {
        "bsonType": "number"
      },
      "score": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for learning_paths
db.runCommand({
  collMod: 'learning_paths',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "path_name"
    ],
    "properties": {
      "path_name": {
        "bsonType": "string"
      },
      "path_description": {
        "bsonType": "string"
      },
      "target_role": {
        "bsonType": "string"
      },
      "skill_level": {
        "bsonType": "string"
      },
      "estimated_hours": {
        "bsonType": "number"
      },
      "courses": {
        "bsonType": "object"
      },
      "is_public": {
        "bsonType": "boolean"
      },
      "created_by": {
        "bsonType": "number"
      },
      "enrollment_count": {
        "bsonType": "number"
      },
      "completion_count": {
        "bsonType": "number"
      },
      "rating": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for user_learning_paths
db.runCommand({
  collMod: 'user_learning_paths',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "path_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "path_id": {
        "bsonType": "number"
      },
      "enrollment_date": {
        "bsonType": "date"
      },
      "target_completion_date": {
        "bsonType": "date"
      },
      "actual_completion_date": {
        "bsonType": "date"
      },
      "progress_percentage": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for assignments
db.runCommand({
  collMod: 'assignments',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "section_id",
      "title"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "assignment_type": {
        "bsonType": "string"
      },
      "title": {
        "bsonType": "string"
      },
      "instructions": {
        "bsonType": "string"
      },
      "attachments": {
        "bsonType": "object"
      },
      "points_possible": {
        "bsonType": "decimal128"
      },
      "weight_percentage": {
        "bsonType": "decimal128"
      },
      "due_date": {
        "bsonType": "date"
      },
      "available_from": {
        "bsonType": "date"
      },
      "available_until": {
        "bsonType": "date"
      },
      "time_limit_minutes": {
        "bsonType": "number"
      },
      "attempt_limit": {
        "bsonType": "number"
      },
      "show_correct_answers": {
        "bsonType": "boolean"
      },
      "show_correct_answers_at": {
        "bsonType": "date"
      },
      "shuffle_questions": {
        "bsonType": "boolean"
      },
      "shuffle_answers": {
        "bsonType": "boolean"
      },
      "require_lockdown_browser": {
        "bsonType": "boolean"
      },
      "require_proctoring": {
        "bsonType": "boolean"
      },
      "late_submission_allowed": {
        "bsonType": "boolean"
      },
      "late_penalty_percentage": {
        "bsonType": "decimal128"
      },
      "grace_period_hours": {
        "bsonType": "number"
      },
      "group_assignment": {
        "bsonType": "boolean"
      },
      "peer_review_required": {
        "bsonType": "boolean"
      },
      "rubric_id": {
        "bsonType": "number"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for questions
db.runCommand({
  collMod: 'questions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "question_text"
    ],
    "properties": {
      "assignment_id": {
        "bsonType": "number"
      },
      "question_type": {
        "bsonType": "string"
      },
      "question_text": {
        "bsonType": "string"
      },
      "question_html": {
        "bsonType": "string"
      },
      "media_url": {
        "bsonType": "string"
      },
      "correct_answer": {
        "bsonType": "object"
      },
      "answer_options": {
        "bsonType": "object"
      },
      "answer_explanation": {
        "bsonType": "string"
      },
      "points": {
        "bsonType": "decimal128"
      },
      "difficulty": {
        "bsonType": "string"
      },
      "time_estimate_seconds": {
        "bsonType": "number"
      },
      "tags": {
        "bsonType": "object"
      },
      "sort_order": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for question_bank
db.runCommand({
  collMod: 'question_bank',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "created_by",
      "question_text"
    ],
    "properties": {
      "created_by": {
        "bsonType": "number"
      },
      "subject": {
        "bsonType": "string"
      },
      "topic": {
        "bsonType": "string"
      },
      "question_type": {
        "bsonType": "string"
      },
      "question_text": {
        "bsonType": "string"
      },
      "correct_answer": {
        "bsonType": "object"
      },
      "answer_options": {
        "bsonType": "object"
      },
      "difficulty": {
        "bsonType": "string"
      },
      "usage_count": {
        "bsonType": "number"
      },
      "success_rate": {
        "bsonType": "decimal128"
      },
      "is_public": {
        "bsonType": "boolean"
      },
      "tags": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for rubrics
db.runCommand({
  collMod: 'rubrics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "rubric_name",
      "created_by"
    ],
    "properties": {
      "rubric_name": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "created_by": {
        "bsonType": "number"
      },
      "is_public": {
        "bsonType": "boolean"
      },
      "criteria": {
        "bsonType": "object"
      },
      "total_points": {
        "bsonType": "decimal128"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for submissions
db.runCommand({
  collMod: 'submissions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "assignment_id",
      "user_id"
    ],
    "properties": {
      "assignment_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "group_id": {
        "bsonType": "number"
      },
      "attempt_number": {
        "bsonType": "number"
      },
      "submission_type": {
        "bsonType": "string"
      },
      "submission_text": {
        "bsonType": "string"
      },
      "submission_files": {
        "bsonType": "object"
      },
      "submission_url": {
        "bsonType": "string"
      },
      "quiz_answers": {
        "bsonType": "object"
      },
      "submitted_at": {
        "bsonType": "date"
      },
      "late_submission": {
        "bsonType": "boolean"
      },
      "time_spent_seconds": {
        "bsonType": "number"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "browser_info": {
        "bsonType": "string"
      },
      "score": {
        "bsonType": "decimal128"
      },
      "grade": {
        "bsonType": "string"
      },
      "graded_by": {
        "bsonType": "number"
      },
      "graded_at": {
        "bsonType": "date"
      },
      "feedback": {
        "bsonType": "string"
      },
      "rubric_scores": {
        "bsonType": "object"
      },
      "similarity_score": {
        "bsonType": "decimal128"
      },
      "similarity_report_url": {
        "bsonType": "string"
      },
      "status": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for gradebook
db.runCommand({
  collMod: 'gradebook',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "section_id",
      "user_id"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "homework_score": {
        "bsonType": "decimal128"
      },
      "quiz_score": {
        "bsonType": "decimal128"
      },
      "exam_score": {
        "bsonType": "decimal128"
      },
      "project_score": {
        "bsonType": "decimal128"
      },
      "participation_score": {
        "bsonType": "decimal128"
      },
      "total_points_earned": {
        "bsonType": "decimal128"
      },
      "total_points_possible": {
        "bsonType": "decimal128"
      },
      "percentage_score": {
        "bsonType": "decimal128"
      },
      "letter_grade": {
        "bsonType": "string"
      },
      "grade_points": {
        "bsonType": "decimal128"
      },
      "assignments_completed": {
        "bsonType": "number"
      },
      "assignments_total": {
        "bsonType": "number"
      },
      "attendance_score": {
        "bsonType": "decimal128"
      },
      "extra_credit": {
        "bsonType": "decimal128"
      },
      "grade_status": {
        "bsonType": "string"
      },
      "last_calculated": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for grade_history
db.runCommand({
  collMod: 'grade_history',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "submission_id",
      "changed_by"
    ],
    "properties": {
      "submission_id": {
        "bsonType": "number"
      },
      "changed_by": {
        "bsonType": "number"
      },
      "old_score": {
        "bsonType": "decimal128"
      },
      "new_score": {
        "bsonType": "decimal128"
      },
      "old_grade": {
        "bsonType": "string"
      },
      "new_grade": {
        "bsonType": "string"
      },
      "change_reason": {
        "bsonType": "string"
      },
      "changed_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for discussions
db.runCommand({
  collMod: 'discussions',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "title",
      "created_by"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "title": {
        "bsonType": "string"
      },
      "description": {
        "bsonType": "string"
      },
      "discussion_type": {
        "bsonType": "string"
      },
      "is_pinned": {
        "bsonType": "boolean"
      },
      "is_locked": {
        "bsonType": "boolean"
      },
      "allow_anonymous": {
        "bsonType": "boolean"
      },
      "require_post_before_view": {
        "bsonType": "boolean"
      },
      "created_by": {
        "bsonType": "number"
      },
      "post_count": {
        "bsonType": "number"
      },
      "last_post_at": {
        "bsonType": "date"
      },
      "created_at": {
        "bsonType": "date"
      },
      "updated_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for discussion_posts
db.runCommand({
  collMod: 'discussion_posts',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "discussion_id",
      "user_id",
      "post_content"
    ],
    "properties": {
      "discussion_id": {
        "bsonType": "number"
      },
      "parent_post_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "post_content": {
        "bsonType": "string"
      },
      "is_anonymous": {
        "bsonType": "boolean"
      },
      "is_answer": {
        "bsonType": "boolean"
      },
      "upvotes": {
        "bsonType": "number"
      },
      "downvotes": {
        "bsonType": "number"
      },
      "is_edited": {
        "bsonType": "boolean"
      },
      "edited_at": {
        "bsonType": "date"
      },
      "is_deleted": {
        "bsonType": "boolean"
      },
      "deleted_at": {
        "bsonType": "date"
      },
      "deleted_by": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for messages
db.runCommand({
  collMod: 'messages',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "sender_id",
      "recipient_id",
      "message_body"
    ],
    "properties": {
      "sender_id": {
        "bsonType": "number"
      },
      "recipient_id": {
        "bsonType": "number"
      },
      "subject": {
        "bsonType": "string"
      },
      "message_body": {
        "bsonType": "string"
      },
      "attachments": {
        "bsonType": "object"
      },
      "is_read": {
        "bsonType": "boolean"
      },
      "read_at": {
        "bsonType": "date"
      },
      "is_deleted_sender": {
        "bsonType": "boolean"
      },
      "is_deleted_recipient": {
        "bsonType": "boolean"
      },
      "priority": {
        "bsonType": "string"
      },
      "created_at": {
        "bsonType": "date"
      },
      "FULLTEXT": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for announcements
db.runCommand({
  collMod: 'announcements',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "title",
      "content",
      "created_by"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "institution_id": {
        "bsonType": "number"
      },
      "title": {
        "bsonType": "string"
      },
      "content": {
        "bsonType": "string"
      },
      "announcement_type": {
        "bsonType": "string"
      },
      "target_audience": {
        "bsonType": "string"
      },
      "target_users": {
        "bsonType": "object"
      },
      "publish_date": {
        "bsonType": "date"
      },
      "expire_date": {
        "bsonType": "date"
      },
      "created_by": {
        "bsonType": "number"
      },
      "view_count": {
        "bsonType": "number"
      },
      "acknowledgment_required": {
        "bsonType": "boolean"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for attendance
db.runCommand({
  collMod: 'attendance',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "section_id",
      "user_id",
      "attendance_date"
    ],
    "properties": {
      "section_id": {
        "bsonType": "number"
      },
      "user_id": {
        "bsonType": "number"
      },
      "attendance_date": {
        "bsonType": "date"
      },
      "status": {
        "bsonType": "string"
      },
      "check_in_time": {
        "bsonType": "date"
      },
      "check_out_time": {
        "bsonType": "date"
      },
      "duration_minutes": {
        "bsonType": "number"
      },
      "location_verified": {
        "bsonType": "boolean"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "notes": {
        "bsonType": "string"
      },
      "recorded_by": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for activity_logs
db.runCommand({
  collMod: 'activity_logs',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "activity_type": {
        "bsonType": "string"
      },
      "resource_type": {
        "bsonType": "string"
      },
      "resource_id": {
        "bsonType": "number"
      },
      "details": {
        "bsonType": "object"
      },
      "ip_address": {
        "bsonType": "string"
      },
      "user_agent": {
        "bsonType": "string"
      },
      "session_id": {
        "bsonType": "string"
      },
      "duration_seconds": {
        "bsonType": "number"
      },
      "created_at": {
        "bsonType": "date"
      },
      "PARTITION": {
        "bsonType": "string"
      }
    }
  }
}
});

// Validation for learning_analytics
db.runCommand({
  collMod: 'learning_analytics',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "section_id",
      "week_number"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "section_id": {
        "bsonType": "number"
      },
      "week_number": {
        "bsonType": "number"
      },
      "login_count": {
        "bsonType": "number"
      },
      "total_time_minutes": {
        "bsonType": "number"
      },
      "content_views": {
        "bsonType": "number"
      },
      "video_watch_minutes": {
        "bsonType": "number"
      },
      "discussion_posts": {
        "bsonType": "number"
      },
      "assignment_submissions": {
        "bsonType": "number"
      },
      "average_score": {
        "bsonType": "decimal128"
      },
      "completion_rate": {
        "bsonType": "decimal128"
      },
      "on_time_submission_rate": {
        "bsonType": "decimal128"
      },
      "risk_level": {
        "bsonType": "string"
      },
      "predicted_grade": {
        "bsonType": "string"
      },
      "engagement_score": {
        "bsonType": "decimal128"
      },
      "calculated_at": {
        "bsonType": "date"
      }
    }
  }
}
});

// Validation for certificates
db.runCommand({
  collMod: 'certificates',
  validator: {
  "$jsonSchema": {
    "bsonType": "object",
    "required": [
      "user_id",
      "certificate_name",
      "issued_date"
    ],
    "properties": {
      "user_id": {
        "bsonType": "number"
      },
      "course_id": {
        "bsonType": "number"
      },
      "certificate_type": {
        "bsonType": "string"
      },
      "certificate_name": {
        "bsonType": "string"
      },
      "certificate_url": {
        "bsonType": "string"
      },
      "issued_date": {
        "bsonType": "date"
      },
      "expiry_date": {
        "bsonType": "date"
      },
      "issuer_name": {
        "bsonType": "string"
      },
      "issuer_signature_url": {
        "bsonType": "string"
      },
      "metadata": {
        "bsonType": "object"
      },
      "created_at": {
        "bsonType": "date"
      }
    }
  }
}
});
