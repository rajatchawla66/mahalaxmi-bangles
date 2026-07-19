# PROJECT CONTEXT — Mahalaxmi Flutter Migration

> **Purpose:** Single source of truth for project state, architecture decisions, and migration progress.
> **Last updated:** 2026-06-14 (Tag Master remove tag fix — JSONB serialization, tag_master deletion; 10 new tests; 173 total)
> **How to use after context compaction:** Read this file first, then `NEXT_STEPS` section, then continue current phase.

---

## 1. Project Overview

- **Business:** Wholesale bridal jewellery order management (B2B catalogue, ordering, costing, production tracking)
- **Legacy:** Python/Flet app (`legacy_flet_app/`) — fully functional in production, now **frozen**
- **Migration target:** Flutter (Dart) — two separate apps + shared package
- **Database:** Supabase (same project, same schema — no schema changes without explicit review)
- **Phase:** Phase 1 (Shared Foundation) — models + business logic + repositories + basic read providers done; UI pending

---

## 2. Current Architecture

```
mahalaxmi_shared/        ← Shared Dart package (no Flutter deps in core layer)
├── lib/models/           ← Freezed data classes (10 models, generated)
├── lib/services/         ← Pure business logic (validation, calculation)
├── lib/constants/        ← Category schemas, enums
├── lib/repositories/     ← ✅ Supabase data access (7 repos, read-only)
├── lib/providers/        ← ✅ Riverpod providers (data reads only)
├── lib/utils/            ← TODO
├── lib/widgets/          ← TODO
├── lib/theme/            ← TODO

mahalaxmi_customer/       ← Customer Flutter app (APK + Web/PWA)
├── lib/main.dart         ← Supabase init, ProviderScope
├── lib/app/app.dart      ← MaterialApp.router
├── lib/app/router.dart   ← GoRouter (placeholder routes)
├── lib/app/theme.dart    ← Deep purple theme
└── lib/features/         ← TODO

mahalaxmi_admin/          ← Admin Flutter app (APK only)
├── lib/main.dart         ← Supabase init, ProviderScope
├── lib/app/app.dart      ← MaterialApp.router
├── lib/app/router.dart   ← GoRouter (placeholder routes)
├── lib/app/theme.dart    ← Blue theme
└── lib/features/         ← TODO

legacy_flet_app/          ← FROZEN reference implementation (do NOT modify)
├── main.py               ← Entry point + UI
├── db.py                 ← Supabase REST layer (~1044 lines)
├── auth.py               ← Hardcoded admin/labour credentials
├── session_helper.py     ← JSON session persistence
├── slip_pdf_generator.py ← PDF generation (fpdf2)
├── cache.py              ← JSON-file offline cache
├── utils.py              ← Image pipeline, validation, connectivity banner
└── views/                ← Flet UI screens
```

---

## 3. Finalized Strategic Decisions

| Decision | Rationale | Effective |
|----------|-----------|-----------|
| **Flet development frozen** | All effort goes to Flutter migration | 2026-06-13 |
| **Two separate Flutter apps** | Different deps, independent release cycles, lower coupling | Phase 0 |
| **Customer APK is primary** | Main distribution channel for B2B customers | Phase 2 |
| **Customer Web/PWA is fallback** | iPhone/browser alternative when APK not viable | Phase 9 |
| **Admin APK only** | No web/admin; admin is Android-only operational tool | Phase 6 |
| **Shared package first** | Models, repos, services in `mahalaxmi_shared` before any UI | Phase 1 |
| **No Supabase calls from widgets** | Widgets → Providers → Repositories → Supabase SDK | Phase 1 |
| **Business logic in shared package** | Validation, calculation, formatting — never in UI layer | Phase 1 |
| **Existing Supabase schema immutable** | Same project, same schema; additive changes only | Always |
| **Riverpod for state management** | FutureProvider.family for per-category cache, StateNotifier for cart | Always |
| **GoRouter with ShellRoute** | Flet interceptor pattern → declarative routing | Phase 2 |
| **No new features during migration** | Parity only; push notifications, camera, FCM delayed to Phase 10 | Always |

---

## 4. Workspace Structure

```
C:\Users\rajat\Labour-receipt\
├── legacy_flet_app/              ← FROZEN — Python/Flet reference
├── mahalaxmi_shared/             ← Dart package (shared)
├── mahalaxmi_customer/           ← Flutter app (customer)
├── mahalaxmi_admin/              ← Flutter app (admin)
├── migration_docs/               ← Migration documentation
│   └── CONTEXT.md                ← THIS FILE
├── FLUTTER_MIGRATION_PHASES.md   ← Detailed phase roadmap
├── FLUTTER_WORKSPACE_README.md   ← Workspace setup instructions
├── EXPECTED_FLUTTER_FEATURES_FROM_FLET.md  ← Feature parity checklist (42 items)
├── build/                        ← Build artifacts
├── cache/                        ← Legacy cache
├── storage/                      ← Legacy storage
├── chuda_business.db             ← Legacy SQLite (offline fallback)
└── venv/                         ← Python venv (legacy)
```

---

## 5. Current Migration Status

| Phase | Scope | Status |
|-------|-------|--------|
| **0** | Workspace reorganization | ✅ **COMPLETE** |
| **1 — Shared Foundation** | **All sub-phases complete** | ✅ **PHASE 1 COMPLETE** |
| **1.1** | Models (freezed) | ✅ **COMPLETE** |
| **1.2** | json_serializable / freezed annotations | ✅ **COMPLETE** |
| **1.3** | Supabase client config | ✅ **COMPLETE** (scaffolded, env vars) |
| **1.4** | Repositories (read-only + write) | ✅ **COMPLETE** |
| **1.5** | Constants & enums | ✅ **COMPLETE** |
| **1.6** | Pure business logic (validation, calculation) | ✅ **COMPLETE** |
| **1.7** | Session & Auth providers | ✅ **COMPLETE** |
| **1.8** | Cart state architecture | ✅ **COMPLETE** |
| **1.9** | Customer order builder & placement | ✅ **COMPLETE** |
| **1.10** | Riverpod providers (basic read) | ✅ **COMPLETE** |
| **1.11** | Tests | ✅ **COMPLETE** (128 tests) |
| **Deferred from Phase 1** | Storage upload helpers, Image service, Result<T>, Connectivity tracking | ➡️ **DEFERRED** |
| **2.1** | Customer app shell, routing, landing page & PIN login | ✅ **COMPLETE** |
| **2.2** | Customer dashboard category grid | ✅ **COMPLETE** |
| **2.3** | Customer category items grid | ✅ **COMPLETE** |
| **2.4** | Item detail & add-to-cart | ✅ **COMPLETE** |
| **2.5** | Customer cart screen | ✅ **COMPLETE** |
| **2.6** | Customer place order UI | ✅ **COMPLETE** |
| **2.7** | Customer my orders | ✅ **COMPLETE** |
| **2.8** | Add Again feature | ✅ **COMPLETE** |
| **Test Build** | Customer debug APK | ✅ **BUILT** |
| **2.8+** | Customer search, add again polish | ⬜ **NOT STARTED** |
| **3.1** | Admin app shell (auth, shell, tabs, env) | ✅ **COMPLETE** |
| **3.2** | Admin orders management (list, detail, status) | ✅ **COMPLETE** |
| **3.3** | Admin catalogue management (categories, items, edit) | ✅ **COMPLETE** |
| **3.4** | Admin customers management (list, edit, PIN, enable/disable) | ✅ **COMPLETE** |
| **6+** | Admin app | ⬜ **IN PROGRESS** |

---

## 6. Completed Migration Work

### 6.1 Workspace (Phase 0)
- [x] `legacy_flet_app/` archived as frozen reference
- [x] `mahalaxmi_shared/`, `mahalaxmi_customer/`, `mahalaxmi_admin/` initialized
- [x] Full backup at `legacy_flet_app/mahalaxmi_flet_backup_2026_06_13.zip`
- [x] `.gitignore` updated for Flutter workspace
- [x] Old workspace-root Python files deleted (preserved in `legacy_flet_app/`)

### 6.2 Models (Phase 1.1)
- [x] 9 freezed model classes + generated code:
  - `Customer` (customers table)
  - `Category` (categories table, with `subCategoryList` getter)
  - `RateItem` (rate_list table, main catalogue item)
  - `TagMaster` (tag_master table)
  - `Material` (materials table)
  - `Order` + `OrderItem` (orders + order_items, with `totalSizeQty` getter)
  - `OrderCreateRequest` (order creation payload)
  - `CostBreakdown` (cost_breakdown table)
  - `ItemMaterial` (item_materials table)
  - `AppSetting` (app_settings table)
- [x] Supporting types: `OrderSummary`, `CategoryGroup`, `OrderSummaryItem`, `CartItem`
- [x] All models use `@JsonKey` for snake_case ↔ camelCase mapping

### 6.3 Business Logic (Phase 1.7)
- [x] `validateCartItem(item, category)` — 5 hardcoded schema rules + dynamic categories
- [x] `validateOrder(cart, rateLookup)` — full order validation
- [x] `calculateLineTotal(item, category, unitPrice)` — 3 formulas
- [x] `buildOrderSummary(cart, rateLookup)` — category grouping + grand total

