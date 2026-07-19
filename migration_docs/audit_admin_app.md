# AUDIT REPORT — Mahalaxmi Admin App

**Date:** 2026-07-15
**Scope:** `mahalaxmi_admin` (55 files, 13,942 LOC) + `mahalaxmi_shared` (88 files, 9,396 LOC)

---

## Threat Model

This app is **not** a public-facing application. It is a private operational tool for Mahalaxmi Bangles' internal use, installed on trusted devices and shared with only 2–3 business personnel. The threat surface is:

- **No internet-facing exposure** — APK installed on owner/manager devices only
- **Trusted user base** — all users are known business personnel with legitimate access
- **No customer/PII exposure** — customer data is business records (name, mobile, shop), not consumer PII
- **Primary risk: data loss or corruption** — accidental deletion, incorrect edits, or silent failures affecting business records

Findings are rated with this context in mind. Security issues like hardcoded passwords are downgraded because the app is behind physical device access. Data integrity and UX issues are rated higher because they directly affect daily business operations.

---

## Overview

| Metric | Value |
|--------|-------|
| **Total Dart files (admin)** | 55 |
| **Total LOC (admin `lib/`)** | 13,942 |
| **Total Dart files (shared)** | 88 |
| **Total LOC (shared `lib/`)** | 9,396 |
| **Features** | 8 (auth, catalogue, cost_calc, customers, cutmail, dashboard, orders, settings) |
| **Routes** | ~25 (5 shell + 20 push/modal) |
| **Flutter SDK** | `^3.2.0` |
| **Backend** | Supabase (PostgreSQL + Storage) |
| **State management** | Riverpod (`FutureProvider`, `StateNotifierProvider`) |
| **Routing** | GoRouter |

---

## HIGH Priority — Affects Business Operations or Data

### H1. Hard Delete Instead of Soft Delete

Orders are the **only** entity with proper soft-delete (`deleted_at`/`deleted_by`/`delete_reason`). All others are permanently removed on delete with no recovery.

| Entity | Repository | Line | Risk |
|--------|-----------|------|------|
| Items (`rate_list`) | `item_repository.dart` | 318-330 | Accidental item deletion = permanent loss |
| Tags (`tag_master`) | `tag_repository.dart` | 45-57 | Tag removal can't be undone |
| Materials (`materials`) | `material_repository.dart` | 88-100 | Costing history lost |
| Cost calculations (`cost_calculations`) | `cost_calculations_repository.dart` | 66-74 | Costing history lost |

**Fix:** Add soft-delete columns to each table and update repository methods. Only the admin UI's delete confirmation dialog changes.

### H2. 18 Empty `catch (_)` Blocks

Errors silently swallowed with no logging and no user feedback. User sees nothing — form doesn't save, search returns no results, screen stays blank — with no indication something went wrong.

| File | Lines | What fails silently |
|------|-------|---------------------|
| `share_photo_service.dart` | 65, 130 | Network download, image composition |
| `cost_calculator_form_page.dart` | 132, 151, 241, 279, 398, 776 | Item search, category lookup, load existing, save |
| `trading_cost_form_page.dart` | 124 | Item search |
| `admin_item_picker_sheet.dart` | 43, 64, 122 | Category/item/chuda options load |
| `create_order_page.dart` | 128 | Chuda options load |
| `orders_page.dart`, `order_detail_page.dart`, `archive_orders_page.dart`, `dashboard_page.dart` | Various | Date formatting |

**Fix:** At minimum log the error; ideally show a user-facing `SnackBar`.

### H3. 13 Provider `.when()` Calls Missing `error:` Handler

If a `FutureProvider` fails, the page shows **nothing** (blank screen). No retry button, no error message — just an empty body.

| Page | File |
|------|------|
| Manage Categories | `manage_categories_page.dart:34` |
| Manage Tags | `manage_tags_page.dart:44` |
| Chuda Customization | `chuda_customization_page.dart:47` |
| Margin Settings | `margin_settings_page.dart:45` |
| Material Master | `material_master_page.dart:101` |
| Customers | `customers_page.dart:31` |
| Customer Edit | `customer_edit_page.dart:112` |
| Category Items | `category_items_page.dart:289` |
| Catalogue | `catalogue_page.dart:35` |
| Missing Price Items | `missing_price_items_page.dart:75` |
| Orders | `orders_page.dart:68` |
| Archive Orders | `archive_orders_page.dart:57` |
| Order Detail | `order_detail_page.dart:367` |

