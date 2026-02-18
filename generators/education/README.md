# Education & LMS Data Generator

## Overview

A comprehensive data generator for the Education & Learning Management System (Example 15) that creates realistic academic data including institutions, courses, enrollments, assignments, grades, and learning activities. This generator simulates a complete educational ecosystem with multiple institutions, academic terms, and student learning patterns.

## Features

### 🏫 Institutional Structure
- **5 institutions** (Universities, Colleges, Online Academies)
- **25 departments** across various disciplines
- Academic terms (Fall, Spring, Summer)
- Subscription tiers (Free, Basic, Professional, Enterprise)
- Storage quotas and usage tracking

### 👥 User Management
- **5,000 users** total
- **4,000 students** with profiles and preferences
- **150 instructors** with qualifications
- **50 administrators**
- User profiles with learning styles and academic standing
- GPA tracking and credit management

### 📚 Course Catalog
- **500 courses** across all levels
- Course formats: In-person, Online, Hybrid, Self-paced
- **1,500 course sections** (actual class instances)
- **5,000+ modules** with learning objectives
- **25,000+ lessons** with various content types
- **3,000+ learning resources** (videos, PDFs, links)
- Prerequisites and corequisites
- Learning outcomes and required materials

### 📝 Academic Activities
- **15,000 enrollments** with status tracking
- **5,000 assignments** of various types
- **50,000 submissions** with timing patterns
- **60,000 grades** with feedback
- **100,000 attendance records**
- Grade distribution following realistic curves

### 💬 Collaboration
- **2,000 discussion forums**
- **10,000+ discussion posts** with threading
- Study groups and peer interactions
- Instructor feedback and responses
- Upvoting and answer marking

### 📊 Analytics & Tracking
- Activity logs for user behavior
- Learning analytics per section
- Progress tracking
- Engagement metrics
- Completion rates
- Time spent analysis

## Data Volumes

| Entity | Count | Description |
|--------|-------|-------------|
| Institutions | 5 | Various types and sizes |
| Departments | 25 | Academic departments |
| Users | 5,000 | Students, instructors, admins |
| Courses | 500 | Course catalog |
| Course Sections | 1,500 | Active classes |
| Modules | 5,000+ | Course content units |
| Lessons | 25,000+ | Individual learning objects |
| Enrollments | 15,000 | Student registrations |
| Assignments | 5,000 | Various assessment types |
| Submissions | 50,000 | Student work |
| Grades | 60,000 | Graded assignments |
| Discussions | 2,000 | Forum topics |
| Posts | 10,000+ | Discussion contributions |
| Attendance | 100,000 | Class attendance records |

## Installation

```bash
# Install Python dependencies
poetry install --no-root
```

## Usage

### Basic Usage

```bash
# Generate with default configuration
python generator.py

# Custom output directory
python generator.py --output ./custom_output

# Custom configuration file
python generator.py --config my_config.json

# Set random seed for reproducibility
python generator.py --seed 42
```

### Configuration

Edit `config.json` to customize:

```json
{
  "counts": {
    "institutions": 5,
    "students": 4000,
    "instructors": 150,
    "courses": 500,
    "enrollments": 15000
  },
  "course_config": {
    "levels": {
      "INTRODUCTORY": 0.3,
      "INTERMEDIATE": 0.4,
      "ADVANCED": 0.2,
      "GRADUATE": 0.1
    }
  },
  "grading_config": {
    "grade_distribution": {
      "A": 0.15,
      "B": 0.35,
      "C": 0.30,
      "D": 0.15,
      "F": 0.05
    }
  }
}
```

## Generated Files

The generator creates CSV files in the output directory:

### Institutional Data
- `institutions.csv` - Educational institutions
- `departments.csv` - Academic departments
- `academic_terms.csv` - Semesters/quarters

### User Data
- `users.csv` - All system users
- `user_profiles.csv` - Extended profiles
- `roles.csv` - System roles
- `user_roles.csv` - Role assignments

### Course Data
- `courses.csv` - Course catalog
- `course_sections.csv` - Class instances
- `course_modules.csv` - Course units
- `lessons.csv` - Learning content
- `learning_resources.csv` - Educational materials

### Academic Records
- `enrollments.csv` - Student registrations
- `assignments.csv` - Course assignments
- `submissions.csv` - Student submissions
- `grades.csv` - Grade records
- `attendance_records.csv` - Attendance tracking

### Interaction Data
- `discussions.csv` - Forum topics
- `discussion_posts.csv` - Forum posts
- `messages.csv` - Direct messages
- `announcements.csv` - Course announcements

### Analytics
- `activity_logs.csv` - User activity tracking
- `learning_analytics.csv` - Aggregated metrics
- `progress_tracking.csv` - Learning progress

## Loading into MySQL

```bash
# 1. Create the database schema
mysql -u root < ../../example_15_education/schema/00_create_database.sql
mysql -u root education_db < ../../example_15_education/schema/01_tables.sql

# 2. Load generated data
for file in output/*.csv; do
    table=$(basename $file .csv)
    mysql -u root education_db -e "
        LOAD DATA LOCAL INFILE '$file'
        INTO TABLE $table
        FIELDS TERMINATED BY ','
        ENCLOSED BY '\"'
        LINES TERMINATED BY '\n'
        IGNORE 1 ROWS;"
done
```

