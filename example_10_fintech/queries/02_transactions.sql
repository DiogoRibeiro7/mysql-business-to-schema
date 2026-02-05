-- =========================================
-- FinTech Platform - Transaction Queries
-- =========================================

USE fintech;

-- =========================================
-- 1. Recent Transaction History
-- =========================================

-- Get recent transactions for an account
SELECT
    t.transaction_id,
    t.transaction_uuid,
    t.initiated_at,
    t.transaction_type,
    t.amount,
    t.currency,
    t.balance_after,
    t.description,
    t.reference_number,
    t.status,
    t.channel,
    CASE
        WHEN tr.transfer_id IS NOT NULL THEN
            CONCAT('Transfer ', tr.transfer_type, ' to/from ', tr.beneficiary_name)
        ELSE t.description
    END AS enhanced_description
FROM transactions t
LEFT JOIN transfers tr ON t.transaction_id IN (tr.from_transaction_id, tr.to_transaction_id)
WHERE t.account_id = 1
ORDER BY t.initiated_at DESC
LIMIT 50;

-- =========================================
-- 2. Daily Transaction Volume
-- =========================================

-- Transaction volume and value by day
SELECT
    DATE(initiated_at) AS transaction_date,
    transaction_type,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount,
    COUNT(DISTINCT account_id) AS unique_accounts,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed,
    SUM(CASE WHEN status = 'reversed' THEN 1 ELSE 0 END) AS reversed
FROM transactions
WHERE initiated_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY DATE(initiated_at), transaction_type
ORDER BY transaction_date DESC, total_amount DESC;

-- =========================================
-- 3. High-Value Transaction Monitoring
-- =========================================

-- Monitor large transactions for compliance
SELECT
    t.transaction_id,
    t.initiated_at,
    a.account_number,
    c.customer_id,
    CASE
        WHEN ic.customer_id IS NOT NULL THEN CONCAT(ic.first_name, ' ', ic.last_name)
        WHEN bc.customer_id IS NOT NULL THEN bc.business_name
    END AS customer_name,
    c.risk_level,
    t.transaction_type,
    t.amount,
    t.currency,
    t.description,
    t.status,
    t.channel,
    t.ip_address,
    CASE
        WHEN fa.alert_id IS NOT NULL THEN 'FLAGGED'
        ELSE 'CLEAR'
    END AS fraud_status
FROM transactions t
JOIN accounts a ON t.account_id = a.account_id
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
LEFT JOIN individual_customers ic ON c.customer_id = ic.customer_id
LEFT JOIN business_customers bc ON c.customer_id = bc.customer_id
LEFT JOIN fraud_alerts fa ON t.transaction_id = fa.transaction_id
WHERE t.amount > 10000
    AND t.initiated_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
ORDER BY t.amount DESC, t.initiated_at DESC;

-- =========================================
-- 4. Transaction Velocity Analysis
-- =========================================

-- Detect unusual transaction velocity (potential fraud)
WITH TransactionVelocity AS (
    SELECT
        account_id,
        COUNT(*) AS tx_count_1h,
        SUM(amount) AS total_amount_1h,
        MAX(amount) AS max_amount_1h,
        COUNT(DISTINCT ip_address) AS unique_ips,
        COUNT(DISTINCT device_id) AS unique_devices
    FROM transactions
    WHERE initiated_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
        AND status IN ('pending', 'completed')
    GROUP BY account_id
    HAVING tx_count_1h >= 5 OR total_amount_1h > 5000
)
SELECT
    tv.*,
    a.account_number,
    a.account_type,
    a.balance,
    c.risk_level,
    c.email
FROM TransactionVelocity tv
JOIN accounts a ON tv.account_id = a.account_id
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
ORDER BY tv.tx_count_1h DESC, tv.total_amount_1h DESC;

-- =========================================
-- 5. Cross-Border Transaction Analysis
-- =========================================

-- International transfers and currency conversions
SELECT
    tr.transfer_id,
    tr.transfer_type,
    t1.initiated_at,
    tr.from_currency,
    tr.to_currency,
    tr.amount,
    tr.exchange_rate,
    ROUND(tr.amount * tr.exchange_rate, 2) AS converted_amount,
    tr.fee_amount,
    tr.beneficiary_name,
    tr.swift_code,
    t1.status,
    c.customer_id,
    c.risk_level,
    ac.result AS aml_check_result
FROM transfers tr
JOIN transactions t1 ON tr.from_transaction_id = t1.transaction_id
JOIN accounts a ON t1.account_id = a.account_id
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
LEFT JOIN (
    SELECT customer_id, MAX(check_date) AS latest_check, result
    FROM aml_checks
    GROUP BY customer_id, result
) ac ON c.customer_id = ac.customer_id
WHERE tr.transfer_type = 'international_wire'
    AND t1.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
