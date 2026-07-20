# Trading Ledger Feature — Blueprint (Revised)

> Status: Approved — ready for implementation
> Date: 2026-07-19

---

## Problem

Need a single place to view **all items** (both trading and manufactured) with their cost price, selling price, and margin — grouped either by **category** or by **vendor**.

Two item types:
- **Trading** — bought from a vendor at cost_price, sold at cost + margin. Simple.
- **Manufactured** — produced in-house. cost_price is the sum of raw materials (calculated via `cost_calculations`). The calculation is revisited often — to verify raw material prices, update them, or catch pricing errors.

Additionally, one-off purchase records (items not in the catalogue) also need to appear in the ledger.

---

## Data Model

### New table: `vendor_master`

Like `tag_master` — a pickable list of vendor names.

| Column | Type | Notes |
|--------|------|-------|
| `id` | `UUID PK` | `DEFAULT gen_random_uuid()` |
| `name` | `text NOT NULL` | Display name |
| `is_active` | `bool DEFAULT true` | Soft delete |

### New column on `rate_list`: `vendor`

| Column | Type | Notes |
|--------|------|-------|
| `vendor` | `text?` | FK-like reference to `vendor_master.name`. Nullable — manufactured items may not have a vendor. Set at item creation/editing. |

The vendor picker on Add/Edit Item works like tag selection — autocomplete from `vendor_master`.

### New table: `vendor_prices`

Non-catalogue purchase records (one-off items that appear in ledger but not in catalogue).

| Column | Type | Notes |
|--------|------|-------|
| `id` | `UUID PK` | `DEFAULT gen_random_uuid()` |
| `item_name` | `text NOT NULL` | Free text |
| `category` | `text?` | For grouping in Category view |
| `vendor_name` | `text NOT NULL` | FK-like reference to `vendor_master.name` |
| `cost_price` | `numeric NOT NULL` | What the user paid |
| `margin_type` | `text NOT NULL DEFAULT 'percent'` | `'percent'` or `'flat'` |
| `margin_value` | `numeric NOT NULL DEFAULT 0` | Percent or flat amount |
| `selling_price` | `numeric NOT NULL` | Computed from cost + margin |
| `notes` | `text?` | e.g. "walk-in customer, paid cash" |
| `created_by` | `text DEFAULT ''` | Session username |
| `created_at` | `timestamptz DEFAULT now()` | |

### Existing tables used (unchanged)

| Table | Role |
|-------|------|
| `rate_list` | Catalogue items (both trading and manufactured) |
| `cost_calculations` | Raw material breakdown for manufactured items |
| `categories` | Category grouping for Category view |
| `cost_breakdown` | Individual raw material line items |
| `material_settings` | Raw material cost config |

---

## Two Views

### 1. Category View

```
Categories (from categories table, sorted by sort_order)
  │
  └─ [Tap]
       │
       Items in category (merged from rate_list + vendor_prices)
         - Item name | Vendor | CP → SP | Margin %
         - Tap → Detail page (full info, pic for catalogue items,
           cost breakdown link for manufactured items)
```

- Categories with zero items are hidden.
- `vendor_prices` items without a category appear under "Uncategorised".

### 2. Vendor View

```
Vendors (from vendor_master, sorted alphabetically)
  │
  └─ [Tap]
       │
       Items from vendor (merged from rate_list + vendor_prices)
         - Item name | Category | CP → SP | Margin %
         - Tap → Detail page (full info, pic for catalogue items,
           cost breakdown link for manufactured items)
```

- Items without a vendor (e.g. manufactured items with no vendor) appear under "No Vendor".
- The same item can appear only once per vendor, deduplicated by `item_number`.

---

## Pages & Routes

