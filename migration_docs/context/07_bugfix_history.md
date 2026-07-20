# 07 — Bugfix History

## CONTEXT.md Refactor — 2026-07-05

The original large `CONTEXT.md` was refactored into a concise essential context file plus detailed topic-specific files under `migration_docs/context/`.

New rule:
- `CONTEXT.md` should contain only current essential project information, guardrails, key database notes, and links to detailed context files.
- Detailed implementation history, bug fixes, audits, release notes, and old decisions should live in the relevant `migration_docs/context/*.md` file.
- Future changes should update the relevant detailed context file, and only add a short line to `CONTEXT.md` if the change affects current project status, architecture, guardrails, or critical database fields.

## Tag Master Edit/Delete — JSONB Filter Syntax

### Symptom
`RepositoryException[rate_list]: invalid input syntax for type json` when renaming/deleting a tag.

### Root Cause
`postgrest` v2.7.1's `.contains(column, value)` treats `List` as PostgreSQL array literal (`{val1,val2}`), producing `{"Gold"}` which is invalid JSON.

### Fix
Replaced `.contains('tags', [tag])` with `.filter('tags', 'cs', jsonEncode([tag]))` in `item_repository.dart:202,261`.

## Customer Last-Access Tracking Not Persisting

### Symptom
`updateLastCatalogueAccess` PATCH did not persist to Supabase — admin always showed null `last_active_at`.

### Root Cause (3 issues)
1. `postgrest-dart` v2.7.1's `.update()` sets `Prefer: ''` (empty header). Flet app sent `Prefer: return=representation`. Empty header caused PostgREST to silently reject the PATCH.
2. `DashboardPage._recordAccess()` used `catch (_) {}` — swallowed all errors.
3. `SessionNotifier.restore()` was never called; `InMemorySessionStorage` provided no persistence.

### Fix
1. Chained `.select()` after `.eq()` in `customer_repository.dart` — transforms Prefer header to `,return=representation`.
2. Removed silent catch in `dashboard_page.dart`.
3. Added `SharedPreferencesSessionStorage`, switched default in `session_provider.dart`.
4. Called `sessionProvider.notifier.restore()` in `main.dart`.

## Admin Catalogue Form Not Updating After Save (P0)

### Symptom
After saving an item edit, the form still showed old values. Provider refresh did not update form controllers.

### Fix
Removed `_dataLoaded` guard pattern in `item_edit_page.dart`. Controllers explicitly updated with saved values after `_save()` completes.

## Order Items Quantity Integer Type Mismatch

### Symptom
Native app crash: `invalid input syntax for type integer: "1.0"`. Dart `double` serializes to `1.0`, PostgreSQL `integer` column rejects it.

### Fix
Cast `quantity` to `.toInt()` in `customer_order_service.dart` and `create_order_page.dart` row mapping.

## Router Root Redirect — GoException

### Symptom
`GoException: No routes for location: /` on cold start with restored session.

### Fix
Updated `router.dart` redirect to map `/` to `/dashboard` when logged in, `/login` otherwise.

## Chuda Customisation — Cart Price Bug (Phase 2)

### Symptom
Cart always used base selling price — customization total (`_customisationTotal`) not added to `CartItem.unitPrice`.

### Fix
Changed `unitPrice = item.sellingPrice` to `unitPrice = basePrice + _customisationTotal` in `_addToCart()`.

## Chuda Customisation — First-Open Default Selection (Phase 6)

### Symptom
First Chuda item open after fresh install: "Please select a patti type". Second open worked fine.

### Root Cause
`chudaCustomizationOptionsProvider` is a `FutureProvider` — not resolved at page build time. `ref.read()` returned `[]`. `_chudaDefaultsLoaded = true` was set prematurely, preventing re-run.

### Fix
Added `_ensureChudaDefaultsReady()` async method that awaits `FutureProvider.future` before applying defaults. `_addToCart()` now awaits it before validation.

## Customer Tag Filter — Stale State on Category Switch

### Symptom
`_selectedTag` persisted across categories — wrong filter applied to new category.

### Fix
Added `didUpdateWidget` lifecycle override in `category_page.dart` — resets `_selectedTag = null` when `widget.categoryName` changes.

## Pull-to-Refresh Broken on Empty Filter

### Symptom
Pull-to-refresh did not work when filter returned no items — `Center` widget is non-scrollable.

### Fix
Wrapped empty state in `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())`.

## SystemNavigator — Flutter Web Crash

### Symptom
`MissingPluginException` when exiting on Flutter Web.

### Fix
Added `kIsWeb` guard: shows SnackBar "You can close this browser tab." on web, calls `SystemNavigator.pop()` on mobile.

## Contact Links Not Opening (Instagram/WhatsApp)

### Symptom
Instagram and WhatsApp buttons did nothing on tap. Only Maps worked.

### Root Cause
`canLaunchUrl()` returns false on some Android versions due to package visibility restrictions.

### Fix
Removed `canLaunchUrl` check. Call `launchUrl()` directly inside try-catch. Show SnackBar on failure.

## Numeric Keypad — Black Blocks on Digits

### Symptom
Keypad digit buttons used plain black blocks, inconsistent with cream/gold login theme.

### Fix
Styled `_KeypadButton`: cream background, soft gold border, dark text. Clear/⌫: white background, maroon border/text.

## Ledger Stale Cache — Vendor Not Showing After Catalogue Edit

### Symptom
Editing a catalogue item to assign a vendor did not appear in the Ledger Vendor tab.

### Root Cause
`add_item_page.dart` and `item_edit_page.dart` only invalidated catalogue-related providers after save/delete. The `allRateItemsProvider` (used by ledger) was never invalidated. Since `StatefulShellRoute.indexedStack` keeps all tab branches alive, the Cost Calc tab held stale cached data.

### Fix
Added `ref.invalidate(allRateItemsProvider)` after save/delete in both `add_item_page.dart` and `item_edit_page.dart`. The ledger providers depend on `allRateItemsProvider` so they refresh automatically on next read.