**Fix:** Add `error: (err, _) => ...` with an error message and retry button to each `.when()` call.

### H4. 54 At-Risk Null Assertion (`!`) Operators

Clusters that crash the app at runtime if data is null. For a 2-3 user app this means "app just closed" with no error report to the developer.

| File | Lines | What crashes |
|------|-------|-------------|
| `create_order_page.dart:550-564` | 6x | `state.selectedCustomer!.shopName`, `.mobile` etc. |
| `create_order_page.dart:286-291` | 3x | `selPatti!.name`, `selColor!.name`, `selBox!.name` |
| `admin_item_picker_sheet.dart:290-295` | 3x | Same chuda pattern |
| `manage_categories_page.dart` | 13+ | `cat.id!`, `pickedCoverBytes!`, `cat.sizeChart!` etc. |
| `item_edit_page.dart:93` | 1x | `item.availableSizes!` |

### H5. 29 Unsafe `as` Casts

| File | Lines | Risk |
|------|-------|------|
| `admin_dashboard_data_provider.dart:84-89` | Indices into `Future.wait` results then casts them |
| `cost_calculator_form_page.dart:270-273` | Assumes `materials` map entry types exist |
| `order_detail_page.dart:815-822` | Casts chuda customization JSON fields |

---

## MEDIUM Priority — Worth Fixing, Lower Urgency

### M1. Hardcoded Admin/Labour Passwords

`mahalaxmi_shared/lib/providers/auth_provider.dart:19-20`
```
const _adminPassword = 'admin123';
const _labourPassword = 'labour123';
```

**Context:** App is private, only 2-3 trusted users. Risk of credential exposure is low but not zero (device theft, disgruntled ex-employee with repo access). No password hashing, no rate limiting, no lockout.

**Fix (when convenient):** Store hashed passwords in `app_settings` table and compare server-side, or add Supabase Auth.

### M2. Labour PIN Hardcoded

`mahalaxmi_labour/lib/providers/labour_auth_provider.dart:5`
```
const _kLabourPin = '1234';
```

Same as M1 but for the labour app.

### M3. Session Stored in Plaintext

`mahalaxmi_shared/lib/services/session_storage.dart` — uses `SharedPreferences` (plain XML on Android, `localStorage` on Web). No encryption.

**Context:** Session data is limited to role, customerId, shop name, mobile — all business records, not personal secrets. On a non-rooted, non-shared device the risk is negligible.

**Fix (when convenient):** Replace with `flutter_secure_storage`.

### M4. No Supabase Auth / RLS Unused

No GoTrue/JWT session — all queries run under anon key. The comprehensive RLS migration (`007_admin_web_rls_hardening.sql`) is unapplied.

**Context:** Private app with trusted users, no public exposure. RLS provides defense-in-depth but is low priority.

**Fix:** Apply after Supabase Auth migration (M1).

### M5. No Role-Based Route Authorization

`router.dart:44-56` checks only `isLoggedIn`, not `AuthRole`. A `labour` user can access all admin routes.

**Context:** Labour would need to install the admin APK (not the labour APK) to exploit this. Low practical risk.

**Fix:** Add role check in router redirect.

### M6. Hard Delete Methods Available but Unused in UI

- `category_repository.dart:160-172` (`deleteCategory`) — not called from any UI page
- `cutmail_repository.dart:198-210` (`deleteCutmail`) — not called from any UI page

Could be misused if a future developer adds a delete button without considering recovery.

### M7. `updateCustomerField()` Allows Any Column Update

`customer_repository.dart:62-74`: `field` parameter passed directly as update key. Could update `pin` or `is_active`.

### M8. `ImagePicker()` Calls Not Wrapped in Try-Catch

- `manage_categories_page.dart:271,466`
- `item_edit_page.dart:424`
- `add_item_page.dart:331`

Will crash the form on permission denial or corrupt files. User loses unsaved form data.

### M9. `storage_service.dart` Has No Try-Catch

