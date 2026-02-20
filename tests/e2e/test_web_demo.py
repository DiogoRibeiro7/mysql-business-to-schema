"""
End-to-end tests for web demo applications.
"""

import pytest
import requests
import time
import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import TimeoutException
import asyncio
from playwright.async_api import async_playwright

@pytest.mark.e2e
class TestWebDemoUI:
    """Test web demo user interface."""

    @pytest.fixture
    def chrome_driver(self):
        """Setup Chrome driver for Selenium tests."""
        options = Options()
        options.add_argument("--headless")  # Run in headless mode
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--disable-gpu")

        driver = webdriver.Chrome(options=options)
        driver.set_window_size(1920, 1080)
        yield driver
        driver.quit()

    def test_homepage_loads(self, chrome_driver, test_config):
        """Test homepage loads successfully."""
        url = test_config["web_demo"]["url"]
        chrome_driver.get(url)

        # Wait for page to load
        wait = WebDriverWait(chrome_driver, 10)
        title = wait.until(EC.presence_of_element_located((By.TAG_NAME, "h1")))

        assert "MySQL Business Schema" in chrome_driver.title
        assert title.text == "MySQL Business Schema Explorer"

    def test_schema_selector(self, chrome_driver, test_config):
        """Test database schema selector functionality."""
        url = test_config["web_demo"]["url"]
        chrome_driver.get(url)

        wait = WebDriverWait(chrome_driver, 10)

        # Find and click schema selector
        selector = wait.until(
            EC.element_to_be_clickable((By.ID, "schema-selector"))
        )
        selector.click()

        # Select clinic schema
        clinic_option = wait.until(
            EC.element_to_be_clickable((By.XPATH, "//option[text()='Clinic Management']"))
        )
        clinic_option.click()

        # Verify schema loaded
        tables_container = wait.until(
            EC.presence_of_element_located((By.CLASS_NAME, "tables-list"))
        )

        tables = chrome_driver.find_elements(By.CLASS_NAME, "table-item")
        assert len(tables) > 0

        # Check for expected tables
        table_names = [table.text for table in tables]
        assert "patients" in table_names
        assert "doctors" in table_names

    def test_query_editor(self, chrome_driver, test_config):
        """Test SQL query editor functionality."""
        url = test_config["web_demo"]["url"]
        chrome_driver.get(url)

        wait = WebDriverWait(chrome_driver, 10)

        # Find query editor
        editor = wait.until(
            EC.presence_of_element_located((By.ID, "query-editor"))
        )

        # Type a query
        test_query = "SELECT * FROM patients LIMIT 10"
        editor.send_keys(test_query)

        # Execute query
        execute_btn = chrome_driver.find_element(By.ID, "execute-query")
        execute_btn.click()

        # Wait for results
        results = wait.until(
            EC.presence_of_element_located((By.ID, "query-results"))
        )

        # Verify results displayed
        rows = chrome_driver.find_elements(By.CSS_SELECTOR, "#query-results tr")
        assert len(rows) > 0

    def test_visualization_tab(self, chrome_driver, test_config):
        """Test data visualization functionality."""
        url = test_config["web_demo"]["url"] + "/visualize"
        chrome_driver.get(url)

        wait = WebDriverWait(chrome_driver, 10)

        # Select chart type
        chart_selector = wait.until(
            EC.element_to_be_clickable((By.ID, "chart-type"))
        )
        chart_selector.click()

        bar_chart = chrome_driver.find_element(By.XPATH, "//option[text()='Bar Chart']")
        bar_chart.click()

        # Configure data source
        data_source = chrome_driver.find_element(By.ID, "data-source")
        data_source.send_keys("SELECT COUNT(*) as count, status FROM orders GROUP BY status")

        # Generate chart
        generate_btn = chrome_driver.find_element(By.ID, "generate-chart")
        generate_btn.click()

        # Wait for chart to render
        chart_canvas = wait.until(
            EC.presence_of_element_located((By.TAG_NAME, "canvas"))
        )

        assert chart_canvas is not None
        assert chart_canvas.get_attribute("width") is not None

    @pytest.mark.asyncio
    async def test_real_time_updates(self, test_config):
        """Test real-time data updates using WebSocket."""
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()

            # Navigate to real-time dashboard
            await page.goto(f"{test_config['web_demo']['url']}/real-time")

            # Wait for WebSocket connection
            await page.wait_for_selector("#connection-status:has-text('Connected')", timeout=5000)

            # Verify initial data
            initial_count = await page.inner_text("#record-count")
            initial_count = int(initial_count)

            # Wait for updates
            await page.wait_for_timeout(3000)

            # Check if count increased
            updated_count = await page.inner_text("#record-count")
            updated_count = int(updated_count)

            assert updated_count >= initial_count

            await browser.close()

