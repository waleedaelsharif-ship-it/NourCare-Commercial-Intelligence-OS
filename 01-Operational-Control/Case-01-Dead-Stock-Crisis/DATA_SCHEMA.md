# CIOS Phase 2 — Case 01 (Dead Stock Containment Crisis)
## Deep Data Layer — Dataset Architecture (Final Schema)

---

## FACT TABLES

### 1) fact_sales_txn  (Grain: receipt-line / sku-line per day per store)
**Keys**
- sales_txn_id (PK)
- store_sku_day_key (Surrogate, UNIQUE, indexed)

**Recommended indexed composite key (to prevent duplication during joins)**
- (date_id, store_id, sku_id, receipt_id, sales_txn_id)

**Fields**
- store_sku_day_key
- sales_txn_id
- date_id (FK → dim_date)
- store_id (FK → dim_store)
- sku_id (FK → dim_sku)
- customer_segment_id (FK → dim_customer_segment, nullable)
- channel_id (FK → dim_channel)
- promo_id (FK → dim_promo, nullable)
- price_event_id (FK → dim_price_event, nullable)
- qty_sold
- gross_sales_amt
- discount_amt
- net_sales_amt
- cogs_amt
- gross_margin_amt
- tax_amt (nullable)
- receipt_id (nullable)
- is_return (boolean)
- return_qty (nullable)
- return_amt (nullable)

---

### 2) fact_inventory_snapshot_daily  (Grain: sku per store per day per run)
**Keys**
- inv_snapshot_id (PK)
- snapshot_run_id (FK → dim_snapshot_run, indexed)
- inventory_snapshot_source_id (FK → dim_inventory_snapshot_source, indexed)

**Fields**
- inv_snapshot_id
- snapshot_run_id
- inventory_snapshot_source_id
- date_id (FK → dim_date)
- store_id (FK → dim_store)
- sku_id (FK → dim_sku)
- on_hand_qty
- on_hand_cost_amt
- on_hand_retail_amt (optional)
- available_qty
- reserved_qty
- in_transit_qty
- backorder_qty
- blocked_qty
- expiry_0_30_qty
- expiry_31_90_qty
- expiry_91_180_qty
- expiry_181_plus_qty
- first_received_date_id (FK → dim_date, nullable)
- last_received_date_id (FK → dim_date, nullable)
- last_sold_date_id (FK → dim_date, nullable)
- avg_unit_cost (optional)
- inventory_age_days (optional)

---

### 3) fact_stock_movement  (Grain: ledger line)
**Fields**
- movement_id (PK)
- date_id (FK → dim_date)
- store_id (FK → dim_store)
- sku_id (FK → dim_sku)
- movement_type_id (FK → dim_movement_type)
- ref_doc_id (nullable)
- ref_doc_type (nullable)        -- PO / GRN / ADJ / TRANSFER / WRITE-OFF
- transfer_id (FK → dim_transfer_header, nullable)  -- anti channel-stuffing
- qty_in
- qty_out
- unit_cost
- extended_cost_amt
- reason_code_id (FK → dim_reason_code, nullable)
- counterparty_store_id (FK → dim_store, nullable)

---

### 4) fact_purchase_order_line  (Grain: PO line)
**Fields**
- po_line_id (PK)
- po_id (FK → dim_purchase_order_header)
- date_id (FK → dim_date)                         -- PO created date
- expected_delivery_date_id (FK → dim_date, nullable)
- store_id (FK → dim_store)
- supplier_id (FK → dim_supplier)
- sku_id (FK → dim_sku)
- order_qty
- unit_cost
- gross_po_cost_amt
- discount_amt (nullable)
- rebate_estimated_amt (nullable)
- net_po_cost_amt
- payment_terms_id (FK → dim_payment_terms)
- status_id (FK → dim_po_status)

---

### 5) fact_goods_receipt_line  (Grain: GRN line)
**Fields**
- grn_line_id (PK)
- grn_id (FK → dim_goods_receipt_header)
- date_id (FK → dim_date)                         -- receipt date
- store_id (FK → dim_store)
- supplier_id (FK → dim_supplier)
- sku_id (FK → dim_sku)
- po_line_id (FK → fact_purchase_order_line, nullable)
- received_qty
- unit_cost
- extended_cost_amt
- batch_id (FK → dim_batch, nullable)
- expiry_date_id (FK → dim_date, nullable)

