-- =====================================================
-- CIOS Phase 2 - Case 01
-- Detection Views Implementation
-- Dead Stock Containment Crisis
-- =====================================================

-- 1) Dead Stock Aging 120+
CREATE OR REPLACE VIEW vw_dead_stock_aging_120 AS
SELECT
    i.date_id,
    i.store_id,
    i.sku_id,
    i.on_hand_cost_amt,
    (d.full_date - ls.full_date) AS days_since_last_sale,
    CASE
        WHEN (d.full_date - ls.full_date) <= 30 THEN '0-30'
        WHEN (d.full_date - ls.full_date) <= 90 THEN '31-90'
        WHEN (d.full_date - ls.full_date) <= 120 THEN '91-120'
        ELSE '121+'
    END AS age_bucket
FROM fact_inventory_snapshot_daily i
JOIN dim_date d ON i.date_id = d.date_id
LEFT JOIN dim_date ls ON i.last_sold_date_id = ls.date_id;


-- 2) Velocity Decay Index
CREATE OR REPLACE VIEW vw_velocity_decay_index AS
WITH sales_weekly AS (
    SELECT
        d.week_id,
        f.store_id,
        f.sku_id,
        SUM(f.qty_sold) AS qty_sold
    FROM fact_sales_txn f
    JOIN dim_date d ON f.date_id = d.date_id
    GROUP BY d.week_id, f.store_id, f.sku_id
),
rolling_calc AS (
    SELECT
        s1.week_id,
        s1.store_id,
        s1.sku_id,
        SUM(CASE WHEN s2.week_id BETWEEN s1.week_id - 3 AND s1.week_id
                 THEN s2.qty_sold ELSE 0 END) AS velocity_4w,
        SUM(CASE WHEN s2.week_id BETWEEN s1.week_id - 11 AND s1.week_id
                 THEN s2.qty_sold ELSE 0 END) AS velocity_12w
    FROM sales_weekly s1
    JOIN sales_weekly s2
      ON s1.store_id = s2.store_id
     AND s1.sku_id = s2.sku_id
    GROUP BY s1.week_id, s1.store_id, s1.sku_id
)
SELECT
    week_id,
    store_id,
    sku_id,
    velocity_4w,
    velocity_12w,
    CASE
        WHEN velocity_12w = 0 THEN NULL
        ELSE velocity_4w::decimal / velocity_12w
    END AS decay_ratio
FROM rolling_calc;


-- 3) Capital Freeze Risk Score
CREATE OR REPLACE VIEW vw_capital_freeze_risk_score AS
SELECT
    g.month_id,
    g.store_id,
    g.category_id,
    SUM(CASE WHEN a.age_bucket = '121+' THEN a.on_hand_cost_amt ELSE 0 END)
        / NULLIF(SUM(a.on_hand_cost_amt),0) AS dead_stock_pct,
    g.gap_pct AS inv_sales_gap_pct,
    AVG(CASE WHEN v.decay_ratio < 0.5 THEN 1 ELSE 0 END) AS velocity_decay_pct,
    (
        (g.gap_pct * 0.4) +
        (AVG(CASE WHEN v.de
