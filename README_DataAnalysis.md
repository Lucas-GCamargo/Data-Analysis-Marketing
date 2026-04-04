# 📊 Digital Marketing Performance Analysis

[![SQL Server](https://img.shields.io/badge/Database-SQL_Server-CC2927?style=for-the-badge&logo=microsoftsqlserver)](https://www.microsoft.com/sql-server)
[![Power BI](https://img.shields.io/badge/Visualisation-Power_BI-F2C811?style=for-the-badge&logo=powerbi)](https://powerbi.microsoft.com)
[![Excel](https://img.shields.io/badge/Data-Excel_%7C_CSV-217346?style=for-the-badge&logo=microsoftexcel)](https://microsoft.com/excel)
[![Privacy](https://img.shields.io/badge/Compliance-Privacy_Aggregation-0078D4?style=for-the-badge&logo=microsoftazure)](https://www.oaic.gov.au)
[![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)](https://github.com/Lucas-GCamargo/Data-Analysis-Marketing)

> **Note on languages:** GitHub shows HTML as the primary language because the dashboard output is an interactive HTML report. The core analysis was built in **SQL Server (T-SQL)** with results published in **Power BI**.

> **An end-to-end analytics pipeline combining 540,000+ global e-commerce transactions with multi-channel ad data to explore campaign spend patterns and surface potential inefficiencies — built with a SQL privacy aggregation layer for responsible data handling.**

---

## 📊 Dashboard Preview

*(See `sample_dashboards/` folder for full screenshots)*

---

## 📌 The Business Problem

The business was spending over **$142K across three months** on digital advertising with no unified view of which campaigns, creative formats, or time windows were actually driving profitable returns. This analysis explores the data to surface potential patterns and inefficiencies.

Key questions left unanswered:

- Which campaigns are generating real profit — and which are burning budget?
- Are certain days or months structurally more efficient for ad spend?
- Which banner formats deliver the highest return per dollar invested?
- How does ad performance correlate with actual e-commerce transaction volume?

Without answers, budget allocation was essentially guesswork.

---

## 🔍 Approach: Problem → Data → Insight → Recommendation

This project follows a complete professional data pipeline — from raw messy CSVs to boardroom-ready KPIs.

```
Raw CSV Files (2 sources, 557,000+ rows combined)
        ↓
SQL Server — Ingestion & Staging
        ↓
SQL Cleaning Layer
  → raw_ads_clean   (nulls removed, zero-display rows excluded)
  → raw_sales_clean (negative quantities, zero prices, missing IDs removed)
        ↓
SQL Aggregation & Privacy Layer
  → daily_sales_apr_jun  (CustomerID anonymised before reporting layer)
  → sales_ads_joined_focus (ads + sales merged on date)
        ↓
Power BI Dashboard
  → DAX FX measures, KPI cards, ROAS/CPA trend charts, campaign breakdown
```

---

## 🛡️ Data Governance & Privacy Aggregation

> In 2026, data ethics is not a checkbox — it is a competitive differentiator.

This pipeline includes a deliberate **SQL privacy aggregation layer**: `CustomerID` is used only within the cleaning and aggregation layer to count unique customers per day, then **dropped entirely** before the data reaches the reporting and visualisation layer (`sales_ads_joined_focus`).

This means:

- No personally identifiable information (PII) ever enters Power BI
- The reporting layer is safe for sharing across teams without privacy risk
- The architecture mirrors patterns required in **Finance, Healthcare, and Government** regulated environments

```sql
-- CustomerID used here for business metric only...
COUNT(DISTINCT CustomerID) AS daily_customers

-- ...then excluded entirely from the final joined table.
-- sales_ads_joined_focus contains zero customer-level identifiers.
SELECT
    a.month, a.day, a.campaign_number,
    a.cost              AS total_ad_spend,
    a.revenue           AS total_ad_revenue,
    s.daily_revenue,
    s.daily_orders,
    s.daily_customers,  -- aggregate count only, not raw IDs
    s.daily_units_sold
    -- No InvoiceNo, no CustomerID, no StockCode
INTO sales_ads_joined_focus
FROM raw_ads_clean a
LEFT JOIN daily_sales_apr_jun s
    ON a.day = s.day_num AND a.month = s.month_name;
-- Note: These are two separate public datasets joined on temporal fields (day + month).
-- This is an exploratory cross-dataset analysis, not a shared-key business pipeline.
```

**Legislative alignment:** Australian Privacy Act 1988 (Cth) — APP 6 (use or disclosure), APP 11 (security of personal information).

---

## 🗂️ The Datasets

| Dataset | Source | Rows | Coverage |
|---|---|---|---|
| [Online Advertising Digital Marketing Data](https://www.kaggle.com/datasets/naniruddhan/online-advertising-digital-marketing-data) | Kaggle — naniruddhan | 15,408 | April, May, June |
| [Global E-Commerce Transactions](https://www.kaggle.com/idriskoladeaderoju) | Kaggle — idriskoladeaderoju | 541,909 | Dec 2010 – Dec 2011 |

Both datasets are publicly available on Kaggle under their respective licences. All analytical work, SQL transformations, DAX measures, and documentation are original work by the author.

---

## ⚙️ SQL Mastery — What Was Built

### Cleaning Log

| Issue Found | Table | Fix Applied |
|---|---|---|
| NULL cost, clicks, revenue rows | `raw_ads` | Filtered out with `WHERE` clause |
| Zero-display rows (division risk) | `raw_ads` | Excluded with `displays > 0` |
| Negative quantity returns | `raw_sales` | Filtered `Quantity > 0` |
| Zero unit prices | `raw_sales` | Filtered `UnitPrice > 0` |
| NULL CustomerIDs | `raw_sales` | Excluded — unusable for customer metrics |

### Key SQL Techniques Used

- **`SELECT INTO`** — Clean table creation without manual DDL
- **`LEFT JOIN`** on composite key (day number + month name) — preserves all ad records even on days with no sales data
- **`COALESCE`** — Converts NULL sales values on unmatched JOIN rows to zero, preventing NULL gaps in aggregations
- **`DATENAME` / `DAY` / `MONTH`** — Resolves the data type mismatch between the ads table (month as text: "April") and the sales table (month as DATE) by normalising both to the same format before joining
- **`CAST` / `DECIMAL(18,2)`** — Consistent financial precision throughout
- **`NULLIF`** — Safe division to prevent divide-by-zero errors in CTR/CPA/ROAS calculations
- **`CASE WHEN`** — Custom month ordering in `ORDER BY` clauses
- **`COUNT(DISTINCT)`** — Accurate deduplication for customers and orders

---

## 📐 DAX Measures (Power BI)

All KPI cards apply a configurable FX currency conversion rate for cross-market consistency:

| Measure | Logic |
|---|---|
| `FX_AdSpend` | `SUM(total_ad_spend) × FX_Rate` |
| `FX_Revenue` | `SUM(total_ad_revenue) × FX_Rate` |
| `FX_Profit` | `FX_Revenue − FX_AdSpend` |
| `FX_ROAS` | `FX_Revenue ÷ FX_AdSpend` |
| `FX_CPA` | `FX_AdSpend ÷ SUM(post_click_conversions)` |

---

## 📈 Results & Insights

### Overall Performance (April – June)

| Metric | Value |
|---|---|
| Total Ad Spend | $142,224 |
| Total Revenue | $264,974,000 |
| Total Profit After Ads | $264,832,000 |
| Overall ROAS | 1,863× *(cross-dataset temporal join — treat as exploratory)* |
| Average CPA | $0.27 |
| Total Clicks | 2,492,837 |
| Total Displays | 239,017,725 |
| Click-Through Rate | 1.04% |
| Total Conversions | 651,768 |

---

### 💡 Insight 1 — Spend Less, Earn More

*Source: verified against Power BI FX-adjusted output*

| Month | FX Ad Spend | FX Revenue | FX ROAS |
|---|---|---|---|
| April | $67,152 | $76,456,507 | 1,138× |
| May | $47,443 | $94,449,249 | 1,991× |
| **June** | **$27,629** | **$94,068,135** | **3,405× ✅ Best** |

**Insight:** June delivered almost identical revenue to May ($94M vs $94M) while spending 42% less. April consumed the most budget ($67K) yet generated the lowest ROAS — meaning the business was paying more per return in its heaviest spend month.

**Recommendation:** Reallocate 30% of the April budget (~$20K) into the timing and targeting patterns of June. The data suggests that audience saturation — not budget size — may be driving the difference in returns. Subject to validation on a shared-key dataset, this type of reallocation could meaningfully improve overall ROAS.

---

### 💡 Insight 2 — One Banner Drives Nearly Half of All Revenue

| Banner | Revenue | Clicks | Share of Revenue |
|---|---|---|---|
| **240 × 400** | $129,930 | 1,113,256 | **49%** |
| 728 × 90 | $64,342 | 569,606 | 24% |
| 300 × 250 | $43,171 | 411,214 | 16% |

**Recommendation:** Consolidate creative investment into the 240×400 format. Deprioritise lower-performing sizes (468×60, 800×250) in future campaign planning — the remaining five banner sizes combined account for approximately 11% of total revenue, each individually below 5%.

---

### 💡 Insight 3 — Campaign 2 Is the Efficiency Leader

| Campaign | Ad Spend | Revenue | ROAS | Clicks |
|---|---|---|---|---|
| Camp 1 | $150,689 | $230,535 | 1.53× | 1,409,136 |
| **Camp 2** | **$17,037** | **$34,890** | **2.05× ✅** | 881,158 |
| Camp 3 | $7,467 | $10,839 | 1.45× | 202,543 |

> **Note:** Campaign-level spend totals ($175,193 combined) reflect the full raw dataset before null-row cleaning. The overall KPI table ($142,224) reflects the cleaned dataset after invalid rows were removed. Both figures are accurate within their respective scopes.

**Recommendation:** Campaign 2 delivers the highest ROAS despite receiving only 11% of total budget. Campaign 1 receives 85% of spend yet returns less per dollar. A controlled budget increase of 20–30% into Campaign 2 is a low-risk, high-confidence optimisation.

---

## 🏗️ Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│  STAGE 1 — INGESTION                                    │
│  540K+ raw e-commerce rows + 15K ad performance rows    │
│  loaded into MS SQL Server via SSMS Import Wizard       │
└────────────────────────┬────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 2 — SQL PRIVACY AGGREGATION LAYER  🛡️           │
│  CustomerID is used only to compute daily_customers     │
│  then DROPPED before data reaches the reporting layer.  │
│  No PII enters Power BI. Compliant with Privacy Act 1988│
└────────────────────────┬────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 3 — ANALYTICS ENGINE                             │
│  Cleaned sales aggregated daily (Apr–Jun)               │
│  Joined with ad performance on day + month key          │
│  Derived metrics: CTR, CPA, ROAS, profit_after_ads      │
└────────────────────────┬────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  STAGE 4 — C-SUITE INTELLIGENCE                         │
│  Power BI dashboard with FX-adjusted DAX measures       │
│  Identifies 3,405× ROAS in June vs 1,138× in April     │
│  Surfaces potential reallocation opportunities           │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 Executive Recommendations

**1. Shift 30% of April's budget to June-style targeting**
June achieved $94M revenue on $27K spend. April spent $67K for $76M revenue — 2.5× more spend for 19% less return. This suggests a potential reallocation opportunity, though projected ROAS improvements would require validation against a dataset with a shared business key before actioning.

**2. Consolidate creative spend into the 240×400 banner format**
This single format generated 49% of all revenue ($129,930) and 45% of all clicks. The next two formats combined produce less than half of that. Reducing spend on the four underperforming sizes and concentrating on 240×400 is the lowest-risk, highest-confidence optimisation available.

**3. Increase Campaign 2's budget by 20–30%**
Campaign 2 has the highest ROAS (2.05×) but receives only 11% of total budget. Campaign 1 receives 85% of spend yet delivers a lower return per dollar. A controlled increase into Campaign 2 with performance monitoring over 30 days would validate whether this efficiency holds at scale.

---

## 📊 Dashboard Overview

The Power BI dashboard (`MarketingProjectDashboard.pbix`) contains:

| Visual | Type | Business Purpose |
|---|---|---|
| Total Revenue | KPI Card | Headline commercial outcome |
| Profit After Ads | KPI Card | Net value delivered after investment |
| Total Ad Spend | KPI Card | Total budget consumed |
| Revenue & Spend Over Time | Clustered Bar + Line | Identifies budget-efficiency mismatches by month |
| Ad Spend Share by Month | Donut Chart | Shows proportional budget split |
| ROAS Trend | Line Chart | Tracks improving return over time |
| CPA Trend | Area Chart | Visualises declining cost per acquisition |
| Monthly Detail Table | Matrix | Full FX-adjusted breakdown per month |

*(See `sample_dashboards/` for screenshots)*

---

## ⚠️ Limitations & Future Work

Acknowledging what a dataset *cannot* answer is as important as what it can. This analysis has three honest constraints:

**1. No product-level attribution**
The advertising dataset provides campaign-level metrics but contains no product codes. It is not possible to determine which specific product a campaign drove — the two datasets share no product key.

**2. Mismatched time coverage**
The sales dataset covers December 2010 – December 2011 (full year). The ad dataset covers only April–June. The analysis is valid within that window but cannot speak to seasonal performance outside it.

**3. Correlation, not causation**
Revenue and ad spend are joined on date — this establishes correlation, not a direct causal link. External factors (seasonality, promotions, organic traffic) are not controlled for.

**Datasets that would strengthen future analysis:**
- Daily weather data — to test whether sales dips correlate with external conditions
- Competitor ad spend benchmarks — to contextualise the $0.27 CPA against industry norms
- Product-level transaction metadata — to enable campaign-to-SKU attribution

---

## 📄 Documentation

| Document | Purpose |
|---|---|
| [`docs/Privacy_Impact_Assessment.pdf`](docs/Privacy_Impact_Assessment.pdf) | Full privacy analysis — PI identification, SQL privacy aggregation architecture, legislative alignment, risk register |
| [`docs/DataAnalysis_Worksheet.pdf`](docs/DataAnalysis_Worksheet.pdf) | Project worksheet — SMART business questions, data flow, cleaning log, key statistics, recommendations |

---

## 🚀 How to Reproduce This Project

**Tools required:**
- SQL Server Express + SSMS *(free — Microsoft)*
- Power BI Desktop *(free — Microsoft)*
- The two CSV files from Kaggle *(links in Dataset section above)*

```sql
-- 1. Create database
CREATE DATABASE MarketingProject;
USE MarketingProject;

-- 2. Load CSVs via SSMS Import Wizard
--    Right-click database → Tasks → Import Flat File
--    Creates: raw_ads, raw_sales

-- 3. Run marketing_analysis.sql (this repo)
--    Produces: raw_ads_clean, raw_sales_clean,
--              daily_sales_apr_jun, sales_ads_joined_focus

-- 4. Open Power BI → Get Data → SQL Server
--    Connect to: MarketingProject database
--    Load: sales_ads_joined_focus
```

---

## 📂 Repository Structure

```
Data-Analysis-Marketing/
│
├── README.md                            ← Executive summary (you are here)
├── marketing_analysis.sql               ← Full SQL pipeline + privacy aggregation layer
│
├── docs/
│   ├── Privacy_Impact_Assessment.pdf    ← Data governance document
│   └── DataAnalysis_Worksheet.pdf       ← Data analysis methodology worksheet
│
└── sample_dashboards/
    ├── dashboard_overview.png           ← Full dashboard screenshot
    ├── roas_trend.png                   ← ROAS trend chart
    └── cpa_trend.png                    ← CPA trend chart
```

---

## 🤝 Let's Connect

I am a data analyst with hands-on experience in SQL, Power BI, and end-to-end analytics pipelines. I am actively seeking **Data Analyst** or **Business Intelligence** roles where SQL, Power BI, and business-first thinking can drive measurable commercial outcomes.

- 📧 [lucascamargo@outlook.com.au](mailto:lucascamargo@outlook.com.au)
- 🔗 [linkedin.com/in/lucasgcamargo](https://www.linkedin.com/in/lucasgcamargo/)

---

## © Copyright

© 2026 Lucas Camargo. All Rights Reserved.
Raw datasets are publicly available on Kaggle under their respective licences. All SQL transformations, DAX measures, analytical frameworks, and documentation are original work by the author.