---

### 6) fact_writeoff_expiry  (Grain: writeoff line)
**Fields**
- writeoff_id (PK)
- date_id (FK → dim_date)
- store_id (FK → dim_store)
- sku_id (FK → dim_sku)
- writeoff_type_id (FK → dim_writeoff_type)
- qty
- unit_cost
- extended_cost_amt
- reason_code_id (FK → dim_reason_code, nullable)
- batch_id (FK → dim_batch, nullable)

---

### 7) fact_price_daily  (Grain: sku per day per store/national)
**Fields**
- price_daily_id (PK)
- date_id (FK → dim_date)
- store_id (FK → dim_store, nullable)             -- null = national
- sku_id (FK → dim_sku)
- list_price
- sell_price
- price_ladder_tier_id (FK → dim_price_ladder_tier)
- price_event_id (FK → dim_price_event, nullable)

---

### 8) fact_promo_sku_day  (Grain: sku per day per store/national)
**Fields**
- promo_sku_day_id (PK)
- date_id (FK → dim_date)
- store_id (FK → dim_store, nullable)             -- null = national
- promo_id (FK → dim_promo)
- sku_id (FK → dim_sku)
- promo_mechanic_id (FK → dim_promo_mechanic)
- promo_depth_pct (nullable)
- promo_price (nullable)
- is_featured (boolean)
- is_display (boolean)

---

## CONTROL FACTS (Mandatory)

### 9) fact_forecast_weekly  (Grain: sku per store per fiscal week)
**Fields**
- forecast_id (PK)
- fiscal_week_id (FK → dim_date.fiscal_week_id OR dim_fiscal_week)
- store_id (FK → dim_store)
- sku_id (FK → dim_sku)
- forecast_qty
- forecast_source                              -- system / manual
- created_by_role_owner_id (FK → dim_role_owner)
- created_date_id (FK → dim_date)

---

### 10) fact_reorder_policy  (Grain: sku per store (or national) per effective window)
**Fields**
- policy_id (PK)
- store_id (FK → dim_store, nullable)            -- null = national
- sku_id (FK → dim_sku)
- min_qty
- max_qty
- reorder_point
- safety_stock_qty
- lead_time_days
- service_level_target
- effective_start_date_id (FK → dim_date)
- effective_end_date_id (FK → dim_date, nullable)
- owner_role_id (FK → dim_role_owner)

---

## DIMENSIONS

### dim_date
- date_id (PK)
- full_date
- day
- week_id
- week_start_date
- month_id
- month_start_date
- month_name
- quarter_id
- year
- fiscal_week_id (optional)
- fiscal_month_id (optional)
- is_month_end (boolean)

### dim_fiscal_week (optional, if fiscal_week_id is not in dim_date)
- fiscal_week_id (PK)
- fiscal_week_start_date
- fiscal_week_end_date
- fiscal_month_id
- fiscal_year

### dim_store
- store_id (PK)
- store_code
- store_name
- region_id (FK → dim_region)
- city
- format_id (FK → dim_store_format)
- open_date_id (FK → dim_date, nullable)
- status

### dim_store_format
- format_id (PK)
- format_name

### dim_region
- region_id (PK)
- region_name

### dim_channel
- channel_id (PK)
- channel_name

### dim_sku
- sku_id (PK)
- sku_code
- sku_name
- brand_id (FK → dim_brand)
- manufacturer_id (FK → dim_manufacturer, nullable)
- category_id (FK → dim_category)
- subcategory_id (FK → dim_subcategory)
- segment_id (FK → dim_segment)
- pack_size (nullable)
- uom (nullable)
- is_rx (boolean)
- is_otc (boolean)
- is_chronic (boolean)
- is_seasonal (boolean)
- launch_date_id (FK → dim_date, nullable)
- status

