-- =====================================================
-- CIOS Phase 2 - Case 01
-- Capital Release Simulation Model
-- Dead Stock Containment Crisis
-- =====================================================

-- Simulated Inventory & Policy Data
WITH simulated_inventory AS (
    SELECT
        1 AS store_id,
        10 AS category_id,
        100000 AS total_inventory_cost,
        18000 AS dead_stock_cost_121_plus,
        0.65 AS avg_service_level
),

simulated_reorder_policy AS (
    SELECT
        1 AS store_id,
        10 AS category_id,
        20000 AS max_stock_value,
        15000 AS adjusted_max_stock_value_after_freeze
),

capital_release_calc AS (
    SELECT
        i.store_id,
        i.category_id,
        i.total_inventory_cost,
        i.dead_stock_cost_121_plus,
        p.max_stock_value,
        p.adjusted_max_stock_value_after_freeze,

        -- Capital tied in dead stock
        i.dead_stock_cost_121_plus AS frozen_capital,

        -- Capital reduction from policy tightening
        (p.max_stock_value - p.adjusted_max_stock_value_after_freeze)
            AS reorder_capital_reduction,

        -- Total potential capital release
        (i.dead_stock_cost_121_plus +
         (p.max_stock_value - p.adjusted_max_stock_value_after_freeze))
            AS total_capital_release,

        -- Simulated service level impact
        CASE
            WHEN p.adjusted_max_stock_value_after_freeze < p.max_stock_value
            THEN i.avg_service_level - 0.03
            ELSE i.avg_service_level
        END AS projected_service_level_after_action

    FROM simulated_inventory i
    JOIN simulated_reorder_policy p
      ON i.store_id = p.store_id
     AND i.category_id = p.category_id
)

SELECT *
FROM capital_release_calc;
