-- ============================================================
-- SUPPLY CHAIN PERFORMANCE ANALYSIS
-- Author: Maximus Morales | Role: Logistics Analyst
-- Tool: SQLite Online (sqliteonline.com)
-- Table: supply_chain | All columns stored as TEXT
-- Usage: Copy/paste each query block individually
-- ============================================================


-- ============================================================
-- SECTION 1: REVENUE & SALES OVERVIEW
-- ============================================================

-- Q1.1: Total revenue, units sold, and avg price by product category
SELECT
    "Product type"                                                          AS product_type,
    COUNT("SKU")                                                            AS num_skus,
    SUM(CAST("Number of products sold" AS INTEGER))                         AS total_units_sold,
    ROUND(SUM(CAST("Revenue generated" AS REAL)), 2)                        AS total_revenue,
    ROUND(AVG(CAST("Price" AS REAL)), 2)                                    AS avg_price,
    ROUND(SUM(CAST("Revenue generated" AS REAL)) /
          SUM(CAST("Number of products sold" AS INTEGER)), 2)               AS revenue_per_unit
FROM supply_chain
GROUP BY "Product type"
ORDER BY total_revenue DESC;


-- Q1.2: Top 10 SKUs by revenue generated
SELECT
    "SKU"                                               AS sku,
    "Product type"                                      AS product_type,
    ROUND(CAST("Price" AS REAL), 2)                     AS price,
    CAST("Number of products sold" AS INTEGER)          AS units_sold,
    ROUND(CAST("Revenue generated" AS REAL), 2)         AS revenue,
    "Inspection results"                                AS inspection_result,
    ROUND(CAST("Defect rates" AS REAL), 2)              AS defect_rate
FROM supply_chain
ORDER BY CAST("Revenue generated" AS REAL) DESC
LIMIT 10;


-- Q1.3: Cumulative revenue contribution by SKU
-- (Window function — shows which SKUs drive 80% of revenue)
WITH ranked_skus AS (
    SELECT
        "SKU"                                                               AS sku,
        "Product type"                                                      AS product_type,
        ROUND(CAST("Revenue generated" AS REAL), 2)                         AS revenue,
        SUM(CAST("Revenue generated" AS REAL)) OVER ()                      AS total_revenue,
        SUM(CAST("Revenue generated" AS REAL))
            OVER (ORDER BY CAST("Revenue generated" AS REAL) DESC)          AS running_total,
        RANK() OVER (ORDER BY CAST("Revenue generated" AS REAL) DESC)       AS revenue_rank
    FROM supply_chain
)
SELECT
    sku,
    product_type,
    revenue,
    revenue_rank,
    ROUND((running_total / total_revenue) * 100, 1)     AS cumulative_pct_of_revenue
FROM ranked_skus
ORDER BY revenue_rank
LIMIT 20;


-- Q1.4: Inventory health — overstock vs. stockout risk
SELECT
    "SKU"                                                   AS sku,
    "Product type"                                          AS product_type,
    "Supplier name"                                         AS supplier,
    CAST("Stock levels" AS INTEGER)                         AS stock_levels,
    CAST("Number of products sold" AS INTEGER)              AS units_sold,
    ROUND(
        CAST("Stock levels" AS REAL) /
        NULLIF(CAST("Number of products sold" AS REAL), 0),
    3)                                                      AS stock_to_sales_ratio,
    CASE
        WHEN CAST("Stock levels" AS REAL) /
             NULLIF(CAST("Number of products sold" AS REAL), 0) > 0.20
             THEN 'Overstock Risk'
        WHEN CAST("Stock levels" AS REAL) /
             NULLIF(CAST("Number of products sold" AS REAL), 0) < 0.05
             THEN 'Stockout Risk'
        ELSE 'Healthy'
    END                                                     AS inventory_status
FROM supply_chain
ORDER BY stock_to_sales_ratio DESC;


-- ============================================================
-- SECTION 2: SUPPLIER QUALITY & PERFORMANCE SCORECARD
-- ============================================================

