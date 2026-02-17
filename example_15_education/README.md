# 🎓 Education & Learning Management System (LMS)

A comprehensive MySQL database schema for modern educational platforms, supporting K-12, higher education, and corporate training with multi-modal learning, assessments, analytics, and compliance features.

## 📊 Database Overview

- **Industry**: Education Technology (EdTech)
- **Complexity**: Very High
- **Tables**: 33
- **Key Features**: Course Management, Learning Paths, Assessments, Analytics, FERPA Compliance
- **Data Generator**: ✅ Available

## 🗂️ Schema Structure

### Institution & User Management (6 tables)

1. **institutions** - Educational organizations
   - Multi-type support (K-12, University, Corporate, Online)
   - Subscription tiers and storage management
   - Custom branding and theming
   - Academic calendar configuration
   - Grading scale customization

2. **users** - System users
   - User types (Student, Instructor, Admin, Parent)
   - Profile information and preferences
   - Authentication and security settings
   - Activity tracking
   - Multi-institution support

3. **user_profiles** - Extended user information
   - Academic records (major, minor, GPA)
   - Emergency contacts
   - Skills and interests
   - Social learning preferences
   - Portfolio links

4. **roles** - Permission management
   - Hierarchical role structure
   - Granular permissions
   - Custom role creation
   - Institution-specific roles

5. **user_roles** - Role assignments
   - Multiple roles per user
   - Time-bounded assignments
   - Delegation capabilities
   - Approval workflows

6. **departments** - Organizational units
   - Academic departments
   - Administrative divisions
   - Course ownership
   - Budget allocation

### Academic Structure (2 tables)

7. **academic_terms** - Semesters/quarters
   - Term scheduling
   - Registration periods
   - Grade submission deadlines
   - Holiday management
   - Session types (regular, summer, winter)

8. **courses** - Course catalog
   - Course codes and credits
   - Delivery modes (online, hybrid, in-person)
   - Capacity management
   - Prerequisites and corequisites
   - Learning outcomes mapping

### Course Content (5 tables)

9. **course_sections** - Class instances
   - Section scheduling
   - Instructor assignments
   - Meeting patterns (MWF, TR, etc.)
   - Location management (room, building, virtual)
   - Enrollment caps and waitlists

10. **course_modules** - Course units/chapters
    - Sequential or flexible ordering
    - Completion requirements
    - Time estimates
    - Module-level objectives
    - Adaptive release rules

11. **lessons** - Learning objects
    - Lesson types (video, reading, interactive)
    - Duration tracking
    - Completion criteria
    - Accessibility options
    - Version control

12. **learning_resources** - Content library
    - Resource types (video, PDF, link, SCORM)
    - File storage and CDN integration
    - Copyright and licensing
    - Resource sharing and reuse
    - Metadata tagging

13. **lesson_resources** - Resource associations
    - Required vs supplemental
    - Access restrictions
    - Download permissions
    - Resource ordering

### Enrollment & Progress (4 tables)

14. **enrollments** - Course registrations
    - Enrollment status workflow
    - Grade modes (letter, pass/fail, audit)
    - Add/drop tracking
    - Withdrawal management
    - Transfer credits

15. **prerequisite_overrides** - Requirement waivers
    - Override reasons
    - Approval chain
    - Expiration dates
    - Documentation

16. **lesson_progress** - Completion tracking
    - Progress percentage
    - Time spent
    - Attempt counts
    - Bookmark positions
    - Activity timestamps

17. **learning_paths** - Personalized curricula
    - Path types (degree, certificate, skill)
    - Milestone tracking
    - Branching logic
    - Recommended sequences
    - Completion certificates

18. **user_learning_paths** - Path enrollments
    - Progress tracking
    - Completion dates
    - Achievement unlocking
    - Path customization

### Assessment & Grading (6 tables)

19. **assignments** - All assessment types
    - Assignment types (quiz, exam, project, discussion)
    - Due dates and extensions
    - Group assignments
    - Rubric associations
    - Submission methods

20. **questions** - Assessment questions
    - Question types (MC, essay, code, file upload)
    - Point values
    - Difficulty levels
    - Learning outcome alignment
    - Question pools

21. **question_bank** - Reusable questions
    - Categorization
    - Version history
    - Usage statistics
    - Sharing permissions
    - Quality metrics

22. **rubrics** - Grading criteria
    - Criterion definitions
    - Performance levels
    - Point distributions
    - Rubric templates
    - Alignment with outcomes

23. **submissions** - Student work
    - Submission timestamps
    - File attachments
    - Similarity checking
    - Peer review assignments
    - Revision tracking