### 6.4 Constants & Schemas (Phase 1.8)
- [x] `CategorySchema` class with hardcoded schemas for Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal
- [x] Enum-like constants: `kChudaSizes`, `kColorOptions`, `kBoxOptions`, `kGrindOptions`, `kUnits`

### 6.5 Repositories (Phase 1.4)
- [x] `SupabaseClientProvider` — centralized client access, mock-ready
- [x] `BaseRepository` / `RepositoryException` — typed error handling
- [x] `CategoryRepository` — `getCategories()`, `getCategoryNames()`, `getValidSubCategories()`
- [x] `ItemRepository` — `getAllItems()`, `getItemByNumber()`, `getAvailableItems()`, `getCustomerCatalogue()`, `getCustomerItemsByCategory()`, `searchCustomerItems()`, `getRateLookup()`, `getImageLookup()`, `getPricedItems()`, `getUnpricedItems()`, `getCostingStatus()`, `getItemsByTag()`
- [x] `CustomerRepository` — `getCustomers()`, `getCustomerByPin()`, `getCustomerById()`
- [x] `OrderRepository` — `getOrdersWithItems()`, `getOrderById()`, `getOrdersByCustomerId()`, `getArchivedOrders()`, `getOrderItems()`
- [x] `TagRepository` — `getTagMaster()` with categories normalization
- [x] `MaterialRepository` — `getMaterials()`, `getCostBreakdown()`, `getItemMaterials()`
- [x] `SettingsRepository` — `getSetting()`, `getDefaultMargin()`, `getLabourCost()`
- [x] All methods return typed domain models, throw `RepositoryException` on failure
- [x] 0 analyzer errors, 0 warnings in repository layer

### 6.6 Providers (Phase 1.5 — Basic Read)
- [x] `supabase_provider.dart` — `supabaseClientProvider`
- [x] `repository_providers.dart` — 7 repository instance providers
- [x] `categories_provider.dart` — `categoriesProvider`, `activeCategoriesProvider`, `categoryNamesProvider`, `validSubCategoriesProvider`
- [x] `items_provider.dart` — `allItemsProvider`, `customerCatalogueProvider`, `customerItemsByCategoryProvider`, `itemByNumberProvider`, `availableItemsProvider`, `pricedItemsProvider`, `unpricedItemsProvider`, `rateLookupProvider`
- [x] `tags_provider.dart` — `tagMasterProvider`, `activeTagMasterProvider`
- [x] `app_settings_provider.dart` — `defaultMarginProvider`, `labourCostProvider`
- [x] `riverpod: ^2.6.0` added to shared package

### 6.7 Session & Auth Providers (Phase 1.6)
- [x] `AppSession` model with `AuthRole` enum (none, admin, labour, customer)
- [x] JSON serialization round-trip for all roles
- [x] `SessionStorage` abstract class + `InMemorySessionStorage` implementation
- [x] `SessionNotifier` (StateNotifier) with `login()`, `logout()`, `restore()` + persistence
- [x] `session_provider.dart` — `sessionStorageProvider`, `appSessionProvider` (StateNotifier)
- [x] `auth_provider.dart` — `AuthController` with admin (`admin123`) and labour (`labour123`) password login
- [x] `customer_auth_provider.dart` — `CustomerAuthController` with PIN login via `CustomerRepository.getCustomerByPin()`
- [x] Typed auth failures: `AuthFailure` (admin/labour), `CustomerAuthFailure` (customer)
- [x] `currentCustomerProvider` (FutureProvider) — fetches full `Customer` object from session
- [x] All providers use `Provider<Controller>` pattern — UI can call `ref.read(customerAuthControllerProvider).loginWithPin('12345678')`

### 6.8 Cart State Architecture (Phase 1.7)
- [x] `CartLine` model — stable UUID identity (not index-based), `copyWith` support, `CartLine.create()` factory
- [x] `CartState` model — immutable, `lines`, `items`, `itemCount`, `findById()`
- [x] `CartMutationResult` sealed hierarchy — `CartAddSuccess`, `CartUpdateSuccess`, `CartValidationError`, `CartMutationError`
- [x] `CartNotifier` (StateNotifier) with typed mutation results:
  - `addItem(CartItem, category)` — validates, then adds new OR merges with matching variant
  - `removeItem(lineId)` — removes by stable UUID
  - `updateItem(lineId, CartItem)` — validates, then replaces
  - `clear()` — resets to initial state
  - `validateAll()` — runs `validateCartItem` on every line
- [x] Merge conditions: same `itemNumber`, `color`, `grindType`, `boxType`, `notes`, `category`
- [x] Merge behavior: sized → sum size quantities; non-sized → sum `quantity`; uses latest `unitPrice`
- [x] Distinct variants (different color, grind, box, notes, category) → separate cart lines
- [x] `cartProvider` — `StateNotifierProvider<CartNotifier, CartState>`
- [x] `cartItemCountProvider`, `cartLinesProvider` — convenience read providers
- [x] `order_summary_provider.dart` — `orderSummaryProvider` (FutureProvider) watches cart + rateLookup, builds `OrderSummary`
- [x] Full category support: all 5 hardcoded schemas (Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal) + dynamic unknown categories
- [x] No business logic in UI — all mutations through `CartNotifier`, all validation via `validateCartItem()`, all totals via `calculateLineTotal()`/`buildOrderSummary()`

### 6.9 Customer Order Builder & Placement (Phase 1.8)
- [x] `OrderRepository` write methods: `insertOrderHeader()`, `insertOrderItems()`, `deleteOrder()` — all typed, use `SupabaseClientProvider` chain, throw `RepositoryException`
- [x] `CustomerOrderService` — orchestrates full order placement flow:
  - Validates session (must be customer, must have `customerId`)
  - Validates cart (not empty, all lines pass `validateCartItem`)
  - Computes `totalAmount` via `buildOrderSummary()` using rateLookup
  - Builds order header payload: `source=customer`, `customer_id`, `customer_name` (shopName), `customer_mobile`, `order_date` (today), `status=pending`
  - Builds order item rows with `unit_price` from rateLookup (fallback to `CartItem.unitPrice`) and `category` from rateLookup
  - Inserts header → inserts items → returns `CustomerOrderSuccess(orderId)`
  - On item insert failure: deletes header (rollback), returns `OrderSaveFailed`
  - On rollback failure: returns `RollbackFailed` with both original and rollback errors
- [x] `CustomerOrderResult` sealed hierarchy: `CustomerOrderSuccess`, `NotLoggedIn`, `EmptyCart`, `InvalidCartItems`, `OrderSaveFailed`, `RollbackFailed`
- [x] `OrderBuilderController` — Riverpod `Provider` that reads session/cart/rateLookup and delegates to service
- [x] `orderBuilderProvider` — UI calls `ref.read(orderBuilderProvider).placeCustomerOrder()`
- [x] Cart clearing is the UI's responsibility after successful placement (service does not modify cart)

### 6.10 Customer App Shell & PIN Login (Phase 2.1)
- [x] Theme updated: cream background (`#FFF8F0`), maroon primary (`#800020`), gold accent (`#FFA000`), Material 3
- [x] Router rewritten with 3 routes: `/` (landing), `/login` (PIN login), `/dashboard` (placeholder)
- [x] Auth-aware redirect: logged in → skip to `/dashboard`, logged out → `/login` or `/`
- [x] `routerProvider` — Riverpod `Provider<GoRouter>` with `ref.listen` for session-driven `router.refresh()`
- [x] Landing page: Mahalaxmi Bangles branding, watermark, "Customer Login" CTA
- [x] PIN login page: 8-digit obscured input, validation, loading spinner, typed error handling (`InvalidPin`, `BlockedCustomer`, `CustomerNetworkError`), navigation on success
- [x] Placeholder dashboard (Phase 2.1): customer shop name from session, logout button
- [x] Watermark asset copied from `legacy_flet_app/assets/`
- [x] `pubspec.yaml` assets section updated
- [x] 0 analyzer errors in customer app

### 6.11 Customer Dashboard Category Grid (Phase 2.2)
- [x] Dashboard rewritten with real category grid using `activeCategoriesProvider`
- [x] 2-column `GridView` with `childAspectRatio: 0.72`, 16px spacing
- [x] Category cards: network `Image.network(coverImageUrl)` → maroon gradient monogram fallback
- [x] Pull-to-refresh via `RefreshIndicator` calling `ref.refresh(activeCategoriesProvider)`
- [x] Three async states: loading (spinner), error (icon + message + retry), empty ("No categories available")
- [x] Premium AppBar with customer shop name, overflow menu (logout)
- [x] Card tap navigates to `/category/:categoryName` with `Uri.encodeComponent`
- [x] Placeholder category page: back arrow, category name, "Phase 2.3 Pending" message
- [x] New route added: `/category/:categoryName`
- [x] 0 analyzer errors in customer app

### 6.12 Customer Category Items Grid (Phase 2.3)
- [x] Category page rewritten using `customerItemsByCategoryProvider(displayName)`
- [x] 2-column `GridView` with `childAspectRatio: 0.65`, 12px spacing
- [x] Item cards: network image → maroon gradient monogram fallback
- [x] Image loading spinner while loading
- [x] "NEW" status badge (gold) when `item.status == 'new'`
- [x] Item number (small, muted), selling price (green, bold)
- [x] Up to 3 tag chips per card (cream background, dark text)
- [x] Three async states: loading (spinner), error (icon + message + retry), empty ("No items available")
- [x] Pull-to-refresh via `RefreshIndicator` calling `provider.future`
- [x] Tap shows snackbar: "details in Phase 2.4"
- [x] 0 analyzer errors, 120 shared tests passing