-- Q2.1: Supplier scorecard — defect rate, lead time, pass/fail rate
SELECT
    "Supplier name"                                                             AS supplier,
    COUNT("SKU")                                                                AS total_skus,
    ROUND(AVG(CAST("Defect rates" AS REAL)), 2)                                 AS avg_defect_rate,
    ROUND(AVG(CAST("Lead time" AS REAL)), 1)                                    AS avg_lead_time_days,
    ROUND(AVG(CAST("Manufacturing costs" AS REAL)), 2)                          AS avg_mfg_cost,
    SUM(CASE WHEN "Inspection results" = 'Pass'    THEN 1 ELSE 0 END)           AS pass_count,
    SUM(CASE WHEN "Inspection results" = 'Fail'    THEN 1 ELSE 0 END)           AS fail_count,
    SUM(CASE WHEN "Inspection results" = 'Pending' THEN 1 ELSE 0 END)           AS pending_count,
    ROUND(
        100.0 * SUM(CASE WHEN "Inspection results" = 'Pass' THEN 1 ELSE 0 END)
        / COUNT("SKU"), 1
    )                                                                           AS pass_rate_pct
FROM supply_chain
GROUP BY "Supplier name"
ORDER BY avg_defect_rate DESC;


-- Q2.2: Defect rate by supplier AND product type
SELECT
    "Supplier name"                                     AS supplier,
    "Product type"                                      AS product_type,
    COUNT("SKU")                                        AS skus,
    ROUND(AVG(CAST("Defect rates" AS REAL)), 2)         AS avg_defect_rate,
    ROUND(MIN(CAST("Defect rates" AS REAL)), 2)         AS min_defect_rate,
    ROUND(MAX(CAST("Defect rates" AS REAL)), 2)         AS max_defect_rate
FROM supply_chain
GROUP BY "Supplier name", "Product type"
ORDER BY "Supplier name", avg_defect_rate DESC;


-- Q2.3: High-risk SKUs — failing inspection AND above-average defect rate
SELECT
    "SKU"                                                   AS sku,
    "Product type"                                          AS product_type,
    "Supplier name"                                         AS supplier,
    "Location"                                              AS location,
    ROUND(CAST("Defect rates" AS REAL), 2)                  AS defect_rate,
    "Inspection results"                                    AS inspection_result,
    ROUND(CAST("Manufacturing costs" AS REAL), 2)           AS manufacturing_cost,
    ROUND(CAST("Revenue generated" AS REAL), 2)             AS revenue,
    ROUND(
        CAST("Revenue generated" AS REAL)
        - CAST("Manufacturing costs" AS REAL)
        - CAST("Shipping costs" AS REAL)
        - CAST("Costs" AS REAL),
    2)                                                      AS est_margin
FROM supply_chain
WHERE "Inspection results" = 'Fail'
  AND CAST("Defect rates" AS REAL) > (
      SELECT AVG(CAST("Defect rates" AS REAL)) FROM supply_chain
  )
ORDER BY CAST("Defect rates" AS REAL) DESC;


-- Q2.4: Each supplier's lead time vs. the company average
-- (Window function benchmarking)
WITH supplier_avg AS (
    SELECT
        "Supplier name"                                         AS supplier,
        ROUND(AVG(CAST("Lead time" AS REAL)), 1)                AS supplier_avg_lead_time,
        ROUND(AVG(AVG(CAST("Lead time" AS REAL))) OVER (), 1)   AS overall_avg_lead_time
    FROM supply_chain
    GROUP BY "Supplier name"
)
SELECT
    supplier,
    supplier_avg_lead_time,
    overall_avg_lead_time,
    ROUND(supplier_avg_lead_time - overall_avg_lead_time, 1)    AS days_vs_average,
    CASE
        WHEN supplier_avg_lead_time > overall_avg_lead_time THEN 'Slower Than Average'
        WHEN supplier_avg_lead_time < overall_avg_lead_time THEN 'Faster Than Average'
        ELSE 'At Average'
    END                                                         AS lead_time_flag
FROM supplier_avg
ORDER BY supplier_avg_lead_time DESC;


-- ============================================================
-- SECTION 3: SHIPPING & LOGISTICS COST ANALYSIS
-- ============================================================

-- Q3.1: Cost efficiency by transportation mode
SELECT
    "Transportation modes"                                                          AS transport_mode,
    COUNT("SKU")                                                                    AS shipments,
    ROUND(AVG(CAST("Shipping costs" AS REAL)), 2)                                   AS avg_shipping_cost,
    ROUND(AVG(CAST("Costs" AS REAL)), 2)                                            AS avg_logistics_cost,
    ROUND(AVG(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL)), 2)           AS avg_total_cost,
    ROUND(AVG(CAST("Shipping times" AS REAL)), 1)                                   AS avg_shipping_days,
    ROUND(SUM(CAST("Revenue generated" AS REAL)), 2)                                AS total_revenue,
    ROUND(
        SUM(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL))
        / SUM(CAST("Revenue generated" AS REAL)) * 100,
    2)                                                                              AS cost_pct_of_revenue
