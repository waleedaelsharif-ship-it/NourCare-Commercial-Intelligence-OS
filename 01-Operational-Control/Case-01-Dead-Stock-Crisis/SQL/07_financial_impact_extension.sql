-- =====================================================
-- CIOS Phase 2 - Case 01
-- Financial Impact Extension
-- Dead Stock Containment Crisis
-- =====================================================

WITH base_simulation AS (
    SELECT
        1 AS store_id,
        10 AS category_id,
        100000 AS total_inventory_cost,
        23000 AS total_capital_release,
        0.62 AS projected_service_level,
        0.28 AS gross_margin_rate,              -- assumed GM%
        80000 AS annual_sales_value             -- simulated annual sales
),

financial_calc AS (
    SELECT
        store_id,
        category_id,
        total_inventory_cost,
        total_capital_release,
        projected_service_level,
        gross_margin_rate,
        annual_sales_value,

        -- 1) Cash-to-Stock Compression Ratio
        total_capital_release / NULLIF(total_inventory_cost,0)
            AS compression_ratio,

        -- 2) Monthly sales estimate
        annual_sales_value / 12.0 AS monthly_sales,

        -- 3) Estimated monthly gross profit
        (annual_sales_value / 12.0) * gross_margin_rate
            AS monthly_gross_profit,

        -- 4) Payback period in months (capital release impact)
        CASE
            WHEN ((annual_sales_value / 12.0) * gross_margin_rate) = 0
            THEN NULL
            ELSE total_capital_release /
                 ((annual_sales_value / 12.0) * gross_margin_rate)
        END AS payback_period_months

    FROM base_simulation
)

SELECT *
FROM financial_calc;
