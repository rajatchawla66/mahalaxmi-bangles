# FLUTTER MIGRATION PHASES — Strict Execution Roadmap

> **Master Document** — Do not modify without reviewing all dependencies.
> **Architecture:** Flutter (Dart) + Supabase + Riverpod + GoRouter + Isar
> **Projects:** `mahalaxmi_shared` / `mahalaxmi_customer` / `mahalaxmi_admin`
> **Strategy:** Shared-first → Customer APK → Admin APK → Customer Web → Production

---

## Contents

1. [Migration Blockers](#a-migration-blockers)
2. [Highest-Risk Migrations](#b-highest-risk-migrations)
3. [Lowest-Risk / Easy-Win Features](#c-lowest-risk--easy-win-features)
4. [Features Deliberately Delayed](#d-features-deliberately-delayed)
5. [Testing Checkpoints](#e-testing-checkpoints)
6. [Architectural Safety Rules](#f-architectural-safety-rules)
7. [Phase 1 — Shared Foundation](#phase-1--shared-foundation)
8. [Phase 2 — Customer Authentication & Navigation](#phase-2--customer-authentication--navigation)
9. [Phase 3 — Customer Catalogue Core](#phase-3--customer-catalogue-core)
10. [Phase 4 — Customer Order Flow](#phase-4--customer-order-flow)
11. [Phase 5 — Customer Advanced & Offline](#phase-5--customer-advanced--offline)
12. [Phase 6 — Admin Order Management](#phase-6--admin-order-management)
13. [Phase 7 — Admin Item & Costing Systems](#phase-7--admin-item--costing-systems)
14. [Phase 8 — Admin Settings & Labour](#phase-8--admin-settings--labour)
15. [Phase 9 — Customer Web / PWA](#phase-9--customer-web--pwa)
16. [Phase 10 — Production Hardening & Polish](#phase-10--production-hardening--polish)
17. [Dependency Graph](#dependency-graph)

---

## A. Migration Blockers

These must be complete before dependent work can start.

| Blocker | Blocks | Phase Resolved | Why It Blocks |
|---------|--------|----------------|---------------|
| **Dart models for all Supabase tables** | All repositories, all providers, all features | Phase 1 | Every feature reads/writes Supabase. Without models, nothing compiles. |
| **Supabase repository layer** | All data-fetching features | Phase 1 | No feature can display or mutate data without repos. |
| **Riverpod providers for shared state** | Auth flow, cart, catalogue cache | Phase 1 | State management foundation required by every screen. |
| **Pure function library** (validation, calculation) | Order form, cart, customer order flow | Phase 1 | Order form validation and line-total calculation needed by both customer and admin order flows. |
| **GoRouter shell route structure** | Navigation in both apps | Phase 2 | Without routing, no screen navigation exists. |
| **Authentication provider + session persistence** | Customer dashboard, admin home, all protected routes | Phase 2 | Customer and admin apps both require role-based access. |
| **Supabase Storage upload helper** | Image upload, PDF upload, category cover upload | Phase 4 (admin) | Admin image pipeline cannot function without storage uploads. |
| **Isar offline schema + repository** | Offline catalogue, offline orders | Phase 5 | Offline features depend entirely on Isar collections being defined and populated. |

---

## B. Highest-Risk Migrations

These sections have the highest probability of bugs, architectural missteps, or significant rework. Allocate extra testing time and consider spike/prototype before full implementation.

| Feature | Risk Level | Why It's Risky | Mitigation |
|---------|-----------|----------------|------------|
| **Order Form Dynamic Schema Engine** | 🔴 Extreme | The Flet `build_category_fields()` generates per-item controls based on `has_sizes`/`has_color` flags with conditional steppers, dropdowns, and custom-color text fields. This is 130 lines of nested conditional UI logic. Getting the widget tree wrong means category-specific validation breaks silently. | Build a minimal Flutter prototype with one sized item + one non-sized item BEFORE wiring to Supabase. Verify all 4 category types render correctly with a mock data provider. |
| **Costing Detail — Material Rows** | 🔴 High | Dynamic row add/remove with live recalculation across multiple material types (master dropdown vs custom text field), rate auto-fill from master, per-row validation, and save to 2 tables (`item_materials` + `rate_list`). Data flow is complex and error-prone. | Separate data state (list of material entries) from widget rendering. Use a `StateNotifier` for material rows. Test all edge cases: zero rows, all master materials, mixed master+custom, invalid qty/rate. |
| **PDF Generation — Karigar Slip** | 🔴 High | Bilingual (Hindi/English), maroon/gold A4 layout, image thumbnails with watermark, sizes boxes table, multi-page support. The Dart `pdf` package has different APIs than `fpdf2`. Getting pixel-perfect parity is non-trivial. | Either (a) port to Dart `pdf` package with a dedicated test that compares against Flet golden output, or (b) offload to a Supabase Edge Function (Python/pdfkit) to reuse the Flet logic. Option (b) is safer. |
| **WhatsApp Share Workflow** | 🔴 High | Multi-step flow: generate PDF → upload to Supabase Storage → build WhatsApp URL with PDF link → launch URL. Failure at any step must show user-friendly error. `url_launcher` behavior varies by platform. | Build a `ShareService` with explicit step-by-step error handling. Test on real Android device. Handle edge case: WhatsApp not installed. |
| **Offline Architecture (Isar)** | 🔴 High | Entirely new architecture compared to Flet's JSON-file approach. Isar schema design, sync strategy (full vs incremental), conflict resolution, image caching. Web requires Drift/SQLite WASM instead of Isar. | Start with online-only for Phases 2–4. Add Isar in Phase 5 as a separate, testable layer. Use a repository pattern that abstracts offline/online so switching is a provider swap. Do NOT attempt offline in first customer release. |
| **Tag Master — Multi-Category Chip UI** | 🟡 Medium | Category-filtered chip selector with "Global" special case, edit dialog with same chip UI, category constraint logic. Flet implementation had bugs (BUG-031). | Port chip selector as a reusable `TagChipSelector` widget. The category filtering logic is pure — extract to shared package. Test all combinations: global-only, category-specific, mixed. |

---

## C. Lowest-Risk / Easy-Win Features

These are mechanical ports with zero business logic complexity. Build these first to establish architecture patterns, CI pipeline, and developer confidence.

| Feature | Est. Effort | Why It's Easy | Phase |
|---------|-------------|---------------|-------|
| **Dart model classes** (10+ tables) | 1 day | Direct 1:1 mapping from JSON shapes. No logic, no UI. Use `json_serializable` or `freezed`. | 1 |
| **Constants & enums** (`COLOR_OPTIONS`, `BOX_OPTIONS`, `GRIND_OPTIONS`, `CATEGORY_SCHEMAS`) | 0.5 day | Trivial data structures. Zero dependencies. | 1 |
| **Pure validation functions** (`validate_cart_item`, `validate_order`) | 0.5 day | Already pure functions in Flet. Mechanical Dart port. Write unit tests immediately. | 1 |
| **Line total calculator** (`calculate_line_total`) | 0.25 day | Pure math function. Zero Flutter dependency. | 1 |
| **Order summary builder** (`build_order_summary`) | 0.5 day | Pure function. Group + sum by category. Write unit tests immediately. | 1 |
| **Connectivity tracking** (failure counter + `isOnline()`) | 0.25 day | Simple integer counter + boolean getter. | 1 |
| **Session persistence** (`shared_preferences` wrapper) | 0.25 day | 3 functions: save/load/clear. | 2 |
| **Basic category grid UI** | 1 day | Static GridView with data from repo. No interactivity beyond navigation. | 3 |

---

## D. Features Deliberately Delayed

These provide marginal value for high implementation cost. Do not prioritize over core workflow completion.

| Feature | Delayed Until | Rationale |
|---------|---------------|-----------|
| **Push notifications (FCM)** | Phase 10 | Not in Flet. Entirely new feature. No parity requirement. Requires Firebase setup. |
| **`workmanager` background sync** | Phase 10 | Flet used thread-based fetch. Not critical for MVP. Online-only is acceptable for V1 Flutter. |
| **Full offline with Isar** | Phase 5 (minimal), Phase 10 (full) | Start with online-only. Add Isar read cache in Phase 5. Full offline (write queue + conflict resolution) is Phase 10. |
| **Customer Web/PWA** | Phase 9 | Web adds platform-specific issues (no Isar, no `share_plus`, different image rendering). Customer APK is the priority. |
| **Camera plugin (native photo capture)** | Phase 8 | Flet used `FilePicker` (gallery only). Camera is a nice-to-have. Gallery + camera fallback to the same image pipeline. |
| **Supabase RLS re-enable** | Phase 10 | Currently disabled. Re-enabling requires policy design + testing. Will break app if done incorrectly. |
| **iPhone testing** | Phase 9 | Requires macOS + Apple Developer account. Not feasible for current solo-dev setup. |
| **Performance optimization** | Phase 10 | Premature optimization is wasteful. Build clean first, profile later. |
| **Multi-select share (Admin Catalogue)** | Post-MVP | Never implemented in Flet. No business requirement confirmed. |
| **YouTube tutorial card on landing page** | Post-MVP | "Coming Soon" placeholder. No content exists. |

---

## E. Testing Checkpoints

Each checkpoint defines: what must work, who tests it, and what gates the next phase.

| Checkpoint | After Phase | What Must Work | Gating |
|------------|-------------|----------------|--------|
| **CP-1: Shared Package Stable** | Phase 1 | All models compile. All repos fetch real Supabase data. All pure functions pass unit tests. Riverpod providers resolve without errors. | Phase 2 cannot start until repos return real data from Supabase. |
| **CP-2: Customer Can Login & Browse** | Phase 3 | PIN login works against Supabase. Category grid loads customer data. Item grid displays with tag filter. Item detail loads. | Customer cannot reach Phase 4 (order flow) without a working catalogue. |
| **CP-3: Customer Can Order** | Phase 4 | Item detail → add to cart → cart view → place order → order appears in Supabase. My Orders screen shows order. | Customer APK is feature-complete. Admin phases can proceed with confidence that the shared layer works end-to-end. |
| **CP-4: Admin Can Manage Orders** | Phase 6 | Dashboard loads orders. Create/edit/save order works. Status management (confirm/cancel/complete) works. Order detail renders. Karigar slip shares via WhatsApp. | Admin cannot proceed to settings until order management is stable. |
| **CP-5: Admin Can Manage Catalogue** | Phase 7 | Add/edit item with image upload works. Catalogue CRUD works. Costing system works (material rows + margin + save). | Admin feature-complete. Remaining phases are settings CRUD and labour. |
| **CP-6: Admin Settings Complete** | Phase 8 | All 6 settings screens functional: categories, margin, materials, tags, customers, archive. Labour checklist works. | All parity features ported. Remaining work is web + hardening. |
| **CP-7: Customer Web Stable** | Phase 9 | Customer APK features work identically on web (PWA). Image rendering correct. Offline via localStorage/Drift. share_plus replaced with url_launcher fallback. | Web is deployable for beta testing. |
| **CP-8: Production Ready** | Phase 10 | Error monitoring active. RLS enabled and tested. CI/CD builds both APKs. APK signing configured. Performance passes Lighthouse (web) and profile mode (APK). | Production launch. |

---

## F. Architectural Safety Rules

### Data Layer Rules
1. **No Supabase calls from widgets.** All data access goes through repositories. Widgets call providers, providers call repositories, repositories call Supabase client.
2. **No business logic in UI layer.** Validation, calculation, and formatting functions live in `mahalaxmi_shared`. Widgets are dumb renderers.
3. **No schema changes without explicit review.** The Supabase schema is shared between Flet (legacy), Flutter (new), and potentially the old Flet APK still in use. Every migration must be additive (add column, never remove/rename) until Flet is fully decommissioned.
4. **Repository methods return `Result` types or throw typed exceptions.** Never return `null` or empty list to indicate failure — Flet's `db.py` does this and it caused silent data loss bugs (BUG-027, BUG-028, BUG-029).
5. **All Supabase queries filter `is_available=true` for customer-facing endpoints.** The Flet codebase has this filter in `get_customer_catalogue()` and `get_customer_items_by_category()`. Missing this filter exposes hidden items to customers.

### State Management Rules
6. **Per-category cache pattern → `FutureProvider.family`.** Flet's `customer_category_cache` dict maps directly to Riverpod's `FutureProvider.family((ref, String category) => ...)`. Do not reimplement the dict pattern.
7. **Cart state in `StateNotifierProvider`.** Flet's `state["customer_cart"]` is a simple list. Riverpod StateNotifier with add/remove/clear/placeOrder methods.
8. **Session state in a dedicated provider.** Read from `shared_preferences` on app start. Write on login/logout. Expose via `StreamProvider` or `StateProvider`.

### Navigation Rules
9. **GoRouter with `ShellRoute` for persistent UI.** The Flet interceptor pattern (always 2 views) maps to GoRouter's `ShellRoute`. Define routes upfront in a `routes.dart` file per app.
10. **Admin and customer apps have separate GoRouter configurations.** Do not share route definitions — the navigation structures are fundamentally different (admin: bottom nav with 5 tabs; customer: push-based drill-down).

### Code Organization Rules
11. **Do not duplicate business logic between apps.** `mahalaxmi_shared` is the single source of truth for: models, repositories, providers, validation, calculation, constants, utilities.
12. **No `dart:io` in shared package.** Breaks web builds. Use `universal_io` or layer-separate platform-specific code.
13. **Each app has its own `presentation/` layer** (widgets, pages, app-specific providers). Shared widgets (item card, category tile, connectivity banner) go in `mahalaxmi_shared`.
14. **No premature abstraction.** Do not create generic "widget factories" for screens that appear once. Flet's `build_category_fields()` is used in exactly one place (order form) — port as a dedicated widget, not a generic engine.

### Migration-Specific Rules
15. **One feature per PR/commit.** Do not mix concerns. A commit that adds "customer dashboard" should not also refactor the repository layer.
16. **Flet golden files as acceptance criteria.** For each feature, create a test that asserts the Flutter output matches Flet behavior. Start with pure functions (easy), extend to widget tests.
17. **Do not re-audit framework choice.** Flutter was chosen. This document is about execution, not re-evaluation.
18. **No new features during migration.** Every line of code in this migration ports an existing Flet feature. New features (push notifications, camera, FCM) are explicitly delayed to Phase 10+.

---

## PHASE 1 — Shared Foundation

### Objective
Establish every dependency that both customer and admin apps will consume. By the end of this phase, `mahalaxmi_shared` is a compiled, tested Dart package with no Flutter dependencies in its core layer.

### Why This Phase Comes Now
Both apps need models, repositories, providers, and utility functions. Building shared infrastructure first prevents:
- Duplicated model definitions across apps
- Repository logic scattered between projects
- Validation bugs diverging between customer and admin
- Rework when connecting UI to data

### Features Included
| # | Feature | Source File (Flet) | Est. Hours |
|---|---------|-------------------|------------|
| 1.1 | Dart model classes for all 10+ tables | `db.py` (schema inferred from REST responses) | 6 |
| 1.2 | `json_serializable` / `freezed` annotations | — | 2 |
| 1.3 | Supabase client configuration | `db.py:62-63` | 1 |
| 1.4 | Repository classes: `ItemRepository`, `CategoryRepository`, `OrderRepository`, `CustomerRepository`, `TagRepository`, `MaterialRepository`, `SettingsRepository` | `db.py:254-1044` | 16 |
| 1.5 | `upload_image()` / `upload_pdf()` Supabase Storage helpers | `db.py:147-228` | 3 |
| 1.6 | Connectivity tracking (`_consecutive_failures`, `isOnline()`) | `db.py:29-57` | 1 |
| 1.7 | Pure function library: `validate_cart_item`, `validate_order`, `calculate_line_total`, `build_order_summary` | `main.py:99-374`, `utils.py:45-109` | 4 |
| 1.8 | Constants & enums: `COLOR_OPTIONS`, `BOX_OPTIONS`, `GRIND_OPTIONS`, `CATEGORY_SCHEMAS` | `main.py:35-96`, `db.py:68-72` | 1 |
| 1.9 | `Result<T>` type and typed exception classes | — | 1 |
| 1.10 | Riverpod providers for all repositories (shared state) | — | 4 |
| 1.11 | `ImageService` (resize/crop/resize pipeline — Dart `image` package) | `utils.py:140-168` | 4 |
| 1.12 | Unit tests for all pure functions | — | 3 |

### Dependencies
- `supabase-flutter` package
- `riverpod` / `flutter_riverpod`
- `json_serializable` / `freezed` (build-time)
- `image` package (Dart)
- `http` package

### High-Risk Areas
- **Repository layer correctness.** Every repository function must be tested against real Supabase data before Phase 2 begins. A bug in `ItemRepository` will corrupt every downstream feature.
- **Image pipeline quality.** The 1080×1350 4:5 crop + sharpen + Q93 JPEG must match Flet output exactly. Differences will be visible in the B2B catalogue.

### Suggested Implementation Order
1. Models + `freezed` annotations (no Supabase dependency)
2. Supabase client setup
3. `ItemRepository` + `CategoryRepository` (simplest, read-heavy)
4. `OrderRepository` (write-heavy, more complex)
5. `CustomerRepository` + `TagRepository` + `MaterialRepository` + `SettingsRepository`
6. Pure functions + unit tests
7. Constants + enums
8. Connectivity tracking
9. `Result<T>` type system
10. `ImageService`
11. Riverpod providers wrapping all repositories
12. End-to-end test: write + read a test record in Supabase

### Testing Strategy
- Unit tests for all pure functions (run in CI)
- Integration tests for each repository against live Supabase (manual, tagged `integration`)
- Golden image comparison for image pipeline output
- Provider resolution smoke test (all providers create without throwing)

### Exit Criteria (CP-1)
- [ ] All models compile with `freezed` / `json_serializable`
- [ ] Every repository can fetch real data from Supabase
- [ ] `Result<T>` type is used by all repository methods
- [ ] All pure functions pass unit tests (100% coverage)
- [ ] Image pipeline produces 1080×1350 JPEG with correct crop
- [ ] All Riverpod providers resolve without runtime errors
- [ ] CI pipeline runs shared package tests

### Estimated Complexity
**Low-Medium.** Mostly mechanical port with well-defined inputs/outputs. No UI complexity.

### Affected Projects
- `mahalaxmi_shared` (only)

---

## PHASE 2 — Customer Authentication & Navigation

### Objective
Build the customer app shell: authentication, session persistence, navigation, and theme. By the end of this phase, a user can launch the app, see the landing page, log in with a PIN, and land on an empty dashboard.

### Why This Phase Comes Now
Without authentication, no customer-specific feature is reachable. This phase establishes:
- The GoRouter navigation skeleton that all subsequent customer features plug into
- The session provider that guards authenticated routes
- The theme and visual language (cream/gold/maroon) that defines the brand

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 2.1 | GoRouter shell route structure | `main.py:550-670,888-1073` | 4 |
| 2.2 | Premium brand landing page (cream/gold/maroon, logo, GST, contact cards, ornamental dividers) | `views/auth.py:18-349` | 6 |
| 2.3 | Customer PIN login screen | `views/auth.py:45-95`, `views/customer.py:12-102` | 4 |
| 2.4 | Session persistence (`shared_preferences`) | `session_helper.py` | 1 |
| 2.5 | Auth provider (Riverpod) | — | 2 |
| 2.6 | Route guards (redirect to login if unauthenticated) | — | 2 |
| 2.7 | Exit confirmation dialog (back-button handling) | `main.py:589-622` | 2 |
| 2.8 | Theme configuration (colors, typography, component themes) | — | 2 |

### Dependencies
- Phase 1 (models, repos, auth provider)
- `go_router` package
- `shared_preferences` package
- `url_launcher` package (contact cards)
- `flutter_riverpod`

### High-Risk Areas
- **GoRouter shell route vs direct navigation.** Flet's `page.go()` is imperative. GoRouter's declarative routing is a different mental model. Route configuration must be planned upfront — badly structured routes cause pain later.
- **Back-button handling parity.** Flet's interceptor + `go_back()` + `BACK_MAP` + exit dialog is complex. Flutter's `PopScope` + GoRouter `context.pop()` must replicate all edge cases: root back → exit dialog, form back → previous screen, modal back → dismiss.

### Suggested Implementation Order
1. Theme configuration (no dependencies, instant visual feedback)
2. GoRouter shell route with placeholder pages
3. Auth provider + session provider
4. Route guards (redirect to `/login` when no session)
5. Landing page (stateless — no auth dependency)
6. PIN login screen (connects to `CustomerRepository`)
7. Exit dialog (`PopScope` wrapper)
8. Wire up: login success → navigate to dashboard (empty placeholder)

### Testing Strategy
- Widget test for landing page visual fidelity
- Widget test for PIN login flow (mock repository returns valid/invalid/blocked customer)
- Integration test for GoRouter navigation (all defined routes are reachable)
- Manual test on Android: install APK, verify login/logout/back-button/exit

### Exit Criteria (CP-2a)
- [ ] Landing page renders at 360px–420px screen widths
- [ ] PIN login accepts valid PIN → navigates to dashboard (empty)
- [ ] Invalid PIN shows error, blocked account shows blocked message
- [ ] Network error shows user-friendly message (not crash)
- [ ] Session persists across app restart (re-login not required)
- [ ] Logout clears session and returns to landing page
- [ ] Hardware back on root shows exit confirmation dialog
- [ ] Exit dialog Cancel returns to app, Exit closes app

### Estimated Complexity
**Low-Medium.** Mostly UI with one database call (PIN lookup). Navigation logic is the only risk area.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_shared` (auth provider added)

---

## PHASE 3 — Customer Catalogue Core

### Objective
Build the complete customer browsing experience: category dashboard, subcategory grid, item grid with tag filter, item detail, and image viewer. By the end of this phase, a customer can log in, browse the full catalogue, and view item details.

### Why This Phase Comes Now
The catalogue is the most-visible customer-facing feature. It also exercises:
- Per-category lazy loading (the `FutureProvider.family` pattern)
- Tag-based client-side filtering
- Image rendering with watermark overlay
- The category/schema engine (displaying sizes, color, price based on item flags)

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 3.1 | Customer dashboard — category grid (portrait tiles, 2-per-row, cover image fallback) | `views/customer.py:159-306` | 6 |
| 3.2 | Subcategory grid (View All + per-subcategory cards) | `views/customer.py:312-429` | 4 |
| 3.3 | Item grid with tag filter (horizontal chip row, client-side filter) | `views/customer.py:532-650` | 8 |
| 3.4 | Item detail view (image, info card, color dropdown, +/- steppers, summary card, sticky CTA) | `views/customer.py:735-1099` | 10 |
| 3.5 | Item image viewer (full-screen, `InteractiveViewer`, close button) | `views/customer.py:1106-1156` | 2 |
| 3.6 | Watermark overlay widget | `views/customer.py:435-449` | 1 |
| 3.7 | Connectivity banner widget | `utils.py:171-185` | 1 |
| 3.8 | Search results screen | `views/customer.py:657-729`, `db.py:469-487` | 4 |
| 3.9 | Offline-empty-state helper widget | `views/customer.py:108-123` | 1 |

### Dependencies
- Phase 1 (ItemRepository, CategoryRepository, image pipeline)
- Phase 2 (navigation, auth)

### High-Risk Areas
- **Tag filter.** Flet's `_rebuild_items()` replaces the entire items list in-place. Flutter's `ListView.builder` with `filteredItems` computed list is simpler but must handle empty state correctly.
- **Item detail steppers.** The +/- stepper per size (5 steppers for Chuda) with live summary recalculation. The `QtyStepper` class in Flet uses closures — Dart widgets use `StatefulWidget` with local state.
- **Per-category cache.** Flet's `customer_category_cache` dict caches items per category. Riverpod's `FutureProvider.family((ref, String category) => ...)` handles this natively — but must also cache on success and return cached on failure (for offline fallback).

### Suggested Implementation Order
1. Category grid (simplest UI, exercises FutureProvider.family)
2. Item grid without tags (basic list from provider)
3. Tag filter (add chip row + filtered list)
4. Item detail (complex but self-contained)
5. Image viewer (depends on detail)
6. Subcategory grid (depends on category grid + category repo)
7. Search (independent)
8. Connectivity banner (independent)
9. Watermark overlay (add to all image displays)

### Testing Strategy
- Widget tests for each screen with mock repository data
- Gold test for item card rendering (portrait layout, price, button)
- Integration test: category tap → items load → item detail → back navigation
- Manual test on device: verify images load, tags filter, detail renders correctly

### Exit Criteria (CP-2)
- [ ] Category grid loads from Supabase, displays correctly
- [ ] Tapping category with subcategories → subcategory grid
- [ ] Tapping category without subcategories → item grid
- [ ] Tag chips display and filter items client-side
- [ ] Item detail shows image, info, steppers, summary
- [ ] Add-to-cart not yet required (placeholder button OK)
- [ ] Search returns results from Supabase
- [ ] Watermark displays on all product images
- [ ] Connectivity banner shows/hides based on connectivity provider

### Estimated Complexity
**Medium.** Multiple screens with real data binding. The item detail stepper logic is the most complex UI element.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_shared` (new providers, shared widgets)

---

## PHASE 4 — Customer Order Flow

### Objective
Complete the customer purchasing journey: cart, place order, my orders. By the end of this phase, a customer can browse → add to cart → place order → view order history.

### Why This Phase Comes Now
This completes the customer APK's primary business value. It also validates:
- The `OrderRepository.createOrder()` with nested items
- The cart provider (`StateNotifier`)
- The order history query with joined items
- End-to-end flow from UI to Supabase and back

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 4.1 | Customer cart (list, remove, total, place order, empty state) | `views/customer.py:1159-1240` | 6 |
| 4.2 | Place order (`createOrder()` with header + line items) | `views/customer.py:1210-1225`, `db.py:644-690` | 4 |
| 4.3 | My Orders screen (order list by customer, expandable detail, status badges) | `views/customer.py:1247-1391` | 6 |
| 4.4 | "Add Again" from past orders (re-add or navigate to detail) | `views/customer.py:1308-1327` | 3 |
| 4.5 | Cart badge on AppBar (item count badge on cart icon) | `main.py:986-994` | 1 |

### Dependencies
- Phase 2 (navigation, auth — customer_id must be available)
- Phase 3 (item detail — Add Again navigates here)
- Phase 1 (OrderRepository with createOrder)

### High-Risk Areas
- **`createOrder()` reliability.** Flet had bugs where the order header was created but items were missing (BUG-028). The Flutter version must either use a Supabase transaction or verify both inserts succeeded, rolling back on failure.
- **Cart provider design.** StateNotifier with add/remove/clear/placeOrder methods. Must handle: empty state, duplicate item handling (Flet allows duplicates), quantity updates.
- **My Orders "Add Again" logic.** Complex conditional: check item availability, if simple → add directly with qty=1, if sized/colored → navigate to item detail. Must preserve exact behavior.

### Suggested Implementation Order
1. Cart provider (StateNotifier — test in isolation)
2. Cart screen UI (list + total + buttons)
3. "Place Order" wiring (connect cart provider → OrderRepository)
4. My Orders screen (read-only order history)
5. "Add Again" (connects order history → cart/item detail)
6. Cart badge on AppBar

### Testing Strategy
- Unit tests for cart provider (add, remove, clear, total calculation)
- Widget test for cart screen (empty state, items list, total display)
- Integration test: add item → cart → place order → verify in Supabase
- Manual test: full flow on Android APK

### Exit Criteria (CP-3)
- [ ] Add to Cart from item detail adds item to cart
- [ ] Cart screen shows all items with correct totals
- [ ] Remove item from cart works
- [ ] Place Order creates order in Supabase with correct items
- [ ] Order appears in My Orders
- [ ] "Add Again" re-creates cart item or navigates to detail
- [ ] Cart badge updates correctly
- [ ] Logout clears cart

### Estimated Complexity
**Medium.** The provider design is straightforward. Risk is in the createOrder transactionality.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_shared` (cart provider, order provider)

---

## PHASE 5 — Customer Advanced & Offline

### Objective
Add offline resilience to the customer app using Isar. By the end of this phase, the customer app works with cached data when offline and provides visual feedback about connectivity state.

### Why This Phase Comes Now
Online-only is acceptable for V1, but offline is a hard requirement for production reliability (Indian mobile networks are unreliable). Isar integration is risky (new architecture) so it gets its own phase for focused testing.

### Features Included
| # | Feature | Source | Est. Hours |
|---|---------|--------|------------|
| 5.1 | Isar schema for `Item`, `Category`, `Order` collections | `cache.py` (conceptual) | 4 |
| 5.2 | Isar repository wrapper (read from Isar, fallback to Supabase, write-through on fetch) | `cache.py:209-264` | 6 |
| 5.3 | Offline catalogue: categories + items load from Isar when offline | `cache.py:209-253` | 4 |
| 5.4 | Offline order history: past orders load from Isar when offline | `cache.py:255-264` | 3 |
| 5.5 | Connectivity-aware providers (switch between online/offline data sources) | `db.py:52-57` | 4 |
| 5.6 | Image caching (download to local storage, serve from cache) | `cache.py:38-40, 127-161` | 3 |

### Dependencies
- Phase 3 + 4 (customer catalogue + order flow — these define what needs offline support)

### High-Risk Areas
- **Isar + web incompatibility.** Isar does not support web. Phase 5 is APK-only. Web offline must use Drift/SQLite WASM in Phase 9.
- **Cache invalidation.** When does cached data become stale? Flet used a manual "Sync Now" button. Flutter should auto-sync on app foreground with a freshness TTL.
- **Image caching strategy.** Downloading all product images (~500 items × ~200KB = ~100MB) is impractical. Only cache images that the user has viewed.

### Suggested Implementation Order
1. Isar schema + initialization
2. Isar repository for Items (read from Isar on fetch failure)
3. Isar repository for Categories
4. Isar repository for Orders
5. Connectivity-aware provider (switch logic: try Supabase → fallback to Isar)
6. Image caching (lazy: download on first view, serve from cache on subsequent)
7. Wire up: catalogue + order screens use new providers

### Testing Strategy
- Unit test Isar read/write cycle
- Integration test: go offline → browse catalogue (loads from Isar)
- Integration test: go offline → My Orders (loads from Isar)
- Manual test: airplane mode → launch app → browse → place order → fail gracefully

### Exit Criteria
- [ ] Catalogue loads from Isar when Supabase is unreachable
- [ ] Orders load from Isar when Supabase is unreachable
- [ ] Image loads from local cache when previously viewed
- [ ] Online → offline transition shows connectivity banner
- [ ] Offline → online transition recovers gracefully (no duplicate data)

### Estimated Complexity
**Medium-High.** Isar is a new dependency with learning curve. Cache invalidation strategy requires careful design.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_shared`

---

## PHASE 6 — Admin Order Management

### Objective
Build the admin order management system: dashboard, order creation (single + mixed), order detail, karigar slip, status management. By the end of this phase, the admin can manage the full order lifecycle.

### Why This Phase Comes Now
Admin order management is the business's daily operational tool. It should be online before admin catalogue management (Phase 7) because:
- Order management is higher frequency than catalogue management
- It validates the OrderRepository with complex write patterns
- It reuses customer phase learnings (navigation patterns, provider architecture)

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 6.1 | Admin dashboard — order cards, status badges, production summary, FAB | `views/home.py:10-354` | 8 |
| 6.2 | Order status management (confirm/cancel/complete) | `views/home.py:190-210`, `db.py:771-777` | 3 |
| 6.3 | Delete order (with confirmation dialog) | `views/home.py:150-188`, `db.py:986-988` | 2 |
| 6.4 | Order type picker (single vs mixed) | `views/orders.py:12-88` | 2 |
| 6.5 | Single-category order form (item dropdown, category fields, live summary, sticky save) | `views/orders.py:170-721` | 16 |
| 6.6 | Mixed-category order form (per-row category picker) | `views/orders.py:407-536` | 6 |
| 6.7 | Order detail (category-grouped items, production pills, total qty + amount) | `views/orders.py:727-1075` | 8 |
| 6.8 | Edit order (load existing into form) | `views/orders.py:1034-1052`, `db.py:694-728` | 4 |
| 6.9 | Karigar slip view (bilingual card layout) | `views/orders.py:1081-1328` | 6 |
| 6.10 | Karigar slip PDF generation + WhatsApp share | `slip_pdf_generator.py`, `db.py:194-228` | 10 |
| 6.11 | Order list background refresh | `views/home.py:306-324` | 2 |
| 6.12 | Admin bottom navigation bar (5 tabs) | `main.py:708-736` | 3 |

### Dependencies
- Phase 1 (OrderRepository, ItemRepository, CategoryRepository, pure functions)
- Phase 2 patterns (GoRouter shell structure, theme) — adapted for admin app
- Phase 3 patterns (category-aware UI) — adapted for order form

### High-Risk Areas
- **Order form dynamic schema engine (EXTREME).** The `build_category_fields()` in Flet is ~130 lines of conditional UI logic. Porting this as a Flutter widget that correctly renders sized/colored/custom items is the single highest-risk UI migration. Must handle: Chuda (5 sizes + color + grind + box), Kaleera (qty + color), Raw_Material (sub_category + qty + unit), Metal_Bangles (5 sizes + color), Seasonal (qty + notes), and dynamic categories (use item flags).
- **Mixed mode category picker dialog.** Flet uses an AlertDialog with category cards. Flutter `showDialog()` with similar content.
- **PDF generation + WhatsApp share.** Multi-step workflow with error handling at each step. See [B. High-Risk Migrations](#b-highest-risk-migrations).

### Suggested Implementation Order
1. Admin GoRouter shell + bottom nav (5 tabs with placeholders)
2. Admin dashboard — order list (read-only)
3. Order type picker + category picker (simple navigation screens)
4. Order form — single category (the most complex — iterate on this)
5. Order form — mixed category (reuses single-category infrastructure)
6. Order detail (read-only, grouped by category)
7. Edit order (reuses order form in edit mode)
8. Status management (confirm/cancel/complete on dashboard + detail)
9. Karigar slip view (static content screen)
10. PDF generation + WhatsApp share (multi-step workflow)

### Testing Strategy
- Widget test for order form: add item, verify category fields render correctly, verify validation errors
- Widget test for order detail: verify category grouping, verify production pills
- Integration test: create order (single category) → verify in Supabase → load detail
- Integration test: create order (mixed) → verify items from multiple categories
- Manual test: full admin flow on Android (create → confirm → slip → share)

### Exit Criteria (CP-4)
- [ ] Dashboard loads orders with correct status badges
- [ ] Creating a single-category order saves correctly to Supabase
- [ ] Creating a mixed-category order saves correctly with items from multiple categories
- [ ] Category-specific fields render correctly for all 5 category types
- [ ] Edit order loads existing data and saves updates
- [ ] Order detail groups items by category
- [ ] Status management (confirm/cancel/complete) updates Supabase
- [ ] Karigar slip renders bilingual content
- [ ] WhatsApp share generates PDF, uploads to Supabase, opens WhatsApp

### Estimated Complexity
**Very High.** This is the most complex phase. The order form alone is ~600 lines of Flet code.

### Affected Projects
- `mahalaxmi_admin` (new project)
- `mahalaxmi_shared` (shared widgets for order cards, category fields)

---

## PHASE 7 — Admin Item & Costing Systems

### Objective
Build the admin catalogue management system: add/edit items, catalogue CRUD, costing system. By the end of this phase, the admin can manage the full product catalogue.

### Why This Phase Comes Now
Catalogue management is less frequent than order management but is a prerequisite for the customer catalogue to function. Without admin catalogue management, no new items can be added.

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 7.1 | Add Item form (item#, category/subcategory, tags, image upload, switches) | `views/pricing.py:10-393` | 12 |
| 7.2 | Product catalogue (CRUD: view, edit, hide/show, delete) | `views/pricing.py:396-561` | 10 |
| 7.3 | Image upload to Supabase Storage (pick → resize → upload → save URL) | `views/pricing.py:21-51`, `db.py:147-191` | 4 |
| 7.4 | Item edit (navigate from catalogue → pre-filled Add Item form) | `views/pricing.py:267-272` | 2 |
| 7.5 | Item visibility toggle (hide/show from customers) | `views/pricing.py:504-518`, `db.py:622-625` | 2 |
| 7.6 | Costing list (searchable, cost-status badges) | `views/pricing.py:568-666` | 4 |
| 7.7 | Costing detail (material rows, margin, SP preview, save) | `views/pricing.py:668-910` | 10 |

### Dependencies
- Phase 1 (ItemRepository, MaterialRepository, ImageService)
- Phase 6 (admin navigation shell)

### High-Risk Areas
- **Costing detail material rows.** Dynamic add/remove with live recalculation across master-listed and custom materials. The save saves to 2 tables (`item_materials` + `rate_list`). See [B. High-Risk Migrations](#b-high-risk-migrations).
- **Image upload flow.** FilePicker → resize → upload → save URL. Error at any step must show user-friendly message and NOT save partial data (BUG-029).
- **5-step save in Add Item.** Flet's `on_save_and_generate()` checks each of 5 DB writes and aborts on first failure. Flutter must replicate this sequential-check pattern.

### Suggested Implementation Order
1. Add Item form — basic fields (no tags, no image)
2. Add Item form — tags (reuse tag provider from shared)
3. Add Item form — image upload (integrate ImageService)
4. Product catalogue — read-only list
5. Product catalogue — edit (reuses Add Item form)
6. Product catalogue — hide/show toggle
7. Product catalogue — delete with confirmation
8. Costing list — searchable
9. Costing detail — material rows + margin + SP preview + save

### Testing Strategy
- Widget test for Add Item form: verify all fields render, verify category/subcategory cascade
- Integration test: create item with image → verify in Supabase Storage → verify rate_list row
- Integration test: edit item → verify update
- Integration test: toggle visibility → verify customer catalogue changes
- Integration test: full costing flow (add materials → set margin → save → verify DB)

### Exit Criteria (CP-5)
- [ ] Add Item creates item in Supabase with all fields
- [ ] Image uploads to Supabase Storage and URL saves to rate_list
- [ ] Tags associate with item correctly
- [ ] Product catalogue lists all items with correct status
- [ ] Edit item pre-fills form and saves updates
- [ ] Hide/Show toggle updates `is_available` correctly
- [ ] Delete item removes from Supabase
- [ ] Costing list shows correct status badges
- [ ] Costing detail: material rows add/remove, margin calculates, save persists

### Estimated Complexity
**High.** Costing detail is complex. Image pipeline must be pixel-perfect.

### Affected Projects
- `mahalaxmi_admin`
- `mahalaxmi_shared`

---

## PHASE 8 — Admin Settings & Labour

### Objective
Complete the admin app with all settings screens and the labour production checklist. By the end of this phase, the admin APK is feature-complete with the legacy Flet app.

### Why This Phase Comes Now
Settings and labour are independent of the order/catalogue flows. They can be built in any order after Phase 6/7. Putting them last minimizes disruption to core workflow development.

### Features Included
| # | Feature | Flet Source | Est. Hours |
|---|---------|-------------|------------|
| 8.1 | Settings menu (list tiles for all settings) | `views/settings.py:10-87` | 1 |
| 8.2 | Manage Categories (add/edit/delete, cover image, activate/deactivate) | `views/settings.py:223-487` | 8 |
| 8.3 | Default Margin setting | `views/settings.py:92-135` | 1 |
| 8.4 | Material Master CRUD | `views/settings.py:138-221` | 3 |
| 8.5 | Tag Master (add/edit/delete, multi-category chips, delete safety) | `views/settings.py:584-910` | 8 |
| 8.6 | Manage Customers (add/edit/block, PIN generation, search) | `views/customers.py:1-246` | 8 |
| 8.7 | Archive Orders (completed/cancelled list, read-only) | `views/archive.py:1-104` | 3 |
| 8.8 | Labour dashboard (order cards without prices) | `views/home.py:10-354` (role-gated) | 2 |
| 8.9 | Production checklist (image-first cards, per-size status toggle, progress) | `views/labour.py:1-247` | 6 |

### Dependencies
- Phase 1 (CustomerRepository, TagRepository, MaterialRepository, ItemRepository)
- Phase 6 (order list infrastructure for labour dashboard, order detail for checklist)

### High-Risk Areas
- **Tag Master multi-category chip UI.** Flet had BUG-031 with chip visuals not updating. Flutter must ensure chip selection/deselection updates immediately.
- **Customer PIN generation.** Must generate unique 8-digit PIN with collision retry. PIN is permanent — no change UI. Admin must be able to copy PIN to clipboard.
- **Delete safety checks.** Category and tag deletion must check for references first. Flet's `delete_category()` queries `rate_list` for items. `delete_tag()` checks `tags` JSONB contains.

### Suggested Implementation Order
1. Settings menu (simple list — instant gratification)
2. Material Master CRUD (simplest settings screen)
3. Default Margin setting (simplest form)
4. Manage Categories (medium complexity)
5. Manage Customers (medium complexity)
6. Archive Orders (read-only, simple)
7. Tag Master (highest complexity settings screen)
8. Labour dashboard (reuses order list, hides prices)
9. Production checklist (dedicated complex screen)

### Testing Strategy
- Integration test for each settings screen: create/read/update/delete cycle against Supabase
- Integration test: create category → verify it appears in order form category picker
- Integration test: create tag → verify it appears in Add Item form for correct categories
- Integration test: delete category with items → verify refusal
- Integration test: delete tag with item references → verify refusal
- Manual test: full production checklist flow (toggle statuses, verify progress, verify Supabase)

### Exit Criteria (CP-6)
- [ ] All 6 settings screens functional (categories, margin, materials, tags, customers, archive)
- [ ] Category CRUD works with optional cover image upload
- [ ] Category deletion refused if items reference it
- [ ] Tag Master: add/edit/delete works, multi-category chip selector functional
- [ ] Tag deletion refused if items reference it
- [ ] Customer management: add with PIN, edit, block/unblock, search, copy PIN
- [ ] Labour dashboard shows orders without prices
- [ ] Production checklist: per-size status toggle updates Supabase immediately
- [ ] Production progress bar updates correctly

### Estimated Complexity
**Medium.** Mostly standard CRUD screens. Tag Master and Production Checklist have the most UI complexity.

### Affected Projects
- `mahalaxmi_admin`
- `mahalaxmi_shared`

---

## PHASE 9 — Customer Web / PWA

### Objective
Deploy the customer app as a web/PWA. By the end of this phase, the customer web app is feature-complete and deployable for beta testing.

### Why This Phase Comes Now
Web distribution reaches customers who cannot or will not install an APK. It also validates:
- The shared package is web-safe (no `dart:io`)
- The customer app works under web constraints (no Isar, no `share_plus`, different image rendering)

### Features Included
| # | Feature | Notes | Est. Hours |
|---|---------|-------|------------|
| 9.1 | Web-safe renderer selection (html vs canvaskit) | Test both on target browsers | 2 |
| 9.2 | Replace Isar with Drift (SQLite WASM) or localStorage for web offline | Isar incompatible with web | 6 |
| 9.3 | Replace `share_plus` with clipboard + `url_launcher` fallback | share_plus is mobile-only | 2 |
| 9.4 | Replace `dart:io` usage with `universal_io` in shared package | Audit and fix | 3 |
| 9.5 | PWA manifest + service worker | Offline shell | 3 |
| 9.6 | iPhone testing (Safari compatibility) | Canvaskit vs HTML renderer | 4 |
| 9.7 | Image lazy loading and responsive images | Web bandwidth considerations | 3 |

### Dependencies
- Phase 3 + 4 + 5 (complete customer app)

### High-Risk Areas
- **Offline on web.** No Isar. Options: Drift with SQLite WASM (experimental), or simple localStorage/cache API. This may require a different offline strategy than the APK.
- **Image rendering.** `Image.network()` with `fit: BoxFit.cover` may look different in Safari vs Chrome. The canvaskit renderer is heavier but more consistent.
- **Platform-specific provider swapping.** The app must use IsarProvider for APK and DriftProvider for web. This requires dependency injection at app startup.

### Suggested Implementation Order
1. Audit all shared package code for `dart:io` usage — replace with `universal_io`
2. Audit all customer app code for mobile-only plugins (`share_plus`, etc.) — add platform guards
3. Set up web entry point with HTML renderer
4. Test all customer screens in Chrome
5. Fix web-specific rendering issues
6. Set up PWA manifest + service worker
7. Test in Safari (iPhone simulator or real device)
8. Switch to canvaskit renderer if HTML has issues
9. Implement web offline (localStorage or Drift WASM)

### Testing Strategy
- Run all shared package unit tests on web (dart compile fails if dart:io present)
- Manual testing in Chrome, Safari, and Chrome Android
- Lighthouse audit for PWA readiness
- Network throttling test for slow connections

### Exit Criteria (CP-7)
- [ ] Customer app renders correctly in Chrome and Safari
- [ ] All customer features work on web (login, catalogue, cart, order)
- [ ] Images load and display correctly (no broken layout)
- [ ] "Add to Cart" and "Place Order" work on web
- [ ] Offline (service worker) serves cached shell
- [ ] PWA passes Lighthouse audit
- [ ] No runtime errors in browser console

### Estimated Complexity
**Medium.** Mostly compatibility fixes. Major risk is web offline requiring different architecture than APK offline.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_shared`

---

## PHASE 10 — Production Hardening & Polish

### Objective
Production-launch quality: security, monitoring, CI/CD, performance. By the end of this phase, both apps are deployable to production users.

### Why This Phase Comes Now
All feature parity is achieved in Phases 1–9. Phase 10 is the safety net before real users touch the app.

### Features Included
| # | Feature | Est. Hours |
|---|---------|------------|
| 10.1 | Supabase RLS policies design + testing + enable | 8 |
| 10.2 | Error monitoring (Sentry or Firebase Crashlytics) | 4 |
| 10.3 | CI/CD: GitHub Actions builds for both APKs (debug + release) | 6 |
| 10.4 | APK signing configuration (release keystore) | 2 |
| 10.5 | Performance profiling (Flutter DevTools profile mode) | 4 |
| 10.6 | Web Lighthouse audit + performance optimization | 4 |
| 10.7 | App icon + splash screen for both apps | 3 |
| 10.8 | Security audit: API keys, storage, session handling | 4 |
| 10.9 | Deferred features: push notifications, workmanager, background sync | 10 |

### Dependencies
- All previous phases

### Exit Criteria (CP-8)
- [ ] RLS enabled and verified (customer can only read own orders, admin can read all)
- [ ] Error monitoring active for both apps
- [ ] CI builds both APKs on every push to main
- [ ] APK signing configured with release keystore
- [ ] No performance bottlenecks in profile mode (< 60fps, < 200ms frame build)
- [ ] Web passes Lighthouse with ≥ 80 in all categories
- [ ] App icons and splash screens for both apps
- [ ] Security audit passed (no exposed keys, no insecure storage)

### Estimated Complexity
**Medium.** Wide scope but each item is independently achievable.

### Affected Projects
- `mahalaxmi_customer`
- `mahalaxmi_admin`
- `mahalaxmi_shared`

---

## Dependency Graph

```
Phase 1: Shared Foundation
  ├──> Phase 2: Customer Auth & Nav
  │     ├──> Phase 3: Customer Catalogue Core
  │     │     ├──> Phase 4: Customer Order Flow
  │     │     │     └──> Phase 5: Customer Offline
  │     │     └──> Phase 9: Customer Web (can start after Phase 4)
  │     └──> Phase 6: Admin Order Management
  │           ├──> Phase 7: Admin Item & Costing
  │           │     └──> Phase 8: Admin Settings & Labour
  │           └──> Phase 8 (labour dashboard)
  └──> Phase 10: Production Hardening (after all phases)
```

**Parallel-safe paths:**
- Phase 9 (Customer Web) can proceed after Phase 4, independently of Phases 6–8
- Phase 8 (Admin Settings) can proceed after Phase 6, independently of Phase 7

**Absolute ordering constraints:**
1. Phase 1 before everything
2. Phase 2 before Phase 3
3. Phase 3 before Phase 4
4. Phase 4 before Phase 5
5. Phase 6 before Phase 8 (labour dashboard needs order list)
6. Phase 10 after everything

---

## Summary

| Phase | Name | Est. Hours | Risk | Customer | Admin | Shared | Web |
|-------|------|------------|------|----------|-------|--------|-----|
| 1 | Shared Foundation | 48 | Low-Med | — | — | ✅ | — |
| 2 | Customer Auth & Nav | 23 | Low-Med | ✅ | — | — | — |
| 3 | Customer Catalogue Core | 37 | Medium | ✅ | — | — | — |
| 4 | Customer Order Flow | 20 | Medium | ✅ | — | — | — |
| 5 | Customer Advanced & Offline | 24 | Med-High | ✅ | — | ✅ | — |
| 6 | Admin Order Management | 70 | Very High | — | ✅ | — | — |
| 7 | Admin Item & Costing | 44 | High | — | ✅ | — | — |
| 8 | Admin Settings & Labour | 40 | Medium | — | ✅ | — | — |
| 9 | Customer Web / PWA | 23 | Medium | ✅ | — | ✅ | ✅ |
| 10 | Production Hardening | 45 | Medium | ✅ | ✅ | ✅ | ✅ |
| | **Total** | **374** | | | | | |

**Total estimated effort: ~374 hours (~47 working days for a solo developer)**

Key ratios:
- Shared package: 48h (13%)
- Customer app: 104h (28%)
- Admin app: 154h (41%)
- Web: 23h (6%)
- Production hardening: 45h (12%)