24. **gradebook** - Grade records
    - Grade calculations
    - Weighting schemes
    - Extra credit
    - Grade overrides
    - Historical records

25. **grade_history** - Grade audit trail
    - Change tracking
    - Justifications
    - Approvals
    - Grade appeals
    - Timestamp logging

### Communication (3 tables)

26. **discussions** - Forum threads
    - Thread types (Q&A, debate, general)
    - Moderation settings
    - Anonymous posting
    - Pinned topics
    - Threading options

27. **discussion_posts** - Forum messages
    - Rich text content
    - Attachments
    - Reactions and voting
    - Best answer marking
    - Edit history

28. **messages** - Direct messaging
    - Individual and group messages
    - Read receipts
    - Message threading
    - Attachment support
    - Blocking and reporting

29. **announcements** - Course/system notices
    - Announcement scope (course, section, institution)
    - Priority levels
    - Scheduling
    - Acknowledgment tracking
    - Multi-channel delivery

### Analytics & Compliance (4 tables)

30. **attendance** - Attendance records
    - Attendance types (present, absent, late, excused)
    - Automatic tracking (LMS login)
    - Manual entry
    - Participation grades
    - Reporting requirements

31. **activity_logs** - User activity tracking
    - Page views
    - Content interactions
    - Time on task
    - IP tracking
    - Session management

32. **learning_analytics** - Aggregated metrics
    - Engagement scores
    - Risk indicators
    - Performance trends
    - Predictive models
    - Intervention triggers

33. **certificates** - Completion certificates
    - Certificate templates
    - Digital signatures
    - Blockchain verification
    - PDF generation
    - Public verification URLs

## 🔑 Key Features

### Learning Management
- **Multi-modal delivery** (online, hybrid, in-person)
- **Adaptive learning paths** based on performance
- **Competency-based education** tracking
- **Mobile-responsive** learning experience
- **Offline content** availability

### Assessment System
- **Diverse question types** (20+ types)
- **Question banks** with randomization
- **Rubric-based grading** for consistency
- **Peer assessments** and reviews
- **Anti-cheating measures** (lockdown, proctoring)

### Student Success
- **Early alert systems** for at-risk students
- **Predictive analytics** for intervention
- **Personalized recommendations**
- **Progress visualization** and gamification
- **Learning analytics dashboards**

### Institutional Features
- **Multi-tenant architecture** for multiple schools
- **FERPA compliance** for privacy
- **Accessibility** (WCAG 2.1 compliant)
- **Integration ready** (LTI, SCORM, xAPI)
- **Comprehensive reporting** for accreditation

## 📈 Use Cases

### Course Management

1. **Intelligent Course Recommendations**
   ```sql
   -- Recommend courses based on student's academic profile and interests
   WITH student_profile AS (
     SELECT
       u.user_id,
       up.major,
       up.gpa,
       up.credits_earned,
       up.interests,
       GROUP_CONCAT(DISTINCT c.subject_area) as completed_subjects,
       AVG(g.grade_points) as avg_grade
     FROM users u
     JOIN user_profiles up ON u.user_id = up.user_id
     LEFT JOIN enrollments e ON u.user_id = e.student_id
     LEFT JOIN courses c ON e.course_id = c.course_id
     LEFT JOIN gradebook g ON e.enrollment_id = g.enrollment_id
     WHERE u.user_id = ?
       AND e.status = 'COMPLETED'
     GROUP BY u.user_id
   ),
   eligible_courses AS (
     SELECT
       c.course_id,
       c.course_code,
       c.course_name,
       c.credits,
       c.difficulty_level,
       c.subject_area,
       c.tags,
       -- Check prerequisites
       CASE WHEN EXISTS (
         SELECT 1 FROM course_prerequisites cp
         WHERE cp.course_id = c.course_id
           AND cp.prerequisite_id NOT IN (
             SELECT course_id FROM enrollments
             WHERE student_id = ? AND status = 'COMPLETED'
           )
       ) THEN 0 ELSE 1 END as prereqs_met,
       -- Calculate relevance score
       CASE
         WHEN c.subject_area = sp.major THEN 3
         WHEN FIND_IN_SET(c.subject_area, sp.completed_subjects) THEN 2
         ELSE 1
       END as relevance,
       -- Get course rating
       (SELECT AVG(rating) FROM course_reviews WHERE course_id = c.course_id) as avg_rating,
       -- Check schedule conflicts
       (SELECT COUNT(*) FROM course_sections cs
        WHERE cs.course_id = c.course_id
          AND cs.term_id = ?
          AND cs.enrollment_count < cs.max_enrollment) as available_sections
     FROM courses c
     CROSS JOIN student_profile sp
     WHERE c.is_active = TRUE
       AND c.course_id NOT IN (
         SELECT course_id FROM enrollments WHERE student_id = ?
       )
   )
   SELECT
     course_id,
     course_code,
     course_name,
     credits,
     difficulty_level,
     avg_rating,
     available_sections,
     -- Calculate recommendation score
     (prereqs_met * 10 +
      relevance * 5 +
      COALESCE(avg_rating, 3) +
      CASE WHEN available_sections > 0 THEN 3 ELSE 0 END) as recommendation_score,
     CASE
       WHEN prereqs_met = 0 THEN 'Prerequisites not met'
       WHEN available_sections = 0 THEN 'No sections available'
       ELSE 'Recommended'
     END as status
   FROM eligible_courses
   ORDER BY
     prereqs_met DESC,
     recommendation_score DESC
   LIMIT 10;
   ```

