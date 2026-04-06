-- ============================================================
-- Digital Marketing Performance Analysis
-- SQL Cleaning & Transformation Queries
-- © 2026 Lucas Camargo. All Rights Reserved.
-- ============================================================

-- ============================================================
-- STEP 1: Create the project database
-- ============================================================
CREATE DATABASE MarketingProject;
USE MarketingProject;

-- ============================================================
-- STEP 2: Load raw CSV files via SSMS Import Wizard
-- (Right-click database → Tasks → Import Flat File)
-- Tables created: raw_ads, raw_sales
-- ============================================================

-- ============================================================
-- STEP 3: Inspect raw data
-- ============================================================

-- Check row counts
SELECT COUNT(*) AS raw_ads_rows   FROM raw_ads;    -- expect ~15,408
SELECT COUNT(*) AS raw_sales_rows FROM raw_sales;  -- expect ~541,909

-- Check for nulls in ads
SELECT
    SUM(CASE WHEN cost    IS NULL THEN 1 ELSE 0 END) AS null_cost,
    SUM(CASE WHEN clicks  IS NULL THEN 1 ELSE 0 END) AS null_clicks,
    SUM(CASE WHEN revenue IS NULL THEN 1 ELSE 0 END) AS null_revenue,
    SUM(CASE WHEN displays IS NULL THEN 1 ELSE 0 END) AS null_displays
FROM raw_ads;

-- Check for nulls/negatives in sales
SELECT
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN Quantity   <= 0    THEN 1 ELSE 0 END) AS negative_qty,
    SUM(CASE WHEN UnitPrice  <= 0    THEN 1 ELSE 0 END) AS zero_price
FROM raw_sales;

-- ============================================================
-- STEP 4: Clean ads data → raw_ads_clean
-- ============================================================
SELECT
    month,
    day,
    campaign_number,
    user_engagement,
    banner,
    placement,
    displays,
    cost,
    clicks,
    revenue,
    post_click_conversions,
    post_click_sales_amount
INTO raw_ads_clean
FROM raw_ads
WHERE cost    IS NOT NULL
  AND clicks  IS NOT NULL
  AND revenue IS NOT NULL
  AND displays IS NOT NULL
  AND displays > 0;

-- Verify
SELECT COUNT(*) AS clean_ads_rows FROM raw_ads_clean;

-- ============================================================
-- STEP 5: Clean sales data → raw_sales_clean
-- ============================================================
SELECT
    InvoiceNo,
    InvoiceDate,
    CustomerID,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    Country,
    CAST(Quantity * UnitPrice AS DECIMAL(18,2)) AS LineTotal
INTO raw_sales_clean
FROM raw_sales
WHERE Quantity  > 0
  AND UnitPrice > 0
  AND CustomerID IS NOT NULL;

-- Verify
SELECT COUNT(*) AS clean_sales_rows FROM raw_sales_clean;

-- ============================================================
-- STEP 6: Create daily sales summary (Apr–Jun only)
-- ============================================================

/* ============================================================
   PRIVACY FIREWALL — Legislative Compliance Layer
   ============================================================
   CustomerID is used ONLY here as an aggregate COUNT to derive
   the business metric 'daily_customers'. The raw CustomerID
   value is deliberately excluded from all downstream tables.

   This ensures that no Personally Identifiable Information (PII)
   reaches the reporting or visualisation layer (Power BI).

   Compliance alignment:
     - GDPR Article 5(1)(c): Data minimisation principle
     - Australian Privacy Act 1988, APP 11: Security of PI
     - ISO/IEC 27001: Information security best practice

   Result: sales_ads_joined_focus contains ZERO customer-level
   identifiers — safe for C-Suite distribution and cross-team
   sharing without additional redaction.
   ============================================================ */

SELECT
    CAST(InvoiceDate AS DATE)           AS sale_date,
    MONTH(InvoiceDate)                  AS month_num,
    DATENAME(MONTH, InvoiceDate)        AS month_name,
    DAY(InvoiceDate)                    AS day_num,
    SUM(LineTotal)                      AS daily_revenue,
    COUNT(DISTINCT InvoiceNo)           AS daily_orders,
    COUNT(DISTINCT CustomerID)          AS daily_customers,  -- aggregate only; raw ID never leaves this layer
    SUM(Quantity)                       AS daily_units_sold
INTO daily_sales_apr_jun
FROM raw_sales_clean
WHERE MONTH(InvoiceDate) BETWEEN 4 AND 6
GROUP BY
    CAST(InvoiceDate AS DATE),
    MONTH(InvoiceDate),
    DATENAME(MONTH, InvoiceDate),
    DAY(InvoiceDate);