### 6.13 Customer Item Detail & Add-to-Cart (Phase 2.4)
- [x] New route `/item/:itemNumber` with `itemByNumberProvider`
- [x] Grid item tap navigates to detail page via `context.go('/item/...')`
- [x] Large product image (360px), tappable for full-screen dialog via `InteractiveViewer`
- [x] Info card: item number, breadcrumb (category > subcategory), selling price, tag chips
- [x] Color dropdown with 5 options (Light Mehroon, Dark Mehroon, Red, Rani, Custom)
- [x] Custom color text field appears when "Custom" selected
- [x] Size steppers (2.2, 2.4, 2.6, 2.8, 2.10) when `hasSizes == true`
- [x] Single quantity stepper (min 1) when `hasSizes == false`
- [x] Live summary card using `calculateLineTotal` from shared service — total sets, estimated total
- [x] Bottom CTA bar: quantity + amount on left, "Add to Cart" button on right
- [x] Add uses `cartProvider.notifier.addItem()` with validation via `validateCartItem`
- [x] Pre-add validation: color required, size qty > 0, quantity >= 1
- [x] Success snackbar (green): "added to cart" or "quantity updated in cart"
- [x] Auto-pop back to category after 600ms on success
- [x] Error snackbar (red) on validation failure
- [x] Loading state on "Add" button while processing
- [x] Error state: "Could not load item" with message
- [x] Item not found: "Item not found" centered message
- [x] 0 analyzer errors (info-level only), 120 shared tests passing

### 6.14 Customer Cart Screen (Phase 2.5)
- [x] New route `/cart` — `CartPage` in `features/cart/pages/cart_page.dart`
- [x] Empty state: cart icon, "Your cart is empty" message, "Browse Catalogue" button → `/dashboard`
- [x] Cart line cards: item number, category, colour, size quantity chips (2.2-2.10), single qty
- [x] Line total computed via `calculateLineTotal` from shared service
- [x] Remove button per line using `cartProvider.notifier.removeItem(lineId)`
- [x] Summary bar: "N items · M sets" + grand total on left, grand total right
- [x] "Place Order" button (placeholder snackbar — Phase 2.6 Pending)
- [x] Cart badge in dashboard AppBar using `cartItemCountProvider` + `Badge` widget
- [x] Cart icon in category page AppBar with badge
- [x] Back navigation from cart to previous page
- [x] Totals computed directly from cart state (no `orderSummaryProvider` dependency)
- [x] 0 analyzer errors, 0 warnings, 120 shared tests passing

### 6.15 Customer Place Order UI (Phase 2.6)
- [x] Cart page Place Order button shows confirmation bottom sheet
- [x] Confirmation sheet: shop name, items count, sets count, grand total, Confirm/Cancel
- [x] Cancel returns to cart unchanged (cart preserved)
- [x] Confirm calls `orderBuilderProvider.placeCustomerOrder()` via shared service
- [x] Loading spinner on button while placing (button disabled)
- [x] Success: cart cleared via `cartProvider.notifier.clear()`, order number shown
- [x] Success dialog: check icon, "Order Placed!", order #, "Continue Shopping" → `/dashboard`
- [x] Error handling mapped to user-friendly messages:
  - `NotLoggedIn` → "Please login again"
  - `EmptyCart` → "Your cart is empty"
  - `InvalidCartItems` → raw validation message
  - `OrderSaveFailed` → "Order could not be saved. Please try again."
  - `RollbackFailed` → "Order failed safely. Please contact admin if issue continues."
- [x] Cart preserved on all failure types (clear only on success)
- [x] 0 analyzer errors, 0 warnings, 120 shared tests passing

### 6.16 Customer My Orders (Phase 2.7) & Add Again (Phase 2.8)
- [x] `customerOrdersProvider` in `features/orders/providers/orders_provider.dart` — reads `customerId` from session, calls `orderRepository.getOrdersByCustomerId()`
- [x] New route `/my-orders` with `MyOrdersPage`
- [x] Dashboard popup menu has "My Orders" entry (between cart and logout)
- [x] Order cards: order #, date, status badge (color-coded), item/sets count, total amount
- [x] Expandable card: tap toggles line items view
- [x] Line items: item number, colour, size chips (2.2-2.10), single qty, per-item total
- [x] Order total row at bottom of expanded section
- [x] Status badges: pending (gold), confirmed (blue), completed (green), cancelled (red)
- [x] Three async states: loading (spinner), error (message + retry), empty ("No orders yet" + "Browse Catalogue" → `/dashboard`)
- [x] Pull-to-refresh via `RefreshIndicator`
- [x] Data filtering: only orders with matching `customer_id` from current session (enforced by repository query)
- [x] No admin actions visible
- [x] **Add Again button** on each order line → bottom sheet with 3 choices:
  - **Repeat Same** — fetches current catalogue item via `ItemRepository.getItemByNumber()`, validates with `validateRepeatableItem()` (not null, `isAvailable`, `sellingPrice > 0`), converts `OrderItem` → `CartItem` via `orderItemToCartItem()` using current `sellingPrice`, adds to cart via `cartProvider.notifier.addItem()`. Shows green snackbar with "View Cart" action on success; red snackbar on validation error or API failure.
  - **Repeat with Change** — fetches item, validates, then pushes to `/item/:itemNumber` for full customization (color, sizes, qty).
  - **Cancel** — dismisses sheet.
- [x] Created `mahalaxmi_shared/lib/services/repeat_order_item.dart` with:
  - `orderItemToCartItem(OrderItem, RateItem)` — maps fields (itemNumber, colour, size qtys, quantity, notes) to `CartItem`, uses current catalogue `sellingPrice`
  - `validateRepeatableItem(RateItem?)` — returns null if valid, error string if null/unavailable/unpriced
- [x] 8 new shared tests (4 validation + 4 conversion)
- [x] 0 analyzer errors, 0 warnings (pre-existing info-level only)

### 6.17 Customer Test Build Checkpoint
- [x] `flutter pub get` — clean resolution
- [x] `flutter analyze` — 0 errors, 0 warnings (info-level only)
- [x] `flutter test` (shared) — 123/123 passing
- [x] `flutter create` — generated Android platform directory
- [x] `flutter build apk --debug` — build succeeded
- [x] APK path: `build/app/outputs/flutter-apk/app-debug.apk`
- [x] APK size: 148.5 MB (debug, multi-arch)
- [x] Build mode: debug
- [x] Build notes: first-time Gradle build required ~7.5 min after cleanup; disk space must have >5 GB free for Gradle cache + intermediate artifacts
- [x] Test checklist created at `migration_docs/CUSTOMER_TEST_BUILD_CHECKLIST.md`

### 6.18 Bug Fix — Item Detail Blank Screen (resolved)
- **Bug:** Tapping any item in the grid showed a blank screen with `BoxConstraints(w=Infinity, h=48.0)` render error
- **Root cause:** `ElevatedButton.icon` inside a `SizedBox(height: 48)` without width constraint, placed directly as a non-flexible child in a `Row`. The `Row` passed unconstrained width, and Material 3's `ElevatedButton` attempted to expand infinitely
- **Fix:** Wrapped the `SizedBox(height: 48, child: ElevatedButton.icon(...))` in a `Flexible` widget so the `Row` properly constrains the button's width
- **Also fixed:** Auto-generated `test/widget_test.dart` referenced non-existent `MyApp` class — updated to reference `MahalaxmiCustomerApp` with proper `ProviderScope` wrapper

### 6.19 Bug Fix — Add to Cart Navigation Crash (resolved)
- **Bug:** After successful add-to-cart, `Navigator.pop()` was called via `Future.delayed`, which could pop the last GoRouter page off the stack, causing `"You have popped the last page off of the stack"` assertion crash
- **Root cause:** `item_detail_page.dart:_addToCart` unconditionally called `navigator.pop()` after 600ms delay regardless of route stack depth, and `context.canPop()` was not checked
- **Fix:** Removed `Navigator.pop()` entirely. After add-to-cart, the snackbar now has a "View Cart" action button that navigates explicitly to `/cart` via `context.go('/cart')`. The user stays on the item detail page and can navigate manually (back to category, or View Cart to cart).

### 6.20 Bug Fix — SnackBar Action Unmounted Context (resolved)
- **Bug:** `SnackBarAction.onPressed` closed over item detail's `BuildContext`; if the page unmounted before the user tapped "View Cart", `context.go('/cart')` threw "This widget has been unmounted" exception
- **Root cause:** SnackBar callbacks are fire-and-forget — the widget may be gone by the time the user interacts
- **Fix:** Captured `GoRouter.of(context)` and `ScaffoldMessenger.of(context)` before showing the snackbar. `onPressed` uses `router.go('/cart')` which is not tied to widget lifecycle. Also added `clearSnackBars()` to prevent stacking and explicit `duration: seconds(2)`.