Both `uploadCategoryCover` and `uploadProductImage` — network errors propagate unhandled. Callers do wrap in try-catch but the service itself is unprotected.

### M10. 11 Files > 500 Lines (Refactor Candidates)

| File | Lines | Primary Concern |
|------|-------|-----------------|
| `cost_calculator_form_page.dart` | **1,097** | Massive form with inline logic |
| `item_edit_page.dart` | 880 | Image handling, costing, size management |
| `order_detail_page.dart` | 810 | Status management, PDF, customization |
| `create_order_page.dart` | 758 | Chuda customization, customer/item pickers |
| `category_items_page.dart` | 656 | Filtering, selection, cost calculations |
| `add_item_page.dart` | 610 | Item add form |
| `manage_categories_page.dart` | 608 | Image upload, sorting, size charts |
| `dashboard_page.dart` | 565 | Stats, alerts, recent orders |
| `admin_item_picker_sheet.dart` | 542 | Item picker with Chuda |
| `chuda_customization_page.dart` | 541 | Options management |
| `trading_cost_form_page.dart` | 530 | Trading cost form |

### M11. Duplicate Code — Chuda Customization

`create_order_page.dart:130-295` and `admin_item_picker_sheet.dart:123-299` are **nearly identical**: same variables (`selPatti`, `selColor`, `selBox`, `customColorText`, `customTotal()`), same chips, same validation logic (~170 duplicated lines).

**Fix:** Extract to a shared widget in `mahalaxmi_shared/lib/widgets/`.

### M12. Duplicate `_statusColor` in 5 Files

Identical switch/case for order status colors duplicated in:
- `orders_page.dart:135-141`
- `order_detail_page.dart:182-188`
- `archive_orders_page.dart:124-130`
- `dashboard_page.dart:441-451` (orders) + `533-539` (cutmails)
- `cutmail_list_page.dart:217-223`

**Fix:** Extract to an extension method or utility function.

### M13. Schema Documentation Stale

6 tables missing from `migration_docs/context/05_database_schema.md`:

| Table | Model Exists? | Repository Exists? |
|-------|--------------|-------------------|
| `materials` | ✅ `material.dart` | ✅ `material_repository.dart` |
| `cost_breakdown` | ✅ `cost_breakdown.dart` | ✅ (via material_repo) |
| `item_materials` | ✅ `item_material.dart` | ✅ (via material_repo) |
| `app_settings` | ✅ `app_setting.dart` | ✅ `settings_repository.dart` |
| `cost_calculations` | ✅ `cost_calculation.dart` | ✅ `cost_calculations_repository.dart` |
| `material_settings` | ❌ No model | ❌ No repository |

4 migration files post-date the schema doc:
- `categories.has_sizes`, `categories.has_subcategories`
- `order_items.production_status` JSONB
- `tag_master.categories` JSONB
- `cost_calculations.costing_type`

**Fix:** Update `05_database_schema.md` to reflect current schema.

### M14. Production Credentials in Test File

`mahalaxmi_shared/test/scratch_db_test.dart:6-10` — hits production Supabase with anon key. Rename to `.dart.skip` or add to gitignore.

### M15. `dart analyze` — 7 Warnings + 17 Infos

| File | Line | Issue |
|------|------|-------|
| `add_item_page.dart` | 6 | Unused import: `size_charts.dart` |
| `item_edit_page.dart` | 6 | Unused import: `size_charts.dart` |
| `trading_cost_form_page.dart` | 9 | Unused import: `cost_calculations_repository.dart` |
| `cost_calculator_form_page.dart` | 33 | Unused class: `_MaterialTotal` |
| `cost_calculator_form_page.dart` | 84 | Unused field: `_selectedItemImageUrl` |
| `trading_cost_form_page.dart` | 152 | Unnecessary null comparison |
| `trading_cost_form_page.dart` | 168 | Unnecessary non-null assertion |
| `main.dart` | 34 | Deprecated `anonKey` — use `publishableKey` |
| 4 files | Various | `BuildContext` across async gap without `mounted` guard |

### M16. String Interpolation in `.or()` Filter

`cutmail_repository.dart:68-70` — `$search` interpolated into filter string. Currently safe (Supabase parameterizes) but a code smell.