2. **Section Enrollment with Waitlist Management**
   ```sql
   -- Handle course enrollment with automatic waitlist processing
   DELIMITER //
   CREATE PROCEDURE enroll_student(
     IN p_student_id INT,
     IN p_section_id INT,
     IN p_grade_mode ENUM('LETTER', 'PASS_FAIL', 'AUDIT')
   )
   BEGIN
     DECLARE v_enrollment_count INT;
     DECLARE v_max_enrollment INT;
     DECLARE v_waitlist_position INT;
     DECLARE v_prereqs_met BOOLEAN;
     DECLARE v_time_conflict BOOLEAN;

     START TRANSACTION;

     -- Check prerequisites
     SELECT check_prerequisites(p_student_id,
       (SELECT course_id FROM course_sections WHERE section_id = p_section_id))
     INTO v_prereqs_met;

     IF NOT v_prereqs_met THEN
       SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = 'Prerequisites not satisfied';
     END IF;

     -- Check time conflicts
     SELECT EXISTS(
       SELECT 1 FROM enrollments e
       JOIN course_sections cs1 ON e.section_id = cs1.section_id
       JOIN course_sections cs2 ON cs2.section_id = p_section_id
       WHERE e.student_id = p_student_id
         AND e.status IN ('ENROLLED', 'WAITLISTED')
         AND cs1.term_id = cs2.term_id
         AND (
           (cs1.meeting_days = cs2.meeting_days AND
            cs1.start_time < cs2.end_time AND
            cs2.start_time < cs1.end_time)
         )
     ) INTO v_time_conflict;

     IF v_time_conflict THEN
       SIGNAL SQLSTATE '45000'
         SET MESSAGE_TEXT = 'Schedule conflict detected';
     END IF;

     -- Get current enrollment numbers
     SELECT enrollment_count, max_enrollment
     INTO v_enrollment_count, v_max_enrollment
     FROM course_sections
     WHERE section_id = p_section_id
     FOR UPDATE;

     IF v_enrollment_count < v_max_enrollment THEN
       -- Direct enrollment
       INSERT INTO enrollments (
         student_id, section_id, enrollment_date,
         status, grade_mode
       ) VALUES (
         p_student_id, p_section_id, NOW(),
         'ENROLLED', p_grade_mode
       );

       -- Update section count
       UPDATE course_sections
       SET enrollment_count = enrollment_count + 1
       WHERE section_id = p_section_id;

       -- Log activity
       INSERT INTO activity_logs (
         user_id, action, entity_type, entity_id
       ) VALUES (
         p_student_id, 'ENROLLED', 'SECTION', p_section_id
       );

     ELSE
       -- Add to waitlist
       SELECT COALESCE(MAX(waitlist_position), 0) + 1
       INTO v_waitlist_position
       FROM enrollments
       WHERE section_id = p_section_id
         AND status = 'WAITLISTED';

       INSERT INTO enrollments (
         student_id, section_id, enrollment_date,
         status, grade_mode, waitlist_position
       ) VALUES (
         p_student_id, p_section_id, NOW(),
         'WAITLISTED', p_grade_mode, v_waitlist_position
       );

       -- Send waitlist notification
       INSERT INTO messages (
         recipient_id, subject, body, priority
       ) VALUES (
         p_student_id,
         'Added to Waitlist',
         CONCAT('You are #', v_waitlist_position, ' on the waitlist'),
         'HIGH'
       );
     END IF;

     COMMIT;
   END//
   DELIMITER ;
   ```

### Learning Analytics

