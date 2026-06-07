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
- **CI Token:** Classic PAT with `repo` + `workflow` scopes (`***REMOVED***` — remove from remote URL after each push)
- **Latest version:** v1.0.8 (build 4)

---

## 2. FILE STRUCTURE

| File | Purpose | Sensitivity |
|------|---------|-------------|
| `main.py` | Entry point, navigation (`go`, `go_back`, `render`), state management, exit dialog, AppBar, NavBar | **HIGH** — most frequently modified |
| `db.py` | Supabase REST API layer — all CRUD operations via httpx | **HIGH** — do not touch casually |
| `utils.py` | Common helper functions | Low |
| `cache.py` | Offline caching logic for database sync | Low |
| `card_generator.py` | Order slip / PDF generation logic | Low |
| `session_helper.py` | Session save/load/clear for all roles | Low (created June 8, 2026) |
| `views/auth.py` | Role selection / login screen | Low (pick_role saves session for admin/labour) |
| `views/home.py` | Admin/Labour dashboard — order list | Low (has background fetch thread) |
| `views/orders.py` | Order creation forms, order detail, karigar slip | Low |
| `views/pricing.py` | Cost calculation, rate lists, margins | Low |
| `views/settings.py` | Admin settings, category management, sync | Low |
| `views/customer.py` | Customer catalogue, cart, items, search | Low |
| `pyproject.toml` | Flet build config (excludes `product_images`, `build/`, etc.) | **HIGH** — do not touch casually |
| `.github/workflows/build_apk.yml` | CI workflow — pins Flutter 3.24.0, caches debug keystore | **HIGH** — do not touch casually |
| `PROJECT_MEMORY.md` | This file — single source of truth | Update after every session |

---

## 3. DATABASE SCHEMA (Supabase Cloud)

