# ARCHITECTURE — Mahalaxmi Bangles Order Manager

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        ANDROID DEVICE                             │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    main.py (Flet UI)                          │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐   │ │
│  │  │  Views   │ │  State   │ │Validation│ │  Navigation  │   │ │
│  │  │ (12+)    │ │  (dict)  │ │  Engine  │ │   System     │   │ │
│  │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬───────┘   │ │
│  │       │             │            │               │           │ │
│  └───────┼─────────────┼────────────┼───────────────┼───────────┘ │
│          │             │            │               │             │
│  ┌───────┼─────────────┼────────────┼───────────────┼───────────┐ │
│  │       ▼             ▼            ▼               ▼           │ │
│  │              db.py (Supabase REST Client)                    │ │
│  │  ┌──────────────────────────────────────────────────────┐   │ │
│  │  │  _get() | _post() | _patch() | _delete()            │   │ │
│  │  │  upload_image() | generate_price_card_url()          │   │ │
│  │  └──────────────────────┬───────────────────────────────┘   │ │
│  │                         │                                    │ │
│  │  ┌─────────────────┐   │   ┌──────────────────────────┐    │ │
│  │  │   cache.py      │   │   │   card_generator.py      │    │ │
│  │  │ (Offline Sync)  │   │   │ (Desktop only - Pillow)  │    │ │
│  │  └────────┬────────┘   │   └──────────────────────────┘    │ │
│  │           │             │                                    │ │
│  │  ┌────────▼────────┐   │                                    │ │
│  │  │  cache/ (local) │   │                                    │ │
│  │  │  ├─catalog.json │   │                                    │ │
│  │  │  ├─orders.json  │   │                                    │ │
│  │  │  └─images/      │   │                                    │ │
│  │  └─────────────────┘   │                                    │ │
│  └─────────────────────────┼────────────────────────────────────┘ │
│                            │                                      │
└────────────────────────────┼──────────────────────────────────────┘
                             │ HTTPS (httpx)
                             ▼
┌────────────────────────────────────────────────────────────────────┐
│                         CLOUD SERVICES                              │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    SUPABASE                                    │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐  │  │
│  │  │ PostgreSQL  │  │   REST API   │  │  Storage (S3)      │  │  │
│  │  │ (6 tables)  │  │  (PostgREST) │  │  product-images/   │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   CLOUDINARY                                   │  │
│  │  ┌─────────────────┐  ┌──────────────────────────────────┐  │  │
│  │  │  Image Upload   │  │  URL-based Text Overlay           │  │  │
│  │  │  (unsigned)     │  │  (price card generation)          │  │  │
│  │  └─────────────────┘  └──────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   WHATSAPP                                     │  │
│  │  Deep link sharing: wa.me/?text=...                           │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
└────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component Architecture

### 2.1 UI Layer (`main.py`)

```
main.py
├── Constants & Config
│   ├── COLOR_OPTIONS, BOX_OPTIONS, PACKING_OPTIONS, GRIND_OPTIONS
│   ├── CATEGORIES (fallback), SUB_CATEGORIES (fallback)
│   ├── CATEGORY_SCHEMAS (validation rules per category)
│   └── _load_categories_from_db() → dynamic category loading
│
├── Validation Engine (pure functions)
│   ├── _safe_int(value) → int
│   ├── validate_cart_item(item, category) → error | None
│   ├── validate_order(cart, rate_lookup) → error | None
│   ├── calculate_line_total(item, category, unit_price) → float
│   └── build_order_summary(cart, rate_lookup) → dict
│
├── main(page: ft.Page) — entry point
│   ├── State initialization
│   ├── Category config loading (_load_category_config)
│   ├── Helper functions (snack, go, go_back, logout)
│   ├── build_app_bar(title, show_back, back_target)
│   ├── build_nav_bar()
│   ├── build_category_fields(category, item_data, callbacks)
│   │
│   ├── View Functions (each returns ft.Control)
│   │   ├── view_login()
│   │   ├── view_home()
│   │   ├── view_order_type_picker()
│   │   ├── view_category_picker()
│   │   ├── view_order_form()
│   │   ├── view_order_detail()
│   │   ├── view_rate_list()
│   │   ├── view_costing()
│   │   ├── view_price_list()
│   │   ├── view_share_catalog()
│   │   ├── view_settings()
│   │   ├── view_manage_categories()
│   │   ├── view_karigar_slip()
│   │   └── view_sync_page()
│   │
│   └── render() — top-level dispatcher
│
└── ft.run(main, assets_dir="product_images")
```