3. **Student Risk Assessment**
   ```sql
   -- Identify at-risk students using multiple indicators
   WITH student_metrics AS (
     SELECT
       e.student_id,
       u.first_name,
       u.last_name,
       e.section_id,
       cs.course_code,
       -- Attendance rate
       (SELECT COUNT(*) FROM attendance a
        WHERE a.student_id = e.student_id
          AND a.section_id = e.section_id
          AND a.status = 'PRESENT') /
       NULLIF((SELECT COUNT(*) FROM attendance a2
        WHERE a2.section_id = e.section_id), 0) * 100 as attendance_rate,
       -- Assignment submission rate
       (SELECT COUNT(*) FROM submissions s
        JOIN assignments a ON s.assignment_id = a.assignment_id
        WHERE s.student_id = e.student_id
          AND a.section_id = e.section_id) /
       NULLIF((SELECT COUNT(*) FROM assignments a3
        WHERE a3.section_id = e.section_id), 0) * 100 as submission_rate,
       -- Current grade
       (SELECT AVG(g.percentage) FROM gradebook g
        WHERE g.enrollment_id = e.enrollment_id) as current_grade,
       -- Days since last login
       DATEDIFF(NOW(), u.last_login_at) as days_since_login,
       -- Discussion participation
       (SELECT COUNT(*) FROM discussion_posts dp
        JOIN discussions d ON dp.discussion_id = d.discussion_id
        WHERE dp.author_id = e.student_id
          AND d.section_id = e.section_id) as discussion_posts,
       -- Page views in last 7 days
       (SELECT COUNT(*) FROM activity_logs al
        WHERE al.user_id = e.student_id
          AND al.entity_type = 'COURSE'
          AND al.entity_id = cs.course_id
          AND al.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)) as recent_activity
     FROM enrollments e
     JOIN users u ON e.student_id = u.user_id
     JOIN course_sections cs ON e.section_id = cs.section_id
     WHERE e.status = 'ENROLLED'
       AND cs.term_id = (SELECT term_id FROM academic_terms
                        WHERE start_date <= CURDATE()
                          AND end_date >= CURDATE())
   ),
   risk_scores AS (
     SELECT
       student_id,
       first_name,
       last_name,
       section_id,
       course_code,
       attendance_rate,
       submission_rate,
       current_grade,
       days_since_login,
       discussion_posts,
       recent_activity,
       -- Calculate risk score (0-100, higher = more at risk)
       (
         CASE WHEN attendance_rate < 70 THEN 20 ELSE 0 END +
         CASE WHEN submission_rate < 80 THEN 20 ELSE 0 END +
         CASE WHEN current_grade < 70 THEN 30 ELSE
              WHEN current_grade < 80 THEN 15 ELSE 0 END +
         CASE WHEN days_since_login > 7 THEN 15
              WHEN days_since_login > 3 THEN 5 ELSE 0 END +
         CASE WHEN discussion_posts = 0 THEN 10 ELSE 0 END +
         CASE WHEN recent_activity < 5 THEN 5 ELSE 0 END
       ) as risk_score,
       -- Risk factors
       CONCAT_WS(', ',
         IF(attendance_rate < 70, 'Low attendance', NULL),
         IF(submission_rate < 80, 'Missing assignments', NULL),
         IF(current_grade < 70, 'Low grades', NULL),
         IF(days_since_login > 7, 'Inactive', NULL),
         IF(discussion_posts = 0, 'No participation', NULL)
       ) as risk_factors
     FROM student_metrics
   )
   SELECT
     student_id,
     CONCAT(first_name, ' ', last_name) as student_name,
     course_code,
     risk_score,
     risk_factors,
     CASE
       WHEN risk_score >= 60 THEN 'HIGH'
       WHEN risk_score >= 30 THEN 'MEDIUM'
       ELSE 'LOW'
     END as risk_level,
     ROUND(attendance_rate, 1) as attendance_pct,
     ROUND(submission_rate, 1) as submission_pct,
     ROUND(current_grade, 1) as current_grade_pct,
     days_since_login
   FROM risk_scores
   WHERE risk_score >= 30  -- Only show medium and high risk
   ORDER BY risk_score DESC, course_code;
   ```

### Assessment & Grading

