# Trading Ledger Feature — Blueprint

> Status: Brainstormed, not implemented
> Date: 2026-07-17

## Problem

User purchases items from vendors for trading (buy + margin → sell). Some items are in the app catalogue, many are not. Need a single place to record:
- Item name, cost price, vendor, margin, selling price
- Both catalogue-listed items and one-off purchase records
- Picture can be uploaded later (or never, if not needed in catalogue)

## Two-Table Architecture

### New table: `vendor_prices`

| Column | Type | Purpose |
|--------|------|---------|
| `id` | `UUID PK` | `DEFAULT gen_random_uuid()` |
| `item_name` | `text` | Required. Free text, no item number needed |
| `item_number` | `text?` | Optional link to `rate_list` if later added to catalogue |
| `category` | `text?` | For grouping/filtering |
| `vendor_name` | `text` | Who it was purchased from |
| `cost_price` | `numeric` | What the user paid |
| `margin_type` | `text` | `'percent'` or `'flat'` |
| `margin_value` | `numeric` | Percent or flat amount |
| `selling_price` | `numeric` | Computed from cost + margin |
| `notes` | `text?` | e.g. "customer walk-in, paid cash" |
| `created_by` | `text` | Session username |
| `created_at` | `timestamptz` | `DEFAULT now()` |

### Existing: `rate_list` + `cost_calculations` (unchanged)

Trading items already in catalogue are queried from `rate_list` joined with `cost_calculations` and shown alongside `vendor_prices` records in a unified view.

## UI Placement

**Not a new tab.** Accessed as a page within the **Cost Calc** tab, via an AppBar icon button (alongside Refresh, Material Prices, Bulk Trading).

| Cost Calc AppBar buttons |
|--------------------------|
| 📋 **Trading Ledger** (new) — `group_add` icon |
| 🔄 Refresh |
| 📦 Bulk Trading |
| ⚙️ Material Prices |

## Ledger Page Layout

```
┌──────────────────────────────────┐
│ AppBar: Trading Ledger           │
│ [+ Add Record] (FAB)            │
├──────────────────────────────────┤
│ Filter: [All ▼] [Vendor ▼] [Cat] │
├──────────────────────────────────┤
│ Result: 74 items                  │
│                                  │
│ ┌── CATALOGUE ITEMS ──────────┐ │
│ │ Chuda Special      ₹450→₹600│ │
│ │   Vendor: —  Margin: 33%    │ │
│ ├─────────────────────────────┤ │
│ │ Kolkata AD 2.4    ₹320→₹450│ │
│ │   Vendor: —  Margin: 40%    │ │
│ └─────────────────────────────┘ │
│ ┌── PURCHASE RECORDS ─────────┐ │
│ │ Item from VendorX ₹200→₹280│ │
│ │   Vendor: VendorX  Margin:40│ │
│ │   Notes: walk-in customer   │ │
│ ├─────────────────────────────┤ │
│ │ Raw Mats from Y   ₹500→₹700│ │
│ │   Vendor: VendorY  Margin:40│ │
│ └─────────────────────────────┘ │
└──────────────────────────────────┘
```

## Pages Needed

| Page | Route | Purpose |
|------|-------|---------|
| `TradingLedgerPage` | `/cost-calc/trading-ledger` | Unified list of all trading records (from both tables) |
| `VendorPriceFormPage` | `/cost-calc/vendor-price/add` | Add/edit a single vendor purchase record |
| `VendorPriceFormPage` | `/cost-calc/vendor-price/:id` | Edit existing record |

## Cross-link from Catalogue

`ItemEditPage` shows a chip `Trading Ledger (N records)` → navigates to `/cost-calc/trading-ledger?item=ITEM001`.

## Loose Ends & Mitigations

| Concern | Resolution |
|---------|-----------|
| **vendor_prices item not in catalogue** — user later wants to list it | Add "List in Catalogue" action on record → pre-fills `AddItemPage` with item_name, cost_price, selling_price |
| **Duplicate entries** — same item entered twice | Tolerated. Historical records. Dedup can be future enhancement. |
| **Same item in both vendor_prices and rate_list** | Both show in ledger — different facts (purchase record vs catalogue listing) |
| **No vendor field on existing catalogue items** | Catalogue items show vendor as `—` |
| **Performance** — merging two tables client-side | Both small tables (hundreds), client-side merge is fine |

## SQL Migration

```sql
CREATE TABLE vendor_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  item_number TEXT,
  category TEXT,
  vendor_name TEXT NOT NULL,
  cost_price NUMERIC NOT NULL CHECK (cost_price > 0),
  margin_type TEXT NOT NULL DEFAULT 'percent',
  margin_value NUMERIC NOT NULL DEFAULT 0,
  selling_price NUMERIC NOT NULL CHECK (selling_price > 0),
  notes TEXT,
  created_by TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT now()
);
```
