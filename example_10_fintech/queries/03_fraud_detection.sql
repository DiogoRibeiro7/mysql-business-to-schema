-- =========================================
-- FinTech Platform - Fraud Detection Queries
-- =========================================

USE fintech;

-- Smoke test for CI query runner
SELECT 1 AS query_smoke_test;

-- =========================================
-- 1. Real-Time Fraud Score Calculation
-- =========================================

-- Calculate fraud risk score for recent transactions
WITH TransactionRiskFactors AS (
    SELECT
        t.transaction_id,
        t.account_id,
        t.amount,
        t.initiated_at,
        t.channel,
        t.ip_address,
        t.device_id,
        -- Amount risk factor (higher amounts = higher risk)
        CASE
            WHEN t.amount > 10000 THEN 30
            WHEN t.amount > 5000 THEN 20
            WHEN t.amount > 1000 THEN 10
            ELSE 0
        END AS amount_risk,
        -- Velocity risk (multiple transactions in short time)
        (SELECT COUNT(*)
         FROM transactions t2
         WHERE t2.account_id = t.account_id
           AND t2.initiated_at BETWEEN DATE_SUB(t.initiated_at, INTERVAL 1 HOUR) AND t.initiated_at
        ) * 5 AS velocity_risk,
        -- New device risk
        CASE
            WHEN EXISTS (
                SELECT 1 FROM device_fingerprints df
                WHERE df.customer_id = ah.customer_id
                  AND df.device_hash = MD5(t.device_id)
                  AND df.first_seen < DATE_SUB(NOW(), INTERVAL 7 DAY)
            ) THEN 0
            ELSE 20
        END AS device_risk,
        -- Geographic risk (new location)
        CASE
            WHEN t.ip_address NOT IN (
                SELECT DISTINCT ip_address
                FROM transactions
                WHERE account_id = t.account_id
                  AND initiated_at < DATE_SUB(t.initiated_at, INTERVAL 7 DAY)
                  AND status = 'completed'
            ) THEN 15
            ELSE 0
        END AS location_risk,
        -- Time-based risk (unusual hours)
        CASE
            WHEN HOUR(t.initiated_at) BETWEEN 2 AND 5 THEN 10
            ELSE 0
        END AS time_risk,
        c.risk_level AS customer_risk_level
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
    JOIN customers c ON ah.customer_id = c.customer_id
    WHERE t.initiated_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
      AND t.status = 'pending'
)
SELECT
    transaction_id,
    account_id,
    amount,
    initiated_at,
    amount_risk,
    velocity_risk,
    device_risk,
    location_risk,
    time_risk,
    (amount_risk + velocity_risk + device_risk + location_risk + time_risk) AS total_risk_score,
    CASE
        WHEN (amount_risk + velocity_risk + device_risk + location_risk + time_risk) >= 50 THEN 'HIGH - BLOCK'
        WHEN (amount_risk + velocity_risk + device_risk + location_risk + time_risk) >= 30 THEN 'MEDIUM - REVIEW'
        ELSE 'LOW - APPROVE'
    END AS risk_decision,
    customer_risk_level
FROM TransactionRiskFactors
ORDER BY total_risk_score DESC;

-- =========================================
-- 2. Suspicious Pattern Detection
-- =========================================

-- Detect potential money laundering patterns
WITH SuspiciousPatterns AS (
    SELECT
        a.account_id,
        a.account_number,
        -- Rapid movement pattern (deposit followed by immediate withdrawal)
        (SELECT COUNT(*)
         FROM transactions t1
         JOIN transactions t2 ON t1.account_id = t2.account_id
         WHERE t1.account_id = a.account_id
           AND t1.transaction_type = 'deposit'
           AND t2.transaction_type = 'withdrawal'
           AND t2.initiated_at BETWEEN t1.completed_at AND DATE_ADD(t1.completed_at, INTERVAL 1 HOUR)
           AND t1.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ) AS rapid_movement_count,
        -- Structuring pattern (multiple deposits just below reporting threshold)
        (SELECT COUNT(*)
         FROM transactions t
         WHERE t.account_id = a.account_id
           AND t.transaction_type = 'deposit'
           AND t.amount BETWEEN 9000 AND 9999
           AND t.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ) AS structuring_count,
        -- Round amount pattern
        (SELECT COUNT(*)
         FROM transactions t
         WHERE t.account_id = a.account_id
           AND MOD(t.amount, 1000) = 0
           AND t.amount >= 1000
           AND t.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        ) AS round_amount_count,
        -- Dormant account suddenly active
        CASE
            WHEN a.last_transaction_date < DATE_SUB(CURDATE(), INTERVAL 180 DAY)
             AND EXISTS (
                SELECT 1 FROM transactions t
                WHERE t.account_id = a.account_id
                  AND t.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
             ) THEN 1
            ELSE 0
        END AS dormant_reactivation
    FROM accounts a
    WHERE a.status = 'active'
)
SELECT
    sp.*,
    c.customer_id,
    c.risk_level,
    c.onboarding_date,
    DATEDIFF(CURDATE(), c.onboarding_date) AS days_since_onboarding,
    (sp.rapid_movement_count * 10 +
     sp.structuring_count * 15 +
     sp.round_amount_count * 5 +
     sp.dormant_reactivation * 20) AS suspicion_score
