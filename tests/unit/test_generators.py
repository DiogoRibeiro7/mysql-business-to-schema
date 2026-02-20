"""
Unit tests for data generators.
"""

import pytest
import json
from pathlib import Path
import sys
sys.path.append(str(Path(__file__).parent.parent.parent))

from generators.base_generator import BaseGenerator
from generators.clinic_generator import ClinicDataGenerator
from generators.iot_generator import IoTDataGenerator
from generators.ecommerce_generator import EcommerceDataGenerator
from unittest.mock import Mock, patch, MagicMock

@pytest.mark.unit
class TestBaseGenerator:
    """Test the base generator functionality."""

    def test_generator_initialization(self):
        """Test generator initializes correctly."""
        generator = BaseGenerator(
            host="localhost",
            user="root",
            password="test",
            database="test_db"
        )
        assert generator.host == "localhost"
        assert generator.user == "root"
        assert generator.database == "test_db"

    @patch('mysql.connector.connect')
    def test_connection_established(self, mock_connect):
        """Test database connection is established."""
        mock_conn = Mock()
        mock_connect.return_value = mock_conn

        generator = BaseGenerator(
            host="localhost",
            user="root",
            password="test",
            database="test_db"
        )

        mock_connect.assert_called_once_with(
            host="localhost",
            user="root",
            password="test",
            database="test_db"
        )

    def test_batch_insert_query_generation(self):
        """Test batch insert SQL query generation."""
        generator = BaseGenerator("localhost", "root", "test", "test_db")

        table = "users"
        columns = ["id", "name", "email"]
        values = [
            (1, "John", "john@example.com"),
            (2, "Jane", "jane@example.com")
        ]

        query = generator._generate_batch_insert(table, columns, values)

        assert "INSERT INTO users" in query
        assert "(id, name, email)" in query
        assert "VALUES" in query

    def test_safe_string_escaping(self):
        """Test SQL injection prevention in string escaping."""
        generator = BaseGenerator("localhost", "root", "test", "test_db")

        # Test dangerous inputs
        dangerous_inputs = [
            "'; DROP TABLE users; --",
            "1' OR '1'='1",
            "admin'--",
            "' UNION SELECT * FROM passwords --"
        ]

        for dangerous_input in dangerous_inputs:
            escaped = generator._escape_string(dangerous_input)
            assert "DROP TABLE" not in escaped or "\\" in escaped
            assert "UNION SELECT" not in escaped or "\\" in escaped

@pytest.mark.unit
class TestClinicDataGenerator:
    """Test clinic data generation."""

    @patch('mysql.connector.connect')
    def test_patient_data_generation(self, mock_connect):
        """Test patient data generation."""
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        generator = ClinicDataGenerator("localhost", "root", "test", "clinic_db")
        patients = generator.generate_patients(count=5)

        assert len(patients) == 5
        for patient in patients:
            assert "first_name" in patient
            assert "last_name" in patient
            assert "email" in patient
            assert "phone" in patient
            assert "date_of_birth" in patient

    @patch('mysql.connector.connect')
    def test_appointment_generation(self, mock_connect):
        """Test appointment generation."""
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        generator = ClinicDataGenerator("localhost", "root", "test", "clinic_db")
        appointments = generator.generate_appointments(
            patient_ids=[1, 2, 3],
            doctor_ids=[1, 2],
            count=10
        )

        assert len(appointments) == 10
        for appointment in appointments:
            assert appointment["patient_id"] in [1, 2, 3]
            assert appointment["doctor_id"] in [1, 2]
            assert "appointment_date" in appointment
            assert "status" in appointment

    def test_medical_record_generation(self):
        """Test medical record generation with realistic data."""
        generator = ClinicDataGenerator("localhost", "root", "test", "clinic_db")

        record = generator.generate_medical_record(patient_id=1)

        assert record["patient_id"] == 1
        assert "diagnosis" in record
        assert "symptoms" in record
        assert "prescription" in record
        assert "notes" in record

@pytest.mark.unit
class TestIoTDataGenerator:
    """Test IoT data generation."""

    @patch('mysql.connector.connect')
    def test_sensor_data_generation(self, mock_connect):
        """Test IoT sensor data generation."""
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        generator = IoTDataGenerator("localhost", "root", "test", "iot_db")

        sensor_data = generator.generate_sensor_readings(
            device_ids=["sensor_001", "sensor_002"],
            count=100
        )

        assert len(sensor_data) == 100
        for reading in sensor_data:
            assert reading["device_id"] in ["sensor_001", "sensor_002"]
            assert "temperature" in reading
            assert "humidity" in reading
            assert "timestamp" in reading
            assert 15 <= reading["temperature"] <= 35
            assert 30 <= reading["humidity"] <= 80

    def test_anomaly_injection(self):
        """Test anomaly injection in IoT data."""
        generator = IoTDataGenerator("localhost", "root", "test", "iot_db")

        # Generate normal data
        normal_data = generator.generate_sensor_readings(
            device_ids=["sensor_001"],
            count=100,
            include_anomalies=False
        )

        # Generate data with anomalies
        anomaly_data = generator.generate_sensor_readings(
            device_ids=["sensor_001"],
            count=100,
            include_anomalies=True,
            anomaly_rate=0.1
        )

        # Check that some anomalies exist
        anomalies = [d for d in anomaly_data if d.get("is_anomaly", False)]
        assert len(anomalies) > 0
        assert len(anomalies) < 20  # Should be around 10%

    def test_time_series_continuity(self):
        """Test time series data has proper continuity."""
        generator = IoTDataGenerator("localhost", "root", "test", "iot_db")

        data = generator.generate_time_series_data(
            device_id="sensor_001",
            start_time="2024-01-01 00:00:00",
            interval_seconds=60,
            count=60
        )

        # Check timestamps are properly spaced
        for i in range(1, len(data)):
            time_diff = (data[i]["timestamp"] - data[i-1]["timestamp"]).seconds
            assert time_diff == 60

