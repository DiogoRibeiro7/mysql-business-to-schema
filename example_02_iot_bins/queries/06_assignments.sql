-- ============================================================================
-- IoT Garbage Bin Monitoring System - Student Assignments
-- ============================================================================
-- Description: Practice queries and exercises for learning SQL with IoT data
-- ============================================================================

USE iot_bins;

-- ============================================================================
-- ASSIGNMENT 1: Basic Queries (Beginner)
-- ============================================================================

-- Exercise 1.1: Find all bins in the 'Downtown' district
-- TODO: Write a query to list bin_code, bin_type, and address
-- Hint: Join bins with districts table

-- Exercise 1.2: Count sensors by type
-- TODO: Write a query to show each sensor_type and how many sensors of that type exist
-- Expected columns: sensor_type, sensor_count

-- Exercise 1.3: Find bins that haven't been collected in the last 3 days
-- TODO: Use collection_events to find bins with old collection dates
-- Show: bin_code, last collection date, days since collection

-- ============================================================================
-- ASSIGNMENT 2: Aggregation Queries (Intermediate)
-- ============================================================================

-- Exercise 2.1: Calculate average fill levels by bin type
-- TODO: Use sensor_readings where sensor_type = 'fill_level'
-- Group by bin_type and calculate average reading_value
-- Expected: bin_type, avg_fill_level, min_fill, max_fill

-- Exercise 2.2: Find the busiest collection day of the week
-- TODO: Analyze collection_events to find which day has most collections
-- Use DAYNAME() function
-- Show: day_name, collection_count, avg_weight_kg

-- Exercise 2.3: District comparison - waste collected last month
-- TODO: Calculate total waste collected per district
-- Include: district_name, total_bins, total_collections, total_weight_tons

-- ============================================================================
-- ASSIGNMENT 3: Time Series Analysis (Intermediate)
-- ============================================================================

-- Exercise 3.1: Hourly fill pattern analysis
-- TODO: Find average fill levels by hour of day for residential bins
-- Use sensor_readings from last 7 days
-- Show: hour_of_day, avg_fill_level, reading_count

-- Exercise 3.2: Identify peak usage times
-- TODO: Find the hours when bins fill up fastest
-- Calculate fill rate change between consecutive hours
-- Hint: Use LAG() window function

-- Exercise 3.3: Weekly trend analysis
-- TODO: Show weekly average fill levels for the past 4 weeks
-- Group by week number and bin_type
-- Include week_start_date, bin_type, avg_fill

-- ============================================================================
-- ASSIGNMENT 4: Alert Analysis (Intermediate)
-- ============================================================================

-- Exercise 4.1: Most common alert types
-- TODO: Count alerts by type and severity
-- Include resolved vs unresolved counts
-- Order by frequency

-- Exercise 4.2: Alert response time analysis
-- TODO: Calculate average time to resolve alerts by severity
-- Only include resolved alerts
-- Show: severity, avg_resolution_hours, min_hours, max_hours

-- Exercise 4.3: Bins with recurring alerts
-- TODO: Find bins that have had more than 5 alerts in the last month
-- Show: bin_code, alert_count, most_common_alert_type

-- ============================================================================
-- ASSIGNMENT 5: Route Optimization (Advanced)
-- ============================================================================

-- Exercise 5.1: Inefficient routes detection
-- TODO: Find routes where average fill level at collection is below 60%
-- This indicates premature collection
-- Include: route_code, avg_fill_at_collection, potential_savings

-- Exercise 5.2: Optimal collection frequency
-- TODO: Calculate ideal collection frequency for each bin
-- Based on average daily fill rate
-- Show: bin_code, current_frequency_days, recommended_frequency_days

-- Exercise 5.3: Route clustering optimization
-- TODO: Find bins that could be grouped into new efficient routes
-- Use geographic proximity and similar fill patterns
-- Hint: Use ST_Distance_Sphere for distance calculations

-- ============================================================================
-- ASSIGNMENT 6: Sensor Performance (Advanced)
-- ============================================================================

-- Exercise 6.1: Sensor reliability scoring
-- TODO: Create a reliability score for each sensor
-- Based on: uptime percentage, error rate, battery level
-- Score from 0-100

-- Exercise 6.2: Correlation analysis
-- TODO: Find correlation between temperature and fill rate
-- Group by location_type
-- Calculate Pearson correlation coefficient

-- Exercise 6.3: Anomaly detection
-- TODO: Identify sensors with abnormal reading patterns
-- Compare recent readings to historical average
-- Flag readings > 2 standard deviations from mean

-- ============================================================================
-- ASSIGNMENT 7: Predictive Analytics (Advanced)
-- ============================================================================

