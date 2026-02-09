-- Student Analytics & Performance Queries
-- Advanced analytics for student success and learning outcomes

USE education_db;

-- ========================================
-- STUDENT PERFORMANCE ANALYTICS
-- ========================================

-- Comprehensive Student Dashboard
WITH student_metrics AS (
    SELECT
        u.user_id,
        u.first_name,
        u.last_name,
        u.email,
        up.gpa,
        up.credits_earned,
        COUNT(DISTINCT e.section_id) as courses_enrolled,
        COUNT(DISTINCT CASE WHEN e.enrollment_status = 'COMPLETED' THEN e.section_id END) as courses_completed,
        AVG(CASE WHEN e.enrollment_status = 'COMPLETED' THEN e.grade_points END) as avg_grade_points,
        SUM(CASE WHEN s.status = 'GRADED' THEN 1 ELSE 0 END) as assignments_graded,
        AVG(s.score / a.points_possible * 100) as avg_assignment_score,
        SUM(al.total_time_minutes) as total_study_time_minutes
    FROM users u
    LEFT JOIN user_profiles up ON u.user_id = up.user_id
    LEFT JOIN enrollments e ON u.user_id = e.user_id
    LEFT JOIN submissions s ON u.user_id = s.user_id
    LEFT JOIN assignments a ON s.assignment_id = a.assignment_id
    LEFT JOIN learning_analytics al ON u.user_id = al.user_id
    WHERE u.user_type = 'STUDENT'
      AND u.status = 'ACTIVE'
    GROUP BY u.user_id
),
percentile_ranks AS (
    SELECT
        *,
        PERCENT_RANK() OVER (ORDER BY gpa) as gpa_percentile,
        PERCENT_RANK() OVER (ORDER BY avg_assignment_score) as performance_percentile,
        PERCENT_RANK() OVER (ORDER BY total_study_time_minutes) as engagement_percentile
    FROM student_metrics
)
SELECT
    user_id,
    CONCAT(first_name, ' ', last_name) as student_name,
    email,
    gpa,
    ROUND(gpa_percentile * 100, 1) as gpa_percentile_rank,
    credits_earned,
    courses_enrolled,
    courses_completed,
    ROUND(courses_completed * 100.0 / NULLIF(courses_enrolled, 0), 1) as completion_rate,
    ROUND(avg_assignment_score, 1) as avg_score,
    ROUND(performance_percentile * 100, 1) as performance_percentile_rank,
    ROUND(total_study_time_minutes / 60.0, 1) as total_study_hours,
    ROUND(engagement_percentile * 100, 1) as engagement_percentile_rank,
    -- Overall student classification
    CASE
        WHEN gpa_percentile > 0.9 AND performance_percentile > 0.9 THEN 'HIGH_ACHIEVER'
        WHEN engagement_percentile < 0.25 OR performance_percentile < 0.25 THEN 'AT_RISK'
        WHEN engagement_percentile > 0.75 AND performance_percentile < 0.5 THEN 'STRUGGLING_BUT_ENGAGED'
        WHEN engagement_percentile < 0.5 AND performance_percentile > 0.75 THEN 'NATURAL_TALENT'
        ELSE 'AVERAGE'
    END as student_classification
FROM percentile_ranks
ORDER BY gpa DESC;

