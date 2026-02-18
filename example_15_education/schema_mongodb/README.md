# MongoDB Schema for example_15_education

Converted from MySQL on 2026-02-17T23:16:48.834855

## Collections

### institutions

**Document Structure:**
```json
{
  "institution_name": {
    "type": "String",
    "required": true
  },
  "institution_type": {
    "type": "String",
    "required": false
  },
  "website_url": {
    "type": "String",
    "required": false
  },
  "logo_url": {
    "type": "String",
    "required": false
  },
  "primary_color": {
    "type": "String",
    "required": false
  },
  "secondary_color": {
    "type": "String",
    "required": false
  },
  "timezone": {
    "type": "String",
    "required": false,
    "default": "UTC"
  },
  "academic_year_start": {
    "type": "Number",
    "required": false,
    "default": "9"
  },
  "grading_scale": {
    "type": "Object",
    "required": false
  },
  "contact_email": {
    "type": "String",
    "required": false
  },
  "contact_phone": {
    "type": "String",
    "required": false
  },
  "address_line1": {
    "type": "String",
    "required": false
  },
  "address_line2": {
    "type": "String",
    "required": false
  },
  "city": {
    "type": "String",
    "required": false
  },
  "state_province": {
    "type": "String",
    "required": false
  },
  "postal_code": {
    "type": "String",
    "required": false
  },
  "country_code": {
    "type": "String",
    "required": false
  },
  "student_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "instructor_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "course_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "subscription_tier": {
    "type": "String",
    "required": false
  },
  "subscription_expires": {
    "type": "Date",
    "required": false
  },
  "storage_used_gb": {
    "type": "Decimal128",
    "required": false
  },
  "storage_limit_gb": {
    "type": "Decimal128",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### users

**Document Structure:**
```json
{
  "institution_id": {
    "type": "Number",
    "required": false
  },
  "password_hash": {
    "type": "String",
    "required": true
  },
  "first_name": {
    "type": "String",
    "required": true
  },
  "last_name": {
    "type": "String",
    "required": true
  },
  "middle_name": {
    "type": "String",
    "required": false
  },
  "display_name": {
    "type": "String",
    "required": false
  },
  "user_type": {
    "type": "String",
    "required": false
  },
  "student_id": {
    "type": "String",
    "required": false
  },
  "employee_id": {
    "type": "String",
    "required": false
  },
  "date_of_birth": {
    "type": "Date",
    "required": false
  },
  "gender": {
    "type": "String",
    "required": false
  },
  "phone_number": {
    "type": "String",
    "required": false
  },
  "phone_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "email_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "profile_picture_url": {
    "type": "String",
    "required": false
  },
  "bio": {
    "type": "String",
    "required": false
  },
  "preferred_language": {
    "type": "String",
    "required": false,
    "default": "en"
  },
  "timezone": {
    "type": "String",
    "required": false
  },
  "notification_preferences": {
    "type": "Object",
    "required": false
  },
  "last_login_at": {
    "type": "Date",
    "required": false
  },
  "last_activity_at": {
    "type": "Date",
    "required": false
  },
  "login_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "failed_login_attempts": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "account_locked_until": {
    "type": "Date",
    "required": false
  },
  "two_factor_enabled": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "two_factor_secret": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "graduation_year": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** institutions_id

### user_profiles

