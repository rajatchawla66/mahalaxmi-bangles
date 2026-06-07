# PROJECT_CONTEXT.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 1 — PROJECT OVERVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**App Name:** Mahalaxmi Bangles  
**Business Context:** Wholesale Bridal Chuda & Bangles Order Management  
**Tech Stack:** Python, Flet (GUI), Supabase REST API (via `httpx`), SQLite (Offline caching)  
**Build Command:** `flet build apk` (via GitHub Actions CI - see Section 9)  
**Flet Version:** 0.28.3  
**CI/CD:** GitHub Actions workflow at `.github/workflows/build_apk.yml`  
**Known Version-Specific Rules:** 
- Flet 0.28.3 does not support `page.client_storage` on Android; must use file-based JSON caching (`customer_session.json`).
- `page.window_destroy()` is unstable/unsupported on Android.
- Avoid manual `page.views` dummy interceptor manipulation on Android as it causes white screens. Rely on `page.controls` replacement for single-page routing where possible.
- APK building on Windows is broken due to Flutter 3.29.2's `objective_c` native-assets requirement. Build via GitHub Actions CI instead.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 2 — FILE STRUCTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- `main.py`: **[DO NOT TOUCH CASUALLY]** Main entry point, state management, top-level layout (AppBar, NavBar), and navigation router (`go`, `go_back`).
- `db.py`: **[DO NOT TOUCH CASUALLY]** Database abstraction layer. Directly queries Supabase via REST API endpoints (`httpx`).
- `utils.py`: Common helper functions.
- `cache.py`: Offline caching logic for database sync to allow offline operation.
- `card_generator.py`: Order slip / PDF generation logic.
- `views/home.py`: Admin/Labour dashboard showing the list of latest orders.
- `views/orders.py`: Forms for creating new orders and viewing order details.
- `views/pricing.py`: Cost calculation, rate lists, and margins management.
- `views/settings.py`: Admin settings panel and Category management.
- `views/customer.py`: Customer dashboard, category grid, and item catalogue for end-users.
- `views/auth.py`: Simple mock login and role-selection screen.
- `pyproject.toml`: **[DO NOT TOUCH CASUALLY]** Build configuration, explicitly excludes dynamically generated folders (e.g., `product_images`) from APK compilation.
- `.github/workflows/build_apk.yml`: **[DO NOT TOUCH CASUALLY]** GitHub Actions workflow for automated APK builds. Uses Flutter 3.24.0 on ubuntu-latest to avoid the native-assets build bug.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 3 — DATABASE SCHEMA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*Supabase Cloud Database Tables:*

- **`categories`**: `id`, `name`, `icon`, `color`, `description`, `sub_categories`, `order_type`, `is_active`, `cover_image_url` (recently added).
- **`rate_list`**: `item_number`, `image_url`, `cost_price`, `selling_price`, `category`, `sub_category`, `has_sizes`, `has_color`, `card_path`, `is_available`, `margin_percent`, `status`.
- **`orders`**: `order_id`, `customer_name`, `order_date`, `color`, `grind_type`, `box_type`, `packing_structure`, `additional_info`, `total_amount`, `source`, `customer_mobile`.
- **`order_items`**: `order_id`, `item_number`, `category`, `qty_2_2`, `qty_2_4`, `qty_2_6`, `qty_2_8`, `qty_2_10`, `quantity`, `unit`, `color`, `grind_type`, `box_type`, `notes`, `unit_price`.
- **`materials`**: `id`, `name`, `rate`, `unit`, `category`.
- **`cost_breakdown`**: `item_number`, `material_id`, `material_name`, `quantity`, `unit`, `rate_per_unit`, `line_total`.
- **`item_materials`**: `item_number`, (along with material assignment fields).
- **`app_settings`**: `key`, `value`.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 4 — ARCHITECTURE RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Rules that must never be broken:**
- **Flet Version Specifics (0.85.2):** Strictly avoid `client_storage` and `window.destroy()`. 
- **Navigation Patterns:** Currently using a single-view `page.controls` replacement approach. Wait for explicit instructions before trying to reinvent or intercept the Android hardware back button stack behavior.
- **State Management Patterns:** All global state must be kept inside `page.state` dictionary. State resets should occur explicitly in the `logout()` function.
- **Known Incompatibilities:** Do NOT use `flet_build.yaml` for APK configuration; use the `[tool.flet.app]` block inside `pyproject.toml` instead.
- **APK Build (Windows):** Broken on local Windows due to Flutter 3.29.2 `objective_c` native-assets bug. Always build via GitHub Actions CI.
- **GitHub Actions Workflow:** The workflow at `.github/workflows/build_apk.yml` pins Flutter 3.24.0 to avoid the native-assets bug. Do not change Flutter version without testing.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 5 — FEATURES STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- ✅ Customer Dashboard & Catalogue
- ✅ Admin Settings & Category Management
- ✅ Sync & Offline Capabilities
- ✅ Order Creation & Flow
- ✅ APK Build via GitHub Actions CI (Flutter 3.24.0, Python 3.11, Flet 0.28.3)
- 🔄 Logout Button (Popup Menu fix pending verification)
- ❌ Navigation & Hardware Back Button (Currently closes the app instead of popping the stack)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 6 — BUG HISTORY LOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- **BUG:** White screen on root back press
  **DATE:** June 2026
  **SYMPTOM:** Pressing hardware back on the home screen causes a white screen on Android.
  **ROOT CAUSE:** Native Flet routing conflict when manually pushing a dummy `ft.View` into `page.views`.
  **FIX:** Ripped out `page.views` manipulation entirely and switched to standard `page.controls.clear()` rendering logic.
  **LESSON:** Do not manually manipulate `page.views` arrays with dummy interceptors on Flet 0.85 Android.
  **FILES CHANGED:** `main.py`