-- At-Risk Student Detection
WITH recent_performance AS (
    SELECT
        e.user_id,
        e.section_id,
        cs.course_id,
        c.course_name,
        -- Recent submission rate
        COUNT(DISTINCT CASE
            WHEN a.due_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
                AND a.due_date <= CURDATE()
            THEN a.assignment_id
        END) as recent_assignments_due,
        COUNT(DISTINCT CASE
            WHEN s.submitted_at >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
            THEN s.submission_id
        END) as recent_submissions,
        -- Grade trend
        AVG(CASE
            WHEN s.submitted_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            THEN s.score / a.points_possible * 100
        END) as recent_avg_score,
        AVG(CASE
            WHEN s.submitted_at < DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            THEN s.score / a.points_possible * 100
        END) as previous_avg_score,
        -- Attendance
        AVG(CASE
            WHEN att.attendance_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
                AND att.status = 'PRESENT'
            THEN 1 ELSE 0
        END) * 100 as recent_attendance_rate,
        -- Engagement
        MAX(al.login_count) as recent_logins,
        MAX(al.total_time_minutes) as recent_activity_minutes
    FROM enrollments e
    JOIN course_sections cs ON e.section_id = cs.section_id
    JOIN courses c ON cs.course_id = c.course_id
    LEFT JOIN assignments a ON cs.section_id = a.section_id
    LEFT JOIN submissions s ON a.assignment_id = s.assignment_id AND e.user_id = s.user_id
    LEFT JOIN attendance att ON cs.section_id = att.section_id AND e.user_id = att.user_id
    LEFT JOIN learning_analytics al ON e.user_id = al.user_id
        AND cs.section_id = al.section_id
        AND al.week_number = WEEK(CURDATE())
    WHERE e.enrollment_status = 'ENROLLED'
      AND cs.status = 'IN_PROGRESS'
    GROUP BY e.user_id, e.section_id
),
risk_indicators AS (
    SELECT
        rp.*,
        u.first_name,
        u.last_name,
        u.email,
        -- Calculate risk scores
        CASE WHEN recent_submissions < recent_assignments_due * 0.5 THEN 30 ELSE 0 END +
        CASE WHEN recent_avg_score < 60 THEN 25 ELSE 0 END +
        CASE WHEN recent_avg_score < previous_avg_score - 10 THEN 20 ELSE 0 END +
        CASE WHEN recent_attendance_rate < 50 THEN 15 ELSE 0 END +
        CASE WHEN recent_logins < 3 THEN 10 ELSE 0 END as risk_score
    FROM recent_performance rp
    JOIN users u ON rp.user_id = u.user_id
)
SELECT
    CONCAT(first_name, ' ', last_name) as student_name,
    email,
    course_name,
    recent_assignments_due,
    recent_submissions,
    ROUND(recent_submissions * 100.0 / NULLIF(recent_assignments_due, 0), 1) as submission_rate,
    ROUND(recent_avg_score, 1) as recent_avg_score,
    ROUND(previous_avg_score, 1) as previous_avg_score,
    ROUND(recent_avg_score - COALESCE(previous_avg_score, recent_avg_score), 1) as score_change,
    ROUND(recent_attendance_rate, 1) as attendance_rate,
    recent_logins,
    recent_activity_minutes,
    risk_score,
    CASE
        WHEN risk_score >= 70 THEN 'CRITICAL'
        WHEN risk_score >= 50 THEN 'HIGH'
        WHEN risk_score >= 30 THEN 'MEDIUM'
        ELSE 'LOW'
    END as risk_level,
    -- Intervention recommendations
    CASE
        WHEN risk_score >= 70 THEN 'Immediate intervention required - Schedule meeting'
        WHEN risk_score >= 50 THEN 'Proactive outreach recommended'
        WHEN risk_score >= 30 THEN 'Monitor closely'
        ELSE 'No immediate action required'
    END as recommended_action
FROM risk_indicators
WHERE risk_score >= 30
ORDER BY risk_score DESC;

-- ========================================
-- COURSE EFFECTIVENESS ANALYSIS
-- ========================================

-- Course Performance Metrics
WITH course_metrics AS (
    SELECT
        c.course_id,
        c.course_code,
        c.course_name,
        cs.section_id,
        cs.section_code,
        cs.term_id,
        CONCAT(u.first_name, ' ', u.last_name) as instructor_name,
        COUNT(DISTINCT e.user_id) as enrolled_students,
        COUNT(DISTINCT CASE WHEN e.enrollment_status = 'COMPLETED' THEN e.user_id END) as completed_students,
        COUNT(DISTINCT CASE WHEN e.enrollment_status = 'DROPPED' THEN e.user_id END) as dropped_students,
        AVG(g.percentage_score) as avg_final_score,
        STDDEV(g.percentage_score) as score_std_dev,
        AVG(CASE WHEN g.letter_grade IN ('A', 'A+', 'A-') THEN 1 ELSE 0 END) * 100 as a_grade_percentage,
        AVG(CASE WHEN g.letter_grade IN ('F', 'D') THEN 1 ELSE 0 END) * 100 as fail_rate
    FROM courses c
    JOIN course_sections cs ON c.course_id = cs.course_id
    JOIN users u ON cs.instructor_id = u.user_id
    LEFT JOIN enrollments e ON cs.section_id = e.section_id
    LEFT JOIN gradebook g ON cs.section_id = g.section_id AND e.user_id = g.user_id
    WHERE cs.status IN ('IN_PROGRESS', 'COMPLETED')
    GROUP BY cs.section_id
),
course_engagement AS (
    SELECT
        cs.section_id,
        AVG(la.total_time_minutes) as avg_time_per_student,
        AVG(la.content_views) as avg_content_views,
        AVG(la.discussion_posts) as avg_discussion_posts,
        AVG(la.on_time_submission_rate) as avg_on_time_rate
    FROM course_sections cs
    JOIN learning_analytics la ON cs.section_id = la.section_id
    GROUP BY cs.section_id
)
SELECT
    cm.course_code,
    cm.course_name,
    cm.section_code,
    cm.instructor_name,
    cm.enrolled_students,
    cm.completed_students,
    ROUND(cm.completed_students * 100.0 / NULLIF(cm.enrolled_students, 0), 1) as completion_rate,
    cm.dropped_students,
    ROUND(cm.dropped_students * 100.0 / NULLIF(cm.enrolled_students, 0), 1) as drop_rate,
    ROUND(cm.avg_final_score, 1) as avg_final_score,
    ROUND(cm.score_std_dev, 1) as score_std_dev,
    ROUND(cm.a_grade_percentage, 1) as a_grade_percentage,
    ROUND(cm.fail_rate, 1) as fail_rate,
    ROUND(ce.avg_time_per_student / 60.0, 1) as avg_study_hours,
    ROUND(ce.avg_content_views, 1) as avg_content_views,
    ROUND(ce.avg_discussion_posts, 1) as avg_discussion_posts,
    ROUND(ce.avg_on_time_rate, 1) as on_time_submission_rate,
    -- Course effectiveness score
    ROUND(
        (cm.completion_rate * 0.3) +
        ((100 - cm.drop_rate) * 0.2) +
        (cm.avg_final_score * 0.25) +
        (ce.avg_on_time_rate * 0.15) +
        ((ce.avg_time_per_student / 60.0) * 0.1),
        1
    ) as effectiveness_score
