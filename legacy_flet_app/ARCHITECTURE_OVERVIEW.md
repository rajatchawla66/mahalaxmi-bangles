# ARCHITECTURE OVERVIEW — Mahalaxmi Bangles Order Manager (Flet v1)

> **Purpose:** Reference document for Flutter migration. Captures the complete architecture of the existing Flet app.

## Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| UI Framework | Flet 0.28.3 | Python-on-Flutter bridge |
| Language | CPython 3.11 | In venv at `venv\` |
| HTTP Client | httpx | Lightweight, works on Android |
| Database | Supabase (PostgreSQL) | REST API via `db.py` |
| Image Storage | Supabase Storage | Public bucket `product-images` |
| Offline Cache | Local JSON files (`cache/`, `cache.py`) | Full-table sync |
| PDF | fpdf2 + Pillow | Karigar slip generation |
| Image Processing | Pillow | Resize, crop, sharpen in `utils.py` |

## Architecture Diagram

```
main.py (entry point, routing, render, state)
  |
  ├── views/
  │   ├── auth.py          — Login / role selection
  │   ├── home.py          — Admin & Labour dashboard
  │   ├── orders.py        — Order create/detail/slip
  │   ├── pricing.py       — Add Item, Catalogue, Costing
  │   ├── settings.py      — Settings, Tag Master
  │   ├── customer.py      — Customer PIN login, catalogue, cart
  │   ├── customers.py     — Admin Manage Customers
  │   ├── labour.py        — Labour production checklist
  │   └── archive.py       — Completed/archived orders
  │
  ├── db.py                — Supabase REST API (httpx)
  ├── cache.py             — Offline caching
  ├── utils.py             — Image processing, helpers
  ├── session_helper.py    — Session persistence
  ├── slip_pdf_generator.py — PDF generation (fpdf2)
  └── main.py              — Navigation, state, render
```

## Key Architectural Patterns

### 1. Navigation
- Single-view replacement (`page.views.clear()` + rebuild)
- Interceptor view at index 0 prevents Android back-button minimize
- `go()` pushes to `nav_history`, `go_back()` pops
- `BACK_MAP` dict for non-linear navigation (e.g., back from tag_master -> settings)

### 2. State Management
- All state in `page.state` dict (Flet's built-in)
- Persisted via `session_helper.py` (JSON file, 3 roles)
- No `page.client_storage` (unsupported on Android)

### 3. Database Layer (`db.py`)
- 4 wrappers: `_get()`, `_post()`, `_patch()`, `_delete()`
- All return parsed JSON or empty list/False on error
- Connectivity tracking: `_consecutive_failures` counter, `is_online()`
- Raise errors only in specific paths (e.g., `get_customer_by_pin(raise_errors=True)`)

### 4. Offline Cache (`cache.py`)
- `sync_all()`: full download of rate_list, categories, orders -> `catalog.json`, `orders.json`
- `get_cached_catalog()`: returns items with image path fallback
- Images downloaded once, skip if local path exists

### 5. Image Pipeline (`utils.py`)
- `resize_product_image()`: EXIF fix, 4:5 center-crop, 1080x1350, LANCZOS, sharpen, JPEG Q93

## File Map

| File | Lines | Purpose | Migration Sensitivity |
|------|-------|---------|----------------------|
| `main.py` | ~1000 | Entry point, routing, state, render, AppBar, NavBar | **HIGH** - navigation patterns |
| `db.py` | ~850 | Supabase REST CRUD | **HIGH** - all API calls |
| `views/customer.py` | ~1400 | Customer flows | HIGH |
| `views/pricing.py` | ~800 | Add Item, Catalogue, Costing | HIGH |
| `views/orders.py` | ~1100 | Order create/detail/slip | HIGH |
| `views/settings.py` | ~920 | Settings, Tag Master, categories | MEDIUM |
| `views/home.py` | ~350 | Admin/Labour dashboard | MEDIUM |
| `views/customers.py` | ~200 | Admin customer management | LOW |
| `views/labour.py` | ~250 | Labour checklist | LOW |
| `views/archive.py` | ~30 | Archive orders | LOW |
| `views/auth.py` | ~50 | Login | LOW |
| `utils.py` | ~150 | Helpers, image processing | MEDIUM |
| `cache.py` | ~200 | Offline cache | MEDIUM |
| `session_helper.py` | ~50 | Session persistence | LOW |
| `slip_pdf_generator.py` | ~300 | Karigar slip PDF | LOW |