- **BUG:** APK Size Ballooning by 15MB
  **DATE:** June 2026
  **SYMPTOM:** Flet APK build size bloated unnecessarily.
  **ROOT CAUSE:** Flet compiler was silently grabbing generated cache folders (e.g., `product_images`).
  **FIX:** Added `exclude` arrays into `pyproject.toml` and `.gitignore`.
  **LESSON:** Always maintain strict exclusion lists for dynamically generated assets in the build config.
  **FILES CHANGED:** `pyproject.toml`, `.gitignore`

- **BUG:** Admin/Labour logout button not working
  **DATE:** June 2026
  **SYMPTOM:** Clicking logout in the AppBar popup menu silently fails and doesn't change the screen.
  **ROOT CAUSE:** Destroying the `AppBar` synchronously while the Flet `PopupMenuItem` overlay is trying to close causes the Flutter client to freeze/drop the routing update.
  **FIX:** Replaced the child `PopupMenuItem.on_click` logout wiring with parent-level `PopupMenuButton.on_select` handling and `data="logout"` on the logout item.
  **LESSON:** Never rebuild the whole page from a child popup-menu item callback on Flet 0.85 Android; use the menu button selection event instead.
  **FILES CHANGED:** `main.py`

- **BUG:** AppBar PopupMenu logout works only from Settings tab
  **DATE:** June 7, 2026
  **SYMPTOM:** Admin/Labour top-right three-dot logout does not work on Home tab, but logout works from Settings and customer dashboard logout works.
  **ROOT CAUSE:** The AppBar `PopupMenuItem.on_click` path is unreliable on Android when it triggers a full AppBar/body rebuild from inside the popup item callback. The previous `threading.Timer` workaround was also unsafe because it mutated Flet page state from a background thread.
  **FIX:** `logout_from_popup()` now runs only from `PopupMenuButton.on_select`; the Logout menu item carries `data="logout"` and no longer has its own `on_click`.
  **LESSON:** For Flet 0.28.3 AppBar popup actions, use parent `PopupMenuButton.on_select` plus menu item data; avoid child item callbacks, timers, and background-thread page updates.
  **FILES CHANGED:** `main.py`

- **BUG:** RangeError (length 12) in Pricing/Costing
  **DATE:** June 7, 2026
  **SYMPTOM:** RangeError flooded the console when opening Costing tab or detail view in Flet 0.28.3.
  **ROOT CAUSE:** Nested combinations of `ft.ListView`, `ft.Tabs`, and `ft.ResponsiveRow` triggered an internal 12-column grid calculation error in the Flutter renderer. `expand=True` within `ft.Row` children was the primary trigger.
  **FIX:** Systematically removed `ft.ResponsiveRow` and `expand=True` (on Row children) from `pricing.py`, `settings.py`, and `orders.py`, replacing them with standard `ft.Row`/`ft.Column` and fixed widths. Replaced top-level `ft.ListView` with `ft.Column(scroll=ft.ScrollMode.AUTO)`.
  **LESSON:** Avoid `ResponsiveRow` and `expand=True` inside `ft.Row` in Flet 0.28.3 to prevent grid indexing crashes.
  **FILES CHANGED:** `views/pricing.py`, `views/settings.py`, `views/orders.py`