FROM course_metrics cm
LEFT JOIN course_engagement ce ON cm.section_id = ce.section_id
ORDER BY effectiveness_score DESC;

-- ========================================
-- LEARNING PATH ANALYSIS
-- ========================================

-- Optimal Learning Path Discovery
WITH course_sequences AS (
    SELECT
        e1.user_id,
        c1.course_id as from_course_id,
        c1.course_code as from_course,
        c2.course_id as to_course_id,
        c2.course_code as to_course,
        e1.final_grade as from_grade,
        e2.final_grade as to_grade,
        DATEDIFF(e2.enrollment_date, e1.completion_date) as days_between
    FROM enrollments e1
    JOIN course_sections cs1 ON e1.section_id = cs1.section_id
    JOIN courses c1 ON cs1.course_id = c1.course_id
    JOIN enrollments e2 ON e1.user_id = e2.user_id
    JOIN course_sections cs2 ON e2.section_id = cs2.section_id
    JOIN courses c2 ON cs2.course_id = c2.course_id
    WHERE e1.enrollment_status = 'COMPLETED'
      AND e2.enrollment_status = 'COMPLETED'
      AND e1.completion_date < e2.enrollment_date
      AND DATEDIFF(e2.enrollment_date, e1.completion_date) < 180  -- Within 6 months
),
path_success_rates AS (
    SELECT
        from_course_id,
        from_course,
        to_course_id,
        to_course,
        COUNT(*) as student_count,
        AVG(CASE
            WHEN to_grade IN ('A', 'A+', 'A-', 'B+', 'B') THEN 1
            ELSE 0
        END) * 100 as success_rate,
        AVG(days_between) as avg_days_between
    FROM course_sequences
    GROUP BY from_course_id, to_course_id
    HAVING student_count >= 5  -- Minimum sample size
)
SELECT
    from_course,
    to_course,
    student_count,
    ROUND(success_rate, 1) as success_rate_percent,
    ROUND(avg_days_between, 0) as avg_days_between,
    CASE
        WHEN success_rate >= 80 THEN 'HIGHLY_RECOMMENDED'
        WHEN success_rate >= 60 THEN 'RECOMMENDED'
        WHEN success_rate >= 40 THEN 'POSSIBLE'
        ELSE 'NOT_RECOMMENDED'
    END as path_recommendation,
    CONCAT(
        'Students who take ', from_course,
        ' followed by ', to_course,
        ' have a ', ROUND(success_rate, 0),
        '% success rate'
    ) as insight
FROM path_success_rates
ORDER BY from_course, success_rate DESC;

-- ========================================
-- ASSIGNMENT & ASSESSMENT ANALYTICS
-- ========================================

