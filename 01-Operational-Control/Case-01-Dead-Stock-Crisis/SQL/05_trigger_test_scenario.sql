-- =====================================================
-- CIOS Phase 2 - Case 01
-- Trigger Logical Test Scenario
-- Dead Stock Containment Crisis
-- =====================================================

-- Simulated Monthly Risk Input
WITH simulated_data AS (
    SELECT
        202401 AS month_id,
        1 AS store_id,
        10 AS category_id,
        0.06 AS inv_sales_gap_pct,
        0.09 AS dead_stock_pct
    UNION ALL
    SELECT
        202402,
        1,
        10,
        0.07,
        0.10
)

-- Simulate LAG behavior
, lagged AS (
    SELECT
        month_id,
        store_id,
        category_id,
        inv_sales_gap_pct,
        dead_stock_pct,
        LAG(inv_sales_gap_pct) OVER (
            PARTITION BY store_id, category_id
            ORDER BY month_id
        ) AS prev_gap_pct
    FROM simulated_data
)

SELECT
    month_id,
    store_id,
    category_id,
    inv_sales_gap_pct,
    dead_stock_pct,
    prev_gap_pct,
    CASE
        WHEN inv_sales_gap_pct >= 0.05
             AND prev_gap_pct >= 0.05
             AND dead_stock_pct >= 0.08
        THEN 1
        ELSE 0
    END AS expected_trigger_flag
FROM lagged;
