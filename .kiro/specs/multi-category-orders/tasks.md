# Implementation Plan: Multi-Category Orders

## Overview

Extend the existing Chuda-only order system to support five product categories (Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal) with category-specific order attributes, dynamic form rendering, and backward-compatible database migration. All changes are confined to `db.py` (data layer) and `main.py` (UI/logic), keeping the project's single-file architecture.

## Tasks

- [x] 1. Database schema extension and migration
  - [x] 1.1 Add new columns to rate_list and order_items tables in db.py
    - Add `category TEXT NOT NULL DEFAULT 'Chuda'`, `sub_category TEXT DEFAULT NULL`, `is_available INTEGER NOT NULL DEFAULT 1` columns to `rate_list` table
    - Add `category TEXT NOT NULL DEFAULT 'Chuda'`, `quantity REAL DEFAULT NULL`, `unit TEXT DEFAULT NULL`, `color TEXT DEFAULT NULL`, `grind_type TEXT DEFAULT NULL`, `box_type TEXT DEFAULT NULL`, `notes TEXT DEFAULT NULL` columns to `order_items` table
    - Use `_safe_add_column` helper pattern (try ALTER TABLE, catch OperationalError) for idempotent column additions
    - _Requirements: 10.1, 10.2, 10.3_

  - [x] 1.2 Implement idempotent migration logic in db.py
    - Create `run_migration()` function called from `init_db()`
    - Migrate existing rate_list items: set `category = 'Chuda'` where category is NULL
    - Copy order-level color, grind_type, box_type from orders table to order_items where those fields are NULL
    - Ensure migration is idempotent (no-op on second run, no errors on fresh DB)
    - _Requirements: 10.4, 10.5, 10.6_

  - [ ]* 1.3 Write property tests for migration logic
    - **Property 8: Migration sets NULL categories to Chuda**
    - **Property 9: Migration copies order-level attributes to item-level**
    - **Property 10: Migration idempotence**
    - **Validates: Requirements 10.4, 10.5, 10.6**

- [x] 2. Rate list API extensions for category support
  - [x] 2.1 Extend add_rate_item and create category management functions in db.py
    - Modify `add_rate_item()` to accept `category` and `sub_category` parameters
    - Add validation: reject save if category is NULL or not in allowed set [Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal]
    - Add validation: reject save if category is Raw_Material and sub_category not in [Patti, Nihar, Box, Bhawari]
    - Create `update_item_category(item_number, category, sub_category)` function
    - Create `set_item_availability(item_number, is_available)` function
    - Create `get_available_items(category=None)` function that filters by `is_available=True`
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 1.6, 7.1, 7.2_

  - [ ]* 2.2 Write property tests for category assignment and availability
    - **Property 3: Category assignment is mandatory**
    - **Property 4: Raw_Material requires valid sub_category**
    - **Property 5: Availability filtering**
    - **Validates: Requirements 1.2, 1.3, 1.4, 7.1, 7.2**

- [x] 3. Category schema registry and validation engine
  - [x] 3.1 Implement category schema registry in main.py
    - Define `CATEGORIES`, `SUB_CATEGORIES`, and `CATEGORY_SCHEMAS` dictionaries as specified in design
    - Each schema entry defines: fields list, size/qty ranges, line_total formula type, validation rule name
    - _Requirements: 1.1, 8.1, 9.2_

  - [x] 3.2 Implement validation engine in main.py
    - Create `validate_cart_item(item, category)` function dispatching to category-specific rules
    - Chuda/Metal_Bangles: at least one size quantity > 0
    - Kaleera: quantity >= 1 AND color is selected
    - Raw_Material: quantity in [0.01, 99999.99] with max 2 decimal places
    - Seasonal: quantity >= 1
    - Non-numeric/negative size inputs treated as 0
    - Create `validate_order(cart, rate_lookup)` that validates all items, returns first error or None
    - _Requirements: 2.5, 3.4, 4.4, 5.4, 5.5, 6.4_

  - [ ]* 3.3 Write property tests for validation logic
    - **Property 12: Input sanitization for size quantities**
    - **Property 13: Kaleera validation requires quantity and color**
    - **Property 14: Raw_Material quantity range validation**
    - **Property 15: Seasonal notes length validation**
    - **Validates: Requirements 3.4, 4.2, 5.4, 6.2**