| Page | Route | Purpose |
|------|-------|---------|
| `LedgerPage` | `/cost-calc/ledger` | Root — toggle between Category / Vendor view |
| `CategoryListPage` | *(inline in LedgerPage)* | Lists categories with item count |
| `ItemsByCategoryPage` | `/cost-calc/ledger/category/:name` | Items in a category, CP/SP/Margin |
| `VendorListPage` | *(inline in LedgerPage)* | Lists vendors with item count |
| `ItemsByVendorPage` | `/cost-calc/ledger/vendor/:name` | Items from a vendor, CP/SP/Margin |
| `ItemLedgerDetailPage` | `/cost-calc/ledger/item/:id?source=rate_list\|vendor_prices` | Full detail + cost breakdown link |

### Form Pages

| Page | Route | Purpose |
|------|-------|---------|
| `VendorPriceFormPage` | `/cost-calc/ledger/vendor-price/add` | Add a non-catalogue purchase record |
| `VendorPriceFormPage` | `/cost-calc/ledger/vendor-price/:id` | Edit existing record |

### Cross-links

| Source | Action |
|--------|--------|
| `ItemEditPage` | Chip "Ledger (N records)" → `/cost-calc/ledger/item/:id?source=rate_list` |
| `ItemLedgerDetailPage` (manufactured) | "View Cost Calculation" → `/cost-calc/calculation/:id` |
| `ItemLedgerDetailPage` (non-catalogue) | "Add to Catalogue" → pre-fills `AddItemPage` |

---

## UI Flow (Wireframe)

```
Cost Calc Tab (AppBar)
│
├─ [📋 Ledger icon button] → LedgerPage
│   ├─ Segment: [Category] [Vendor]
│   │
│   ├── Category tab:
│   │   ┌────────────────────────────────────┐
│   │   │ Search: _______________             │
│   │   │                                     │
│   │   │ Chuda (18 items)           ›        │
│   │   │ Kolkata AD Bangles (12)    ›        │
│   │   │ Metal Bangles (7)          ›        │
│   │   │ Uncategorised (3)          ›        │
│   │   └────────────────────────────────────┘
│   │         [Tap category] → ItemsByCategoryPage
│   │   ┌────────────────────────────────────┐
│   │   │ ← Ledger    Chuda                  │
│   │   │ [+ Add Record] (FAB)              │
│   │   │                                     │
│   │   │ K92 Chuda         ₹450→₹600  33%  │
│   │   │   Vendor: ABC Traders              │
│   │   │ K94 Chuda         ₹420→₹560  33%  │
│   │   │   Vendor: — (Manufactured)         │
│   │   │ ...                                 │
│   │   └────────────────────────────────────┘
│   │         [Tap item] → ItemLedgerDetailPage
│   │
│   └── Vendor tab:
│       ┌────────────────────────────────────┐
│       │ Search: _______________             │
│       │                                     │
│       │ ABC Traders (5 items)      ›        │
│       │ XYZ Mart (3 items)         ›        │
│       │ No Vendor (22 items)       ›        │
│       └────────────────────────────────────┘
│             [Tap vendor] → ItemsByVendorPage
│       ┌────────────────────────────────────┐
│       │ ← Ledger    ABC Traders            │
│       │ [+ Add Record] (FAB)              │
│       │                                     │
│       │ K92 Chuda         ₹450→₹600  33%  │
│       │   Category: Chuda                   │
│       │ Item from vendor  ₹200→₹280  40%  │
│       │   Category: —  (one-off)           │
│       │ ...                                 │
│       └────────────────────────────────────┘
│
├─ [Tap item] → ItemLedgerDetailPage
│   ┌────────────────────────────────────┐
│   │ ← Ledger    Item Detail            │
│   │                                     │
│   │ [Item Image — catalogue items]     │
│   │                                     │
│   │ Name: K92 Chuda                     │
│   │ Category: Chuda                     │
│   │ Item #: CHD001                      │
│   │ Vendor: ABC Traders                 │
│   │                                     │
│   │ Cost Price:  ₹450                   │
│   │ Selling Price: ₹600                 │
│   │ Margin: 33%                         │
│   │                                     │
│   │ [View Cost Calculation]  ← mfg only │
│   │ [Add to Catalogue]       ← one-offs │
│   └────────────────────────────────────┘
│
└─ [FAB on ItemsByVendor/ItemsByCategory]
   └─ VendorPriceFormPage (add one-off record)

```