### 6.21 Bug Fix — Cart Back Button "Nothing to Pop" (resolved)
- **Bug:** Cart page back button used `context.pop()`; when cart was reached via `context.go('/cart')`, the route stack had no previous page, causing "There is nothing to pop" error
- **Root cause:** Two `context.pop()` calls in `cart_page.dart` and `my_orders_page.dart` did not check `context.canPop()` before calling
- **Fix:** Changed both to `context.canPop() ? context.pop() : context.go('/dashboard')`. Verified no other blind `context.pop()` calls remain in the app (remaining pops are dialog/bottom-sheet overlays which are safe).

### 6.22 Bug Fix — Metal Bangles Category Shows 0 Items (resolved)
- **Bug:** "Metal Bangles" category showed 0 items in Flutter customer app, but 3 items in legacy Flet app
- **Root cause:** `category_page.dart` applied `replaceAll('_', ' ')` to the category name before passing it to the provider query. The DB stores `"Metal_Bangles"` (underscore) in both `categories.name` and `rate_list.category`. After replacement, the query was `.eq('category', 'Metal Bangles')` which didn't match any rows.
- **Fix:** Separated query name from display name in `category_page.dart`. The raw decoded `queryName` is used for the provider/repository query (preserving DB format), while `displayName` with `replaceAll('_', ' ')` is used only for UI display. Also fixed `item_detail_page.dart` breadcrumb to use `replaceAll('_', ' ')` for display so users don't see raw underscores.

### 6.23 Bug Fix — Kaleera Color Validation Ignores hasColor Attribute (resolved)
- **Bug:** Item 'shop' (category "Kaleera", `has_color: false`) in Flutter showed "color is required for kaleera item Shop" when adding to cart, even though the item has no color attribute
- **Root cause:** `validation.dart:_applySchemaRule` for rule `qty_gte_1_and_color_required` always required color regardless of the item's `hasColor` field. The legacy Flet customer `add_to_cart` (`customer.py:1012-1016`) guards the color check with `if has_color:` and doesn't call `validate_cart_item`, so it never hits this validation. Flutter calls `validateCartItem` on both add-to-cart and place-order flows.
- **Fix:** Added `if (item.hasColor)` guard in `_applySchemaRule` before requiring color. Items with `hasColor: false` in category "Kaleera" now pass validation without selecting a color. Also fixed hardcoded "Kaleera" in error messages to use the dynamic `$category` parameter. Applied the same fix to "Seasonal" error messages for consistency.

