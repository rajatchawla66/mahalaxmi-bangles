# Category Ordering Audit

## 1. Current Category Fetch & Order Behavior

| Location | Query | Sort | File & Line |
|---|---|---|---|
| Customer dashboard | `activeCategoriesProvider` → `getCategories(activeOnly: true)` → `Supabase` | `.order('name')` (alphabetical) | `category_repository.dart:18` |
| Admin catalogue grid | `adminCategoriesWithStatsProvider` → `getCategories(activeOnly: false)` | `.order('name')` | `category_repository.dart:18` |
| Admin manage categories | `adminCategoriesManageProvider` → `getCategories(activeOnly: false)` | `.order('name')` | `manage_categories_page.dart:9-12` |
| Admin add-item picker | `getCategories()` | `.order('name')` | `category_repository.dart:18` |

**All category queries** go through the single `CategoryRepository.getCategories()` method which issues `.order('name')`. There is **no** server-side or client-side reordering anywhere.

## 2. Does the Database Already Have a Sort Field?

**No.** The `categories` table has no `sort_order`, `position`, `display_order`, or `priority` column.

**Current columns** (inferred from model + migrations):

| Column | Type | Notes |
|---|---|---|
| `id` | `int` | PK |
| `name` | `text` | Used as display name AND sort key |
| `icon` | `text` | Default `'CATEGORY'` |
| `color` | `text` | Default `'GREY_400'` |
| `description` | `text` | Default `''` |
| `sub_categories` | `text` | Default `''` |
| `order_type` | `text` | 'quantity' per-item pricing mode — NOT sort order |
| `is_active` | `boolean` | Default true |
| `cover_image_url` | `text?` | Nullable |
| `has_sizes` | `boolean` | Default false (added via migration) |
| `has_subcategories` | `boolean` | Default false (added via migration) |

No `CREATE TABLE` SQL exists in the repo; the table was created by the legacy Flet app.

## 3. Current Category Model

```dart
// mahalaxmi_shared/lib/models/category.dart
@freezed
class Category with _$Category {
  const factory Category({
    @JsonKey(name: 'id') int? id,
    required String name,
    @Default('CATEGORY') String icon,
    @Default('GREY_400') String color,
    @Default('') String description,
    @JsonKey(name: 'sub_categories') @Default('') String subCategories,
    @JsonKey(name: 'order_type') @Default('quantity') String orderType,        // pricing mode, NOT sort
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'cover_image_url') String? coverImageUrl,
    @JsonKey(name: 'has_sizes') @Default(false) bool hasSizes,
    @JsonKey(name: 'has_subcategories') @Default(false) bool hasSubcategories,
  }) = _Category;
}
```

**No `sortOrder` field.** The existing `order_type` field is for per-category pricing method (quantity vs weight), not display ordering.

## 4. Inactive Category Rule

- **Customer dashboard:** `getCategories(activeOnly: true)` filters `.eq('is_active', true)` — inactive categories are hidden.
- **Admin catalogue / manage:** `activeOnly: false` shows all categories.
- The `is_active` field is the sole filter. Any ordering solution must respect this: inactive categories will naturally be excluded from the customer dashboard by the existing filter, regardless of their `sort_order`.

## 5. Customer Dashboard Layout

Current category display (no changes needed):
- 3:4 portrait cover images in a 2-column grid
- Category name overlay on bottom gradient
- Tapping navigates to `/category/:categoryName`
- 16px gap between items

**The sorting change only affects the order of cards in this grid.** No layout change is required.

## 6. Recommended Implementation

### Phase 1 — Database Migration

Add a `sort_order` column with a gap-based numbering scheme.

```sql
-- 1. Add nullable column
ALTER TABLE categories
  ADD COLUMN IF NOT EXISTS sort_order INTEGER;

-- 2. Backfill: assign sort_order based on current alphabetical order
--    (categories with same name appearance order get sequential 10, 20, 30...)
UPDATE categories
SET sort_order = subq.new_order
FROM (
  SELECT id, (row_number() OVER (ORDER BY name, id) * 10) AS new_order
  FROM categories
) subq
WHERE categories.id = subq.id;

-- 3. Set NOT NULL after backfill
ALTER TABLE categories
  ALTER COLUMN sort_order SET NOT NULL,
  ALTER COLUMN sort_order SET DEFAULT 0;
```

**Design decisions:**
- Gap of 10 between initial orders (10, 20, 30...) allows inserting categories between existing ones without reindexing.
- Default 0 ensures new categories without an explicit order appear first (admin must reorder them).
- Alternative: auto-assign `SELECT COALESCE(MAX(sort_order), 0) + 10` on creation (recommended, implemented in repo).

### Phase 2 — Model Update

```dart
// mahalaxmi_shared/lib/models/category.dart — add field
@JsonKey(name: 'sort_order') @Default(0) int sortOrder,
```

This is additive — no existing fields change.

### Phase 3 — Repository Update

```dart
// mahalaxmi_shared/lib/repositories/category_repository.dart

// Change line 18 from:
var query = SupabaseClientProvider.from(_table).select();
// ...
final data = await query.order('name');

// To:
var query = SupabaseClientProvider.from(_table).select();
// ...
final data = await query.order('sort_order').order('name');
// sort_order primary, name as tiebreaker for duplicates
```

Add new methods:

```dart
/// Update sort_order for a single category
Future<void> updateSortOrder(int categoryId, int newOrder);

/// Batch-update sort_order after a reorder (e.g., drag-and-drop or move-up/move-down)
Future<void> reorderCategories(List<(int id, int order)> updates);
```

