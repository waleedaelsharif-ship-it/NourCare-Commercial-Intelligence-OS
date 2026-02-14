-- =====================================================
-- CIOS Phase 2 - Case 01
-- Real Data Capital Release Model
-- Dead Stock Containment Crisis
-- =====================================================

WITH inventory_base AS (
    SELECT
        r.month_id,
        r.store_id,
        r.category_id,
        r.dead_stock_pct,
        r.inv_sales_gap_pct,
        SUM(m.end_of_month_on_hand_cost_amt) AS total_inventory_cost
    FROM vw_capital_freeze_risk_score r
    JOIN vw_monthly_inventory_cost m
      ON r.month_id = m.month_id
     AND r.store_id = m.store_id
    JOIN dim_sku sk
      ON sk.sku_id = m.sku_id
     AND sk.category_id = r.category_id
    GROUP BY
        r.month_id,
        r.store_id,
        r.category_id,
        r.dead_stock_pct,
        r.inv_sales_gap_pct
),

capital_calc AS (
    SELECT
        month_id,
        store_id,
        category_id,
        total_inventory_cost,
        dead_stock_pct,
        inv_sales_gap_pct,

        -- Real dead stock capital
        total_inventory_cost * dead_stock_pct AS frozen_capital,

        -- Simulated 15% policy tightening on affected categories
        total_inventory_cost * 0.15 AS reorder_capital_reduction,

        -- Total release potential
        (total_inventory_cost * dead_stock_pct) +
        (total_inventory_cost * 0.15) AS total_capital_release

    FROM inventory_base
    WHERE inv_sales_gap_pct >= 0.05
)

SELECT *
FROM capital_calc;
