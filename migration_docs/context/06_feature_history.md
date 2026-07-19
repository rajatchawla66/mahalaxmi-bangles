# 06 — Feature History

## Phase 1 — Initial Migration (Flet → Flutter)

- Core customer app: PIN login, catalogue, cart, orders
- Admin app: dashboard, order management, basic catalogue
- Shared package: models, repositories, providers
- PDF order generation

## Image & UI Overhaul

- Uniform 4:5 image policy (1080×1350 px, JPEG Q90)
- 3:4 category covers (900×1200 px, JPEG Q87)
- Admin cropping UI (`crop_your_image`)
- Customer one-column product feed (replaced two-column grid)
- `CachedNetworkImage` for all customer images
- Watermark overlay on product images
- Full-screen image viewer

## Admin Catalogue Refinement

### Catalogue Polish
- Tag chip selector (replaced text input)
- Add new item flow
- Default margin auto-calculation
- Cost/price indicators (loss badge, margin badge)
- Sorting (Item/Price/Cost, ↑↓)
- Search + availability filter
- Inactive category badge
- Price=0 warnings
- Item deletion
- Missing price items page

### WhatsApp Photo Share
- Multi-select → sequential JPG generation → share via `share_plus`
- 1080×1350 layout with item number + price

## Category Features

- Admin-controlled sort order (Move Up/Down)
- Category-level size chart (admin-configurable via chips)
- Item-level available sizes

## Chuda Customisation (Phases 2–6)

- Phase 2: Cart price bug fix (base + customization total)
- Phase 3: Order pipeline, display (admin + customer), PDF output, repeat order
- Phase 4: Admin create order customization
- Phase 5: Collapsible customization UI, quantity above customization
- Phase 6: First-open default selection bug fix (async provider await)

## Order System

- Archive orders screen (tabbed: All/Completed/Cancelled)
- Soft-delete archived orders (completed/cancelled only)
- Danger Zone with graduated confirmation (simple confirm + typed `DELETE`)

## Cart Persistence

- `CartItem.toJson/fromJson` + `CartPersistenceService` (SharedPreferences)
- Per-customer keys, auto-save on mutation, clear on successful order

## Session & Auth

- `SharedPreferencesSessionStorage` replaced `InMemorySessionStorage`
- Session restore on cold start (both customer + admin apps)
- Customer deactivation force-logout (session restore, app resume, pre-order)
- `forcedLogoutReasonProvider` for disabled-account messages
- Router broad-guard for all protected routes

## Login Screen Redesign

- Business info header (name, tagline, GST, address)
- In-app numeric keypad (replaced mobile keyboard)
- Contact cards (Instagram, WhatsApp, Maps) with `url_launcher`
- Secure & Trusted label
- Heritage text block
- Web-safe exit confirmation

## Error Handling

- `CustomerErrorMessages` — centralized exception-to-friendly-message mapping
- 7 raw exception leakage points fixed in customer UI

## Customer Polish

- Confirm-exit dialog on dashboard (PopScope)
- Compact tag filter row spacing
- Stale tag filter reset on category switch
- Empty filter pull-to-refresh fix

## Cutmail / Stock Check (Phase 1)

- Labour app created from scratch
- Cutmail creation flow (category → item → size-wise qty → submit)
- Admin cutmail list (Pending/Reviewed/Archived/All) + detail/edit
- Not linked to customer orders

## Admin — Session Persistence & Router

- Admin app session restore (matching customer pattern)
- Router root redirect fix (no route for `/`)

## Order Items Integer Cast

- Fixed native crash: quantity `1.0` (double) → `1` (int) for PostgreSQL `integer` column

## Admin Dashboard Phase 1 Redesign — 2026-07-05

- Dashboard redesigned from orders-only summary to full business overview
- 6 sections: Quick Actions, Main Summary Cards, Needs Attention, Recent Orders (5), Latest Cutmail (5), Catalogue Health
- New `adminDashboardDataProvider` combines 6 existing providers in parallel
- No schema changes or new repository methods
- Phase 2: server-side count queries if performance becomes an issue

## APK & Web Build

- `flutter build apk --release --split-per-abi`
- Gradle-direct rebuild (`.\gradlew assembleRelease`)
- `flutter build web --release`
- Adaptive icon + native splash screen (Android)

## Admin Web Support (2026-07-06)

- Admin app enabled for Flutter Web (same codebase as Android)
- Web blockers fixed: `dart:io` in share service, `SystemNavigator.pop()`, share file handling
- `share_photo_service.dart` rewritten to use `Uint8List` + `share_plus` (cross-platform)
- Web manifest and index.html updated with admin branding
- Planned URL: `https://admin.mahalaxmibangles.com`
- Build: `flutter build web --release --dart-define-from-file=.env` → `build/web/`
- All features work on web: login, dashboard, orders, catalogue, customers, settings, cutmail, image picker, PDF