### 2.2 Data Layer (`db.py`)

```
db.py
├── Configuration
│   ├── SUPABASE_URL, SUPABASE_KEY
│   ├── STORAGE_BUCKET = "product-images"
│   └── CLOUDINARY_CLOUD_NAME, CLOUDINARY_UPLOAD_PRESET
│
├── HTTP Helpers (private)
│   ├── _headers() → dict
│   ├── _get(table, params) → list[dict]
│   ├── _post(table, data) → list[dict]
│   ├── _patch(table, params, data) → bool
│   └── _delete(table, params) → bool
│
├── Image Operations
│   ├── upload_image(file_path, item_number) → public_url
│   └── generate_price_card_url(image_url, item_number, selling_price, shop_name) → url
│
├── Categories API
│   ├── get_categories(active_only) → list
│   ├── get_category_names(active_only) → list[str]
│   ├── add_category(name, icon, color, description, sub_categories, order_type) → bool
│   ├── update_category(id, name, icon, color, description, sub_categories, order_type) → bool
│   ├── toggle_category_active(id, is_active) → bool
│   └── delete_category(id) → bool
│
├── Rate List API
│   ├── add_rate_item(item_number, image_path, cost_price, selling_price, category, ...) → bool
│   ├── get_rate_list() → list
│   ├── get_rate_lookup() → dict[item_number → item_info]
│   ├── get_image_lookup() → dict[item_number → image_url]
│   ├── get_item_by_number(item_number) → dict | None
│   ├── get_available_items(category) → list
│   ├── get_all_items_with_cards() → list
│   ├── update_item_prices(item_number, cost_price, selling_price) → bool
│   ├── update_item_category(item_number, category, sub_category) → bool
│   ├── set_item_availability(item_number, is_available) → bool
│   ├── update_item_card_path(item_number, card_path) → bool
│   ├── update_item_image_and_card(item_number, image_path, card_path) → bool
│   ├── update_item_properties(item_number, has_sizes, has_color) → bool
│   ├── save_item_pricing(item_number, cost_price, selling_price, margin_percent) → bool
│   ├── get_priced_items() → list
│   └── get_unpriced_items() → list
│
├── Orders API
│   ├── create_order(header, line_items) → order_id
│   ├── get_orders() → list
│   └── get_order_items(order_id) → list
│
├── Materials API
│   ├── get_materials() → list
│   ├── add_material(name, rate, unit, category) → bool
│   ├── update_material(id, name, rate, unit, category) → bool
│   └── delete_material(id) → bool
│
├── Cost Breakdown API
│   ├── get_cost_breakdown(item_number) → list
│   └── save_cost_breakdown(item_number, rows) → bool
│
└── App Settings API
    ├── get_setting(key, default) → str
    ├── set_setting(key, value) → bool
    ├── get_default_margin() → float
    └── get_labour_cost() → float
```

### 2.3 Cache Layer (`cache.py`)

```
cache.py
├── Path Helpers (private)
│   ├── _cache_dir() → str
│   ├── _images_dir() → str
│   ├── _catalog_path() → str
│   ├── _orders_path() → str
│   └── _meta_path() → str
│
├── Sync
│   └── sync_all(on_progress) → {items_synced, images_synced, orders_synced, errors}
│
└── Read Cache
    ├── is_cache_available() → bool
    ├── get_last_sync_time() → str
    ├── get_cached_catalog() → list
    ├── get_cached_categories() → list
    ├── get_cached_orders() → list
    └── get_cached_image_path(item_number) → str
```

---

## 3. Data Flow Diagrams

### 3.1 Order Creation Flow

```
User Action                    UI (main.py)                    DB (db.py)                 Supabase
─────────────────────────────────────────────────────────────────────────────────────────────────
Tap FAB (+)          →  go("order_type_picker")
                        render() → view_order_type_picker()

Pick "Single"        →  go("category_picker")
                        render() → view_category_picker()

Pick "Chuda"         →  state["selected_category"] = "Chuda"
                        go("order_form")
                        render() → view_order_form()
                                                        →  get_available_items("Chuda")  →  GET /rate_list?category=eq.Chuda
                                                                                         ←  [...items]

Tap "Add Item"       →  state["cart"].append({uid, item_number:"", ...})
                        render_cart()

Select item "CH-786" →  ci["item_number"] = "CH-786"
                        rebuild_category_fields()
                        (shows size steppers + color dropdown)

Fill sizes           →  ci["qty_2_2"] = 3, ci["qty_2_4"] = 2, ...
                        refresh_line_total()
                        refresh_summary()

Tap "Save Order"     →  validate_order(cart, rate_lookup)
                        calculate totals
                                                        →  create_order(header, items)   →  POST /orders {...}
                                                                                         ←  [{order_id: 42}]
                                                                                         →  POST /order_items [{...}]
                        snack("✅ Order #42 saved")
                        go("home")
```