## Data Characteristics

### Institution Types
- **40% Universities**: Large, comprehensive programs
- **40% Colleges**: Smaller, focused programs
- **20% Online**: Fully digital learning platforms

### Course Distribution
- **30% Introductory**: 100-200 level courses
- **40% Intermediate**: 300 level courses
- **20% Advanced**: 400 level courses
- **10% Graduate**: 500+ level courses

### Course Formats
- **40% In-Person**: Traditional classroom
- **30% Online**: Fully remote
- **25% Hybrid**: Mixed delivery
- **5% Self-Paced**: Asynchronous learning

### Grade Distribution
- **15% A**: Excellent performance
- **35% B**: Good performance
- **30% C**: Satisfactory performance
- **15% D**: Below average
- **5% F**: Failing

### Student Behavior
- **80% Enrollment completion rate**
- **10% Course drop rate**
- **75% Attendance rate**
- **90% Assignment submission rate**
- **40% Discussion participation**

### Learning Preferences
- **30% Visual** learners
- **20% Auditory** learners
- **30% Reading/Writing** learners
- **15% Kinesthetic** learners
- **5% Mixed** learning styles

### Assignment Types
- **30% Homework**: Regular assignments
- **20% Quizzes**: Short assessments
- **20% Exams**: Major tests
- **15% Projects**: Extended work
- **10% Presentations**: Oral assessments
- **5% Participation**: Class engagement

## Realistic Features

### Academic Calendar
- Fall semester: September - December
- Spring semester: January - May
- Summer session: June - August
- Registration periods and deadlines
- Add/drop and withdrawal dates

### Enrollment Patterns
- Average 4 courses per student per term
- Waitlist management
- Prerequisites enforcement
- Enrollment capacity limits
- Late enrollment options

### Grading System
- Letter grades with GPA calculation
- Late submission penalties (10% per day)
- Multiple attempt allowance
- Rubric-based grading
- Grade curving options

### Learning Analytics
- Student engagement tracking
- Resource access patterns
- Time spent per activity
- Discussion participation rates
- Assignment completion trends

### Attendance Tracking
- Present, Absent, Late, Excused statuses
- Check-in times
- Duration tracking
- Attendance impact on grades

## Performance

Generation times on standard hardware:
- Institutional structure: ~2 seconds
- Users and profiles: ~8 seconds
- Courses and content: ~15 seconds
- Enrollments: ~10 seconds
- Assignments and grades: ~20 seconds
- Total generation: ~60 seconds

## Troubleshooting

### Common Issues

1. **Memory Usage**: For large datasets:
   ```bash
   python -Xmx4g generator.py
   ```

2. **Reduce Counts**: For faster generation:
   ```json
   "students": 1000,
   "courses": 100,
   "enrollments": 3000
   ```

3. **Date Conflicts**: Ensure terms don't overlap:
   ```json
   "fall_end": "12-20",
   "spring_start": "01-15"
   ```

## Customization

### Adding Departments
Add to departments_list in config.json:
```json
"departments_list": [
    "Artificial Intelligence",
    "Quantum Computing",
    "Biotechnology"
]
```

### Adjusting Grade Distribution
Modify grading_config:
```json
"grade_distribution": {
    "A": 0.20,
    "B": 0.40,
    "C": 0.25,
    "D": 0.10,
    "F": 0.05
}
```

### Course Levels
Adjust course level distribution:
```json
"levels": {
    "INTRODUCTORY": 0.25,
    "INTERMEDIATE": 0.45,
    "ADVANCED": 0.25,
    "GRADUATE": 0.05
}
```

## Validation

Run validation after generation:
```bash
# Check record counts
python -c "
import pandas as pd
import glob

for file in glob.glob('output/*.csv'):
    df = pd.read_csv(file)
    print(f'{file}: {len(df)} records')
"

# Verify enrollment distribution
python -c "
import pandas as pd

enrollments = pd.read_csv('output/enrollments.csv')
print(f'Total enrollments: {len(enrollments)}')
print(f'Average per student: {len(enrollments)/4000:.1f}')
print(enrollments['enrollment_status'].value_counts())
"
```

## Use Cases

This generator simulates:
1. **Multi-institution** learning platforms
2. **Complete academic lifecycle** from enrollment to graduation
3. **Various learning modalities** (online, hybrid, in-person)
4. **Comprehensive assessment** systems
5. **Student engagement** tracking
6. **Learning analytics** and reporting
7. **Academic compliance** (FERPA, accreditation)
8. **Collaborative learning** environments

## Contributing

To improve the generator:
1. Add more realistic learning patterns
2. Enhance grade calculation algorithms
3. Add competency-based education features
4. Implement adaptive learning paths
5. Add international education support

## License

MIT License - Part of the MySQL Business to Schema project
