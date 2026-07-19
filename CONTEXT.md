# CONTEXT

> This is the essential project context. For detailed implementation/bug history, see `migration_docs/context/*.md`.
>
> **File purpose:**
> - `CONTEXT.md` = current essentials only.
> - `migration_docs/context/*.md` = detailed feature and bug history.
> - `migration_docs/*.md` = audits, SQL migrations, one-time reports.

## Project Identity

- **Business:** Mahalaxmi Bangles — wholesale bridal chuda/bangles manufacturer
- **Location:** Sri Ganganagar, Rajasthan
- **GST:** 08AHPPC2086C1ZI
- **Tech Stack:** Flutter (3 apps), Supabase (PostgreSQL + Storage + Auth), Riverpod, GoRouter
- **Web App:** `https://app.mahalaxmibangles.com`

## App Structure

| App | Purpose | Folder |
|-----|---------|--------|
| `mahalaxmi_customer` | Customer-facing catalogue, cart, orders | `mahalaxmi_customer/` |
| `mahalaxmi_admin` | Admin dashboard, orders, catalogue, customers, settings | `mahalaxmi_admin/` |
| `mahalaxmi_labour` | Cutmail/stock-check creation (beta) | `mahalaxmi_labour/` |
| `mahalaxmi_shared` | Shared models, repositories, providers, services | `mahalaxmi_shared/` |

## Feature Status

- **Customer app:** Production-ready. PIN login, catalogue, cart (persisted), orders, Chuda customisation, PDF share, web-compatible.
- **Admin app:** Production-ready (Android + Web). Dashboard, orders (create/archive/soft-delete), catalogue management (add/edit/delete/tags/images), cost calc (trading + manufacturing), customers, settings, cutmail review, WhatsApp photo share.
- **Audit report:** `migration_docs/audit_admin_app.md` — 24 findings (5 high, 12 medium, 7 low) with adjusted severity for private deployment (2-3 trusted users). Full admin app audit completed 2026-07-15.
- **Labour app:** Beta. Cutmail/stock-check creation only. No session auth guard yet.
- **Web apps:** Customer live at `https://app.mahalaxmibangles.com`. Admin web at `https://admin.mahalaxmibangles.com` (behind Cloudflare Access — owner email only). Supabase Auth/RLS hardening pending.
- **Play Store:** Not yet published.
- **iOS (Admin):** GitHub Actions CI produces unsigned IPA (`flutter build ios --release --no-codesign`). Native MethodChannel implemented (merged into `AppDelegate.swift`). Requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` secrets set in repo. See `iOS_Migration_Plan.md` and `migration_docs/context/09_ios_migration.md`.

## Critical Guardrails

1. **No direct Supabase calls in UI** — use repository pattern in `mahalaxmi_shared`
2. **Keep sizes as text/string, never numeric** — `2.10` must not become `2.1`
3. **Preserve raw category names internally** — display-friendly names only in UI
4. **Do not break Chuda customisation/order pipeline** — affects pricing, display, PDF
5. **No hard-delete from UI** — use soft-delete (`deleted_at`) for business records
6. **Do not expose admin/labour data to customer app**
7. **Update context files after major changes**

## Essential Database Notes

| Table | Key Fields | Notes |
|-------|-----------|-------|
| `categories` | `size_chart jsonb`, `sort_order int`, `is_active bool` | |
| `rate_list` | `available_sizes jsonb`, `selling_price numeric`, `cost_price numeric`, `tags jsonb` | |
| `order_items` | `qty_2_12 int`, `customization jsonb` | Customization stores Chuda patti/color/box snapshot |
| `orders` | `deleted_at timestamptz`, `deleted_by text`, `delete_reason text` | Soft-delete columns |
| `customers` | `is_active bool`, `pin text`, `last_active_at timestamptz` | |
| `cutmails` | Status, category/item snapshot, notes | General stock check |
| `cutmail_sizes` | FK to cutmails, size text, qty int | Per-size quantities |
| `chuda_customization_options` | Group/name/price/default | Patti, Color, Box options |
| `tag_master` | Name, is_active | Catalogue tags |

## Detailed References

- Project overview & architecture → `migration_docs/context/01_project_overview.md`
- Customer app features (login, catalogue, cart, orders, Chuda, web) → `migration_docs/context/02_customer_app.md`
- Admin app features (dashboard, orders, catalogue, customers, settings, cutmail) → `migration_docs/context/03_admin_app.md`
- Labour app (cutmail creation, dashboard) → `migration_docs/context/04_labour_app.md`
- Database schema, migrations, RLS → `migration_docs/context/05_database_schema.md`
- Full admin app audit (2026-07-15) → `migration_docs/audit_admin_app.md`
- Feature history → `migration_docs/context/06_feature_history.md`
- Bugfix history → `migration_docs/context/07_bugfix_history.md`
- Play Store/Web/APK build → `migration_docs/context/08_release_playstore_web.md`

## Build

```bash
# Standard APK (customer app)
cd mahalaxmi_customer && flutter build apk --release --split-per-abi

# Faster rebuild (skip Flutter validation when deps unchanged)
cd mahalaxmi_customer/android && .\gradlew assembleRelease

# Web
cd mahalaxmi_customer && flutter build web --release

