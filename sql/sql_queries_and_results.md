# CFPB Consumer Complaint Intelligence - SQL Queries & Output Results

This document showcases production-grade SQL scripts featuring schemas, CTEs, window functions, and business KPIs along with their executed output tables.

## Query 1: High-Level Portfolio Health & Volume Summary

*Calculates global dataset metrics including date range, total disputes, distinct companies, and product coverage.*

```sql
SELECT 
    COUNT(*) AS total_complaints,
    MIN(date_received) AS min_date,
    MAX(date_received) AS max_date,
    COUNT(DISTINCT company) AS total_companies,
    COUNT(DISTINCT product) AS total_products
FROM cfpb_analytics.complaints;
```

**Query Result Output:**

|   total_complaints | min_date            | max_date            |   total_companies |   total_products |
|-------------------:|:--------------------|:--------------------|------------------:|-----------------:|
|           15741615 | 2021-09-26 00:00:00 | 2026-09-26 00:00:00 |              6110 |               14 |

---

## Query 2: Top 3 Complaint Issues Per Product (Window Function DENSE_RANK)

*Applies DENSE_RANK partitioned by product category to rank recurring consumer pain points.*

```sql
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
ORDER BY product, issue_rank
LIMIT 15;
```

**Query Result Output:**

| product                                                                      |   issue_rank | issue                                                                            |   total_complaints |
|:-----------------------------------------------------------------------------|-------------:|:---------------------------------------------------------------------------------|-------------------:|
| Checking or savings account                                                  |            1 | Managing an account                                                              |             169206 |
| Checking or savings account                                                  |            2 | Closing an account                                                               |              38802 |
| Checking or savings account                                                  |            3 | Problem with a lender or other company charging your account                     |              36279 |
| Credit card                                                                  |            1 | Problem with a purchase shown on your statement                                  |              62313 |
| Credit card                                                                  |            2 | Incorrect information on your report                                             |              32611 |
| Credit card                                                                  |            3 | Getting a credit card                                                            |              31670 |
| Credit card or prepaid card                                                  |            1 | Problem with a purchase shown on your statement                                  |              20584 |
| Credit card or prepaid card                                                  |            2 | Getting a credit card                                                            |              12054 |
| Credit card or prepaid card                                                  |            3 | Other features, terms, or problems                                               |               8550 |
| Credit reporting or other personal consumer reports                          |            1 | Incorrect information on your report                                             |            7081211 |
| Credit reporting or other personal consumer reports                          |            2 | Improper use of your report                                                      |            2920883 |
| Credit reporting or other personal consumer reports                          |            3 | Problem with a company's investigation into an existing problem                  |            2325124 |
| Credit reporting, credit repair services, or other personal consumer reports |            1 | Incorrect information on your report                                             |             507499 |
| Credit reporting, credit repair services, or other personal consumer reports |            2 | Improper use of your report                                                      |             435310 |
| Credit reporting, credit repair services, or other personal consumer reports |            3 | Problem with a credit reporting company's investigation into an existing problem |             361768 |

---

## Query 3: Company SLA Turnaround & Timely Response Compliance

*Identifies bottom 10 companies with lowest timely response percentages (filtered for companies with >= 1,000 complaints).*

```sql
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
```

**Query Result Output:**

| company                                          |   total_complaints |   avg_turnaround_days |   timely_response_rate_pct |
|:-------------------------------------------------|-------------------:|----------------------:|---------------------------:|
| Servicer under contract with Federal Student Aid |               7476 |                  6.6  |                       0    |
| Westcreek Financial                              |               1179 |                  3.49 |                      58.18 |
| Rent Recovery Solutions                          |               2657 |                  2.61 |                      59.28 |
| Conduent Incorporated                            |               1080 |                 10.01 |                      59.91 |
| MOHELA                                           |              28895 |                  1.38 |                      63.99 |
| Professional Debt Mediation, Inc.                |               1485 |                  2.87 |                      67    |
| EdFinancial Services                             |               9295 |                  2.92 |                      76.79 |
| Incomm Holdings Inc.                             |               3163 |                  2.74 |                      78.63 |
| CCS Financial Services, Inc.                     |              24421 |                  1.63 |                      83.68 |
| Waypoint Resource Group, LLC                     |               1875 |                  1.19 |                      84.75 |

---

## Query 4: Month-over-Month (MoM) Complaint Growth Percentage Using LAG()

*Calculates MoM dispute growth using LAG() window function across historical monthly complaint volume.*

```sql
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
ORDER BY year DESC, month DESC
LIMIT 12;
```

**Query Result Output:**

|   year |   month |   monthly_count |   prev_month_count |   mom_growth_pct |
|-------:|--------:|----------------:|-------------------:|-----------------:|
|   2026 |       9 |          505167 |             653305 |           -22.68 |
|   2026 |       8 |          653305 |             670099 |            -2.51 |
|   2026 |       7 |          670099 |             620832 |             7.94 |
|   2026 |       6 |          620832 |             619958 |             0.14 |
|   2026 |       5 |          619958 |             618300 |             0.27 |
|   2026 |       4 |          618300 |             614957 |             0.54 |
|   2026 |       3 |          614957 |             497121 |            23.7  |
|   2026 |       2 |          497121 |             541264 |            -8.16 |
|   2026 |       1 |          541264 |             512474 |             5.62 |
|   2025 |      12 |          512474 |             496658 |             3.18 |
|   2025 |      11 |          496658 |             519786 |            -4.45 |
|   2025 |      10 |          519786 |             503850 |             3.16 |

---