-- Exercise 7.1: Fill rate prediction
-- TODO: Predict tomorrow's fill levels based on historical patterns
-- Consider day of week, location type, and recent trends
-- Show: bin_code, current_fill, predicted_tomorrow_fill

-- Exercise 7.2: Maintenance prediction
-- TODO: Identify sensors likely to fail in next 30 days
-- Based on battery degradation rate and error frequency
-- Include: sensor_code, failure_probability, recommended_action

-- Exercise 7.3: Seasonal pattern detection
-- TODO: Identify bins with significant seasonal variations
-- Compare monthly averages across the dataset
-- Show bins with >20% variation between months

-- ============================================================================
-- ASSIGNMENT 8: Complex Reporting (Expert)
-- ============================================================================

-- Exercise 8.1: Multi-dimensional performance dashboard
-- TODO: Create a comprehensive query combining:
-- - Collection efficiency by district
-- - Sensor health metrics
-- - Alert statistics
-- - Route optimization potential
-- Present as a single unified report

-- Exercise 8.2: Cost-benefit analysis
-- TODO: Calculate potential savings from route optimization
-- Compare current vs optimal collection patterns
-- Include: fuel savings, labor hours, CO2 reduction

-- Exercise 8.3: Predictive maintenance ROI
-- TODO: Analyze cost savings from predictive vs reactive maintenance
-- Calculate prevented failures and associated costs
-- Show monthly breakdown with cumulative savings

-- ============================================================================
-- SOLUTIONS SECTION (Instructor Use)
-- ============================================================================

-- Solution 1.1: Find all bins in the 'Downtown' district
SELECT
    b.bin_code,
    b.bin_type,
    b.address
FROM bins b
INNER JOIN districts d ON b.district_id = d.district_id
WHERE d.name = 'Downtown'
ORDER BY b.bin_code;

-- Solution 2.1: Calculate average fill levels by bin type
SELECT
    b.bin_type,
    ROUND(AVG(sr.reading_value), 2) AS avg_fill_level,
    ROUND(MIN(sr.reading_value), 2) AS min_fill,
    ROUND(MAX(sr.reading_value), 2) AS max_fill,
    COUNT(DISTINCT b.bin_id) AS bin_count
FROM sensor_readings sr
INNER JOIN sensors s ON sr.sensor_id = s.sensor_id
INNER JOIN bins b ON s.bin_id = b.bin_id
WHERE s.sensor_type = 'fill_level'
    AND sr.reading_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    AND sr.quality = 'good'
GROUP BY b.bin_type
ORDER BY avg_fill_level DESC;

-- Solution 4.1: Most common alert types
SELECT
    alert_type,
    severity,
    COUNT(*) AS total_alerts,
    SUM(CASE WHEN resolved_at IS NULL THEN 1 ELSE 0 END) AS unresolved,
    SUM(CASE WHEN resolved_at IS NOT NULL THEN 1 ELSE 0 END) AS resolved,
    ROUND(100.0 * SUM(CASE WHEN resolved_at IS NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS unresolved_pct
FROM alerts
WHERE triggered_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY alert_type, severity
ORDER BY total_alerts DESC;

-- ============================================================================
-- GRADING RUBRIC
-- ============================================================================
/*
Assignment Grading Criteria:

1. Query Correctness (40%)
   - Returns expected results
   - Handles edge cases
   - No syntax errors

2. Performance (20%)
   - Appropriate use of indexes
   - Efficient JOIN strategies
   - Avoids unnecessary subqueries

3. Code Quality (20%)
   - Clear and readable
   - Proper formatting
   - Meaningful aliases

4. Business Understanding (20%)
   - Addresses the business question
   - Includes relevant metrics
   - Provides actionable insights

Difficulty Levels:
- Exercises 1-2: Basic SQL (SELECT, WHERE, JOIN, GROUP BY)
- Exercises 3-4: Intermediate (Window functions, CTEs, complex JOINs)
- Exercises 5-6: Advanced (Spatial functions, statistical analysis)
- Exercises 7-8: Expert (Predictive modeling, multi-dimensional analysis)
*/

-- ============================================================================
-- ADDITIONAL CHALLENGES
-- ============================================================================

-- Challenge 1: Real-time Dashboard Query
-- Create a single query that provides all metrics needed for a real-time
-- monitoring dashboard, optimized to run every 30 seconds

-- Challenge 2: Route Optimization Algorithm
-- Implement a traveling salesman approximation using SQL
-- to find the most efficient collection route

-- Challenge 3: Anomaly Detection System
-- Build a query that automatically detects and ranks anomalies
-- across all sensor types using statistical methods

-- Challenge 4: Predictive Model
-- Create a SQL-based prediction model for bin fill rates
-- using historical patterns and external factors