### 3.2 Item Add/Edit Flow (Rate List)

```
User Action                    UI (main.py)                    DB (db.py)                 Cloud Services
──────────────────────────────────────────────────────────────────────────────────────────────────────────
Type item number     →  on_item_lookup()
                                                        →  get_item_by_number("CH-786")  →  GET /rate_list?item_number=eq.CH-786
                        (if exists: populate form)
                        (if new: show "🆕 New item")

Pick image           →  file_picker.pick_files()
                        shutil.copy(src, product_images/_pending.ext)
                        preview_img.content = Image(...)

Tap "Save Item"      →  on_save_and_generate()
                                                        →  upload_image(path, item_no)   →  PUT /storage/v1/object/product-images/CH-786.jpg
                                                                                         ←  public_url
                                                        →  add_rate_item(...) or         →  POST /rate_list {...}
                                                           update_item_prices(...)           PATCH /rate_list?item_number=eq.CH-786

                        (if HAS_CARD_GENERATOR):
                        card_generator.generate_price_card()  →  (local Pillow processing)
                                                              ←  generated_cards/CH-786_card.jpg
                        update_item_card_path(...)
```

### 3.3 Price Card Sharing Flow (Android)

```
User Action                    UI (main.py)                    DB (db.py)                 Cloudinary
──────────────────────────────────────────────────────────────────────────────────────────────────────
Select items         →  selected["CH-786"] = True

Tap "Share WhatsApp" →  share_whatsapp()
                        for each selected item:
                                                        →  generate_price_card_url(      →  GET image from Supabase
                                                              image_url, item_no, sp)    →  POST /v1_1/duwvd4t6j/image/upload
                                                                                         ←  200 OK
                                                                                         ←  transformation_url
                        Build text with card URLs
                        page.launch_url("https://wa.me/?text=...")
```

### 3.4 Offline Sync Flow

```
User Action                    cache.py                        DB (db.py)                 Local Storage
──────────────────────────────────────────────────────────────────────────────────────────────────────
Tap "Sync Now"       →  sync_all(on_progress)
                                                        →  get_rate_list()               →  GET /rate_list
                                                        →  get_categories()              →  GET /categories
                        Save catalog.json                                                →  cache/catalog.json

                                                        →  get_orders()                  →  GET /orders
                        for each order:
                                                        →  get_order_items(id)           →  GET /order_items?order_id=eq.X
                        Save orders.json                                                 →  cache/orders.json

                        for each item with http image:
                        httpx.get(image_url)                                             →  cache/images/{name}.jpg

                        Save sync_meta.json                                              →  cache/sync_meta.json
                        Return result summary
```

---

## 4. State Management

### 4.1 Application State (in-memory dict)

```python
state = {
    "role": "admin" | "labour" | None,
    "username": str | None,
    "current_page": str,          # determines which view to render
    "cart": [                     # order form cart items
        {
            "uid": int,           # unique row identifier
            "item_number": str,
            "category": str,
            "qty_2_2": int, "qty_2_4": int, "qty_2_6": int, "qty_2_8": int, "qty_2_10": int,
            "quantity": int | float | None,
            "unit": str | None,
            "color": str | None,
            "grind_type": str | None,
            "box_type": str | None,
            "notes": str | None,
            "sub_category": str | None,
            "_has_sizes": bool,   # runtime flag from rate_lookup
            "_has_color": bool,   # runtime flag from rate_lookup
        }
    ],
    "cart_uid": int,              # auto-incrementing counter
    "selected_category": str | None,
    "order_mode": "single" | "mixed",
    "detail_order_id": int | None,
    "slip_order_id": int | None,
    "nav_history": [str],         # page name stack (max 20)
}
```

### 4.2 Navigation State Machine