4. **Automated Grade Calculation with Weighted Categories**
   ```sql
   -- Calculate final grades with category weighting and drop lowest
   WITH grade_categories AS (
     SELECT
       e.enrollment_id,
       e.student_id,
       a.category,
       a.weight,
       COUNT(DISTINCT a.assignment_id) as total_assignments,
       a.drop_lowest,
       -- Get all grades in this category
       JSON_ARRAYAGG(
         JSON_OBJECT(
           'assignment_id', a.assignment_id,
           'points_earned', g.points_earned,
           'points_possible', g.points_possible,
           'percentage', g.percentage
         ) ORDER BY g.percentage ASC
       ) as grades_json
     FROM enrollments e
     JOIN assignments a ON a.section_id = e.section_id
     LEFT JOIN gradebook g ON g.enrollment_id = e.enrollment_id
       AND g.assignment_id = a.assignment_id
     WHERE e.enrollment_id = ?
     GROUP BY e.enrollment_id, a.category
   ),
   category_scores AS (
     SELECT
       enrollment_id,
       student_id,
       category,
       weight,
       total_assignments,
       drop_lowest,
       -- Calculate category score after dropping lowest
       CASE
         WHEN total_assignments > drop_lowest THEN
           (SELECT AVG(percentage) FROM (
             SELECT percentage FROM JSON_TABLE(grades_json, '$[*]'
               COLUMNS(percentage DECIMAL(5,2) PATH '$.percentage')) as t
             LIMIT total_assignments - drop_lowest OFFSET drop_lowest
           ))
         ELSE
           (SELECT AVG(percentage) FROM JSON_TABLE(grades_json, '$[*]'
             COLUMNS(percentage DECIMAL(5,2) PATH '$.percentage')) as t)
       END as category_average
     FROM grade_categories
   ),
   final_calculation AS (
     SELECT
       enrollment_id,
       student_id,
       SUM(category_average * weight / 100) as weighted_average,
       SUM(weight) as total_weight,
       GROUP_CONCAT(
         CONCAT(category, ': ', ROUND(category_average, 1), '%')
         ORDER BY category
       ) as category_breakdown
     FROM category_scores
     WHERE category_average IS NOT NULL
     GROUP BY enrollment_id
   )
   SELECT
     fc.enrollment_id,
     fc.student_id,
     fc.weighted_average as final_percentage,
     fc.category_breakdown,
     -- Apply grading scale
     CASE
       WHEN fc.weighted_average >= 93 THEN 'A'
       WHEN fc.weighted_average >= 90 THEN 'A-'
       WHEN fc.weighted_average >= 87 THEN 'B+'
       WHEN fc.weighted_average >= 83 THEN 'B'
       WHEN fc.weighted_average >= 80 THEN 'B-'
       WHEN fc.weighted_average >= 77 THEN 'C+'
       WHEN fc.weighted_average >= 73 THEN 'C'
       WHEN fc.weighted_average >= 70 THEN 'C-'
       WHEN fc.weighted_average >= 67 THEN 'D+'
       WHEN fc.weighted_average >= 63 THEN 'D'
       WHEN fc.weighted_average >= 60 THEN 'D-'
       ELSE 'F'
     END as letter_grade,
     -- Calculate grade points
     CASE
       WHEN fc.weighted_average >= 93 THEN 4.0
       WHEN fc.weighted_average >= 90 THEN 3.7
       WHEN fc.weighted_average >= 87 THEN 3.3
       WHEN fc.weighted_average >= 83 THEN 3.0
       WHEN fc.weighted_average >= 80 THEN 2.7
       WHEN fc.weighted_average >= 77 THEN 2.3
       WHEN fc.weighted_average >= 73 THEN 2.0
       WHEN fc.weighted_average >= 70 THEN 1.7
       WHEN fc.weighted_average >= 67 THEN 1.3
       WHEN fc.weighted_average >= 63 THEN 1.0
       WHEN fc.weighted_average >= 60 THEN 0.7
       ELSE 0.0
     END as grade_points
   FROM final_calculation fc;
   ```

### Learning Progress

