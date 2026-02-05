-- =========================================
-- FinTech Platform - Account Management Queries
-- =========================================

USE fintech;

-- =========================================
-- 1. Customer Account Overview
-- =========================================

-- Get all accounts for a customer with current balances
SELECT
    c.customer_id,
    c.email,
    CASE
        WHEN ic.customer_id IS NOT NULL THEN CONCAT(ic.first_name, ' ', ic.last_name)
        WHEN bc.customer_id IS NOT NULL THEN bc.business_name
    END AS customer_name,
    c.status AS customer_status,
    c.risk_level,
    a.account_number,
    a.account_type,
    a.currency,
    a.status AS account_status,
    a.balance,
    a.available_balance,
    a.pending_balance,
    ah.relationship_type,
    ah.ownership_percentage
FROM customers c
LEFT JOIN individual_customers ic ON c.customer_id = ic.customer_id
LEFT JOIN business_customers bc ON c.customer_id = bc.customer_id
JOIN account_holders ah ON c.customer_id = ah.customer_id
JOIN accounts a ON ah.account_id = a.account_id
WHERE c.customer_id = 1
ORDER BY a.account_type, a.opened_date;

-- =========================================
-- 2. Account Balance Summary
-- =========================================

-- Total balances by account type and currency
SELECT
    account_type,
    currency,
    COUNT(*) AS num_accounts,
    SUM(balance) AS total_balance,
    SUM(available_balance) AS total_available,
    SUM(pending_balance) AS total_pending,
    AVG(balance) AS avg_balance,
    MIN(balance) AS min_balance,
    MAX(balance) AS max_balance
FROM accounts
WHERE status = 'active'
GROUP BY account_type, currency
ORDER BY account_type, currency;

-- =========================================
-- 3. High-Value Accounts
-- =========================================

-- Find top accounts by balance
SELECT
    a.account_number,
    a.account_type,
    a.currency,
    a.balance,
    c.customer_id,
    CASE
        WHEN ic.customer_id IS NOT NULL THEN CONCAT(ic.first_name, ' ', ic.last_name)
        WHEN bc.customer_id IS NOT NULL THEN bc.business_name
    END AS customer_name,
    c.customer_type,
    c.risk_level,
    a.last_transaction_date
FROM accounts a
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
LEFT JOIN individual_customers ic ON c.customer_id = ic.customer_id
LEFT JOIN business_customers bc ON c.customer_id = bc.customer_id
WHERE a.status = 'active'
ORDER BY a.balance DESC
LIMIT 20;

-- =========================================
-- 4. Dormant Account Detection
-- =========================================

-- Find accounts with no activity in last 90 days
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    a.currency,
    a.last_transaction_date,
    DATEDIFF(CURDATE(), a.last_transaction_date) AS days_inactive,
    c.email,
    c.phone_number
FROM accounts a
JOIN account_holders ah ON a.account_id = ah.account_id AND ah.relationship_type = 'primary'
JOIN customers c ON ah.customer_id = c.customer_id
WHERE a.status = 'active'
    AND a.balance > 0
    AND (a.last_transaction_date IS NULL
         OR a.last_transaction_date < DATE_SUB(CURDATE(), INTERVAL 90 DAY))
ORDER BY a.balance DESC;

-- =========================================
-- 5. Account Opening Trends
-- =========================================

-- Monthly account opening statistics
SELECT
    DATE_FORMAT(opened_date, '%Y-%m') AS month,
    account_type,
    COUNT(*) AS accounts_opened,
    SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) AS currently_active,
    SUM(CASE WHEN status = 'closed' THEN 1 ELSE 0 END) AS closed,
    AVG(DATEDIFF(IFNULL(closed_date, CURDATE()), opened_date)) AS avg_account_lifetime_days
FROM accounts
WHERE opened_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(opened_date, '%Y-%m'), account_type
ORDER BY month DESC, account_type;

-- =========================================
-- 6. Joint Account Analysis
-- =========================================

-- Find all joint accounts and their holders
SELECT
    a.account_number,
    a.account_type,
    a.balance,
    GROUP_CONCAT(
        CONCAT(
            CASE
                WHEN ic.customer_id IS NOT NULL THEN CONCAT(ic.first_name, ' ', ic.last_name)
                WHEN bc.customer_id IS NOT NULL THEN bc.business_name
            END,
            ' (', ah.relationship_type, ' - ', ah.ownership_percentage, '%)'
        )
        ORDER BY ah.relationship_type, ah.ownership_percentage DESC
        SEPARATOR ', '
    ) AS account_holders