```
login ──────────────────────────────────────────────────────────────────────┐
  │ (pick role)                                                              │
  ▼                                                                          │
home ◄──────────────────────────────────────────────────────────────────────┤
  │         │         │         │         │                                  │
  │ (FAB)   │ (nav)   │ (nav)   │ (nav)   │ (nav)                          │
  ▼         ▼         ▼         ▼         ▼                                  │
order_type  rate_list  costing  share_    settings ──► manage_categories     │
_picker                         catalog              ──► sync_page           │
  │    │                                                                     │
  │    │ (mixed)                                                             │
  │    ▼                                                                     │
  │  order_form ──► (save) ──► home                                         │
  │                                                                          │
  │ (single)                                                                 │
  ▼                                                                          │
category_picker                                                              │
  │                                                                          │
  ▼                                                                          │
order_form ──► (save) ──► home                                              │
                                                                             │
home ──► order_detail ──► karigar_slip                                       │
                                                                             │
(logout) ──► login ─────────────────────────────────────────────────────────┘
```

---

## 5. Database Access Patterns

### 5.1 Supabase REST API (PostgREST)

All queries use PostgREST URL syntax:

| Operation | HTTP Method | URL Pattern | Example |
|-----------|-------------|-------------|---------|
| Select all | GET | `/rest/v1/{table}?{filters}` | `GET /rest/v1/rate_list?category=eq.Chuda&order=item_number.asc` |
| Select columns | GET | `?select=col1,col2` | `GET /rest/v1/rate_list?select=item_number,selling_price` |
| Insert | POST | `/rest/v1/{table}` | `POST /rest/v1/orders` with JSON body |
| Update | PATCH | `/rest/v1/{table}?{filter}` | `PATCH /rest/v1/rate_list?item_number=eq.CH-786` |
| Delete | DELETE | `/rest/v1/{table}?{filter}` | `DELETE /rest/v1/categories?id=eq.5` |
| Upload file | PUT | `/storage/v1/object/{bucket}/{path}` | Binary body with content-type header |

### 5.2 Common Query Patterns

```python
# Filter by equality
_get("rate_list", "category=eq.Chuda&is_available=eq.true")

# Filter with URL encoding (for special chars)
from urllib.parse import quote
_get("rate_list", f"item_number=eq.{quote(item_number)}")

# Order results
_get("orders", "order=order_id.desc")

# Limit results
_get("rate_list", f"category=eq.{quote(cat_name)}&select=id&limit=1")

# Multiple conditions
_get("rate_list", "status=eq.priced&selling_price=gt.0&order=item_number.asc")
```

---

## 6. Security Architecture

### Current State (Development)

```
┌──────────────┐         ┌──────────────────┐
│  Android App │ ──────► │  Supabase        │
│  (anon key)  │         │  (NO RLS)        │
│              │         │  Full read/write  │
└──────────────┘         └──────────────────┘
```

- **Authentication:** None (role picker, no password)
- **Authorization:** Client-side only (admin vs labour views)
- **Database Security:** Anon key has unrestricted access to all tables
- **Storage Security:** Public bucket (anyone with URL can access images)

### Recommended Production Architecture

```
┌──────────────┐         ┌──────────────────────────────────┐
│  Android App │ ──────► │  Supabase                         │
│  (JWT token) │         │  ┌─────────────────────────────┐ │
│              │         │  │  Auth (email/password)       │ │
│              │         │  │  RLS Policies:               │ │
│              │         │  │  - admin: full CRUD          │ │
│              │         │  │  - labour: read orders only  │ │
│              │         │  └─────────────────────────────┘ │
└──────────────┘         └──────────────────────────────────┘
```

---

## 7. Offline Architecture

### Current Implementation

```
┌─────────────────────────────────────────────────┐
│                 ONLINE MODE                       │
│  All reads/writes go directly to Supabase        │
│  No queuing, no conflict resolution              │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│                 OFFLINE MODE                      │
│  Read: cache/catalog.json, cache/orders.json     │
│  Write: NOT SUPPORTED (operations silently fail) │
│  Sync: Manual "Sync Now" button                  │
└─────────────────────────────────────────────────┘
```

### Planned Architecture (Not Implemented)

```
┌─────────────────────────────────────────────────┐
│              OFFLINE-FIRST MODE                   │
│  Read: Always from local cache                   │
│  Write: Queue to local write_queue.json          │
│  Sync: Auto on app start + periodic              │
│  Conflict: Last-write-wins with timestamps       │
└─────────────────────────────────────────────────┘
```