FROM SuspiciousPatterns sp
JOIN account_holders ah ON sp.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
WHERE sp.rapid_movement_count > 0
   OR sp.structuring_count > 0
   OR sp.round_amount_count > 5
   OR sp.dormant_reactivation = 1
ORDER BY suspicion_score DESC;

-- =========================================
-- 3. Device Fingerprint Analysis
-- =========================================

-- Analyze device trust and suspicious device patterns
SELECT
    df.device_hash,
    df.device_type,
    df.operating_system,
    df.trust_score,
    df.is_blocked,
    COUNT(DISTINCT df.customer_id) AS customers_using_device,
    COUNT(DISTINCT df.ip_address) AS unique_ips,
    GROUP_CONCAT(DISTINCT df.location_country) AS countries,
    MIN(df.first_seen) AS first_seen,
    MAX(df.last_seen) AS last_seen,
    COUNT(fa.alert_id) AS fraud_alerts_count,
    SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN 1 ELSE 0 END) AS confirmed_frauds
FROM device_fingerprints df
LEFT JOIN customers c ON df.customer_id = c.customer_id
LEFT JOIN fraud_alerts fa ON c.customer_id = fa.customer_id
GROUP BY df.device_hash, df.device_type, df.operating_system, df.trust_score, df.is_blocked
HAVING customers_using_device > 3  -- Same device used by multiple customers
    OR unique_ips > 10  -- Device connecting from many IPs
    OR fraud_alerts_count > 0
ORDER BY customers_using_device DESC, fraud_alerts_count DESC;

-- =========================================
-- 4. Velocity Check Dashboard
-- =========================================

-- Real-time velocity monitoring by account
SELECT
    a.account_id,
    a.account_number,
    c.customer_id,
    c.risk_level,
    -- Last hour statistics
    SUM(CASE WHEN t.initiated_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN 1 ELSE 0 END) AS tx_last_hour,
    SUM(CASE WHEN t.initiated_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR) THEN t.amount ELSE 0 END) AS amount_last_hour,
    -- Last 24 hours statistics
    SUM(CASE WHEN t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN 1 ELSE 0 END) AS tx_last_24h,
    SUM(CASE WHEN t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR) THEN t.amount ELSE 0 END) AS amount_last_24h,
    -- Unique characteristics
    COUNT(DISTINCT t.ip_address) AS unique_ips_24h,
    COUNT(DISTINCT t.device_id) AS unique_devices_24h,
    COUNT(DISTINCT DATE(t.initiated_at)) AS active_days,
    MAX(t.amount) AS max_transaction_amount
FROM accounts a
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
JOIN transactions t ON a.account_id = t.account_id
WHERE t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
  AND t.status IN ('pending', 'completed')
GROUP BY a.account_id, a.account_number, c.customer_id, c.risk_level
HAVING tx_last_hour >= 5  -- 5+ transactions in last hour
    OR amount_last_hour > 10000  -- Over $10k in last hour
    OR tx_last_24h >= 20  -- 20+ transactions in 24 hours
    OR unique_devices_24h > 3  -- Multiple devices
ORDER BY amount_last_hour DESC, tx_last_hour DESC;

-- =========================================
-- 5. Fraud Alert Queue
-- =========================================

-- Pending fraud alerts requiring investigation
SELECT
    fa.alert_id,
    fa.created_at,
    fa.alert_type,
    fa.risk_score,
    fa.status,
    c.customer_id,
    c.email,
    c.risk_level AS customer_risk_level,
    t.transaction_id,
    t.amount,
    t.currency,
    t.description,
    t.channel,
    a.account_number,
    rr.rule_name,
    rr.action AS rule_action,
    JSON_EXTRACT(fa.alert_details, '$.reason') AS alert_reason
FROM fraud_alerts fa
JOIN customers c ON fa.customer_id = c.customer_id
LEFT JOIN transactions t ON fa.transaction_id = t.transaction_id
LEFT JOIN accounts a ON t.account_id = a.account_id
LEFT JOIN risk_rules rr ON fa.rule_id = rr.rule_id
WHERE fa.status IN ('pending', 'investigating')
ORDER BY fa.risk_score DESC, fa.created_at ASC;