### M17. `getCustomers()` Returns Inactive Customers

`customer_repository.dart:13-15` — no `eq('is_active', true)` filter. Admin can see disabled customers in lists (moderate, intended behavior).

---

## LOW Priority — Cosmetic or Nice-to-Have

### L1. 95+ Hardcoded Color Values

- `0xFF1565C0` (blue) — **48 occurrences** across 18 files
- `0xFF2E7D32` (green) — 30 occurrences
- `0xFF800000` / `0xFF800020` (maroon brand) — 11 occurrences
- Additional colors (red, yellow, purple, orange, pink) — scattered

**Fix:** Extract to `AppColors` constant class.

### L2. 40+ Hardcoded Status String Literals

`'pending'`, `'confirmed'`, `'completed'`, `'cancelled'` duplicated across orders, cutmail, and dashboard pages.

**Fix:** Extract to a shared enum (`OrderStatus`, `CutmailStatus`).

### L3. Double Precision for Currency

Prices stored as `double` — could lose precision for very large totals (lakhs/crores). Mitigated by `toStringAsFixed(2)` pattern.

### L4. 85 `@JsonKey` Annotation Warnings on Freezed Constructors

All model files — `@JsonKey` on constructor parameters instead of fields. Functionally harmless, codegen works correctly.

### L5. `StateNotifier.state` Accessed Externally

`customer_auth_provider.dart:69` — `_sessionNotifier.state` bypasses encapsulation.

### L6. Widespread `.select('*')` Over-Fetching

Many repository methods use bare `.select()` instead of column-restricted selects. Acceptable for small tables but over-fetches for `rate_list`/`orders`.

### L7. `.env` Files Committed to Git

All three `.env` files contain `SUPABASE_URL` and `SUPABASE_ANON_KEY`. Anon key is public by design, but committing env files is an anti-pattern.

---

## What's Done Well

| Pattern | Details |
|---------|---------|
| **Repository pattern** | No direct Supabase calls in UI — all through `mahalaxmi_shared/lib/repositories/` |
| **Error SnackBars** | ~30 properly catch errors and show `SnackBar` with `catch (e)` |
| **Loading states** | Most save/delete operations have `_saving` / `_loading` flags with indicators |
| **Soft-delete on orders** | `deleted_at`, `deleted_by`, `delete_reason` respected in all order queries |
| **Sizes as strings** | `List<String>?` consistently — never parsed as numbers (guardrail respected) |
| **No print/debugPrint** | Zero debug output in production code |
| **No TODO/FIXME** | Zero tracked technical debt |
| **No timer hacks** | Zero `Future.delayed` or `sleep()` calls |
| **Cost calc repositories** | Properly wrap Supabase calls in try-catch with typed `RepositoryException` |
| **Dashboard** | Full loading/error/data states in `dashboard_page.dart` |
| **App structure** | Clean feature-based folder organization |
| **Models** | All DB tables mapped to Freezed models with generated JSON serialization |
| **Dependency injection** | Repository providers via Riverpod — testable architecture |
| **Image policy** | Consistent 4:5 (product) and 3:4 (category) aspect ratios with `crop_your_image` |
| **Price rounding** | Selling price calculation uses proper rounding (`roundToNearest5` in trading form) |

---

## Top 5 Recommended Fixes

1. **Convert hard deletes to soft deletes** — items, tags, materials, cost calculations. Protects against accidental data loss. Highest business impact.
2. **Fix all 18 empty `catch (_)` blocks** — silent failures are confusing for non-technical users. At minimum log the error.
3. **Add `error:` handlers to all 13 provider `.when()` calls** — blank screens on network failure are confusing. Show a retry button.
4. **Handle `ImagePicker` exceptions** — prevent form crash and data loss on permission denial.
5. **Extract shared Chuda customization widget** — reduce duplication and prevent bugs from divergent code.

---

## Stats Summary

| Severity | Count |
|----------|-------|
| 🟠 High (affects business ops) | 5 |
| 🟡 Medium (worth fixing) | 12 |
| 🟢 Low (cosmetic/nice-to-have) | 7 |
| ✅ Good practices | 12 |
| **Total findings** | **24** |
