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
- **Image Processing:** Supabase Storage (public bucket: `product-images`)
- **Offline Cache:** Local JSON files + downloaded images
- **PDF Generation:** fpdf2 + Pillow
- **APK Build:** GitHub Actions CI (Windows local builds broken)

**Git / CI:**
- **Remote:** `https://github.com/rajatchawla66/mahalaxmi-bangles.git`
- **Branch:** `main`
- **CI endpoint:** https://github.com/rajatchawla66/mahalaxmi-bangles/actions
- **CI Token:** Classic PAT with `repo` + `workflow` scopes (regenerated June 8, 2026 — stored in git remote URL, removed from all git history)
- **Latest version:** v1.0.20 (build 46)

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
| **`rate_list`** | `item_number`, `image_url`, `cost_price`, `selling_price`, `category`, `sub_category`, `has_sizes`, `has_color`, `is_available`, `margin_percent`, `status` |
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
| **Dropdown** | Use `on_change` NOT `on_select` (confirmed June 11, 2026) |
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
    "customer_category_cache": {},
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

### BUG-025: Labour Production Checklist — status button does not visually update after tap
| Field | Detail |
|-------|--------|
| **Date** | June 11, 2026 |
| **Symptom** | Tapping a production status button (pending/prepared/not_available) on labour checklist updates the progress summary correctly but the tapped button's text/color stays frozen. Close/reopen shows correct persisted state. |
| **Root Cause** | `status_btn` container's `bgcolor` and `content` (`ft.Text`) were assigned static values at card-build time (lines 162-171, 186-196). The toggle handler (`_make_toggle_handler`, line 87-107) mutated the backing dict (`status_ref[size_key]`) and called `page.update()`, but **never reassigned** `e.control.bgcolor` or `e.control.content`. Flet re-rendered the button with the same stale property values. |
| **Fix** | Added 3 lines inside `_h()` after `status_ref[size_key] = next_st`: look up `next_color, next_label` from `STATUS_STYLES[next_st]`, update `e.control.bgcolor` with `ft.Colors.with_opacity(0.12, next_color)`, and replace `e.control.content` with a new `ft.Text(next_label, size=12, weight="bold", color=next_color)`. Since `e.control` IS the `status_btn` container, no structural or layout changes needed. |
| **Files** | `views/labour.py:87-107` (`_make_toggle_handler`) |
| **Lesson** | When a control's appearance depends on mutable state, the handler that mutates that state must also update the control's visual properties directly. `page.update()` only re-renders existing property values — it does not re-read the backing dict to derive new values. |

---

### BUG-030: Home Order List — ft.ListTile.on_click unreliable on Android in scrollable parent
| Field | Detail |
|-------|--------|
| **Date** | June 12, 2026 |
| **Symptom** | Tapping an order card on the home screen (admin or labour) often does nothing on Android. Requires multiple taps or very precise tap. Chevron/popup menu are the only reliably tappable areas. |
| **Root Cause** | `ft.ListTile` inside `ft.Column(scroll=ft.ScrollMode.AUTO)` — Flet 0.28.3 has unreliable gesture detection for `ListTile.on_click` when the parent is a scrollable Column. The ListTile's internal gesture detector conflicts with the scroll detector. The popup menu button and chevron icon work reliably because they are separate controls with their own gesture areas. |
| **Fix** | Replaced `ft.ListTile(on_click=on_order_tap(order_id), leading=..., title=..., subtitle=..., trailing=...)` with `ft.Container` structure: outer white Container with `border_radius=10` and `clip_behavior=ANTI_ALIAS` (no `on_click`); inner Row with two children: (1) clickable body Container with `expand=True, on_click=on_order_tap(order_id), ink=True` containing the 6px color strip + title/subtitle Column, and (2) trailing Container (popup menu or chevron) with no `on_click`. This ensures the trailing (3-dot menu / chevron) does NOT trigger order navigation. |
| **Files** | `views/home.py:258-294` (replaced ListTile block) |
| **Lesson** | `ft.ListTile.on_click` is unreliable inside scrollable parents in Flet 0.28.3 on Android. Use `ft.Container(on_click=..., ink=True)` for reliable tap detection. Split clickable body from interactive trailing elements to prevent accidental navigation. |

---

### BUG-026: Connectivity Phase 1+2 — No offline detection, no user indication
| Field | Detail |
|-------|--------|
| **Date** | June 12, 2026 |
| **Symptom** | App has no awareness of network state. When offline, requests silently return `[]`/`False`/`""` with no user-facing indication. Users can perform actions that appear to succeed but silently fail. |
| **Root Cause** | No connectivity detection mechanism existed. The 4 centralized wrappers (`_get`/`_post`/`_patch`/`_delete`) caught all exceptions silently. No counter tracked consecutive failures. No UI element indicated offline state. |
| **Fix** | Added module-level `_consecutive_failures` counter + `_OFFLINE_THRESHOLD=3` in `db.py`. Added `_mark_success()`/`_mark_failure()` called from all 4 wrappers. Added `_is_transport_error()` to distinguish network issues (timeout, connect error, 5xx) from business-logic HTTP errors (4xx). Added `is_online()` and `get_connectivity_status()` public API. Added `connectivity_banner()` in `utils.py` — thin 28px orange banner when offline, zero-height when online. Banner added to 4 read-heavy views: customer dashboard, admin home, pricing catalogue, order form. |
| **Files** | `db.py`, `utils.py`, `views/customer.py`, `views/home.py`, `views/pricing.py`, `views/orders.py` |
| **Lesson** | Connectivity should be inferred passively from existing request failures, not via active ping. A simple failure counter in the centralized wrapper layer is sufficient. |

---

### BUG-027: update_order() Always Returns True
| Field | Detail |
|-------|--------|
| **Date** | June 12, 2026 |
| **Symptom** | Admin edits an order offline — UI shows "✅ Order updated" and navigates to home. DB was never updated. |
| **Root Cause** | `db.update_order()` called `_patch()`, `_delete()`, and `_post()` but never checked any of their return values. Always unconditionally returned `True`. |
| **Fix** | Added `if not` checks after each of the 3 internal writes. On any failure, returns `False` immediately. Caller in `orders.py:590-593` now checks return: `if not ok: snack("❌ Failed to update order — check network"); return`. |
| **Files** | `db.py:557-579`, `views/orders.py:590-593` |
| **Lesson** | Every function that returns `bool` must actually check its dependencies' return values. A "success" return with unchecked inner calls is a data-loss bug waiting to happen. |

---

### BUG-028: create_order() Partial Failure — items insert result ignored
| Field | Detail |
|-------|--------|
| **Date** | June 12, 2026 |
| **Symptom** | Customer places order offline — header created but items missing. UI shows "✅ Order #X placed successfully!" Customer sees empty order in My Orders. Data loss. |
| **Root Cause** | `db.create_order()` checked header insert result but ignored items insert result. If header succeeded but items failed, it returned a truthy `order_id`. |
| **Fix** | `db.create_order()` now checks `_post("order_items", ...)` return. On items insert failure, attempts cleanup via `_delete("orders", ...)` and returns `0`. Admin `save_order()` (orders.py:601-606) now checks `new_id` before showing success. Customer `place_order()` already checked — no change needed. |
| **Files** | `db.py:540-543`, `views/orders.py:601-606` |
| **Lesson** | Multi-step DB operations must verify every step. A fake success from a partial write is worse than a clean failure — the incomplete data persists and confuses users. |

---

### BUG-029: Add/Edit Item Save — fake success on network failure
| Field | Detail |
|-------|--------|
| **Date** | June 12, 2026 |
| **Symptom** | Admin saves a new catalogue item offline — UI shows "✅ Item saved!" and clears the form. No item was created in DB. Admin must re-enter all fields. |
| **Root Cause** | `on_save_and_generate()` in `pricing.py:174-246` called 5 DB writes with zero return-value checks. Success snackbar was unconditional. Form cleared unconditionally. Image upload failure fell back to local filesystem path, which is broken for all other devices. |
| **Fix** | (1) Image upload now checks return — if fails, shows red snackbar and returns (no local-path fallback). (2) All 4 edit writes (`update_item_prices`, `update_item_image`, `update_item_category`, `update_item_properties`) now return-checked — any failure stops the sequence and shows error. (3) `add_rate_item` return now checked for new items. (4) Form clears only on complete success. |
| **Files** | `views/pricing.py:197-246` (`on_save_and_generate`) |
| **Lesson** | A save function with N writes must check all N returns. Local-file fallbacks for cloud storage create invisible data corruption — better to fail loudly. |

---

