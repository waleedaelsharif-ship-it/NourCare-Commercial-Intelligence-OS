# CIOS Phase 2 — Case 01 (Dead Stock Containment Crisis)
## Views + Trigger (Schema Only)

---

## CORE VIEWS (3)

### 1) vw_monthly_sales_cost
**Grain**
- month_id, store_id, sku_id
**Columns**
- month_id
- store_id
- sku_id
- net_sales_amt
- cogs_amt
- gross_margin_amt
- qty_sold

---

### 2) vw_monthly_inventory_cost
**Grain**
- month_id, store_id, sku_id
**Columns**
- month_id
- store_id
- sku_id
- avg_on_hand_cost_amt
- end_of_month_on_hand_cost_amt
- avg_on_hand_qty

---

### 3) vw_inventory_growth_vs_sales_growth
**Grain**
- month_id, store_id, category_id   (optionally supplier_id)
**Columns**
- month_id
- store_id
- category_id
- supplier_id (nullable)
- inventory_growth_pct
- sales_growth_pct
- gap_pct                                   -- inventory_growth_pct - sales_growth_pct

---

## MANDATORY DETECTION VIEWS (3)

### 4) vw_dead_stock_aging_120
**Grain**
- date_id, store_id, sku_id
**Columns**
- date_id
- store_id
- sku_id
- on_hand_cost_amt
- days_since_last_sale
- age_bucket                                -- 0-30 / 31-90 / 91-120 / 121+

---

### 5) vw_velocity_decay_index
**Grain**
- week_id, store_id, sku_id
**Columns**
- week_id
- store_id
- sku_id
- velocity_4w                               -- sales qty over last 4 weeks
- velocity_12w                              -- sales qty over last 12 weeks
- decay_ratio                               -- velocity_4w / NULLIF(velocity_12w,0)

---

### 6) vw_capital_freeze_risk_score
**Grain**
- month_id, store_id, category_id
**Columns**
- month_id
- store_id
- category_id
- dead_stock_pct                            -- cost(121+ bucket)/total inv cost
- inv_sales_gap_pct                         -- from vw_inventory_growth_vs_sales_growth.gap_pct
- velocity_decay_pct                        -- % SKUs with decay_ratio below threshold
- risk_score                                -- 0–100

---

## GOVERNANCE LOCK (Trigger View — Final)

### 7) vw_trigger_inventory_divergence_veto
**Grain**
- month_id, store_id, category_id

**Trigger Condition (Schema Spec)**
- (inventory_growth_pct - sales_growth_pct) >= 0.05
- for two consecutive months
- AND dead_stock_pct >= X                   -- default: 0.08

**Output Columns**
- month_id
- store_id
- category_id
- inventory_growth_pct
- sales_growth_pct
- gap_pct
- dead_stock_pct
- trigger_flag                              -- 0/1
- trigger_level                             -- Yellow / Red
- required_action                           -- Freeze PO / Reduce Max / Liquidate
- veto_owner_role_id                        -- Head of Commercial Intelligence (dim_role_owner)