-- Assignment Difficulty Analysis
WITH assignment_stats AS (
    SELECT
        a.assignment_id,
        a.title,
        a.assignment_type,
        cs.course_id,
        c.course_code,
        COUNT(DISTINCT s.user_id) as submission_count,
        AVG(s.score / a.points_possible * 100) as avg_score,
        STDDEV(s.score / a.points_possible * 100) as score_std_dev,
        MIN(s.score / a.points_possible * 100) as min_score,
        MAX(s.score / a.points_possible * 100) as max_score,
        AVG(s.time_spent_seconds / 60.0) as avg_time_minutes,
        AVG(s.attempt_number) as avg_attempts,
        SUM(CASE WHEN s.late_submission THEN 1 ELSE 0 END) * 100.0 / COUNT(*) as late_rate
    FROM assignments a
    JOIN course_sections cs ON a.section_id = cs.section_id
    JOIN courses c ON cs.course_id = c.course_id
    JOIN submissions s ON a.assignment_id = s.assignment_id
    WHERE s.status = 'GRADED'
    GROUP BY a.assignment_id
),
difficulty_classification AS (
    SELECT
        *,
        -- Classify difficulty based on multiple factors
        CASE
            WHEN avg_score < 60 AND score_std_dev > 20 THEN 'VERY_DIFFICULT'
            WHEN avg_score < 70 THEN 'DIFFICULT'
            WHEN avg_score > 90 AND score_std_dev < 10 THEN 'EASY'
            WHEN avg_score > 80 THEN 'MODERATE_EASY'
            ELSE 'MODERATE'
        END as difficulty_level,
        -- Calculate discrimination index (how well it separates high/low performers)
        CASE
            WHEN score_std_dev > 15 THEN 'HIGH_DISCRIMINATION'
            WHEN score_std_dev > 10 THEN 'MODERATE_DISCRIMINATION'
            ELSE 'LOW_DISCRIMINATION'
        END as discrimination_level
    FROM assignment_stats
)
SELECT
    course_code,
    title as assignment_title,
    assignment_type,
    submission_count,
    ROUND(avg_score, 1) as avg_score,
    ROUND(score_std_dev, 1) as score_std_dev,
    ROUND(min_score, 1) as min_score,
    ROUND(max_score, 1) as max_score,
    ROUND(avg_time_minutes, 1) as avg_time_minutes,
    ROUND(avg_attempts, 1) as avg_attempts,
    ROUND(late_rate, 1) as late_submission_rate,
    difficulty_level,
    discrimination_level,
    -- Recommendations
    CASE
        WHEN difficulty_level = 'VERY_DIFFICULT' THEN 'Consider providing additional resources or breaking into smaller assignments'
        WHEN difficulty_level = 'EASY' AND discrimination_level = 'LOW_DISCRIMINATION' THEN 'Consider increasing challenge level'
        WHEN late_rate > 30 THEN 'High late submission rate - review deadline or workload'
        ELSE 'Assignment performing as expected'
    END as recommendation
FROM difficulty_classification
ORDER BY course_code, avg_score;

-- ========================================
-- ENGAGEMENT PATTERNS
-- ========================================

-- Weekly Engagement Patterns
WITH weekly_activity AS (
    SELECT
        DAYNAME(al.created_at) as day_of_week,
        DAYOFWEEK(al.created_at) as day_number,
        HOUR(al.created_at) as hour_of_day,
        COUNT(DISTINCT al.user_id) as unique_users,
        COUNT(*) as total_activities,
        AVG(CASE WHEN al.activity_type = 'VIEW' THEN 1 ELSE 0 END) * 100 as view_percentage,
        AVG(CASE WHEN al.activity_type = 'SUBMIT' THEN 1 ELSE 0 END) * 100 as submit_percentage,
        AVG(CASE WHEN al.activity_type = 'POST' THEN 1 ELSE 0 END) * 100 as post_percentage
    FROM activity_logs al
    WHERE al.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY DAYOFWEEK(al.created_at), HOUR(al.created_at)
)
SELECT
    day_of_week,
    hour_of_day,
    unique_users,
    total_activities,
    ROUND(view_percentage, 1) as content_view_pct,
    ROUND(submit_percentage, 1) as submission_pct,
    ROUND(post_percentage, 1) as discussion_pct,
    -- Create heatmap indicator
    CASE
        WHEN unique_users > (SELECT AVG(unique_users) + STDDEV(unique_users) FROM weekly_activity) THEN 'HIGH'
        WHEN unique_users > (SELECT AVG(unique_users) FROM weekly_activity) THEN 'MEDIUM'
        ELSE 'LOW'
    END as activity_level,
    -- Identify peak times
    CASE
        WHEN hour_of_day BETWEEN 9 AND 11 THEN 'Morning Peak'
        WHEN hour_of_day BETWEEN 14 AND 16 THEN 'Afternoon Peak'
        WHEN hour_of_day BETWEEN 19 AND 22 THEN 'Evening Peak'
        WHEN hour_of_day BETWEEN 23 AND 24 OR hour_of_day BETWEEN 0 AND 2 THEN 'Late Night'
        ELSE 'Normal'
    END as time_period
