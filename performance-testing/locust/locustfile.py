#!/usr/bin/env python3
"""
Locust Load Testing Suite for MySQL Business-to-Schema
Comprehensive performance testing scenarios
"""

import json
import random
import time
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Any

from locust import HttpUser, task, between, events, tag
from locust.exception import RescheduleTask
from locust.runners import MasterRunner, WorkerRunner
import gevent


# Test data generators
class DataGenerator:
    """Generate realistic test data for different schemas"""

    @staticmethod
    def generate_patient():
        """Generate patient data for clinic schema"""
        return {
            "name": f"Patient {uuid.uuid4().hex[:8]}",
            "date_of_birth": (
                datetime.now() - timedelta(days=random.randint(365, 36500))
            ).isoformat(),
            "gender": random.choice(["Male", "Female", "Other"]),
            "phone": f"+1{random.randint(2000000000, 9999999999)}",
            "email": f"patient{uuid.uuid4().hex[:8]}@example.com",
            "address": f"{random.randint(100, 9999)} Main St, City, ST {random.randint(10000, 99999)}",
            "insurance_provider": random.choice(
                ["Blue Cross", "Aetna", "United Health", "Kaiser"]
            ),
            "medical_history": {
                "allergies": random.choice(
                    [[], ["Penicillin"], ["Peanuts"], ["Latex"]]
                ),
                "conditions": random.choice(
                    [[], ["Diabetes"], ["Hypertension"], ["Asthma"]]
                ),
            },
        }

    @staticmethod
    def generate_appointment():
        """Generate appointment data"""
        return {
            "patient_id": random.randint(1, 10000),
            "doctor_id": random.randint(1, 100),
            "appointment_date": (
                datetime.now() + timedelta(days=random.randint(1, 30))
            ).isoformat(),
            "appointment_type": random.choice(
                ["Checkup", "Consultation", "Follow-up", "Emergency"]
            ),
            "status": "scheduled",
            "notes": f"Appointment notes {uuid.uuid4().hex[:8]}",
        }

    @staticmethod
    def generate_order():
        """Generate e-commerce order data"""
        items = []
        for _ in range(random.randint(1, 5)):
            items.append(
                {
                    "product_id": random.randint(1, 1000),
                    "quantity": random.randint(1, 5),
                    "price": round(random.uniform(10, 500), 2),
                }
            )

        total = sum(item["price"] * item["quantity"] for item in items)

        return {
            "customer_id": random.randint(1, 5000),
            "items": items,
            "total_amount": round(total, 2),
            "shipping_address": f"{random.randint(100, 9999)} Commerce St, City, ST {random.randint(10000, 99999)}",
            "payment_method": random.choice(
                ["credit_card", "debit_card", "paypal", "crypto"]
            ),
            "status": "pending",
        }

    @staticmethod
    def generate_iot_reading():
        """Generate IoT sensor reading"""
        sensor_types = {
            "temperature": {"min": -20, "max": 50, "unit": "celsius"},
            "humidity": {"min": 0, "max": 100, "unit": "percent"},
            "pressure": {"min": 950, "max": 1050, "unit": "mbar"},
            "flow_rate": {"min": 0, "max": 100, "unit": "l/min"},
        }

        sensor_type = random.choice(list(sensor_types.keys()))
        sensor_config = sensor_types[sensor_type]

        return {
            "device_id": f"DEV{random.randint(1, 1000):04d}",
            "sensor_type": sensor_type,
            "value": round(
                random.uniform(sensor_config["min"], sensor_config["max"]), 2
            ),
            "unit": sensor_config["unit"],
            "timestamp": datetime.utcnow().isoformat(),
            "location": {
                "lat": round(random.uniform(-90, 90), 6),
                "lon": round(random.uniform(-180, 180), 6),
            },
            "metadata": {
                "battery_level": random.randint(20, 100),
                "signal_strength": random.randint(-100, -30),
            },
        }

    @staticmethod
    def generate_social_post():
        """Generate social media post"""
        return {
            "user_id": random.randint(1, 10000),
            "content": f"Post content {uuid.uuid4().hex} "
            + " ".join([f"word{i}" for i in range(random.randint(5, 50))]),
            "post_type": random.choice(["text", "image", "video", "link"]),
            "tags": [f"tag{i}" for i in range(random.randint(0, 5))],
            "visibility": random.choice(["public", "friends", "private"]),
        }


