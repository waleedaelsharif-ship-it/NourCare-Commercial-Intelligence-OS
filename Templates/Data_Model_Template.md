# Data Model Template — Deep Data Cases

---

## Fact Tables

### fact_sales
- date
- branch_id
- sku_id
- quantity
- net_sales
- cogs
- gross_margin

### fact_inventory
- date
- branch_id
- sku_id
- on_hand_qty
- on_hand_value
- aging_bucket
- dead_stock_flag

---

## Dimension Tables

### dim_sku
- sku_id
- category
- subcategory
- brand
- pack_size
- cost_band
- price_band

### dim_branch
- branch_id
- city
- region
- store_type

### dim_supplier
- supplier_id
- supplier_name
- payment_terms
- dependency_flag

### dim_date
- date
- month
- quarter
- season

---

## Core Analytical Queries

1. Inventory vs Sales Divergence
2. Dead Stock Aging Analysis
3. Inventory Turnover Calculation
4. ROIC Proxy Calculation
5. Capital Exposure Simulation