# Admin web (Cloudflare Pages)
cd mahalaxmi_admin && flutter build web --release --dart-define-from-file=.env
# Output: mahalaxmi_admin/build/web/

# iOS (unsigned IPA — requires macOS CI)
cd mahalaxmi_admin && flutter build ios --release --no-codesign --dart-define-from-file=.env
# Output: mahalaxmi_admin/build/ios/iphoneos/Runner.app
# To package as .ipa: cd build/ios/iphoneos && mkdir -p Payload && cp -r Runner.app Payload/ && zip -r admin_unsigned.ipa Payload/
```

## Session — 2026-07-15

### Done
1. **Orphan image cleanup script** — `scripts/cleanup_orphan_images.ps1` lists/deletes unused images from `product-images` bucket. Identified 21 orphan files (~11 MB). Run with `-ServiceRoleKey` from Supabase dashboard.
2. **UI: Auto-select sizes on category pick** — `add_item_page.dart`: when a category is selected, "Has Sizes" auto-enables and all category sizes pre-checked (admin unchecks unavailable ones). Handles both dropdown selection and `initialCategory` route param.
3. **Full admin app audit** — `migration_docs/audit_admin_app.md` with adjusted severity for private deployment (2-3 trusted users). 24 findings: 5 high (hard deletes, empty catches, blank screens, null crashes), 12 medium, 7 low.
4. **Admin APK built & installed** — `flutter build apk --debug --dart-define-from-file=.env`, installed via `adb install -r`.
5. **SQL migrations applied in Supabase Editor** — `costing_type` column added to `cost_calculations`, 4 balance records' empty categories fixed to 'Kolkata AD Bangles', test orders (Aman, New MB, Saloni + prior) soft-deleted.
6. **Orphan images cleaned up** — ran `scripts/cleanup_orphan_images.ps1` with service_role key, deleted 21 unused files (~11 MB) from `product-images` bucket.

### Pending
- (none)

## Session — 2026-07-17

### Done
1. **APK build blocker resolved (file_picker compileSdk mismatch)** — Removed `file_picker: ^8.1.0` dependency. Replaced with native MethodChannel + `ACTION_OPEN_DOCUMENT` in `MainActivity.kt` for Browse Files functionality. Cleaned up gradle hacks (`compileSdk = 36` reverted to `flutter.compileSdkVersion`, `resolutionStrategy` block removed). Build verified.
2. **SQL migration** — Added `created_at TIMESTAMPTZ DEFAULT now()` to `rate_list` table via Supabase SQL editor.
3. **Sort fix** — `getItemsByCategory()` in `item_repository.dart` now orders by `created_at DESC, item_number` so "Recently Added" works correctly. Items with null `created_at` fall to bottom sorted by item number.

### Pending
- (none)

## Session — 2026-07-19

### Done
1. **iOS platform directory scaffolded** — `flutter create --platforms=ios .` generated 40 files (`AppDelegate.swift`, `Info.plist`, Xcode project, storyboards, assets, tests).
2. **Info.plist permission strings added** — `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryAddUsageDescription` required by `image_picker` and `share_plus`.
3. **FilePickerPlugin merged into AppDelegate.swift** — Avoids Xcode build phase registration issue; uses `registrar(forPlugin:)` to convert `FlutterPluginRegistry` → `FlutterPluginRegistrar`.
4. **App icons enabled for iOS** — `pubspec.yaml`: `ios: true`, ran `flutter_launcher_icons` to generate icon set.
5. **GitHub Actions CI iterated** — `.github/workflows/ios_build.yml`:
   - Writes `.env` from `${{ secrets.SUPABASE_URL }}` / `${{ secrets.SUPABASE_ANON_KEY }}`
   - Runs `flutter pub get`, `pod install`, generates icons, builds unsigned IPA, packages as `.ipa`, uploads as artifact
6. **Root gitignore fix** — `flutter/` → `/flutter/` to stop matching `ios/Flutter/` case-insensitively. `AppFrameworkInfo.plist`, `Debug.xcconfig`, `Release.xcconfig` force-added to git.
7. **Unsigned IPA built successfully** — Confirmed via GitHub Actions CI.

### Pending
- Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` as repo secrets for CI to work at runtime
- Phase 2 platform polish (adaptive transitions, dialogs, bottom nav) — see `iOS_Migration_Plan.md`

## Session — 2026-07-19 (2)

### Done
1. **Legacy Flet app deleted** — `legacy_flet_app/` directory (30 entries) removed from repo.
2. **`.gitignore` cleaned** — Removed 18 stale `legacy_flet_app/` exclusion lines.
3. **`migration_docs/CONTEXT.md` deleted** — 904-line outdated migration plan (Flutter migration complete).
4. **`FLUTTER_WORKSPACE_README.md` updated** — Removed legacy directory tree, purpose table row, and 2 frozen-Flet rules.
5. **`EXPECTED_FLUTTER_FEATURES_FROM_FLET.md` header updated** — Source note changed to "archived — legacy app deleted".
6. **`migration_docs/context/01_project_overview.md` updated** — One stale directory-tree reference marked as deleted.
7. **`migration_docs/security_audit_2026-07-19.md` updated** — Two legacy file references removed.

### Pending
- No legacy cleanup remains. Only 1 `legacy_flet_app` mention left in repo — a historical note in `migration_docs/context/01_project_overview.md`.
- Security fixes from audit (separate session).