| Table | Key Columns |
|-------|-------------|
| **`categories`** | `id`, `name`, `icon`, `color`, `description`, `sub_categories`, `order_type`, `is_active`, `cover_image_url` |
| **`rate_list`** | `item_number`, `image_url`, `cost_price`, `selling_price`, `category`, `sub_category`, `has_sizes`, `has_color`, `card_path`, `is_available`, `margin_percent`, `status` |
| **`orders`** | `order_id`, `customer_name`, `order_date`, `color`, `grind_type`, `box_type`, `packing_structure`, `additional_info`, `total_amount`, `source`, `customer_mobile` |
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
| CI (via `subosito/flutter-action@v2`) | 3.24.0 | GitHub Actions — **works** |

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
Login (Select Dashboard)
  ├── Admin → home
  ├── Labour → home
  └── Customer → customer_name_entry → customer_dashboard

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
}
```

### Session Persistence

- **File:** `customer_session.json` in `FLET_APP_STORAGE_DATA` or `"."`
- **Format:** `{"role": "admin"|"labour"|"customer", "username": "...", "customer_mobile": "..."}`
- **Helper module:** `session_helper.py` — `save_session(state)`, `load_session()`, `clear_session()`
- **Backward compatible:** Old customer-only sessions (no `role` field, just `name`/`mobile`) restored as customer
- **Save triggers:** Admin/labour saved on role pick in `views/auth.py`. Customer saved in `views/customer.py` on name submit.
- **Restore:** On app start in `main.py` — routes to correct dashboard based on role.
- **Clear:** On `logout()` — deletes session file, resets state to login.

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
| **Root Cause** | GitHub Actions runners are ephemeral. Flutter generates a new random `~/.android/debug.keystore` on every build, so each APK has a different signing signature. Android rejects certificate mismatch. |
| **Fix** | Cache `~/.android/debug.keystore` via `actions/cache@v4` with key `android-debug-keystore-${{ runner.os }}`. First build after fix generates + caches keystore; subsequent builds reuse it. |
| **Files** | `.github/workflows/build_apk.yml` |
| **Note** | First v1.0.8 build will still need uninstall (no cache yet). Subsequent builds update in-place. |

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
| **Root Cause** | Unknown — suspected `page.window.destroy()` either fails silently at Flet/Flutter level on this Android version, or the method attribute access fails. The try/except wrapper didn't catch it (no error printed) → suggests Flet accepted the call but Flutter didn't act on it. |
| **Fix** | Pending — needs investigation. Possible approaches: (1) verify `page.window.destroy()` is correct property vs `page.window_destroy()` method in Flet 0.28.3; (2) test alternative close APIs like `page.window.close()` or `ft.app(close=True)`; (3) use `import sys; sys.exit(0)` if running as main process; (4) fallback: minimize to background instead of closing. |
| **Files** | `main.py` (show_exit_dialog → handle_exit handler) |
| **Note** | Priority: MEDIUM. The Cancel path works correctly. User can still exit via OS task switcher. This is not a white-screen or data-loss bug. |

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
- Exit Confirmation Dialog — Cancel works, Exit closes dialog but does NOT close app (BUG-013)
- Background Fetch Guard (render skips when dialog open)
- Consistent APK Signing (cached debug keystore)

### 🔄 Pending Verification (needs real Android testing)
- Logout button across all roles
- Exit dialog back-dismiss behavior
- White screen after force-stop/reopen

### ❌ Blocked
- **WhatsApp Sharing** — `ft.Share` API changed in Flet 0.28.3; no replacement found yet
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
4. Download `mahalaxmi-bangles-v1.0.8.zip`
5. Extract to get the `.apk` file

### CI Environment
| Component | Version |
|-----------|---------|
| OS | ubuntu-latest |
| Python | 3.11 |
| Flet | 0.28.3 |
| Flutter | 3.24.0 (pinned via `subosito/flutter-action@v2`) |
| Java | 17 (Temurin) |
| Signing | Debug keystore cached via `actions/cache@v4` |

### Workflow file
`.github/workflows/build_apk.yml` — do not modify unless you understand the Flutter native-assets constraint.

---

## 10. RISK ASSESSMENT

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| White screen on real Android (back button) | High | Low | No pop in `on_view_pop_handler`; dialog handler restores views via `render()`; `render()` guard prevents background-thread corruption |
| `page.window.destroy()` fails on Android | Medium | Medium | Wrapped in try/except; app stays open if close fails |
| Background thread calls `render()` during dialog | Medium | Low | Guard at top of `render()` skips execution when dialog open |
| Exit dialog not rendering (Flet 0.28.3 overlay API issues) | Medium | Low | Same `page.overlay.append()` pattern as 2 other dialogs in codebase |
| First build after keystore cache miss needs uninstall | Low | Certain (once) | Cache is populated after first build; subsequent builds update in-place |
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
# Actions → latest run → Artifacts → mahalaxmi-bangles-v1.0.8.zip

# Git push with PAT:
git push https://***REMOVED***@github.com/rajatchawla66/mahalaxmi-bangles.git main
# Always reset remote URL after push:
git remote set-url origin https://github.com/rajatchawla66/mahalaxmi-bangles.git

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
| June 8, 2026 | Exit button not closing app — logged as BUG-013. Moved 3 legacy context files to archive/. Tagged for tomorrow. | PROJECT_MEMORY.md | Pending — BUG-013 unresolved |
| June 8, 2026 | Project memory consolidation: merged 3 context files into PROJECT_MEMORY.md | PROJECT_MEMORY.md (new), archive/PROJECT_CONTEXT.md, archive/PROJECT_HANDOVER.md, archive/contextD.md | Complete |
| June 8, 2026 | Exit dialog guard: added render() skip-return when dialog open; removed on_dismiss; simplified cancel/exit flow | main.py | Complete — pushed, CI building |
| June 8, 2026 | Keystore caching: added actions/cache for ~/.android/debug.keystore; bumped to v1.0.8 | .github/workflows/build_apk.yml | Complete — pushed, CI building |
| June 8, 2026 | Exit dialog + white screen fix: removed view pop from handler; switched dialog to overlay API; defensive view guard | main.py | Complete — pushed, CI building |
| June 8, 2026 | Session restore for all roles + exit confirmation dialog | session_helper.py (new), main.py, views/auth.py | Complete |
| June 7, 2026 | Initial CI setup, git init, first APK build, back-button fix, PROJECT_CONTEXT.md | Multiple | Complete |