FROM supply_chain
GROUP BY "Transportation modes"
ORDER BY cost_pct_of_revenue DESC;


-- Q3.2: Carrier performance — cost, speed, and defect rates
SELECT
    "Shipping carriers"                                         AS carrier,
    COUNT("SKU")                                                AS shipments,
    ROUND(AVG(CAST("Shipping costs" AS REAL)), 2)               AS avg_shipping_cost,
    ROUND(AVG(CAST("Shipping times" AS REAL)), 1)               AS avg_days_to_ship,
    ROUND(SUM(CAST("Revenue generated" AS REAL)), 2)            AS total_revenue_serviced,
    ROUND(AVG(CAST("Defect rates" AS REAL)), 2)                 AS avg_defect_rate
FROM supply_chain
GROUP BY "Shipping carriers"
ORDER BY avg_shipping_cost DESC;


-- Q3.3: Route profitability — worst cost-to-revenue ratios
SELECT
    "Routes"                                                                        AS route,
    "Transportation modes"                                                          AS transport_mode,
    COUNT("SKU")                                                                    AS shipments,
    ROUND(SUM(CAST("Revenue generated" AS REAL)), 2)                                AS total_revenue,
    ROUND(SUM(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL)), 2)           AS total_logistics_cost,
    ROUND(
        SUM(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL))
        / SUM(CAST("Revenue generated" AS REAL)) * 100,
    2)                                                                              AS logistics_cost_pct,
    ROUND(AVG(CAST("Shipping times" AS REAL)), 1)                                   AS avg_shipping_days
FROM supply_chain
GROUP BY "Routes", "Transportation modes"
ORDER BY logistics_cost_pct DESC;


-- Q3.4: Shipping cost by supplier location
SELECT
    "Location"                                                                      AS location,
    COUNT("SKU")                                                                    AS skus,
    ROUND(AVG(CAST("Shipping costs" AS REAL)), 2)                                   AS avg_shipping_cost,
    ROUND(AVG(CAST("Costs" AS REAL)), 2)                                            AS avg_logistics_cost,
    ROUND(AVG(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL)), 2)           AS avg_total_cost,
    ROUND(AVG(CAST("Lead time" AS REAL)), 1)                                        AS avg_lead_time
FROM supply_chain
GROUP BY "Location"
ORDER BY avg_total_cost DESC;


-- ============================================================
-- SECTION 4: MARGIN ANALYSIS
-- ============================================================

-- Q4.1: Estimated gross margin per SKU (20 least profitable)
SELECT
    "SKU"                                                                           AS sku,
    "Product type"                                                                  AS product_type,
    "Supplier name"                                                                 AS supplier,
    ROUND(CAST("Revenue generated" AS REAL), 2)                                     AS revenue,
    ROUND(CAST("Manufacturing costs" AS REAL), 2)                                   AS mfg_cost,
    ROUND(CAST("Shipping costs" AS REAL), 2)                                        AS shipping_cost,
    ROUND(CAST("Costs" AS REAL), 2)                                                 AS logistics_cost,
    ROUND(
        CAST("Manufacturing costs" AS REAL)
        + CAST("Shipping costs" AS REAL)
        + CAST("Costs" AS REAL),
    2)                                                                              AS total_cost,
    ROUND(
        CAST("Revenue generated" AS REAL)
        - CAST("Manufacturing costs" AS REAL)
        - CAST("Shipping costs" AS REAL)
        - CAST("Costs" AS REAL),
    2)                                                                              AS est_gross_margin,
    ROUND(
        (CAST("Revenue generated" AS REAL)
         - CAST("Manufacturing costs" AS REAL)
         - CAST("Shipping costs" AS REAL)
         - CAST("Costs" AS REAL))
        / NULLIF(CAST("Revenue generated" AS REAL), 0) * 100,
    1)                                                                              AS margin_pct
FROM supply_chain
ORDER BY margin_pct ASC
LIMIT 20;


