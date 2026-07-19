# 03 — Admin App (`mahalaxmi_admin`)

## Web Support

- **Enabled:** 2026-07-06 — Admin app now builds for both Android APK and Web
- **Web URL:** `https://admin.mahalaxmibangles.com`
- **Build command:** `flutter build web --release --dart-define-from-file=.env`
- **Output folder:** `build/web/`
- **Hosting:** Cloudflare Pages
- **Protection:** Cloudflare Access (owner email only — no public access)
- **Web blockers fixed:**
  - `dart:io` removed from `share_photo_service.dart` (was importing `File`, `path_provider`)
  - `SystemNavigator.pop()` guarded with `!kIsWeb` in `router.dart`
  - Share photo service rewritten to use `Uint8List` + `share_plus` (works on both platforms)
  - Web manifest and index.html updated with admin branding (maroon theme, "Mahalaxmi Admin" title)
- **Web-compatible features:** Login, dashboard, orders, catalogue, customers, settings, cutmail, image picker, PDF generation (via `printing` package)
- **Web fallbacks:** Photo share uses Web Share API or browser download on web
- **Session:** `SharedPreferences` works on web via `shared_preferences_web` (localStorage)

### Web Security Layers

| Layer | Status | Purpose |
|-------|--------|---------|
| Cloudflare Access | ✅ Deployed | Outer gate — only approved email can reach the app |
| Route guards | ✅ Client-side | Redirects unauthenticated users to `/login` |
| Supabase Auth | ⚠️ **Pending** | Server-side JWT validation (currently hardcoded passwords) |
| RLS policies | ⚠️ **Pending** | Database-level row access control (currently disabled) |

> ⚠️ **WARNING:** Admin web MUST NOT be deployed without Cloudflare Access until Supabase Auth/RLS hardening is complete. See `ADMIN_WEB_SECURITY_RLS_AUDIT.md` for details.

## Dashboard

- **Phase 1 redesign** (2026-07-05): Now a business overview with 6 sections
- **Quick Actions:** 4 action cards — Create Order, Add Item, Add Customer, View Cutmail
- **Main Summary Cards:** Pending Orders, Confirmed Orders, Pending Cutmail, Active Customers
- **Needs Attention:** Alerts for items without price, categories missing cover, cutmails pending review, unavailable items
- **Recent Orders:** Latest 5 orders with amount, tap to open detail
- **Latest Cutmail:** Latest 5 cutmail reports, tap to open detail
- **Catalogue Health:** Total/available/unavailable items, categories, customers, active customers
- **Data source:** Combined `adminDashboardDataProvider` (reads from 6 existing providers in parallel via `Future.wait`)
- **Refresh:** Manual only (AppBar button + pull-to-refresh), no auto-refresh timer
- **Phase 2 pending:** Server-side count queries if performance needed
- Session persistence via `SharedPreferences` (same pattern as customer app)

## Orders

- **Active orders:** Filterable list (All/Pending/Confirmed/Completed/Cancelled)
- **Create order:** Manual order creation with item picker, size/quantity input, Chuda customization support
- **Archive orders:** Tabbed list (All/Completed/Cancelled) — status-based archive
- **Soft delete:** Archived orders (completed/cancelled) can be soft-deleted with `deleted_at`/`deleted_by`/`delete_reason`
  - Cancelled: simple confirm with optional reason
  - Completed: requires typing `DELETE` to confirm
  - No hard-delete from UI — uses `softDeleteOrder()` in repository
  - Soft-deleted orders excluded from all queries (`isFilter('deleted_at', null)`)
- **Admin order detail:** Shows size chips, Chuda customisation section, Danger Zone for delete
- **Order item variant merging:** `_isSameVariant` compares all customization fields to decide merge vs new line

## Catalogue

- **Category list:** Shows all categories with item counts, inactive badge, sort order controls
- **Category items:** Search + availability filter (All/Available/Hidden) + sorting (Item/Price/Cost, ↑↓)
- **Item cards:** Selling price (red if loss), cost price, margin badge (green), LOSS badge (red), tags on own line
- **Add item:** Full form with item number, category (with sub-category), selling/cost price, margin % (auto-calc), tag chips, available sizes, availability, image URL/web upload with crop
- **Edit item:** All fields editable including cost price, margin %, has_sizes, has_colors, available sizes; auto-save with navigation back
- **Delete item:** Confirmation dialog, refreshes provider
- **Missing price items:** Routing `/catalogue/missing-price`, items with `sellingPrice == 0.0`
- **Default margin:** Loaded from provider, auto-calculates selling price from cost + margin
- **Image upload:** 4:5 crop at 1080×1350px, JPEG Q90, Supabase Storage

### Tags

- Tag chip selector (DropdownButton + InputChip with delete), sourced from Tag Master
- Tags saved as `List<String>` JSONB on `rate_list.tags`
- Tag Master edit/delete fix: use `.filter('tags', 'cs', jsonEncode([tag]))` instead of `.contains()` for JSONB compatibility with postgrest v2.7.1

## WhatsApp Photo Share

- Selection mode on category items page (checkbox overlays)
- Generate JPGs (1080×1350, 4:5, Q90) with item number + price (`INR X,XXX`)
- Sequential generation, skip failed image downloads
- Share via `share_plus` — one JPG per item, no branding

## Customers

- Customer list with last-active timestamps
- Toggle active/inactive status
- Active status validated on customer app session restore, app resume, and before order placement
- Force-logout inactive customers

## Settings

- **Manage Categories:** Create/edit/delete, size chart chip selector, sort order (▲/▼ Move Up/Move Down)
- **Tag Master:** Create/edit/delete tags
- **Cutmail:** View/edit/review/archive stock-check entries
- **Archive Orders:** Tabbed archive order list

## Cutmail Admin

- Tabbed list (Pending/Reviewed/Archived/All) with search + category filter
- Detail page: item info, size-wise quantities (edit mode), note, status badge
- Actions: Mark Reviewed (with reviewer name), Archive
- Status colors: yellow=pending, green=reviewed, grey=archived
