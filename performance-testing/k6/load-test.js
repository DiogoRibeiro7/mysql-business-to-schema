/**
 * K6 Load Testing Script for MySQL Business-to-Schema
 * Advanced performance testing with multiple scenarios
 */

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter, Gauge } from 'k6/metrics';
import { randomString, randomIntBetween, randomItem } from 'https://jslib.k6.io/k6-utils/1.4.0/index.js';
import { SharedArray } from 'k6/data';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";

// Custom metrics
const errorRate = new Rate('errors');
const patientCreationDuration = new Trend('patient_creation_duration');
const orderProcessingDuration = new Trend('order_processing_duration');
const iotIngestionRate = new Counter('iot_readings_sent');
const concurrentUsers = new Gauge('concurrent_users');
const dbQueryDuration = new Trend('db_query_duration');
const cacheHitRate = new Rate('cache_hits');

// Configuration
const BASE_URL = __ENV.BASE_URL || 'http://localhost:8000';
const AUTH_TOKEN = __ENV.AUTH_TOKEN || '';

// Test data
const testUsers = new SharedArray('users', function () {
    const data = [];
    for (let i = 0; i < 1000; i++) {
        data.push({
            username: `user${i}`,
            password: 'password123',
            email: `user${i}@example.com`
        });
    }
    return data;
});

// Test scenarios configuration
export const options = {
    scenarios: {
        // Scenario 1: Smoke Test
        smoke_test: {
            executor: 'constant-vus',
            vus: 2,
            duration: '1m',
            gracefulStop: '10s',
            tags: { test_type: 'smoke' },
            exec: 'smokeTest'
        },

        // Scenario 2: Load Test
        load_test: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '2m', target: 50 },   // Ramp up
                { duration: '5m', target: 50 },   // Stay at 50 VUs
                { duration: '2m', target: 100 },  // Ramp up to 100
                { duration: '5m', target: 100 },  // Stay at 100 VUs
                { duration: '2m', target: 0 },    // Ramp down
            ],
            gracefulRampDown: '30s',
            tags: { test_type: 'load' },
            exec: 'loadTest',
            startTime: '2m'  // Start after smoke test
        },

        // Scenario 3: Stress Test
        stress_test: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '2m', target: 100 },
                { duration: '5m', target: 100 },
                { duration: '2m', target: 200 },
                { duration: '5m', target: 200 },
                { duration: '2m', target: 300 },
                { duration: '5m', target: 300 },
                { duration: '2m', target: 0 },
            ],
            gracefulRampDown: '30s',
            tags: { test_type: 'stress' },
            exec: 'stressTest',
            startTime: '18m'  // Start after load test
        },

        // Scenario 4: Spike Test
        spike_test: {
            executor: 'ramping-vus',
            startVUs: 0,
            stages: [
                { duration: '10s', target: 0 },
                { duration: '5s', target: 500 },   // Sudden spike
                { duration: '1m', target: 500 },   // Stay at peak
                { duration: '5s', target: 0 },     // Quick drop
            ],
            tags: { test_type: 'spike' },
            exec: 'spikeTest',
            startTime: '40m'  // Start after stress test
        },

        // Scenario 5: Soak Test
        soak_test: {
            executor: 'constant-vus',
            vus: 50,
            duration: '30m',
            tags: { test_type: 'soak' },
            exec: 'soakTest',
            startTime: '45m'  // Start after spike test
        },

        // Scenario 6: Breakpoint Test
        breakpoint_test: {
            executor: 'ramping-arrival-rate',
            startRate: 10,
            timeUnit: '1s',
            preAllocatedVUs: 50,
            maxVUs: 1000,
            stages: [
                { duration: '10m', target: 10000 },  // Ramp up to breaking point
            ],
            tags: { test_type: 'breakpoint' },
            exec: 'breakpointTest',
            startTime: '77m'  // Start after soak test
        }
    },

    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1500'],  // 95% of requests under 500ms
        http_req_failed: ['rate<0.05'],                   // Error rate under 5%
        errors: ['rate<0.05'],
        patient_creation_duration: ['p(95)<1000'],
        order_processing_duration: ['p(95)<2000'],
        db_query_duration: ['p(95)<100'],
        cache_hits: ['rate>0.8'],                         // Cache hit rate above 80%
    },

    noConnectionReuse: false,
    userAgent: 'K6LoadTest/1.0',
};