ORDER BY t1.initiated_at DESC;

-- =========================================
-- 6. Failed Transaction Analysis
-- =========================================

-- Analyze failed transactions to identify issues
SELECT
    DATE(initiated_at) AS failure_date,
    transaction_type,
    channel,
    COUNT(*) AS failed_count,
    SUM(amount) AS failed_amount,
    AVG(amount) AS avg_failed_amount,
    COUNT(DISTINCT account_id) AS affected_accounts,
    GROUP_CONCAT(DISTINCT LEFT(description, 50) SEPARATOR '; ') AS failure_reasons
FROM transactions
WHERE status = 'failed'
    AND initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY DATE(initiated_at), transaction_type, channel
ORDER BY failure_date DESC, failed_count DESC;

-- =========================================
-- 7. Channel Usage Statistics
-- =========================================

-- Transaction channel preference analysis
SELECT
    channel,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT account_id) AS unique_accounts,
    SUM(amount) AS total_volume,
    AVG(amount) AS avg_transaction,
    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) AS successful,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed,
    ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS success_rate
FROM transactions
WHERE initiated_at >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY channel
ORDER BY transaction_count DESC;

-- =========================================
-- 8. Peak Transaction Hours
-- =========================================

-- Identify peak transaction hours for capacity planning
SELECT
    HOUR(initiated_at) AS hour_of_day,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_volume,
    AVG(amount) AS avg_amount,
    COUNT(DISTINCT account_id) AS unique_accounts,
    AVG(CASE WHEN status = 'completed'
        THEN TIMESTAMPDIFF(SECOND, initiated_at, completed_at)
        ELSE NULL END) AS avg_processing_time_seconds
FROM transactions
WHERE initiated_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
GROUP BY HOUR(initiated_at)
ORDER BY hour_of_day;

-- =========================================
-- 9. Monthly Transaction Summary
-- =========================================

-- Comprehensive monthly transaction report
WITH MonthlyStats AS (
    SELECT
        DATE_FORMAT(initiated_at, '%Y-%m') AS month,
        transaction_type,
        COUNT(*) AS tx_count,
        SUM(amount) AS total_amount,
        AVG(amount) AS avg_amount,
        COUNT(DISTINCT account_id) AS unique_accounts
    FROM transactions
    WHERE status = 'completed'
        AND initiated_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(initiated_at, '%Y-%m'), transaction_type
),
MonthlyTotals AS (
    SELECT
        month,
        SUM(tx_count) AS total_tx,
        SUM(total_amount) AS total_volume
    FROM MonthlyStats
    GROUP BY month
)
SELECT
    ms.month,
    ms.transaction_type,
    ms.tx_count,
    ROUND(100.0 * ms.tx_count / mt.total_tx, 2) AS pct_of_transactions,
    ms.total_amount,
    ROUND(100.0 * ms.total_amount / mt.total_volume, 2) AS pct_of_volume,
    ms.avg_amount,
    ms.unique_accounts
FROM MonthlyStats ms
JOIN MonthlyTotals mt ON ms.month = mt.month
ORDER BY ms.month DESC, ms.total_amount DESC;

-- =========================================
-- 10. Transaction Pattern Recognition
-- =========================================

-- Identify recurring transaction patterns (subscriptions, salary, etc.)
WITH RecurringTransactions AS (
    SELECT
        account_id,
        description,
        amount,
        COUNT(*) AS occurrence_count,
        MIN(initiated_at) AS first_occurrence,
        MAX(initiated_at) AS last_occurrence,
        AVG(DATEDIFF(
            initiated_at,
            LAG(initiated_at) OVER (PARTITION BY account_id, description, amount ORDER BY initiated_at)
        )) AS avg_days_between
    FROM transactions
    WHERE status = 'completed'
        AND initiated_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY account_id, description, amount
    HAVING COUNT(*) >= 3
)
SELECT
    rt.*,
    a.account_number,
    CASE
        WHEN avg_days_between BETWEEN 28 AND 32 THEN 'Monthly'
        WHEN avg_days_between BETWEEN 13 AND 15 THEN 'Bi-weekly'
        WHEN avg_days_between BETWEEN 6 AND 8 THEN 'Weekly'
        WHEN avg_days_between BETWEEN 364 AND 366 THEN 'Annual'
        ELSE 'Other'
    END AS pattern_type
FROM RecurringTransactions rt
JOIN accounts a ON rt.account_id = a.account_id
WHERE avg_days_between IS NOT NULL
ORDER BY occurrence_count DESC, amount DESC;