---

## Data Merge Logic

The ledger merges two data sources client-side:

### Source A: `rate_list` (catalogue items)

```sql
SELECT
  id, item_name, item_number, category, vendor,
  cost_price,
  selling_price,
  NULL AS notes, 'rate_list' AS source,
  -- margin computed later
FROM rate_list
WHERE is_active = true
```

For manufactured items, `cost_price` is the value stored in `rate_list.cost_price` (populated when the cost calculation is saved). The detail page provides a link to view/edit the underlying `cost_calculations` breakdown.

### Source B: `vendor_prices` (non-catalogue records)

```sql
SELECT
  id, item_name, NULL AS item_number, category, vendor_name AS vendor,
  cost_price, selling_price,
  notes, 'vendor_prices' AS source
FROM vendor_prices
```

### Margin Calculation

```
margin_pct = ROUND((selling_price - cost_price) / cost_price * 100)
```

### Dedup

- `vendor_prices` records with a non-null `item_number` that matches an existing `rate_list.item_number` are shown alongside the catalogue entry — they represent different facts (purchase history vs catalogue listing).
- In Vendor view, items are grouped by `vendor`. If a catalogue item has no vendor, it falls under "No Vendor".

---

## Cost Calculation Integration (Manufactured Items)

For manufactured items, the detail page shows:

```
Cost Price Breakdown:
  ─────────────────────────────
  Raw Material A       ₹200
  Raw Material B       ₹150
  Making Charges       ₹100
  ─────────────────────────────
  Total Cost           ₹450
  Margin (33%)         ₹150
  Selling Price        ₹600
  ─────────────────────────────
```

Tapping "View Cost Calculation" navigates to the existing cost calculation detail (`/cost-calc/calculation/:id`) where the user can:
- See the full raw material breakdown
- Update raw material prices
- Verify no pricing errors

This is the key workflow for the "revisit cost calculation" use case.

---

## UI Placement (in Admin App)

**Entry point:** AppBar icon button in the **Cost Calc** tab.

```
Cost Calc AppBar buttons (revised):
┌──────────────────────────────────┐
│ 📋 Ledger    🔄 Refresh          │
│ 📦 Bulk Trading  ⚙️ Material     │
└──────────────────────────────────┘
```

Icon: `receipt_long` or `book` — positioned as the first button.

---

## Existing ItemEditPage Integration

When editing an item in `ItemEditPage`, a `vendor` field is added to the form:
- Autocomplete/dropdown from `vendor_master`
- Acts like tag selection — start typing, pick from filtered list
- Can be left empty for manufactured items with no vendor

---

## SQL Migration

```sql
-- 1. Vendor master table
CREATE TABLE vendor_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true
);

-- 2. Add vendor column to rate_list
ALTER TABLE rate_list
  ADD COLUMN vendor TEXT;

-- 3. Vendor purchase records (non-catalogue)
CREATE TABLE vendor_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
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

---

## Loose Ends & Mitigations

| Concern | Resolution |
|---------|-----------|
| **Manufactured item cost_price is stale** — raw material prices updated after cost calc was saved | Stale is acceptable — the cost calc detail shows the current breakdown. User can re-save to update `rate_list.cost_price`. |
| **Item has multiple cost calculations** (revisions) | Show the latest. Detail page lists all revisions. |
| **One-off record later added to catalogue** | "Add to Catalogue" action on detail page pre-fills `AddItemPage`. After creation, the record remains in `vendor_prices` as a historical purchase. |
| **Same vendor name variants** ("ABC Traders" vs "abc traders") | Vendor master enforces canonical names. Autocomplete prevents duplicates. |
| **Performance** — merging two tables client-side | Both tables are small (hundreds). Client-side merge is fine. |
| **Legacy items with no vendor** | Show under "No Vendor" in vendor view. Category view unaffected. |