### 6.24 Bug Fix — My Orders Shows 0 Amount/Items (resolved)
- **Bug:** My Orders page displayed order header correctly (order #, date, status) but `totalAmount` showed 0, item count showed 0, and expandable items section was empty
- **Root cause (primary):** `Order.orderItems` field had no `@JsonKey(name: 'order_items')` annotation. Freezed's default serialization mapped `orderItems` → JSON key `'orderItems'` (camelCase), but the Supabase join query `select('*, order_items(*)')` returns nested data under `'order_items'` (snake_case). So `orderItems` was always an empty list.
- **Root cause (secondary):** `OrderItem.lineTotal` getter computed `unitPrice * totalSizeQty` only. For quantity-based items (Kaleera, Seasonal, Raw_Material), `totalSizeQty` is 0 (all size fields are 0) while the actual quantity is in the `quantity` field. So line totals showed 0 for non-sized items.
- **Root cause (UI):** `my_orders_page.dart:255` repeated the same bug — `item.totalSizeQty * item.unitPrice` instead of using `item.lineTotal`.
- **Fix (3 files):**
  1. `order.dart` — Added `@JsonKey(name: 'order_items')` to `orderItems` field
  2. `order.dart` — Updated `lineTotal` getter: if `totalSizeQty > 0` use sized calculation, otherwise fall back to `quantity * unitPrice`
  3. `my_orders_page.dart` — Changed line total display from `item.totalSizeQty * item.unitPrice` to `item.lineTotal`
- **Tests (5 new):** OrderItem lineTotal for sized items, non-sized items, both fields present; Order.fromJson parsing nested `order_items`; Order.fromJson with missing order_items key

### 6.25 Bug Fix — My Orders TypeError: production_status String Not Map (resolved)
- **Bug:** Opening My Orders threw `"type 'String' is not a subtype of type Map<String, dynamic>?"` — orders failed to load entirely with a TypeError
- **Root cause:** Legacy Flet stores `production_status` in `order_items` as a JSON string (e.g. `'{"2.4": "prepared"}'`) while newer Flutter inserts store it as an empty JSON object `{}`. The generated `OrderItem.fromJson` in `order.g.dart` does `json['production_status'] as Map<String, dynamic>?` which throws when the value is a String instead of a Map.
- **Fix (2 files):**
  1. `order.dart` — Added top-level `_productionStatusFromJson()` helper that checks if the value is a `Map`, a `String` (parsed via `jsonDecode`), or null/invalid, and returns `Map<String, String>` accordingly
  2. `order.g.dart` — Replaced the generated cast line with `_productionStatusFromJson(json['production_status'])` to handle both types safely
- **Tests (4 new):** production_status as Map, as String (legacy), as null, as invalid string

### 6.26 Bug Fix — Android APK Login Fails: Missing INTERNET Permission & dart-define (resolved)
- **Bug:** Customer PIN login worked in Chrome but always failed in APK with "Connection error, Please try again" for both correct and incorrect PIN
- **Root cause (primary):** `AndroidManifest.xml` was missing `<uses-permission android:name="android.permission.INTERNET"/>` — Android blocks all HTTP requests without this permission, so every Supabase API call fails immediately
- **Root cause (secondary):** APK build command `flutter build apk --debug` did not include `--dart-define-from-file=.env`, so `SUPABASE_URL` and `SUPABASE_ANON_KEY` were empty strings. `Supabase.initialize()` silently accepts empty config, causing failures on first query.
- **Fix (3 files):**
  1. `AndroidManifest.xml` — Added `<uses-permission android:name="android.permission.INTERNET"/>` before `<application>`
  2. `main.dart` — Added fail-fast validation: if `SUPABASE_URL` or `SUPABASE_ANON_KEY` are empty, renders a diagnostic error screen instead of proceeding with broken Supabase config
  3. `build_apk.ps1` — Created convenience build script with `--dart-define-from-file=.env`
- **Build command:** `flutter build apk --debug --dart-define-from-file=.env`

### 6.27 Bug Fix — Add-to-Cart Snackbar Overlaps Bottom Bar (resolved)
- **Bug:** Green snackbar ("Item added to cart") appeared with `SnackBarBehavior.floating` but overlapped the bottom CTA bar (Add to Cart button), visually blocking it
- **Fix:** Added explicit `margin: EdgeInsets.only(bottom: 88, left: 12, right: 12)` to the success SnackBar to clear the ~72px bottom bar. Also added `clearSnackBars()` to the error snackbar (`_showError`) for consistency.

### 6.28 Bug Fix — Navigation Stack: Android Back Exits App Instead of Stack-by-Stack (resolved)
- **Bug:** All deep navigation used `context.go()` which replaces the GoRouter route stack, destroying back history. Android hardware back from any deep screen (category, item detail, cart) minimized/exited the app.
- **Root cause:** `context.go()` replaces the current route. With no stack entries to pop, GoRouter has nowhere to go back to, so the hardware back button propagates to the OS level, minimizing the app.
- **Fix (6 files):**
  1. All deep navigations changed from `context.go()` to `context.push()`: dashboard→cart, dashboard→my-orders, dashboard→category, category→item detail, category→cart, snackbar→cart (via `router.push()`)
  2. Added AppBar leading back buttons with safe fallback (`canPop ? pop : go('/dashboard')`) to category page and item detail page
  3. Created `lib/app/navigation_utils.dart` with reusable `SafeBack` extension on `BuildContext`
  4. Root resets (login success, logout, browse catalogue from empty states, landing→login) preserved as `context.go()`
- `context.go()` preserved only for: login success (`/`→`/dashboard`), logout (`/dashboard`→`/`), landing→login, browse catalogue from empty states, order success dialog→dashboard

### 6.29 Bug Fix — Snackbar Persists After Navigation (resolved)
- **Bug:** Item detail page's success/error snackbar (shown on root `ScaffoldMessenger`) remained visible even after navigating away via AppBar back, Android hardware back, or "View Cart" action
- **Root cause:** `MaterialApp.router` uses one root `ScaffoldMessenger` for all routes. With `push()` navigation, the previous route's Scaffold stays in the tree but hidden. The root snackbar overlay persists across route changes.
- **Fix (1 file — `item_detail_page.dart`):**
  1. Added `ScaffoldMessengerState? _messenger` instance variable — stored whenever a snackbar is shown (both success and error paths)
  2. Added `_clearSnackbars()` helper that calls `_messenger?.clearSnackBars()`
  3. `dispose()` calls `_clearSnackbars()` — catches Android hardware back and any route removal
  4. AppBar leading back button calls `_clearSnackbars()` before navigating
  5. "View Cart" `SnackBarAction.onPressed` calls `_clearSnackbars()` before `router.push('/cart')`
  6. Both success (green) and error (red) snackbars use consistent `_messenger` + `_clearSnackbars()` pattern

### 6.30 Feature — Tag Filter Row on Category Page (added)
- **Goal:** Parity with legacy Flet customer app — horizontal scrollable tag chip row above item grid
- **Flet behavior:** Tags extracted client-side from currently loaded items' `tags` JSONB field (not from `tag_master`). "All" chip resets filter. Filtering is local, no additional DB query.
- **Flutter implementation:**
  1. Created `mahalaxmi_shared/lib/services/tag_filter.dart` with two pure functions:
     - `extractSortedTags(List<RateItem>)` — collects unique non-empty tags, case-insensitive sorted
     - `filterItemsByTag(List<RateItem>, String? tag)` — returns all items when tag is null, otherwise filters by exact tag match
  2. Converted `category_page.dart` from `ConsumerWidget` to `ConsumerStatefulWidget` with `String? _selectedTag` state
  3. Added horizontal `ListView` chip row (52px tall) above the grid: "All" chip + one chip per unique tag
  4. Tag chips styled: selected = maroon background/white text, unselected = cream background/dark text with border
  5. Tags extracted from items already returned by `customerItemsByCategoryProvider` — no additional network call
  6. Filter resets on pull-to-refresh, error retry, and category change (new page instance)
  7. Empty filter state displays "No items found for this filter" with "Clear filter" button
  8. Tag row hidden when 0 or 1 unique tags exist (only meaningful filtering)
- **Key design decisions:**
  - Tag filtering is entirely client-side (items already loaded). No new provider or DB query needed.
  - Underscores in tag slugs are replaced with spaces for display (matching Flet behavior)
  - Tapping the same chip again deselects it (toggles back to "All")

### 6.31 Tests (updated)
- [x] 163 shared unit tests (all passing)
  - 9 tag filter tests: extractSortedTags (unique tags, empty, dedup, case-insensitive sort, empty strings) + filterItemsByTag (null, exact match, no match, exact not substring)
  - 8 repeat order item tests: validateRepeatableItem (null, unavailable, unpriced, valid) + orderItemToCartItem (basic, with colour, with sizes, preserves notes/quantity)
- [x] Customer app: no tests yet (UI logic tested manually via `flutter run`)
  - 6 new validation tests: Kaleera hasColor=false passes without color, Kaleera hasColor=true requires color, dynamic "Kalira" category passes
  - AppSession model (12 tests): creation, JSON round-trip, edge cases
  - SessionStorage (3 tests): save, load, clear
  - SessionNotifier (5 tests): login, logout, restore, persistence
  - AuthController (5 tests): admin/labour correct/wrong password, logout
  - CustomerAuthController (5 tests): valid PIN, invalid PIN, blocked customer, logout, session replacement
  - CartLine (3 tests): identity, equals/hashCode
  - CartState (3 tests): initial state, findById, items getter
  - CartNotifier addItem (11 tests): new item, multiple distinct items, merge sized, merge non-sized, distinct color/grind/box/notes/category, validation rejection, latest unitPrice
  - CartNotifier removeItem (3 tests): by id, unknown id, correct item removal
  - CartNotifier updateItem (3 tests): quantities, invalid rejection, unknown id
  - CartNotifier clear (1 test): full reset
  - CartNotifier validateAll (4 tests): valid cart, empty cart, corrupt state, multi-line detection
  - Dynamic categories (4 tests): unknown category with/without sizes, validation edge cases
  - Category-specific (4 tests): Raw_Material valid/invalid, Seasonal valid/invalid
  - Order service (13 tests): success payload mapping, source=customer, customer id/mobile/name, unitPrice from rateLookup, category from rateLookup, not logged in rejection, empty cart rejection, invalid item rejection, header failure, item rollback, rollback failure surfacing, cart not cleared by service, rateLookup fallback unitPrice
- [x] All tests passing

### 6.32 Feature — Add Again on My Orders (added)
- **Goal:** Parity with legacy Flet customer app — re-add items from past orders to current cart
- **Flet behavior:** Each order line has an "Add Again" button. Tapping shows a two-option dialog: "Repeat Same" (auto-adds with same selections) or "Repeat with Change" (navigates to item detail). Uses current catalogue price.
- **Flutter implementation:**
  1. Created `mahalaxmi_shared/lib/services/repeat_order_item.dart` with two pure functions:
     - `validateRepeatableItem(RateItem?)` — null check, `isAvailable==true`, `sellingPrice>0`
     - `orderItemToCartItem(OrderItem, RateItem)` — maps `OrderItem` fields to `CartItem`, uses current catalogue `RateItem.sellingPrice`
  2. Added `_showAddAgainSheet(OrderItem)` bottom sheet to `_OrderCardState` in `my_orders_page.dart`
  3. Bottom sheet has 3 options: Repeat Same (maroon button), Repeat with Change (outlined maroon), Cancel (text)
  4. Repeat Same flow: fetches item via `ItemRepository.getItemByNumber()`, validates, converts, adds to cart via `cartProvider.notifier.addItem()`, shows success/error snackbar
  5. Repeat with Change flow: fetches item, validates, pushes to `/item/:itemNumber` for customization
  6. Added `onAddAgain` callback to `_OrderItemRow` widget, passes up to `_OrderCardState`
  7. Both async flows guard `mounted` before using `context` after await
  8. Snackbar persistence: `messenger.clearSnackBars()` called before showing new snackbar
- **Key design decisions:**
  - Uses current catalogue `RateItem.sellingPrice`, not old `OrderItem.unitPrice` — matches Flet behavior (customer always gets latest price)
  - Repeat with Change navigates to item detail via `context.push()` — preserves navigation stack, back returns to My Orders
  - SnackBarAction captures `GoRouter.of(context)` before showing snackbar (not inside callback)
   - 8 new shared tests (4 validation + 4 conversion)

### 6.33 Admin Refinement — Manage Categories Add/Edit Fields (added)
- **Decision:** Removed manual URL textbox from Add Category UI; image picker upload is the only cover image method
- **Has Sizes** (boolean, category-level): Added to Category model as `hasSizes` with `@Default(false)`, JSON key `has_sizes`, DB column via migration `sql/migration_add_category_flags.sql`
- **Has Subcategories** (boolean, category-level): Added to Category model as `hasSubcategories` with `@Default(false)`, JSON key `has_subcategories`, same migration
- **Has Colors** and **Order Type**: Intentionally deferred (not exposed in UI)
- **Add Category dialog** updated:
  - URL text field removed
  - Gallery picker retained as sole cover image method
  - Has Sizes and Has Subcategories `SwitchListTile` controls added
  - Both flags saved via `repo.insertCategory()` on create
- **Edit Category dialog** updated:
  - URL text field removed; gallery re-upload added (shows current cover, allows replacement)
  - Has Sizes and Has Subcategories switches pre-filled from `cat.hasSizes` / `cat.hasSubcategories`
  - Changes saved via `repo.updateCategoryHasSizes()`, `repo.updateCategoryHasSubcategories()`
- **Repository additions:**
  - `updateCategoryHasSizes(int categoryId, bool hasSizes)` — updates `has_sizes` column
  - `updateCategoryHasSubcategories(int categoryId, bool hasSubcategories)` — updates `has_subcategories` column
- **SQL migration** at `legacy_flet_app/sql/migration_add_category_flags.sql`:
  ```sql
  ALTER TABLE categories
    ADD COLUMN IF NOT EXISTS has_sizes BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS has_subcategories BOOLEAN NOT NULL DEFAULT FALSE;
  ```
- **Tests:** 14 new Category model tests covering JSON fromJson/toJson for has_sizes/has_subcategories, subCategoryList, copyWith, equality
- **Verification:** 163/163 shared tests passing, admin app 0 errors, customer app 0 errors

### 6.34 Bug Fix — Tag Master Remove Tag (invalid JSONB write + missing tag_master deletion)
- **Root cause (error):** `ItemRepository.updateItemTags()` sent a Dart `List<String>` to the `rate_list.tags` JSONB column via `.update({'tags': tags})`. When the filtered list was empty (`[]`), the supabase_flutter client serialized the empty list in a way PostgreSQL rejected: `"invalid input syntax for type json"`. Fixed by explicitly typing the payload map as `Map<String, dynamic>` to ensure proper JSON serialization of empty arrays for JSONB columns.
- **Root cause (missing step):** `_removeTag()` only removed the tag string from each item's `tags` array but never deleted the `tag_master` record. The tag remained visible in the admin UI after refresh.
- **Fix (4 files):**
  1. `tag_repository.dart` — Added `deleteTag(int tagId)` method that deletes from `tag_master` by ID.
  2. `item_repository.dart` — Changed `updateItemTags` payload to explicitly typed `Map<String, dynamic>` to fix JSONB serialization of empty arrays.
  3. `manage_tags_page.dart` — Updated `_removeTag()` to:
     - Show count of affected items in confirmation dialog
     - After removing from items, also delete the `tag_master` record via `tagRepo.deleteTag(tagId)`
     - Show detailed snackbar: "Tag removed from N item(s) and Tag Master"
  4. `tag_master_test.dart` — **New** 10 tests: TagMaster model JSON round-trip, fromJson defaults, plus 6 tag list manipulation tests (remove preserves others, empty list, non-existent tag, duplicates, rename).
- **Verification:** 173/173 shared tests passing, admin app 0 errors, customer app 0 errors

---

## 7. Pending Migration Phases

### Phase 1 — ✅ COMPLETE (shared foundation checkpoint passed)

**Deferred from Phase 1 (not forgotten, just delayed):**
- `uploadImage()` / `uploadPdf()` Supabase Storage helpers
- `ImageService` (resize/crop/sharpen pipeline)
- `Result<T>` type system (typed success/failure wrapper)
- Connectivity tracking (`_consecutive_failures`, `isOnline()` pattern)
- SharedPreferences session storage implementation
- Lint/analyze CI setup

### Phase 2
- Customer authentication & navigation (GoRouter shell, PIN login, session persistence)

### Phase 3
- Customer catalogue (category grid, item grid, tag filter, item detail)

### Phase 4
- Customer order flow (cart, place order, my orders)

### Phase 5
- Customer offline (Isar)

### Phase 6
- Admin order management (dashboard, order form, karigar slip, WhatsApp share)

### Phase 7
- Admin item & costing systems (add/edit items, costing detail)

### Phase 8
- Admin settings & labour (categories, tags, customers, materials, production checklist)

### Phase 9
- Customer web/PWA

### Phase 10
- Production hardening (RLS, monitoring, CI/CD, performance)

---

## 8. Critical Business Rules

These must be preserved exactly in the Flutter implementation:

| Rule | Where Enforced |
|------|----------------|
| Labour must never see prices | All order-related views |
| Customer sees only `is_available=true` AND `selling_price > 0` | Catalogue queries |
| Admin sees everything | All views |
| Order status flow: pending → confirmed → cancelled/completed | `set_order_status()` |
| Order deletion is permanent (cascade) | `delete_order()` |
| Order items replaced on edit (delete + reinsert) | `update_order()` |
| Source = "customer" vs "admin" distinguishes origin | `create_order()` |
| PIN is 8-digit numeric, unique, permanent (no change UI) | Customer CRUD |
| Item number is unique and immutable on edit | Add Item form |
| Cart is NOT persisted (lost on app close) | Cart state |
| Line total = sum(qty) × unit_price (sized) or qty × unit_price (non-sized) | `calculate_line_total()` |

---

## 9. Supabase Rules

- **Project URL:** `https://lgiepatlslklpxmeqkww.supabase.co`
- **Storage bucket:** `product-images`
- **RLS:** Currently **disabled** on all tables — re-enable before production (Phase 10)
- **Immutable rule:** No existing table/column modifications. New features require additive changes only.
- **Tables:** `customers`, `categories`, `rate_list`, `orders`, `order_items`, `tag_master`, `materials`, `cost_breakdown`, `item_materials`, `app_settings`
- **Storage paths:** `product-images/{item_number}.{ext}`, `product-images/category_covers/{slug}.{ext}`, `product-images/order-pdfs/slip_{order_id}.pdf`

---

## 10. Flutter Architecture Rules

1. **No Supabase calls from widgets.** Widgets → Providers → Repositories → Supabase SDK
2. **No business logic in UI layer.** Shared package owns validation, calculation, formatting
3. **Repository methods return `Result<T>` or throw typed exceptions.** Never return null/empty on failure
4. **All customer queries filter `is_available=true`.** Missing this filter exposes hidden items
5. **Cart state in `StateNotifierProvider` (`CartNotifier`).** Not persisted to disk. All mutations go through `addItem()` / `removeItem()` / `updateItem()` / `clear()` — never mutate directly. Validation on add/update enforced at cart level.
6. **Navigate with `push` for deep screens, `go` for root resets.** Use `context.push()` for category→item, dashboard→category, cart→any deep screen. Use `context.go()` only for root resets: login success, logout, landing→login, browse catalogue from empty state, order success→dashboard.
7. **Back button fallback always safe.** Every AppBar leading back button uses `context.canPop() ? context.pop() : context.go('/dashboard')`. Never use blind `context.pop()`.
8. **GoRouter with `ShellRoute`** for persistent UI (admin: 5-tab bottom nav, customer: push drill-down)
9. **Each app independently buildable.** `flutter build` must work without the other app present
10. **No `dart:io` in shared package.** Breaks web builds
11. **No premature abstraction.** Port widget trees directly; don't create generic engines for single-use patterns

---

## 11. Flet Legacy Rules

- **DO NOT MODIFY** files in `legacy_flet_app/` — it's the frozen reference
- The Flet APK is still in production use until Flutter migration is complete
- Flet golden files serve as acceptance criteria for Flutter output
- 19 Flet-only workarounds documented in `EXPECTED_FLUTTER_FEATURES_FROM_FLET.md §5` — do NOT port these to Flutter
- 9 postponed items documented in §6 — do NOT implement during migration

---

## 12. Known Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Order form dynamic schema engine (~130 lines nested conditional UI) | 🔴 Extreme | Prototype with mock data before Supabase wiring |
| Costing material rows (add/remove/live recalc) | 🔴 High | StateNotifier for material rows; test all edge cases |
| PDF generation (bilingual, maroon/gold, multi-page) | 🔴 High | Option: Supabase Edge Function reusing Flet logic |
| WhatsApp share flow (PDF → upload → URL → launch) | 🔴 High | Step-by-step error handling; test on real device |
| Offline (Isar) architecture | 🔴 High | Start online-only; Isar in Phase 5 as separate layer |
| Tag Master multi-category chip UI (BUG-031 parity) | 🟡 Medium | Reusable TagChipSelector widget |
| HasSizes flag handling (absent vs explicit false in validation) | 🟡 Medium | Current port uses hasSizes always-set; verify with validateOrder path |
| No Flutter platform directories generated yet | 🟡 Medium | `flutter create` needed before any build/run |

---

## 13. Important File References

| File | Purpose |
|------|---------|
| `legacy_flet_app/main.py` | Entry point, UI, constants, validation engine, category schemas |
| `legacy_flet_app/db.py` | All Supabase operations (~1044 lines) |
| `legacy_flet_app/auth.py` | Admin/labour authentication |
| `legacy_flet_app/session_helper.py` | Session persistence |
| `legacy_flet_app/utils.py` | Image pipeline, validation, connectivity |
| `legacy_flet_app/slip_pdf_generator.py` | Karigar slip PDF generation |
| `legacy_flet_app/cache.py` | Offline cache logic |
| `legacy_flet_app/views/` | All Flet UI screens |
| `FLUTTER_MIGRATION_PHASES.md` | Detailed phase roadmap with dependencies |
| `EXPECTED_FLUTTER_FEATURES_FROM_FLET.md` | Feature parity checklist (42 items, per-priority, per-app) |
| `FLUTTER_WORKSPACE_README.md` | Workspace structure, setup, and rules |
| `mahalaxmi_shared/lib/models/` | Freezed model classes (9 models + generated code) |
| `mahalaxmi_shared/lib/services/validation.dart` | `validateCartItem`, `validateOrder` |
| `mahalaxmi_shared/lib/services/calculation.dart` | `calculateLineTotal`, `buildOrderSummary` |
| `mahalaxmi_shared/lib/services/tag_filter.dart` | `extractSortedTags`, `filterItemsByTag` |
| `mahalaxmi_shared/lib/constants/category_schemas.dart` | `CategorySchema` definitions |
| `mahalaxmi_shared/lib/repositories/supabase_client_provider.dart` | Centralized Supabase client |
| `mahalaxmi_shared/lib/repositories/base_repository.dart` | `RepositoryException`, `NotFoundException` |
| `mahalaxmi_shared/lib/repositories/category_repository.dart` | Category read methods |
| `mahalaxmi_shared/lib/repositories/item_repository.dart` | Rate item read methods |
| `mahalaxmi_shared/lib/repositories/customer_repository.dart` | Customer read methods |
| `mahalaxmi_shared/lib/repositories/order_repository.dart` | Order + order item read methods |
| `mahalaxmi_shared/lib/repositories/tag_repository.dart` | Tag master read + normalization |
| `mahalaxmi_shared/lib/repositories/material_repository.dart` | Materials + costing read methods |
| `mahalaxmi_shared/lib/repositories/settings_repository.dart` | App settings read methods |
| `mahalaxmi_shared/lib/providers/supabase_provider.dart` | `supabaseClientProvider` |
| `mahalaxmi_shared/lib/providers/repository_providers.dart` | 7 repository instance providers |
| `mahalaxmi_shared/lib/providers/categories_provider.dart` | Category read providers |
| `mahalaxmi_shared/lib/providers/items_provider.dart` | Item read providers (catalogue, search, pricing) |
| `mahalaxmi_shared/lib/providers/tags_provider.dart` | Tag master providers |
| `mahalaxmi_shared/lib/providers/app_settings_provider.dart` | Default margin, labour cost providers |
| `mahalaxmi_shared/lib/providers/session_provider.dart` | Session StateNotifier + storage provider |
| `mahalaxmi_shared/lib/providers/auth_provider.dart` | Admin/labour auth controller |
| `mahalaxmi_shared/lib/providers/customer_auth_provider.dart` | Customer PIN login controller + currentCustomerProvider |
| `mahalaxmi_shared/lib/models/app_session.dart` | Session model with AuthRole enum, JSON serialization |
| `mahalaxmi_shared/lib/services/session_storage.dart` | SessionStorage abstract class + InMemorySessionStorage |
| `mahalaxmi_shared/test/session_test.dart` | 28 tests for session, auth, customer auth |
| `mahalaxmi_shared/lib/models/cart_state.dart` | CartLine, CartState, CartMutationResult sealed hierarchy |
| `mahalaxmi_shared/lib/providers/cart_provider.dart` | CartNotifier (StateNotifier) + cartProvider + derived read providers |
| `mahalaxmi_shared/lib/providers/order_summary_provider.dart` | orderSummaryProvider (FutureProvider, watches cart + rateLookup) |
| `mahalaxmi_shared/test/cart_test.dart` | 51 tests for cart mutations, merge, validation, clear |
| `mahalaxmi_shared/lib/services/customer_order_service.dart` | CustomerOrderService + CustomerOrderResult sealed hierarchy |
| `mahalaxmi_shared/lib/providers/order_builder_provider.dart` | OrderBuilderController + orderBuilderProvider |
| `mahalaxmi_shared/test/order_service_test.dart` | 13 tests for order placement, validation, rollback |
| `mahalaxmi_shared/lib/models/cart_item.dart` | Cart item data class |
| `mahalaxmi_shared/lib/models/enums.dart` | Constants: sizes, colors, boxes, grind options |
| `mahalaxmi_shared/test/validation_test.dart` | 28 tests for validation |
| `mahalaxmi_shared/test/calculation_test.dart` | 15 tests for calculation + summary |
| `mahalaxmi_customer/lib/app/theme.dart` | Cream/gold/maroon customer theme |
| `mahalaxmi_customer/lib/app/router.dart` | GoRouter with auth redirect (/, /login, /dashboard) |
| `mahalaxmi_customer/lib/features/auth/pages/landing_page.dart` | Landing page with branding |
| `mahalaxmi_customer/lib/features/auth/pages/login_page.dart` | PIN login page |
| `mahalaxmi_customer/lib/features/dashboard/pages/dashboard_page.dart` | Category grid dashboard with logout |
| `mahalaxmi_customer/lib/features/cart/pages/cart_page.dart` | Cart screen with line list, remove, summary, Place Order |
| `mahalaxmi_customer/lib/features/category/pages/category_page.dart` | Category items grid with tag filter row |
| `mahalaxmi_customer/lib/features/category/pages/item_detail_page.dart` | Item detail with colour/quantity controls & add-to-cart |
| `mahalaxmi_customer/lib/features/orders/pages/my_orders_page.dart` | My Orders with expandable order details |
| `mahalaxmi_customer/lib/features/orders/providers/orders_provider.dart` | `customerOrdersProvider` typed provider |
| `mahalaxmi_shared/test/tag_filter_test.dart` | 9 tests: extractSortedTags + filterItemsByTag |
| `mahalaxmi_shared/lib/services/repeat_order_item.dart` | `orderItemToCartItem`, `validateRepeatableItem` |
| `mahalaxmi_shared/test/repeat_order_item_test.dart` | 8 tests: validation + conversion |
| `mahalaxmi_shared/lib/repositories/order_repository.dart` | `getOrdersWithItems`, `getOrderById`, `updateOrderStatus` |
| `mahalaxmi_admin/lib/main.dart` | Supabase init with fail-fast env validation |
| `mahalaxmi_admin/lib/app/app.dart` | MaterialApp.router with routerProvider |
| `mahalaxmi_admin/lib/app/theme.dart` | Blue Material 3 admin theme |
| `mahalaxmi_admin/lib/app/router.dart` | Auth redirect + StatefulShellRoute 4-tab bottom nav + detail routes |
| `mahalaxmi_admin/lib/app/navigation_utils.dart` | SafeBack extension |
| `mahalaxmi_admin/lib/features/auth/pages/login_page.dart` | Admin/Labour password login |
| `mahalaxmi_admin/lib/features/dashboard/providers/dashboard_provider.dart` | DashboardStats FutureProvider |
| `mahalaxmi_admin/lib/features/dashboard/pages/dashboard_page.dart` | Stats cards + recent orders |
| `mahalaxmi_admin/lib/features/orders/providers/admin_orders_provider.dart` | Admin order list & detail providers |
| `mahalaxmi_admin/lib/features/orders/pages/orders_page.dart` | Order list with tab filters, cards, pull-to-refresh |
| `mahalaxmi_admin/lib/features/orders/pages/order_detail_page.dart` | Order detail with items, totals, status update actions |
| `mahalaxmi_admin/lib/features/catalogue/pages/catalogue_page.dart` | Placeholder |
| `mahalaxmi_admin/lib/features/settings/pages/settings_page.dart` | Settings menu + logout |
| `mahalaxmi_admin/lib/features/catalogue/providers/admin_catalogue_provider.dart` | CategoryWithStats, adminCategoriesWithStatsProvider, adminCategoryItemsProvider |
| `mahalaxmi_admin/lib/features/catalogue/pages/catalogue_page.dart` | Category list with cover images, item counts |
| `mahalaxmi_admin/lib/features/catalogue/pages/category_items_page.dart` | Per-category item list with image, price, availability |
| `mahalaxmi_admin/lib/features/catalogue/pages/item_edit_page.dart` | Item edit: toggle availability, price, tags, attributes |
| `mahalaxmi_admin/lib/features/customers/providers/admin_customers_provider.dart` | adminCustomersProvider |
| `mahalaxmi_admin/lib/features/customers/pages/customers_page.dart` | Customer list with avatar, name, mobile, PIN, active badge |
| `mahalaxmi_admin/lib/features/customers/pages/customer_edit_page.dart` | Customer edit: name, mobile, PIN, enable/disable |

---

## 14. Immediate Next Steps

### ✅ Phase 1 (Shared Foundation) — COMPLETE
All shared-layer modules implemented, tested, and checkpoint-verified.
Deferred items recorded — see Section 7.

### ▶️ Next: Phase 3.5 — Admin Settings (Category & Tag Management)

Continue building admin app features:

1. **Manage Categories** — category CRUD with cover image
2. **Tag Master** — tag management with multi-category selector
3. **Default Margin** — margin setting form
4. **Archive Orders** — read-only completed/cancelled order list

### ✅ Phase 3.4 — Admin Customers Management (June 14)
Built customer management page with list and editing:

- **Customer list** — shop name, avatar initial, mobile, PIN display, active/disabled badge
- **Customer edit page** — edit shop name, owner name, mobile, PIN (8-digit validation), enable/disable toggle
- **PIN validation** — exactly 8 digits required before save
- **Confirmation** — customer login is blocked when disabled (`is_active=false`); PIN changes take effect immediately
- **CustomerRepository updates** — added `updateCustomerShopName`, `updateCustomerMobile`, `updateCustomerPin`, `updateCustomerActiveStatus`, `updateCustomerField` (generic)
- **GoRouter push** — `/customers` and `/customers/:customerId` routes
- **Settings link** — "Manage Customers" menu item in Settings now navigates to customer list
- **Pull-to-refresh, loading/error/empty states** throughout
- **No delete** — only enable/disable toggle
- **Customer login compatibility preserved** — `getCustomerByPin()` in customer app checks PIN directly; disabling a customer sets `is_active=false` which is checked in `CustomerAuthController`

### ✅ Phase 3.3 — Admin Catalogue Management (June 14)
Replaced catalogue placeholder with full category/product browsing and editing:

- **Category list** — name, cover image, total item count, available item count
- **Category items list** — per-category items with image, item number, price, availability badge, subcategory, tags
- **Item edit page** — toggle availability (with confirmation dialog), edit selling price, edit tags (comma-separated), read-only attribute display (hasSizes, hasColor, costPrice, margin, status)
- **Shared repository updates** — `updateItemAvailability()`, `updateItemSellingPrice()`, `updateItemTags()` added to `ItemRepository`
- **GoRouter push** — `/catalogue/:categoryName` and `/catalogue/:categoryName/edit/:itemNumber` use `parentNavigatorKey` for full-screen push
- **Pull-to-refresh** on all list pages
- **Loading/error/empty states** throughout
- **Confirmation dialog** before toggling availability
- **Customer safety** — items set unavailable or price 0 are filtered by customer app's `getCustomerCatalogue()` and `getCustomerItemsByCategory()` which query `is_available=true` and `selling_price>0`
- **`0 errors, 0 warnings`** — flutter analyze clean
- **149 shared tests passing** — no regressions

### ✅ Phase 3.1 — Admin App Shell (June 14)
Created admin app from scratch:
- **Supabase env validation** — fail-fast pattern matching customer app
- **Auth** — Admin/Labour password login page using shared `AuthController`
- **GoRouter with StatefulShellRoute** — 4-tab bottom navigation (Dashboard, Orders, Catalogue, Settings)
- **Auth redirect** — unauthenticated → `/login`, authenticated → `/dashboard`
- **Dashboard** — real order stats from shared `OrderRepository` (Total/Pending/Confirmed/Completed/Cancelled) + recent orders list
- **Placeholder tabs** — Orders, Catalogue, Settings with coming-soon pages
- **INTERNET permission** added to AndroidManifest.xml
- **`build_apk.ps1`** — one-click debug APK builder
- **`0 errors, 0 warnings`** — flutter analyze clean

### ✅ Phase 3.2 — Admin Orders Management (June 14)
Replaced orders placeholder with full order management:
- **Tab filters** — All, Pending, Confirmed, Completed, Cancelled via `TabBar`
- **Order cards** — order #, customer name, date, status badge, total amount, item count
- **Tap → detail page via `context.push()`** — preserves navigation stack
- **Order detail** — customer info, status badge, status update buttons (Confirm/Complete/Cancel), items list with size/color/quantity/rate/line total, grand total
- **Status transitions** — Pending→Confirmed, Confirmed→Completed, Pending/Confirmed→Cancelled
- **Status update in shared layer** — `updateOrderStatus()` added to `OrderRepository`
- **Pull-to-refresh** on both list and detail pages
- **Loading/error/empty states** throughout
- **`0 errors, 0 warnings`** — flutter analyze clean
- **149 shared tests passing** — no regressions

### ✅ Add Again feature added (June 14)
Legacy Flet parity: each order line in My Orders now has "Add Again" button → bottom sheet with Repeat Same / Repeat with Change / Cancel. Uses current catalogue price. 8 new shared tests (149 total).

### Navigation & UX Fixes Applied (June 14):
- **Snackbar margin:** Green success snackbar on add-to-cart now has `margin: EdgeInsets.only(bottom: 88, left: 12, right: 12)` to clear the bottom CTA bar (previously overlapped "Add to Cart" button)
- **Stack-by-stack navigation:** All deep navigations changed from `context.go()` to `context.push()`. Android hardware back now goes back through screens (cart→item→category→dashboard) instead of minimizing the app
- **AppBar back buttons:** Category page and item detail page now have leading back buttons with safe fallback (`canPop ? pop : go('/dashboard')`)
- **safeBack helper:** Created `lib/app/navigation_utils.dart` with `SafeBack` extension on `BuildContext` for reusable safe-back pattern
- **Snackbar persistence:** Added `_messenger` + `_clearSnackbars()` in item detail page — snackbar is dismissed on AppBar back, Android hardware back (via `dispose()`), and View Cart tap. Both success and error snackbars use the same consistent pattern.
- **Tag filter row:** Category page now has a horizontal tag chip row (52px) above the item grid. Tags extracted client-side from loaded items. "All" chip + per-tag chips. Filtering is local, no DB query. Created `tag_filter.dart` in shared with `extractSortedTags()` + `filterItemsByTag()`. 9 new shared tests (149 total).
- **Add Again:** My Orders page now has "Add Again" button per order line → bottom sheet with Repeat Same (auto-adds to cart) / Repeat with Change (navigates to item detail) / Cancel. Created `repeat_order_item.dart` with `orderItemToCartItem()` + `validateRepeatableItem()`. 8 new shared tests (149 total).

### Deferred (revisit after Phase 2-3):
- `Result<T>` type system
- Image service
- Storage upload helpers
- Connectivity tracking
- Lint/analyze CI setup

---

## Maintenance Log

| Date | Change | Author |
|------|--------|--------|
| 2026-06-13 | Initial creation | — |
| 2026-06-13 | Phase 1.4 — Repository layer completed (7 repos, read-only) | — |
| 2026-06-13 | Phase 1.5 — Basic read Riverpod providers completed (6 files, ~20 providers) | — |
| 2026-06-13 | Phase 1.6 — Session & Auth providers completed (3 files, ~6 providers, 28 new tests) | — |
| 2026-06-13 | Phase 1.7 — Cart state architecture completed (3 files, CartNotifier with add/merge/remove/update/clear/validate, 51 tests) | — |
| 2026-06-13 | Phase 1.8 — Customer order builder & placement foundation completed (3 files, OrderRepository write methods, CustomerOrderService with rollback, 13 tests) | — |
| 2026-06-13 | Phase 1 Checkpoint — Shared foundation verified (123 tests, 0 errors, 10/10 architecture checks passed, PHASE_1_CHECKPOINT.md created) | — |
| 2026-06-13 | Phase 2.1 — Customer app shell, routing, landing page & PIN login completed | — |
| 2026-06-13 | Phase 2.2 — Customer dashboard category grid completed (real categories, 3 states, pull-to-refresh, category route) | — |
| 2026-06-13 | Phase 2.3 — Customer category items grid completed (real items, image cards, price/tags, async states) | — |
| 2026-06-13 | Phase 2.4 — Item detail & add-to-cart completed (image, colour, sizes, quantities, live total, cart integration) | — |
| 2026-06-13 | Phase 2.5 — Cart screen completed (line list, remove, summary, badge, Place Order placeholder) | — |
| 2026-06-13 | Phase 2.6 — Place order UI completed (confirmation sheet, order submission, typed error handling, cart clearing) | — |
| 2026-06-13 | Phase 2.7 — Customer my orders completed (order history, expandable items, status badges, customer_id filter) | — |
| 2026-06-13 | Test build checkpoint — customer debug APK built (148.5 MB, debug, multi-arch) | Requires real-device testing |
| 2026-06-13 | Bug fix — Metal Bangles category item query mismatch (replaceAll('_', ' ') on query name) | — |
| 2026-06-13 | Bug fix — Kaleera color validation ignoring hasColor attribute (validation always required color) | — |
| 2026-06-13 | Bug fix — My Orders 0 amount/items (orderItems JSON key mismatch, lineTotal getter wrong) | — |
| 2026-06-13 | Bug fix — My Orders TypeError: production_status is String, not Map (legacy Flet stores JSON string) | — |
| 2026-06-13 | Bug fix — Android APK login: missing INTERNET permission + build missing --dart-define-from-file=.env | — |
| 2026-06-14 | Bug fix — Add-to-cart snackbar overlapping bottom bar (added margin) | — |
| 2026-06-14 | Bug fix — Navigation stack: Android back exited app instead of stack-by-stack (go→push for deep nav, AppBar back buttons, safeBack helper) | — |
| 2026-06-14 | Bug fix — Snackbar persists after navigation (added _messenger reference, _clearSnackbars() helper, cleared in dispose/back/View Cart) | — |
| 2026-06-14 | Feature — Tag filter row on category page (extractSortedTags + filterItemsByTag in shared, 9 new tests, ConsumerStatefulWidget with chip row), 141 tests total | — |
| 2026-06-14 | Feature — Add Again on My Orders (repeat_order_item.dart, bottom sheet with Repeat Same/Repeat with Change/Cancel, 8 new tests), 149 tests total | — |
| 2026-06-14 | Phase 3.1 — Admin app shell (auth, routing, bottom nav, dashboard, env validation, INTERNET permission, build script) | — |
| 2026-06-14 | Phase 3.2 — Admin orders management (tab filters, order cards, detail page, status update via repository) | — |
| 2026-06-14 | Phase 3.3 — Admin catalogue management (categories list, items list, item edit with availability/price/tags) | — |
| 2026-06-14 | Phase 3.4 — Admin customers management (list, edit, PIN reset, enable/disable) | — |
| 2026-06-14 | Phase 3.5 — Admin settings / master data (tags rename/remove, categories edit, default margin, material add/delete) | — |
| 2026-06-14 | Phase 3.6 — Admin order creation (customer autocomplete, catalogue item picker, review & place, qty validation) | — |
| 2026-06-14 | Audit — Admin app stability audit completed (Bug 1: Dashboard order.id→orderId + orderDate String→DateTime parse. Bug 2: Removed duplicate adminCustomersProvider. Bug 3: Customer edit saves ownerName. Bug 4: Create order refreshes orders+dashboard. Bug 5/6: Replaced dynamic types with typed Order/CategoryWithStats. Bug 8: Added non-zero qty validation on place order. 0 errors, 0 warnings, 149 tests passing.) | Stable beta quality |

### 6.33 Audit Findings — Admin App Full Audit (2026-06-14)

**Bugs found and fixed:**

| # | File | Issue | Fix |
|---|------|-------|-----|
| 1 | `dashboard_page.dart` | Used `order.id` (model has `orderId`); `order.orderDate` treated as `DateTime` but it's a `String` | Changed to `order.orderId`, added `_formatDate()` with `DateTime.parse()` |
| 2 | `admin_order_create_provider.dart` | Duplicate `adminCustomersProvider` (also defined in `customers_provider.dart`) | Removed duplicate; `create_order_page.dart` imports from correct file |
| 3 | `customer_edit_page.dart` | Owner name field displayed but not saved to DB | Added `updateCustomerField('owner_name', ...)` call |
| 4 | `create_order_page.dart` | After placing order, orders list / dashboard showed stale data | Added `ref.refresh(adminAllOrdersProvider)` and `ref.refresh(dashboardStatsProvider)` |
| 5 | `dashboard_page.dart` | `_OrderListItem` used `dynamic` type | Changed to typed `Order` |
| 6 | `catalogue_page.dart` | `_CategoryCard` used `dynamic` type | Changed to typed `CategoryWithStats` |
| 7 | `item_edit_page.dart` | Re-fetches entire category to find one item (inefficient) | Not a bug, no fix needed |
| 8 | `create_order_page.dart` | No validation for zero qty/size on line items before placing | Added loop checking `hasSizes&&totalSizeQty==0` and `!hasSizes&&quantity<=0` |

**Verification results:**
- Admin app: **0 errors, 0 warnings** (7 info-level: 6 const hints + 1 anonKey deprecation)
- Customer app: **0 errors, 0 warnings** (23 info-level, unchanged)
- Shared tests: **149/149 passing** (unchanged)
- INTERNET permission present in `AndroidManifest.xml`
- `.env` file present with valid Supabase credentials
- `build_apk.ps1` uses `--dart-define-from-file=.env`
- Navigation: all full-screen routes use `parentNavigatorKey: _rootNavigatorKey` for correct push behavior
- Snackbar lifecycle: `mounted` guards present after all async gaps across all pages
- Pull-to-refresh: present on dashboard, orders, catalogue, customers, settings pages