5. **Personalized Learning Path Progress**
   ```sql
   -- Track student progress through personalized learning paths
   WITH path_progress AS (
     SELECT
       ulp.user_id,
       u.first_name,
       u.last_name,
       lp.path_name,
       lp.path_type,
       lp.total_credits_required,
       ulp.start_date,
       ulp.target_completion_date,
       -- Calculate completed credits
       (SELECT SUM(c.credits)
        FROM learning_path_requirements lpr
        JOIN courses c ON lpr.course_id = c.course_id
        JOIN enrollments e ON e.course_id = c.course_id
        WHERE lpr.path_id = lp.path_id
          AND e.student_id = ulp.user_id
          AND e.status = 'COMPLETED'
          AND e.final_grade_points >= 2.0) as completed_credits,
       -- Calculate in-progress credits
       (SELECT SUM(c.credits)
        FROM learning_path_requirements lpr
        JOIN courses c ON lpr.course_id = c.course_id
        JOIN enrollments e ON e.course_id = c.course_id
        WHERE lpr.path_id = lp.path_id
          AND e.student_id = ulp.user_id
          AND e.status = 'ENROLLED') as in_progress_credits,
       -- Get next recommended courses
       (SELECT GROUP_CONCAT(c.course_code ORDER BY lpr.sequence_number)
        FROM learning_path_requirements lpr
        JOIN courses c ON lpr.course_id = c.course_id
        WHERE lpr.path_id = lp.path_id
          AND lpr.is_required = TRUE
          AND c.course_id NOT IN (
            SELECT course_id FROM enrollments
            WHERE student_id = ulp.user_id
          )
        LIMIT 3) as next_courses,
       -- Calculate milestones completed
       (SELECT COUNT(*)
        FROM learning_path_milestones lpm
        WHERE lpm.path_id = lp.path_id
          AND lpm.milestone_id IN (
            SELECT milestone_id FROM user_milestones
            WHERE user_id = ulp.user_id AND completed = TRUE
          )) as milestones_completed,
       (SELECT COUNT(*)
        FROM learning_path_milestones
        WHERE path_id = lp.path_id) as total_milestones
     FROM user_learning_paths ulp
     JOIN learning_paths lp ON ulp.path_id = lp.path_id
     JOIN users u ON ulp.user_id = u.user_id
     WHERE ulp.status = 'ACTIVE'
   )
   SELECT
     user_id,
     CONCAT(first_name, ' ', last_name) as student_name,
     path_name,
     path_type,
     CONCAT(COALESCE(completed_credits, 0), '/', total_credits_required) as credit_progress,
     ROUND(COALESCE(completed_credits, 0) / total_credits_required * 100, 1) as completion_percentage,
     COALESCE(in_progress_credits, 0) as credits_in_progress,
     next_courses as recommended_next,
     CONCAT(milestones_completed, '/', total_milestones) as milestone_progress,
     DATEDIFF(target_completion_date, NOW()) as days_remaining,
     -- Predict on-track status
     CASE
       WHEN DATEDIFF(target_completion_date, NOW()) < 0 THEN 'OVERDUE'
       WHEN (completed_credits / total_credits_required) >=
            (DATEDIFF(NOW(), start_date) / DATEDIFF(target_completion_date, start_date))
            THEN 'ON_TRACK'
       ELSE 'BEHIND'
     END as progress_status,
     -- Estimated completion
     DATE_ADD(NOW(),
       INTERVAL (total_credits_required - completed_credits) *
         DATEDIFF(NOW(), start_date) / NULLIF(completed_credits, 0) DAY
     ) as estimated_completion
   FROM path_progress
   ORDER BY completion_percentage DESC;
   ```

### Institutional Analytics