-- =========================================
-- 6. Geographic Anomaly Detection
-- =========================================

-- Detect transactions from unusual geographic locations
WITH CustomerLocationProfile AS (
    SELECT
        ah.customer_id,
        t.ip_address,
        COUNT(*) AS transaction_count,
        MAX(t.initiated_at) AS last_seen
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
    WHERE t.status = 'completed'
      AND t.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY ah.customer_id, t.ip_address
),
RecentTransactions AS (
    SELECT
        t.transaction_id,
        t.initiated_at,
        t.amount,
        t.ip_address,
        ah.customer_id,
        a.account_number
    FROM transactions t
    JOIN accounts a ON t.account_id = a.account_id
    JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
    WHERE t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
      AND t.status = 'pending'
)
SELECT
    rt.transaction_id,
    rt.initiated_at,
    rt.amount,
    rt.ip_address AS current_ip,
    rt.account_number,
    c.email,
    c.risk_level,
    CASE
        WHEN NOT EXISTS (
            SELECT 1 FROM CustomerLocationProfile clp
            WHERE clp.customer_id = rt.customer_id
              AND clp.ip_address = rt.ip_address
        ) THEN 'NEW_LOCATION'
        WHEN EXISTS (
            SELECT 1 FROM CustomerLocationProfile clp
            WHERE clp.customer_id = rt.customer_id
              AND clp.ip_address = rt.ip_address
              AND clp.transaction_count < 3
        ) THEN 'RARE_LOCATION'
        ELSE 'KNOWN_LOCATION'
    END AS location_risk
FROM RecentTransactions rt
JOIN customers c ON rt.customer_id = c.customer_id
HAVING location_risk IN ('NEW_LOCATION', 'RARE_LOCATION')
ORDER BY rt.amount DESC;

-- =========================================
-- 7. Account Takeover Detection
-- =========================================

-- Detect potential account takeover attempts
WITH AccountBehaviorBaseline AS (
    SELECT
        account_id,
        AVG(amount) AS avg_amount,
        STDDEV(amount) AS stddev_amount,
        AVG(HOUR(initiated_at)) AS avg_hour,
        COUNT(DISTINCT channel) AS typical_channels,
        COUNT(DISTINCT ip_address) AS typical_ips
    FROM transactions
    WHERE status = 'completed'
      AND initiated_at BETWEEN DATE_SUB(CURDATE(), INTERVAL 90 DAY)
                          AND DATE_SUB(CURDATE(), INTERVAL 7 DAY)
    GROUP BY account_id
),
RecentActivity AS (
    SELECT
        t.account_id,
        t.transaction_id,
        t.amount,
        t.initiated_at,
        t.channel,
        t.ip_address,
        t.device_id
    FROM transactions t
    WHERE t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
      AND t.status IN ('pending', 'completed')
)
SELECT
    ra.transaction_id,
    ra.account_id,
    a.account_number,
    ra.amount,
    abb.avg_amount,
    abb.stddev_amount,
    CASE
        WHEN ra.amount > (abb.avg_amount + 3 * abb.stddev_amount) THEN 'UNUSUAL_AMOUNT'
        ELSE 'NORMAL_AMOUNT'
    END AS amount_anomaly,
    CASE
        WHEN ABS(HOUR(ra.initiated_at) - abb.avg_hour) > 6 THEN 'UNUSUAL_TIME'
        ELSE 'NORMAL_TIME'
    END AS time_anomaly,
    CASE
        WHEN ra.channel NOT IN (
            SELECT DISTINCT channel FROM transactions
            WHERE account_id = ra.account_id
              AND status = 'completed'
              AND initiated_at < DATE_SUB(CURDATE(), INTERVAL 7 DAY)
        ) THEN 'NEW_CHANNEL'
        ELSE 'KNOWN_CHANNEL'
    END AS channel_anomaly,
    c.risk_level
FROM RecentActivity ra
JOIN AccountBehaviorBaseline abb ON ra.account_id = abb.account_id
JOIN accounts a ON ra.account_id = a.account_id
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
WHERE ra.amount > (abb.avg_amount + 2 * abb.stddev_amount)
   OR ABS(HOUR(ra.initiated_at) - abb.avg_hour) > 6
ORDER BY ra.amount DESC;

-- =========================================
-- 8. Fraud Ring Detection
-- =========================================

