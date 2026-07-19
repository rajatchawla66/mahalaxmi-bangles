# Chuda Customisation Feature — Implementation Audit

> **Status:** Analysis only — no implementation yet
> **Date:** 2026-06-18
> **Audience:** Implementation planning

---

## Table of Contents

1. [Current Architecture Findings](#1-current-architecture-findings)
2. [Recommended Schema](#2-recommended-schema)
3. [Recommended Models](#3-recommended-models)
4. [Recommended Admin UI](#4-recommended-admin-ui)
5. [Recommended Customer UI](#5-recommended-customer-ui)
6. [Cart/Order Impact](#6-cartorder-impact)
7. [Pricing Calculation Design](#7-pricing-calculation-design)
8. [Migration/SQL Required](#8-migrationsql-required)
9. [Testing Plan](#9-testing-plan)
10. [Risks](#10-risks)
11. [Step-by-Step Implementation Phases](#11-step-by-step-implementation-phases)
12. [Answers to Key Questions](#12-answers-to-key-questions)

---

## 1. Current Architecture Findings

### 1.1 Existing Schema for Chuda

The `category_schemas.dart` already defines Chuda's editable fields as:

```dart
'Chuda': CategorySchema(
  fields: ['color', 'grind_type', 'box_type', 'sizes'],
  sizes: kChudaSizes,
  lineTotal: 'sum_sizes_x_price',
  validation: 'at_least_one_size_gt_zero',
),
```

**Key finding:** `grind_type` and `box_type` are already declared in the schema, but **no Flutter UI populates them anywhere**. The schema framework recognises these fields exist, but the customer item detail page only renders `color` and `sizes`.

### 1.2 Existing `order_items` DB Columns

The `OrderItem` freezed model already maps these columns:

| JSON Key | DB Column | Model Field | Present in _itemToRow? | Present in admin create? |
|----------|-----------|-------------|----------------------|------------------------|
| `color` | `color` | `color` | ✅ Yes | ✅ Yes |
| `grind_type` | `grind_type` | `grindType` | ✅ Yes (always null) | ❌ No |
| `box_type` | `box_type` | `boxType` | ✅ Yes (always null) | ❌ No |

**The DB columns `grind_type` and `box_type` likely exist** on `order_items` (they are referenced in `customer_order_service._itemToRow` without error, and the freezed model maps them). If they don't exist, Supabase ignores unknown keys in inserts.

The admin `create_order_page.dart` does **not** include `grind_type` or `box_type` in its insert map.

### 1.3 Existing CartItem Fields

`CartItem` already has these pre-existing fields:

| Field | Type | Default | Used by UI? |
|-------|------|---------|-------------|
| `color` | `String?` | null | ✅ Yes — dropdown on item detail |
| `grindType` | `String?` | null | ❌ No — no UI sets it |
| `boxType` | `String?` | null | ❌ No — no UI sets it |

These fields already participate in:
- **Variant matching** in `CartNotifier.addItem()` — `color`, `grindType`, `boxType`, `notes`, `category` are all used to determine if two cart items are the same variant (for merge)
- **`CartItem.toJson()/fromJson()`** — all three serialize/deserialize without issues
- **`CartPersistenceService`** — auto-persists via toJson/fromJson

### 1.4 Price Calculation (Critical Finding)

`customer_order_service._itemToRow()` line 33:
```dart
'unit_price': itemInfo?.sellingPrice ?? item.unitPrice,
```

This **always uses the fresh DB price** from `rateLookup`, NOT the cart's stored `unitPrice`. For non-customized items, this ensures the order always reflects the latest DB price. But for customized Chuda items, the customisation price difference would be lost because the cart's calculated final price would be overwritten by the base DB price.

**This is a critical design issue that must be addressed.** See section 7 for the solution.

### 1.5 Category Detection in Item Detail Page

The customer `item_detail_page.dart` already detects Chuda items via:
```dart
final category = item.category as String;
if (_lastCategory != category) {
  // re-fetches size chart, resets sizes
}
```

The customization section would only need to show when `category == 'Chuda'`.

### 1.6 Admin Settings Structure

All settings pages follow a consistent pattern:
- `ConsumerStatefulWidget` + inline `FutureProvider`
- `FloatingActionButton` for add actions
- `showDialog` + `StatefulBuilder` for create/edit forms
- `ref.refresh(provider)` after mutations
- Full-screen routes via `_rootNavigatorKey`

Current settings routes:
- `/settings/tags` → `ManageTagsPage`
- `/settings/categories` → `ManageCategoriesPage`
- `/settings/margin` → `MarginSettingsPage`
- `/settings/materials` → `MaterialMasterPage`
- `/settings/archive` → `ArchiveOrdersPage`

**New route needed:** `/settings/chuda-customization`

---

## 2. Recommended Schema

### 2.1 New Table: `chuda_customization_options`

```sql
CREATE TABLE IF NOT EXISTS chuda_customization_options (
  id SERIAL PRIMARY KEY,
  group_type TEXT NOT NULL CHECK (group_type IN ('patti', 'color', 'box')),
  name TEXT NOT NULL,
  price_difference NUMERIC(10, 2) NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One default per group constraint (enforced in app + DB trigger optional)
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_default_per_group
  ON chuda_customization_options (group_type)
  WHERE is_default = true;
```

### 2.2 New Column on `order_items`: `customization jsonb`

```sql
ALTER TABLE order_items
  ADD COLUMN IF NOT EXISTS customization JSONB;
```

This stores a snapshot of the customization choices at order time:

```json
{
  "patti": {"name": "Grind", "price_difference": 50},
  "color": {"name": "Light Mehroon", "price_difference": 0, "custom_text": null},
  "box": {"name": "Box 2", "price_difference": 20},
  "total_difference": 70
}
```

**Decision rationale:** A single JSONB column is preferred over individual columns because:
- All customization data in one place
- Easy to add new option groups later (e.g., "Stone Type")
- Self-contained snapshot — old orders immune to admin edits
- Existing `grind_type` and `box_type` columns remain but are superseded for customization

### 2.3 No Changes to `rate_list`

The base price stays in `rate_list.selling_price`. Customization price difference is additive on top. No DB migration needed for items.

### 2.4 No Changes to Existing Order Flow

The existing `unit_price` column on `order_items` stores the final per-unit price (base + customization). The `customization` JSONB stores the breakdown.

---

## 3. Recommended Models

### 3.1 New Model: `ChudaCustomizationOption`

```dart
// mahalaxmi_shared/lib/models/chuda_customization_option.dart
@freezed
class ChudaCustomizationOption with _$ChudaCustomizationOption {
  const factory ChudaCustomizationOption({
    @Default(0) int id,
    required String groupType,      // 'patti', 'color', 'box'
    required String name,
    @Default(0.0) double priceDifference,
    @Default(false) bool isDefault,
    @Default(true) bool isActive,
    @Default(0) int sortOrder,
  }) = _ChudaCustomizationOption;

  factory ChudaCustomizationOption.fromJson(Map<String, dynamic> json) =>
      _$ChudaCustomizationOptionFromJson(json);
}
```

### 3.2 New Model: `ChudaCustomizationSnapshot`

For storing the user's selections (used in CartItem and OrderItem):

```dart
class ChudaCustomizationSnapshot {
  final String pattiName;
  final double pattiPriceDiff;
  final String colorName;
  final double colorPriceDiff;
  final String? customColorText;
  final String boxName;
  final double boxPriceDiff;
  final double totalDifference;

  // toJson, fromJson, copyWith
  Map<String, dynamic> toJson() => { ... };
  factory ChudaCustomizationSnapshot.fromJson(Map<String, dynamic> json) => ...;
}
```

### 3.3 CartItem Changes

Add a new field to `CartItem`:

```dart
class CartItem {
  // ... existing 17 fields unchanged

  // NEW:
  final ChudaCustomizationSnapshot? customization;
}
```

**Impact on existing code:**
- `toJson()` — add `customization?.toJson()` (null-safe, won't break non-Chuda items)
- `fromJson()` — add `customization = json['customization'] != null ? ChudaCustomizationSnapshot.fromJson(...) : null`
- `copyWith()` — add `ChudaCustomizationSnapshot? customization`
- `_mergeItems()` — when merging same-variant items, ensure `customization` matches (it will since same variant)
- Variant matching (`_isSameVariant`) — `customization` doesn't need to be in the match key since the existing fields (grindType, boxType, color) already distinguish variants. But we should confirm: for the same base item with different customizations, the matching still works.

**Variant matching analysis:**
Currently matches on: `itemNumber`, `color`, `grindType`, `boxType`, `notes`, `hasSizes`
- Two Chuda items with same itemNumber and different patti/box choices: `grindType` and `boxType` already differentiate them
- Two Chuda items with same itemNumber and different color choices: `color` already differentiates
- Two Chuda items with same everything but different custom color text: `notes` field could store this, or we add `notes` to the customization flow

**Recommendation:** The existing variant matching fields (`color`, `grindType`, `boxType`) are sufficient for Chuda customization. The new `customization` field on CartItem is for display and price calculation, not for variant matching.

### 3.4 OrderItem Changes

Add to `OrderItem` freezed model:

```dart
@JsonKey(name: 'customization') Map<String, dynamic>? customization,
```

This stores the raw JSON from the `customization` column. Display parsing happens at the UI layer.

### 3.5 OrderPdfService Changes

The order PDF should include customization info in the item description. Currently it builds descriptions from category and color. Add customization text like:
```
Patti: Grind (+₹50), Color: Light Mehroon, Box: Box 2 (+₹20)
```

---

## 4. Recommended Admin UI

### 4.1 New Settings Page: "Chuda Customisation"

**Route:** `/settings/chuda-customization`
**Location:** `mahalaxmi_admin/lib/features/settings/pages/chuda_customization_page.dart`
**Menu entry:** Add to `settings_page.dart` after "Tag Master" or after "Manage Categories"

### 4.2 UI Layout

```
┌─────────────────────────────────────┐
│  ⬅  Settings    Chuda Customisation │ AppBar
├─────────────────────────────────────┤
│                                     │
│  ┌─ Patti Options ───────────────┐  │
│  │ Without Grind   ₹0  ★ Default│  │  ★ = default badge
│  │ Grind          +₹50  Active  │  │  edit/deactivate icons
│  └────────────────────────────────┘  │
│                                     │
│  ┌─ Patti Color Options ─────────┐  │
│  │ Light Mehroon  ₹0  ★ Default │  │
│  │ Dark Mehroon    ₹0  Active   │  │
│  │ Rani            ₹0  Active   │  │
│  │ Custom          ₹0  Active   │  │
│  └────────────────────────────────┘  │
│                                     │
│  ┌─ Box Options ─────────────────┐  │
│  │ Box 1           ₹0  ★ Default│  │
│  │ Box 2          +₹20  Active  │  │
│  │ Box 3          -₹10  Active  │  │
│  └────────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
  [FAB: + Add Option]
```

### 4.3 Add/Edit Option Dialog

```
┌─ Add Chuda Customisation Option ──┐
│                                    │
│  Group Type:  [Patti ▼]           │  dropdown: Patti / Patti Color / Box
│  Name:        [______________]     │  TextField
│  Price Diff:  [__0.00__]          │  NumberField (can be negative)
│  Is Default:  [☐]                 │  Checkbox
│  Is Active:   [☑]                 │  Checkbox
│  Sort Order:  [__0__]             │  NumberField (optional, auto-assigned)
│                                    │
│         [Cancel]  [Save]          │
└────────────────────────────────────┘
```

### 4.4 Validation Rules

| Rule | Enforcement |
|------|-------------|
| Exactly one default per group | Check before save: if setting `is_default=true`, unset any existing default in that group |
| Default must have price_difference = 0 | Show warning/deny save if non-zero |
| Custom color option must exist in 'color' group | Informational (not enforced) |
| Active and Name required | Required fields |
| Price difference can be any number | Positive, zero, or negative allowed |

### 4.5 Order Detail Enhancement

In `order_detail_page.dart`, add customization section to `_OrderItemCard`:

```
┌──────────────────────────────────────┐
│ ITEM-123                ₹970.00     │
│ Color: Gold                          │
│ [2.2: 1] [2.4: 3]                   │
│ ── Customisation ──                  │  new section
│ Patti: Grind (+₹50)                  │
│ Color: Light Mehroon                │
│ Box: Box 2 (+₹20)                   │
│ Total customisation: +₹70           │
│                    Line Total: ₹3,880│
└──────────────────────────────────────┘
```

For custom color:
```
│ Color: Custom - "Customer entered text" │
```

### 4.6 Admin Order Create Page

The admin create order page should also support customisation for Chuda items. However, this is v2 scope since admin order creation is used by Mahalaxmi staff, and customisation is primarily a customer-side feature.

**v1 scope:** Admin order creation can skip customisation UI — admin adds items at base price, customer customisation happens on customer side.

---

## 5. Recommended Customer UI

### 5.1 Item Detail Page Changes

Only for Chuda items (`category == 'Chuda'`), add after the size section and before the summary card:

```
┌─ Customize Chooda ──────────────────┐
│                                      │
│  Patti                               │  section header
│  ┌──────────────┐ ┌──────────────┐  │
│  │ Without Grind│ │  Grind       │  │  chips
│  │ Included     │ │  +₹50        │  │  price diff subtitle
│  └──────────────┘ └──────────────┘  │
│                                      │
│  Patti Color                          │
│  ┌──────────┐ ┌──────────┐ ┌──────┐  │
│  │Light     │ │Dark      │ │Rani  │  │  chips, no price diff shown
│  │Mehroon   │ │Mehroon   │ │      │  │  (all ₹0 difference)
│  └──────────┘ └──────────┘ └──────┘  │
│  ┌──────────┐                         │
│  │ Custom   │                         │
│  └──────────┘                         │
│  If Custom selected:                  │
│  [ Enter custom patti color ]        │  TextField
│                                      │
│  To see patti color pictures,         │  helper text
│  please visit Opek category.          │
│                                      │
│  Box                                   │
│  ┌───────┐ ┌───────┐ ┌───────────┐   │
│  │Box 1  │ │Box 2  │ │  Box 3    │   │  chips
│  │Incl.  │ │+₹20   │ │  -₹10     │   │  price diff subtitle
│  └───────┘ └───────┘ └───────────┘   │
│                                      │
│  To see box pictures, please visit    │  helper text
│  Box category.                        │
│                                      │
│  Customisation: +₹70                  │  total customisation
│  Final price: ₹970                    │  base + customisation
└────────────────────────────────────────┘
```

### 5.2 Price Difference Display Rules

| Price Difference | Display |
|-----------------|---------|
| 0 | "Included" or "Incl." |
| Positive | "+₹XX" (green or neutral) |
| Negative | "-₹XX" (orange/red — discount) |

### 5.3 Default Selection

On page load, auto-select the default option in each group. Query `chuda_customization_options WHERE is_default = true` per group.

### 5.4 Price Calculation (Live)

```dart
double _calculateCustomisedPrice() {
  final basePrice = unitPrice;  // from RateItem.sellingPrice
  final pattiDiff = _selectedPattiOption?.priceDifference ?? 0;
  final colorDiff = _selectedColorOption?.priceDifference ?? 0;
  final boxDiff = _selectedBoxOption?.priceDifference ?? 0;
  final totalDiff = pattiDiff + colorDiff + boxDiff;
  return basePrice + totalDiff;
}
```

### 5.5 Add to Cart Payload

```dart
CartItem(
  // ... existing fields unchanged ...
  unitPrice: _calculateCustomisedPrice(),  // FINAL price
  customization: ChudaCustomizationSnapshot(
    pattiName: 'Grind',
    pattiPriceDiff: 50,
    colorName: 'Light Mehroon',
    colorPriceDiff: 0,
    customColorText: null,
    boxName: 'Box 2',
    boxPriceDiff: 20,
    totalDifference: 70,
  ),
)
```

### 5.6 Cart Display

In customer cart page, show customization info under item number:

```
ITEM-123
Patti: Grind (+₹50)
Color: Light Mehroon
Box: Box 2 (+₹20)
₹970 x 2 = ₹1,940
```

### 5.7 Options Loading

Load options from `chuda_customization_options` table where `is_active = true`, ordered by `sort_order ASC`.

**Caching:** Since these options change infrequently, cache them in-memory via a Riverpod `FutureProvider` for the session duration. Refetch on app resume if needed.

```dart
final chudaCustomizationOptionsProvider =
    FutureProvider<List<ChudaCustomizationOption>>((ref) async {
  final repo = ref.read(chudaCustomizationRepositoryProvider);
  return await repo.getActiveOptions();
});
```

**Per-group filtering:**

```dart
final pattiOptionsProvider = Provider((ref) {
  final all = ref.watch(chudaCustomizationOptionsProvider).valueOrNull ?? [];
  return all.where((o) => o.groupType == 'patti').toList();
});
```

---

## 6. Cart/Order Impact

### 6.1 Cart Item Storage

`CartItem.customization` is the single source of truth for what the customer selected. All pricing decisions use this snapshot.

### 6.2 Variant Matching in CartNotifier.addItem()

Current matching key: `itemNumber`, `color`, `grindType`, `boxType`, `notes`, `category`

With customization, this should be expanded to include the customization choices for proper merge behavior:

```dart
// In _isSameVariant equivalent:
itemNumber == a.itemNumber &&
a.color == b.color &&
a.grindType == b.grindType &&
a.boxType == b.boxType &&
a.notes == b.notes &&
a.hasSizes == b.hasSizes &&
_a.customization?.pattiName == _b.customization?.pattiName &&
_a.customization?.colorName == _b.customization?.colorName &&
_a.customization?.boxName == _b.customization?.boxName &&
_a.customization?.customColorText == _b.customization?.customColorText
```

Without this, selecting different customizations on the same base item would incorrectly merge quantities.

### 6.3 Cart Persistence

`CartPersistenceService` uses `CartItem.toJson()/fromJson()`. Adding `customization` to both methods ensures automatic persistence. **No changes needed to `CartPersistenceService` itself.**

### 6.4 Order Insert — customer_order_service._itemToRow()

**Critical change required.** The current implementation overwrites `unit_price` with the fresh DB price:

```dart
'unit_price': itemInfo?.sellingPrice ?? item.unitPrice,
```

**Fix for customization:** If the cart item has a `customization` snapshot, use the cart's `unitPrice` (which already includes customization difference). Otherwise, keep the current behavior.

```dart
'unit_price': item.customization != null
    ? item.unitPrice
    : (itemInfo?.sellingPrice ?? item.unitPrice),
```

Also add:
```dart
'customization': item.customization?.toJson(),
```

### 6.5 Order Insert — admin create_order_page.dart

The admin page inserts item rows without calling `_itemToRow`. It directly builds the map. Add:

```dart
'customization': item.customization?.toJson(),
```

### 6.6 Order Summary Calculation (buildOrderSummary)

Currently uses `rateLookup` to get fresh prices. For customized items, it should use the cart's `unitPrice`. However, the summary is primarily for display — the actual order total is recalculated at insert time.

**Recommendation:** In `buildOrderSummary`, when building summary items, if `item.customization != null`, use `item.unitPrice` instead of `rateLookup` price. This ensures the customer sees the correct estimated total during checkout.

### 6.7 Order Total

The order `total_amount` is `summary.grandTotal` which sums line totals. If line totals use the corrected unit price (with customization), the order total will be correct automatically.

### 6.8 Order Detail Display

Parse `orderItem.customization` JSON and display in `_OrderItemCard` as described in section 4.5.

---

## 7. Pricing Calculation Design

### 7.1 Price Flow Summary

```
RateItem.sellingPrice (base price, e.g. ₹900)
  │
  ▼
Item Detail Page:
  finalUnitPrice = basePrice
                 + selectedPatti.priceDifference
                 + selectedColor.priceDifference
                 + selectedBox.priceDifference
  │
  ▼
CartItem {
  unitPrice: finalUnitPrice,           // e.g. ₹970
  customization: {
    totalDifference: 70,               // sum of diffs
    patti: { name: "Grind", priceDifference: 50 },
    color: { name: "Light Mehroon", priceDifference: 0 },
    box: { name: "Box 2", priceDifference: 20 }
  }
}
  │
  ▼
customer_order_service._itemToRow():
  unit_price = item.customization != null
               ? item.unitPrice          // keep the calculated price
               : dbPrice;                // fresh from DB
  customization = item.customization.toJson()
  │
  ▼
order_items {
  unit_price: 970,                      // final price with customization
  customization: { ... snapshot ... }   // immutable snapshot
}
```

### 7.2 Line Total

```dart
lineTotal = unitPrice * totalSizeQty
```

This already works correctly because `unitPrice` now includes customization.

### 7.3 Order Grand Total

Sum of all line totals. Unchanged calculation — just the prices are now higher for customized items.

### 7.4 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Admin changes base price after add-to-cart | Current behavior uses DB price for non-customized items (fresh price). For customized, uses cart price (agreed price at time of order). |
| Admin changes option prices after add-to-cart | Customer's cart has snapshot of old prices. Order uses cart prices. |
| Admin deactivates an option | Customer's cart still has the selected option name. Order shows it. But no new selections possible. |
| Customer has Chuda in cart, admin changes rate_list price | For non-customized Chuda: fresh DB price used (as today). For customized: cart price used. |
| Zero price item with customization | Base ₹0 + ₹50 customization = ₹50 final price. Edge case for free items. |

---

## 8. Migration/SQL Required

### 8.1 Phase 1 (Pre-implementation)

```sql
-- Create customization options table
CREATE TABLE IF NOT EXISTS chuda_customization_options (
  id SERIAL PRIMARY KEY,
  group_type TEXT NOT NULL CHECK (group_type IN ('patti', 'color', 'box')),
  name TEXT NOT NULL,
  price_difference NUMERIC(10, 2) NOT NULL DEFAULT 0,
  is_default BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One default per group (partial unique index)
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_default_per_group
  ON chuda_customization_options (group_type)
  WHERE is_default = true;
```

### 8.2 Phase 1b — Seed Default Options

```sql
-- Patti options
INSERT INTO chuda_customization_options (group_type, name, price_difference, is_default, is_active, sort_order) VALUES
  ('patti', 'Without Grind', 0, true, true, 10),
  ('patti', 'Grind', 50, false, true, 20);

-- Color options
INSERT INTO chuda_customization_options (group_type, name, price_difference, is_default, is_active, sort_order) VALUES
  ('color', 'Light Mehroon', 0, true, true, 10),
  ('color', 'Dark Mehroon', 0, false, true, 20),
  ('color', 'Rani', 0, false, true, 30),
  ('color', 'Custom', 0, false, true, 40);

-- Box options
INSERT INTO chuda_customization_options (group_type, name, price_difference, is_default, is_active, sort_order) VALUES
  ('box', 'Box 1', 0, true, true, 10),
  ('box', 'Box 2', 20, false, true, 20),
  ('box', 'Box 3', -10, false, true, 30);
```

### 8.3 Phase 2 (Before Customer UI Goes Live)

```sql
-- Add customization JSONB column to order_items
ALTER TABLE order_items
  ADD COLUMN IF NOT EXISTS customization JSONB;
```

### 8.4 Verification Queries

```sql
-- Verify options
SELECT * FROM chuda_customization_options ORDER BY group_type, sort_order;

-- Verify orders with customization
SELECT oi.item_number, oi.unit_price, oi.customization
FROM order_items oi
WHERE oi.customization IS NOT NULL;
```

---

## 9. Testing Plan

### 9.1 Admin Settings — Chuda Customisation Page

| Test | Expected |
|------|----------|
| Add patti option "Test" with ₹25 | Appears in patti group |
| Add box option with -₹5 | Appears in box group |
| Edit price from ₹25 to ₹30 | Price updated |
| Set as default | Previous default in group loses default |
| Try to set default with non-zero price | Warning/block |
| Deactivate option | Hidden from customer app |
| Reactivate option | Visible again |
| Delete option | Removed (or soft-delete via deactivate) |

### 9.2 Customer Item Detail — Customisation Section

| Test | Expected |
|------|----------|
| Open Chuda item | Shows Customize Chooda section |
| Open non-Chuda item | No customisation section |
| Defaults pre-selected | Each group shows default chip active |
| Price display | "Included" for ₹0, "+₹50" for positive, "-₹10" for negative |
| Select different patti | Live price updates |
| Select different box | Live price updates |
| Select Custom color | Text field appears |
| Leave Custom color empty | Validation blocks add-to-cart |
| Total customisation | Sum of all diffs displayed |
| Final price | Base + total diff displayed |

### 9.3 Cart

| Test | Expected |
|------|----------|
| Add customized Chuda to cart | Cart shows customization details |
| Add same Chuda with same customisation | Quantities merge |
| Add same Chuda with different customisation | Separate line item |
| Add non-Chuda item | Behave normally |
| Kill app and reopen | Cart restored with customisation |
| Place order | Order stores customization snapshot |

### 9.4 Order

| Test | Expected |
|------|----------|
| Place customer order with customization | customization JSONB populated |
| Admin views order detail | Customisation section visible |
| Admin edits option name after order placed | Old order still shows original name |
| PDF share | Customisation info in item description |

### 9.5 Regression

| Test | Expected |
|------|----------|
| Order non-Chuda item | No customization column, unit_price unchanged from fresh DB |
| Order Chuda WITHOUT customization (preexisting cart) | unit_price from DB, customization null |
| Admin creates order for Chuda item | No customization section (v1 scope) |
| All 182 existing tests pass | No regressions |

---

## 10. Risks

### 10.1 Risk Matrix

| # | Risk | Probability | Impact | Mitigation |
|---|------|-------------|--------|------------|
| 1 | `_itemToRow` overwrites customization price with fresh DB price | **High** | **High** | Fix `_itemToRow` to use `item.unitPrice` when customization is present (section 6.4) |
| 2 | CartItem variant matching doesn't account for customization, merges different choices | **Medium** | **High** | Add customization fields to variant matching key (section 6.2) |
| 3 | `buildOrderSummary` calculates line total with base price instead of customised price | **Medium** | **Medium** | Update to use `item.unitPrice` when customization present (section 6.6) |
| 4 | Admin order creation doesn't support customization | **Low** | **Medium** | v1 scope exclusion — admin creates orders at base price; explicit decision |
| 5 | Existing `grind_type`/`box_type` columns on order_items become stale/misleading | **Low** | **Low** | They remain at null for new orders; customization JSONB is the source of truth |
| 6 | Cart persistence fails if `ChudaCustomizationSnapshot.toJson()` not implemented | **Low** | **High** | Standard implementation; test covers this |
| 7 | Customer app loads options from Supabase on every page load (no caching) | **Medium** | **Low** | Options are small (<10 rows); a simple `FutureProvider` caches for session |
| 8 | Admin changes option price while customer is on item detail page | **Low** | **Low** | Price is locked at add-to-cart time; cart shows the snapshot |

### 10.2 High-Risk Items Requiring Attention

**Risk #1** is the most critical. Without fixing `_itemToRow`, customer orders for customized Chuda items will lose the price difference.

The fix is small and localized:
```dart
// customer_order_service.dart line 33
'unit_price': item.customization != null
    ? item.unitPrice
    : (itemInfo?.sellingPrice ?? item.unitPrice),
```

### 10.3 No-Break Rules Compliance

| Rule | Status |
|------|--------|
| Current Chuda size chart/size availability logic | ✅ Not touched |
| Cart persistence | ✅ Extends CartItem, not persistence service |
| Category size_chart feature | ✅ Not touched |
| Product feed layout | ✅ Not touched |
| Watermark/zoom | ✅ Not touched |
| Tag filter | ✅ Not touched |
| Customer login/session | ✅ Not touched |
| Disabled customer logic | ✅ Not touched |
| Normal catalogue categories | ✅ Not touched |
| Supabase product images | ✅ Not touched |
| WhatsApp Photo Share | ✅ Not touched |

---

## 11. Step-by-Step Implementation Phases

### Phase 0 — Setup (Estimated: 1 hour)
- [ ] Run SQL migration to create `chuda_customization_options` table
- [ ] Run seed SQL for default options
- [ ] Run SQL to add `customization` column to `order_items`
- [ ] Create `ChudaCustomizationOption` freezed model + generated files
- [ ] Add `chuda_customization_repository.dart` to shared package
- [ ] Create `ChudaCustomizationSnapshot` model (plain Dart, with toJson/fromJson)
- [ ] Add `customization` field to `CartItem` (model + toJson + fromJson + copyWith)
- [ ] Add `customization` field to `OrderItem` freezed model + regenerate

### Phase 1 — Admin Settings UI (Estimated: 3-4 hours)
- [ ] Create `ChudaCustomizationPage` (ConsumerStatefulWidget, inline FutureProvider)
- [ ] Group options by type (Patti / Color / Box)
- [ ] Add/Edit/Deactivate option dialogs
- [ ] Sort order management
- [ ] Default option validation (one per group)
- [ ] Add route `/settings/chuda-customization` to router
- [ ] Add menu entry in `settings_page.dart`
- [ ] Run `flutter analyze` — 0 errors

### Phase 2 — Customer Item Detail (Estimated: 4-5 hours)
- [ ] Load customization options in item detail page (only for Chuda category)
- [ ] Add `ChudaCustomizationSnapshot` state to page
- [ ] Render Patti chip selector with price diffs
- [ ] Render Color chip selector (with Custom → text field)
- [ ] Render Box chip selector with price diffs
- [ ] Helper text links (Opek / Box categories)
- [ ] Live price calculation display
- [ ] Pass customization snapshot to CartItem on add-to-cart
- [ ] Update variant matching in `CartNotifier.addItem()` (add customization fields)
- [ ] Display customization in cart page
- [ ] Run `flutter analyze` — 0 errors

### Phase 3 — Order Pipeline (Estimated: 2-3 hours)
- [ ] Fix `customer_order_service._itemToRow`:
  - Use `item.unitPrice` when customization present
  - Include `customization` JSON in insert map
- [ ] Fix admin `create_order_page.dart`:
  - Include `customization` in insert map (even if null)
- [ ] Update `buildOrderSummary` to use `item.unitPrice` for customized items
- [ ] Display customization in `_OrderItemCard` on order detail page
- [ ] Add customization info to PDF generation
- [ ] Run `flutter analyze` — 0 errors

### Phase 4 — Testing & Polish (Estimated: 3-4 hours)
- [ ] Run all 182 existing tests — pass
- [ ] Write new unit tests for:
  - `_itemToRow` with customization
  - `CartNotifier.addItem` variant matching with customization
  - `buildOrderSummary` with customized items
  - `CartItem.toJson/fromJson` round-trip with customization
  - `ChudaCustomizationSnapshot` serialization
- [ ] Manual testing on device (see section 9)
- [ ] Verify no regression in non-Chuda ordering
- [ ] Verify PDF share includes customization info
- [ ] Run `flutter analyze` on all 3 apps — 0 errors

### Total Estimated Effort: 10-14 hours

---

## 12. Answers to Key Questions

### Q1: What new Supabase tables/columns are needed?

**New table:** `chuda_customization_options`
**New column:** `order_items.customization` (JSONB)

### Q2: Should order_items get a `customization` jsonb column?

**Yes.** A single JSONB column is preferred over individual columns because:
- Snapshot isolation (old orders immune to admin edits)
- Extensible (add new option groups without migration)
- Self-contained (all customization data in one place)
- Simple to parse and display

The existing `grind_type`, `box_type`, `color` columns still exist but the JSONB is the authoritative source for customized orders.

### Q3: Should cart item store customization as a model or map?

**Model.** A dedicated Dart class `ChudaCustomizationSnapshot` with `toJson()/fromJson()` provides type safety, clarity, and easy serialization. Stored in the `CartItem.customization` field.

### Q4: How should final price be calculated and saved?

1. **Calculation:** `finalPrice = rateList.sellingPrice + sum(all selected option price_differences)`
2. **Storage in cart:** `CartItem.unitPrice = finalPrice`, `CartItem.customization = snapshot`
3. **Storage in order:** `order_items.unit_price = finalPrice`, `order_items.customization = snapshot.toJson()`

### Q5: Where should customer load customisation options from?

Supabase `chuda_customization_options` table, filtered by `is_active = true`, ordered by `sort_order ASC`. Loaded via a shared repository in `mahalaxmi_shared`.

### Q6: Should options be cached?

**Yes — in-memory only.** A Riverpod `FutureProvider` caches options for the current app session. Options change infrequently (admin-controlled). Refetch on app resume or pull-to-refresh. No need for SharedPreferences or disk cache.

### Q7: How to ensure one default per group?

**Partial unique index** on `chuda_customization_options`:
```sql
CREATE UNIQUE INDEX idx_one_default_per_group
  ON chuda_customization_options (group_type)
  WHERE is_default = true;
```

This enforces the constraint at the DB level. Additionally, the admin UI must unset the previous default when setting a new one (to avoid insert/update errors).

### Q8: How to prevent old orders from changing after admin edits options?

**Immutable snapshot in order_items.** The `customization` JSONB column stores option `name` (not ID) + `price_difference` at order time. Even if admin later changes an option's name or price, the order record is unchanged. This is the same pattern used throughout the system (e.g., `unit_price` snapshots the price at order time rather than referencing `rate_list.selling_price`).

### Q9: What are the exact implementation phases?

See [Section 11](#11-step-by-step-implementation-phases) — 4 phases totaling 10-14 hours.

### Q10: Should this be implemented before Play Store internal testing or after?

**After.** Rationale:

1. **Minimum Viable Beta:** The current app is feature-complete for beta testing without Chuda customization. The existing ordering flow (base price, sizes, color) already works.

2. **Risk of delay:** Adding 10-14 hours of work before testing introduces unnecessary delay. The beta feedback on the core experience (login, catalogue browsing, cart, ordering, PDF share) is more valuable.

3. **Low coupling:** The customization feature is fully additive — no existing feature depends on it. It can be shipped as a v1.1 update without touching v1.0.

4. **Revalidation:** After beta testing, the customization requirements may change based on real customer feedback. Implementing before testing risks building the wrong solution.

**Recommendation:** Ship the current app for Play Store internal testing first. Implement Chuda Customisation as the first post-beta feature update.

---

## Minimum V1 Scope

| Feature | V1 | V2 |
|---------|----|----|
| Admin settings page (CRUD options) | ✅ | — |
| Admin order detail shows customization | ✅ | — |
| Customer item detail — Patti selector | ✅ | — |
| Customer item detail — Color selector | ✅ | — |
| Customer item detail — Box selector | ✅ | — |
| Customer item detail — Custom color text | ✅ | — |
| Live price calculation | ✅ | — |
| Cart stores customization snapshot | ✅ | — |
| Order stores immutable customization JSON | ✅ | — |
| PDF includes customization info | ✅ | — |
| Admin order creation supports customization | — | ✅ (Phase 5) |
| Option images (box/patti pictures in UI) | — | ✅ (Future) |
| Multiple language support for option names | — | ✅ (Future) |

### V1 Exclusions (Intentional)

- **Admin order creation customization:** Admin staff creates orders at base price. Customer customisation is customer-side only. If staff needs to create a pre-customized order, they can edit line item description/notes.
- **Image uploads for box options:** Box images are not needed per business decision. Customer sees helper text linking to Box category.
- **Bulk import/export of options:** Admin can add options manually via the settings UI.
- **Customer order editing after placement:** Standard — orders are immutable once placed.

---

## Conclusion

**Is this safe to implement now?** ✅ **Yes, but it should be implemented AFTER the initial Play Store beta release, not before.**

The feature is:
- **Additive** — no existing code is modified in a breaking way
- **Self-contained** — new table, new column, new UI section, no refactoring
- **Low risk** — all 12 audit findings have clear mitigations
- **Well-scoped** — v1 covers the complete flow from admin setup to order snapshot

The one critical implementation requirement (**Risk #1**) is the `_itemToRow` fix in `customer_order_service.dart` — without it, customized prices would be overwritten by DB prices at order time. This is a small, localized change with no side effects.

**Recommended sequence:**
1. Ship current app for Play Store internal testing (this week)
2. Implement Chuda Customisation (10-14 hours, next sprint)
3. Ship v1.1 update with customization