6. **Course Effectiveness Analysis**
   ```sql
   -- Analyze course effectiveness across multiple metrics
   WITH course_metrics AS (
     SELECT
       c.course_id,
       c.course_code,
       c.course_name,
       cs.section_id,
       cs.term_id,
       i.instructor_id,
       CONCAT(i.first_name, ' ', i.last_name) as instructor_name,
       COUNT(DISTINCT e.student_id) as enrollment_count,
       -- Completion rate
       SUM(CASE WHEN e.status = 'COMPLETED' THEN 1 ELSE 0 END) /
         NULLIF(COUNT(*), 0) * 100 as completion_rate,
       -- Average grade
       AVG(CASE WHEN e.status = 'COMPLETED'
         THEN e.final_grade_points ELSE NULL END) as avg_gpa,
       -- DFW rate (D, F, Withdraw)
       SUM(CASE WHEN e.status = 'WITHDRAWN'
         OR e.final_grade IN ('D', 'D-', 'F')
         THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) * 100 as dfw_rate,
       -- Student satisfaction
       (SELECT AVG(rating) FROM course_evaluations
        WHERE section_id = cs.section_id) as avg_rating,
       -- Engagement score
       (SELECT AVG(la.engagement_score)
        FROM learning_analytics la
        JOIN enrollments e2 ON la.user_id = e2.student_id
        WHERE e2.section_id = cs.section_id) as avg_engagement,
       -- Learning outcome achievement
       (SELECT AVG(achievement_rate) FROM (
         SELECT AVG(CASE WHEN lo.achieved THEN 1 ELSE 0 END) * 100 as achievement_rate
         FROM course_learning_outcomes clo
         JOIN learning_outcome_results lo ON clo.outcome_id = lo.outcome_id
         WHERE clo.course_id = c.course_id
         GROUP BY lo.student_id
       ) as t) as outcome_achievement_rate
     FROM courses c
     JOIN course_sections cs ON c.course_id = cs.course_id
     JOIN users i ON cs.instructor_id = i.user_id
     JOIN enrollments e ON cs.section_id = e.section_id
     WHERE cs.term_id IN (
       SELECT term_id FROM academic_terms
       WHERE end_date >= DATE_SUB(NOW(), INTERVAL 1 YEAR)
     )
     GROUP BY c.course_id, cs.section_id
   ),
   course_rankings AS (
     SELECT
       course_id,
       course_code,
       course_name,
       instructor_name,
       enrollment_count,
       ROUND(completion_rate, 1) as completion_rate,
       ROUND(avg_gpa, 2) as avg_gpa,
       ROUND(dfw_rate, 1) as dfw_rate,
       ROUND(avg_rating, 1) as student_rating,
       ROUND(avg_engagement, 1) as engagement_score,
       ROUND(outcome_achievement_rate, 1) as outcome_rate,
       -- Calculate effectiveness score
       (
         completion_rate * 0.2 +
         (avg_gpa / 4.0 * 100) * 0.2 +
         (100 - dfw_rate) * 0.2 +
         (avg_rating / 5.0 * 100) * 0.2 +
         avg_engagement * 0.1 +
         outcome_achievement_rate * 0.1
       ) as effectiveness_score
     FROM course_metrics
   )
   SELECT
     course_code,
     course_name,
     instructor_name,
     enrollment_count,
     CONCAT(completion_rate, '%') as completion_rate,
     avg_gpa,
     CONCAT(dfw_rate, '%') as dfw_rate,
     CONCAT(student_rating, '/5') as student_rating,
     engagement_score,
     CONCAT(outcome_rate, '%') as learning_outcomes,
     ROUND(effectiveness_score, 1) as overall_effectiveness,
     CASE
       WHEN effectiveness_score >= 80 THEN 'Excellent'
       WHEN effectiveness_score >= 70 THEN 'Good'
       WHEN effectiveness_score >= 60 THEN 'Satisfactory'
       ELSE 'Needs Improvement'
     END as performance_tier
   FROM course_rankings
   ORDER BY effectiveness_score DESC;
   ```

## 🚀 Getting Started

### 1. Create Database
```bash
mysql -u root -p < schema/00_create_database.sql
```

### 2. Create Schema
```bash
mysql -u root -p education_db < schema/01_tables.sql
mysql -u root -p education_db < schema/02_constraints.sql
mysql -u root -p education_db < schema/03_indexes.sql
mysql -u root -p education_db < schema/04_views.sql
mysql -u root -p education_db < schema/05_procedures.sql
```

### 3. Generate Test Data
```bash
# Using the unified runner (recommended)
python generators/run_generators.py education --test

# Or run directly
cd generators/education
python generator.py
```

### 4. Load Generated Data
```bash
mysql -u root -p education_db < generators/education/output/*.sql
```

### 5. Run Example Queries
```bash
mysql -u root -p education_db < queries/01_enrollment.sql
mysql -u root -p education_db < queries/02_grading.sql
mysql -u root -p education_db < queries/03_analytics.sql
mysql -u root -p education_db < queries/04_reporting.sql
```

## 📋 Business Rules

### Enrollment Management
- **Prerequisites** must be satisfied (C or better)
- **Time conflicts** prevented automatically
- **Enrollment caps** enforced with waitlist
- **Add/drop period** restrictions (first 2 weeks)
- **Withdrawal** allowed until 60% course completion

### Academic Policies
- **GPA calculation** on 4.0 scale
- **Academic standing** (good, probation, dismissal)
- **Grade appeals** within 30 days
- **Incomplete grades** convert to F after 1 term
- **Retake policy** - best grade counts

### Assessment Rules
- **Late penalties** - 10% per day
- **Plagiarism detection** required for papers
- **Make-up exams** with documentation
- **Extra credit** capped at 5%
- **Curve grading** at instructor discretion

### Compliance
- **FERPA** - educational records privacy
- **ADA** - accessibility accommodations
- **Title IX** - discrimination prevention
- **Academic integrity** - honor code enforcement
- **Data retention** - 7 years minimum

## 🔍 Performance Optimizations

### Indexes
- **Covering indexes** for enrollment queries
- **Full-text indexes** for content search
- **Composite indexes** on frequent JOINs
- **Partial indexes** for active records

