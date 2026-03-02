#!/usr/bin/env python3
"""
Education & Learning Management System Data Generator
Generates realistic sample data for the education database schema
with courses, enrollments, grades, and learning activities
"""

import random
import json
import csv
import os
import sys
import math
import hashlib
import argparse
from datetime import datetime, timedelta, date, time
from typing import List, Dict, Any, Tuple, Optional
from decimal import Decimal
from pathlib import Path
from collections import defaultdict

# Required: pip install faker
from faker import Faker
from faker.providers import (
    person,
    address,
    phone_number,
    company,
    date_time,
    python,
    lorem,
    internet,
)


class EducationDataGenerator:
    def __init__(self, config_path: str = "config.json"):
        """Initialize the generator with configuration"""
        self.fake = Faker("en_US")
        self.fake.add_provider(person)
        self.fake.add_provider(address)
        self.fake.add_provider(phone_number)
        self.fake.add_provider(company)
        self.fake.add_provider(date_time)
        self.fake.add_provider(python)
        self.fake.add_provider(lorem)
        self.fake.add_provider(internet)

        # Load configuration
        with open(config_path, "r") as f:
            self.config = json.load(f)

        # Set seed for reproducibility
        random.seed(self.config["seed"])
        Faker.seed(self.config["seed"])

        # Data storage
        self.institutions: List[Any] = []
        self.departments: List[Any] = []
        self.users: List[Any] = []
        self.user_profiles: List[Any] = []
        self.roles: List[Any] = []
        self.user_roles: List[Any] = []
        self.academic_terms: List[Any] = []
        self.courses: List[Any] = []
        self.course_sections: List[Any] = []
        self.course_modules: List[Any] = []
        self.lessons: List[Any] = []
        self.learning_resources: List[Any] = []
        self.enrollments: List[Any] = []
        self.attendance_records: List[Any] = []
        self.assignments: List[Any] = []
        self.submissions: List[Any] = []
        self.grades: List[Any] = []
        self.grade_history: List[Any] = []
        self.rubrics: List[Any] = []
        self.rubric_criteria: List[Any] = []
        self.discussions: List[Any] = []
        self.discussion_posts: List[Any] = []
        self.announcements: List[Any] = []
        self.messages: List[Any] = []
        self.study_groups: List[Any] = []
        self.study_group_members: List[Any] = []
        self.learning_paths: List[Any] = []
        self.progress_tracking: List[Any] = []
        self.achievements: List[Any] = []
        self.user_achievements: List[Any] = []
        self.certificates: List[Any] = []
        self.activity_logs: List[Any] = []
        self.learning_analytics: List[Any] = []
        self.transcripts: List[Any] = []
        self.prerequisites: List[Any] = []
        self.course_materials: List[Any] = []
        self.quiz_questions: List[Any] = []
        self.quiz_responses: List[Any] = []

        # Counters for IDs
        self.counters = defaultdict(lambda: 1)

        # Cache for lookups
        self.student_ids: List[Any] = []
        self.instructor_ids: List[Any] = []
        self.admin_ids: List[Any] = []
        self.section_students = defaultdict(list)  # section_id -> list of student_ids
        self.student_courses = defaultdict(list)  # student_id -> list of section_ids

        # Course subjects and names
        self.course_subjects = {
            "Computer Science": [
                "Programming",
                "Data Structures",
                "Algorithms",
                "Databases",
                "Networks",
                "Web Development",
                "Mobile Apps",
                "AI",
                "Machine Learning",
                "Cybersecurity",
            ],
            "Mathematics": [
                "Calculus",
                "Linear Algebra",
                "Statistics",
                "Discrete Math",
                "Number Theory",
                "Differential Equations",
                "Probability",
                "Topology",
                "Abstract Algebra",
            ],
            "Business": [
                "Management",
                "Marketing",
                "Finance",
                "Accounting",
                "Economics",
                "Entrepreneurship",
                "Operations",
                "Strategy",
                "Leadership",
                "Analytics",
            ],
            "Science": [
                "Physics",
                "Chemistry",
                "Biology",
                "Astronomy",
                "Geology",
                "Environmental Science",
                "Anatomy",
                "Genetics",
                "Ecology",
                "Microbiology",
            ],
            "Liberal Arts": [
                "Literature",
                "History",
                "Philosophy",
                "Psychology",
                "Sociology",
                "Art History",
                "Music Theory",
                "Creative Writing",
                "Ethics",
                "Anthropology",
            ],
            "Engineering": [
                "Mechanical",
                "Electrical",
                "Civil",
                "Chemical",
                "Aerospace",
                "Biomedical",
                "Materials",
                "Industrial",
                "Systems",
                "Software",
            ],
        }

        # Learning outcomes templates
        self.learning_outcomes = [
            "Understand fundamental concepts of {}",
            "Apply {} principles to solve real-world problems",
            "Analyze and evaluate {} methodologies",
            "Create innovative solutions using {}",
            "Demonstrate proficiency in {}",
            "Critically assess {} theories and practices",
            "Collaborate effectively on {} projects",
            "Communicate {} concepts clearly",
            "Design and implement {} systems",
            "Research and synthesize {} literature",
        ]

        # Assignment titles
        self.assignment_titles = {
            "HOMEWORK": [
                "Problem Set",
                "Reading Assignment",
                "Practice Exercises",
                "Weekly Assignment",
                "Homework",
            ],
            "QUIZ": [
                "Quiz",
                "Pop Quiz",
                "Weekly Quiz",
                "Chapter Quiz",
                "Quick Assessment",
            ],
            "EXAM": [
                "Midterm Exam",
                "Final Exam",
                "Unit Test",
                "Comprehensive Exam",
                "Assessment",
            ],
            "PROJECT": [
                "Final Project",
                "Group Project",
                "Research Project",
                "Capstone Project",
                "Term Project",
            ],
            "PRESENTATION": [
                "Presentation",
                "Final Presentation",
                "Group Presentation",
                "Research Presentation",
            ],
            "PARTICIPATION": [
                "Class Participation",
                "Discussion Participation",
                "Forum Activity",
                "Attendance",
            ],
        }

    def generate_institutions(self):
        """Generate educational institutions"""
        print("  Generating institutions...")

        for inst_type_config in self.config["institutions_config"]["types"]:
            for i in range(inst_type_config["count"]):
                inst_id = self.counters["institution"]
                self.counters["institution"] += 1

                inst_type = inst_type_config["type"]

                # Generate institution name based on type
                if inst_type == "UNIVERSITY":
                    name = f"{self.fake.city()} University"
                    code = f"U{inst_id:03d}"
                elif inst_type == "COLLEGE":
                    name = f"{self.fake.last_name()} College"
                    code = f"C{inst_id:03d}"
                elif inst_type == "ONLINE":
                    name = f"{self.fake.catch_phrase()} Online Academy"
                    code = f"OA{inst_id:03d}"
                else:
                    name = f"{self.fake.company()} Institute"
                    code = f"I{inst_id:03d}"

                # Select subscription tier
                tier = self._weighted_choice(
                    list(
                        self.config["institutions_config"]["subscription_tiers"].keys()
                    ),
                    list(
                        self.config["institutions_config"][
                            "subscription_tiers"
                        ].values()
                    ),
                )

                # Calculate limits based on tier
                storage_limits = {
                    "FREE": 10,
                    "BASIC": 100,
                    "PROFESSIONAL": 500,
                    "ENTERPRISE": 5000,
                }

                institution = {
                    "institution_id": inst_id,
                    "institution_code": code,
                    "institution_name": name,
                    "institution_type": inst_type,
                    "website_url": f"https://www.{name.lower().replace(' ', '')}.edu",
                    "logo_url": f"https://assets.edu/{code}/logo.png",
                    "primary_color": f"#{random.randint(0, 0xFFFFFF):06x}",
                    "secondary_color": f"#{random.randint(0, 0xFFFFFF):06x}",
                    "timezone": random.choice(
                        ["US/Eastern", "US/Central", "US/Mountain", "US/Pacific"]
                    ),
                    "academic_year_start": 9,  # September
                    "grading_scale": json.dumps(
                        {"A": 90, "B": 80, "C": 70, "D": 60, "F": 0}
                    ),
                    "contact_email": f"info@{name.lower().replace(' ', '')}.edu",
                    "contact_phone": self.fake.phone_number(),
                    "address_line1": self.fake.street_address(),
                    "address_line2": (
                        self.fake.secondary_address() if random.random() > 0.7 else None
                    ),
                    "city": self.fake.city(),
                    "state_province": self.fake.state(),
                    "postal_code": self.fake.zipcode(),
                    "country_code": "US",
                    "student_count": inst_type_config["avg_students"],
                    "instructor_count": inst_type_config["avg_students"] // 20,
                    "course_count": inst_type_config["avg_courses"],
                    "subscription_tier": tier,
                    "subscription_expires": (
                        datetime.now() + timedelta(days=365)
                    ).date(),
                    "storage_used_gb": round(
                        random.uniform(1, storage_limits[tier] * 0.7), 2
                    ),
                    "storage_limit_gb": storage_limits[tier],
                    "is_active": True,
                }

                self.institutions.append(institution)

    def generate_departments(self):
        """Generate academic departments for each institution"""
        print("  Generating departments...")

        dept_names = self.config["departments_list"]

        for institution in self.institutions:
            # Each institution gets a subset of departments
            num_depts = min(10, len(dept_names))
            selected_depts = random.sample(dept_names, num_depts)

            for dept_name in selected_depts:
                dept_id = self.counters["department"]
                self.counters["department"] += 1

                # Generate department code
                dept_code = "".join(word[0] for word in dept_name.split())[:4].upper()

                department = {
                    "department_id": dept_id,
                    "institution_id": institution["institution_id"],
                    "department_code": f"{dept_code}{dept_id:02d}",
                    "department_name": dept_name,
                    "department_head_id": None,  # Will be assigned after users are created
                    "description": f"The {dept_name} department offers comprehensive programs in various aspects of {dept_name.lower()}.",
                }

                self.departments.append(department)

    def generate_academic_terms(self):
        """Generate academic terms (semesters/quarters)"""
        print("  Generating academic terms...")

        for institution in self.institutions:
            # Generate terms for current academic year
            year = 2024

            terms_config = [
                ("FALL", f"Fall {year}", "SEMESTER", f"{year}-09-01", f"{year}-12-20"),
                (
                    "SPRING",
                    f"Spring {year+1}",
                    "SEMESTER",
                    f"{year+1}-01-15",
                    f"{year+1}-05-31",
                ),
                (
                    "SUMMER",
                    f"Summer {year+1}",
                    "SUMMER",
                    f"{year+1}-06-01",
                    f"{year+1}-08-15",
                ),
            ]

            for term_code, term_name, term_type, start_date, end_date in terms_config:
                term_id = self.counters["term"]
                self.counters["term"] += 1

                start = datetime.strptime(start_date, "%Y-%m-%d").date()
                end = datetime.strptime(end_date, "%Y-%m-%d").date()

                term = {
                    "term_id": term_id,
                    "institution_id": institution["institution_id"],
                    "term_code": f"{term_code}{year}",
                    "term_name": term_name,
                    "term_type": term_type,
                    "start_date": start,
                    "end_date": end,
                    "registration_start": start - timedelta(days=30),
                    "registration_end": start - timedelta(days=7),
                    "add_drop_deadline": start + timedelta(days=14),
                    "withdrawal_deadline": start + timedelta(days=60),
                    "is_active": term_code == "SPRING",  # Spring 2024 is current
                }

                self.academic_terms.append(term)

    def generate_users(self):
        """Generate users (students, instructors, administrators)"""
        print("  Generating users...")

        # Generate students
        for _ in range(self.config["counts"]["students"]):
            user = self._create_user("STUDENT")
            self.users.append(user)
            self.student_ids.append(user["user_id"])
            self._create_user_profile(user)

        # Generate instructors
        for _ in range(self.config["counts"]["instructors"]):
            user = self._create_user("INSTRUCTOR")
            self.users.append(user)
            self.instructor_ids.append(user["user_id"])
            self._create_user_profile(user)

        # Generate administrators
        for _ in range(self.config["counts"]["admins"]):
            user = self._create_user("ADMIN")
            self.users.append(user)
            self.admin_ids.append(user["user_id"])

        # Assign department heads
        for dept in self.departments:
            # Select an instructor from the same institution
            inst_instructors = [
                u
                for u in self.users
                if u["user_type"] == "INSTRUCTOR"
                and u["institution_id"] == dept["institution_id"]
            ]
            if inst_instructors:
                dept["department_head_id"] = random.choice(inst_instructors)["user_id"]

    def _create_user(self, user_type: str) -> Dict:
        """Create a single user"""
        user_id = self.counters["user"]
        self.counters["user"] += 1

        institution = random.choice(self.institutions)
        first_name = self.fake.first_name()
        last_name = self.fake.last_name()
        username = f"{first_name.lower()}.{last_name.lower()}{random.randint(1, 99)}"
        email = (
            f"{username}@{institution['institution_name'].lower().replace(' ', '')}.edu"
        )

        # Generate student/employee ID
        if user_type == "STUDENT":
            student_id = f"S{user_id:06d}"
            employee_id = None
            status = random.choice(["ACTIVE", "ACTIVE", "ACTIVE", "INACTIVE"])
        else:
            student_id = None
            employee_id = f"E{user_id:06d}"
            status = "ACTIVE"

        user = {
            "user_id": user_id,
            "institution_id": institution["institution_id"],
            "username": username,
            "email": email,
            "password_hash": hashlib.sha256(f"password{user_id}".encode()).hexdigest(),
            "first_name": first_name,
            "last_name": last_name,
            "middle_name": self.fake.first_name() if random.random() > 0.7 else None,
            "display_name": f"{first_name} {last_name}",
            "user_type": user_type,
            "student_id": student_id,
            "employee_id": employee_id,
            "date_of_birth": self.fake.date_of_birth(minimum_age=18, maximum_age=65),
            "gender": random.choice(["MALE", "FEMALE", "OTHER", "PREFER_NOT_TO_SAY"]),
            "phone_number": self.fake.phone_number(),
            "phone_verified": random.random() > 0.3,
            "email_verified": random.random() > 0.1,
            "profile_picture_url": f"https://avatars.edu/{user_id}.jpg",
            "bio": self.fake.paragraph() if user_type == "INSTRUCTOR" else None,
            "preferred_language": "en",
            "timezone": institution["timezone"],
            "notification_preferences": json.dumps(
                self.config["notification_settings"]
            ),
            "last_login_at": self.fake.date_time_between(
                start_date="-7d", end_date="now"
            ),
            "last_activity_at": self.fake.date_time_between(
                start_date="-1d", end_date="now"
            ),
            "login_count": random.randint(1, 500),
            "failed_login_attempts": random.randint(0, 3),
            "account_locked_until": None,
            "two_factor_enabled": random.random() > 0.7,
            "two_factor_secret": (
                hashlib.sha256(f"2fa{user_id}".encode()).hexdigest()
                if random.random() > 0.7
                else None
            ),
            "status": status,
            "graduation_year": (
                random.randint(2024, 2028) if user_type == "STUDENT" else None
            ),
        }

        return user

    def _create_user_profile(self, user: Dict):
        """Create extended user profile"""
        profile_id = self.counters["profile"]
        self.counters["profile"] += 1

        if user["user_type"] == "STUDENT":
            # Student profile
            major = random.choice(
                [dept["department_name"] for dept in self.departments]
            )
            gpa = round(random.uniform(2.0, 4.0), 2)
            credits_earned = random.randint(0, 120)

            profile = {
                "profile_id": profile_id,
                "user_id": user["user_id"],
                "major": major,
                "minor": (
                    random.choice(
                        [dept["department_name"] for dept in self.departments]
                    )
                    if random.random() > 0.7
                    else None
                ),
                "gpa": gpa,
                "credits_earned": credits_earned,
                "credits_required": 120,
                "expected_graduation": (
                    date(user["graduation_year"], 5, 31)
                    if user["graduation_year"]
                    else None
                ),
                "academic_standing": "GOOD" if gpa >= 2.5 else "PROBATION",
                "occupation": None,
                "employer": None,
                "years_experience": None,
                "learning_style": self._weighted_choice(
                    list(self.config["learning_preferences"]["styles"].keys()),
                    list(self.config["learning_preferences"]["styles"].values()),
                ),
                "preferred_pace": self._weighted_choice(
                    list(self.config["learning_preferences"]["pace"].keys()),
                    list(self.config["learning_preferences"]["pace"].values()),
                ),
                "interests": json.dumps(
                    random.sample(list(self.course_subjects.keys()), k=3)
                ),
                "skills": json.dumps(
                    random.sample(
                        ["Python", "Java", "SQL", "Excel", "Writing", "Research"], k=3
                    )
                ),
                "certifications": json.dumps([]),
                "accessibility_needs": (
                    json.dumps([]) if random.random() > 0.95 else json.dumps([])
                ),
                "accommodations_required": random.random() > 0.95,
                "accommodations_details": None,
            }

        else:  # INSTRUCTOR
            profile = {
                "profile_id": profile_id,
                "user_id": user["user_id"],
                "major": None,
                "minor": None,
                "gpa": None,
                "credits_earned": None,
                "credits_required": None,
                "expected_graduation": None,
                "academic_standing": None,
                "occupation": "Professor",
                "employer": next(
                    i["institution_name"]
                    for i in self.institutions
                    if i["institution_id"] == user["institution_id"]
                ),
                "years_experience": random.randint(1, 30),
                "learning_style": None,
                "preferred_pace": None,
                "interests": json.dumps(
                    random.sample(list(self.course_subjects.keys()), k=2)
                ),
                "skills": json.dumps(
                    random.sample(
                        ["Teaching", "Research", "Mentoring", "Publishing"], k=3
                    )
                ),
                "certifications": (
                    json.dumps(["PhD", "Teaching Certificate"])
                    if random.random() > 0.5
                    else json.dumps(["Masters"])
                ),
                "accessibility_needs": json.dumps([]),
                "accommodations_required": False,
                "accommodations_details": None,
            }

        self.user_profiles.append(profile)

    def generate_courses(self):
        """Generate course catalog"""
        print("  Generating courses...")

        for _ in range(self.config["counts"]["courses"]):
            course_id = self.counters["course"]
            self.counters["course"] += 1

            department = random.choice(self.departments)
            institution = next(
                i
                for i in self.institutions
                if i["institution_id"] == department["institution_id"]
            )

            # Select course subject area
            subject_area = random.choice(list(self.course_subjects.keys()))
            topic = random.choice(self.course_subjects[subject_area])

            # Generate course code and name
            level_num = random.choice(["101", "201", "301", "401", "501"])
            course_code = f"{department['department_code']}{level_num}"
            course_name = f"{topic} {random.choice(['Fundamentals', 'Introduction', 'Advanced', 'Topics in', 'Principles of'])}"

            # Select course level based on code
            if level_num[0] in ["1", "2"]:
                level = "INTRODUCTORY"
            elif level_num[0] == "3":
                level = "INTERMEDIATE"
            elif level_num[0] == "4":
                level = "ADVANCED"
            else:
                level = "GRADUATE"

            # Generate learning outcomes
            outcomes = []
            for _ in range(random.randint(3, 5)):
                outcome_template = random.choice(self.learning_outcomes)
                outcomes.append(outcome_template.format(topic.lower()))

            course = {
                "course_id": course_id,
                "institution_id": institution["institution_id"],
                "department_id": department["department_id"],
                "course_code": course_code,
                "course_name": course_name,
                "course_description": self.fake.paragraph(nb_sentences=5),
                "syllabus_url": f"https://syllabus.edu/{course_code}.pdf",
                "credits": random.choice(self.config["course_config"]["credits"]),
                "course_level": level,
                "format": self._weighted_choice(
                    list(self.config["course_config"]["formats"].keys()),
                    list(self.config["course_config"]["formats"].values()),
                ),
                "duration_weeks": random.choice(
                    self.config["course_config"]["duration_weeks"]
                ),
                "hours_per_week": random.choice(
                    self.config["course_config"]["hours_per_week"]
                ),
                "max_students": random.choice(
                    self.config["course_config"]["max_students"]
                ),
                "min_students": 5,
                "prerequisites": (
                    json.dumps([])
                    if level == "INTRODUCTORY"
                    else (
                        json.dumps([random.randint(1, course_id - 1)])
                        if course_id > 1
                        else json.dumps([])
                    )
                ),
                "corequisites": json.dumps([]),
                "learning_outcomes": json.dumps(outcomes),
                "required_materials": json.dumps(
                    [f"Textbook: {topic} ({random.randint(1, 10)}th Edition)"]
                ),
                "tags": json.dumps([subject_area, topic, level]),
                "is_active": True,
                "version": 1,
                "created_by": random.choice(self.instructor_ids),
                "approved_by": (
                    random.choice(self.admin_ids) if self.admin_ids else None
                ),
                "approved_date": datetime.now()
                - timedelta(days=random.randint(30, 365)),
            }

            self.courses.append(course)

            # Generate course modules
            self._generate_course_modules(course_id, topic)

    def _generate_course_modules(self, course_id: int, topic: str):
        """Generate modules for a course"""
        num_modules = random.randint(8, 12)

        for module_num in range(1, num_modules + 1):
            module_id = self.counters["module"]
            self.counters["module"] += 1

            module = {
                "module_id": module_id,
                "course_id": course_id,
                "module_number": module_num,
                "module_name": f"Module {module_num}: {self.fake.catch_phrase()}",
                "module_description": self.fake.paragraph(),
                "learning_objectives": json.dumps(
                    [self.fake.sentence() for _ in range(3)]
                ),
                "estimated_hours": round(random.uniform(2, 8), 1),
                "is_published": True,
                "unlock_date": datetime.now() + timedelta(weeks=module_num - 1),
                "due_date": datetime.now() + timedelta(weeks=module_num),
                "sort_order": module_num,
            }

            self.course_modules.append(module)

            # Generate lessons for this module
            self._generate_lessons(module_id, module_num)

    def _generate_lessons(self, module_id: int, module_num: int):
        """Generate lessons for a module"""
        num_lessons = random.randint(3, 6)

        for lesson_num in range(1, num_lessons + 1):
            lesson_id = self.counters["lesson"]
            self.counters["lesson"] += 1

            lesson = {
                "lesson_id": lesson_id,
                "module_id": module_id,
                "lesson_number": lesson_num,
                "lesson_name": f"Lesson {module_num}.{lesson_num}: {self.fake.catch_phrase()}",
                "lesson_type": random.choice(
                    ["VIDEO", "TEXT", "INTERACTIVE", "ASSIGNMENT"]
                ),
                "content_url": f"https://content.edu/lesson_{lesson_id}",
                "content_text": self.fake.text(max_nb_chars=2000),
                "estimated_minutes": random.randint(15, 60),
                "is_required": random.random() > 0.2,
                "sort_order": lesson_num,
            }

            self.lessons.append(lesson)

            # Generate learning resources for this lesson
            self._generate_learning_resources(lesson_id)

    def _generate_learning_resources(self, lesson_id: int):
        """Generate learning resources for a lesson"""
        num_resources = random.randint(1, 4)

        for _ in range(num_resources):
            resource_id = self.counters["resource"]
            self.counters["resource"] += 1

            resource_type = self._weighted_choice(
                list(self.config["resource_types"].keys()),
                list(self.config["resource_types"].values()),
            )

            resource = {
                "resource_id": resource_id,
                "lesson_id": lesson_id,
                "resource_type": resource_type,
                "resource_name": f"{resource_type} - {self.fake.catch_phrase()}",
                "resource_url": f"https://resources.edu/{resource_type.lower()}_{resource_id}",
                "file_size_mb": (
                    random.randint(1, 500)
                    if resource_type in ["VIDEO", "PDF"]
                    else None
                ),
                "duration_minutes": (
                    random.randint(5, 45) if resource_type == "VIDEO" else None
                ),
                "download_count": random.randint(0, 100),
                "is_required": random.random() > 0.5,
            }

            self.learning_resources.append(resource)

    def generate_course_sections(self):
        """Generate course sections (actual class instances)"""
        print("  Generating course sections...")

        for course in self.courses:
            # Create 1-3 sections per course
            num_sections = random.randint(1, 3)

            for section_num in range(1, num_sections + 1):
                section_id = self.counters["section"]
                self.counters["section"] += 1

                # Select term
                inst_terms = [
                    t
                    for t in self.academic_terms
                    if t["institution_id"] == course["institution_id"]
                ]
                term = (
                    random.choice(inst_terms) if inst_terms else self.academic_terms[0]
                )

                # Select instructor
                inst_instructors = [
                    u
                    for u in self.users
                    if u["user_type"] == "INSTRUCTOR"
                    and u["institution_id"] == course["institution_id"]
                ]
                instructor = (
                    random.choice(inst_instructors)
                    if inst_instructors
                    else self.users[0]
                )

                # Generate meeting schedule
                if course["format"] == "IN_PERSON":
                    meeting_pattern = random.choice(["MWF", "TTH", "MW"])
                    meeting_days = self._get_meeting_days(meeting_pattern)
                    start_time = time(random.choice([8, 9, 10, 11, 13, 14, 15, 16]), 0)
                    end_time = time(start_time.hour + random.choice([1, 2, 3]), 0)
                    location = f"Building {random.choice(['A', 'B', 'C', 'D'])}"
                    room = f"{random.randint(100, 499)}"
                    is_online = False
                    meeting_url = None
                elif course["format"] == "ONLINE":
                    meeting_pattern = "CUSTOM"
                    meeting_days = []
                    start_time = None
                    end_time = None
                    location = "Online"
                    room = None
                    is_online = True
                    meeting_url = (
                        f"https://zoom.us/j/{random.randint(10000000000, 99999999999)}"
                    )
                else:  # HYBRID
                    meeting_pattern = random.choice(["MW", "TTH"])
                    meeting_days = self._get_meeting_days(meeting_pattern)
                    start_time = time(random.choice([9, 10, 14, 15]), 0)
                    end_time = time(start_time.hour + 1, 30)
                    location = f"Building {random.choice(['A', 'B', 'C'])}"
                    room = f"{random.randint(100, 299)}"
                    is_online = True
                    meeting_url = (
                        f"https://zoom.us/j/{random.randint(10000000000, 99999999999)}"
                    )

                section = {
                    "section_id": section_id,
                    "course_id": course["course_id"],
                    "term_id": term["term_id"],
                    "section_code": f"{course['course_code']}-{section_num:02d}",
                    "instructor_id": instructor["user_id"],
                    "co_instructor_id": None,
                    "teaching_assistants": (
                        json.dumps([])
                        if course["course_level"] != "GRADUATE"
                        else json.dumps([random.choice(self.student_ids)])
                    ),
                    "meeting_pattern": meeting_pattern,
                    "meeting_days": (
                        json.dumps(list(meeting_days))
                        if meeting_days
                        else json.dumps([])
                    ),
                    "start_time": start_time,
                    "end_time": end_time,
                    "location": location,
                    "room_number": room,
                    "is_online": is_online,
                    "meeting_url": meeting_url,
                    "enrollment_capacity": course["max_students"],
                    "enrollment_count": 0,  # Will be updated
                    "waitlist_capacity": 10,
                    "waitlist_count": 0,
                    "allow_auditing": random.random() > 0.7,
                    "allow_late_enrollment": random.random() > 0.8,
                    "require_attendance": random.random() > 0.5,
                    "record_lectures": is_online or random.random() > 0.7,
                    "status": "IN_PROGRESS" if term["is_active"] else "COMPLETED",
                }

                self.course_sections.append(section)

    def _get_meeting_days(self, pattern: str) -> set:
        """Convert meeting pattern to set of days"""
        patterns = {
            "MWF": {"MON", "WED", "FRI"},
            "TTH": {"TUE", "THU"},
            "MW": {"MON", "WED"},
            "DAILY": {"MON", "TUE", "WED", "THU", "FRI"},
            "WEEKLY": {random.choice(["MON", "TUE", "WED", "THU", "FRI"])},
        }
        return patterns.get(pattern, set())

    def generate_enrollments(self):
        """Generate student enrollments"""
        print("  Generating enrollments...")

        # Each student enrolls in multiple courses
        for student_id in self.student_ids:
            student = next(u for u in self.users if u["user_id"] == student_id)

            # Get sections from student's institution
            inst_sections = [
                s
                for s in self.course_sections
                if any(
                    c["institution_id"] == student["institution_id"]
                    for c in self.courses
                    if c["course_id"] == s["course_id"]
                )
            ]

            if not inst_sections:
                continue

            # Number of courses to enroll in
            num_courses = min(random.randint(3, 6), len(inst_sections))

            selected_sections = random.sample(inst_sections, num_courses)

            for section in selected_sections:
                enrollment_id = self.counters["enrollment"]
                self.counters["enrollment"] += 1

                # Determine enrollment status
                if random.random() < self.config["enrollment_patterns"]["drop_rate"]:
                    status = "DROPPED"
                    grade = None
                elif (
                    random.random()
                    < self.config["enrollment_patterns"]["waitlist_rate"]
                ):
                    status = "WAITLISTED"
                    grade = None
                else:
                    status = "ENROLLED"
                    # Generate final grade
                    grade = self._weighted_choice(
                        list(
                            self.config["grading_config"]["grade_distribution"].keys()
                        ),
                        list(
                            self.config["grading_config"]["grade_distribution"].values()
                        ),
                    )

                enrollment = {
                    "enrollment_id": enrollment_id,
                    "student_id": student_id,
                    "section_id": section["section_id"],
                    "enrollment_date": datetime.now()
                    - timedelta(days=random.randint(60, 90)),
                    "enrollment_status": status,
                    "enrollment_type": "CREDIT",
                    "grade": grade,
                    "grade_points": (
                        self._calculate_grade_points(grade) if grade else None
                    ),
                    "attendance_percentage": (
                        random.uniform(60, 100) if status == "ENROLLED" else None
                    ),
                    "last_accessed": datetime.now()
                    - timedelta(days=random.randint(0, 7)),
                    "completion_date": (
                        datetime.now() if status == "ENROLLED" and grade else None
                    ),
                }

                self.enrollments.append(enrollment)

                # Update section enrollment count
                if status == "ENROLLED":
                    section["enrollment_count"] += 1
                    self.section_students[section["section_id"]].append(student_id)
                    self.student_courses[student_id].append(section["section_id"])
                elif status == "WAITLISTED":
                    section["waitlist_count"] += 1

    def _calculate_grade_points(self, grade: str) -> float:
        """Calculate grade points from letter grade"""
        grade_points = {"A": 4.0, "B": 3.0, "C": 2.0, "D": 1.0, "F": 0.0}
        return grade_points.get(grade, 0.0)

    def generate_assignments(self):
        """Generate assignments for courses"""
        print("  Generating assignments...")

        for section in self.course_sections:
            # Get course info
            course = next(
                c for c in self.courses if c["course_id"] == section["course_id"]
            )

            # Generate various assignment types
            assignments_config = [
                ("HOMEWORK", 5, 0.20),
                ("QUIZ", 4, 0.15),
                ("EXAM", 2, 0.30),
                ("PROJECT", 1, 0.25),
                ("PARTICIPATION", 1, 0.10),
            ]

            for assignment_type, count, weight in assignments_config:
                for i in range(count):
                    assignment_id = self.counters["assignment"]
                    self.counters["assignment"] += 1

                    # Generate title
                    title_options = self.assignment_titles[assignment_type]
                    title = f"{random.choice(title_options)} {i+1}"

                    # Set dates
                    days_offset = random.randint(7, 90)
                    assigned_date = datetime.now() - timedelta(days=days_offset)
                    due_date = assigned_date + timedelta(
                        days=7 if assignment_type == "HOMEWORK" else 1
                    )

                    assignment = {
                        "assignment_id": assignment_id,
                        "section_id": section["section_id"],
                        "assignment_type": assignment_type,
                        "title": title,
                        "description": self.fake.paragraph(),
                        "instructions": self.fake.text(max_nb_chars=500),
                        "total_points": random.choice([10, 20, 50, 100]),
                        "weight_percentage": weight / count,
                        "assigned_date": assigned_date,
                        "due_date": due_date,
                        "allow_late_submission": random.random() > 0.5,
                        "late_penalty_percent": 10 if random.random() > 0.5 else 0,
                        "submission_type": random.choice(
                            ["FILE_UPLOAD", "TEXT_ENTRY", "URL", "QUIZ"]
                        ),
                        "max_attempts": (
                            1
                            if assignment_type in ["EXAM", "PROJECT"]
                            else random.choice([1, 2, 3])
                        ),
                        "time_limit_minutes": self.config["assessment_config"][
                            "time_limit_minutes"
                        ].get(assignment_type),
                        "is_group_assignment": assignment_type == "PROJECT"
                        and random.random() > 0.5,
                        "rubric_id": None,  # Would link to rubrics table
                        "is_published": True,
                    }

                    self.assignments.append(assignment)

                    # Generate submissions for this assignment
                    self._generate_submissions(assignment, section["section_id"])

    def _generate_submissions(self, assignment: Dict, section_id: int):
        """Generate student submissions for an assignment"""
        enrolled_students = self.section_students.get(section_id, [])

        for student_id in enrolled_students:
            # Determine if student submitted
            if random.random() < 0.9:  # 90% submission rate
                submission_id = self.counters["submission"]
                self.counters["submission"] += 1

                # Determine submission timing
                timing = self._weighted_choice(
                    ["early", "on_time", "late"], [0.2, 0.6, 0.2]
                )

                if timing == "early":
                    submitted_at = assignment["due_date"] - timedelta(
                        days=random.randint(1, 3)
                    )
                elif timing == "on_time":
                    submitted_at = assignment["due_date"] - timedelta(
                        hours=random.randint(1, 24)
                    )
                else:  # late
                    submitted_at = assignment["due_date"] + timedelta(
                        hours=random.randint(1, 48)
                    )

                submission = {
                    "submission_id": submission_id,
                    "assignment_id": assignment["assignment_id"],
                    "student_id": student_id,
                    "submission_number": 1,
                    "submitted_at": submitted_at,
                    "submission_status": "SUBMITTED",
                    "submission_type": assignment["submission_type"],
                    "submission_content": (
                        self.fake.text(max_nb_chars=1000)
                        if assignment["submission_type"] == "TEXT_ENTRY"
                        else None
                    ),
                    "submission_url": (
                        f"https://submissions.edu/{submission_id}"
                        if assignment["submission_type"] in ["FILE_UPLOAD", "URL"]
                        else None
                    ),
                    "file_name": (
                        f"submission_{submission_id}.pdf"
                        if assignment["submission_type"] == "FILE_UPLOAD"
                        else None
                    ),
                    "file_size_kb": (
                        random.randint(100, 5000)
                        if assignment["submission_type"] == "FILE_UPLOAD"
                        else None
                    ),
                    "is_late": timing == "late",
                    "attempt_number": 1,
                }

                self.submissions.append(submission)

                # Generate grade for this submission
                self._generate_grade(submission, assignment, timing == "late")

    def _generate_grade(self, submission: Dict, assignment: Dict, is_late: bool):
        """Generate grade for a submission"""
        grade_id = self.counters["grade"]
        self.counters["grade"] += 1

        # Calculate score based on grade distribution
        max_points = assignment["total_points"]
        grade_letter = self._weighted_choice(
            list(self.config["grading_config"]["grade_distribution"].keys()),
            list(self.config["grading_config"]["grade_distribution"].values()),
        )

        # Convert letter grade to percentage
        grade_percentages = {
            "A": random.uniform(0.90, 1.0),
            "B": random.uniform(0.80, 0.89),
            "C": random.uniform(0.70, 0.79),
            "D": random.uniform(0.60, 0.69),
            "F": random.uniform(0, 0.59),
        }

        percentage = grade_percentages[grade_letter]
        points_earned = max_points * percentage

        # Apply late penalty if applicable
        if is_late and assignment.get("late_penalty_percent"):
            points_earned *= 1 - assignment["late_penalty_percent"] / 100

        grade = {
            "grade_id": grade_id,
            "submission_id": submission["submission_id"],
            "assignment_id": assignment["assignment_id"],
            "student_id": submission["student_id"],
            "grader_id": random.choice(self.instructor_ids),
            "points_earned": round(points_earned, 2),
            "points_possible": max_points,
            "percentage": round(percentage * 100, 2),
            "letter_grade": grade_letter,
            "feedback": self.fake.paragraph() if random.random() > 0.5 else None,
            "graded_at": submission["submitted_at"]
            + timedelta(days=random.randint(1, 7)),
            "is_final": True,
        }

        self.grades.append(grade)

    def generate_discussions(self):
        """Generate discussion forums and posts"""
        print("  Generating discussions...")

        for section in self.course_sections[:100]:  # Limit for performance
            # Create 3-5 discussion topics per section
            num_discussions = random.randint(3, 5)

            for i in range(num_discussions):
                discussion_id = self.counters["discussion"]
                self.counters["discussion"] += 1

                discussion = {
                    "discussion_id": discussion_id,
                    "section_id": section["section_id"],
                    "title": f"Discussion {i+1}: {self.fake.catch_phrase()}",
                    "description": self.fake.paragraph(),
                    "created_by": section["instructor_id"],
                    "created_at": datetime.now()
                    - timedelta(days=random.randint(30, 60)),
                    "is_pinned": i == 0,
                    "is_locked": False,
                    "require_initial_post": True,
                    "post_count": 0,
                    "view_count": random.randint(10, 200),
                }

                self.discussions.append(discussion)

                # Generate posts for this discussion
                self._generate_discussion_posts(discussion, section["section_id"])

    def _generate_discussion_posts(self, discussion: Dict, section_id: int):
        """Generate posts in a discussion"""
        participants = self.section_students.get(section_id, [])[
            :10
        ]  # Limit participants

        if not participants:
            return

        num_posts = random.randint(5, 20)

        for _ in range(num_posts):
            post_id = self.counters["post"]
            self.counters["post"] += 1

            # Mix of students and instructor posts
            if random.random() < 0.8:
                author_id = random.choice(participants)
            else:
                author_id = discussion["created_by"]

            post = {
                "post_id": post_id,
                "discussion_id": discussion["discussion_id"],
                "author_id": author_id,
                "parent_post_id": (
                    None
                    if random.random() > 0.5
                    else max(1, post_id - random.randint(1, 3))
                ),
                "content": self.fake.paragraph(nb_sentences=random.randint(2, 5)),
                "posted_at": discussion["created_at"]
                + timedelta(days=random.randint(1, 30)),
                "edited_at": None,
                "is_answer": random.random() > 0.8,
                "upvotes": random.randint(0, 10),
                "is_deleted": False,
            }

            self.discussion_posts.append(post)

            # Update discussion post count
            discussion["post_count"] += 1

    def generate_attendance(self):
        """Generate attendance records"""
        print("  Generating attendance records...")

        for section in self.course_sections[:50]:  # Limit for performance
            if not section.get("require_attendance"):
                continue

            enrolled_students = self.section_students.get(section["section_id"], [])

            # Generate attendance for 10 class sessions
            for session_num in range(1, 11):
                session_date = datetime.now() - timedelta(days=90 - session_num * 7)

                for student_id in enrolled_students:
                    attendance_id = self.counters["attendance"]
                    self.counters["attendance"] += 1

                    # Determine attendance status
                    if (
                        random.random()
                        < self.config["enrollment_patterns"]["attendance_rate"]
                    ):
                        status = "PRESENT"
                    elif random.random() < 0.5:
                        status = "ABSENT"
                    else:
                        status = random.choice(["LATE", "EXCUSED"])

                    attendance = {
                        "attendance_id": attendance_id,
                        "section_id": section["section_id"],
                        "student_id": student_id,
                        "session_date": session_date.date(),
                        "status": status,
                        "check_in_time": (
                            session_date.replace(
                                hour=(
                                    section["start_time"].hour
                                    if section["start_time"]
                                    else 9
                                ),
                                minute=random.randint(0, 15),
                            )
                            if status in ["PRESENT", "LATE"]
                            else None
                        ),
                        "duration_minutes": (
                            random.randint(45, 90) if status == "PRESENT" else None
                        ),
                        "notes": None,
                    }

                    self.attendance_records.append(attendance)

    def generate_analytics(self):
        """Generate learning analytics data"""
        print("  Generating analytics...")

        # Generate activity logs for recent activities
        for _ in range(1000):  # Sample activity logs
            activity_id = self.counters["activity"]
            self.counters["activity"] += 1

            user = random.choice(self.users)

            activity = {
                "activity_id": activity_id,
                "user_id": user["user_id"],
                "activity_type": random.choice(
                    [
                        "LOGIN",
                        "VIEW_COURSE",
                        "SUBMIT_ASSIGNMENT",
                        "VIEW_RESOURCE",
                        "POST_DISCUSSION",
                    ]
                ),
                "activity_details": json.dumps(
                    {"ip": self.fake.ipv4(), "user_agent": self.fake.user_agent()}
                ),
                "timestamp": self.fake.date_time_between(
                    start_date="-30d", end_date="now"
                ),
            }

            self.activity_logs.append(activity)

        # Generate aggregated analytics
        for section in self.course_sections[:50]:
            analytics_id = self.counters["analytics"]
            self.counters["analytics"] += 1

            analytics = {
                "analytics_id": analytics_id,
                "section_id": section["section_id"],
                "metric_date": datetime.now().date(),
                "active_students": len(
                    self.section_students.get(section["section_id"], [])
                ),
                "avg_grade": random.uniform(70, 90),
                "completion_rate": random.uniform(0.6, 0.95),
                "avg_time_spent_minutes": random.randint(30, 180),
                "discussion_posts": random.randint(10, 100),
                "resources_accessed": random.randint(20, 200),
                "assignments_submitted": random.randint(5, 50),
            }

            self.learning_analytics.append(analytics)

    def _weighted_choice(self, choices: List, weights: List):
        """Make a weighted random choice"""
        return random.choices(choices, weights=weights)[0]

    def save_to_csv(self, output_dir: Optional[str] = None):
        """Save all generated data to CSV files"""
        if output_dir is None:
            output_dir = self.config["output_dir"]

        # Create output directory if it doesn't exist
        Path(output_dir).mkdir(parents=True, exist_ok=True)

        # Define tables and their data
        tables = {
            "institutions": self.institutions,
            "departments": self.departments,
            "users": self.users,
            "user_profiles": self.user_profiles,
            "academic_terms": self.academic_terms,
            "courses": self.courses,
            "course_sections": self.course_sections,
            "course_modules": self.course_modules,
            "lessons": self.lessons,
            "learning_resources": self.learning_resources,
            "enrollments": self.enrollments,
            "assignments": self.assignments,
            "submissions": self.submissions,
            "grades": self.grades,
            "discussions": self.discussions,
            "discussion_posts": self.discussion_posts,
            "attendance_records": self.attendance_records,
            "activity_logs": self.activity_logs,
            "learning_analytics": self.learning_analytics,
        }

        # Save each table to CSV
        for table_name, data in tables.items():
            if data:
                file_path = Path(output_dir) / f"{table_name}.csv"

                # Convert dates and complex types to strings
                clean_data = []
                for row in data:
                    clean_row = {}
                    for key, value in row.items():
                        if isinstance(value, (datetime, date, time)):
                            if isinstance(value, datetime):
                                clean_row[key] = value.strftime("%Y-%m-%d %H:%M:%S")
                            elif isinstance(value, date):
                                clean_row[key] = value.strftime("%Y-%m-%d")
                            elif isinstance(value, time):
                                clean_row[key] = value.strftime("%H:%M:%S")
                        elif value is None:
                            clean_row[key] = ""
                        else:
                            clean_row[key] = str(value)
                    clean_data.append(clean_row)

                # Write to CSV
                with open(file_path, "w", newline="", encoding="utf-8") as f:
                    if clean_data:
                        writer = csv.DictWriter(f, fieldnames=clean_data[0].keys())
                        writer.writeheader()
                        writer.writerows(clean_data)

                print(f"  Saved {len(data)} records to {table_name}.csv")

    def generate_all_data(self):
        """Generate all data in the correct sequence"""
        print("Education LMS Data Generator Starting...")
        print(
            f"  Configuration: {self.config['counts']['institutions']} institutions, {self.config['counts']['courses']} courses"
        )

        print("\n1. Generating institutional structure...")
        self.generate_institutions()
        self.generate_departments()
        self.generate_academic_terms()
        print(f"  - {len(self.institutions)} institutions")
        print(f"  - {len(self.departments)} departments")
        print(f"  - {len(self.academic_terms)} academic terms")

        print("\n2. Generating users...")
        self.generate_users()
        print(f"  - {len(self.student_ids)} students")
        print(f"  - {len(self.instructor_ids)} instructors")
        print(f"  - {len(self.admin_ids)} administrators")
        print(f"  - {len(self.user_profiles)} user profiles")

        print("\n3. Generating course catalog...")
        self.generate_courses()
        self.generate_course_sections()
        print(f"  - {len(self.courses)} courses")
        print(f"  - {len(self.course_sections)} course sections")
        print(f"  - {len(self.course_modules)} modules")
        print(f"  - {len(self.lessons)} lessons")
        print(f"  - {len(self.learning_resources)} learning resources")

        print("\n4. Generating enrollments...")
        self.generate_enrollments()
        print(f"  - {len(self.enrollments)} enrollments")

        print("\n5. Generating assignments and grades...")
        self.generate_assignments()
        print(f"  - {len(self.assignments)} assignments")
        print(f"  - {len(self.submissions)} submissions")
        print(f"  - {len(self.grades)} grades")

        print("\n6. Generating interactions...")
        self.generate_discussions()
        self.generate_attendance()
        print(f"  - {len(self.discussions)} discussions")
        print(f"  - {len(self.discussion_posts)} discussion posts")
        print(f"  - {len(self.attendance_records)} attendance records")

        print("\n7. Generating analytics...")
        self.generate_analytics()
        print(f"  - {len(self.activity_logs)} activity logs")
        print(f"  - {len(self.learning_analytics)} analytics records")

        print("\n[COMPLETE] Data generation complete!")
        return self