-- Q4.2: Average margin by product category
SELECT
    "Product type"                                                                  AS product_type,
    ROUND(AVG(CAST("Revenue generated" AS REAL)), 2)                                AS avg_revenue,
    ROUND(AVG(
        CAST("Manufacturing costs" AS REAL)
        + CAST("Shipping costs" AS REAL)
        + CAST("Costs" AS REAL)
    ), 2)                                                                           AS avg_total_cost,
    ROUND(AVG(
        CAST("Revenue generated" AS REAL)
        - CAST("Manufacturing costs" AS REAL)
        - CAST("Shipping costs" AS REAL)
        - CAST("Costs" AS REAL)
    ), 2)                                                                           AS avg_gross_margin,
    ROUND(AVG(
        (CAST("Revenue generated" AS REAL)
         - CAST("Manufacturing costs" AS REAL)
         - CAST("Shipping costs" AS REAL)
         - CAST("Costs" AS REAL))
        / NULLIF(CAST("Revenue generated" AS REAL), 0)
    ) * 100, 1)                                                                     AS avg_margin_pct
FROM supply_chain
GROUP BY "Product type"
ORDER BY avg_margin_pct DESC;


-- Q4.3: Problem SKU report — poor margin + failing QC
SELECT
    "SKU"                                                                           AS sku,
    "Product type"                                                                  AS product_type,
    "Supplier name"                                                                 AS supplier,
    "Location"                                                                      AS location,
    ROUND(CAST("Revenue generated" AS REAL), 2)                                     AS revenue,
    ROUND(
        CAST("Manufacturing costs" AS REAL)
        + CAST("Shipping costs" AS REAL)
        + CAST("Costs" AS REAL),
    2)                                                                              AS total_cost,
    ROUND(
        CAST("Revenue generated" AS REAL)
        - CAST("Manufacturing costs" AS REAL)
        - CAST("Shipping costs" AS REAL)
        - CAST("Costs" AS REAL),
    2)                                                                              AS est_margin,
    ROUND(
        (CAST("Revenue generated" AS REAL)
         - CAST("Manufacturing costs" AS REAL)
         - CAST("Shipping costs" AS REAL)
         - CAST("Costs" AS REAL))
        / NULLIF(CAST("Revenue generated" AS REAL), 0) * 100,
    1)                                                                              AS margin_pct,
    "Inspection results"                                                            AS inspection_result,
    ROUND(CAST("Defect rates" AS REAL), 2)                                          AS defect_rate,
    CAST("Lead time" AS INTEGER)                                                    AS lead_time
FROM supply_chain
WHERE "Inspection results" IN ('Fail', 'Pending')
  AND CAST("Defect rates" AS REAL) > 2.0
  AND (
      CAST("Revenue generated" AS REAL)
      - CAST("Manufacturing costs" AS REAL)
      - CAST("Shipping costs" AS REAL)
      - CAST("Costs" AS REAL)
  ) / NULLIF(CAST("Revenue generated" AS REAL), 0) < 0.90
ORDER BY est_margin ASC;


-- ============================================================
-- SECTION 5: EXECUTIVE SUMMARY KPIs
-- (Single query — headline KPIs for the dashboard)
-- ============================================================

SELECT
    COUNT("SKU")                                                                    AS total_skus,
    ROUND(SUM(CAST("Revenue generated" AS REAL)), 0)                                AS total_revenue,
    ROUND(AVG(CAST("Defect rates" AS REAL)), 2)                                     AS avg_defect_rate,
    ROUND(AVG(CAST("Lead time" AS REAL)), 1)                                        AS avg_lead_time_days,
    ROUND(AVG(CAST("Shipping times" AS REAL)), 1)                                   AS avg_shipping_days,
    ROUND(SUM(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL)), 0)           AS total_logistics_spend,
    ROUND(
        SUM(CAST("Shipping costs" AS REAL) + CAST("Costs" AS REAL))
        / SUM(CAST("Revenue generated" AS REAL)) * 100,
    1)                                                                              AS logistics_cost_pct_revenue,
    SUM(CASE WHEN "Inspection results" = 'Pass'    THEN 1 ELSE 0 END)               AS total_pass,
    SUM(CASE WHEN "Inspection results" = 'Fail'    THEN 1 ELSE 0 END)               AS total_fail,
    SUM(CASE WHEN "Inspection results" = 'Pending' THEN 1 ELSE 0 END)               AS total_pending,
    ROUND(
        100.0 * SUM(CASE WHEN "Inspection results" = 'Fail' THEN 1 ELSE 0 END)
        / COUNT("SKU"),
    1)                                                                              AS fail_rate_pct
FROM supply_chain;