// Setup function
export function setup() {
    console.log('Setting up test environment...');

    // Login and get auth token
    const loginRes = http.post(`${BASE_URL}/api/auth/login`, JSON.stringify({
        username: 'admin',
        password: 'admin123'
    }), {
        headers: { 'Content-Type': 'application/json' }
    });

    const authToken = loginRes.json('token');

    // Warm up cache
    http.get(`${BASE_URL}/api/warmup`);

    return { authToken };
}

// Helper functions
function getHeaders(authToken) {
    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
        'X-Request-ID': randomString(16),
        'X-Test-Scenario': __ENV.scenario || 'default'
    };
}

function generatePatientData() {
    return {
        name: `Patient ${randomString(8)}`,
        date_of_birth: `${randomIntBetween(1950, 2010)}-01-01`,
        gender: randomItem(['Male', 'Female', 'Other']),
        phone: `+1${randomIntBetween(2000000000, 9999999999)}`,
        email: `patient${randomString(8)}@example.com`,
        address: `${randomIntBetween(100, 9999)} Main St`,
        insurance_provider: randomItem(['Blue Cross', 'Aetna', 'United Health'])
    };
}

function generateOrderData() {
    const items = [];
    const itemCount = randomIntBetween(1, 5);

    for (let i = 0; i < itemCount; i++) {
        items.push({
            product_id: randomIntBetween(1, 1000),
            quantity: randomIntBetween(1, 5),
            price: randomIntBetween(10, 500)
        });
    }

    return {
        customer_id: randomIntBetween(1, 5000),
        items: items,
        shipping_address: `${randomIntBetween(100, 9999)} Commerce St`,
        payment_method: randomItem(['credit_card', 'debit_card', 'paypal'])
    };
}

function generateIoTReading() {
    const sensorTypes = ['temperature', 'humidity', 'pressure', 'flow_rate'];
    const sensorType = randomItem(sensorTypes);

    let value;
    switch (sensorType) {
        case 'temperature': value = randomIntBetween(-20, 50); break;
        case 'humidity': value = randomIntBetween(0, 100); break;
        case 'pressure': value = randomIntBetween(950, 1050); break;
        case 'flow_rate': value = randomIntBetween(0, 100); break;
    }

    return {
        device_id: `DEV${randomIntBetween(1, 1000).toString().padStart(4, '0')}`,
        sensor_type: sensorType,
        value: value,
        timestamp: new Date().toISOString()
    };
}

// Test scenarios
export function smokeTest(data) {
    const headers = getHeaders(data.authToken);

    group('Smoke Test - Basic Functionality', () => {
        // Test health endpoint
        const healthRes = http.get(`${BASE_URL}/health`);
        check(healthRes, {
            'Health check successful': (r) => r.status === 200,
        });

        // Test authentication
        const authRes = http.get(`${BASE_URL}/api/auth/verify`, { headers });
        check(authRes, {
            'Authentication valid': (r) => r.status === 200,
        });

        // Test basic CRUD operations
        const patientData = generatePatientData();
        const createRes = http.post(`${BASE_URL}/api/clinic/patients`,
            JSON.stringify(patientData), { headers });

        check(createRes, {
            'Patient created': (r) => r.status === 201 || r.status === 200,
        });
    });

    sleep(1);
}

export function loadTest(data) {
    const headers = getHeaders(data.authToken);
    concurrentUsers.add(1);

    group('Load Test - Normal Operations', () => {
        // Clinic operations
        group('Clinic Module', () => {
            const startTime = Date.now();

            // Create patient
            const patientRes = http.post(`${BASE_URL}/api/clinic/patients`,
                JSON.stringify(generatePatientData()), { headers });

            patientCreationDuration.add(Date.now() - startTime);

            check(patientRes, {
                'Patient created successfully': (r) => r.status === 201 || r.status === 200,
            }) || errorRate.add(1);

            // Get patients list
            const listRes = http.get(`${BASE_URL}/api/clinic/patients?page=1&limit=20`, { headers });
            check(listRes, {
                'Patients list retrieved': (r) => r.status === 200,
            });
        });

        // E-commerce operations
        group('E-commerce Module', () => {
            const startTime = Date.now();

            // Browse products
            const productsRes = http.get(`${BASE_URL}/api/ecommerce/products`, { headers });
            check(productsRes, {
                'Products retrieved': (r) => r.status === 200,
            });

            // Create order
            const orderRes = http.post(`${BASE_URL}/api/ecommerce/orders`,
                JSON.stringify(generateOrderData()), { headers });

            orderProcessingDuration.add(Date.now() - startTime);

            check(orderRes, {
                'Order created successfully': (r) => r.status === 201 || r.status === 200,
            }) || errorRate.add(1);
        });

        // IoT operations
        group('IoT Module', () => {
            // Send batch readings
            const readings = [];
            for (let i = 0; i < 10; i++) {
                readings.push(generateIoTReading());
            }

            const batchRes = http.post(`${BASE_URL}/api/iot/readings/batch`,
                JSON.stringify({ readings }), { headers });

            iotIngestionRate.add(readings.length);

            check(batchRes, {
                'IoT batch ingested': (r) => r.status === 200 || r.status === 204,
            }) || errorRate.add(1);
        });
    });

    sleep(randomIntBetween(1, 3));
}