### dim_category
- category_id (PK)
- category_name
- category_role_id (FK → dim_category_role)
- category_manager_id (FK → dim_role_owner)

### dim_subcategory
- subcategory_id (PK)
- subcategory_name
- category_id (FK → dim_category)

### dim_segment
- segment_id (PK)
- segment_name
- subcategory_id (FK → dim_subcategory)

### dim_category_role
- category_role_id (PK)
- role_name                                  -- Destination / Routine / Convenience / Seasonal

### dim_brand
- brand_id (PK)
- brand_name
- supplier_id (FK → dim_supplier, nullable)

### dim_manufacturer
- manufacturer_id (PK)
- manufacturer_name

### dim_supplier
- supplier_id (PK)
- supplier_code
- supplier_name
- supplier_type_id (FK → dim_supplier_type)
- is_key_supplier (boolean)
- payment_terms_id (FK → dim_payment_terms)
- lead_time_days (nullable)

### dim_supplier_type
- supplier_type_id (PK)
- supplier_type_name

### dim_payment_terms
- payment_terms_id (PK)
- terms_name
- days
- early_payment_discount_pct (nullable)

### dim_promo
- promo_id (PK)
- promo_code
- promo_name
- start_date_id (FK → dim_date)
- end_date_id (FK → dim_date)
- funding_type_id (FK → dim_funding_type)
- owner_role_id (FK → dim_role_owner)

### dim_promo_mechanic
- promo_mechanic_id (PK)
- mechanic_name

### dim_funding_type
- funding_type_id (PK)
- funding_type_name

### dim_price_event
- price_event_id (PK)
- event_name
- event_type                                 -- Permanent / Temporary / Markdown / Regulatory
- start_date_id (FK → dim_date)
- end_date_id (FK → dim_date, nullable)
- owner_role_id (FK → dim_role_owner)

### dim_price_ladder_tier
- price_ladder_tier_id (PK)
- tier_name                                  -- KVI / Core / Hero / Premium

### dim_movement_type
- movement_type_id (PK)
- movement_type_name

### dim_reason_code
- reason_code_id (PK)
- reason_code
- reason_desc

### dim_purchase_order_header
- po_id (PK)
- po_number
- created_date_id (FK → dim_date)
- store_id (FK → dim_store)
- supplier_id (FK → dim_supplier)
- buyer_role_id (FK → dim_role_owner)
- status_id (FK → dim_po_status)

### dim_po_status
- status_id (PK)
- status_name

### dim_goods_receipt_header
- grn_id (PK)
- grn_number
- receipt_date_id (FK → dim_date)
- store_id (FK → dim_store)
- supplier_id (FK → dim_supplier)

### dim_batch
- batch_id (PK)
- batch_number (nullable)
- lot_number (nullable)

### dim_writeoff_type
- writeoff_type_id (PK)
- writeoff_type_name                          -- expiry / damage / shrink / recall

### dim_customer_segment (optional)
- customer_segment_id (PK)
- segment_name

### dim_role_owner
- role_owner_id (PK)
- role_name
- org_unit (nullable)

---

## SNAPSHOT PROVENANCE (Mandatory)

### dim_inventory_snapshot_source
- inventory_snapshot_source_id (PK)
- source_system_name                          -- ERP / WMS / POS / Manual Upload
- source_table_or_endpoint (nullable)
- extraction_method                           -- API / ETL / File
- owner_team (nullable)

### dim_snapshot_run
- snapshot_run_id (PK)
- run_ts_utc
- run_ts_local
- pipeline_name
- pipeline_version (nullable)
- run_status                                 -- success / failed / partial
- row_count (nullable)
- checksum_hash (nullable)

---

## TRANSFER DIMENSIONS (Mandatory)

### dim_transfer_header
- transfer_id (PK)
- transfer_number
- from_store_id (FK → dim_store)
- to_store_id (FK → dim_store)
- created_date_id (FK → dim_date)
- status_id (FK → dim_transfer_status)
- owner_role_id (FK → dim_role_owner)

### dim_transfer_status
- status_id (PK)
- status_name                                -- Open / In-Transit / Completed / Cancelled