# Base user class with common functionality
class BaseUser(HttpUser):
    """Base user with common authentication and headers"""

    def on_start(self):
        """Called when a user starts"""
        # Login and get token
        response = self.client.post(
            "/api/auth/login",
            json={
                "username": f"user{random.randint(1, 1000)}",
                "password": "password123",
            },
            catch_response=True,
        )

        if response.status_code == 200:
            self.token = response.json().get("token")
            self.headers = {"Authorization": f"Bearer {self.token}"}
            response.success()
        else:
            self.token = "dummy_token"
            self.headers = {"Authorization": "Bearer dummy_token"}
            response.failure(f"Login failed: {response.status_code}")

    def on_stop(self):
        """Called when a user stops"""
        # Logout
        self.client.post("/api/auth/logout", headers=self.headers, catch_response=True)


# Clinic System User
class ClinicUser(BaseUser):
    """User simulating clinic system operations"""

    wait_time = between(1, 3)
    weight = 20

    @task(10)
    @tag("read", "clinic")
    def get_patients(self):
        """Get list of patients"""
        with self.client.get(
            "/api/clinic/patients", headers=self.headers, catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to get patients: {response.status_code}")

    @task(5)
    @tag("write", "clinic")
    def create_patient(self):
        """Create a new patient"""
        patient_data = DataGenerator.generate_patient()

        with self.client.post(
            "/api/clinic/patients",
            json=patient_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to create patient: {response.status_code}")

    @task(8)
    @tag("read", "clinic")
    def get_patient_details(self):
        """Get specific patient details"""
        patient_id = random.randint(1, 10000)

        with self.client.get(
            f"/api/clinic/patients/{patient_id}",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.success()  # Not found is acceptable
            else:
                response.failure(
                    f"Failed to get patient {patient_id}: {response.status_code}"
                )

    @task(7)
    @tag("write", "clinic")
    def create_appointment(self):
        """Create an appointment"""
        appointment_data = DataGenerator.generate_appointment()

        with self.client.post(
            "/api/clinic/appointments",
            json=appointment_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(
                    f"Failed to create appointment: {response.status_code}"
                )

    @task(3)
    @tag("update", "clinic")
    def update_appointment(self):
        """Update appointment status"""
        appointment_id = random.randint(1, 10000)

        with self.client.patch(
            f"/api/clinic/appointments/{appointment_id}",
            json={"status": random.choice(["confirmed", "cancelled", "completed"])},
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 204]:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(
                    f"Failed to update appointment: {response.status_code}"
                )


# E-commerce User
class EcommerceUser(BaseUser):
    """User simulating e-commerce operations"""

    wait_time = between(0.5, 2)
    weight = 30

    @task(15)
    @tag("read", "ecommerce")
    def browse_products(self):
        """Browse product catalog"""
        category = random.choice(["electronics", "clothing", "books", "home"])

        with self.client.get(
            f"/api/ecommerce/products?category={category}",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to browse products: {response.status_code}")

    @task(10)
    @tag("read", "ecommerce")
    def search_products(self):
        """Search for products"""
        query = random.choice(["laptop", "shirt", "book", "chair", "phone"])

        with self.client.get(
            f"/api/ecommerce/search?q={query}",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to search products: {response.status_code}")

    @task(8)
    @tag("write", "ecommerce")
    def add_to_cart(self):
        """Add item to cart"""
        cart_item = {
            "product_id": random.randint(1, 1000),
            "quantity": random.randint(1, 3),
        }

        with self.client.post(
            "/api/ecommerce/cart",
            json=cart_item,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to add to cart: {response.status_code}")

    @task(5)
    @tag("write", "ecommerce")
    def create_order(self):
        """Create an order"""
        order_data = DataGenerator.generate_order()

        with self.client.post(
            "/api/ecommerce/orders",
            json=order_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to create order: {response.status_code}")

    @task(3)
    @tag("read", "ecommerce")
    def get_order_status(self):
        """Check order status"""
        order_id = random.randint(1, 10000)

        with self.client.get(
            f"/api/ecommerce/orders/{order_id}",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(f"Failed to get order status: {response.status_code}")


# IoT System User
class IoTUser(BaseUser):
    """User simulating IoT device operations"""

    wait_time = between(0.1, 1)
    weight = 35

    @task(50)
    @tag("write", "iot")
    def send_reading(self):
        """Send sensor reading"""
        reading_data = DataGenerator.generate_iot_reading()

        with self.client.post(
            "/api/iot/readings",
            json=reading_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201, 204]:
                response.success()
            else:
                response.failure(f"Failed to send reading: {response.status_code}")

    @task(10)
    @tag("write", "iot")
    def send_batch_readings(self):
        """Send batch of readings"""
        readings = [
            DataGenerator.generate_iot_reading() for _ in range(random.randint(10, 50))
        ]

        with self.client.post(
            "/api/iot/readings/batch",
            json={"readings": readings},
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201, 204]:
                response.success()
            else:
                response.failure(
                    f"Failed to send batch readings: {response.status_code}"
                )

    @task(5)
    @tag("read", "iot")
    def get_device_status(self):
        """Get device status"""
        device_id = f"DEV{random.randint(1, 1000):04d}"

        with self.client.get(
            f"/api/iot/devices/{device_id}/status",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(f"Failed to get device status: {response.status_code}")

    @task(3)
    @tag("read", "iot")
    def get_device_history(self):
        """Get device reading history"""
        device_id = f"DEV{random.randint(1, 1000):04d}"

        with self.client.get(
            f"/api/iot/devices/{device_id}/history?hours=24",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(
                    f"Failed to get device history: {response.status_code}"
                )


# Social Media User
class SocialMediaUser(BaseUser):
    """User simulating social media operations"""

    wait_time = between(0.5, 2)
    weight = 15

    @task(20)
    @tag("read", "social")
    def get_feed(self):
        """Get user feed"""
        with self.client.get(
            "/api/social/feed", headers=self.headers, catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to get feed: {response.status_code}")

    @task(10)
    @tag("write", "social")
    def create_post(self):
        """Create a post"""
        post_data = DataGenerator.generate_social_post()

        with self.client.post(
            "/api/social/posts",
            json=post_data,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            else:
                response.failure(f"Failed to create post: {response.status_code}")

    @task(8)
    @tag("write", "social")
    def like_post(self):
        """Like a post"""
        post_id = random.randint(1, 100000)

        with self.client.post(
            f"/api/social/posts/{post_id}/like",
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201, 204]:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(f"Failed to like post: {response.status_code}")

    @task(5)
    @tag("write", "social")
    def comment_on_post(self):
        """Comment on a post"""
        post_id = random.randint(1, 100000)
        comment = {"content": f"Comment {uuid.uuid4().hex[:8]}"}

        with self.client.post(
            f"/api/social/posts/{post_id}/comments",
            json=comment,
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 201]:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(f"Failed to comment: {response.status_code}")

    @task(3)
    @tag("read", "social")
    def get_profile(self):
        """Get user profile"""
        user_id = random.randint(1, 10000)

        with self.client.get(
            f"/api/social/users/{user_id}", headers=self.headers, catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            elif response.status_code == 404:
                response.success()
            else:
                response.failure(f"Failed to get profile: {response.status_code}")


# Admin User for Complex Operations
class AdminUser(BaseUser):
    """User simulating admin operations"""

    wait_time = between(2, 5)
    weight = 5

    @task(10)
    @tag("read", "admin")
    def get_dashboard_metrics(self):
        """Get dashboard metrics"""
        with self.client.get(
            "/api/admin/metrics/dashboard", headers=self.headers, catch_response=True
        ) as response:
            if response.status_code == 200:
                response.success()
            else:
                response.failure(f"Failed to get dashboard: {response.status_code}")

    @task(5)
    @tag("read", "admin")
    def run_report(self):
        """Run analytics report"""
        report_type = random.choice(["revenue", "users", "performance", "errors"])

        with self.client.post(
            "/api/admin/reports/generate",
            json={"type": report_type, "period": "last_7_days"},
            headers=self.headers,
            catch_response=True,
        ) as response:
            if response.status_code in [200, 202]:
                response.success()
            else:
                response.failure(f"Failed to run report: {response.status_code}")

    @task(3)
    @tag("write", "admin")
    def update_configuration(self):
        """Update system configuration"""
        config = {
            "setting": f"config_{random.randint(1, 100)}",
            "value": random.choice(["true", "false", "100", "enabled", "disabled"]),
        }

        with self.client.put(
            "/api/admin/config", json=config, headers=self.headers, catch_response=True
        ) as response:
            if response.status_code in [200, 204]:
                response.success()
            else:
                response.failure(f"Failed to update config: {response.status_code}")

    @task(2)
    @tag("write", "admin")
    def trigger_backup(self):
        """Trigger database backup"""
        with self.client.post(
            "/api/admin/backup/trigger", headers=self.headers, catch_response=True
        ) as response:
            if response.status_code in [200, 202]:
                response.success()
            else:
                response.failure(f"Failed to trigger backup: {response.status_code}")


# Event handlers for metrics collection
@events.request.add_listener
def on_request(
    request_type,
    name,
    response_time,
    response_length,
    response,
    context,
    exception,
    **kwargs,
):
    """Custom request handler for additional metrics"""
    if exception:
        print(f"Request failed: {name} - {exception}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Initialize test environment"""
    print("Starting load test...")
    print(f"Target host: {environment.host}")


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Clean up after test"""
    print("Load test completed")
    print(f"Total requests: {environment.stats.total.num_requests}")
    print(f"Failure rate: {environment.stats.total.fail_ratio:.2%}")
    print(f"Average response time: {environment.stats.total.avg_response_time:.2f}ms")