### Phase 4 — Admin UI (Manage Categories Page)

**File:** `mahalaxmi_admin/lib/features/settings/pages/manage_categories_page.dart`

**Recommended first version: Up/Down buttons approach**

Each category tile gets two small icon buttons at the right edge:
- ▲ Move Up (disabled for first item)
- ▼ Move Down (disabled for last item)

On tap:
1. Swap `sort_order` values with the adjacent category.
2. Call `reorderCategories()` with both updated rows.
3. Refresh the provider.

**Why Up/Down instead of drag-and-drop:**
- Safe with the current card layout (cover image + name + switches).
- `ReorderableListView` long-press conflicts with existing tap-to-edit and switch interactions.
- Simpler to implement, test, and verify.
- Drag-and-drop can be added later as a UX polish.

UI mock:
```
┌──────────────────────────────────────┐
│  [cover]  Chuda            ▲  ▼      │
├──────────────────────────────────────┤
│  [cover]  Kaleera          ▲  ▼      │
├──────────────────────────────────────┤
│  [cover]  Raw_Material     ▲  ▼      │
├──────────────────────────────────────┤
│  [cover]  New_Category     ▲  ▼      │
└──────────────────────────────────────┘
```

### Phase 5 — New Category Default Order

On new category creation, the repository should auto-assign:
```sql
sort_order = COALESCE(MAX(sort_order), 0) + 10
```

This places new categories at the end by default.

### Phase 6 — Customer Dashboard

No UI changes. The `activeCategoriesProvider` already passes through `getCategories(activeOnly: true)`, which will now order by `sort_order` + `name` tiebreaker. Categories render in admin-defined order automatically.

## 7. Edge Cases & Handling

| Edge Case | Handling |
|---|---|
| **Existing categories with null sort_order** | Backfill migration sets sequential 10, 20, 30...; NOT NULL enforced after backfill |
| **Duplicate sort_order values** | Fallback `.order('name')` tiebreaker in query |
| **New category creation** | Auto-assign `MAX(sort_order) + 10` in repository |
| **Deleted category** | No special handling; remaining order values stay valid |
| **Inactive category in middle of order** | Customer dashboard skips it via `is_active` filter; order gap remains |
| **Category rename** | No impact — name is only a tiebreaker |
| **Admin rapidly reorders** | Batch update in a single DB call — safe |
| **Customer app cached data** | Provider auto-refreshes on next navigation; Riverpod handles staleness |
| **GoRouter params (categoryName)** | Names must remain stable after reorder (they already are) |

## 8. Implementation Phases

| Phase | Scope | Files | Effort |
|---|---|---|---|
| **P1** | DB migration: add `sort_order`, backfill, set NOT NULL | Supabase SQL (run manually or via migration tool) | Small |
| **P2** | Model: add `int sortOrder` field | `category.dart` | Trivial |
| **P3** | Repository: change `.order('name')` → `.order('sort_order').order('name')` + add `updateSortOrder` / `reorderCategories` | `category_repository.dart` | Small |
| **P4** | Admin UI: add ▲/▼ buttons on Manage Categories | `manage_categories_page.dart` | Medium |
| **P5** | Provider refresh after reorder | `manage_categories_page.dart` (local provider) | Trivial |
| **P6** | Verify customer dashboard picks up new order | No code change needed | Test only |

## 9. Manual Testing Plan

1. **Migration test:** Run SQL migration, verify `sort_order` column exists and all rows have non-null values in 10-increment sequence.
2. **Admin reorder:** Open Manage Categories, tap ▲ on second category — verify it moves above the first. Tap ▼ on first — verify it moves back.
3. **New category:** Create a new category via admin — verify it appears at the end of the list.
4. **Customer dashboard:** Open customer app — verify categories appear in the order set by admin.
5. **Inactive categories:** Deactivate a category in admin — verify it disappears from customer dashboard but retains its order position in admin.
6. **Refresh:** Pull-to-refresh on customer dashboard — verify no order regression.
7. **Edge case — all same order:** Temporarily set two categories to `sort_order = 10` — verify alphabetical tiebreaker works.
8. **Share photo test:** Generate WhatsApp share images — verify category list order matches admin order (no regression).

## 10. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| **Admin UI conflicts:** ▲/▼ buttons may feel less polished | Acceptable for v1; drag-and-drop can be added later |
| **Out-of-range order values:** Move-up on first item, move-down on last | Disable buttons at boundaries |
| **Race condition:** Two admins reorder simultaneously | Use batch update within a transaction; last-write-wins is acceptable for v1 |
| **Customer stale cache:** Old order cached in app | Riverpod auto-refreshes on navigation; no manual cache invalidation needed |
| **Large reorder (50 categories):** ▲/▼ becomes tedious | Acceptable for v1; bulk reorder (number input) or drag-and-drop can be added later |

## 11. Recommendation

| Item | Choice | Rationale |
|---|---|---|
| Column type | `sort_order INTEGER NOT NULL DEFAULT 0` | Simple, queryable, sortable |
| Gap strategy | Increments of 10 | Room for future insertions |
| Initial backfill | Alphabetical by name | Matches current behavior; no perception change |
| Admin UI | ▲/▼ buttons on Manage Categories page | Safe with existing layout; no drag conflicts |
| New category order | `MAX(sort_order) + 10` | Natural end-of-list placement |
| Customer sort query | `.order('sort_order').order('name')` | Primary ordered + deterministic tiebreaker |
| Provider change | None needed | Delegates to repository; auto-picks up new ordering |