@pytest.mark.unit
class TestEcommerceDataGenerator:
    """Test e-commerce data generation."""

    @patch('mysql.connector.connect')
    def test_product_generation(self, mock_connect):
        """Test product data generation."""
        mock_cursor = Mock()
        mock_conn = Mock()
        mock_conn.cursor.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        generator = EcommerceDataGenerator("localhost", "root", "test", "ecommerce_db")

        products = generator.generate_products(count=20)

        assert len(products) == 20
        for product in products:
            assert "name" in product
            assert "description" in product
            assert "price" in product
            assert "category" in product
            assert product["price"] > 0

    def test_order_generation_with_items(self):
        """Test order generation with order items."""
        generator = EcommerceDataGenerator("localhost", "root", "test", "ecommerce_db")

        order = generator.generate_order_with_items(
            user_id=1,
            product_ids=[1, 2, 3, 4, 5],
            max_items=3
        )

        assert order["user_id"] == 1
        assert "order_items" in order
        assert len(order["order_items"]) <= 3
        assert order["total_amount"] > 0

        # Check total amount matches items
        items_total = sum(item["price"] * item["quantity"] for item in order["order_items"])
        assert abs(order["total_amount"] - items_total) < 0.01

    def test_customer_journey_generation(self):
        """Test customer journey data generation."""
        generator = EcommerceDataGenerator("localhost", "root", "test", "ecommerce_db")

        journey = generator.generate_customer_journey(user_id=1)

        expected_events = ["page_view", "product_view", "add_to_cart", "checkout", "purchase"]

        assert len(journey) > 0
        for event in journey:
            assert event["event_type"] in expected_events
            assert "timestamp" in event
            assert "session_id" in event

    def test_inventory_updates(self):
        """Test inventory update generation."""
        generator = EcommerceDataGenerator("localhost", "root", "test", "ecommerce_db")

        updates = generator.generate_inventory_updates(
            product_ids=[1, 2, 3],
            count=10
        )

        assert len(updates) == 10
        for update in updates:
            assert update["product_id"] in [1, 2, 3]
            assert "quantity_change" in update
            assert "reason" in update
            assert update["reason"] in ["sale", "restock", "return", "damaged"]

@pytest.mark.unit
class TestDataValidation:
    """Test data validation utilities."""

    def test_email_validation(self):
        """Test email format validation."""
        from generators.validators import validate_email

        valid_emails = [
            "user@example.com",
            "john.doe@company.co.uk",
            "test+tag@domain.org"
        ]

        invalid_emails = [
            "not-an-email",
            "@example.com",
            "user@",
            "user..@example.com"
        ]

        for email in valid_emails:
            assert validate_email(email) is True

        for email in invalid_emails:
            assert validate_email(email) is False

    def test_phone_validation(self):
        """Test phone number validation."""
        from generators.validators import validate_phone

        valid_phones = [
            "+1-234-567-8900",
            "(234) 567-8900",
            "234.567.8900",
            "2345678900"
        ]

        for phone in valid_phones:
            assert validate_phone(phone) is True

    def test_date_validation(self):
        """Test date format validation."""
        from generators.validators import validate_date

        valid_dates = [
            "2024-01-15",
            "2024-12-31",
            "2023-02-28"
        ]

        invalid_dates = [
            "2024-13-01",  # Invalid month
            "2024-01-32",  # Invalid day
            "24-01-15",    # Wrong format
            "not-a-date"
        ]

        for date in valid_dates:
            assert validate_date(date) is True

        for date in invalid_dates:
            assert validate_date(date) is False

@pytest.mark.unit
class TestPerformanceOptimizations:
    """Test performance optimizations in generators."""

    def test_batch_size_optimization(self):
        """Test optimal batch size calculation."""
        from generators.optimizations import calculate_optimal_batch_size

        # Test with different data sizes
        test_cases = [
            (100, 10),      # Small dataset
            (10000, 100),   # Medium dataset
            (1000000, 1000) # Large dataset
        ]

        for total_records, expected_min_batch in test_cases:
            batch_size = calculate_optimal_batch_size(total_records)
            assert batch_size >= expected_min_batch
            assert batch_size <= 10000  # Max batch size limit

    def test_connection_pooling(self):
        """Test connection pool management."""
        from generators.connection_pool import ConnectionPool

        pool = ConnectionPool(
            host="localhost",
            user="root",
            password="test",
            database="test_db",
            pool_size=5
        )

        # Test acquiring connections
        connections = []
        for i in range(5):
            conn = pool.get_connection()
            assert conn is not None
            connections.append(conn)

        # Test pool exhaustion
        with pytest.raises(TimeoutError):
            pool.get_connection(timeout=0.1)

        # Test connection release
        for conn in connections:
            pool.release_connection(conn)

        # Should be able to get connection again
        conn = pool.get_connection()
        assert conn is not None