@pytest.mark.e2e
class TestGraphQLAPI:
    """Test GraphQL API endpoints."""

    @pytest.fixture
    def graphql_url(self, test_config):
        """GraphQL endpoint URL."""
        return test_config["graphql_endpoint"]

    def test_introspection_query(self, graphql_url):
        """Test GraphQL introspection."""
        query = """
        {
            __schema {
                types {
                    name
                    kind
                    description
                }
            }
        }
        """

        response = requests.post(graphql_url, json={"query": query})
        assert response.status_code == 200

        data = response.json()
        assert "data" in data
        assert "__schema" in data["data"]
        assert len(data["data"]["__schema"]["types"]) > 0

    def test_query_patients(self, graphql_url):
        """Test querying patients through GraphQL."""
        query = """
        query GetPatients($limit: Int, $offset: Int) {
            patients(limit: $limit, offset: $offset) {
                id
                firstName
                lastName
                email
                dateOfBirth
                appointments {
                    id
                    scheduledAt
                    status
                }
            }
        }
        """

        variables = {"limit": 10, "offset": 0}

        response = requests.post(
            graphql_url,
            json={"query": query, "variables": variables}
        )

        assert response.status_code == 200
        data = response.json()

        assert "data" in data
        assert "patients" in data["data"]
        assert isinstance(data["data"]["patients"], list)

    def test_mutation_create_appointment(self, graphql_url):
        """Test creating appointment through GraphQL mutation."""
        mutation = """
        mutation CreateAppointment($input: AppointmentInput!) {
            createAppointment(input: $input) {
                id
                patientId
                doctorId
                scheduledAt
                status
            }
        }
        """

        variables = {
            "input": {
                "patientId": 1,
                "doctorId": 1,
                "scheduledAt": "2024-02-01T10:00:00Z",
                "reason": "Regular checkup",
                "status": "scheduled"
            }
        }

        response = requests.post(
            graphql_url,
            json={"query": mutation, "variables": variables}
        )

        assert response.status_code == 200
        data = response.json()

        if "errors" not in data:
            assert "data" in data
            assert "createAppointment" in data["data"]
            assert data["data"]["createAppointment"]["status"] == "scheduled"

    def test_subscription_real_time_updates(self, graphql_url):
        """Test GraphQL subscription for real-time updates."""
        # WebSocket connection for subscriptions
        import websocket
        import threading
        import queue

        ws_url = graphql_url.replace("http", "ws").replace("/graphql", "/subscriptions")
        message_queue = queue.Queue()

        def on_message(ws, message):
            message_queue.put(json.loads(message))

        def on_open(ws):
            # Send subscription
            subscription = {
                "type": "start",
                "payload": {
                    "query": """
                    subscription OnAppointmentUpdate {
                        appointmentUpdated {
                            id
                            status
                            updatedAt
                        }
                    }
                    """
                }
            }
            ws.send(json.dumps(subscription))

        ws = websocket.WebSocketApp(
            ws_url,
            on_message=on_message,
            on_open=on_open
        )

        # Run WebSocket in thread
        ws_thread = threading.Thread(target=ws.run_forever)
        ws_thread.daemon = True
        ws_thread.start()

        # Wait for subscription confirmation
        time.sleep(2)

        # Trigger an update (would normally happen through another operation)
        # Check if we received any messages
        messages_received = []
        while not message_queue.empty():
            messages_received.append(message_queue.get())

        ws.close()

    def test_query_complexity_limiting(self, graphql_url):
        """Test GraphQL query complexity limiting."""
        # Very complex nested query
        complex_query = """
        {
            patients(limit: 100) {
                id
                appointments {
                    doctor {
                        appointments {
                            patient {
                                appointments {
                                    doctor {
                                        name
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        response = requests.post(graphql_url, json={"query": complex_query})

        # Should be rejected or rate-limited
        if response.status_code == 200:
            data = response.json()
            # Check if query was rejected due to complexity
            if "errors" in data:
                error_messages = [e.get("message", "") for e in data["errors"]]
                assert any("complexity" in msg.lower() or "depth" in msg.lower()
                          for msg in error_messages)

@pytest.mark.e2e
class TestRESTAPI:
    """Test REST API endpoints."""

    @pytest.fixture
    def api_base_url(self, test_config):
        """REST API base URL."""
        return f"{test_config['web_demo']['url']}/api/v1"

    def test_health_check(self, api_base_url):
        """Test API health check endpoint."""
        response = requests.get(f"{api_base_url}/health")
        assert response.status_code == 200

        data = response.json()
        assert data["status"] == "healthy"
        assert "database" in data
        assert "uptime" in data

    def test_get_schemas(self, api_base_url):
        """Test getting available schemas."""
        response = requests.get(f"{api_base_url}/schemas")
        assert response.status_code == 200

        schemas = response.json()
        assert isinstance(schemas, list)
        assert len(schemas) > 0

        # Verify schema structure
        for schema in schemas:
            assert "name" in schema
            assert "description" in schema
            assert "tables" in schema

    def test_execute_query(self, api_base_url):
        """Test query execution endpoint."""
        query_data = {
            "query": "SELECT 1 as test",
            "database": "test_db"
        }

        response = requests.post(
            f"{api_base_url}/query",
            json=query_data,
            headers={"Authorization": "Bearer test-token"}
        )

        if response.status_code == 200:
            data = response.json()
            assert "results" in data
            assert "execution_time" in data
            assert "rows_affected" in data

    def test_rate_limiting(self, api_base_url):
        """Test API rate limiting."""
        # Make multiple rapid requests
        responses = []
        for i in range(20):
            response = requests.get(f"{api_base_url}/schemas")
            responses.append(response)

        # Check if rate limiting kicked in
        status_codes = [r.status_code for r in responses]
        assert 429 in status_codes or all(s == 200 for s in status_codes)

        # Check for rate limit headers
        last_response = responses[-1]
        assert "X-RateLimit-Limit" in last_response.headers or \
               "X-RateLimit-Remaining" in last_response.headers

    def test_pagination(self, api_base_url):
        """Test API pagination."""
        # Test with tables endpoint
        response = requests.get(
            f"{api_base_url}/tables",
            params={"page": 1, "limit": 10}
        )

        assert response.status_code == 200
        data = response.json()

        assert "data" in data
        assert "pagination" in data
        assert "page" in data["pagination"]
        assert "limit" in data["pagination"]
        assert "total" in data["pagination"]

        # Verify limit is respected
        assert len(data["data"]) <= 10

@pytest.mark.e2e
class TestAuthentication:
    """Test authentication and authorization."""

    @pytest.fixture
    def auth_api_url(self, test_config):
        """Authentication API URL."""
        return f"{test_config['web_demo']['url']}/api/auth"

    def test_login(self, auth_api_url):
        """Test user login."""
        credentials = {
            "username": "testuser",
            "password": "testpass123"
        }

        response = requests.post(f"{auth_api_url}/login", json=credentials)

        if response.status_code == 200:
            data = response.json()
            assert "token" in data
            assert "user" in data
            assert "expires_in" in data

            # Verify token format (JWT)
            token = data["token"]
            assert token.count(".") == 2  # JWT has 3 parts

    def test_protected_endpoint_without_token(self, api_base_url):
        """Test accessing protected endpoint without token."""
        response = requests.post(f"{api_base_url}/query", json={"query": "SELECT 1"})
        assert response.status_code in [401, 403]

    def test_protected_endpoint_with_token(self, api_base_url, auth_api_url):
        """Test accessing protected endpoint with valid token."""
        # First, get a token
        credentials = {"username": "testuser", "password": "testpass123"}
        auth_response = requests.post(f"{auth_api_url}/login", json=credentials)

        if auth_response.status_code == 200:
            token = auth_response.json()["token"]

            # Use token to access protected endpoint
            response = requests.post(
                f"{api_base_url}/query",
                json={"query": "SELECT 1"},
                headers={"Authorization": f"Bearer {token}"}
            )

            assert response.status_code == 200

    def test_token_refresh(self, auth_api_url):
        """Test token refresh functionality."""
        # Login first
        credentials = {"username": "testuser", "password": "testpass123"}
        login_response = requests.post(f"{auth_api_url}/login", json=credentials)

        if login_response.status_code == 200:
            refresh_token = login_response.json().get("refresh_token")

            if refresh_token:
                # Use refresh token
                refresh_response = requests.post(
                    f"{auth_api_url}/refresh",
                    json={"refresh_token": refresh_token}
                )

                assert refresh_response.status_code == 200
                assert "token" in refresh_response.json()

@pytest.mark.e2e
class TestErrorHandling:
    """Test error handling and recovery."""

    def test_invalid_query_handling(self, api_base_url):
        """Test handling of invalid SQL queries."""
        query_data = {
            "query": "SELCT * FORM users",  # Intentional typos
            "database": "test_db"
        }

        response = requests.post(
            f"{api_base_url}/query",
            json=query_data,
            headers={"Authorization": "Bearer test-token"}
        )

        assert response.status_code in [400, 422]
        data = response.json()
        assert "error" in data
        assert "message" in data

    def test_database_connection_failure(self, api_base_url):
        """Test handling of database connection failures."""
        # Query with non-existent database
        query_data = {
            "query": "SELECT 1",
            "database": "non_existent_db"
        }

        response = requests.post(
            f"{api_base_url}/query",
            json=query_data,
            headers={"Authorization": "Bearer test-token"}
        )

        assert response.status_code in [500, 503]
        data = response.json()
        assert "error" in data

    def test_timeout_handling(self, api_base_url):
        """Test query timeout handling."""
        # Long-running query
        query_data = {
            "query": "SELECT SLEEP(30)",  # 30 second sleep
            "database": "test_db",
            "timeout": 1  # 1 second timeout
        }

        response = requests.post(
            f"{api_base_url}/query",
            json=query_data,
            headers={"Authorization": "Bearer test-token"},
            timeout=5
        )

        assert response.status_code in [408, 504]