# PROJECT MEMORY — Mahalaxmi Bangles Order Manager

> Read this file **completely** at the START of every CLI session.
> After every significant change, update the relevant sections.
> After every session ends, update Section 9 (Session Log).

---

## 1. PROJECT OVERVIEW

**App Name:** Mahalaxmi Bangles Order Manager  
**Business Context:** Wholesale Bridal Chuda & Bangles Order Management for a small business  
**Target Users:**
- **Admin** — Business owner: creates orders, manages rate list, prices items, shares catalogs
- **Labour** — Workshop worker: views orders and karigar (artisan) slips, no access to prices
- **Customer** — Shop owner: browses categorized catalogue, adds items to cart, places orders

**Tech Stack:**
- **UI Framework:** Flet (Python-on-Flutter) **0.28.3**
- **Python:** CPython 3.11 (in venv at `venv\`)
- **HTTP Client:** httpx (lightweight, works on Android)
- **Database:** Supabase (PostgreSQL) via REST API
- **Image Storage:** Supabase Storage (public bucket: `product-images`)
- **Price Card Generation:** Cloudinary (text overlay transformations)
- **Offline Cache:** Local JSON files + downloaded images
- **PDF Generation:** fpdf2 + Pillow
- **APK Build:** GitHub Actions CI (Windows local builds broken)

**Git / CI:**
- **Remote:** `https://github.com/rajatchawla66/mahalaxmi-bangles.git`
- **Branch:** `main`
- **CI endpoint:** https://github.com/rajatchawla66/mahalaxmi-bangles/actions
- **CI Token:** Classic PAT with `repo` + `workflow` scopes (regenerated June 8, 2026 — stored in git remote URL, removed from all git history)
- **Latest version:** v1.0.18 (build 44+)

---

## 2. FILE STRUCTURE

| File | Purpose | Sensitivity |
|------|---------|-------------|
| `main.py` | Entry point, navigation (`go`, `go_back`, `render`), state management, exit dialog, AppBar, NavBar | **HIGH** — most frequently modified |
| `db.py` | Supabase REST API layer — all CRUD operations via httpx | **HIGH** — do not touch casually |
| `utils.py` | Common helper functions | Low |
| `cache.py` | Offline caching logic for database sync | Low |
| `session_helper.py` | Session save/load/clear for all roles | Low (created June 8, 2026) |
| `slip_pdf_generator.py` | Karigar slip PDF generation (fpdf2, maroon/gold card layout, image thumbnails, sizes table, multi-page) | Low |
| `views/auth.py` | Role selection / login screen | Low (pick_role saves session for admin/labour) |
| `views/home.py` | Admin/Labour dashboard — order list | Low (has background fetch thread) |
| `views/orders.py` | Order creation forms, order detail, karigar slip | Low |
| `views/pricing.py` | Cost calculation, rate lists, margins | Low |
| `views/settings.py` | Admin settings, category management, sync | Low |
| `views/customer.py` | Customer PIN login, catalogue, cart, items, search | Low |
| `views/customers.py` | Admin Manage Customers UI (add/edit/block/PIN mgmt) | Low |
| `sql/create_customers_table.sql` | SQL schema for customers table | Low |
| `pyproject.toml` | Flet build config (excludes `product_images`, `build/`, etc.) | **HIGH** — do not touch casually |
| `.github/workflows/build_apk.yml` | CI workflow — pins Flutter 3.24.0, caches debug keystore | **HIGH** — do not touch casually |
| `PROJECT_MEMORY.md` | This file — single source of truth | Update after every session |

---

## 3. DATABASE SCHEMA (Supabase Cloud)

| Table | Key Columns |
|-------|-------------|
| **`customers`** | `id`, `pin` (unique, 8-digit), `shop_name`, `owner_name`, `mobile`, `city`, `notes`, `is_active`, `created_at`, `last_active_at` |
| **`categories`** | `id`, `name`, `icon`, `color`, `description`, `sub_categories`, `order_type`, `is_active`, `cover_image_url` |
| **`rate_list`** | `item_number`, `image_url`, `cost_price`, `selling_price`, `category`, `sub_category`, `has_sizes`, `has_color`, `card_path`, `is_available`, `margin_percent`, `status` |
| **`orders`** | `order_id`, `customer_name`, `order_date`, `color`, `grind_type`, `box_type`, `packing_structure`, `additional_info`, `total_amount`, `source`, `customer_mobile`, `status` |
| **`order_items`** | `order_id`, `item_number`, `category`, `qty_2_2/2.4/2.6/2.8/2.10`, `quantity`, `unit`, `color`, `grind_type`, `box_type`, `notes`, `unit_price` |
| **`materials`** | `id`, `name`, `rate`, `unit`, `category` |
| **`cost_breakdown`** | `item_number`, `material_id`, `material_name`, `quantity`, `unit`, `rate_per_unit`, `line_total` |
| **`item_materials`** | `item_number`, material assignments |
| **`app_settings`** | `key`, `value` |

---

## 4. TECH STACK & ENVIRONMENT

### Python Environments

| Env | Python | Flet | Location | Status |
|-----|--------|------|----------|--------|
| **venv (primary)** | 3.11.9 | 0.28.3 | `venv\` | ✅ Development & CI-compatible |
| System Python 3.14 | 3.14.5 | 0.28.3 | `C:\Users\rajat\AppData\Local\Python\bin\python.exe` | ⚠️ Was 0.85.2, upgraded to 0.28.3 |
| System Python 3.11 | 3.11.9 | 0.28.3 | `C:\Program Files\Python311\` | ✅ Used for CI-compatible builds |

### Flet Version-Specific Rules (0.28.3)

| Rule | Details |
|------|---------|
| **No `page.client_storage`** | Not supported on Android; use file-based JSON caching (`customer_session.json`) |
| **No `page.window_destroy()`** | Use `page.window.destroy()` instead (note: property, not method) |
| **Dialog API** | Use `page.overlay.append(dlg)` NOT `page.dialog = dlg` |
| **SnackBar API** | Use `page.overlay.append(sb)` |
| **Dropdown** | Use `on_select` NOT `on_change` |
| **No `ResponsiveRow`** | Causes RangeError; use `ft.Row`/`ft.Column` with fixed widths |
| **No `expand=True` inside `ft.Row`** | Triggers grid crash; use fixed widths |
| **ListView in tabs** | Replace with `ft.Column(scroll=ft.ScrollMode.AUTO)` |
| **PopupMenu** | Use parent `on_select` with `data` attribute, NOT child `on_click` |

### Flutter SDK

| Location | Version | Used For |
|----------|---------|----------|
| `C:\Users\rajat\flutter\3.29.2\` | 3.29.2 | Auto-downloaded by Flet CLI (local) — **broken for APK builds** |
| CI (via `subosito/flutter-action@v2`) | 3.24.0 | CI step — **ineffective** — Flet overrides with 3.29.2 |

### Why Flutter 3.24.0 pin in CI is ineffective

Flet CLI 0.28.3 (`flet_cli/commands/build.py:39`) hardcodes `MINIMAL_FLUTTER_VERSION = version.Version("3.29.2")`. The `flutter_version_valid()` method at line 707-730 checks `flutter_version.major == 3 AND flutter_version.minor == 29`. Flutter 3.24.0 (minor=24) fails this check, so Flet **always downloads Flutter 3.29.2** into `$HOME/flutter/3.29.2/` regardless of what's on PATH. There is no `FLET_FLUTTER_HOME` env var in Flet 0.28.3.

The 3.24.0 pin is kept only as a fallback in case Flet's own download mechanism changes. CI builds actually use Flutter 3.29.2 (downloaded by Flet), which somehow works on Linux runners despite the native-assets issue that breaks Windows builds.

### Build Environment Hacks (PowerShell)

```powershell
# Force UTF-8 encoding (required for PowerShell):
$env:PYTHONIOENCODING='utf-8'

# Disable Flet CLI rich output (avoids rendering artifacts):
$env:FLET_CLI_NO_RICH_OUTPUT='true'

# Set console to UTF-8:
chcp 65001

# Flutter native-assets experiment — DOES NOT WORK for packaging step:
$env:DART_VM_OPTIONS='--enable-experiment=native-assets'
```

### Why `DART_VM_OPTIONS` doesn't work
The error occurs during `dart run serious_python:main package` (the "Packaging Python app" step). `DART_VM_OPTIONS` applies to the Dart VM but `--enable-experiment=native-assets` must be a CLI argument to `dart run`, not an env var. Flet CLI hardcodes the `dart run` command without the experiment flag. This flag only affects the later `flutter build` step (via `--flutter-build-args`), which never runs because packaging fails first.

### Why Flutter 3.24.0 in CI
Flutter 3.29.2 ships Dart 3.10+ which enforces `--enable-experiment=native-assets` for Dart packages using native assets (like `objective_c`). Flet's `dart run serious_python:main` packaging step does not pass this flag, causing a build failure. Flutter 3.24.0 (Dart 3.5.x) predates this requirement and builds successfully.

---

## 5. ARCHITECTURE RULES

**Rules that must never be broken:**

1. **Navigation Pattern:** Single-view `page.views` replacement approach. Always maintain `len(page.views) >= 2` = `[interceptor, content_view]`. The interceptor at index 0 is a dummy `ft.View(route="base_interceptor", controls=[ft.Container()])`.

2. **State Management:** All global state in `page.state` dict. State resets occur explicitly in `logout()`. Do NOT use `page.client_storage` or `page.shared_preferences`.

3. **Android Back Interception:** `on_view_pop_handler` calls `go_back()` — does NOT pop views. `render()` manages all view creation/destruction atomically.

4. **Dialog API:** Always use `page.overlay.append(dlg)` for AlertDialogs and SnackBars. Never use `page.dialog = dlg`.

5. **Exit Dialog:** `show_exit_dialog()` in `main.py:590`. Guard against stacking: check `any(isinstance(c, ft.AlertDialog) and getattr(c, 'open', False) for c in page.overlay)`. Cancel calls `render()` to restore content. Exit calls `page.window.destroy()`.

6. **`render()` Guard:** `render()` has an early return if any AlertDialog is open in overlay. This prevents background threads (e.g., `views/home.py` fetch) from corrupting view state during dialog display.

7. **APK Build:** Local Windows builds are broken. Always build via GitHub Actions CI. Never change Flutter version in CI without testing.

8. **Build Config:** Use `[tool.flet.app]` in `pyproject.toml`. Do NOT use `flet_build.yaml`.

9. **Encoding:** Use `encoding='utf-8'` for all file operations.

---

## 6. CURRENT ARCHITECTURE

### Navigation System

```
Login (Premium Brand Landing Page)
  ├── Customer PIN → customer_dashboard
  ├── Admin (small link) → home
  └── Labour (small link) → home

Forward Navigation (go):
  - Pushes current page to nav_history (stack)
  - Root pages (login, home, customer_dashboard) clear nav_history
  - Shows loading spinner, calls render()

Back Navigation (go_back):
  ├── nav_history has entries → pop → render()
  ├── Root pages (home, customer_dashboard, login) → show_exit_dialog()
  │     ├── Cancel → close dialog → render() restores content
  │     └── Exit → close dialog → page.window.destroy()
  ├── BACK_MAP has entry → navigate to target → render()
  └── Otherwise → show_exit_dialog()

Back Button (on_view_pop_handler):
  - Just calls go_back() — does NOT pop views or manage Navigator
```

### page.views Invariant

```
ALWAYS: page.views = [interceptor_view, content_view]  (len >= 2)

render():
  page.views.clear()
  page.views.append(ft.View(route="base_interceptor", controls=[ft.Container()]))
  view = ft.View(route="/", controls=[body], appbar=..., navigation_bar=...)
  page.views.append(view)
  page.update()

This ensures Android's back button always triggers on_view_pop instead of
minimizing the app (which happens when len(page.views) == 1).
```

### State Dictionary

```python
state = {
    "role": None,                    # "admin" | "labour" | "customer"
    "username": None,
    "current_page": "login",         # login | home | customer_dashboard | etc.
    "nav_history": [],               # stack for back navigation
    "cart": [],
    "cart_uid": 0,
    "selected_category": None,
    "order_mode": "single",
    "detail_order_id": None,
    "slip_order_id": None,
    "customer_selected_category": None,
    "customer_selected_subcategory": None,
    "customer_subcategories": [],
    "customer_search_query": "",
    "customer_selected_item": None,
    "customer_cart": [],
    "customer_mobile": None,
    "customer_full_catalogue": None,
    "customer_categories": None,
    "customer_id": None,
    "customer_shop_name": None,
}
```

### Session Persistence

- **File:** `customer_session.json` in `FLET_APP_STORAGE_DATA` or `"."`
- **Format:** `{"role": "admin"|"labour"|"customer", "username": "...", "customer_mobile": "...", "customer_id": "...", "customer_shop_name": "..."}`
- **Helper module:** `session_helper.py` — `save_session(state)`, `load_session()`, `clear_session()`
- **Backward compatible:** Old customer-only sessions (no `role` field, just `name`/`mobile`) restored as customer
- **Save triggers:** Admin/labour saved on role pick in `views/auth.py`. Customer saved in `views/customer.py` on PIN login success.
- **Restore:** On app start in `main.py` — routes to correct dashboard based on role + loads `customer_id`/`customer_shop_name`.
- **Clear:** On `logout()` — deletes session file, resets state (including customer_id/shop_name/cart) to login.

### Exit Dialog

```python
show_exit_dialog() in main.py:590

API: page.overlay.append(dlg)
Stacking guard: checks if any open AlertDialog exists in overlay
Cancel: closes dialog → calls render() to restore content views
Exit: closes dialog → calls page.window.destroy()
```

---

## 7. BUG HISTORY LOG

---

### BUG-020: Place Order button silently dead — NameError: name 'datetime' is not defined
| Field | Detail |
|-------|--------|
| **Date** | June 10, 2026 |
| **Symptom** | Customer adds items to cart, taps "Place Order" — nothing happens. No snackbar, no navigation, no order created. Button appears dead. |
| **Root Cause** | `db.py:470` uses `datetime.datetime.utcnow().isoformat()` in `create_order()` but `import datetime` was never present at module level. A `NameError` is raised inside the Flet event handler, which Flet silently swallows — user sees no feedback. |
| **Fix** | Added `import datetime` at the top of `db.py` (line 20). Removed redundant local `import datetime` from `set_order_status()` and `set_customer_last_active()` since the module-level import now covers all call sites. |
| **Files** | `db.py:20` (added import), `db.py:568` (removed local import), `db.py:845` (removed local import) |
| **Lesson** | Always ensure module-level imports cover all usage sites. Flet silently swallows exceptions in event callbacks — must surface errors manually or add comprehensive try/except. |

---

### BUG-019: Customer catalogue loads stale memory/cache data after logout/login or app restart
| Field | Detail |
|-------|--------|
| **Date** | June 10, 2026 |
| **Symptom** | After logout → re-login, customer dashboard shows old catalogue. Manual refresh (🔄) required to see latest data. On app restart, stale cache served instead of fresh Supabase data. |
| **Root Cause** | Two bugs combined: (1) `logout()` did NOT clear `customer_full_catalogue` or `customer_categories` from state — guard `if state.get("customer_full_catalogue") is None` found stale data and skipped loading entirely. (2) `view_customer_dashboard()` checked local cache (`cache.is_cache_available()`) FIRST, Supabase only if cache missing — stale `catalog.json` always preferred over fresh Supabase on app restart. |
| **Fix** | (a) `logout()` now clears all 6 catalogue state keys (`customer_full_catalogue`, `customer_categories`, `customer_selected_category`, `customer_selected_subcategory`, `customer_search_query`, `customer_selected_item`). (b) Dashboard load priority reversed: try Supabase first → fallback to cache only on exception → empty lists if both fail. (c) PIN login `do_login()` clears all catalogue keys before navigating. (d) Session restore sets catalogue state to `None` for fresh fetch. (e) "Add Again" lazy-load uses same Supabase-first priority. |
| **Files** | `main.py`, `views/customer.py` |
| **Lesson** | Always clear all domain-specific state keys in `logout()`. Cache should be fallback, not primary. Guard checks must account for stale in-memory state. |

---

### BUG-018: CI Flutter download corrupted — EOFError during flet build
| Field | Detail |
|-------|--------|
| **Date** | June 10, 2026 |
| **Symptom** | `EOFError: Compressed file ended before the end-of-stream marker was reached` during `flet build apk`. Flet downloads its own Flutter 3.29.2 but the ~700MB archive is truncated. |
| **Root Cause** | Flet CLI 0.28.3 (`flet_cli/commands/build.py:39`) hardcodes `MINIMAL_FLUTTER_VERSION = "3.29.2"`. The `flutter_version_valid()` method (line 707-730) requires **exact major.minor match** (`major==3 AND minor==29`). Flutter 3.24.0 (pinned in CI) fails this check. Flet downloads Flutter 3.29.2 every build. The download from `storage.googleapis.com` was truncated — transient GitHub runner network issue. |
| **Fix** | Wrapped `flet build apk` in a retry loop (max 2 attempts). On failure, cleans `$HOME/flutter/` and `$HOME/flutter_*.{zip,tar.xz}` partial downloads, then retries. `download_with_progress()` always re-downloads (no caching), so retry is safe. |
| **Files** | `.github/workflows/build_apk.yml` |
| **Lesson** | Flet 0.28.3 ALWAYS overrides the system Flutter with its own download of 3.29.2. The `subosito/flutter-action` pin to 3.24.0 is ineffective — kept only as fallback. Any network glitch during the large download can corrupt the archive. Retry with cleanup is the safest fix. |

---

### BUG-001: APK Build fails with objective_c native-assets error
| Field | Detail |
|-------|--------|
| **Date** | June 7, 2026 |
| **Symptom** | `flet build apk` fails during "Packaging Python app": `Package(s) objective_c require the native assets feature to be enabled.` |
| **Root Cause** | Flet 0.28.3 hardcodes Flutter 3.29.2 (Dart 3.10+). Transitive dep `objective_c 9.4.1` requires `--enable-experiment=native-assets`. Flet CLI's `dart run serious_python:main` doesn't include this flag. `DART_VM_OPTIONS` env var doesn't apply at the packaging step. |
| **Fix** | Moved builds to GitHub Actions CI with Flutter 3.24.0 (pre-native-assets era). Also tested `--template-ref 0.27.0` (packaging passes, Gradle fails — `webview_flutter_android` Dart version mismatch). |
| **Files** | `.github/workflows/build_apk.yml`, `.gitignore` |
| **Lesson** | Flet 0.28.3 APK builds are broken on any system with Flutter 3.29.2+. Always pin an older Flutter version via CI. |

---

### BUG-002: White screen on root back press (Original)
| Field | Detail |
|-------|--------|
| **Date** | June 2026 |
| **Symptom** | Pressing hardware back on home screen causes a white screen on Android. |
| **Root Cause** | Native Flet routing conflict when manually pushing a dummy `ft.View` into `page.views`. |
| **Fix** | Switched to standard `page.controls.clear()` rendering logic. |
| **Files** | `main.py` |
| **Note** | This fix was later superseded by BUG-003's approach (page.views interceptor). |

---

### BUG-003: Android hardware back button white screen (Recurrence)
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Back on root screen minimizes/closes app. Reopen shows white screen requiring force stop. |
| **Root Cause** | `render()` called `page.views.clear()` without re-adding interceptor. After render, `page.views` had exactly 1 view. Flutter minimized app on back press (1 view). On reopen, Flutter restored broken view state → white screen. |
| **Fix** | `render()` now recreates the interceptor at `page.views[0]` after clear, so `page.views = [interceptor, content]` (len >= 2) at all times. |
| **Files** | `main.py` |
| **Lesson** | Any `page.views.clear()` must immediately re-add interceptor. The interceptor must ALWAYS be at index 0. |

---

### BUG-004: APK Size Ballooning by 15MB
| Field | Detail |
|-------|--------|
| **Date** | June 2026 |
| **Symptom** | Flet APK build size bloated unnecessarily. |
| **Root Cause** | Flet compiler silently grabbed generated cache folders (e.g., `product_images`). |
| **Fix** | Added `exclude` arrays in `pyproject.toml` and `.gitignore`. |
| **Files** | `pyproject.toml`, `.gitignore` |
| **Lesson** | Always maintain strict exclusion lists for dynamically generated assets. |

---

### BUG-005: Admin/Labour logout button not working
| Field | Detail |
|-------|--------|
| **Date** | June 2026 |
| **Symptom** | Logout in AppBar popup menu silently fails on Home tab. |
| **Root Cause** | Destroying AppBar synchronously while PopupMenuItem overlay is closing causes Flutter to freeze/drop the routing update. |
| **Fix** | Replaced child `PopupMenuItem.on_click` with parent-level `PopupMenuButton.on_select` + `data="logout"`. |
| **Files** | `main.py` |
| **Lesson** | Never rebuild the whole page from a child popup-menu item callback on Android; use the menu button selection event instead. |

---

### BUG-006: AppBar PopupMenu logout works only from Settings tab
| Field | Detail |
|-------|--------|
| **Date** | June 7, 2026 |
| **Symptom** | Top-right three-dot logout doesn't work on Home tab but works from Settings/Customer dashboard. |
| **Root Cause** | `PopupMenuItem.on_click` path unreliable on Android when triggering full rebuild inside the callback. Previous `threading.Timer` workaround unsafe (mutated Flet state from background thread). |
| **Fix** | `logout_from_popup()` runs only from `PopupMenuButton.on_select`; Logout item carries `data="logout"` with no child `on_click`. |
| **Files** | `main.py` |
| **Lesson** | For Flet 0.28.3 AppBar popup actions, use parent `on_select` + `data` attribute; avoid child item callbacks, timers, and background-thread page updates. |

---

### BUG-007: RangeError (length 12) in Pricing/Costing
| Field | Detail |
|-------|--------|
| **Date** | June 7, 2026 |
| **Symptom** | RangeError flooded console when opening Costing tab or detail view. |
| **Root Cause** | Nested `ft.ListView`, `ft.Tabs`, and `ft.ResponsiveRow` triggered 12-column grid calculation error. `expand=True` in `ft.Row` children was primary trigger. |
| **Fix** | Removed all `ResponsiveRow` and `expand=True` from Row children. Replaced with `ft.Row`/`ft.Column` + fixed widths. Replaced top-level `ft.ListView` with `ft.Column(scroll=ft.ScrollMode.AUTO)`. |
| **Files** | `views/pricing.py`, `views/settings.py`, `views/orders.py` |
| **Lesson** | Avoid `ResponsiveRow` and `expand=True` inside `ft.Row` in Flet 0.28.3. |

---

### BUG-008: Session restore only worked for Customer
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Admin and Labour sessions not persisted across app restarts. |
| **Root Cause** | Session save only implemented in `views/customer.py` (customer name entry). Auth `pick_role` for admin/labour never saved. |
| **Fix** | Created `session_helper.py` (`save_session`/`load_session`/`clear_session`). Admin/labour save in `views/auth.py:27`. Restore in `main.py:487-502` handles all roles + backward compat. |
| **Files** | `session_helper.py` (new), `main.py`, `views/auth.py` |
| **Lesson** | All roles need session persistence, not just customer. Keep helper module clean. |

---

### BUG-009: Exit dialog not rendering on Android
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Exit confirmation dialog never appeared on Android. |
| **Root Cause** | Used `page.dialog = dlg` (deprecated pre-0.25 API). Flet 0.28.3 requires `page.overlay.append(dlg)`. All existing dialogs in codebase use overlay. |
| **Fix** | Changed to `page.overlay.append(dlg)`. |
| **Files** | `main.py` |
| **Lesson** | Always check codebase conventions for API usage. Don't assume `page.dialog` works. |

---

### BUG-010: White screen after exit dialog (double-back)
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Double-back after exit dialog minimizes app. Reopen = white screen. |
| **Root Cause** | `on_view_pop_handler` unconditionally popped content view (`page.views.pop()`), reducing `len(page.views)` to 1. Next back press → Flutter minimizes (only 1 view). |
| **Fix** | Removed `page.views.pop()` from `on_view_pop_handler`. Now just calls `go_back()`. Added defensive guard in `show_exit_dialog()`: if `len(page.views) < 2`, append placeholder. |
| **Files** | `main.py` |
| **Lesson** | Never pop views in `on_view_pop_handler`. Let `go_back()`/`render()` manage views entirely. |

---

### BUG-011: APK package conflict on every install
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | "Package conflicts with existing package" — must uninstall and reinstall each time. |
| **Root Cause** | GitHub Actions runners are ephemeral. Each build generates a new random debug keystore, signing APK with a different certificate. Android rejects certificate mismatch. |
| **Fix Attempt 1** | Committed deterministic debug keystore (`android/debug.keystore`) to repo. CI copies it to `~/.android/` before `flet build apk`. |
| **Fix Attempt 2** | Added `fetch-depth: 0` to checkout step so `git rev-list --count HEAD` returns actual commit count for versionCode. |
| **Fix — Final** | **Replaced debug keystore with proper release signing via GitHub Secrets.** Removed `android/debug.keystore`. CI now decodes keystore from `ANDROID_KEYSTORE_BASE64` secret and passes `--android-signing-key-store` flags to `flet build apk`. One-time uninstall required, then all future builds use the same permanent key. |
| **Status** | ✅ **Fixed.** First build after this fix requires uninstalling old app once. Subsequent builds will use the same permanent release keystore (SHA-256: `EB:AA:3E:11:00:76:42:7E:A7:7E:08:61:67:DE:D0:11:5A:60:4D:58:0A:38:79:79:6D:8F:3B:80:C6:A2:4D:B6`, alias: `mahalaxmi`, valid until 2051). |
| **Files** | `.github/workflows/build_apk.yml`, `.gitignore`, `android/debug.keystore` (del) |

---

### BUG-012: Exit dialog + background thread causes grey screen
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Exit dialog appears briefly, then screen turns grey after a few seconds. Subsequent back presses don't show dialog; double-back minimizes app. |
| **Root Cause** | `views/home.py:62` background fetch calls `page.app_render()` (→ `render()`) from a daemon thread ~2-5s after dialog appears. `render()` does `page.views.clear()` + re-adds views while the overlay dialog is open, corrupting Flutter's renderer (dialog scrim remains, views replaced). |
| **Fix** | Added guard at top of `render()`: `if any(isinstance(c, ft.AlertDialog) and getattr(c, 'open', False) for c in page.overlay): return`. Simplified `show_exit_dialog()`: removed `on_dismiss` (unreliable), Cancel explicitly calls `render()`. |
| **Files** | `main.py` |
| **Lesson** | `render()` must never run while a dialog is open. Background threads must not interfere with UI state. |

---

### BUG-013: Exit button in dialog does not close app
| Field | Detail |
|-------|--------|
| **Date** | June 8, 2026 |
| **Symptom** | Exit dialog appears correctly on back press. Clicking "Exit" dismisses the dialog but app stays open, no change. |
| **Root Cause** | `page.window.destroy()` is not implemented for Android in Flet 0.28.3 (known upstream bug — flet-dev/flet#4808). The attribute is accepted silently by Flet but the Flutter-side handler never acts on it. |
| **Fix** | Use `page.platform == ft.PagePlatform.ANDROID` for Android detection in `handle_exit`. On Android, call `os._exit(0)` to terminate the Python subprocess. On desktop, fall back to `page.window.destroy()`. |
| **Files** | `main.py:601-611` (show_exit_dialog → handle_exit handler) |
| **Note** | Previous attempt used `ANDROID_ARGUMENT` env var which is NOT set by Flet on Android. `page.platform` is set by the Flutter client during session handshake (`local_connection.py:44`) and is Flet's own mechanism for platform detection. Desktop path unchanged. |

---

### BUG-014: Catalogue page does not scroll
| Field | Detail |
|-------|--------|
| **Date** | June 9, 2026 |
| **Symptom** | Catalogue item grid is cut off at bottom of screen; cannot scroll to see all items. |
| **Root Cause** | The outer `ft.Column(scroll=ft.ScrollMode.AUTO)` in `view_catalogue()` was missing `expand=True`, so it sized to its content rather than filling the View height, and scroll never engaged. |
| **Fix** | Added `expand=True` to the outer Column in `view_catalogue()` (`views/pricing.py:408`). The Column now fills available space and scroll activates on overflow. |
| **Files** | `views/pricing.py:408` |

### BUG-015: Home auto-scrolls to top on background refresh
| Field | Detail |
|-------|--------|
| **Date** | June 9, 2026 |
| **Symptom** | After background thread fetches new orders, the home page scrolls back to the top, losing the user's scroll position. |
| **Root Cause** | `fetch_latest_data()` background thread called `page.app_render()`, which destroys and rebuilds the entire View, resetting the scroll position to 0. |
| **Fix** | Extracted order card building into `_build_order_cards()`. Created a persistent `_cards_column` reference. Background thread now does `_cards_column.controls = _build_order_cards(latest); page.update()` instead of `page.app_render()`. Delete handler also uses the same in-place update. Removed old duplicate `fetch_latest_data` that was still calling `app_render()`. |
| **Files** | `views/home.py:42-69` (delete old function), `views/home.py:75+` (_build_order_cards, _cards_column) |

### BUG-016: Editing an item creates a duplicate instead of updating
| Field | Detail |
|-------|--------|
| **Date** | June 9, 2026 |
| **Symptom** | When editing a catalogue item via Admin > Catalogue > tap card, the item is saved as a NEW record instead of updating the existing one. |
| **Root Cause** | The `item_number` TextField was editable during edit. When the user changed the item number, the save flow called `db.get_item_by_number()` which found no match, so it fell into the INSERT path instead of UPDATE. |
| **Fix** | Set `item_tf.read_only = True` when `state["edit_item"]` is present (`views/pricing.py:168`). Reset to `False` after save (`views/pricing.py:233`). The item number is locked during edit, so the lookup always finds the existing record and takes the UPDATE path. |
| **Files** | `views/pricing.py:168, 233` |

---

### BUG-017: Costing Detail RangeError 12 — invisible ListView child causes index mismatch
| Field | Detail |
|-------|--------|
| **Date** | June 9, 2026 |
| **Symptom** | Admin → Costing → tap item: costing detail opens with all fields visible, but bottom shows infinite grey scroll. Console repeatedly prints `RangeError (length): Invalid value: Not in inclusive range 0..11: 12`. |
| **Root Cause** | `custom_margin_row` is a direct child of `ft.ListView` with `visible=False`. Flet's ListView builder computes `itemCount` from total children (13) but filters invisible controls when building visible widgets (12). When Flutter tries to build child index 12 (the Save button), the visible array only has 12 elements (0-11), throwing RangeError. |
| **Fix** | Wrapped the entire bottom section (Divider, margin text, switch, custom_margin_row, sp_preview, Save button) into a `ft.Column`. Now `custom_margin_row` is nested 1 level deep — the ListView's direct child is the Column (always visible), so the child count stays consistent. |
| **Files** | `views/pricing.py:751` |
| **Lesson** | Never put a `visible=False` control directly inside a `ft.ListView`. Wrap invisible controls in a `ft.Column` or `ft.Container` first. |

---

## 8. FEATURES STATUS

### ✅ Working
- Customer Dashboard & Catalogue
- Admin Settings & Category Management
- Sync & Offline Capabilities (local JSON cache)
- Order Creation & Full Flow
- APK Build via GitHub Actions CI (Flutter 3.24.0, Python 3.11, Flet 0.28.3)
- Navigation & Hardware Back Button (interceptor preserved, no view popping)
- Session Restore for All Roles (admin, labour, customer)
- Exit Confirmation Dialog — Cancel works, Exit closes app (fixed BUG-013 via `page.platform` detection + `os._exit(0)` on Android)
- Background Fetch Guard (render skips when dialog open)
- Consistent APK Signing (committed debug keystore at android/debug.keystore — no more uninstall/reinstall)
- Karigar Slip PDF Share — generates styled PDF (maroon/gold card layout, image thumbnails, sizes boxes, multi-page), uploads to Supabase Storage with `x-upsert`, opens WhatsApp with public link. Direct local PDF attachment via WhatsApp not supported in current Flet setup.
- Customer Item Detail UI — premium B2B catalogue layout: rounded image card, product info card (item# + category badge + price), compact +/- quantity stepper rows replacing oversized TextFields, live order summary card, sticky bottom CTA bar with qty preview.
- Customer Catalogue Redesign — portrait image-first card layout: 220px hero image (COVER fill), subtle item code, large green price, right-aligned View button. Removed side-by-side layout, "Multiple Sizes" chip, and metadata badges. Social-commerce browsing feel.
- Customer Dashboard Phase 3 — portrait category tiles (3:4 ratio, 2-per-row), cascading image fallback (cover → first item → monogram), no ResponsiveRow/wrap.
- Admin Navigation Restructure — nested Items tab (Add/Edit + Catalogue ft.Tabs) replaced with two standalone NavBar destinations: Add Item and Catalogue. 5-tab NavBar: Home, Add Item, Catalogue, Costing, Settings.
- Catalogue page scroll (BUG-014) — outer Column has `expand=True`, Catalogue scrolls on overflow.
- Home scroll position preserved on background refresh (BUG-015) — in-place `_cards_column.controls` update instead of `page.app_render()`.
- Edit item no longer creates duplicate (BUG-016) — `item_tf.read_only=True` during edit locks item number.
- Admin Settings UI organized — 3 grouped cards (Catalogue & Categories, Materials & Pricing, Account) with section titles and subtitles. Data & Sync card removed — Offline Sync UI hidden from users. `sync_page` route/code kept as developer fallback.
- Dead Cloudinary price-card code removed — deleted `generate_price_card_url()`, `update_item_card_path()`, and `CLOUDINARY_*` constants from `db.py`. Steps A+B only.
- Costing Detail RangeError 12 (BUG-017) — wrapped bottom section in `ft.Column` so `visible=False` on custom margin row doesn't corrupt ListView child count.
- Item Visibility Toggle — Hide/Show button in Admin Catalogue cards; customer cache filters `is_available=true` at load time.
- Customer Manual Catalogue Refresh — 🔄 icon in customer AppBar on all catalogue screens. Fetches fresh data from Supabase and updates state in-place.
- Offline Sync UI removed — Sync icon removed from Admin AppBar; Data & Sync card removed from Settings. `view_sync_page()`, route, BACK_MAP, and `cache.py` kept intact as hidden developer fallback.
- Order Status System (Phase 1) — Admin side: `status` column added to orders table; status badge (pending/confirmed/cancelled) on admin Home cards; Confirm/Cancel actions for pending orders; read-only for confirmed/cancelled. `set_order_status()` in db.py.
- Customer PIN Login System (Phases 1-3) — Admin Manage Customers page (add/edit/block, copy PIN, search). 8-digit PIN auto-generation with collision retry. Customer PIN login replaces free-text name entry. `customer_id`/`customer_shop_name` in state + session. Session persists PIN login across restarts. `sql/create_customers_table.sql` for Supabase schema.
- Premium Brand Landing Page — Redesigned login screen as premium jewellery-brand landing page. Cream background, gold accents, maroon CTA, centered layout with logo/firm name/subtitle, gold ornamental dividers (`ft.Row` with gold lines + ✦), GST card, PIN login directly on landing page, 2x2 contact cards (Instagram/WhatsApp/Location/YouTube), heritage trust container, small Admin/Labour text links. Old `view_login()` replaced entirely. `customer_login` route preserved as fallback.

### 🔄 Pending Verification (needs real Android testing)
- Logout button across all roles
- White screen after force-stop/reopen

### ❌ Blocked
- **Local Windows APK Build** — Flutter 3.29.2 + `objective_c` native-assets incompatibility
- **`--template-ref 0.27.0`** — Gradle fails with `webview_flutter_android` Dart version mismatch

---

## 9. CI/CD BUILD PROCESS

### How to build APK
All APK builds run via **GitHub Actions CI**. Local Windows builds are broken and not supported.

**Trigger a build:**
1. Push code to `main` branch (auto-triggers)
2. Or go to https://github.com/rajatchawla66/mahalaxmi-bangles/actions → "Build Android APK" → "Run workflow" (manual trigger)

**Download APK:**
1. Wait for build to complete (~15-25 min)
2. Click the completed workflow run
3. Scroll to **Artifacts** section
4. Download `mahalaxmi-bangles-v1.0.14.zip`
5. Extract to get the `.apk` file

### How to bump version
1. Edit `version.txt` with the new version (e.g., `1.0.14`)
2. Update `PROJECT_MEMORY.md` sections 1 (Latest version), 9 (Session Log)
3. Commit message should mention the new version
4. Push to `main` — CI reads `version.txt` for `--build-version` and uses commit count for `--build-number`

### CI Environment
| Component | Version |
|-----------|---------|
| OS | ubuntu-latest |
| Python | 3.11 |
| Flet | 0.28.3 |
| Flutter | 3.24.0 (pinned via `subosito/flutter-action@v2`) — **ineffective**, Flet overrides with 3.29.2 |
| Java | 17 (Temurin) |
| Signing | Committed `android/debug.keystore` (deterministic, same key every build) |

### Workflow file
`.github/workflows/build_apk.yml` — do not modify unless you understand the Flutter native-assets constraint and Flet's hardcoded `MINIMAL_FLUTTER_VERSION = "3.29.2"`.

### Build retry
The Build APK step has an automatic retry (max 2 attempts). If `flet build apk` fails (e.g. corrupted Flutter download), the script cleans `$HOME/flutter/` and retries. This avoids transient runner storage/network issues.

---

## 10. RISK ASSESSMENT

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| White screen on real Android (back button) | High | Low | No pop in `on_view_pop_handler`; dialog handler restores views via `render()`; `render()` guard prevents background-thread corruption |
| `page.window.destroy()` fails on Android | Medium | Medium | Wrapped in try/except; app stays open if close fails |
| Background thread calls `render()` during dialog | Medium | Low | Guard at top of `render()` skips execution when dialog open |
| Exit dialog not rendering (Flet 0.28.3 overlay API issues) | Medium | Low | Same `page.overlay.append()` pattern as 2 other dialogs in codebase |
| First build after keystore cache miss needs uninstall | Low | Certain (once) | **Resolved** — committed deterministic keystore `android/debug.keystore` guarantees same signing key on every build. |
| Session file path `"."` on Android when `FLET_APP_STORAGE_DATA` unset | Medium | Medium | `os.makedirs()` called; no crash, but session won't survive restart |
| GitHub Actions cache eviction (7-day inactivity) | Low | Low | Rare for active project; if happens, one-time uninstall/reinstall needed |
| Logout fails on real Android device | Medium | Medium | Test all three roles before production release |

---

## 11. QUICK REFERENCE

```bash
# Run locally (desktop):
cd C:\Users\rajat\Labour-receipt
venv\Scripts\activate
flet run main.py

# Trigger CI build:
git push  # OR go to Actions tab → "Run workflow"

# Download APK:
# Actions → latest run → Artifacts → mahalaxmi-bangles-v1.0.13.zip

# Git push (PAT stored in remote URL):
git push

# NEVER store PATs in any file tracked by git. Use remote URL or GitHub CLI.
# To update remote URL with new PAT:
git remote set-url origin https://<PAT>@github.com/rajatchawla66/mahalaxmi-bangles.git

# Encoding workaround (PowerShell):
$env:PYTHONIOENCODING='utf-8'
chcp 65001
```

---

## 12. HOW TO USE THIS FILE

**At the START of every new CLI session:**
1. Read this entire file
2. Understand current architecture, pending issues, and bug history

**During a session:**
- Reference bug history to avoid repeating past mistakes
- Follow architecture rules (Section 5)
- Use Quick Reference (Section 11) for common commands
- **After EVERY tool call that changes code**, immediately update the relevant section in this file before moving to the next task. Do not batch updates at the end.

**After EVERY significant change:**
1. Update the relevant section (bug history, features status, architecture)
2. Keep the new update at the top of the list or note

**After EVERY session ends:**
1. Update Section 9 (Session Log) — just add a brief note at the top
2. Ensure all changes are pushed to GitHub
3. Verify PROJECT_MEMORY.md is updated and accurate

### Session Log

| Date | Work Done | Files Changed | Status |
|------|-----------|---------------|--------|
| June 10, 2026 | Settings screen restructuring — clean 6-item menu replacing inline forms. New settings_margin/settings_materials routes. Removed duplicate get_default_margin() in db.py. | `db.py`, `views/settings.py`, `main.py`, `PROJECT_MEMORY.md` | Complete — pushed |
| June 10, 2026 | Category system stability — 6 fixes: (1) add_category sets is_active=True, (2) decoupled catalogue/category fetch try/except, (3) independent category guard, (4) decoupled manual refresh try/except, (5) offline cache is_active filtering, (6) .strip() normalization on category name comparisons | `db.py`, `views/customer.py`, `main.py`, `cache.py`, `PROJECT_MEMORY.md` | Complete — pushing CI |
| June 10, 2026 | BUG-020 — Place Order silently dead. Added `import datetime` to `db.py` (was missing in `create_order`). Removed redundant local imports. | `db.py`, `PROJECT_MEMORY.md` | Complete — pushing CI |
| June 10, 2026 | BUG-019 — Customer catalogue stale data fix. `logout()` clears 6 catalogue keys. Dashboard load priority: Supabase first → cache fallback only on failure. PIN login and session restore clear stale state before fetch. "Add Again" same priority fix. | `main.py`, `views/customer.py`, `PROJECT_MEMORY.md` | Complete — pushed CI |
| June 10, 2026 | Premium Brand Landing Page — Redesigned login screen as jewellery-brand landing page. Cream bg, gold accents, maroon CTA, logo, PIN login on-page, 2x2 contact cards (Instagram/WhatsApp/Location/YouTube), heritage text, small Admin/Labour links. Old `view_login()` replaced entirely. | `views/auth.py`, `PROJECT_MEMORY.md` | Complete |
| June 10, 2026 | BUG-018 — CI Flutter download corruption fix. `flet build apk` wrapped in retry loop (max 2 attempts). Clean `$HOME/flutter/` on retry. Investigation revealed Flet 0.28.3 always downloads Flutter 3.29.2 — the 3.24.0 pin is ineffective. | `.github/workflows/build_apk.yml`, `PROJECT_MEMORY.md` | Complete — pushed |
| June 10, 2026 | R1 fix — Customer PIN login network error messaging: `get_customer_by_pin()` uses `raise_errors=True`; invalid PIN, blocked, and connection errors each have distinct messages. | db.py, views/customer.py, PROJECT_MEMORY.md | Complete |
| June 10, 2026 | Timezone fix — Customer last login shows IST instead of UTC. Helper `format_ist_datetime()` parses ISO timestamp, converts to Asia/Kolkata. Shows "Never" for None. | views/customers.py | Complete — pushed, verified |
| June 10, 2026 | App logo — added `assets/icon.png`, configured adaptive icon `[tool.flet.android]` in pyproject.toml (background #000000, foreground from icon file). | pyproject.toml, assets/icon.png (new) | Complete — pushed, verified |
| June 10, 2026 | versionCode fix — added `fetch-depth: 0` to CI checkout so `git rev-list --count HEAD` returns actual commit count instead of always 1. | .github/workflows/build_apk.yml | Pushed, pending verification (blocked by BUG-011 signing issue) |
| June 10, 2026 | Release Blocker Batch 1 — Fix 8 bugs: R2 (session mobile key mismatch), R3 (cart remove stale index), H1 (place_order redirect to dashboard), H2 (Add Again lazy-load catalogue), H3/H4 (admin status/delete check DB result), H5 (safe .get() on order fields), M5 (PIN uniqueness raise_errors), M6 (cache filter zero-price items). | views/customer.py, views/home.py, main.py, db.py | Complete |
| June 10, 2026 | Pre-release regression audit (12 flows) — 30+ bugs found. Report added as Section 13. | PROJECT_MEMORY.md | Complete |
| June 10, 2026 | Customer Catalogue Redesign — portrait image-first card layout, removed side-by-side layout and badges, premium browsing feel. | views/customer.py | Complete |
| June 10, 2026 | Completed/Archive Orders feature — status_updated_at column, completed status, archive page, home filter, confirmed→completed action, settings entry. | db.py, views/home.py, views/archive.py (new), main.py, views/settings.py, PROJECT_MEMORY.md | Complete |
| June 10, 2026 | Quick Add Again per item in My Orders | views/customer.py | Complete |
| June 10, 2026 | Customer PIN Login System (Phases 1-3): db.py — customer CRUD functions (create/get/update/block/last_active) + 8-digit unique PIN auto-generation; views/customers.py (new) — Admin Manage Customers UI (search, add/edit dialog, block/unblock, copy PIN, PIN reveal on creation); views/settings.py — Manage Customers link in Account card; main.py — manage_customers route, customer_login route replaces customer_name_entry, state keys (customer_id, customer_shop_name), BACK_MAP entries, session restore, logout clears customer state; views/auth.py — customer button routes to customer_login; views/customer.py — view_customer_pin_login replaces view_customer_name_entry (8-digit PIN validation, db lookup, active check, session save, last_active_at update); session_helper.py — persists customer_id/customer_shop_name; sql/create_customers_table.sql for Supabase schema. | db.py, views/customers.py (new), views/settings.py, main.py, views/auth.py, views/customer.py, session_helper.py, sql/create_customers_table.sql (new), PROJECT_MEMORY.md | Complete |
| June 10, 2026 | Order Status System (Phase 1 — Admin side): added `status='pending'` to create_order; added `set_order_status()` in db.py with status validation; added status badge + Confirm/Cancel buttons to admin Home order cards; confirmed/cancelled orders read-only; missing/null status treated as pending. Run `ALTER TABLE orders ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';` in Supabase first. Bump to v1.0.17. | db.py, views/home.py, PROJECT_MEMORY.md, version.txt | Complete |
| June 9, 2026 | Customer Manual Catalogue Refresh: added 🔄 icon to customer AppBar on all catalogue screens via `_customer_refresh` handler. Removed Offline Sync UI: Data & Sync card from Settings, Sync icon from Admin AppBar. Kept sync_page route/code/cache.py as hidden fallback. Bump to v1.0.16. | main.py, views/settings.py, PROJECT_MEMORY.md, version.txt | Complete |
| June 9, 2026 | Item Visibility Toggle: added Hide/Show button to Admin Catalogue cards via `db.set_item_availability()`. Customer catalogue cache now filters `is_available=true` at load time. Pushed for CI testing. No schema/DB changes. | views/pricing.py, views/customer.py, PROJECT_MEMORY.md, version.txt | Complete — pushed, CI building v1.0.15 (build 32) |
| June 9, 2026 | Fixed RangeError 12 in Costing Detail: wrapped bottom section (margin, SP preview, save button) in a Column so `visible=False` on custom_margin_row doesn't corrupt ListView child count. Root cause: Flet ListView builder miscounts visible children when a direct child has `visible=False`. | views/pricing.py, PROJECT_MEMORY.md, version.txt | Complete — pushed, CI building v1.0.14 (build 31) |
| June 9, 2026 | Dead price-card code cleanup (Step A+B): deleted `generate_price_card_url()`, `CLOUDINARY_*` constants, `update_item_card_path()` from db.py. No view/db changes. | db.py, PROJECT_MEMORY.md | Complete |
| June 9, 2026 | Admin Settings UI restructured into 4 grouped cards: Catalogue & Categories, Materials & Pricing, Data & Sync, Account. Each with title + subtitle icons. No logic changes. | views/settings.py, PROJECT_MEMORY.md | Complete |
| June 9, 2026 | BUG-014/015/016 fix round + `page.pop_dialog()` fix in pricing.py and home.py delete confirmations (4 sites). Added rule: update PROJECT_MEMORY.md after every code change. | views/pricing.py, views/home.py, PROJECT_MEMORY.md | Complete — pushed, CI building v1.0.12 (build 8) |
| June 9, 2026 | Admin Nav Restructure: replaced nested Items tab (ft.Tabs with Add/Edit + Catalogue) with two standalone NavBar destinations. Created `view_add_item()` and `view_catalogue()`, removed `view_rate_list()`. Edit-from-catalogue uses `state["edit_item"]` + navigation to `"add_item"`. 5-tab NavBar: Home, Add Item, Catalogue, Costing, Settings. | views/pricing.py, main.py, PROJECT_MEMORY.md | Complete |
| June 8, 2026 | Customer Dashboard Phase 3: redesigned category tiles to portrait 3:4 ratio, 2-per-row manual layout (no ResponsiveRow), cascading image fallback (cover → first item image → monogram). Removed item grid filter chip row. Bumped to v1.0.10 (build 6). | views/customer.py, PROJECT_MEMORY.md | Complete — pushed, CI building |
| June 8, 2026 | BUG-011 fix v2: replaced unreliable actions/cache with committed deterministic debug keystore. Added `android/debug.keystore`, updated CI to copy it before build. Cleaned scratch/diagnostic files. Updated pyproject.toml exclusions. Bumped to v1.0.9 (build 5). | `.github/workflows/build_apk.yml`, `android/debug.keystore` (new), `.gitignore`, `pyproject.toml`, `PROJECT_MEMORY.md` | Complete |
| June 8, 2026 | FilePicker fix: replaced `await file_picker.pick_files(...)` (sync method returning None) with callback-based `on_result` pattern across 3 flows (pricing.py item upload, settings.py new/existing cover upload). | views/pricing.py, views/settings.py | Complete — Verified on device |
| June 8, 2026 | Dead price-card code cleanup (Phase 1+3): deleted card_generator.py (170 lines), assets/logo.png, removed dead imports/routes, removed card_preview grey 300x300 Container, card_thumb, 🎨 badge, Cloudinary card generation from save/edit/costing flows. DB compatibility stubs left intact. | card_generator.py (del), assets/logo.png (del), main.py, views/pricing.py | Complete |
| June 8, 2026 | Admin Items tab grey card fix: replaced `ft.Wrap(...)` (doesn't exist in Flet 0.28.3) with `ft.Row(wrap=True, run_spacing=2)`. Removed two unnecessary `wrap=True` from other Rows. | views/pricing.py | Complete — Verified on device |
| June 8, 2026 | Customer Item Detail UI redesign: premium B2B catalogue layout. Replaced flat ListView with card-based layout: rounded image card with shadow, product info card (item# + price side-by-side), +/- quantity stepper rows replacing oversized TextFields, live order summary card, sticky bottom CTA bar with qty preview. QtyStepper helper class preserves `.value` contract for add_to_cart(). All 5 edge cases tested (with/without sizes, with/without color, no image, no item guard). | views/customer.py | Complete |
| June 8, 2026 | PAT regenerated and updated in remote URL. Security sweep complete. | PROJECT_MEMORY.md | Complete |
| June 8, 2026 | BUG-013 v2: corrected Android detection from `ANDROID_ARGUMENT` env var to `page.platform == ft.PagePlatform.ANDROID`. First attempt failed because Flet doesn't set `ANDROID_ARGUMENT`. | main.py, PROJECT_MEMORY.md | Complete |
| June 8, 2026 | **BUG-013 CONFIRMED FIXED**: Exit dialog correctly closes app on Android via `page.platform` detection + `os._exit(0)`. | main.py, PROJECT_MEMORY.md | Complete — Verified on device |
| June 8, 2026 | Project memory consolidation: merged 3 context files into PROJECT_MEMORY.md | PROJECT_MEMORY.md (new), archive/PROJECT_CONTEXT.md, archive/PROJECT_HANDOVER.md, archive/contextD.md | Complete |
| June 8, 2026 | Exit dialog guard: added render() skip-return when dialog open; removed on_dismiss; simplified cancel/exit flow | main.py | Complete — pushed, CI building |
| June 8, 2026 | Keystore caching: added actions/cache for ~/.android/debug.keystore; bumped to v1.0.8 | .github/workflows/build_apk.yml | Complete — pushed, CI building |
| June 8, 2026 | Exit dialog + white screen fix: removed view pop from handler; switched dialog to overlay API; defensive view guard | main.py | Complete — pushed, CI building |
| June 8, 2026 | Session restore for all roles + exit confirmation dialog | session_helper.py (new), main.py, views/auth.py | Complete |
| June 8, 2026 | Diagnostic marker "PDF FORMAT VERSION: v2" added to PDF header, confirmed APK runs redesigned generator, marker removed after verification. | slip_pdf_generator.py | Complete — Verified on device |
| June 8, 2026 | Redesigned Karigar Slip PDF: maroon/gold palette, bordered details card, 3-zone item layout (image | center text | sizes box), image placeholders, divider lines, signature line. Replaced flat cells with rect-based cards. | slip_pdf_generator.py | Complete — Verified on device |
| June 7, 2026 | Initial CI setup, git init, first APK build, back-button fix, PROJECT_CONTEXT.md | Multiple | Complete |

---

## 13. PRE-RELEASE AUDIT REPORT (June 10, 2026)

Full regression audit across 12 major flows. 30+ bugs found. Organized by severity.

### 🚫 RELEASE BLOCKERS (Fix before ship)

| ID | File:Line | Description | Status |
|----|-----------|-------------|--------|
| **R1** | `views/customer.py:38-50` / `db.py:819` | DB unreachable shows "Invalid PIN" — `get_customer_by_pin()` now uses `raise_errors=True`; `do_login()` catches exceptions and shows connection error. Invalid PIN only when DB succeeds and returns no customer. | **FIXED** |
| **R2** | `session_helper.py:17` / `main.py:486` | Session saves `customer_mobile` but restores `mobile` — key mismatch, mobile lost on restart | **FIXED** |
| **R3** | `views/customer.py:919-921` | Cart remove uses stale positional index — wrong item removed or IndexError after shift | **FIXED** |
| **R4** | `views/pricing.py:194-195` | New items created with zero price — invisible in customer catalogue (filtered `gt.0`) | Pending |
| **R5** | `views/pricing.py:42-43` | FilePicker overlay leak — every Add Item visit appends new picker, never removed | Pending |
| **R6** | `views/pricing.py:216-226` | Save reports "✅ Item saved!" even when ALL 4+ DB update calls fail — no return-value checks | Pending |
| **R7** | `views/pricing.py:336` | `it["selling_price"] - it["cost_price"]` direct access — KeyError crashes catalogue render | Pending |
| **R8** | `db.py:737-747` | `save_item_materials()` deletes before insert with no rollback — data loss on insert failure | Pending |

### 🔴 HIGH Priority

| ID | File:Line | Description | Status |
|----|-----------|-------------|--------|
| H1 | `views/customer.py:944` | After place_order, redirects to admin login instead of customer dashboard | **FIXED** |
| H2 | `views/customer.py:1029-1038` | Add Again says "unavailable" for all items when catalogue not yet lazy-loaded | **FIXED** |
| H3 | `views/home.py:137-154` | Status confirm/cancel updates local cache even if DB PATCH fails — phantom state | **FIXED** |
| H4 | `views/home.py:102-135` | Delete order shows "✅ Deleted" even when DB delete fails | **FIXED** |
| H5 | `views/home.py:159,166,170` | Three `order[key]` direct accesses — KeyError crashes home if keys missing | **FIXED** |
| H6 | `views/home.py:206-224` | Background thread calls `page.update()` — thread-safety violation, RangeError risk | Pending |
| H7 | `views/orders.py:762-766` | `int.is_integer()` AttributeError crash on non-numeric quantity in order detail | Pending |
| H8 | `views/customer.py:60` | `customer["id"]` direct access — KeyError if DB column renamed | Pending |
| H9 | `views/customer.py:73-74` | `save_session()` IO exception crashes login after successful PIN auth | Pending |
| H10 | `views/customers.py:59-62,168-178` | Block/Edit always shows success snackbar even when DB PATCH fails | Pending |
| H11 | `views/pricing.py:218` | `card_path` overwritten with `""` on every save — destroys existing card paths | Pending |
| H12 | `main.py:618-642` | `go_back()` doesn't guard against open dialogs — state corruption | Pending |

### 🟡 MEDIUM Priority

| ID | File:Line | Description | Status |
|----|-----------|-------------|--------|
| M1 | `views/pricing.py:114` | HTTP request on every keystroke in item number field — rate-limit risk | Pending |
| M2 | `db.py:66-85` | All HTTP wrappers swallow exceptions — no caller knows if data persisted | Pending |
| M3 | `slip_pdf_generator.py:39-43` | Empty font path crashes PDF generation if HindiFont.ttf missing | Pending |
| M4 | `views/pricing.py:576` | `float("")` on empty custom margin crashes costing detail | Pending |
| M5 | `db.py:792` | PIN uniqueness check false positive on network error (`_get` returns `[]`) | **FIXED** |
| M6 | `views/customer.py:108` | Cache path doesn't filter zero-price items, DB path does — inconsistency | **FIXED** |
| M7 | `views/customer.py:1067-1069` | ft.Card inside ft.ListView blocks touch on buttons (KNOWN_ISSUES.md #2) | Pending |
| M8 | `views/pricing.py:386-398` | Rapid hide/show clicks race condition — wrong toggle state | Pending |
| M9 | `views/orders.py:840-843` | Edit order always sets mixed mode even for single-category orders | Pending |
| M10 | `views/orders.py:1044,1086` | Share PDF double-click guard flag set but never checked | Pending |
| M11 | `views/customer.py:1050-1052` | Add Again for sized items doesn't pre-fill original quantities | Pending |

### 🟢 LOW / COSMETIC

| ID | File:Line | Description | Status |
|----|-----------|-------------|--------|
| L1 | `main.py:483` | Dead `session_data.get("name")` branch — helper never writes `"name"` key | Pending |
| L2 | `views/customers.py:114,164` | `name_tf.value.strip()` crashes if value is `None` | Pending |
| L3 | `views/customer.py:31` | `pin_input.value.strip()` could crash if value is `None` | Pending |
| L4 | `session_helper.py:14-19` | Cart not persisted — lost on app restart | Pending |
| L5 | `views/pricing.py:48-49` | "Camera" button identical to "Gallery" — misleading | Pending |
| L6 | `.github/workflows/build_apk.yml:78` | `if-no-files-found: warn` hides build failures; should be `error` | Pending |
| L7 | `main.py:492-516` | `item_detail` missing from BACK_MAP — empty nav_history + back = exit dialog | Pending |
| L8 | `db.py:669-674,749-756` | Duplicate `get_default_margin()` with different key — confusing | Pending |

### ✅ Flows With No Major Issues

- Manage Customers UI (no crashes, all paths guarded)
- Customer PIN login (core flow works end-to-end — R1 fixed: network/db errors vs invalid PIN distinguished)
- My Orders display (list + expandable detail work correctly)
- Add Again → simple item (direct cart add works)
- Add Again → sized/colored (navigates to item_detail)
- Session restore (login works, customer_id + mobile persisted) — R2 fixed
- APK workflow (Flutter 3.24.0 pinned, keystore committed, CI structural sound)

---
### Order Status + Archive System

Status: ✅ Implemented

Statuses:
* pending
* confirmed
* cancelled
* completed

Workflow:
pending → confirmed → completed
pending → cancelled

Admin Dashboard Rules:
* Home shows ONLY: pending, confirmed
* completed and cancelled hidden from Home

Archive:
* Settings → Archive Orders
* Archive contains: completed, cancelled
* Read-only
* Tap opens existing order detail

Database:
* orders.status_updated_at added
* set_order_status() updates timestamp
* create_order() sets initial timestamp

Future Plan:
* Optional cleanup of archived orders older than 30 days
* NOT implemented yet

---
### Android Release Signing

Status: ✅ Implemented

Previous Problems:
* versionCode always = 1 due to shallow clone
* random signing key mismatch
* INSTALL_FAILED_UPDATE_INCOMPATIBLE
* uninstall required before every update

Final Fix:
* GitHub Actions uses fetch-depth: 0
* Permanent release keystore configured
* CI signing migrated from debug.keystore to release signing
* GitHub Secrets used:
  * ANDROID_KEYSTORE_BASE64
  * ANDROID_KEYSTORE_PASSWORD
  * ANDROID_KEY_PASSWORD
  * ANDROID_KEY_ALIAS

Verification:
* APK now installs over existing installs successfully
* Stable signing fingerprint confirmed
* Package name unchanged: com.flet.mahalaxmi_bangles

Security:
* release-signing-backup/ added to .gitignore
* permanent offline keystore backup created