-- Identify linked accounts potentially involved in fraud
WITH LinkedAccounts AS (
    SELECT DISTINCT
        ah1.customer_id AS customer1,
        ah2.customer_id AS customer2,
        'SHARED_ACCOUNT' AS link_type,
        ah1.account_id AS shared_resource
    FROM account_holders ah1
    JOIN account_holders ah2 ON ah1.account_id = ah2.account_id
    WHERE ah1.customer_id < ah2.customer_id

    UNION

    SELECT DISTINCT
        df1.customer_id AS customer1,
        df2.customer_id AS customer2,
        'SHARED_DEVICE' AS link_type,
        df1.device_hash AS shared_resource
    FROM device_fingerprints df1
    JOIN device_fingerprints df2 ON df1.device_hash = df2.device_hash
    WHERE df1.customer_id < df2.customer_id

    UNION

    SELECT DISTINCT
        c1.customer_id AS customer1,
        c2.customer_id AS customer2,
        'SAME_ADDRESS' AS link_type,
        ca1.address_id AS shared_resource
    FROM customer_addresses ca1
    JOIN customer_addresses ca2 ON ca1.street_address_1 = ca2.street_address_1
                                AND ca1.postal_code = ca2.postal_code
    JOIN customers c1 ON ca1.customer_id = c1.customer_id
    JOIN customers c2 ON ca2.customer_id = c2.customer_id
    WHERE c1.customer_id < c2.customer_id
)
SELECT
    la.customer1,
    la.customer2,
    la.link_type,
    c1.risk_level AS customer1_risk,
    c2.risk_level AS customer2_risk,
    (SELECT COUNT(*) FROM fraud_alerts WHERE customer_id = la.customer1) AS customer1_alerts,
    (SELECT COUNT(*) FROM fraud_alerts WHERE customer_id = la.customer2) AS customer2_alerts,
    CASE
        WHEN c1.risk_level = 'high' OR c2.risk_level = 'high' THEN 'HIGH_RISK_LINK'
        WHEN (SELECT COUNT(*) FROM fraud_alerts WHERE customer_id IN (la.customer1, la.customer2)) > 3 THEN 'SUSPICIOUS_LINK'
        ELSE 'MONITOR'
    END AS link_risk_assessment
FROM LinkedAccounts la
JOIN customers c1 ON la.customer1 = c1.customer_id
JOIN customers c2 ON la.customer2 = c2.customer_id
WHERE c1.risk_level IN ('medium', 'high')
   OR c2.risk_level IN ('medium', 'high')
   OR EXISTS (SELECT 1 FROM fraud_alerts WHERE customer_id IN (la.customer1, la.customer2))
ORDER BY link_risk_assessment DESC, customer1_alerts + customer2_alerts DESC;

-- =========================================
-- 9. Fraud Metrics Dashboard
-- =========================================

-- Overall fraud prevention metrics
SELECT
    DATE(fa.created_at) AS date,
    COUNT(DISTINCT fa.alert_id) AS total_alerts,
    COUNT(DISTINCT fa.customer_id) AS customers_flagged,
    COUNT(DISTINCT fa.transaction_id) AS transactions_flagged,
    SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN 1 ELSE 0 END) AS confirmed_frauds,
    SUM(CASE WHEN fa.status = 'cleared' THEN 1 ELSE 0 END) AS false_positives,
    SUM(CASE WHEN fa.action_taken = 'blocked' THEN t.amount ELSE 0 END) AS amount_blocked,
    SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN t.amount ELSE 0 END) AS fraud_loss_prevented,
    ROUND(100.0 * SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN 1 ELSE 0 END) / COUNT(*), 2) AS precision_rate
FROM fraud_alerts fa
LEFT JOIN transactions t ON fa.transaction_id = t.transaction_id
WHERE fa.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(fa.created_at)
ORDER BY date DESC;

-- =========================================
-- 10. Risk Rule Effectiveness
-- =========================================

-- Analyze effectiveness of fraud detection rules
SELECT
    rr.rule_id,
    rr.rule_name,
    rr.rule_type,
    rr.action,
    COUNT(fa.alert_id) AS alerts_triggered,
    SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN 1 ELSE 0 END) AS true_positives,
    SUM(CASE WHEN fa.status = 'cleared' THEN 1 ELSE 0 END) AS false_positives,
    ROUND(100.0 * SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN 1 ELSE 0 END) /
          NULLIF(COUNT(fa.alert_id), 0), 2) AS precision_rate,
    SUM(CASE WHEN fa.status = 'confirmed_fraud' THEN t.amount ELSE 0 END) AS fraud_prevented,
    AVG(fa.risk_score) AS avg_risk_score
FROM risk_rules rr
LEFT JOIN fraud_alerts fa ON rr.rule_id = fa.rule_id
    AND fa.created_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN transactions t ON fa.transaction_id = t.transaction_id
WHERE rr.is_active = TRUE
GROUP BY rr.rule_id, rr.rule_name, rr.rule_type, rr.action
ORDER BY alerts_triggered DESC, precision_rate DESC;