-- Verify
SELECT COUNT(*) AS daily_rows FROM daily_sales_apr_jun;
SELECT * FROM daily_sales_apr_jun ORDER BY sale_date;

-- ============================================================
-- STEP 7: Create final joined table → sales_ads_joined_focus
-- ============================================================

-- NOTE — Data Type Normalisation:
-- The ads table stores month as text ('April', 'May', 'June').
-- The sales table stores InvoiceDate as a DATE.
-- DATENAME(MONTH, InvoiceDate) converts DATE → month name text
-- so both sides of the JOIN key are the same type.
-- DAY(InvoiceDate) extracts the numeric day for the second key.
-- This composite key (day number + month name) resolves the
-- date/text mismatch between the two source datasets.

SELECT
    a.month,
    a.day,
    a.campaign_number,
    a.user_engagement,
    a.banner,
    a.placement,
    a.displays,
    a.cost                              AS total_ad_spend,
    a.clicks                            AS total_clicks,
    a.revenue                           AS total_ad_revenue,
    a.post_click_conversions,
    a.post_click_sales_amount,
    -- Derived ad metrics
    CASE
        WHEN a.clicks > 0
        THEN CAST(a.clicks AS FLOAT) / NULLIF(a.displays, 0)
        ELSE 0
    END                                 AS CTR,
    CASE
        WHEN a.post_click_conversions > 0
        THEN a.cost / a.post_click_conversions
        ELSE 0
    END                                 AS CPA,
    CASE
        WHEN a.cost > 0
        THEN a.revenue / a.cost
        ELSE 0
    END                                 AS ROAS,
    -- Sales data (joined via LEFT JOIN — COALESCE handles days
    -- where no matching sales record exists, treating them as
    -- zero-revenue days rather than producing NULL gaps)
    COALESCE(s.daily_revenue,   0)      AS daily_revenue,
    COALESCE(s.daily_orders,    0)      AS daily_orders,
    COALESCE(s.daily_customers, 0)      AS daily_customers,
    COALESCE(s.daily_units_sold,0)      AS daily_units_sold,
    -- Profit
    CAST(a.revenue - a.cost AS DECIMAL(18,2)) AS profit_after_ads
INTO sales_ads_joined_focus
FROM raw_ads_clean a
LEFT JOIN daily_sales_apr_jun s
    ON a.day = s.day_num
    AND a.month = s.month_name;

-- Verify
SELECT COUNT(*) AS joined_rows FROM sales_ads_joined_focus;

-- ============================================================
-- STEP 8: Key summary queries (used to validate Power BI)
-- ============================================================

-- Overall performance summary
SELECT
    SUM(total_ad_spend)             AS total_spend,
    SUM(total_ad_revenue)           AS total_revenue,
    SUM(profit_after_ads)           AS total_profit,
    SUM(total_clicks)               AS total_clicks,
    SUM(displays)                   AS total_displays,
    SUM(post_click_conversions)     AS total_conversions,
    AVG(ROAS)                       AS avg_roas,
    AVG(CPA)                        AS avg_cpa
FROM sales_ads_joined_focus;

-- Performance by month
SELECT
    month,
    SUM(total_ad_spend)             AS spend,
    SUM(total_ad_revenue)           AS revenue,
    SUM(profit_after_ads)           AS profit,
    AVG(ROAS)                       AS avg_roas,
    AVG(CPA)                        AS avg_cpa,
    SUM(total_clicks)               AS clicks
FROM sales_ads_joined_focus
GROUP BY month
ORDER BY
    CASE month
        WHEN 'April' THEN 1
        WHEN 'May'   THEN 2
        WHEN 'June'  THEN 3
    END;

-- Performance by campaign
SELECT
    campaign_number,
    SUM(total_ad_spend)             AS spend,
    SUM(total_ad_revenue)           AS revenue,
    AVG(ROAS)                       AS avg_roas,
    SUM(total_clicks)               AS clicks
FROM sales_ads_joined_focus
GROUP BY campaign_number
ORDER BY revenue DESC;

-- Performance by banner size
SELECT
    banner,
    SUM(total_ad_spend)             AS spend,
    SUM(total_ad_revenue)           AS revenue,
    SUM(total_clicks)               AS clicks,
    AVG(CTR)                        AS avg_ctr
FROM sales_ads_joined_focus
GROUP BY banner
ORDER BY revenue DESC;


-- ============================================================
-- END OF SCRIPT
-- ============================================================
