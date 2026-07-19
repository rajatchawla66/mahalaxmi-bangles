# IMPORTANT WORKFLOWS — Business Logic Reference for Flutter Migration

## 1. Customer Catalogue Flow

```
WhatsApp link / App icon
  -> Customer PIN Login (views/customer.py:12-110)
    -> Customer Dashboard (views/customer.py:159-310)
      -> Category tap -> cache check
        -> If cached: serve from state["customer_category_cache"]
        -> If not: db.get_customer_items_by_category() -> cache in state
      -> Subcategory screen (if sub_categories exist)
      -> Items list with tag filter row (P4)
        -> Tag chips derived from items' tags JSONB
        -> Local filter only — no DB call
        -> In-place rebuild via _rebuild_items()
      -> Item Detail (views/customer.py:662-850)
        -> Image, price, sizes, color
        -> +/- quantity stepper, add to cart
      -> Cart -> Place Order -> db.create_order()
```

**Key migration point:** `_get_category_items()` per-category cache in `state["customer_category_cache"]` — Flutter equivalent uses Riverpod + Isar cache.

## 2. Admin Catalogue Management

```
Admin -> Add Item tab (views/pricing.py:50-250)
  -> Item number (read-only on edit)
  -> Category dropdown -> populates tags
  -> Tags: multi-select chip row (P3) — filtered by category + global
  -> Image picker -> resize_product_image() -> Supabase upload
  -> Save: add_rate_item() or updates to rate_list
  -> Tag save: update_item_tags() for edit, tags param for new

Admin -> Catalogue tab (views/pricing.py:250-400)
  -> Lazy-loaded card grid
  -> Hide/Show availability toggle
  -> Tap card -> edit flow
  -> Multi-select share (planned, not implemented)
```

**Key migration point:** `resize_product_image()` pipeline — replicate in Dart using Image package.

## 3. Order Management

```
Admin -> Create Order (views/orders.py)
  -> Single category: item dropdown -> size/qty/color controls
  -> Mixed category: per-row category picker
  -> Cart-style row management with UID
  -> Sticky bottom: [Add Item] [Save Order]
  -> Save: db.create_order() with header + items
  -> Share PDF: slip_pdf_generator.py -> Supabase upload -> WhatsApp URL

Admin -> Home Dashboard (views/home.py)
  -> Order cards with status badges
  -> Background refresh thread (preserves scroll position)
  -> Confirm/Cancel/Complete actions
  -> Production summary per order
```

## 4. Labour Production Checklist

```
Labour -> Home -> Tap order (views/labour.py)
  -> Image-first cards (260px portrait)
  -> Per-size status pills (pending/prepared/not_available)
  -> Tap cycles through statuses
  -> JSONB column in order_items stores status
```

**Key migration point:** The status cycling logic is simple — straightforward port.

## 5. Tag System

```
Tag Master (views/settings.py:584-909)
  -> Add tag: display name + multi-category chips
  -> Edit tag: dialog with same chips + active/inactive
  -> Delete tag: safety check — refuses if items reference tag
  -> Tags stored in tag_master table + rate_list.tags JSONB

Customer Tag Filter (views/customer.py:532-650)
  -> Tags extracted from loaded items' tags JSONB
  -> Horizontally scrollable chip row
  -> In-place local filter, no DB call
  -> Factory functions avoid late-binding closure bugs
```

## 6. Offline Architecture

```
cache.py:
  sync_all() -> downloads rate_list, categories, orders
  -> writes catalog.json, orders.json, sync_meta.json

views/customer.py:
  _get_category_items():
    -> state["customer_category_cache"] (per-category)
    -> Falls back to cache.get_cached_catalog() on DB failure
    -> Returns (items, was_offline) tuple

db.py:
  _consecutive_failures counter -> is_online()
  connectivity_banner() in utils.py shown on 3+ failures
```

## 7. Image Pipeline

```
Admin uploads image (views/pricing.py):
  FilePicker -> resize_product_image() ->
    EXIF fix -> 4:5 crop -> 1080x1350 -> LANCZOS -> sharpen -> JPEG Q93
  -> httpx PUT to Supabase Storage -> public URL saved

Customer views image:
  image_url from rate_list -> ft.Image(src=url, fit=COVER)
  Offline: local cache path fallback
```

## 8. Session Persistence

```
session_helper.py:
  save_session(state) -> JSON file
  load_session() -> dict or None
  clear_session() -> delete file

Keys: role, username, customer_mobile, customer_id, customer_shop_name
File location: FLET_APP_STORAGE_DATA or "." fallback
```

## 9. Key Business Rules

| Rule | Location | Description |
|------|----------|-------------|
| Customer PIN login | `views/customer.py:38-50` | 8-digit PIN, checked via `get_customer_by_pin()` |
| Price hiding for labour | `main.py:render()` | Prices not shown to labour role |
| Offline detection | `db.py` | 3 consecutive failures = offline state |
| Delete tag safety | `db.py:delete_tag()` | Refuses if items reference the tag |
| Image optimization | `utils.py:resize_product_image()` | 1080x1350, 4:5 crop, sharpen, Q93 |
| Cart uniqueness | `views/orders.py` | UUID per cart row (counter-based) |