**Document Structure:**
```json
{
  "major": {
    "type": "String",
    "required": false
  },
  "minor": {
    "type": "String",
    "required": false
  },
  "gpa": {
    "type": "Decimal128",
    "required": false
  },
  "credits_earned": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "credits_required": {
    "type": "Number",
    "required": false
  },
  "expected_graduation": {
    "type": "Date",
    "required": false
  },
  "academic_standing": {
    "type": "String",
    "required": false
  },
  "occupation": {
    "type": "String",
    "required": false
  },
  "employer": {
    "type": "String",
    "required": false
  },
  "years_experience": {
    "type": "Number",
    "required": false
  },
  "linkedin_url": {
    "type": "String",
    "required": false
  },
  "portfolio_url": {
    "type": "String",
    "required": false
  },
  "resume_url": {
    "type": "String",
    "required": false
  },
  "learning_style": {
    "type": "String",
    "required": false
  },
  "preferred_pace": {
    "type": "String",
    "required": false
  },
  "interests": {
    "type": "Object",
    "required": false
  },
  "skills": {
    "type": "Object",
    "required": false
  },
  "certifications": {
    "type": "Object",
    "required": false
  },
  "accessibility_needs": {
    "type": "Object",
    "required": false
  },
  "accommodations_required": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "accommodations_details": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### roles

**Document Structure:**
```json
{
  "role_description": {
    "type": "String",
    "required": false
  },
  "permissions": {
    "type": "Object",
    "required": false
  },
  "is_system_role": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

### user_roles

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "role_id": {
    "type": "Number",
    "required": true
  },
  "assigned_by": {
    "type": "Number",
    "required": false
  },
  "valid_from": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "valid_until": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, roles_id, users_id

### departments

**Document Structure:**
```json
{
  "institution_id": {
    "type": "Number",
    "required": true
  },
  "department_code": {
    "type": "String",
    "required": true
  },
  "department_name": {
    "type": "String",
    "required": true
  },
  "department_head_id": {
    "type": "Number",
    "required": false
  },
  "description": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** institutions_id, users_id

### academic_terms

**Document Structure:**
```json
{
  "institution_id": {
    "type": "Number",
    "required": true
  },
  "term_code": {
    "type": "String",
    "required": true
  },
  "term_name": {
    "type": "String",
    "required": true
  },
  "term_type": {
    "type": "String",
    "required": false
  },
  "start_date": {
    "type": "Date",
    "required": true
  },
  "end_date": {
    "type": "Date",
    "required": true
  },
  "registration_start": {
    "type": "Date",
    "required": false
  },
  "registration_end": {
    "type": "Date",
    "required": false
  },
  "add_drop_deadline": {
    "type": "Date",
    "required": false
  },
  "withdrawal_deadline": {
    "type": "Date",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** institutions_id

### courses

**Document Structure:**
```json
{
  "institution_id": {
    "type": "Number",
    "required": true
  },
  "department_id": {
    "type": "Number",
    "required": false
  },
  "course_code": {
    "type": "String",
    "required": true
  },
  "course_name": {
    "type": "String",
    "required": true
  },
  "course_description": {
    "type": "String",
    "required": false
  },
  "syllabus_url": {
    "type": "String",
    "required": false
  },
  "credits": {
    "type": "Number",
    "required": false,
    "default": "3"
  },
  "course_level": {
    "type": "String",
    "required": false
  },
  "format": {
    "type": "String",
    "required": false
  },
  "duration_weeks": {
    "type": "Number",
    "required": false
  },
  "hours_per_week": {
    "type": "Decimal128",
    "required": false
  },
  "max_students": {
    "type": "Number",
    "required": false,
    "default": "30"
  },
  "min_students": {
    "type": "Number",
    "required": false,
    "default": "5"
  },
  "prerequisites": {
    "type": "Object",
    "required": false
  },
  "corequisites": {
    "type": "Object",
    "required": false
  },
  "learning_outcomes": {
    "type": "Object",
    "required": false
  },
  "required_materials": {
    "type": "Object",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "is_active": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "version": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "created_by": {
    "type": "Number",
    "required": false
  },
  "approved_by": {
    "type": "Number",
    "required": false
  },
  "approved_date": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** institutions_id, departments_id, users_id, users_id

### course_sections

**Document Structure:**
```json
{
  "course_id": {
    "type": "Number",
    "required": true
  },
  "term_id": {
    "type": "Number",
    "required": true
  },
  "section_code": {
    "type": "String",
    "required": true
  },
  "instructor_id": {
    "type": "Number",
    "required": true
  },
  "co_instructor_id": {
    "type": "Number",
    "required": false
  },
  "teaching_assistants": {
    "type": "Object",
    "required": false
  },
  "meeting_pattern": {
    "type": "String",
    "required": false
  },
  "meeting_days": {
    "type": "Array",
    "required": false
  },
  "start_time": {
    "type": "String",
    "required": false
  },
  "end_time": {
    "type": "String",
    "required": false
  },
  "location": {
    "type": "String",
    "required": false
  },
  "room_number": {
    "type": "String",
    "required": false
  },
  "is_online": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "meeting_url": {
    "type": "String",
    "required": false
  },
  "enrollment_capacity": {
    "type": "Number",
    "required": false,
    "default": "30"
  },
  "enrollment_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "waitlist_capacity": {
    "type": "Number",
    "required": false,
    "default": "10"
  },
  "waitlist_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "allow_auditing": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "allow_late_enrollment": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "require_attendance": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "record_lectures": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** courses_id, academic_terms_id, users_id, users_id

### course_modules

**Document Structure:**
```json
{
  "course_id": {
    "type": "Number",
    "required": true
  },
  "module_number": {
    "type": "Number",
    "required": true
  },
  "module_name": {
    "type": "String",
    "required": true
  },
  "module_description": {
    "type": "String",
    "required": false
  },
  "learning_objectives": {
    "type": "Object",
    "required": false
  },
  "estimated_hours": {
    "type": "Decimal128",
    "required": false
  },
  "is_published": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "unlock_date": {
    "type": "Date",
    "required": false
  },
  "due_date": {
    "type": "Date",
    "required": false
  },
  "sort_order": {
    "type": "Number",
    "required": true
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** courses_id

### lessons

**Document Structure:**
```json
{
  "module_id": {
    "type": "Number",
    "required": true
  },
  "lesson_number": {
    "type": "Number",
    "required": true
  },
  "lesson_name": {
    "type": "String",
    "required": true
  },
  "lesson_type": {
    "type": "String",
    "required": false
  },
  "content_url": {
    "type": "String",
    "required": false
  },
  "content_html": {
    "type": "String",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "is_required": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "is_published": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "allow_comments": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "completion_criteria": {
    "type": "Object",
    "required": false
  },
  "points_possible": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "sort_order": {
    "type": "Number",
    "required": true
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_modules_id

### learning_resources

**Document Structure:**
```json
{
  "resource_type": {
    "type": "String",
    "required": false
  },
  "resource_name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "url": {
    "type": "String",
    "required": false
  },
  "file_path": {
    "type": "String",
    "required": false
  },
  "file_size_mb": {
    "type": "Decimal128",
    "required": false
  },
  "mime_type": {
    "type": "String",
    "required": false
  },
  "duration_seconds": {
    "type": "Number",
    "required": false
  },
  "thumbnail_url": {
    "type": "String",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "usage_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "created_by": {
    "type": "Number",
    "required": false
  },
  "is_public": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "license_type": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** users_id

### lesson_resources

**Document Structure:**
```json
{
  "lesson_id": {
    "type": "Number",
    "required": true
  },
  "resource_id": {
    "type": "Number",
    "required": true
  },
  "is_required": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "sort_order": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** lessons_id, learning_resources_id

### enrollments

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "enrollment_type": {
    "type": "String",
    "required": false
  },
  "enrollment_status": {
    "type": "String",
    "required": false
  },
  "enrollment_date": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "drop_date": {
    "type": "Date",
    "required": false
  },
  "completion_date": {
    "type": "Date",
    "required": false
  },
  "final_grade": {
    "type": "String",
    "required": false
  },
  "grade_points": {
    "type": "Decimal128",
    "required": false
  },
  "credits_earned": {
    "type": "Decimal128",
    "required": false
  },
  "attendance_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "last_accessed": {
    "type": "Date",
    "required": false
  },
  "access_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_sections_id, users_id

### prerequisite_overrides

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "course_id": {
    "type": "Number",
    "required": true
  },
  "overridden_by": {
    "type": "Number",
    "required": true
  },
  "reason": {
    "type": "String",
    "required": false
  },
  "valid_until": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, courses_id, users_id

### lesson_progress

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "lesson_id": {
    "type": "Number",
    "required": true
  },
  "section_id": {
    "type": "Number",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "progress_percentage": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "time_spent_seconds": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "last_position": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "completion_date": {
    "type": "Date",
    "required": false
  },
  "attempts": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "score": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, lessons_id, course_sections_id

### learning_paths

**Document Structure:**
```json
{
  "path_name": {
    "type": "String",
    "required": true
  },
  "path_description": {
    "type": "String",
    "required": false
  },
  "target_role": {
    "type": "String",
    "required": false
  },
  "skill_level": {
    "type": "String",
    "required": false
  },
  "estimated_hours": {
    "type": "Number",
    "required": false
  },
  "courses": {
    "type": "Object",
    "required": false
  },
  "is_public": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "created_by": {
    "type": "Number",
    "required": false
  },
  "enrollment_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "completion_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "rating": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** users_id

### user_learning_paths

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "path_id": {
    "type": "Number",
    "required": true
  },
  "enrollment_date": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "target_completion_date": {
    "type": "Date",
    "required": false
  },
  "actual_completion_date": {
    "type": "Date",
    "required": false
  },
  "progress_percentage": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, learning_paths_id

### assignments

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": true
  },
  "assignment_type": {
    "type": "String",
    "required": false
  },
  "title": {
    "type": "String",
    "required": true
  },
  "instructions": {
    "type": "String",
    "required": false
  },
  "attachments": {
    "type": "Object",
    "required": false
  },
  "points_possible": {
    "type": "Decimal128",
    "required": false
  },
  "weight_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "due_date": {
    "type": "Date",
    "required": false
  },
  "available_from": {
    "type": "Date",
    "required": false
  },
  "available_until": {
    "type": "Date",
    "required": false
  },
  "time_limit_minutes": {
    "type": "Number",
    "required": false
  },
  "attempt_limit": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "show_correct_answers": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "show_correct_answers_at": {
    "type": "Date",
    "required": false
  },
  "shuffle_questions": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "shuffle_answers": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "require_lockdown_browser": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "require_proctoring": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "late_submission_allowed": {
    "type": "Boolean",
    "required": false,
    "default": "TRUE"
  },
  "late_penalty_percentage": {
    "type": "Decimal128",
    "required": false
  },
  "grace_period_hours": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "group_assignment": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "peer_review_required": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "rubric_id": {
    "type": "Number",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_sections_id

### questions

**Document Structure:**
```json
{
  "assignment_id": {
    "type": "Number",
    "required": false
  },
  "question_type": {
    "type": "String",
    "required": false
  },
  "question_text": {
    "type": "String",
    "required": true
  },
  "question_html": {
    "type": "String",
    "required": false
  },
  "media_url": {
    "type": "String",
    "required": false
  },
  "correct_answer": {
    "type": "Object",
    "required": false
  },
  "answer_options": {
    "type": "Object",
    "required": false
  },
  "answer_explanation": {
    "type": "String",
    "required": false
  },
  "points": {
    "type": "Decimal128",
    "required": false
  },
  "difficulty": {
    "type": "String",
    "required": false
  },
  "time_estimate_seconds": {
    "type": "Number",
    "required": false
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "sort_order": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** assignments_id

### question_bank

**Document Structure:**
```json
{
  "created_by": {
    "type": "Number",
    "required": true
  },
  "subject": {
    "type": "String",
    "required": false
  },
  "topic": {
    "type": "String",
    "required": false
  },
  "question_type": {
    "type": "String",
    "required": false
  },
  "question_text": {
    "type": "String",
    "required": true
  },
  "correct_answer": {
    "type": "Object",
    "required": false
  },
  "answer_options": {
    "type": "Object",
    "required": false
  },
  "difficulty": {
    "type": "String",
    "required": false
  },
  "usage_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "success_rate": {
    "type": "Decimal128",
    "required": false
  },
  "is_public": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "tags": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** users_id

### rubrics

**Document Structure:**
```json
{
  "rubric_name": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "created_by": {
    "type": "Number",
    "required": true
  },
  "is_public": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "criteria": {
    "type": "Object",
    "required": false
  },
  "total_points": {
    "type": "Decimal128",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### submissions

**Document Structure:**
```json
{
  "assignment_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "group_id": {
    "type": "Number",
    "required": false
  },
  "attempt_number": {
    "type": "Number",
    "required": false,
    "default": "1"
  },
  "submission_type": {
    "type": "String",
    "required": false
  },
  "submission_text": {
    "type": "String",
    "required": false
  },
  "submission_files": {
    "type": "Object",
    "required": false
  },
  "submission_url": {
    "type": "String",
    "required": false
  },
  "quiz_answers": {
    "type": "Object",
    "required": false
  },
  "submitted_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "late_submission": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "time_spent_seconds": {
    "type": "Number",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "browser_info": {
    "type": "String",
    "required": false
  },
  "score": {
    "type": "Decimal128",
    "required": false
  },
  "grade": {
    "type": "String",
    "required": false
  },
  "graded_by": {
    "type": "Number",
    "required": false
  },
  "graded_at": {
    "type": "Date",
    "required": false
  },
  "feedback": {
    "type": "String",
    "required": false
  },
  "rubric_scores": {
    "type": "Object",
    "required": false
  },
  "similarity_score": {
    "type": "Decimal128",
    "required": false
  },
  "similarity_report_url": {
    "type": "String",
    "required": false
  },
  "status": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** assignments_id, users_id, users_id

### gradebook

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "homework_score": {
    "type": "Decimal128",
    "required": false
  },
  "quiz_score": {
    "type": "Decimal128",
    "required": false
  },
  "exam_score": {
    "type": "Decimal128",
    "required": false
  },
  "project_score": {
    "type": "Decimal128",
    "required": false
  },
  "participation_score": {
    "type": "Decimal128",
    "required": false
  },
  "total_points_earned": {
    "type": "Decimal128",
    "required": false
  },
  "total_points_possible": {
    "type": "Decimal128",
    "required": false
  },
  "percentage_score": {
    "type": "Decimal128",
    "required": false
  },
  "letter_grade": {
    "type": "String",
    "required": false
  },
  "grade_points": {
    "type": "Decimal128",
    "required": false
  },
  "assignments_completed": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "assignments_total": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "attendance_score": {
    "type": "Decimal128",
    "required": false
  },
  "extra_credit": {
    "type": "Decimal128",
    "required": false
  },
  "grade_status": {
    "type": "String",
    "required": false
  },
  "last_calculated": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_sections_id, users_id

### grade_history

**Document Structure:**
```json
{
  "submission_id": {
    "type": "Number",
    "required": true
  },
  "changed_by": {
    "type": "Number",
    "required": true
  },
  "old_score": {
    "type": "Decimal128",
    "required": false
  },
  "new_score": {
    "type": "Decimal128",
    "required": false
  },
  "old_grade": {
    "type": "String",
    "required": false
  },
  "new_grade": {
    "type": "String",
    "required": false
  },
  "change_reason": {
    "type": "String",
    "required": false
  },
  "changed_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** submissions_id, users_id

### discussions

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": false
  },
  "title": {
    "type": "String",
    "required": true
  },
  "description": {
    "type": "String",
    "required": false
  },
  "discussion_type": {
    "type": "String",
    "required": false
  },
  "is_pinned": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_locked": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "allow_anonymous": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "require_post_before_view": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_by": {
    "type": "Number",
    "required": true
  },
  "post_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "last_post_at": {
    "type": "Date",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  }
}
```

**References:** course_sections_id, users_id

### discussion_posts

**Document Structure:**
```json
{
  "discussion_id": {
    "type": "Number",
    "required": true
  },
  "parent_post_id": {
    "type": "Number",
    "required": false
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "post_content": {
    "type": "String",
    "required": true
  },
  "is_anonymous": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_answer": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "upvotes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "downvotes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "is_edited": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "edited_at": {
    "type": "Date",
    "required": false
  },
  "is_deleted": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "deleted_at": {
    "type": "Date",
    "required": false
  },
  "deleted_by": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** discussions_id, discussion_posts_id, users_id, users_id

### messages

**Document Structure:**
```json
{
  "sender_id": {
    "type": "Number",
    "required": true
  },
  "recipient_id": {
    "type": "Number",
    "required": true
  },
  "subject": {
    "type": "String",
    "required": false
  },
  "message_body": {
    "type": "String",
    "required": true
  },
  "attachments": {
    "type": "Object",
    "required": false
  },
  "is_read": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "read_at": {
    "type": "Date",
    "required": false
  },
  "is_deleted_sender": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "is_deleted_recipient": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "priority": {
    "type": "String",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "FULLTEXT": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, users_id

### announcements

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": false
  },
  "institution_id": {
    "type": "Number",
    "required": false
  },
  "title": {
    "type": "String",
    "required": true
  },
  "content": {
    "type": "String",
    "required": true
  },
  "announcement_type": {
    "type": "String",
    "required": false
  },
  "target_audience": {
    "type": "String",
    "required": false
  },
  "target_users": {
    "type": "Object",
    "required": false
  },
  "publish_date": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "expire_date": {
    "type": "Date",
    "required": false
  },
  "created_by": {
    "type": "Number",
    "required": true
  },
  "view_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "acknowledgment_required": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_sections_id, institutions_id, users_id

### attendance

**Document Structure:**
```json
{
  "section_id": {
    "type": "Number",
    "required": true
  },
  "user_id": {
    "type": "Number",
    "required": true
  },
  "attendance_date": {
    "type": "Date",
    "required": true
  },
  "status": {
    "type": "String",
    "required": false
  },
  "check_in_time": {
    "type": "Date",
    "required": false
  },
  "check_out_time": {
    "type": "Date",
    "required": false
  },
  "duration_minutes": {
    "type": "Number",
    "required": false
  },
  "location_verified": {
    "type": "Boolean",
    "required": false,
    "default": "FALSE"
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "notes": {
    "type": "String",
    "required": false
  },
  "recorded_by": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** course_sections_id, users_id, users_id

### activity_logs

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "activity_type": {
    "type": "String",
    "required": false
  },
  "resource_type": {
    "type": "String",
    "required": false
  },
  "resource_id": {
    "type": "Number",
    "required": false
  },
  "details": {
    "type": "Object",
    "required": false
  },
  "ip_address": {
    "type": "String",
    "required": false
  },
  "user_agent": {
    "type": "String",
    "required": false
  },
  "session_id": {
    "type": "String",
    "required": false
  },
  "duration_seconds": {
    "type": "Number",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "PARTITION": {
    "type": "String",
    "required": false
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id

### learning_analytics

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "section_id": {
    "type": "Number",
    "required": true
  },
  "week_number": {
    "type": "Number",
    "required": true
  },
  "login_count": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "total_time_minutes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "content_views": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "video_watch_minutes": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "discussion_posts": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "assignment_submissions": {
    "type": "Number",
    "required": false,
    "default": "0"
  },
  "average_score": {
    "type": "Decimal128",
    "required": false
  },
  "completion_rate": {
    "type": "Decimal128",
    "required": false
  },
  "on_time_submission_rate": {
    "type": "Decimal128",
    "required": false
  },
  "risk_level": {
    "type": "String",
    "required": false
  },
  "predicted_grade": {
    "type": "String",
    "required": false
  },
  "engagement_score": {
    "type": "Decimal128",
    "required": false
  },
  "calculated_at": {
    "type": "Date",
    "required": false,
    "default": "CURRENT_TIMESTAMP"
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, course_sections_id

### certificates

**Document Structure:**
```json
{
  "user_id": {
    "type": "Number",
    "required": true
  },
  "course_id": {
    "type": "Number",
    "required": false
  },
  "certificate_type": {
    "type": "String",
    "required": false
  },
  "certificate_name": {
    "type": "String",
    "required": true
  },
  "certificate_url": {
    "type": "String",
    "required": false
  },
  "issued_date": {
    "type": "Date",
    "required": true
  },
  "expiry_date": {
    "type": "Date",
    "required": false
  },
  "issuer_name": {
    "type": "String",
    "required": false
  },
  "issuer_signature_url": {
    "type": "String",
    "required": false
  },
  "metadata": {
    "type": "Object",
    "required": false
  },
  "created_at": {
    "type": "Date",
    "default": "new Date()"
  },
  "updated_at": {
    "type": "Date",
    "default": "new Date()"
  }
}
```

**References:** users_id, courses_id