- [x] 4. Line total calculation and order summary
  - [x] 4.1 Implement line total calculator in main.py
    - Create `calculate_line_total(item, category, unit_price)` pure function
    - Size-based (Chuda, Metal_Bangles): sum of all size quantities × unit_price
    - Quantity-based (Kaleera, Raw_Material, Seasonal): quantity × unit_price
    - Return value in float, suitable for Indian Rupee display (2 decimal places)
    - _Requirements: 2.4, 3.3, 4.3, 5.3, 6.3_

  - [x] 4.2 Implement order summary builder in main.py
    - Create `build_order_summary(cart, rate_lookup)` function
    - Group items by category in alphabetical order
    - Calculate count and subtotal per category group
    - Calculate grand total as sum of all subtotals
    - Exclude categories with zero items
    - _Requirements: 11.1, 11.2, 11.4_

  - [ ]* 4.3 Write property tests for line total and order summary
    - **Property 1: Size-based line total calculation**
    - **Property 2: Quantity-based line total calculation**
    - **Property 11: Order summary grouping and aggregation**
    - **Validates: Requirements 2.4, 3.3, 4.3, 5.3, 6.3, 11.1, 11.2, 11.4**

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Dynamic order form UI rendering
  - [x] 6.1 Implement dynamic category field renderer in main.py
    - Create `build_category_fields(category, item_data, callbacks)` function returning list of Flet controls
    - Chuda: Color dropdown (on_select), Grind Type dropdown, Box Type dropdown, 5 size quantity TextFields
    - Kaleera: Color dropdown (on_select), quantity TextField (int, 1–9999)
    - Raw_Material: Sub-category read-only label, quantity TextField (float, 0.01–99999.99), unit Dropdown (pieces/kg/meters)
    - Metal_Bangles: Color dropdown (on_select), 5 size quantity TextFields
    - Seasonal: quantity TextField (int, 1–99999), notes TextField (max_length=500)
    - Handle Custom color: show free-text input when "Custom" is selected
    - Use Flet 0.85 patterns: `Dropdown(on_select=...)`, `ft.Row(wrap=True)`
    - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 5.1, 5.2, 6.1, 6.2, 8.1_

  - [x] 6.2 Implement cart row with category-aware item selection
    - When item is selected from dropdown, look up its category from rate_list
    - Render only the fields for that category using `build_category_fields()`
    - When item changes to different category, clear all previous attribute values and re-render fields
    - When no item is selected, show only the item dropdown (no attribute fields)
    - Filter item dropdown to show only items where `is_available=True`
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 7.1_

  - [ ]* 6.3 Write property tests for dynamic field rendering
    - **Property 6: Category determines rendered field set**
    - **Property 7: Category change clears previous attribute values**
    - **Validates: Requirements 8.1, 8.2**

- [x] 7. Order-level vs item-level attribute handling
  - [x] 7.1 Implement order-level fields and Chuda defaults in main.py
    - Display Customer Name, Order Date, Packing Structure, Additional Info at order level (top of form)
    - When order contains only Chuda items, show Color, Grind Type, Box Type at order level
    - Pre-fill each Chuda cart row with order-level defaults (overridable per item)
    - When a non-Chuda item is added, retain order-level values for existing Chuda items but don't apply to non-Chuda items
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [x] 7.2 Extend create_order in db.py to persist item-level attributes
    - Modify `create_order()` to accept and store item-level color, grind_type, box_type, quantity, unit, notes, category per line item
    - Modify `get_order_items()` to return all item-level attributes and category info
    - _Requirements: 10.3_

- [x] 8. Rate list UI updates for category management
  - [x] 8.1 Update Add Item form to include category selection
    - Add Category Dropdown (required, options: Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal) using `on_select`
    - Show Sub-Category Dropdown (Patti, Nihar, Box, Bhawari) only when Raw_Material is selected
    - Validate category is selected before allowing save; show "Category is required" error via SnackBar
    - Validate sub_category for Raw_Material; show "Sub-category is required for Raw Material" error
    - _Requirements: 1.2, 1.3, 1.4_

  - [x] 8.2 Update Edit Item form to allow category/sub_category changes
    - Pre-populate category and sub_category from existing item data
    - Allow changing category and sub_category on edit
    - Add is_available toggle for Seasonal items (show/hide from order form)
    - _Requirements: 1.5, 7.1, 7.2_

- [x] 9. Order summary display with category breakdown
  - [x] 9.1 Implement order summary UI in main.py
    - Display cart summary grouped by category (alphabetical order)
    - Show line item count and subtotal per category group
    - Show grand total as sum of all category subtotals
    - Hide category groups with zero items after item removal
    - When viewing saved orders, display each line item with category label and captured attributes
    - _Requirements: 11.1, 11.2, 11.3, 11.4_

- [x] 10. Seasonal item lifecycle and cart behavior
  - [x] 10.1 Implement seasonal item availability logic
    - Items marked `is_available=False` are hidden from item selection dropdown in Create Order
    - Items marked `is_available=True` reappear in dropdown
    - Retain historical order data for unavailable items (display name/attributes in past orders)
    - If a Seasonal item is marked unavailable while in unsaved cart, retain it in current session
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 11. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties using Hypothesis library
- Unit tests validate specific examples and edge cases
- All UI code uses Flet 0.85 conventions: `Dropdown(on_select=...)`, `ft.Row(wrap=True)`, `page.show_dialog()` for SnackBar, `ft.run()` entry point
- No new files are introduced — all changes go into `db.py` and `main.py`

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "3.1"] },
    { "id": 1, "tasks": ["1.2", "2.1", "3.2"] },
    { "id": 2, "tasks": ["1.3", "2.2", "3.3", "4.1"] },
    { "id": 3, "tasks": ["4.2", "4.3", "7.2"] },
    { "id": 4, "tasks": ["6.1", "8.1"] },
    { "id": 5, "tasks": ["6.2", "6.3", "7.1", "8.2"] },
    { "id": 6, "tasks": ["9.1", "10.1"] }
  ]
}
```