export function stressTest(data) {
    const headers = getHeaders(data.authToken);

    group('Stress Test - High Load Operations', () => {
        // Heavy database operations
        const queries = [
            http.get(`${BASE_URL}/api/analytics/revenue/monthly`, { headers }),
            http.get(`${BASE_URL}/api/analytics/patients/demographics`, { headers }),
            http.get(`${BASE_URL}/api/analytics/iot/anomalies`, { headers }),
        ];

        queries.forEach((res, index) => {
            check(res, {
                [`Analytics query ${index + 1} successful`]: (r) => r.status === 200,
            }) || errorRate.add(1);
        });

        // Concurrent writes
        const batch = http.batch([
            ['POST', `${BASE_URL}/api/clinic/patients`, JSON.stringify(generatePatientData()), { headers }],
            ['POST', `${BASE_URL}/api/ecommerce/orders`, JSON.stringify(generateOrderData()), { headers }],
            ['POST', `${BASE_URL}/api/iot/readings`, JSON.stringify(generateIoTReading()), { headers }],
        ]);

        batch.forEach((res, index) => {
            check(res, {
                [`Concurrent write ${index + 1} successful`]: (r) => r.status < 300,
            });
        });
    });

    sleep(0.5);
}

export function spikeTest(data) {
    const headers = getHeaders(data.authToken);

    // Simulate sudden burst of traffic
    const requests = [];
    for (let i = 0; i < 10; i++) {
        requests.push(['GET', `${BASE_URL}/api/clinic/patients/${randomIntBetween(1, 1000)}`, null, { headers }]);
    }

    const responses = http.batch(requests);
    responses.forEach((res) => {
        check(res, {
            'Spike request handled': (r) => r.status < 500,
        });
    });

    sleep(0.1);
}

export function soakTest(data) {
    const headers = getHeaders(data.authToken);

    // Long-running operations to test memory leaks and resource exhaustion
    group('Soak Test - Extended Operations', () => {
        // WebSocket connection simulation
        const wsRes = http.get(`${BASE_URL}/api/ws/connect`, {
            headers,
            tags: { name: 'WebSocket' }
        });

        // Large data transfer
        const largeData = {
            records: Array(100).fill(null).map(() => generatePatientData())
        };

        const bulkRes = http.post(`${BASE_URL}/api/clinic/patients/bulk`,
            JSON.stringify(largeData), { headers });

        check(bulkRes, {
            'Bulk operation successful': (r) => r.status < 300,
        });

        // Cache testing
        const cacheKey = `cache_test_${randomIntBetween(1, 100)}`;
        const cacheRes = http.get(`${BASE_URL}/api/cache/${cacheKey}`, { headers });

        if (cacheRes.headers['X-Cache-Hit'] === 'true') {
            cacheHitRate.add(1);
        } else {
            cacheHitRate.add(0);
        }
    });

    sleep(randomIntBetween(2, 5));
}

export function breakpointTest(data) {
    const headers = getHeaders(data.authToken);

    // Minimal operations to find breaking point
    const res = http.get(`${BASE_URL}/api/health`, { headers });

    check(res, {
        'System responsive': (r) => r.status === 200 && r.timings.duration < 5000,
    }) || errorRate.add(1);
}

// Teardown function
export function teardown(data) {
    console.log('Cleaning up test environment...');

    // Logout
    http.post(`${BASE_URL}/api/auth/logout`, null, {
        headers: { 'Authorization': `Bearer ${data.authToken}` }
    });
}

// Custom summary
export function handleSummary(data) {
    return {
        'summary.json': JSON.stringify(data),
        'summary.html': htmlReport(data),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}