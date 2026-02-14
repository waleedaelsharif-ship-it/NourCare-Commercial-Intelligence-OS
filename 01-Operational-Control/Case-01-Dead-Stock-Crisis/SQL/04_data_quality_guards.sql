-- =====================================================
-- CIOS Phase 2 - Case 01
-- Data Quality & Structural Guards
-- Dead Stock Containment Crisis
-- =====================================================

-- 1) Prevent duplicate daily inventory snapshots
ALTER TABLE fact_inventory_snapshot_daily
ADD CONSTRAINT uq_inventory_snapshot_unique
UNIQUE (date_id, store_id, sku_id, snapshot_run_id);


-- 2) Prevent negative inventory quantities
ALTER TABLE fact_inventory_snapshot_daily
ADD CONSTRAINT chk_inventory_non_negative
CHECK (
    on_hand_qty >= 0
    AND available_qty >= 0
    AND reserved_qty >= 0
    AND in_transit_qty >= 0
);


-- 3) Prevent negative sales quantity unless marked as return
ALTER TABLE fact_sales_txn
ADD CONSTRAINT chk_sales_qty_valid
CHECK (
    (qty_sold >= 0)
    OR (is_return = TRUE AND return_qty IS NOT NULL)
);


-- 4) Enforce valid reorder window
ALTER TABLE fact_reorder_policy
ADD CONSTRAINT chk_reorder_policy_window
CHECK (
    effective_end_date_id IS NULL
    OR effective_end_date_id >= effective_start_date_id
);


-- 5) Prevent max_qty < min_qty
ALTER TABLE fact_reorder_policy
ADD CONSTRAINT chk_reorder_min_max
CHECK (
    max_qty >= min_qty
);


-- 6) Enforce forecast non-negative
ALTER TABLE fact_forecast_weekly
ADD CONSTRAINT chk_forecast_non_negative
CHECK (
    forecast_qty >= 0
);


-- 7) Prevent duplicate forecast entries per week/store/sku
ALTER TABLE fact_forecast_weekly
ADD CONSTRAINT uq_forecast_unique
UNIQUE (fiscal_week_id, store_id, sku_id);


-- 8) Enforce PO quantity positive
ALTER