### Partitioning Strategy
- **Range partitioning** on activity_logs by date
- **List partitioning** on enrollments by term
- **Hash partitioning** on submissions for distribution

### Caching Strategy
- **Course catalog** cached for 1 hour
- **User profiles** cached for 30 minutes
- **Grade calculations** cached until update
- **Learning paths** cached for 24 hours

### Query Optimization
- **Materialized views** for gradebook summaries
- **Stored procedures** for complex calculations
- **Query hints** for optimal execution plans
- **Connection pooling** for scalability

## 📊 Sample Data Statistics

When using the data generator with default configuration:

- **Institutions**: 5 educational organizations
- **Users**: 10,000 (8,000 students, 1,500 instructors, 500 admin)
- **Courses**: 500 in catalog
- **Sections**: 1,500 per term
- **Enrollments**: 40,000 active
- **Assignments**: 15,000 across all courses
- **Submissions**: 200,000+
- **Discussions**: 5,000 threads, 50,000 posts
- **Total Records**: ~500,000+

## 🎯 Learning Objectives

This example demonstrates:

1. **Hierarchical Data Modeling** - Institution → Department → Course → Module → Lesson
2. **Complex Workflows** - Enrollment, grading, prerequisites, learning paths
3. **Temporal Data** - Terms, schedules, deadlines, progress tracking
4. **Many-to-Many Relationships** - Students-courses, roles-permissions
5. **Analytics & Reporting** - Risk assessment, effectiveness metrics
6. **Compliance Implementation** - FERPA privacy, accessibility
7. **Gamification** - Achievements, certificates, learning paths
8. **Performance at Scale** - Handling thousands of concurrent learners

## 🔧 Customization

### Learning Modalities

1. **Competency-Based Education**
   ```sql
   CREATE TABLE competencies (
     competency_id INT PRIMARY KEY,
     competency_name VARCHAR(200),
     description TEXT,
     mastery_criteria JSON
   );

   CREATE TABLE student_competencies (
     student_id INT,
     competency_id INT,
     mastery_level ENUM('NOVICE', 'DEVELOPING', 'PROFICIENT', 'ADVANCED'),
     evidence_url VARCHAR(500),
     assessed_date DATE
   );
   ```

2. **Micro-Learning & Badges**
   ```sql
   CREATE TABLE badges (
     badge_id INT PRIMARY KEY,
     badge_name VARCHAR(100),
     badge_image_url VARCHAR(500),
     criteria JSON,
     issuer_id INT
   );

   CREATE TABLE earned_badges (
     user_id INT,
     badge_id INT,
     earned_date TIMESTAMP,
     evidence_url VARCHAR(500),
     blockchain_hash VARCHAR(64)
   );
   ```

3. **AI-Powered Learning**
   ```sql
   CREATE TABLE ai_recommendations (
     recommendation_id BIGINT PRIMARY KEY,
     user_id INT,
     content_type ENUM('COURSE', 'RESOURCE', 'PEER'),
     content_id INT,
     relevance_score DECIMAL(3,2),
     reasoning TEXT,
     created_at TIMESTAMP
   );

   CREATE TABLE chatbot_interactions (
     interaction_id BIGINT PRIMARY KEY,
     user_id INT,
     course_id INT,
     question TEXT,
     answer TEXT,
     confidence_score DECIMAL(3,2),
     helpful BOOLEAN
   );
   ```

## 🛠️ Technologies

- **Database**: MySQL 8.0+
- **Engine**: InnoDB (ACID compliance, foreign keys)
- **Full-Text Search**: MySQL FULLTEXT indexes
- **JSON Support**: For flexible metadata
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_unicode_ci

## 🔐 Security & Compliance

- **FERPA Compliance**: Educational records privacy
- **GDPR Ready**: Data portability and deletion
- **WCAG 2.1**: Accessibility standards
- **OAuth 2.0/SAML**: Single sign-on support
- **Role-Based Access**: Granular permissions
- **Audit Logging**: Complete activity trail

## 📚 Additional Resources

- [Generator Documentation](../generators/education/README.md)
- [Query Examples](queries/)
- [Schema DDL](schema/)
- [API Documentation](../docs/api.md)
- [Integration Guide](../docs/integration.md)

## 🤝 Contributing

To improve this example:

1. Add adaptive learning algorithms
2. Implement VR/AR learning spaces
3. Create blockchain credentials
4. Add social learning features
5. Implement AI tutoring system

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📝 License

This example is part of the MySQL Business-to-Schema project, licensed under MIT License.