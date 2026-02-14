-- =====================================================
-- CIOS Phase 2 - Case 01
-- Governance Trigger View
-- Dead Stock Containment Crisis
-- =====================================================

CREATE OR REPLACE VIEW vw_trigger_inventory_divergence_veto AS
WITH risk_base AS (
    SELECT
        r.month_id,
        r.store_id,
        r.category_id,
        r.inv_sales_gap_pct,
        r.dead_stock_pct,
        LAG(r.inv_sales_gap_pct) OVER (
            PARTITION BY r.store_id, r.category_id
            ORDER BY r.month_id
        ) AS prev_gap_pct
    FROM vw_capital_freeze_risk_score r
)
SELECT
    month_id,
    store_id,
    category_id,
    inv_sales_gap_pct AS gap_pct,
    dead_stock_pct,
    CASE
        WHEN inv_sales_gap_pct >= 0.05
             AND prev_gap_pct >= 0.05
             AND dead_stock_pct >= 0.08
        THEN 1
        ELSE 0
    END AS trigger_flag,
    CASE
        WHEN inv_sales_gap_pct >= 0.08
             AND dead_stock_pct >= 0.12
        THEN 'Red'
        WHEN inv_sales_gap_pct >= 0.05
             AND dead_stock_pct >= 0.08
        THEN 'Yellow'
        ELSE 'None'
    END AS trigger_level,
    CASE
        WHEN inv_sales_gap_pct >= 0.05
             AND prev_gap_pct >= 0.05
             AND dead_stock_pct >= 0.08
        THEN 'Freeze PO / Reduce Max / Liquidate'
        ELSE NULL
    END AS required_action,
    (
        SELECT role_owner_id
        FROM dim_role_owner
        WHERE role_name = 'Head of Commercial Intelligence'
        LIMIT 1
    ) AS veto_owner_role_id
FROM risk_base;