def main():
    parser = argparse.ArgumentParser(description="Generate education LMS sample data")
    parser.add_argument(
        "--config", type=str, default="config.json", help="Path to configuration file"
    )
    parser.add_argument(
        "--output", type=str, default=None, help="Output directory for CSV files"
    )
    parser.add_argument(
        "--seed", type=int, default=None, help="Random seed for reproducibility"
    )

    args = parser.parse_args()

    # Initialize generator
    generator = EducationDataGenerator(args.config)

    # Override seed if provided
    if args.seed:
        random.seed(args.seed)
        Faker.seed(args.seed)

    # Generate all data
    generator.generate_all_data()

    # Save to CSV files
    print("\n[SAVING] Saving data to CSV files...")
    generator.save_to_csv(args.output)

    print("\n[SUCCESS] Education LMS data generation complete!")
    print(f"  Output directory: {args.output or generator.config['output_dir']}")

    # Print summary statistics
    print("\n[SUMMARY] Statistics:")
    print(f"  Institutions: {len(generator.institutions):,}")
    print(f"  Users: {len(generator.users):,}")
    print(f"  Courses: {len(generator.courses):,}")
    print(f"  Enrollments: {len(generator.enrollments):,}")
    print(f"  Assignments: {len(generator.assignments):,}")
    print(f"  Submissions: {len(generator.submissions):,}")
    print(f"  Grades: {len(generator.grades):,}")
    print(f"  Discussions: {len(generator.discussion_posts):,}")


if __name__ == "__main__":
    main()
