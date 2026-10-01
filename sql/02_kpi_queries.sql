-- ======================================================================================
-- PROJECT: Consumer Complaint Intelligence (CFPB)
-- FILE: 02_kpi_queries.sql
-- PURPOSE: Advanced Business Analytics, CTEs, Window Functions, and Growth Metrics
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- QUERY 1: Portfolio Health & Overall Volume Summary
-- --------------------------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_complaints,
    MIN(date_received) AS min_date,
    MAX(date_received) AS max_date,
    COUNT(DISTINCT company) AS total_companies,
    COUNT(DISTINCT product) AS total_products
FROM cfpb_analytics.complaints;


-- --------------------------------------------------------------------------------------
-- QUERY 2: Top 3 Complaint Issues Per Product Using Window Function (DENSE_RANK)
-- --------------------------------------------------------------------------------------
WITH RankedIssues AS (
    SELECT 
        product,
        issue,
        COUNT(complaint_id) AS total_complaints,
        DENSE_RANK() OVER (
            PARTITION BY product 
            ORDER BY COUNT(complaint_id) DESC
        ) AS issue_rank
    FROM cfpb_analytics.complaints
    GROUP BY product, issue
)
SELECT 
    product,
    issue_rank,
    issue,
    total_complaints
FROM RankedIssues
WHERE issue_rank <= 3
ORDER BY product, issue_rank;


-- --------------------------------------------------------------------------------------
-- QUERY 3: Company Resolution SLA Turnaround & Timeliness Rate (Min 1,000 Complaints)
-- --------------------------------------------------------------------------------------
WITH CompanyMetrics AS (
    SELECT 
        company,
        COUNT(complaint_id) AS total_complaints,
        SUM(CASE WHEN timely_response = 'Yes' THEN 1 ELSE 0 END) AS timely_count,
        ROUND(AVG(response_days), 2) AS avg_turnaround_days
    FROM cfpb_analytics.complaints
    GROUP BY company
    HAVING COUNT(complaint_id) >= 1000
)
SELECT 
    company,
    total_complaints,
    avg_turnaround_days,
    ROUND((timely_count * 100.0 / total_complaints), 2) AS timely_response_rate_pct
FROM CompanyMetrics
ORDER BY timely_response_rate_pct ASC
LIMIT 10;


-- --------------------------------------------------------------------------------------
-- QUERY 4: Month-over-Month (MoM) Complaint Volume Growth Using LAG() Window Function
-- --------------------------------------------------------------------------------------
WITH MonthlyVolume AS (
    SELECT 
        year,
        month,
        COUNT(complaint_id) AS monthly_count
    FROM cfpb_analytics.complaints
    GROUP BY year, month
)
SELECT 
    year,
    month,
    monthly_count,
    LAG(monthly_count, 1) OVER (ORDER BY year, month) AS prev_month_count,
    ROUND(
        (monthly_count - LAG(monthly_count, 1) OVER (ORDER BY year, month)) * 100.0 / 
        NULLIF(LAG(monthly_count, 1) OVER (ORDER BY year, month), 0), 
        2
    ) AS mom_growth_pct
FROM MonthlyVolume
ORDER BY year, month;