FROM weekly_activity
ORDER BY day_number, hour_of_day;

-- ========================================
-- PREDICTIVE ANALYTICS
-- ========================================

-- Grade Prediction Model Features
WITH student_features AS (
    SELECT
        e.user_id,
        e.section_id,
        -- Historical performance
        up.gpa as historical_gpa,

        -- Current course performance
        AVG(s.score / a.points_possible * 100) as current_avg_score,
        COUNT(DISTINCT s.submission_id) as submission_count,
        SUM(CASE WHEN s.late_submission THEN 1 ELSE 0 END) as late_submissions,

        -- Engagement metrics
        SUM(la.total_time_minutes) as total_engagement_minutes,
        SUM(la.content_views) as total_content_views,
        SUM(la.discussion_posts) as total_discussion_posts,

        -- Attendance
        AVG(CASE WHEN att.status = 'PRESENT' THEN 1 ELSE 0 END) * 100 as attendance_rate,

        -- Current grade
        g.letter_grade as actual_grade,
        g.percentage_score as actual_percentage

    FROM enrollments e
    LEFT JOIN user_profiles up ON e.user_id = up.user_id
    LEFT JOIN submissions s ON e.user_id = s.user_id
    LEFT JOIN assignments a ON s.assignment_id = a.assignment_id
    LEFT JOIN learning_analytics la ON e.user_id = la.user_id AND e.section_id = la.section_id
    LEFT JOIN attendance att ON e.user_id = att.user_id AND e.section_id = att.section_id
    LEFT JOIN gradebook g ON e.user_id = g.user_id AND e.section_id = g.section_id
    WHERE e.enrollment_status = 'ENROLLED'
    GROUP BY e.user_id, e.section_id
),
grade_prediction AS (
    SELECT
        user_id,
        section_id,
        historical_gpa,
        ROUND(current_avg_score, 1) as current_avg_score,
        submission_count,
        late_submissions,
        ROUND(total_engagement_minutes / 60.0, 1) as engagement_hours,
        total_content_views,
        total_discussion_posts,
        ROUND(attendance_rate, 1) as attendance_rate,
        actual_grade,
        -- Simple predictive model based on weighted features
        ROUND(
            (COALESCE(historical_gpa * 20, 60)) * 0.2 +
            (COALESCE(current_avg_score, 70)) * 0.4 +
            (COALESCE(attendance_rate, 80)) * 0.2 +
            (LEAST(submission_count * 2, 100)) * 0.1 +
            (LEAST(total_engagement_minutes / 10, 100)) * 0.1,
            1
        ) as predicted_score,
        -- Confidence level
        CASE
            WHEN submission_count >= 10 AND total_engagement_minutes > 600 THEN 'HIGH'
            WHEN submission_count >= 5 AND total_engagement_minutes > 300 THEN 'MEDIUM'
            ELSE 'LOW'
        END as prediction_confidence
    FROM student_features
)
SELECT
    u.first_name,
    u.last_name,
    c.course_code,
    c.course_name,
    gp.current_avg_score,
    gp.submission_count,
    gp.engagement_hours,
    gp.attendance_rate,
    gp.predicted_score,
    CASE
        WHEN predicted_score >= 93 THEN 'A'
        WHEN predicted_score >= 90 THEN 'A-'
        WHEN predicted_score >= 87 THEN 'B+'
        WHEN predicted_score >= 83 THEN 'B'
        WHEN predicted_score >= 80 THEN 'B-'
        WHEN predicted_score >= 77 THEN 'C+'
        WHEN predicted_score >= 73 THEN 'C'
        WHEN predicted_score >= 70 THEN 'C-'
        WHEN predicted_score >= 67 THEN 'D+'
        WHEN predicted_score >= 63 THEN 'D'
        WHEN predicted_score >= 60 THEN 'D-'
        ELSE 'F'
    END as predicted_grade,
    gp.actual_grade,
    gp.prediction_confidence,
    -- Intervention recommendation
    CASE
        WHEN predicted_score < 70 AND prediction_confidence IN ('HIGH', 'MEDIUM') THEN 'Intervention recommended'
        WHEN predicted_score < 60 THEN 'Urgent intervention required'
        WHEN predicted_score >= 90 THEN 'Performing excellently'
        ELSE 'Monitor progress'
    END as recommendation
FROM grade_prediction gp
JOIN users u ON gp.user_id = u.user_id
JOIN enrollments e ON gp.user_id = e.user_id AND gp.section_id = e.section_id
JOIN course_sections cs ON e.section_id = cs.section_id
JOIN courses c ON cs.course_id = c.course_id
ORDER BY predicted_score ASC;