### BUG-024: Admin Order Form — Dropdown on_select never fires, missing return controls
| Field | Detail |
|-------|--------|
| **Date** | June 11, 2026 |
| **Symptom** | Admin → Create Order: Single Category — items show in dropdown but selecting does nothing (no size/qty controls). Mixed Order — category dropdown works but item dropdown shows no items. |
| **Root Cause** | Two bugs: (1) `item_dd.on_select = on_item_change` and `row_cat_dd.on_select = on_row_cat_change` — `Dropdown` in Flet 0.28.3 uses `on_change`, not `on_select`. The `on_select` attribute is silently ignored. (2) `build_category_fields()` in `main.py` builds size/qty/color controls into a `controls` list but never returns it — Python returns `None`, so `category_fields_column.controls = None` discards all controls. |
| **Fix** | (a) Changed `item_dd.on_select` → `item_dd.on_change`, `row_cat_dd.on_select` → `row_cat_dd.on_change`. (b) Added `return controls` at end of `build_category_fields()`. (c) Fixed same `on_select` → `on_change` for `color_dd` inside `build_category_fields`. |
| **Files** | `views/orders.py:427,453`, `main.py:843,867` |
| **Lesson** | Flet 0.28.3 `Dropdown.on_select` is not a valid event — the attribute is silently accepted but never fires. Always use `on_change`. Every Python function that builds a list must `return` it. |

---

### BUG-023: Admin Order Form — Layout starvation after ft.Card → ft.Container replacement
| Field | Detail |
|-------|--------|
| **Date** | June 11, 2026 |
| **Symptom** | Admin → Create Order: text wraps letter-by-letter, controls width-collapsed, dropdown rendering broken. Triggered by ft.Card→ft.Container fix for touch reliability. |
| **Root Cause** | `ft.Card` intrinsically expands to fill `ft.ListView` width in Flet 0.28.3. `ft.Container` without `expand` or `width` sizes to its content. After replacement, the three cards (customer_card, items_card, summary_card) were ~220px wide (content-width from TextField labels) instead of filling the full ListView width. |
| **Fix** | Wrapped each card in `ft.Column([card], expand=True)` — the Column wrapper forces full-width expansion from ListView while the card Container still auto-sizes vertically. |
| **Files** | `views/orders.py:658-667` |
| **Lesson** | `ft.Container` direct child of `ft.ListView` does NOT stretch to full width like `ft.Card` does. Must wrap in `ft.Column(expand=True)` or use explicit width. |

---

### BUG-022: Card_path overwritten with "" — legacy Cloudinary system fully removed
| Field | Detail |
|-------|--------|
| **Date** | June 11, 2026 |
| **Symptom** | Every item save wipes `card_path` column to `""`. Whole Cloudinary price-card system is dead but code still references it. |
| **Root Cause** | `update_item_image_and_card()` in `db.py` always writes `""` for `card_path` because Cloudinary generation was removed. `get_all_items_with_cards()` has misleading name. `card_path` column exists in Supabase but no code reads it. |
| **Fix** | Renamed `update_item_image_and_card()` → `update_item_image()`, removed `card_path` param and PATCH field. Renamed `get_all_items_with_cards()` → `get_all_items()`. Updated both callers in `views/pricing.py`. Removed `generated_cards/` from `.gitignore` and `pyproject.toml`. Added `sql/migration_remove_card_path.sql` — run manually in Supabase: `ALTER TABLE rate_list DROP COLUMN IF EXISTS card_path;`. Zero active references remain in `.py` files. |
| **Files** | `db.py:408,442`, `views/pricing.py:218,294`, `.gitignore`, `pyproject.toml`, `sql/migration_remove_card_path.sql` (new) |
| **Lesson** | Dead features must be fully removed from code AND database, not just left with stubs. |

---

### BUG-021: Admin Order Form — Category comparison fails due to whitespace mismatch
| Field | Detail |
|-------|--------|
| **Date** | June 11, 2026 |
| **Symptom** | Mixed Order: after selecting a category, item dropdown shows no items. Items exist in the category but the equality check fails. |
| **Root Cause** | `_get_items_for_row()` in `views/orders.py:347` compares `it.get("category") == cat`. Category names stored in `rate_list.items` vs `categories` table may have trailing/leading whitespace differences — no `.strip()` normalization. |
| **Fix** | Added `.strip().lower()` to both sides: `it.get("category", "").strip().lower() == cat.strip().lower()`. |
| **Files** | `views/orders.py:347` |
| **Lesson** | Category names are free-text input, always normalize comparisons with `.strip().lower()`. |

---

### BUG-031: Tag Master — multi-category chip visuals do not live-update on tap; Edit/Delete buttons cropped
| Field | Detail |
|-------|--------|
| **Date** | June 13, 2026 |
| **Symptom** | (1) Tapping a category chip in Tag Master add form or edit dialog does not visually change chip color — user cannot confirm tap worked. (2) Edit/Delete TextButtons in tag cards are slightly vertically cropped — text/emoji clipped at top/bottom. |
| **Root Cause** | (1) `_rebuild_cats_chips()` in add form and `_rebuild_edit_chips()` in edit dialog both clear and re-populate `cats_row.controls` / `edit_cats_row.controls` but **never call `.update()`** on the parent row. Flet requires `control.update()` after modifying `controls` list to sync changes to the Flutter renderer. An initial attempt to put `.update()` inside the rebuild functions caused "row control must be added to the page first" — the initial rebuild runs during view/dialog construction before the row is mounted. (2) TextButtons had `height=30` constraint which is below Flet's minimum content height — the emoji characters "✏️"/"🗑️" and text are clipped. Container bottom padding `bottom=6` was also tight. |
| **Fix** | (1) Moved `.update()` calls to user-initiated handlers only: `_select_global()` and `_toggle_cat_chip()` now call `cats_row.update()` after `_rebuild_cats_chips()`. Edit dialog lambda handlers now call `edit_cats_row.update()` as the last expression in the tuple after `_rebuild_edit_chips()`. Initial rebuild calls during construction (before row is mounted) have no `.update()`. (2) Removed `height=30` from both TextButtons (natural height). Increased outer Container `bottom` padding from 6 to 10. |
| **Files** | `views/settings.py` |
| **Lesson** | After clearing/re-populating a control's `.controls` list, always call `.update()` on that control explicitly. Flet does not auto-sync `controls` mutations. Avoid constraining TextButton height below its natural content height. |

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
- Order Creation & Full Flow (Single Category + Mixed Order, size/quantity/color controls)
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
- Order Form Phase A — No image preview in cart rows, compact customer card (full-width fields), single compact summary row (Items | Sets | Amount), mode badge, dead code removed.
- Order Form Phase B — Packing structure fully removed from UI/save/slips/PDF/DB layer. Sticky save button (always visible at bottom). Visible red Remove button per item. Tighter item row spacing.
- Order Form Phase C — Image thumbnail (64×64, rounded) appears after item selection with placeholder icon fallback. Smart Add Item: mixed order opens category picker dialog that pre-selects category in the new row. Sticky bottom bar with outlined [+ Add Item] + filled [Save Order] always visible.
- Labour Production Checklist V1 — per-size status toggle (pending→prepared→not_available→pending), image thumbnails, progress summary, JSONB column in order_items.
- Labour Production Checklist V2 — Image-first cards (260px portrait, COVER fit, radius 12), direct routing (labour taps order → checklist, bypasses order_detail), BACK_MAP to home, pill-shaped status buttons (border_radius=20, padding 12,8).
- Admin Home Production Summary — `Production: ✅ 3/10 ⚠ 1` on admin order cards using existing data.
- Admin Order Detail Production Redesign — visual item cards with 64px images, per-size status pills (✅ Ready / ⬜ Pending / ⚠ Not Avail), category group headers, production summary at top.
- **Customer Tag Filter Row (P4)** — Horizontal-scroll tag chips extracted from loaded items, in-place local filter via `_rebuild_items()` + `page.update()`, no DB call, no navigation, works offline. Tag reset on category change. Factory functions for closure safety.
- **Customer Dashboard Performance Refactor (Phase 1)** — Category-first lazy loading: dashboard no longer preloads full catalogue. Categories load instantly from `categories` table (lightweight query). Items fetched per-category via `db.get_customer_items_by_category()` when category is tapped. Results cached in `state["customer_category_cache"]` for instant repeat opens. Search uses `db.search_customer_items()` on demand. Add Again uses `db.get_item_by_number()` (single-item fetch). Zero items fetched at startup.
- **Home Order List mobile touch fix (BUG-030)** — `ft.ListTile` replaced with `ft.Container` split layout; clickable body with ink ripple; trailing popup menu/chevron outside click scope.
- **Tag Master chip live-update (BUG-031)** — Multi-category chip visuals update immediately on tap in add form and edit dialog. `.update()` called from user-initiated handlers only (avoids crash on un-mounted rows during construction). Edit/Delete buttons no longer cropped.
- **Image optimization** — Uploaded images resized to 1080×1350 HD JPEG (Q93) with `resize_product_image()`: EXIF transpose, 4:5 center-crop, LANCZOS, sharpen filter.

