# EXPECTED FLUTTER FEATURES — Feature-Parity Checklist

> **Source:** Flet v1 (`legacy_flet_app/`)
> **Target:** Flutter (Dart) — `mahalaxmi_customer/`, `mahalaxmi_admin/`, `mahalaxmi_shared/`
> **Database:** Supabase (unchanged schema — see §Migration-Critical Business Rules)
> **Date:** 2026-06-13

---

## Contents

1. [Customer App Features](#1-customer-app-features)
2. [Admin App Features](#2-admin-app-features)
3. [Labour Features](#3-labour-features)
4. [Shared / Library Features](#4-shared--library-features)
5. [Flet-Only Workarounds — DO NOT COPY](#5-flet-only-workarounds--do-not-copy)
6. [Postponed Items (Stay Postponed)](#6-postponed-items-stay-postponed)
7. [Migration-Critical Business Rules](#7-migration-critical-business-rules)
8. [Supabase Schema Assumptions — DO NOT CHANGE](#8-supabase-schema-assumptions--do-not-change)
9. [Feature Totals & Status](#9-feature-totals--status)

---

## 1. Customer App Features

Target APK: `mahalaxmi_customer` (APK + Web/PWA)

| # | Feature | Flet Status | Flutter Requirement | Priority | Source File(s) | Migration Notes | Acceptance Test |
|---|---------|-------------|---------------------|----------|----------------|-----------------|-----------------|
| 1.1 | **Premium Brand Landing Page** | ✅ Working — Cream bg, gold accents, maroon CTA, logo, GST row, ornamental dividers, 2×2 contact cards (Instagram/WhatsApp/Location/YouTube coming-soon), heritage container, Admin/Labour text links | Rebuild as Flutter widget with same visual hierarchy. Use `url_launcher` for WhatsApp/Instagram/Location. YouTube card shows "Coming Soon". | Must-have | `views/auth.py:18-349` | Logo uses `assets/watermark.png`. Contact URLs are hardcoded. GST number `08AHPPC2086C1ZI` is static. | Landing page matches Flet pixel-for-pixel on 360px–420px screen. All 4 contact cards open correct URLs. |
| 1.2 | **Customer PIN Login** | ✅ Working — 8-digit PIN entry, validation, `get_customer_by_pin()` lookup, blocked-account check, session save, `set_customer_last_active()` | Same flow in Flutter. Use `supabase.from("customers").select().eq("pin", pin).single()`. | Must-have | `views/auth.py:45-95`, `views/customer.py:12-102`, `db.py:1029-1031` | Session save maps to `shared_preferences` or `flutter_secure_storage`. The "blocked" check uses `is_active` column. | Correct PIN → dashboard. Wrong PIN → error. Blocked account → "blocked" message. Network error → user-friendly message. |
| 1.3 | **Customer Dashboard — Category Grid** | ✅ Working — Portrait tiles (3:4 ratio, 2-per-row), cover image fallback (cover → initial letter monogram on gradient), gradient overlay, category name text | Use `GridView.count(crossAxisCount: 2)` with `AspectRatio(3/4)`. Container with `BoxDecoration` gradient + `Stack` for overlay + text. | Must-have | `views/customer.py:159-306` | Tile width derived from screen width: `(sw - 32 - 12) / 2`. Categories loaded from Supabase with `active_only=true`. | Tiles render 2-per-row. Cover images display. Categories without covers show gradient + initial. Tap navigates to items (or subcategories). |
| 1.4 | **Subcategory Grid** | ✅ Working — "View All" option + per-subcategory cards (cover image, gradient overlay, item count) | Single screen with "All" header row + `GridView` of subcategories. Impages show cover from first item in subcategory. | Must-have | `views/customer.py:312-429` | Subcategories parsed from `categories.sub_categories` (comma-separated string). Items lazy-loaded via per-category cache. | Tapping a subcategory filters items. "View All" shows all items in category. |
| 1.5 | **Customer Item Grid** | ✅ Working — Portrait cards (350px hero image, watermark overlay, item code, green price, "View" button), horizontally scrollable tag filter row, client-side filtering | `CustomScrollView` with `SliverToBoxAdapter` for tags + `SliverGrid` or `SliverList` for items. Tag row = `ListView.builder(scrollDirection: horizontal)`. | Must-have | `views/customer.py:532-650` | Tags extracted from loaded items' `tags` JSONB. Filter is local (no DB call). Factory functions in Flet avoid closure bugs — Dart closures don't have this issue. | Items display in portrait cards. Tag chips filter locally. "All" resets filter. Empty state shown when no items match. |
| 1.6 | **Item Detail View** | ✅ Working — Premium B2B layout: 400px rounded image (tap-to-zoom), product info card (item#, badge, price), color dropdown, +/- quantity stepper rows (one per size or single Qty), live order summary card, sticky bottom CTA bar | Rebuild as single scrollable widget + sticky bottom `SafeArea` with "Add to Cart" button. Use `InteractiveViewer` for zoom (already planned). | Must-have | `views/customer.py:735-1099` | Sizes = 5 steppers for Chuda/Metal_Bangles items (`has_sizes=true`). Non-sized = single Qty stepper. Watermark overlay on image. Summary card updates live. | Image displays. All sizes render if `has_sizes=true`. Steppers increment/decrement. Summary updates live. "Add to Cart" adds item to cart and navigates back. |
| 1.7 | **Item Image Viewer** | ✅ Working — Full-screen black bg, `InteractiveViewer` (pinch zoom 1×–5×), watermark overlay, close button top-right | Simple `InteractiveViewer` in full-screen `Scaffold` with black background. Close button via `Navigator.pop`. | Should-have | `views/customer.py:1106-1156` | Flet code has `InteractiveViewer` fallback if not available. Flutter `InteractiveViewer` is stable. | Image loads full-screen. Pinch-to-zoom works. Close returns to detail. |
| 1.8 | **Customer Cart** | ✅ Working — Item list with remove, total amount, "Place Order" + "Add More Items" buttons. Empty state with "Browse Catalogue" redirect. | Standard Flutter cart screen. `ListView` with `Dismissible` or trailing delete icon. | Must-have | `views/customer.py:1159-1240` | Cart stored in state/cubit (not persisted — lost on app close). `db.create_order()` handles both header + line items. On success, cart clears, navigates to dashboard. | Empty cart → empty state with "Browse" button. Items list correctly. Total calculates. Place Order creates order in Supabase. Success snackbar shows order #. |
| 1.9 | **Customer Place Order** | ✅ Working — `create_order()` with header (customer_name, mobile, customer_id, date, total, source='customer') + line items (item_number, category, qty sizes/quantity, color, unit_price) | Same flow. Use `supabase.from("orders").insert(header)` then `supabase.from("order_items").insert(items)`. Wrap in transaction if possible. | Must-have | `views/customer.py:1210-1225`, `db.py:644-690` | Source = "customer" distinguishes from admin-created orders. `customer_id` links order to customer table. Items insert is rollback-on-failure (deletes header if items fail). | Order appears in Supabase `orders` table with correct customer_id and line items. |
| 1.10 | **Customer My Orders** | ✅ Working — Order history filtered by `customer_id`, expandable detail rows per order, "Add Again" button per item (navigates to detail or adds directly for simple items), date, status badge | `FutureBuilder` with `supabase.from("orders").select("*, order_items(*)").eq("customer_id", id).order("order_id", ascending: false)`. Expandable tiles for detail. | Must-have | `views/customer.py:1247-1391` | "Add Again" checks `is_available` and `selling_price > 0`. For sized/colored items, navigates to item detail. For simple items, adds directly to cart with qty=1. | Orders list loads. Tapping "View Details" expands per-item breakdown. "Add Again" works for both simple and complex items. |
| 1.11 | **Customer Catalogue Search** | ✅ Working — Search via `search_customer_items()`, client-side filter on item_number/category/sub_category/tags, results rendered with same `_build_item_card()` | Debounced search against Supabase (or cached items). Use same item card widget as item grid. | Should-have | `views/customer.py:657-729`, `db.py:469-487` | Flet searches all items then filters client-side. Flutter can either preload all + filter locally or use Supabase `ilike` query. Local is faster for offline. | Search with ≥3 chars shows results. Results use same card layout. Empty results shown when no match. |
| 1.12 | **Watermark Overlay** | ✅ Working — Semi-transparent watermark logo centered on product images in item cards, item detail, and image viewer | `Stack` with `Positioned.fill` + `Opacity` widget wrapping `Image.asset("watermark.png")`. Same across all image views. | Should-have | `views/customer.py:435-449` | Watermark image is at `assets/watermark.png`. Opacity = 0.30 in cards, lower in viewer. | Watermark appears on all product images. Not tappable. |

---

## 2. Admin App Features

Target APK: `mahalaxmi_admin` (APK only — no web)

| # | Feature | Flet Status | Flutter Requirement | Priority | Source File(s) | Migration Notes | Acceptance Test |
|---|---------|-------------|---------------------|----------|----------------|-----------------|-----------------|
| 2.1 | **Admin Dashboard — Order List** | ✅ Working — Order cards with status badge, category color strip, customer name, amount, production summary row, trailing popup menu (Confirm/Cancel/Delete), FAB for new order. Background refresh preserves scroll position. | `ListView.builder` with order card widgets. Pull-to-refresh. Background fetch via `workmanager` or auto-refresh timer. FAB → navigate to order type picker. | Must-have | `views/home.py:10-354` | Order cards use `ft.Container(inline=True)` for reliable tap detection in Flet — Flutter `ListTile.onTap` works natively. Production summary computed from `production_status` JSONB. | Orders load ordered by date desc. Status badges display correctly. Confirm/Cancel/Delete work via popup menu. FAB navigates to order type picker. |
| 2.2 | **Order Status Management** | ✅ Working — `set_order_status()` transitions: pending → confirmed → cancelled, confirmed → completed. Status persisted in `orders.status` column + `status_updated_at` timestamp. | Same Supabase update. Status-specific action buttons: Confirm/Cancel for pending, Mark Completed for confirmed. | Must-have | `views/home.py:190-210`, `db.py:771-777` | Status updates optimistically update local cache then DB. Flutter should do pessimistic (DB-first) or optimistic with rollback. | Confirming an order changes badge to green. Cancelling turns it red. Completed confirmed orders. |
| 2.3 | **Delete Order** | ✅ Working — Confirmation dialog → `db.delete_order()` → removes from cache + UI. Cascade deletes `order_items`. | Same. Show confirm dialog (Flutter's `showDialog` + `AlertDialog`). Call delete API. Remove from list. | Should-have | `views/home.py:150-188`, `db.py:986-988` | Delete is permanent (cascade). No soft-delete in current schema. | Delete removes order from list and DB. Order items also deleted. |
| 2.4 | **Order Type Picker** | ✅ Working — Two cards: "Single Category" (all items from one category) and "Mixed Order" (items from multiple categories). Sets `order_mode` in state. | Simple selection screen with two prominent cards. `GoRouter` navigates to category picker or order form accordingly. | Must-have | `views/orders.py:12-88` | No migration complexity. Direct port. | Both cards tappable. Selecting "Single" → category picker. "Mixed" → order form with category dropdown per row. |
| 2.5 | **Category Picker** | ✅ Working — Grid of category cards (icon, name, description, color) loaded from DB. Sets `selected_category` in state. | `GridView` with category cards from Supabase `categories` table (active only). | Must-have | `views/orders.py:94-164` | Colors/icons loaded dynamically from `categories` table (`color` + `icon` string columns mapped to Flutter constants). | Categories load from DB. Tapping a category navigates to order form pre-filtered. |
| 2.6 | **Order Form — Single Category** | ✅ Working — Customer name, date, notes fields. Item dropdown filtered by category. Per-row category fields (sizes/qty/color) based on item properties. Image thumbnail preview. Live total calculation. Summary bar (Items/Sets/Amount). Sticky bottom bar: [+ Add Item] + [Save Order]. | Complex form. Use `Form` + `StatefulWidget`. Each cart item = a card widget with category-specific controls. Summary computed from cart via `calculate_line_total()`. | Must-have | `views/orders.py:170-721` | The `build_category_fields()` function in `main.py` is the most complex UI builder — maps `has_sizes`/`has_color` flags to +/- steppers or dropdowns. `validate_order()` and `calculate_line_total()` are pure functions — extract to shared package. | Form renders. Item dropdown works. Category fields appear based on item properties. Add/Remove rows work. Save creates order in DB. |
| 2.7 | **Order Form — Mixed Category** | ✅ Working — Same as single but with category dropdown per row. Changing category resets item selection and field controls. Category picker dialog for add-item. | Same order form widget with a `DropdownButton` for category on each row. Category-change clears item + rebuilds fields. | Must-have | `views/orders.py:407-536` | Category comparison uses `.strip().lower()` to avoid whitespace bugs (BUG-021). | Category dropdown per row works. Changing category resets item selection. Fields rebuild based on selected item. |
| 2.8 | **Order Detail View — Admin** | ✅ Working — Header (order#, date, customer, notes), items grouped by category with visual cards (image thumbnail, category color header, sizes table, production status pills per size, line total). Total qty + amount. Action buttons: Edit Order, Karigar Slip. | Order detail screen. Group items by category. For each group: colored header card + item list with production status pills. | Must-have | `views/orders.py:727-1075` | Production status computed from `order_items.production_status` JSONB. The `_parse_ps()` helper handles both string and dict formats. | Order loads with correct items. Categories grouped with colored headers. Production status pills show per size. |
| 2.9 | **Order Detail View — Labour** | ✅ Working — Same as admin but text-based rendering, no prices shown. "Production Checklist" button instead of "Edit/Karigar Slip". | Same screen but conditionally hide prices. Show "Production Checklist" button for labour role. | Must-have | `views/orders.py:923-1065` | Price hiding is business rule — labour must never see prices. | Labour sees order items without prices. Labour sees "Production Checklist" button. |
| 2.10 | **Edit Order** | ✅ Working — Loads existing order into order form (cart rows = existing line items, mode = mixed). `db.update_order()` replaces all order_items (delete + reinsert). | Load existing order into same order form widget. On save, call `supabase.from("order_items").delete().eq("order_id", id)` + reinsert all items. | Must-have | `views/orders.py:1034-1052`, `db.py:694-728` | Edit mode sets `edit_order_id`, `edit_order_customer`, etc. in state. Cart is rebuilt from existing line items. | Edit loads existing data correctly. Save replaces order items. Total recalculated. |
| 2.11 | **Karigar Slip View** | ✅ Working — Mobile-printable HTML-like view: maroon/gold header, order meta (color/grind/box/notes), per-item cards (image, item#, total sets, sizes table), bilingual (Hindi/English). Share button → PDF generation → Supabase Storage upload → WhatsApp share. | Slip screen as static content card. PDF generation → `pdf` package (Dart) or server-side (Supabase Edge Function). WhatsApp share → `url_launcher` with `https://wa.me/?text=...`. | Must-have | `views/orders.py:1081-1328`, `slip_pdf_generator.py` | Flet uses `fpdf2` in Python. Flutter can use `printing` + `pdf` packages, or generate server-side. The WhatsApp share flow uploads PDF to Supabase Storage first, then shares the public URL via `url_launcher`. | Slip view shows bilingual header. Item cards display with images. Share generates PDF, uploads, opens WhatsApp with URL. |
| 2.12 | **Karigar Slip PDF Generation** | ✅ Working — Maroon/gold card layout, A4, header (business name, Karigar Slip title, order#/customer/date), per-item cards (image thumbnail, sizes table, totals), Hindi font support via `HindiFont.ttf` | Port to Dart `pdf` package. The Hindi font (`assets/fonts/HindiFont.ttf`) must be bundled. If PDF generation is too complex, defer to server-side via Supabase Edge Function. | Should-have | `slip_pdf_generator.py:1-368` | The PDF includes: watermarked image thumbnails, sizes table with horizontal layout, colour-coded headers. Port the layout algorithm exactly. | PDF matches Flet output on A4. Hindi text renders correctly. Images included. Sizes table correct. |
| 2.13 | **Add Item Form** | ✅ Working — Item number (read-only on edit), category dropdown (dynamic subs), sub-category, availability switch, has_sizes/has_color switches, tag multi-select (category-filtered), image picker → resize → Supabase upload, 5-step save with rollback | Complex form. Image picker → `image_picker` or `camera` plugin → resize in Dart (`image` package) → upload via Supabase Storage SDK. Tags: multi-select chip input. | Must-have | `views/pricing.py:10-393` | The `resize_product_image()` pipeline → Dart `Image` package: EXIF fix, 4:5 center-crop, 1080×1350, LANCZOS, sharpen, JPEG Q93. The `on_save_and_generate()` function has the most complex save logic with 5 DB writes and return-value checks — must port exactly (BUG-029). | Item number lookup works (edit mode). Category/sub-category cascading works. Image uploads to Supabase Storage. Save creates/updates item. Tags persist. |
| 2.14 | **Product Catalogue (Admin)** | ✅ Working — Card list with image thumbnails, item#/category badge/CP/SP/margin, Hide/Show toggle, Edit button, Delete button (with confirm). Background cache refresh. | `ListView.builder` with admin catalogue cards. Toggle availability via PATCH. Edit button navigates to Add Item form with pre-filled data. Delete with confirmation dialog. | Must-have | `views/pricing.py:396-561` | `state["edit_item"]` holds the item data for edit navigation. Catalogue loads from cache first, then background DB refresh replaces cache. | Items list loads. Hide/Show toggles correctly. Edit navigates to form with data. Delete removes with confirmation. |
| 2.15 | **Costing List** | ✅ Working — Searchable list of all items with cost status: "Priced (₹SP)" green badge, "No SP" amber badge, "Not costed" red badge. Tapping opens costing detail. | `SearchDelegate` or in-page search. Item cards showing cost status badge. Tap → navigate to costing detail. | Must-have | `views/pricing.py:568-666` | Status logic: `selling_price > 0` → priced, `cost_price > 0 but no SP` → amber, else → red. | List loads with correct badges. Search filters by item#/category. Tap opens costing detail. |
| 2.16 | **Costing Detail** | ✅ Working — Header (item#, category, image), materials list (dropdown for master materials + custom entries, qty/rate inputs, auto-calc line total), total cost, margin selector (default % or custom), calculated SP preview, save button. Material master + cost breakdown save. | Complex form. Dynamic list of material rows (each with name dropdown/textfield + qty + rate). Margin switch (default vs custom). `recalculateSellingPrice()` = `totalCost * (1 + margin/100)`. | Must-have | `views/pricing.py:668-910` | Materials saved to `item_materials` table (delete + reinsert). Costing saved to `rate_list` (cost_price, selling_price). Default margin from `app_settings` key `default_margin`. | Material rows addable/removable. Values calculate correctly. Custom margin overrides default. Save updates DB. |
| 2.17 | **Admin Settings** | ✅ Working — List tile menu: Manage Categories, Margin, Material Master, Tag Master, Manage Customers, Archive Orders, Logout. | `ListView` of settings categories. Each navigates to its dedicated screen. | Must-have | `views/settings.py:10-87` | Direct port. No business logic in settings menu. | All menu items navigate correctly. Logout works. |
| 2.18 | **Manage Categories** | ✅ Working — Add new category form (name, icon, color, description, sub-categories CSV, order type, cover image), category list with status badge, color-coded left border, cover image thumbnails, Activate/Deactivate toggle, Cover image upload, Delete (safety check — refuses if items reference category). | Full CRUD screen. Cover image upload to Supabase Storage `category_covers/`. Category deletion safety check verifies no items use that category. | Must-have | `views/settings.py:223-487` | Category `order_type` field controls validation behavior in order forms. Colors/icons stored as string keys mapped to Flutter constants. Sub-categories stored as comma-separated string. | Add/create/edit/delete all work. Delete safety prevents orphan items. Cover image uploads correctly. |
| 2.19 | **Default Margin Setting** | ✅ Working — Text field for percentage, save to `app_settings` table | Simple form with text input. | Should-have | `views/settings.py:92-135` | Used as default for new costing calculations. | Save persists to `app_settings`. Value loads on revisit. |
| 2.20 | **Material Master CRUD** | ✅ Working — List of (name, rate, unit) with delete buttons. Add form with name + rate. | Simple list + add form. | Should-have | `views/settings.py:138-221` | Materials used in costing detail dropdown. Rate stored per unit. | Add/delete materials works. Materials appear in costing detail dropdown. |
| 2.21 | **Tag Master** | ✅ Working — Add tag (display name, multi-category chip selector with "Global" option, category-filtered tag list), tag list (display name, slug, categories chips, active/inactive status, Edit/Delete buttons). Edit dialog: display name + categories + active toggle. Delete safety check — refuses if items reference tag. Tags store in `tag_master` table + `rate_list.tags` JSONB. | Full CRUD screen. Multi-category chip selector. Category-filtered display (tags only show for their assigned categories). Delete safety check queries `rate_list.tags` JSONB via `contains` operator. | Must-have | `views/settings.py:584-910` | Tags are category-scoped: "Global" tags (no categories filter) appear for all categories; category-specific tags only appear when that category is selected. The `categories` column in `tag_master` is JSONB array of category names. | Add tag with categories works. Tag appears in add item form for correct categories. Edit/delete works. Delete safety prevents removal of in-use tags. |
| 2.22 | **Manage Customers** | ✅ Working — Customer list with search (shop name/owner/mobile), status badge (Active/Blocked), PIN display with copy button, last login timestamp, Edit + Block/Unblock buttons, Add Customer dialog (shop name, owner, mobile, city, notes), PIN generation (8-digit, collision-retry), PIN show dialog after creation. | Full CRUD screen. `get_customers()` returns all. PIN generation with `random` + collision check against DB. Copy PIN via clipboard. | Must-have | `views/customers.py:1-246` | Customer creation triggers `set_customer_last_active()` on login. PIN is permanent — no change UI. Block sets `is_active=false`. | Search filters correctly. Add creates customer with unique 8-digit PIN. Block/Unblock works. Copy PIN copies to clipboard. |
| 2.23 | **Archive Orders** | ✅ Working — Lists completed + cancelled orders (status filter). Same card style as home dashboard but read-only. Tap navigates to order detail. | `FutureBuilder` with status filter `in.(completed,cancelled)`. Read-only cards. Tap → order detail. | Should-have | `views/archive.py:1-104` | Uses `get_archived_orders()` which fetches by status + orders by `status_updated_at` desc. | Archived orders load correctly. Tapping navigates to read-only detail. |
| 2.24 | **Offline Sync Page (Hidden)** | ✅ Working — Hidden developer fallback (no nav UI entry). `sync_all()` downloads catalog + orders + images. Progress bar. Last-sync timestamp. Manual trigger only. | Keep as hidden dev tool or remove entirely if Isar handles sync automatically. | Later | `views/settings.py:493-576`, `cache.py` | Flet cache uses JSON files + downloaded images. Flutter uses Isar for offline. If Isar handles real-time sync, this page is unnecessary. | N/A — hidden feature. |
| 2.25 | **Item Visibility Toggle** | ✅ Working — Hide/Show button in Admin Catalogue cards. When hidden, `is_available=false` in rate_list. Customer catalogue filters `is_available=true` at load time. | Same Supabase column. Customer queries must always include `is_available=eq.true`. | Must-have | `views/pricing.py:504-518`, `db.py:622-625` | This is the customer-facing visibility control — critical for seasonal inventory. | Hiding an item removes it from customer catalogue. Showing restores it. |

---

## 3. Labour Features

Target APK: `mahalaxmi_admin` (labour role within admin APK — no separate APK)

| # | Feature | Flet Status | Flutter Requirement | Priority | Source File(s) | Migration Notes | Acceptance Test |
|---|---------|-------------|---------------------|----------|----------------|-----------------|-----------------|
| 3.1 | **Labour Dashboard** | ✅ Working — Order cards without prices, order count, FAB hidden (labour has no create). Tap → production checklist (labour) or order detail (admin). | Same order card widget as admin but conditionally hide price fields. No FAB. | Must-have | `views/home.py:10-354` | Price hiding based on `state["role"] == "labour"`. Labour also gets production summary on dashboard cards. | Labour sees orders without prices. No FAB. Tap opens production checklist. |
| 3.2 | **Production Checklist** | ✅ Working — Image-first cards (260px portrait). Per-size status pills (pending→prepared→not_available→pending cycle). Toggle cycles through statuses immediately with visual update. Status stored in `order_items.production_status` JSONB. Progress summary header. | Image-first cards with `GestureDetector` for per-size status toggles. Three-state cycle. Save to Supabase after each toggle. | Must-have | `views/labour.py:1-247` | Status cycle: `STATUS_CYCLE = ["pending", "prepared", "not_available"]`. Toggle updates both local state + Supabase immediately. JSONB column stores `{"2.2": "prepared", "2.4": "pending"}`. | Each size button cycles through 3 states. Visual update is instant. Progress bar updates. DB persists changes. |

---

## 4. Shared / Library Features

Target: `mahalaxmi_shared` (Dart package — models, repos, providers)

| # | Feature | Flet Status | Flutter Requirement | Priority | Source File(s) | Migration Notes | Acceptance Test |
|---|---------|-------------|---------------------|----------|----------------|-----------------|-----------------|
| 4.1 | **Supabase Repository Layer** | ✅ Working — 4 wrappers: `_get()`, `_post()`, `_patch()`, `_delete()` with error handling, connectivity tracking, `raise_errors` option. Functions: CRUD for all 10+ tables. | Dart package with Supabase SDK. Repository classes: `CategoryRepository`, `ItemRepository`, `OrderRepository`, `CustomerRepository`, `TagRepository`, `MaterialRepository`, `SettingsRepository`. Functions map 1:1 to `db.py`. | Must-have | `db.py:1-1044` | Flet's `db.py` is ~1044 lines of pure REST calls — mechanical but careful port. The `_get()` wrapper checks `_is_transport_error()` vs business errors — preserve this distinction. | All 10+ tables readable/writeable. Error handling matches Flet behavior (empty list on failure, True/False for mutations). |
| 4.2 | **Connectivity Tracking** | ✅ Working — `_consecutive_failures` counter (threshold=3), `is_online()`, `get_connectivity_status()` | Use `connectivity_plus` package OR passive tracking from Supabase client errors. Flet approach is passive — inferred from request failures. | Must-have | `db.py:29-57` | Passive tracking is preferable — no active ping. Riverpod `StreamProvider` for connectivity state? | After 3 consecutive failures, `isOnline()` returns false. On success, counter resets. |
| 4.3 | **Image Pipeline** | ✅ Working — `resize_product_image()`: EXIF fix (`ImageOps.exif_transpose`), 4:5 center-crop, 1080×1350, LANCZOS, sharpen (`ImageFilter.SHARPEN`), JPEG Q93 optimize. | Dart `image` package: same pipeline. Use `exif` package for orientation fix. `copyCrop()` + `resize()` + `Sharpening()` filter + `encodeJpg(quality: 93)`. | Must-have | `utils.py:140-168` | The 1080×1350 (4:5) portrait crop is critical for the B2B catalogue card layout. Image quality must match Flet output. | Image output is 1080×1350, 4:5 crop, no EXIF orientation issues, comparable quality to Flet. |
| 4.4 | **Offline Cache** | ✅ Working — `cache.py`: `sync_all()` → downloads `rate_list`, `categories`, `orders` → writes `catalog.json`, `orders.json`, `sync_meta.json`. `get_cached_catalog()`, `get_cached_orders()`, `get_cached_categories()`. Background image download. | Isar database as offline store. Collections: `Item`, `Order`, `Category`, `SyncMeta`. Background sync via `workmanager` or Supabase real-time. | Must-have | `cache.py:1-273` | Isar doesn't support web — use Drift (SQLite WASM) for web offline. The per-category cache pattern (`customer_category_cache` dict) maps to Riverpod `FutureProvider.family`. Flet's cache is login-invariant file-based — Flutter's Isar cache should work the same way. | Offline catalogue loads from Isar. Offline orders load from Isar. Sync updates Isar + UI. |
| 4.5 | **Session Persistence** | ✅ Working — `session_helper.py`: JSON file save/load/clear for 3 roles (admin, labour, customer). Keys: role, username, customer_mobile, customer_id, customer_shop_name. | `shared_preferences` for Flutter (both APK + Web). Role-based restore on app start. | Must-have | `session_helper.py:1-43` | Flet file location = `FLET_APP_STORAGE_DATA` env var or `"."`. Flutter `shared_preferences` handles this natively per platform. | Session survives app restart for all 3 roles. Logout clears session. |
| 4.6 | **Validation Engine** | ✅ Working — `validate_cart_item()` per-category rules: Chuda/Metal_Bangles = at least one size qty > 0, Kaleera = qty ≥ 1 + color required, Raw_Material = qty in [0.01, 99999.99] max 2 decimal places, Seasonal = qty ≥ 1. Dynamic categories use item's `has_sizes` flag. `validate_order()` validates all items + checks `rate_lookup`. | Pure Dart functions in shared package. Same rules. The `CATEGORY_SCHEMAS` dict maps to a Dart map or enum. | Must-have | `main.py:99-239`, `utils.py:45-92` | These are pure functions — easiest port in the entire codebase. Zero Flutter dependency. | Validation rejects invalid items. Accepts valid items. Error messages match Flet (for UX consistency). |
| 4.7 | **Line Total Calculator** | ✅ Working — `calculate_line_total()`: `sum_sizes_x_price` (Chuda, Metal_Bangles), `qty_x_price` (Kaleera, Raw_Material, Seasonal), dynamic fallback based on `_has_sizes` flag. | Pure Dart function. Same formula logic. | Must-have | `main.py:242-309`, `utils.py:94-109` | Pure function — easiest port. | Calculation matches Flet for all category types. |
| 4.8 | **Order Summary Builder** | ✅ Working — `build_order_summary()`: groups cart items by category, computes subtotals, grand total. Pure function (no DB calls). | Pure Dart function. Returns `OrderSummary` model with `List<CategoryGroup>` + `grandTotal`. | Should-have | `main.py:314-374` | Used by order form for live summary. No DB calls — purely derived from cart + rate lookup. | Summary groups items by category. Subtotals + grand total correct. |
| 4.9 | **Category Schema Engine** | ✅ Working — `build_category_fields()` in `main.py` maps item's `has_sizes`/`has_color` flags to controls: color dropdown (with "Custom" option) for colored items, 5 stepper rows for sized items, single qty stepper otherwise. `CATEGORY_SCHEMAS` defines 5 hardcoded + dynamic fallback. | Riverpod provider or helper function. Returns widget configuration (not widgets themselves). Fields are: color dropdown, 5 size steppers, single qty stepper. Dynamic categories use item flags. | Must-have | `main.py:740-870` | The +/- stepper UI pattern (`_build_qty_stepper`) is used pervasively — extract as reusable Flutter widget. Color dropdown + "Custom" textfield logic is specific to Chuda category. | Fields render correctly for has_sizes=true/false items. Color dropdown works with Custom option. Steppers increment/decrement. |
| 4.10 | **Tag Filter System** | ✅ Working — Tags extracted from loaded items' `tags` JSONB. Horizontally scrollable chip row. "All" chip + per-tag chips. Client-side filter — no DB call. Factory functions avoid closure bugs. | `ListView.builder(scrollDirection: Axis.horizontal)` for tags. Filter logic = `items.where((i) => i.tags.contains(selectedTag))`. Dart closures don't have Flet's closure bug — simpler implementation. | Must-have | `views/customer.py:561-637` | The `_make_tag_chip()` and `_make_all_chip()` factory functions in Flet are workarounds for Flet's closure bug. In Flutter, use normal closures. "Global" tags in Tag Master become special case: items with tags not matching any category-specific tag. | Tag chips display horizontally. Tapping a tag filters items locally. "All" reset works. |
| 4.11 | **Navigation System** | ✅ Working — `go()`: pushes to `nav_history`, clears on root pages, shows loading spinner, calls `render()`. `go_back()`: pops history or uses `BACK_MAP` or shows exit dialog. `render()`: page.views[interceptor + content]. Back button interceptor prevents minimize. | GoRouter with `ShellRoute` for persistent UI. `context.go()` for forward nav. `context.pop()` for back. Exit handling via `WillPopScope` + `showDialog`. | Must-have | `main.py:550-670,888-1073` | Flet's navigation is imperative; GoRouter is declarative. The `BACK_MAP` dict maps to GoRouter redirect rules. The interceptor pattern maps to `ShellRoute`. | All 20+ routes navigate correctly. Hardware back works at all levels. Exit dialog shows on root back. |
| 4.12 | **Connectivity Banner UI** | ✅ Working — `connectivity_banner()` in `utils.py`: 28px orange banner with "🔴 Offline — showing cached data" (offline), zero-height placeholder (online). Used on 4 read-heavy views: customer dashboard, admin home, pricing catalogue, order form. | `Consumer` widget that reads connectivity state. Shows orange banner when offline, zero-height `SizedBox.shrink()` when online. | Should-have | `utils.py:171-185` | Simple conditional widget. Can be `SliverToBoxAdapter` in `CustomScrollView` sliver lists. | Banner shows in offline state across all 4 views. Hidden when online. |
| 4.13 | **Business Rules Constants** | ✅ Working — `COLOR_OPTIONS`, `BOX_OPTIONS`, `GRIND_OPTIONS` in `main.py`. `CATEGORY_SCHEMAS` for validation rules. `_FALLBACK_CATEGORIES` in `db.py`. | Extracted as constants or enums in shared package. | Must-have | `main.py:35-43`, `db.py:71-72` | Colors: Light Mehroon, Dark Mehroon, Red, Rani, Custom. Box: Jodi Box, Mahal Box, Flap Box, Velvet Box. Grind: Gol / Internal-Grind, Bina Gol / Non-Grind. | Constants match Flet values exactly. |

---

## 5. Flet-Only Workarounds — DO NOT COPY

These patterns exist because of Flet 0.28.3 limitations. Flutter provides native equivalents — do not port the workaround, use Flutter's proper API.

| Flet Workaround | File | Why Not Needed in Flutter | Flutter API |
|-----------------|------|---------------------------|-------------|
| `page.overlay.append(dlg)` for dialogs | every view | Flutter dialogs are first-class | `showDialog()` |
| `page.overlay.append(snackbar)` | `main.py:535` | Flutter has native SnackBar | `ScaffoldMessenger.showSnackBar()` |
| `page.overlay` guard in `render()` | `main.py:889` | No background thread corruption in Flutter | `setState()` is synchronous |
| `page.views.clear()` + interceptor hack | `main.py:1056-1068` | GoRouter/`Navigator` handles routing natively | `ShellRoute` + `Navigator` |
| `ft.Dropdown.on_change` not `on_select` | `views/orders.py` | Flutter Dropdown uses `onChanged` | `DropdownButton.onChanged` |
| No `ResponsiveRow` | multiple files | Flutter `LayoutBuilder` + `GridView` work | `LayoutBuilder` + `GridView` |
| No `expand=True` inside `ft.Row` | `views/pricing.py` | Flutter `Expanded` widget works | `Expanded(child: ...)` |
| No `ft.ListTile.on_click` (unreliable) | `views/home.py` | Flutter `ListTile.onTap` is reliable | `ListTile.onTap` |
| RangeError in `ft.ListView` with hidden children | `views/pricing.py:751` | Flutter `ListView.builder` is robust | `ListView.builder(itemCount: ...)` |
| `connectivity_banner()` via failure counter | `utils.py:171-185` | `connectivity_plus` gives real stream | `connectivity_plus` package |
| `page.platform` detection for exit | `main.py:604` | `dart:io` `Platform` or `Theme.of(context).platform` | `Platform.isAndroid` |
| No `page.client_storage` | `session_helper.py` | `shared_preferences` works everywhere | `shared_preferences` package |
| Thread-based background work | `views/home.py:323` | `workmanager` or `Isolate` | `workmanager` plugin |
| No native share sheet | `views/orders.py:1254` | `share_plus` plugin (multi-image) | `share_plus` package |
| No `Intent.ACTION_SEND_MULTIPLE` | `slip_pdf_generator.py` | `share_plus` natively supports this | `Share.shareXFiles()` |
| Closure-bug factory functions (`make_*` handlers) | multiple views | Dart closures capture by value correctly | Normal closures |
| `page.state` dict for global state | `main.py:443-466` | Riverpod providers are type-safe | Riverpod |
| `ft.Container(on_click=..., ink=True)` for reliable taps | `views/home.py:268` | Flutter `GestureDetector` / `InkWell` work | `InkWell` / `GestureDetector` |
| `ft.Column([card], expand=True)` wrapper for width | `views/orders.py:700` | Flutter `Card` fills width naturally | `Card(child: ...)` |
| `os._exit(0)` for Android exit | `main.py:605` | Flutter: `SystemNavigator.pop()` | `SystemNavigator.pop()` |

---

## 6. Postponed Items (Stay Postponed)

These features existed in the original architecture or were planned but never implemented/matured. They should remain postponed in Flutter.

| Item | Context | Rationale for Postponement | File |
|------|---------|---------------------------|------|
| **Multi-select share** (Admin Catalogue) | Planned but not implemented in Flet | No requirement from business. Implement only if requested. | `views/pricing.py:250-400` (mentioned in comment) |
| **Offline Sync UI** (Data & Sync card) | Hidden from users in Flet (v1.0.20+). Kept as developer fallback. | Isar handles offline transparently in Flutter — no manual sync needed. Keep as dev-only debug page if required. | `views/settings.py:493-576` |
| **YouTube tutorial video** card on landing page | Marked "Coming Soon" in Flet | No content yet. Keep as placeholder if needed. | `views/auth.py:292` |
| **Push notifications (FCM)** | Planned in MIGRATION_NOTES.md Phase 2 | Not implemented in Flet. New feature — not feature parity. | MIGRATION_NOTES.md |
| **Camera plugin** (native) | Planned in MIGRATION_NOTES.md Phase 3 | Not implemented in Flet (used FilePicker fallback). Add when performance requires. | MIGRATION_NOTES.md |
| **`workmanager` background sync** | Planned in MIGRATION_NOTES.md Phase 3 | Not implemented in Flet (used thread-based background fetch). Add if users need background sync. | MIGRATION_NOTES.md |
| **Supabase RLS re-enable on tag_master** | Currently disabled in Flet | Would break current app. Re-enable with proper policies before production. | MIGRATION_NOTES.md §I.5 |
| **Customer Web (PWA)** | Planned Phase 4 | Still web-safe in Flutter codebase but PWA-specific features (manifest, service worker) are Phase 4. | MIGRATION_NOTES.md §H |
| **iPhone testing** | Planned Phase 4 | Requires macOS build environment. No Flet iOS equivalent existed. | MIGRATION_NOTES.md §H |
| **Old Cloudinary price-card system** | Fully removed in Flet (BUG-022) | Dead feature. Do NOT re-add. | `sql/migration_remove_card_path.sql` |
| **Packing structure** | Fully removed in Flet (Order Form Phase B) | Removed from UI, DB, PDF, slips. Do NOT re-add. | `views/orders.py` |

---

## 7. Migration-Critical Business Rules

These rules must be preserved exactly in Flutter. Breaking any of these will cause data loss or business workflow disruption.

### 7.1 Role-Based Access
| Rule | Detail | Enforcement Point |
|------|--------|-------------------|
| **Labour must never see prices** | Price columns (selling_price, cost_price, line_total) hidden from labour role in all views: home dashboard, order detail, production checklist. | All order-related views |
| **Customer sees only available items** | `is_available=true` AND `selling_price > 0` filter applied in all customer catalogue queries. | `get_customer_items_by_category()`, `get_customer_catalogue()`, `search_customer_items()` |
| **Admin sees everything** | Admin has full CRUD access. No data filtering. | All views |

### 7.2 Order Lifecycle
| Rule | Detail | Enforcement Point |
|------|--------|-------------------|
| Status flow: pending → confirmed → cancelled (from pending), confirmed → completed | Transitions are irreversible (once confirmed, cannot cancel — Flet doesn't enforce this but UI only shows relevant actions). | `set_order_status()` |
| Order deletion is permanent | No soft-delete. Cascade deletes `order_items`. | `delete_order()` |
| Order items are replaced on edit | `update_order()` deletes all existing items + reinserts. | `update_order()` |
| Source = "customer" vs "admin" | Customer-placed orders have `source="customer"`. Admin-created have `source="admin"`. | `create_order()` |

### 7.3 Customer Management
| Rule | Detail | Enforcement Point |
|------|--------|-------------------|
| PIN is 8-digit numeric, must be unique | Auto-generated with collision retry (max 100 attempts). PIN is permanent — no change UI. | `generate_unique_pin()`, `create_customer()` |
| Blocked customers cannot log in | `is_active=false` → "Your account is blocked" message on login attempt. | `get_customer_by_pin()`, login flow |
| Customer last_active_at tracked | Updated on every successful PIN login. | `set_customer_last_active()` |

### 7.4 Item & Catalogue Rules
| Rule | Detail | Enforcement Point |
|------|--------|-------------------|
| Item number is unique and immutable on edit | During edit, item_number field is read-only (BUG-016). | `view_add_item()` in `pricing.py` |
| Category cannot be deleted while items use it | `delete_category()` checks `rate_list` for references first. | `delete_category()` |
| Tag cannot be deleted while items reference it | `delete_tag()` checks `rate_list.tags` JSONB `contains` operator. | `delete_tag()` |
| Image pipeline is fixed: 1080×1350, 4:5 crop, sharpen, Q93 | Must match exactly for consistent catalogue appearance. | `resize_product_image()` |

### 7.5 Customer Cart Rules
| Rule | Detail | Enforcement Point |
|------|--------|-------------------|
| Cart is NOT persisted | Lost on app close. Session saves role + identity only. | `logout()` clears `customer_cart` |
| Line total = qty × unit_price | For sized items: sum of all size qty values × unit_price. For simple items: quantity × unit_price. | `calculate_line_total()` |
| Order validation runs before save | `validate_order()` checks every cart item against category rules. | `save_order()` in orders.py, `place_order()` in customer.py |

---

## 8. Supabase Schema Assumptions — DO NOT CHANGE

The Flutter app connects to the **same Supabase project**. These schema details must remain unchanged or the app breaks.

### 8.1 Tables & Key Columns

| Table | Key Columns | Notes |
|-------|-------------|-------|
| **`customers`** | `id` (PK), `pin` (unique text), `shop_name`, `owner_name`, `mobile`, `city`, `notes`, `is_active` (bool), `created_at`, `last_active_at` | PIN is 8-digit text (leading zeros preserved). `is_active=false` = blocked. |
| **`categories`** | `id` (PK), `name` (unique text), `icon` (text key), `color` (text key), `description`, `sub_categories` (comma-separated text), `order_type` (text), `is_active` (bool), `cover_image_url` (text) | `order_type` values: "sizes", "quantity", "quantity_with_unit", "quantity_with_notes". |
| **`rate_list`** | `item_number` (PK text), `image_url` (text), `cost_price` (float8), `selling_price` (float8), `category` (text FK), `sub_category` (text), `has_sizes` (bool), `has_color` (bool), `is_available` (bool), `margin_percent` (float8), `status` (text: "new"/"priced"), `tags` (JSONB: `["tag1","tag2"]`) | `item_number` is the primary key, NOT `id`. Tags JSONB is `List<String>` in Dart. |
| **`orders`** | `order_id` (PK int8), `customer_name`, `order_date`, `color`, `grind_type`, `box_type`, `additional_info`, `total_amount`, `source` ("admin"/"customer"), `customer_mobile`, `customer_id` (int8 FK→customers.id), `status` (text: "pending"/"confirmed"/"cancelled"/"completed"), `status_updated_at` | `order_id` is auto-increment. Source = "customer" for customer-placed orders. |
| **`order_items`** | `order_id` (FK→orders), `item_number` (text), `category` (text), `qty_2_2`/`2_4`/`2_6`/`2_8`/`2_10` (int4), `quantity` (float8), `unit` (text), `color` (text), `grind_type` (text), `box_type` (text), `notes` (text), `unit_price` (float8), `production_status` (JSONB or text) | `production_status` JSONB example: `{"2.2": "prepared", "2.4": "pending"}`. Non-sized items use key `"single"`. |
| **`tag_master`** | `id` (PK), `name` (text — slug), `display_name` (text), `category` (legacy text — nullable), `is_active` (bool), `categories` (JSONB: `["Cat1","Cat2"]`), `created_at` | `categories` JSONB is the preferred column. `category` kept for backward compat. |
| **`materials`** | `id` (PK), `name` (text), `rate` (float8), `unit` (text), `category` (text) | Used in costing dropdown. |
| **`cost_breakdown`** | `id` (PK), `item_number` (FK→rate_list), `material_id` (int8), `material_name` (text), `quantity` (float8), `unit` (text), `rate_per_unit` (float8), `line_total` (float8) | Replaced on each costing save (delete + reinsert). |
| **`item_materials`** | `item_number` (FK→rate_list), `material_id` (int8), `material_name` (text), `qty` (float8), `rate_per_unit` (float8) | Used in costing detail. Replaced on each save. |
| **`app_settings`** | `key` (text PK), `value` (text) | Keys: `default_margin`, `labour_cost_flat`. Fetched via `get_setting(key, default)`. |

### 8.2 Storage Buckets

| Bucket | Path Pattern | Visibility | Used For |
|--------|-------------|------------|----------|
| `product-images` | `{item_number}.{ext}` | Public | Product images. Upsert enabled (`x-upsert: true`). |
| `product-images` | `category_covers/{slug}.{ext}` | Public | Category cover images. |
| `product-images` | `order-pdfs/slip_{order_id}.pdf` | Public | Karigar slip PDFs. |

### 8.3 RLS Status

| Table | RLS | Policy |
|-------|-----|--------|
| All tables | **Disabled** (currently) | Must re-enable with proper policies before production release. Start with tag_master (MIGRATION_NOTES.md §I.5). |

### 8.4 Supabase Project

| Detail | Value |
|--------|-------|
| Project URL | `https://lgiepatlslklpxmeqkww.supabase.co` |
| Anon Key | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnaWVwYXRsc2xrbHB4bWVxa3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMzYyMzEsImV4cCI6MjA5NTgxMjIzMX0.ciwTJjAjNeZ01tsZDUFgZ_ryQDQltloJQm_OQinryKQ` |
| Storage Bucket | `product-images` |

---

## 9. Feature Totals & Status

### Count by Priority

| Priority | Count | Categories |
|----------|-------|------------|
| **Must-have** | 33 | Core customer flow (1.1–1.11), admin CRUD (2.1–2.25), labour (3.1–3.2), shared core (4.1–4.13) |
| **Should-have** | 8 | Image viewer (1.7), search (1.11), watermark (1.12), PDF gen (2.12), archive (2.23), margin (2.19), material master (2.20), order summary builder (4.8), connectivity banner (4.12) |
| **Later** | 1 | Offline sync page (2.24) |

### Count by App Target

| Target | Must-have | Should-have | Later | Total |
|--------|-----------|-------------|-------|-------|
| **Customer APK+Web** | 9 | 3 | 0 | 12 |
| **Admin APK** | 19 | 4 | 1 | 24 |
| **Labour (in Admin APK)** | 2 | 0 | 0 | 2 |
| **Shared package** | 7 | 2 | 0 | 9 |
| **Total** | 33 | 8 | 1 | 42 |

### Flet-Only Workarounds (DO NOT COPY)
**19 patterns** documented in §5 — ensures Flutter code uses native APIs, not Flet workarounds.

### Postponed Items (Stay Postponed)
**9 items** documented in §6 — prevents scope creep and re-introduction of dead features.

### Migration-Critical Business Rules
**14 rules** documented in §7 — must be preserved exactly to avoid data loss or workflow disruption.

### Supabase Schema Assumptions
**Full schema** documented in §8 — tables, columns, storage buckets, RLS status — must remain unchanged.