FROM accounts a
JOIN account_holders ah ON a.account_id = ah.account_id
JOIN customers c ON ah.customer_id = c.customer_id
LEFT JOIN individual_customers ic ON c.customer_id = ic.customer_id
LEFT JOIN business_customers bc ON c.customer_id = bc.customer_id
WHERE a.status = 'active'
GROUP BY a.account_id
HAVING COUNT(ah.account_holder_id) > 1
ORDER BY a.balance DESC;

-- =========================================
-- 7. Interest Calculation Due
-- =========================================

-- Accounts due for interest calculation
SELECT
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance,
    a.interest_rate,
    a.last_interest_date,
    DATEDIFF(CURDATE(), IFNULL(a.last_interest_date, a.opened_date)) AS days_since_interest,
    ROUND(
        a.balance * a.interest_rate / 100 *
        DATEDIFF(CURDATE(), IFNULL(a.last_interest_date, a.opened_date)) / 365,
        2
    ) AS accrued_interest
FROM accounts a
WHERE a.account_type IN ('savings', 'checking')
    AND a.status = 'active'
    AND a.interest_rate > 0
    AND (a.last_interest_date IS NULL
         OR a.last_interest_date < DATE_SUB(CURDATE(), INTERVAL 1 MONTH))
ORDER BY accrued_interest DESC;

-- =========================================
-- 8. Account Type Migration
-- =========================================

-- Customers eligible for account upgrade
WITH AccountActivity AS (
    SELECT
        a.account_id,
        a.account_type,
        ah.customer_id,
        a.balance,
        COUNT(t.transaction_id) AS transaction_count,
        AVG(t.amount) AS avg_transaction_amount,
        MAX(t.initiated_at) AS last_transaction
    FROM accounts a
    JOIN account_holders ah ON a.account_id = ah.account_id
    LEFT JOIN transactions t ON a.account_id = t.account_id
        AND t.initiated_at >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
        AND t.status = 'completed'
    WHERE a.status = 'active'
        AND ah.relationship_type = 'primary'
    GROUP BY a.account_id, a.account_type, ah.customer_id, a.balance
)
SELECT
    aa.customer_id,
    c.email,
    aa.account_type AS current_type,
    aa.balance,
    aa.transaction_count,
    aa.avg_transaction_amount,
    CASE
        WHEN aa.account_type = 'checking' AND aa.balance > 10000 THEN 'Premium Checking'
        WHEN aa.account_type = 'savings' AND aa.balance > 25000 THEN 'High-Yield Savings'
        WHEN aa.account_type = 'checking' AND aa.transaction_count > 50 THEN 'Active Checking'
        ELSE 'No Upgrade'
    END AS recommended_upgrade
FROM AccountActivity aa
JOIN customers c ON aa.customer_id = c.customer_id
WHERE aa.balance > 5000
    OR aa.transaction_count > 30
ORDER BY aa.balance DESC;

-- =========================================
-- 9. Currency Exposure Report
-- =========================================

-- Total exposure by currency across all accounts
SELECT
    a.currency,
    COUNT(DISTINCT a.account_id) AS num_accounts,
    COUNT(DISTINCT ah.customer_id) AS num_customers,
    SUM(a.balance) AS total_balance,
    SUM(a.available_balance) AS total_available,
    SUM(a.pending_balance) AS total_pending,
    MAX(er.exchange_rate) AS current_rate_to_usd,
    SUM(a.balance * IFNULL(er.exchange_rate, 1)) AS total_balance_usd
FROM accounts a
JOIN account_holders ah ON a.account_id = ah.account_id
LEFT JOIN exchange_rates er ON a.currency = er.from_currency
    AND er.to_currency = 'USD'
    AND er.rate_date = (
        SELECT MAX(rate_date)
        FROM exchange_rates
        WHERE from_currency = a.currency AND to_currency = 'USD'
    )
WHERE a.status = 'active'
GROUP BY a.currency
ORDER BY total_balance_usd DESC;

-- =========================================
-- 10. Account Closure Analysis
-- =========================================

-- Analyze closed accounts to understand churn
SELECT
    DATE_FORMAT(closed_date, '%Y-%m') AS closure_month,
    account_type,
    COUNT(*) AS accounts_closed,
    AVG(DATEDIFF(closed_date, opened_date)) AS avg_lifetime_days,
    AVG(balance) AS avg_final_balance,
    COUNT(CASE WHEN balance > 0 THEN 1 END) AS closed_with_balance
FROM accounts
WHERE status = 'closed'
    AND closed_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(closed_date, '%Y-%m'), account_type
ORDER BY closure_month DESC, accounts_closed DESC;