### 🔄 Pending Verification (needs real Android testing)
- Logout button across all roles
- White screen after force-stop/reopen
- **Connectivity Phase 1+2** — Passive connectivity tracking (db.py), offline banner in 4 read-heavy screens (customer dashboard, admin home, pricing catalogue, order form)
- **Connectivity Phase 3 — update_order() fix** — Now checks return values of all 3 internal writes, returns False on failure. Caller shows "Failed to update order — check network" and prevents navigation/state-clear.
- **Connectivity Phase 3 — create_order() fix** — Items insert result now checked; on failure attempts orphan header cleanup and returns 0 (falsy). Both admin and customer callers check return and prevent fake success.
- **Connectivity Phase 3A — Add/Edit Item save fix** — All 5 DB writes now return-checked. Image upload failure shows error instead of saving local path to DB. Form preserved on failure for retry.
- **BUG-025** — Labour status buttons visually update immediately on tap
- **BUG-027** — update_order() no longer always returns True
- **Connectivity Phase 3B — Delete Item safety** — `db.delete_item()` return now checked. On failure: red snackbar shown, cache/UI unchanged, dialog stays open. On success: cache mutated, dialog closes, success snackbar shown.
- **Connectivity Phase 3C — Availability toggle safety** — Form switch reverts on failure. Catalogue Hide/Show checks DB return before mutating cache.
- **Connectivity Phase 3D — Costing save integrity** — `save_item_materials()` now checks `_delete()` and `_post()` return values instead of ignoring them. Fake success eliminated.
- Offline banner shows correctly on connectivity loss
- Item save with network failure does not clear form
- Delete item with network failure keeps item visible
- **Home order list (BUG-030)** — ListTile → Container touch reliability fix; trailing popup/chevron does not trigger navigation
- **Customer Performance Refactor** — Category-first lazy loading; no full catalogue preload; search/add-again use on-demand DB fetch
- **Customer Offline Fallback** — `_offline_empty_state()` helper with Reload button; dashboard offline state; category items offline state; subcategories offline state

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
| June 13, 2026 | **BUG-031** — Tag Master multi-category chip live-update + button cropping. Initial fix (`.update()` inside rebuild) caused "row control must be added to the page first" crash. Refined: moved `.update()` to user-initiated handlers only. Button crop: removed `height=30`, increased card bottom padding 6→10. **Verified working.** | `views/settings.py`, `PROJECT_MEMORY.md` | Complete |
| June 13, 2026 | **P4 — Customer tag filter row** in `view_customer_items()`. Tags extracted from loaded items (no DB call), horizontally scrollable chip row (NOT wrap), in-place filter via `_rebuild_items()` + `page.update()` — no navigation, no image reload. Factory functions for closure safety. Tag reset on category change in dashboard. | `views/customer.py`, `PROJECT_MEMORY.md` | Complete |
| June 13, 2026 | Phase A2 — Multi-category tags code migration. db.py: get_tag_master normalizes categories JSONB, add_tag/update_tag accept `categories: list`. Tag Master: single-category Dropdown replaced with multi-category chip selector (Global + per-category chips, toggle behavior). Edit dialog uses same chip pattern (no Dropdown = no overlay conflict). Tag list shows multiple category badges (indigo) or Global badge (teal). P3 selector filter uses `t.get(\"categories\", [])`. | `db.py`, `views/settings.py`, `views/pricing.py`, `PROJECT_MEMORY.md` | Complete |
| June 13, 2026 | P3 — Multi-tag chip selector in Add/Edit Item form. Tags loaded by selected category (category match + global). Chips with wrap layout, tap to toggle, indigo/grey color. New items pass tags to add_rate_item(). Edit items call update_item_tags(). Edit preload preserves existing tags including unknown ones. Proper closure scoping. | `views/pricing.py`, `PROJECT_MEMORY.md` | Complete |
| June 13, 2026 | Tag Master bug fixes + field simplification. Fixed: (1) white screen on dialog close — removed `page.overlay.remove(dlg)` from all 4 dialog handlers (Flutter null-check crash in Flet 0.28.3). (2) Save "Failed to update" on non-last tags — Python late-binding closure bug: passed `tag_name`/`display_name`/`cat`/`is_active` as parameters to factory functions. (3) Removed duplicate Tag Name (slug) field — slug auto-derived from display name. | `views/settings.py`, `PROJECT_MEMORY.md` | Complete |
| June 12, 2026 | Customer Search UI/UX Audit — identified 8 issues (2 HIGH: full fetch per keystroke, no debounce; 4 MEDIUM; 2 LOW). Report added as Section 14. Implementation postponed. | None (audit only) | Complete |
| June 12, 2026 | Product Tags P2 Implementation — Tag Master admin UI in settings.py: add/edit/delete/toggle tags, category dropdown, active pill, edit AlertDialog, delete confirmation with safety check. Route + BACK_MAP in main.py. | `views/settings.py`, `main.py`, `PROJECT_MEMORY.md` | Complete |
| June 12, 2026 | Product Tags P1 Implementation — SQL migration file (sql/migration_add_tags.sql), 6 new db.py functions (get_tag_master, add_tag, update_tag, delete_tag, get_items_by_tag, update_item_tags), modified add_rate_item (optional tags param), modified search_customer_items (tags in filter). Backend only — no UI yet. | `sql/migration_add_tags.sql` (new), `db.py` | Complete |
| June 12, 2026 | Sync Architecture Audit — documented all full-table re-download paths, delta-sync opportunities, and implementation plan. Added as Section 15. | PROJECT_MEMORY.md | Complete |
| June 12, 2026 | Offline fallback fix for customer lazy loading: Added `_offline_empty_state()` helper (icon + message + Reload button). `_get_category_items()` now returns `(items, was_offline)` tuple. Dashboard shows offline state when categories fail to load. Items/subcategories views show offline state when category items fail + cached catalog empty. Reload button retries DB fetch (clears cache key, navigates to self). Categories tap into genuinely empty categories now shows "No items found" (not offline state). | `views/customer.py` | Pending Android test |
| June 12, 2026 | Customer Dashboard Performance Refactor — Category-first lazy loading. Removed full catalogue preload from dashboard (was calling `get_customer_catalogue()`). Added `get_customer_items_by_category()` for per-category DB filter. Added `state["customer_category_cache"]` dict for per-category in-memory cache. Added `search_customer_items()` for on-demand search. Refactored Add Again to use `get_item_by_number()` (single-item fetch). Updated refresh handler to clear category cache instead of full reload. Dashboard now loads ONLY categories at startup — zero items fetched until category tapped. | `views/customer.py`, `db.py`, `main.py` | Pending Android test |
| June 12, 2026 | **BUG-030** — Home order list mobile touch fix. Replaced `ft.ListTile(on_click=...)` with `ft.Container` split layout: clickable body with `ink=True` + trailing outside click scope. Popup menu/chevron no longer triggers order navigation. | `views/home.py` | Pending Android test |
| June 12, 2026 | Image optimization — Added `resize_product_image()` to utils.py: EXIF rotation fix, center-crop 4:5, LANCZOS resize to 1080×1350, SHARPEN filter, JPEG Q93. Called from `views/pricing.py:on_pick_result` before Supabase upload. Local filesystem fallback removed. | `utils.py`, `views/pricing.py` | Complete — pushed CI |
| June 12, 2026 | Connectivity Phase 3C+3D — Availability toggle safety (form revert + catalogue check) + Costing save integrity (save_item_materials checks _delete/_post returns). All remaining pricing write paths hardened. | `views/pricing.py`, `db.py` | Pending Android test |
| June 12, 2026 | Connectivity Phase 3B — Delete Item safety. `db.delete_item()` return now checked in `confirm_delete`. Cache/UI mutation only after successful DB delete. Failure shows red snackbar, keeps item visible. | `views/pricing.py` | Pending Android test |
| June 12, 2026 | Connectivity Phase 3A — Add/Edit Item save safety. Image upload failure no longer falls back to local path. All 5 DB writes in `on_save_and_generate()` now return-checked. Form preserved on failure. Fake success eliminated. | `views/pricing.py` | Pending Android test |
| June 12, 2026 | Connectivity Phase 3 — create_order() partial failure fix. Items insert result now checked. Orphan header cleanup on failure. Admin caller (orders.py) now checks return. | `db.py`, `views/orders.py` | Pending Android test |
| June 12, 2026 | Connectivity Phase 3 — update_order() fake-success fix. All 3 internal writes (`_patch`/`_delete`/`_post`) now return-checked. Caller shows failure snackbar and aborts navigation. | `db.py`, `views/orders.py` | Pending Android test |
| June 12, 2026 | Connectivity Phase 1+2 — Passive connectivity tracking in db.py (`_consecutive_failures`, `is_online()`), offline banner in utils.py (`connectivity_banner()`), banner added to 4 read-heavy screens. | `db.py`, `utils.py`, `views/customer.py`, `views/home.py`, `views/pricing.py`, `views/orders.py` | Pending Android test |
| June 11, 2026 | Labour Production Checklist — Image-first redesign + BUG-025 fix. Direct routing (labour taps order → checklist directly). BACK_MAP updated (checklist → home). Cards redesigned: 260px portrait image, pill-shaped status buttons (border_radius=20, padding 12,8), subtle text. BUG-025 fix: added 3 lines to `_make_toggle_handler` to update `e.control.bgcolor` and `e.control.content` after dict mutation. | `views/home.py`, `main.py`, `views/labour.py`, `PROJECT_MEMORY.md` | Complete — pushed `b51ee6d` |
| June 11, 2026 | Admin Order Detail visual redesign — per-size production status pills (✅ Ready / ⬜ Pending / ⚠ Not Avail), 64px product image thumbnails, category group headers, per-item pricing, production summary at top. Labour text rendering unchanged. Replaced ft.Card with ft.Container for admin. | `views/orders.py` | Complete — pushed |
| June 11, 2026 | Labour Production Checklist V1 — new views/labour.py with per-size status toggle, image thumbnails, progress summary. SQL migration file for JSONB column. Role-aware buttons in order detail. Admin read-only production status in order detail text. | `views/labour.py` (new), `views/orders.py`, `db.py`, `main.py`, `sql/migration_add_production_status.sql` (new) | Complete — pushed `b38fbfe` |
| June 11, 2026 | Admin Home production summary — per-order production progress on admin order cards (Production: ✅ 3/10 ⚠ 1). Uses existing embedded order_items data, no new queries. | `views/home.py` | Complete — pushed |
| June 11, 2026 | Order Form Phase A — Removed 100×100 image preview from cart rows, restructured customer card layout (full-width name, date+packing row, full-width notes), compact summary (single bordered row replacing 3 stat cards), mode badge (Mixed/Single), removed dead `_stat_card_wrap()`, removed stale PACKING_OPTIONS from main.py (kept in utils.py). | `views/orders.py`, `main.py` | Complete — pushed |
| June 11, 2026 | BUG-024 — Order form dropdowns not firing + missing return controls. Changed on_select→on_change for all 3 dropdowns (item_dd, row_cat_dd, color_dd). Added missing `return controls` in build_category_fields(). | `views/orders.py`, `main.py` | Complete — pushed `c4f0dd2` |
| June 11, 2026 | BUG-023 — Order form layout starvation after ft.Card→ft.Container. Wrapped 3 cards in ft.Column(expand=True). | `views/orders.py` | Complete — pushed `6c5a14d` |
| June 11, 2026 | BUG-022 — Cloudinary/price-card/card_path full cleanup. Renamed 2 db.py functions, removed card_path param and PATCH field, updated callers, removed generated_cards from config, added SQL migration. | `db.py`, `views/pricing.py`, `.gitignore`, `pyproject.toml`, `sql/migration_remove_card_path.sql` (new) | Complete — pushed `b7efe78` |
| June 11, 2026 | BUG-021 — Category comparison whitespace mismatch. Added .strip().lower() to both sides in _get_items_for_row(). | `views/orders.py` | Complete — pushed `6c5a14d` |
| June 11, 2026 | Mobile touch reliability fix — replaced risky ft.Card with ft.Container across 4 files (orders/customer/settings/customers). 11 cards replaced, SAFE/LOW cards untouched. | `views/orders.py`, `views/customer.py`, `views/settings.py`, `views/customers.py`, `Audit Report 11June.md` (new) | Complete — pushed `4b143c5` |
| June 11, 2026 | Costing Detail mobile redesign — create_material_row() rewritten to vertical card with stored references, double-click delete guard. | `views/pricing.py` | Complete — pushed `3ff6534` |
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
| **R5** | `views/pricing.py:42-43` | FilePicker overlay leak — every Add Item visit appends new picker, never removed | **FIXED** (June 11 — Manage Categories FilePicker is now singleton) |
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
| H11 | `views/pricing.py:218` / `db.py:442` | `card_path` overwritten with `""` on every save — **FIXED**: `card_path` column removed from code and DB, dead Cloudinary price-card system fully cleaned up | **FIXED** |
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
| M7 | `views/customer.py:1067-1069` | ft.Card inside ft.ListView blocks touch on buttons (KNOWN_ISSUES.md #2) | **FIXED** (June 11 — all risky ft.Card → ft.Container across 4 files + Column expand wrapper) |
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

---

## 14. CUSTOMER SEARCH UI/UX AUDIT (June 12, 2026)

Conducted: June 12, 2026. Scope: `views/customer.py`, `db.py`, `cache.py`.

### Current Flow
- Dashboard search bar (`on_change`, 3-char minimum) navigates to `customer_search_results` page
- Results page has its own search `TextField` (autofocus, instant `on_change` — fires on every keystroke, no debounce)
- `db.search_customer_items(query)` fetches ALL customer-visible items from DB, filters client-side in Python

### Fields Searched
- `item_number`, `category`, `sub_category` — substring match via Python `in` (OR'd)

### Issues Found

| # | Issue | Severity |
|---|-------|----------|
| 1 | **Full catalogue fetch on every keystroke** — no server-side `ilike`, 500 items transferred per search call | HIGH |
| 2 | **No debounce** — fires DB fetch on every `on_change` event; 3+ consecutive chars = 3+ full fetches | HIGH |
| 3 | **No loading state** — screen stays frozen until DB responds | MEDIUM |
| 4 | **Inconsistent min-char logic** — dashboard requires 3 chars, results page search fires instantly on 1-2 chars (results in empty-state flash) | MEDIUM |
| 5 | **No offline empty state** — DB error + no cache shows "No results for 'X'" instead of offline message + Reload | MEDIUM |
| 6 | **No result caching** — same query repeated re-fetches entire catalogue | MEDIUM |
| 7 | **Inconsistent hint text** — dashboard: "Search 500+ items...", results: "Search items..." | LOW |
| 8 | **Arrow button on dashboard** — unclear UX; calls `on_search_change(None)` which reads `search_tf.value` | LOW |

### Offline Behavior
- On DB exception: falls back to `cache.get_cached_catalog()`, same client-side filter
- No cache → `[]` → shows "No results" (misleading)
- **No Reload button** (unlike category items view which has `_offline_empty_state`)

### Performance Risks
- Full catalogue fetch per keystroke: ~500 items per call, 3+ calls per session
- No server-side filtering; Supabase `ilike` would reduce payload to matching rows only
- No search result cache; repeated same query repeats full fetch

### Recommended Changes (NOT IMPLEMENTED — postponed)
**Phase 1 (minimum):** Server-side `ilike` search in `db.py`, 300ms debounce, offline empty state, loading indicator
**Phase 2 (UX):** Consistent hint text, search result caching, AppBar search action
**Phase 3 (advanced):** Inline dashboard search results, search suggestions, price filters

---

## 15. SYNC ARCHITECTURE AUDIT (June 12, 2026)

Conducted: June 12, 2026.

### 1. Current Sync Architecture

Two separate caching layers exist:

**Layer A — Offline Cache (`cache.py`):**
- `sync_all()`: full download of rate_list, categories, orders, images → written to `catalog.json`, `orders.json`, `sync_meta.json`
- `get_cached_catalog()`: reads `catalog.json` → returns items (with local image path fallback)
- `get_cached_categories()`: reads from same `catalog.json` → filters active
- `get_cached_orders()`: reads `orders.json`
- Called explicitly from Settings Sync page (`views/settings.py:view_sync_page`)
- Images downloaded once (skip if local path exists)

**Layer B — In-Memory State Cache (per-session):**
- `state["catalog_cache"]` (admin pricing catalogue background fetch)
- `state["orders_cache"]` (admin home background fetch)
- `state["customer_category_cache"]` (customer per-category lazy-load)
- `state["customer_categories"]` (customer dashboard categories)
- `state["orders_cache"]` (home page)

### 2. Flows That Still Full-Download

| Flow | Function | Table | Frequency | Payload |
|------|----------|-------|-----------|---------|
| Admin catalogue | `get_all_items()` | rate_list | Every navigation to catalogue (background thread) | All columns, all rows |
| Admin home | `get_orders_with_items()` | orders + order_items | Every navigation to home (background thread) | All columns, all rows, nested items |
| Settings sync | `get_rate_list()` (via `sync_all`) | rate_list | On manual trigger | All columns, all rows |
| Settings sync | `get_categories()` (via `sync_all`) | categories | On manual trigger | All columns, all rows |
| Settings sync | `get_orders_with_items()` (via `sync_all`) | orders + order_items | On manual trigger | All columns, all rows |
| Admin catalogue refresh | `get_categories(active_only=False)` | categories | On catalogue load | All columns, all rows |
| Admin settings (materials) | `get_materials()` | materials | Every settings page visit | All columns, all rows |
| Admin manage customers | `get_customers()` | customers | Every manage_customers visit | All columns, all rows |
| Customer search | `search_customer_items()` | rate_list | Per keystroke | All customer-visible rows, all columns |
| Customer dashboard (pre-refactor) | `get_customer_catalogue()` | rate_list | Was per-visit (now removed) | All customer-visible rows |

### 3. Flows Already Optimized

| Flow | Optimization | Mechanism |
|------|-------------|-----------|
| Customer dashboard | Category-first lazy load | Only `get_categories(active_only=True)` — no items fetched |
| Customer category items | Per-category DB filter | `get_customer_items_by_category(category)` — 1 category per call |
| Customer category cache | Repeated opens instant | `state["customer_category_cache"][category]` in-memory |
| Customer Add Again | Single-item fetch | `get_item_by_number(item_no)` — 1 row |
| Admin catalogue | Background cache | `state["catalog_cache"]` + background thread, preserves UI |
| Admin orders | Background cache | `state["orders_cache"]` + background thread, preserves scroll |
| Images | Already downloaded skip | `sync_all()` checks `os.path.exists()` before download |

### 4. Biggest Bandwidth/Memory Offenders (ranked)

1. **Admin catalogue load** (`get_all_items()`): ~500 rows × 15+ columns = heavy. Triggered every catalogue navigation.
2. **Admin home load** (`get_orders_with_items()`): All orders with nested items. Grows linearly with order count.
3. **Customer search** (`search_customer_items()`): Full catalogue per keystroke. Most wasteful per-use.
4. **Settings sync** (`sync_all()`): Full everything + image download. Only on manual trigger but heaviest single operation.
5. **Admin manage customers** (`get_customers()`): All customers every time page loads.

### 5. Cache Overwrite Behavior

- `catalog.json` and `orders.json` are **fully overwritten** every sync — no append/merge
- In-memory caches (`catalog_cache`, `orders_cache`) are **replaced entirely** on background fetch
- `customer_category_cache` is **append-only** (new categories added, never removed except on refresh)
- Images are **not re-downloaded** if local path exists

### 6. Existing Timestamp Columns

| Table | Column | Purpose |
|-------|--------|---------|
| `orders` | `status_updated_at` | Written on status change (`set_order_status`) |
| `customers` | `created_at` | Written on creation (`create_customer`) |
| `customers` | `last_active_at` | Written on PIN login (`set_customer_last_active`) |

**No `updated_at` columns exist on `rate_list`, `categories`, `materials`, `order_items`, `cost_breakdown`, `item_materials`.**

### 7. Current Schema Delta-Sync Readiness

**Not ready.** Delta sync requires:
- `updated_at` timestamp column (with index) on every table queried for sync
- `deleted_at` or a tombstone mechanism for deleted records (currently hard-deleted)
- Only `orders.status_updated_at` exists — insufficient for any table

### 8. Best Future Delta-Sync Strategy

**Phase 1 — Add `updated_at` columns (DB migration only):**
```sql
ALTER TABLE rate_list ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE categories ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE orders ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE order_items ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE customers ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE materials ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
```
+ Create trigger/index: `CREATE INDEX idx_rate_list_updated_at ON rate_list(updated_at);`

**Phase 2 — Last-sync tracking:**
- Store `last_sync_times` per table in `sync_meta.json` (already has `last_sync` key)
- Or use `app_settings` table for persistent key-value sync timestamps

**Phase 3 — Incremental fetch:**
```python
def get_changed_items(since: str) -> list:
    return _get("rate_list", f"updated_at=gt.{quote(since)}&order=updated_at.asc")
```

**Phase 4 — Local cache merge:**
- Instead of `json.dump` overwrite, read existing cache, merge/update changed records, write back
- Requires mutable cache file format (could keep full-rewrite for simplicity with small deltas)

### 9. Smallest Safe Implementation Plan

| Step | Effort | Impact | Risk |
|------|--------|--------|------|
| 1. Add `updated_at` + index to all sync tables | SQL only | Enables all future delta work | Low (new column, no code change) |
| 2. Add `search_customer_items_server()` with `ilike` | Low | Eliminates #3 bandwidth offender | Low (new function, old unchanged) |
| 3. Replace `get_all_items()` with minimal-column `select=necessary_cols` for admin catalogue | Low | Reduces payload per row | Low (add select param) |
| 4. Store `last_sync_*` per-table in `sync_meta.json` | Low | Prerequisite for delta fetch | Low |
| 5. Implement `get_changed_items(since)` + merge into cache | Medium | Full delta sync for rate_list | Medium (merge logic) |
| 6. Schedule lightweight periodic background sync | Medium | Automatic offline cache freshness | Medium (threading) |
| 7. Image invalidation via image URL hash/version | High | Cache-bust stale images | Low (append ?v= to URL) |

### 10. Priority Order for Optimization

1. **P0 — Customer search server-side `ilike`** (reduces #3 offender, very low risk, already audited separately)
2. **P1 — `updated_at` columns for rate_list + categories** (enables all delta work)
3. **P2 — Minimal-column admin catalogue queries** (reduces #1 offender payload per row)
4. **P3 — Incremental rate_list fetch + merge** (builds on P1)
5. **P4 — Incremental orders fetch + merge** (builds on P1)
6. **P5 — Periodic background sync** (builds on P3+P4)

### 11. Regression Risks

| Risk | Mitigation |
|------|------------|
| Merge logic bug corrupts local cache | Keep full-rewrite as fallback; version cache files |
| `updated_at` not set on existing records | `DEFAULT NOW()` handles new records; backfill via `UPDATE ... SET updated_at = NOW()` |
| Delta fetch missed records due to clock skew | Add 1-minute overlap: `updated_at >= since - 60s` |
| Image re-download on URL change | Compare URL hash in cache metadata; skip if same |
| Background sync conflicts with user interaction | Only sync when app is foregrounded; cancel if dialog open (reuse `render()` guard pattern) |

### 12. What Should NOT Be Optimized Yet

- **Orders delta sync:** Orders change infrequently; full fetch with background thread is acceptable for current scale
- **Customer delta sync:** Customers table is small (<200 rows); full fetch is fine
- **Materials/costing delta sync:** Admin-only, small tables; optimize if usage grows
- **Image cache invalidation:** Images rarely change; `os.path.exists()` skip works well
- **Websocket/live updates:** Overkill for 1-admin + few-customer scale; adds complexity
- **Background periodic sync for customer app:** Customer app already lazy-loads per-category; no benefit until offline cache freshness matters

---

## 16. PRODUCT TAGS + TAG MASTER SYSTEM — ARCHITECTURE AUDIT (June 12, 2026)

Conducted: June 12, 2026. No code changes — planning only.

### 1. Business Context

Categories are broad product families (Chuda, Metal Kangan, Kalira, Bhawari, Seep Patti). Products within a category need flexible filter labels (e.g., Chuda → Kundan, Dot, Antique, Golden, Maroon, Bridal). These labels are **not** a second category hierarchy — they are orthogonal filter dimensions.

### 2. Current Architecture Impact

**rate_list table** (used by `db.py`):
- Has `category` (single value) and `sub_category` (single value, nullable)
- `sub_category` is treated as a sub-filter; items can only have ONE sub_category
- No field exists for multiple tags per item
- All fetch functions (`get_all_items`, `get_rate_list`, `get_customer_items_by_category`, `search_customer_items`) return all columns — a new `tags` JSONB column would be included automatically

**categories table**:
- Has `sub_categories` (comma-separated string) — used for the customer subcategory grid
- This is metadata on the category, not per-item tags

**customer flow** (`views/customer.py`):
- Dashboard → category tap → either subcategory grid or items list
- Items are filtered by `sub_category` in `view_customer_items()` at line 545
- Items loaded per-category via `_get_category_items()` and cached in `customer_category_cache`
- Search (`search_customer_items`) filters client-side on `item_number`, `category`, `sub_category`

**admin Add/Edit form** (`views/pricing.py:58-100`):
- Has fields: item_number, category dropdown, sub_category dropdown, availability switch, has_sizes switch, has_color switch
- No tags input exists

**Tag Master comparison** — the closest existing UI patterns:
- **Material Master** (`views/settings.py:130-212`): TextField + rate + Add button; items listed as ListTile with delete
- **Manage Categories** (`views/settings.py:215-479`): Form card + card list with active/inactive toggle, edit, delete

**Cache** (`cache.py`):
- `catalog.json` stores `{"items": [...], "categories": [...], "synced_at": ...}`
- Each item dict is a full row from rate_list — a new `tags` column would be included automatically
- `get_cached_catalog()` returns items with image_url rewrite; tags would pass through unchanged
- `sync_all()` fetches via `db.get_rate_list()` — tags column already included

### 3. Recommended Schema: OPTION A — JSONB tags + tag_master table

**tag_master** (new table):
```sql
CREATE TABLE IF NOT EXISTS tag_master (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    category TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tag_master_name ON tag_master(name);
CREATE INDEX IF NOT EXISTS idx_tag_master_category ON tag_master(category);
```

**rate_list** (add column):
```sql
ALTER TABLE rate_list ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_rate_list_tags ON rate_list USING GIN(tags);
```

**Why Option A over Option B (normalized many-to-many):**

| Factor | Option A (JSONB) | Option B (item_tags) |
|--------|------------------|----------------------|
| Customer filter query | Local Python filter: `tag in item.get("tags", [])` — no DB re-fetch | Needs JOIN → more complex REST query; pre-load join data into cache |
| Offline cache | Tags stored inline in each item dict — zero format change | Needs separate cache file or nested structure |
| Admin tag selector | Loaded from tag_master, stored as JSON array | Needs JOIN on save/load |
| Tag rename | `UPDATE rate_list SET tags = ...` — iterates items with JSONB replace (small dataset, fine) | Simple UPDATE tag_master.name — no cascade |
| Supabase REST filter | `tags=cs.{tag_name}` (contains) — single param | Needs join query or subquery |
| Code complexity | Minimal — just a new column | New table, new queries, new cache logic |

At current scale (~500 items, 1 admin), Option A's rename-cascade cost is negligible, and the simplicity gain in all code paths is decisive.

### 4. Questions Answered

**Q1: Which schema for V1?** Option A — JSONB `tags` column on `rate_list` + `tag_master` table.

**Q2: Global or category-specific tags?** Both. Tags can have a `category` column (NULL = global). Customer filter shows only tags that appear in the current category's loaded items.

**Q3: Should tag_master include category_id/category_name?** Yes — a `category TEXT DEFAULT NULL` column. NULL means global tag. Non-NULL means tag is specific to that category. Simple category name string (no FK — avoids referential complexity).

**Q4: Customer filter — all tags or only used in current category?** Only tags that appear in the current category's loaded items. This is achieved by extracting unique tags from `item.get("tags", [])` after items are loaded per-category.

**Q5: Display name + slug?** Yes — `name` is the unique slug (lowercase, no spaces), `display_name` is human-readable (e.g., name="kundan", display_name="Kundan").

**Q6: Tag rename?** V1: Update tag_master.name + iterate all rate_list items containing old name, replace in JSONB array. This is a simple JSONB operation at current scale.

**Q7: Inactive tags in customer filter?** No — inactive tags (`tag_master.is_active = false`) should not appear in customer filter row, even if items still reference them. Items retaining an inactive tag are still shown but without a filter chip.

**Q8: Remove sub_category field later?** No — sub_category serves a different purpose (second-level category hierarchy used in subcategory grid view). Tags are orthogonal filters. Both coexist.

**Q9: Offline cache store tags?** Yes — tags JSONB is a column on rate_list, so it's already included in catalog.json items array. No cache format change needed.

**Q10: Search include tags?** Yes — `search_customer_items()` adds `q in (" ".join(item.get("tags", []))).lower()` to the client-side filter.

**Q11: Add/Edit Item multi-tag selector?** A `ft.Column` with toggle chips from tag_master, filtered by selected category. Selected tags stored as `state["selected_tags"]` list.

**Q12: SQL migrations needed?** Two: (1) CREATE tag_master table, (2) ALTER rate_list ADD COLUMN tags JSONB.

### 5. Recommended Product Tag Behavior (V1)

- Tags stored in `rate_list.tags` as JSONB array of strings (tag names)
- Tags chosen from tag_master — no free-text input
- Customer filter row shows tags extracted from the current category's items
- Inactive tags excluded from filter row even if items reference them
- Default selected tag = "All"
- Single-tap filter (V1); multi-select deferred

### 6. SQL Migrations Required

Two SQL statements, run in Supabase SQL Editor:

```sql
-- 1. Create tag_master table
CREATE TABLE IF NOT EXISTS tag_master (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    display_name TEXT NOT NULL,
    category TEXT DEFAULT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_tag_master_name ON tag_master(name);
CREATE INDEX IF NOT EXISTS idx_tag_master_category ON tag_master(category);

-- 2. Add tags column to rate_list
ALTER TABLE rate_list ADD COLUMN IF NOT EXISTS tags JSONB DEFAULT '[]'::jsonb;
CREATE INDEX IF NOT EXISTS idx_rate_list_tags ON rate_list USING GIN(tags);
```

Save as `sql/migration_add_tags.sql`.

### 7. Tag Master UI Recommendation

**Settings menu** (`views/settings.py`):
- Add `ListTile` after Material Master (line 41): `"Tag Master"` with `TAG` icon (or `LABEL`/`BOOKMARK`), routes to `"tag_master"`
- Add route in `main.py`, BACK_MAP entry

**Tag Master page** (new `views/tag_master.py` or inline in `views/settings.py`):

Follow **Material Master pattern** (simpler than Manage Categories):
```
Header: "🏷️ Tag Master" + subtitle
Add row: [TextField "Tag Name"] [TextField "Display Name"] [Dropdown "Category (optional)"] [Add button]
---
Existing tags (each as card):
  - Name (bold) + Display name (grey)
  - Category badge (if set)
  - Active pill / Inactive pill (click to toggle)
  - ✏️ Edit button → inline dialog: rename name + display_name + reassign category
  - 🗑️ Delete button → confirm dialog → `db.delete_tag()` — fails if items still use tag, shows error
```

**db.py functions needed:**
- `get_tag_master(active_only=False)` → list of tag dicts
- `add_tag(name, display_name, category=None)` → bool
- `update_tag(tag_id, name, display_name, category, is_active)` → bool
- `delete_tag(tag_id)` → bool (fails with Supabase FK or check)
- `get_items_by_tag(tag_name)` → list of item_numbers (for delete safety check)

No separate views file is strictly needed — Tag Master can be a new function in `views/settings.py` (~100 lines), following Material Master patterns (lines 130-212). If it grows, extract to `views/tag_master.py`.

### 8. Add/Edit Item Tag Selector Recommendation

In `view_add_item()` (`views/pricing.py`):

**After existing fields (after `has_color_switch`, line 100):**

1. On category_dd change or page load, load `db.get_tag_master(active_only=True)` → filter to global + matching category
2. Display as a section label "🏷️ Tags" + a `ft.Column` of toggle chips:

```python
tag_chips = []
selected_tags = state.setdefault("selected_tags", [])
available_tags = load_tags_for_category(selected_category)

for t in available_tags:
    is_selected = t["name"] in selected_tags
    chip = ft.Container(
        content=ft.Text(t["display_name"], size=12),
        bgcolor=indigo_100 if is_selected else grey_100,
        border_radius=16,
        padding=ft.Padding(left=12, right=12, top=6, bottom=6),
        on_click=lambda e, tn=t["name"]: toggle_tag(tn),
        ink=True,
    )
    tag_chips.append(chip)

tags_row = ft.Row(tag_chips, wrap=True, spacing=6, run_spacing=6)
```

3. `toggle_tag(tag_name)` function: adds/removes from `selected_tags`, updates chip bgcolors
4. On save (`on_save_and_generate`):
   - For existing items: new `db.update_item_tags(item_no, selected_tags)` PATCHes `tags` column
   - For new items: pass `tags=selected_tags` to `add_rate_item()`

**db.py new/updated functions:**
- `update_item_tags(item_number: str, tags: list) -> bool` — PATCH `{"tags": tags}`
- `update add_rate_item()` signature to accept optional `tags: list = None`

### 9. Customer Tag Filter UI Recommendation

In `view_customer_items()` (`views/customer.py`), after `_get_category_items()`:

**After items are loaded (line 541-546), extract unique tags:**

```python
# After items are loaded
all_tags = set()
for it in items:
    for t in it.get("tags", []):
        all_tags.add(t)
sorted_tags = sorted(all_tags)  # or sort by business order
```

**Before item grid, render filter row:**

```python
selected_tag = state.get("customer_selected_tag", None)

def on_tag_select(e, tag_name=None):
    state["customer_selected_tag"] = tag_name
    page.update()  # or page.go("customer_items") for re-render

tag_chips = [create_chip("All", selected_tag is None, lambda e: on_tag_select(e))]
for t in sorted_tags:
    tag_chips.append(create_chip(t, selected_tag == t, lambda e, tn=t: on_tag_select(e, tn)))

filter_row = ft.Container(
    content=ft.Row(tag_chips, scroll=ft.ScrollMode.AUTO, spacing=4),
    padding=ft.Padding(left=16, right=16, top=0, bottom=8),
)
```

**Filter items by selected tag:**

```python
if selected_tag:
    items = [it for it in items if selected_tag in it.get("tags", [])]
```

**Chip style:**
- Selected: indigo background, white text
- Unselected: grey_100 background, grey text
- Chips are horizontal scrolling (not wrap), to avoid vertical clutter
- "All" chip always first, highlighted when no tag selected

**Key design choices:**
- Filter is **local** — no new DB fetch needed (all category items already loaded)
- Tags come from loaded items, not from tag_master (handles offline cache automatically)
- Inactive tags are excluded during tag_master load in admin; on customer side, only tags present on items are shown
- Works with lazy-loaded category cache — tag filter applies to whatever items are in cache

### 10. Search Behavior

In `search_customer_items()` (`db.py:466-483`), add tags to the client-side filter:

```python
q in (" ".join(str(t) for t in (r.get("tags") or []))).lower()
```

This is added to the existing `or` chain:

```python
filtered = [r for r in rows if
    q in (r.get("item_number") or "").lower() or
    q in (r.get("category") or "").lower() or
    q in (r.get("sub_category") or "").lower() or
    q in (" ".join(str(t) for t in (r.get("tags") or []))).lower()]
```

Future optimization: Supabase `ilike` on JSONB tags text (or use `?` operator) when server-side search is implemented.

In `view_customer_search()` (`views/customer.py:590-629`), the offline fallback also needs the same tags filter added.

### 11. Offline/Cache Impact

**Minimal impact:**
- `tags` is a JSONB column on `rate_list` — it is automatically included in `_get("rate_list", ...)` results
- `sync_all()` → `catalog.json` — tags are stored inline in each item dict, no format change
- `get_cached_catalog()` — returns items with tags untouched
- `get_cached_categories()` — unrelated to tags
- No new cache files needed

**tag_master for offline:** Not needed in V1 for customer filter (tags extracted from loaded items, not from tag_master). For admin Add/Edit form, tag master is fetched live from DB (same as categories/materials are today). Deferred: cache tag_master in sync_meta or new file.

### 12. Implementation Phases

| Phase | Scope | Estimated Effort | Files Changed | Risk |
|-------|-------|-----------------|---------------|------|
| **P1 — Foundation** | SQL migration + db.py functions (CRUD for tags) | Low (~50 lines) | `db.py`, `sql/migration_add_tags.sql` (new) | Low — new table + column, safe |
| **P2 — Admin Tag Master UI** | Settings page for CRUD tags | Low (~100 lines) | `views/settings.py`, `main.py` | Low — follows Material Master pattern |
| **P3 — Admin tag selector** | Multi-tag chip selector in Add/Edit form + save tags | Medium (~80 lines) | `views/pricing.py`, `db.py` | Low — new UI element, existing save path |
| **P4 — Customer tag filter** | Horizontal chip row, local tag filter | Medium (~60 lines) | `views/customer.py` | Medium — affects customer flow |
| **P5 — Search + polish** | Tags in search, inactive tag handling, delete safety | Low (~30 lines) | `db.py`, `views/customer.py` | Low — additive changes |

### 13. Regression Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Old items without `tags` field | Customer filter row shows "All" only — acceptable | `.get("tags", [])` in all reads |
| Tag rename doesn't cascade to item tags | Stale tag names in items | Rename function: UPDATE rate_list SET tags = jsonb_set(...) WHERE tags @> '["old_name"]'; |
| Customer filter chip count too high | Horizontal scroll overflow | Use `ft.Row(scroll=ft.ScrollMode.AUTO)` — horizontal scroll, no vertical clutter |
| Offline cache without tags | `.get("tags", [])` returns empty | No crash, customer filter shows "All" only |
| tag_master fetch failure in admin form | No tags shown | Fallback to empty list; item saves without tags |
| Delete tag used by items | Orphan tag references in items | `delete_tag()` checks `SELECT COUNT(*) FROM rate_list WHERE tags @> '["name"]'` first; refuses if > 0 |
| GIN index size growth | Minimal at ~500 items | Acceptable for current scale |

### 14. What Should Be Postponed

| Feature | Reason | Revisit When |
|---------|--------|--------------|
| **Category-specific tag master validation** (restrict tag assignment to matched category) | V1 can show all active tags; category is informational | Phase 6 or user request |
| **Multi-tag customer filter** (select multiple chips) | V1 is single-tap only | User request |
| **Tag reorder / priority** (control chip order in customer filter) | Alphabetic sort is fine for V1 | User request |
| **tag_master offline cache** | Not needed — tags extracted from loaded items | If sync without DB needed for tag management |
| **Auto-cascade tag rename to items** | Manual batch function or skip; rename is rare | If rename becomes frequent |
| **Supabase server-side tag search (`ilike`)** | Already planned in Search Audit Phase 1; add tags then | When search is optimized |
| **Admin bulk tag assignment** | Use Add/Edit per item for now | If bulk operation needed |
| **Customer filter "clear all"** | Single-tap mode doesn't need it | When multi-select is added |

### 15. Summary of Code Changes (per file)

| File | What Changes |
|------|--------------|
| `db.py` | New: `get_tag_master()`, `add_tag()`, `update_tag()`, `delete_tag()`, `get_items_by_tag()`, `update_item_tags()`. Modified: `add_rate_item()` (optional tags param), `search_customer_items()` (tags in filter) |
| `sql/migration_add_tags.sql` (new) | CREATE tag_master, ALTER rate_list ADD tags JSONB |
| `views/settings.py` | New: `view_tag_master()` function (~100 lines). Modified: settings menu adds Tag Master ListTile |
| `main.py` | New route `"tag_master"`, BACK_MAP entry |
| `views/pricing.py` | Modified: `view_add_item()` adds tag chip selector section, `on_save_and_generate()` includes tags in save |
| `views/customer.py` | Modified: `view_customer_items()` adds tag filter row and local tag filtering |
| `startup_progress.md` | Track migration run status |

### 16. Flet 0.28.3 UI Constraints for Tag Implementation

| Constraint | Impact | Workaround |
|------------|--------|------------|
| No native multi-select component | Cannot use ft.Dropdown with multiple | Use toggle chips (ft.Container with on_click) in a Row(wrap=True) |
| ft.Dropdown on_change (not on_select) | For dropdown-based tag picking | Use on_change for any category dropdown that filters tags |
| ft.Container with ink=True | For chip tap feedback | Add ink=True to tag chip containers for visual feedback |
| ft.Row(wrap=True) for chip wrapping | Available and works | Use for admin tag selector overflow |
| ft.Row(scroll=AUTO) for horizontal scroll | Available and works | Use for customer filter row to avoid vertical clutter |
| ft.ListView tag count mismatch (BUG-017) | Tag filter row must NOT be directly in ListView | Wrap filter row + item grid in a Column, then put Column in ListView |

### 17. V1 UI Sketches (Text)

**Admin Add/Edit Item — Tags section:**
```
┌─────────────────────────────────────────────────┐
│  🏷️ Tags                                        │
│                                                 │
│  [kundan] [dot] [antique] [golden] [bridal]     │
│  [maroon]  [rose-gold]  [silver]                │
│                                                 │
│  (tap to toggle — selected chips highlighted)    │
└─────────────────────────────────────────────────┘
```

**Customer Items — Tag filter row:**
```
┌─────────────────────────────────────────────────┐
│  Chuda                                          │
│                                                 │
│  [All] [Kundan] [Dot] [Antique] [Golden] →      │
│                                                 │
│  ┌──────┐  ┌──────┐  ┌──────┐                   │
│  │ img  │  │ img  │  │ img  │                   │
│  │ CH-1 │  │ CH-2 │  │ CH-3 │                   │
│  │ ₹450 │  │ ₹550 │  │ ₹650 │                   │
│  └──────┘  └──────┘  └──────┘                   │
└─────────────────────────────────────────────────┘
```

**Tag Master (Settings):**
```
┌─────────────────────────────────────────────────┐
│  🏷️ Tag Master                                  │
│  Manage product tags for filtering               │
│                                                 │
│  [Tag Name] [Display Name] [Category ▼] [➕Add]  │
│  ─────────────────────────────────────────────── │
│  ┌─────────────────────────────────────────────┐ │
│  │ kundan                           ● Active   │ │
│  │ Kundan                           [✏️] [🗑️]  │ │
│  │ Chuda category                              │ │
│  ├─────────────────────────────────────────────┤ │
│  │ dot                              ● Active   │ │
│  │ Dot Chuda                        [✏️] [🗑️]  │ │
│  │ Chuda category                              │ │
│  └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### 18. First-Time Migration Sequence

1. Run SQL in Supabase SQL Editor (create tag_master table + add tags column)
2. Populate tag_master with initial tags from user's business knowledge
3. (Optional) Batch-update existing items: `UPDATE rate_list SET tags = '["kundan"]' WHERE ...`
4. Deploy code with db.py, settings UI, add/edit selector, customer filter
5. APK build via CI → deploy

### 19. Phase P1 Implementation (June 12, 2026)

**Completed — backend infrastructure for tags:**

| Item | Status |
|------|--------|
| `sql/migration_add_tags.sql` | Created — verified: tag_master table + 6 columns, rate_list.tags JSONB column, UNIQUE constraint, RLS disabled all confirmed present in Supabase |
| `db.py:get_tag_master()` | Added — fetches from tag_master, optional active_only filter |
| `db.py:add_tag()` | Added — normalizes name to lowercase slug, validates |
| `db.py:update_tag()` | Added — updates name/display_name/category/is_active |
| `db.py:delete_tag()` | Added — safety check: refuses if any item references tag |
| `db.py:get_items_by_tag()` | Added — queries rate_list where tags contains tag_name |
| `db.py:update_item_tags()` | Added — PATCHes tags JSONB on rate_list |
| `db.py:add_rate_item()` | Modified — accepts optional `tags` param, backward compatible |
| `db.py:search_customer_items()` | Modified — includes tags in client-side search filter |

**Delete safety:** `delete_tag()` first fetches the tag name, then queries `rate_list` with `tags=cs.%22{tag_name}%22` (JSONB contains). If any item uses the tag, returns False without deleting.

**Search update:** `search_customer_items()` now also matches against tags: `q in (" ".join(str(t) for t in (r.get("tags") or []))).lower()`

### 20. Phase P2 Implementation (June 12, 2026 — updated June 13)

**Completed — Tag Master admin UI:**

| Item | Status |
|------|--------|
| `views/settings.py:view_tag_master()` | Added — CRUD UI for tag management |
| `views/settings.py` settings menu | Tag Master ListTile added (purple LABEL icon, between Material Master & Manage Customers) |
| `main.py` route | `"tag_master"` → `v_settings.view_tag_master(page)` |
| `main.py` BACK_MAP | `"tag_master": "settings"` |

**UI structure:**
- Title bar: "🏷️ Tag Master" with subtitle
- Add row: single "Tag Name" TextField (auto-derived slug) + Category (optional) dropdown + green Add button
- Divider
- Scrollable tag list, each in a bordered Container:
  - Display name (bold 15px) + Active/Inactive pill
  - Slug (grey `name` text)
  - Category badge (if set) — small indigo pill
  - Edit + Delete `TextButton`s, right-aligned
  - Tappable active/inactive circle (●) on far right

**Active/inactive toggle:** Click the ●/○ circle — calls `db.update_tag()` with inverted `is_active`. Refreshes list on success. Red snackbar on failure.

**Edit flow:** Opens `AlertDialog` with Display Name TextField + Category dropdown + Status dropdown (Active/Inactive). Slug auto-derived from display name. Save calls `db.update_tag()`. Red snackbar on failure.

**Delete flow:** Confirmation `AlertDialog`. Calls `db.delete_tag(id)`. On `False`: red snackbar `"❌ Tag is used by items and cannot be deleted"`. On success: refreshes list, green snackbar.

**Design choices:**
- Follows Material Master pattern (single-view, inline add row, compact list)
- No `ft.Card` — uses `ft.Container` with border
- Active/inactive as pill text chip, not `ft.Switch`
- Category dropdown loaded from `db.get_categories(active_only=True)` with "Global (any category)" default
- No nested scrollables — single `ft.Column(scroll=AUTO)` wrapper
- State: no caching needed — fetched fresh from DB on render
- Tag Name field removed: slug auto-derived from display name (`dn.strip().lower().replace(" ", "_")`)

**Bug fixes applied (June 13):**
| Bug | Root Cause | Fix |
|-----|-----------|-----|
| White screen on dialog close | `page.overlay.remove(dlg)` after `dlg.open=False` causes Flutter null-check crash in Flet 0.28.3 | Removed all 4 `page.overlay.remove(dlg)` calls — close pattern is now `dlg.open=False; page.update()` only |
| Save shows "Failed to update" on non-last tags | Python late-binding closure: `tag_name`/`display_name`/`cat`/`is_active` from for-loop captured by reference, always resolved to last iteration's values | Passed all 4 variables as parameters to `make_edit()`, `make_delete()`, `make_toggle()` factory functions |

**Phase P4 implemented (June 13, 2026):** Customer tag filter row completed. See Section 22.

### 21. Phase P3 Implementation (June 13, 2026)

**Completed — Multi-tag selector in Add/Edit Item form:**

| Item | Status |
|------|--------|
| `views/pricing.py` tag chip UI | Added — wrap-enabled chip row below switches, above image picker |
| Category-tag filter | Tags filtered by selected category + global (null category) tags, active only |
| Toggle behavior | Tap chip to select/deselect, immediate visual feedback, no full page rebuild |
| New item save | `tags=state["selected_tags"]` passed to `add_rate_item()` |
| Edit item save | `db.update_item_tags()` called after other updates, preserves unknown tags |
| Edit preload | Existing item tags loaded into `state["selected_tags"]`, chips pre-highlighted |
| Form reset | Tags cleared on form reset after save |
| Closure safety | `lambda e, tn=tag_name: _toggle_tag(tn)` — default-arg capture avoids late-binding bug |

**Architecture:**
- `state["selected_tags"]` — `list[str]` of selected tag slugs, maintained in state
- `_displayed_tags` — closure-scoped list of active tag dicts for current category
- `_rebuild_tag_chips()` — clears + rebuilds `tags_row.controls` from `_displayed_tags` + `state["selected_tags"]`
- `_load_tags_for_category(cat_name)` — queries `db.get_tag_master(active_only=True)`, filters by category match, triggers chip rebuild
- `_toggle_tag(tag_name)` — adds/removes from `state["selected_tags"]`, triggers chip rebuild
- Category change: clears `selected_tags`, loads tags for new category
- Item lookup edit: loads `existing.get("tags")` into `selected_tags`, triggers chip rebuild
- Save (new): `tags=state.get("selected_tags", [])` passed to `add_rate_item()`
- Save (edit): `db.update_item_tags(item_no, state.get("selected_tags", []))` after other updates

**Files changed:**
| File | Changes |
|------|---------|
| `views/pricing.py` | Added ~50 lines: tag helpers (`_rebuild_tag_chips`, `_load_tags_for_category`, `_toggle_tag`), tag row UI, modified 3 functions (`on_category_select`, `on_item_lookup`, `on_save_and_generate`), modified form reset |

### 22. Phase P4 Implementation (June 13, 2026)

**Completed — Customer tag filter row:**

| Item | Status |
|------|--------|
| `views/customer.py:view_customer_items()` | Added tag extraction from loaded items + in-place filter |
| `views/customer.py:view_customer_dashboard()` | Added `state["customer_selected_tag"] = None` on category change |

**Architecture:**
- Tag chips extracted from `it.get("tags", [])` across all loaded items for current category — no DB call, works offline
- Display name derived from slug: `slug.replace("_", " ").title()` — no `tag_master` fetch needed
- Chips are horizontally scrollable (`ft.Row(scroll=AUTO)` in a fixed-height Container) — NOT wrap
- `_rebuild_items()` function rebuilds both chip row and item cards in-place via `page.update()` — no navigation, no image reload, no re-fetch
- Factory functions `_make_all_chip()` and `_make_tag_chip(slug)` avoid late-binding closure bugs
- Selected chip: indigo background, white text. Unselected: grey background, dark text.
- "All" chip always first, highlighted when no filter active
- Empty filtered state shows SEARCH_OFF icon + "No items found for this filter"

**Filter lifecycle:**
- Default: "All" (no filter), all items shown
- Chip tap → sets `state["customer_selected_tag"]` → `_rebuild_items()` updates chip colors + filters cards → `page.update()`
- Category change (via dashboard) → `customer_selected_tag` reset to `None`
- Back from item detail → tag preserved (state persists across renders)
- Category cache cleared (refresh) → `customer_selected_tag` reset to `None`

**Key design choices:**
- Local-only filter — no DB queries, no network dependency
- Tags come from loaded items (not tag_master) — works identically online and offline
- `state.setdefault("customer_selected_tag", None)` — first-visit default; persists across renders within same category session
- In-place rebuild (no `page.go`) — instant tap response, scroll position preserved