---

## 8. Image Pipeline

```
┌──────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  User picks  │     │  Local copy to   │     │  Upload to Supabase │
│  image from  │ ──► │  product_images/ │ ──► │  Storage bucket     │
│  gallery/cam │     │  _pending.ext    │     │  → public URL       │
└──────────────┘     └──────────────────┘     └─────────┬───────────┘
                                                         │
                                                         ▼
                     ┌──────────────────┐     ┌─────────────────────┐
                     │  Cloudinary URL  │ ◄── │  Upload to          │
                     │  with text       │     │  Cloudinary         │
                     │  overlay         │     │  (for price cards)  │
                     └──────────────────┘     └─────────────────────┘
                              │
                              ▼
                     ┌──────────────────┐
                     │  Share via       │
                     │  WhatsApp        │
                     │  deep link       │
                     └──────────────────┘
```

### Image URL Resolution Priority
1. HTTP/HTTPS URL → use directly (Supabase Storage or Cloudinary)
2. Local file path → check `os.path.exists()` → use if found
3. Cached image → `cache/images/{safe_name}.jpg`
4. Fallback → show placeholder text "No image"

---

## 9. Validation Architecture

### Category Schema Registry Pattern

```python
CATEGORY_SCHEMAS = {
    "CategoryName": {
        "fields": [...],           # UI fields to show
        "sizes": [...],            # available sizes (if applicable)
        "line_total": "formula",   # "sum_sizes_x_price" or "qty_x_price"
        "validation": "rule",      # validation rule name
    }
}
```

### Validation Dispatch

```
validate_order(cart, rate_lookup)
  │
  ├── For each cart item:
  │     │
  │     ├── Check item exists in rate_lookup
  │     ├── Determine category
  │     ├── Set _has_sizes, _has_color flags from rate_lookup
  │     │
  │     └── validate_cart_item(item, category)
  │           │
  │           ├── If item has _has_sizes flag → size-based validation
  │           ├── If item has _has_sizes=False → quantity-based validation
  │           └── Else → use CATEGORY_SCHEMAS[category]["validation"] rule
  │                 │
  │                 ├── "at_least_one_size_gt_zero" → sum(sizes) > 0
  │                 ├── "qty_gte_1_and_color_required" → qty >= 1 AND color != ""
  │                 ├── "qty_gt_zero" → 0.01 <= qty <= 99999.99, max 2 decimals
  │                 └── "qty_gte_1" → qty >= 1
  │
  └── Return first error found, or None
```

### Line Total Calculation

```
calculate_line_total(item, category, unit_price)
  │
  ├── If _has_sizes → sum(all size quantities) × unit_price
  ├── If not _has_sizes → quantity × unit_price
  └── Fallback to CATEGORY_SCHEMAS formula
```

---

## 10. Technology Constraints

### Flet 0.85 on Android

| Capability | Status | Notes |
|-----------|--------|-------|
| UI rendering | ✅ | Flutter-based, native performance |
| HTTP requests | ✅ | httpx works on Android |
| File system | ✅ | Via `FLET_APP_STORAGE_DATA` |
| Camera/Gallery | ✅ | Via `ft.FilePicker` |
| Pillow/PIL | ❌ | Native C extensions don't compile for Android |
| SQLite | ✅ | Available but not used (migrated to Supabase) |
| Background tasks | ❌ | No threading/async worker support |
| Push notifications | ❌ | Not available in Flet 0.85 |
| Deep links | ✅ | `page.launch_url()` for WhatsApp |

### httpx on Android
- Synchronous calls only (no async in Flet's event loop easily)
- Timeout set to 10s for queries, 30s for uploads
- All exceptions caught silently (returns empty/False)

---

## 11. Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT                                    │
│                                                                   │
│  Developer Machine (Windows)                                      │
│  ├── flet run main.py (desktop preview)                          │
│  ├── flet build apk (generates APK)                              │
│  └── Direct Supabase access (same credentials)                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCTION                                     │
│                                                                   │
│  Android APK (sideloaded or Play Store)                          │
│  ├── Bundled Python + Flet runtime                               │
│  ├── assets/product_images/ bundled                              │
│  ├── Runtime storage: FLET_APP_STORAGE_DATA                      │
│  └── Network: Supabase REST API + Cloudinary                     │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Build Command
```bash
flet build apk
```
This generates a Flutter project in `build/` and compiles to APK with embedded Python interpreter.
