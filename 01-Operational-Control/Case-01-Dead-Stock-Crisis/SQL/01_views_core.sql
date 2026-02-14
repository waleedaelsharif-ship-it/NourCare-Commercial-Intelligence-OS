-- =====================================================
-- CIOS Phase 2 - Case 01
-- Core Views Implementation
-- Dead Stock Containment Crisis
-- =====================================================

-- 1) Monthly Sales Aggregation
CREATE OR REPLACE VIEW vw_monthly_sales_cost AS
SELECT
    d.month_id,
    s.store_id,
    sk.sku_id,
    SUM(f.net_sales_amt) AS net_sales_amt,
    SUM(f.cogs_amt) AS cogs_amt,
    SUM(f.gross_margin_amt) AS gross_margin_amt,
    SUM(f.qty_sold) AS qty_sold
FROM fact_sales_txn f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_store s ON f.store_id = s.store_id
JOIN dim_sku sk ON f.sku_id = sk.sku_id
GROUP BY
    d.month_id,
    s.store_id,
    sk.sku_id;


-- 2) Monthly Inventory Aggregation
CREATE OR REPLACE VIEW vw_monthly_inventory_cost AS
SELECT
    d.month_id,
    i.store_id,
    i.sku_id,
    AVG(i.on_hand_cost_amt) AS avg_on_hand_cost_amt,
    MAX(CASE WHEN d.is_month_end = TRUE THEN i.on_hand_cost_amt END) 
        AS end_of_month_on_hand_cost_amt,
    AVG(i.on_hand_qty) AS avg_on_hand_qty
FROM fact_inventory_snapshot_daily i
JOIN dim_date d ON i.date_id = d.date_id
GROUP BY
    d.month_id,
    i.store_id,
    i.sku_id;