- **BUG:** APK build fails with `objective_c` native-assets error
  **DATE:** June 7, 2026
  **SYMPTOM:** `flet build apk` fails during "Packaging Python app" stage with: `Package(s) objective_c require the native assets feature to be enabled.`
  **ROOT CAUSE:** Flet 0.28.3 hardcodes Flutter 3.29.2 which ships Dart 3.10+. The `serious_python` transitive dependency `objective_c 9.4.1` requires `--enable-experiment=native-assets`, but Flet CLI's `dart run serious_python:main` command doesn't include this flag. `DART_VM_OPTIONS` env var and `--flutter-build-args` do not apply at the packaging step.
  **FIX:** Moved APK builds to GitHub Actions CI using `subosito/flutter-action@v2` with Flutter 3.24.0 (pre-native-assets era). Also tried `--template-ref 0.27.0` as a local workaround (packaging succeeds but Gradle fails with `webview_flutter_android` Dart version mismatch).
  **LESSON:** Flet 0.28.3 APK builds are broken on any system that auto-downloads Flutter 3.29.2. Always pin an older Flutter version via CI. Local Windows builds are not viable for this project.
  **FILES CHANGED:** `.github/workflows/build_apk.yml`, `.gitignore`, `PROJECT_CONTEXT.md`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 7 — CURRENT SESSION STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Most recently working on:** Fixed the APK build blocker by setting up GitHub Actions CI. Local Windows builds are permanently blocked by Flutter 3.29.2's `objective_c` native-assets requirement.

**Currently Broken (local Windows build):** 
- APK build on Windows fails due to Flutter 3.29.2 + `objective_c 9.4.1` native-assets incompatibility. No known workaround without modifying Flet CLI source code.

**Resolved via GitHub Actions CI:**
- First APK built successfully on June 7, 2026 using Flutter 3.24.0 + Python 3.11 + Flet 0.28.3 on ubuntu-latest.
- Workflow file: `.github/workflows/build_apk.yml`
- To trigger a new build: Push to `main` branch or go to Actions tab → "Build Android APK" → "Run workflow".

**Needs Testing:** Install the CI-built APK on an actual Android device and verify layout stability, logout functionality, and navigation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 8 — PENDING FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Rebuild a stable, Android-compatible Navigation Stack that pops views correctly upon a hardware back button press, without resorting to broken `page.views` interceptor hacks.
2. Verify full functionality of the Logout feature across all roles.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## SECTION 9 — CI/CD BUILD PROCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

### How to build APK

All APK builds run via **GitHub Actions CI**. Local Windows builds are broken and not supported.

**Trigger a build:**
1. Push code to `main` branch (auto-triggers)
2. Or go to https://github.com/rajatchawla66/mahalaxmi-bangles/actions → "Build Android APK" → "Run workflow" (manual trigger)

**Download APK:**
1. Wait for build to complete (~15-25 min)
2. Click the completed workflow run
3. Scroll to **Artifacts** section
4. Download `mahalaxmi-bangles-v1.0.7.zip`
5. Extract to get the `.apk` file

### CI Environment

| Component | Version |
|-----------|---------|
| OS | ubuntu-latest |
| Python | 3.11 |
| Flet | 0.28.3 |
| Flutter | 3.24.0 (pinned via `subosito/flutter-action@v2`) |
| Java | 17 (Temurin) |

### Why Flutter 3.24.0?

Flutter 3.29.2 ships Dart 3.10+ which enforces `--enable-experiment=native-assets` for Dart packages using native assets (like `objective_c`). Flet's `dart run serious_python:main` packaging step does not pass this flag, causing a build failure. Flutter 3.24.0 (Dart 3.5.x) predates this requirement and builds successfully.

### Workflow file location

`.github/workflows/build_apk.yml` — do not modify unless you understand the Flutter native-assets constraint.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## HOW TO USE THIS FILE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

At the **START** of every new CLI session: Read `PROJECT_CONTEXT.md` completely before doing anything else.
After **EVERY** significant change: Update the relevant sections, bug history, and feature status.
After **EVERY** session ends: Update Section 7 with exactly what was done and what still needs doing.
