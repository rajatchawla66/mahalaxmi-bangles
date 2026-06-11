# Mahalaxmi Bangles — Complete Codebase Audit

**Date:** 11 June 2026
**Version:** 1.0.18
**Framework:** Flet 0.28.3 (Python), Supabase (cloud), httpx (HTTP)
**DB Schema:** 9 tables — `categories`, `rate_list`, `orders`, `order_items`, `materials`, `cost_breakdown`, `customers`, `app_settings`, `item_materials`
**Build:** APK via `flet build apk`, CI on GitHub Actions
**Total source files:** 16 `.py` files across `views/` + root

---

## 1. ADMIN FEATURES

### Screens & Actions

| Screen | File | Actions Available |
|--------|------|-------------------|
| **Login** | `views/auth.py` | Tap "Admin Login" text button immediately logs in as admin (no password) |
| **Home** (order list) | `views/home.py` | View all orders newest-first; tap order → detail; status badge (Pending/Confirmed); popup menu: Confirm / Cancel / Delete; Mark Completed; FAB (+) → create new order |
| **Order Type Picker** | `views/orders.py` | Choose Single Category or Mixed Order |
| **Category Picker** | `views/orders.py` | Pick one category (dynamically loaded from DB) |
| **Order Form** | `views/orders.py` | Customer name, date, packing, additional info; add items with +/- steppers (sizes or qty); color dropdown with Custom option; remove items; summary with items/qty/amount; Save Order |
| **Order Detail** | `views/orders.py` | Header, items grouped by category with sizes/qty, line totals, grand total; Edit Order, Karigar Slip |
| **Karigar Slip** | `views/orders.py` | Hindi/English slip with images, sizes table; Share PDF (PDF generation via fpdf2 → Supabase upload → WhatsApp) |
| **Add Item** | `views/pricing.py` | Item number, category (dynamic), sub-category, has_sizes/has_color toggles, image picker, availability toggle, save |
| **Catalogue** | `views/pricing.py` | All items with image, CP/SP, margin, availability; Edit → Add Item; Hide/Show; Delete with confirm |
| **Costing List** | `views/pricing.py` | Searchable items with costed status (✅ SP, ⚠️ CP only, ❌ not costed) |
| **Costing Detail** | `views/pricing.py` | Vertical material cards (name, qty, rate, amount, delete); total cost; margin toggle; selling price preview; Save |
| **Settings** | `views/settings.py` | 6-item menu: Manage Categories, Margin, Material Master, Manage Customers, Archive Orders, Logout |
| **Manage Categories** | `views/settings.py` | Add (name, icon, color, description, sub-categories, order_type, cover image); Activate/Deactivate/Delete |
| **Margin** | `views/settings.py` | Set default margin % |
| **Material Master** | `views/settings.py` | CRUD for raw materials (name, rate, delete) |
| **Manage Customers** | `views/customers.py` | Search; Add (auto-generates 8-digit PIN, shows in dialog); Copy PIN; Edit; Block/Unblock; last active in IST |
| **Archive Orders** | `views/archive.py` | Completed/cancelled orders list; tap → order detail |
| **Sync** | `views/settings.py` | Manual sync; downloads catalog, orders, images to cache; progress bar; last sync time |

### Admin-specific data visible
- Selling prices, cost prices, margin
- All orders (any customer)
- Customer names on orders
- Total amounts on orders

### Limitations / incomplete features
- No password authentication — tap-to-login
- No order deletion from order detail (only from home popup)
- No batch operations

---

## 2. LABOUR FEATURES

### Screens & Actions

| Screen | Actions Available |
|--------|-------------------|
| **Login** | Tap "Labour Login" → immediately logged in |
| **Home** | View all orders, tap → detail; **no** Confirm/Cancel/Delete; **no** FAB; **no** nav bar |

### What Labour cannot see
- No prices (selling, cost, total amounts hidden)
- No Rate List / Catalogue / Costing / Settings tabs
- No Add Item
- No navigation bar (only Home)

### Limitations
- Same login method as admin (no password)
- Identical data access except prices hidden and actions restricted

---

## 3. CUSTOMER FEATURES

### Screens & Flow

| Screen | Actions Available |
|--------|-------------------|
| **Landing Page** (`views/auth.py`) | Premium cream/gold/maroon page; watermark logo, firm name, GST number, 8-digit PIN input, 2x2 contact cards (Instagram, WhatsApp, Visit Showroom, YouTube coming soon), heritage text, Admin/Labour links |
| **Dashboard** (`views/customer.py`) | Greeting; search (3+ chars); category grid (portrait tiles 2-per-row, item count badge, cover images); cart badge + My Orders + Refresh in header |
| **Subcategories** | "View All" card + subcategory cards with item counts and covers |
| **Items Grid** | Portrait cards (350px image with watermark overlay, item number, selling price, "View" button); single column |
| **Item Detail** | Large image with watermark + tap-to-zoom; info card; optional color dropdown; quantity steppers (per-size 2.2-2.10 or single qty); summary card; bottom CTA "Add to Cart" |
| **Image Viewer** | Full-screen pinch zoom (InteractiveViewer), watermark overlay, close button |
| **Search Results** | Same portrait cards, filtered by item_number/category/sub_category; real-time |
| **Cart** | Items with qty, line total, delete; total; Place Order / Browse Catalogue |
| **My Orders** | Customer's orders with status badges; expandable detail; "Add Again" per item |

### Customer visible data
- Item numbers, categories, subcategories
- Selling prices
- Their own order history with status
- Item images with watermark overlay

### Customer cannot see
- Cost prices, margins
- Other customers' orders
- Any admin/labour screens
- No order editing or cancellation

### Limitations
- No address / delivery fields
- "Add Again" for sized/colored items redirects to item detail (no direct re-add)
- Cart not persisted across app restarts
- Search requires 3+ characters

---

## 4. ORDER MANAGEMENT

### Creation Flow
1. Admin taps FAB (+) → Order Type Picker (Single/Mixed)
2. Single: pick category → Order Form filtered to that category
3. Mixed: Order Form with per-row category dropdown
4. Add items → select item → fill sizes/qty/color → repeat
5. Enter customer name, date, packing, notes
6. Save → validation → Supabase insert → back to home

### Data Captured Per Order
- **Header**: customer_name, order_date, color, grind_type, box_type, packing_structure, additional_info, total_amount, source ("admin"|"customer"), customer_mobile, customer_id, status, status_updated_at
- **Line Items**: item_number, category, qty_2_2–qty_2_10, quantity, unit, color, grind_type, box_type, notes, unit_price

### Statuses
- `pending` → `confirmed` → `completed` | `cancelled` (anytime)
- Admin: Pending → Confirmed / Cancelled / Deleted; Confirmed → Completed
- Customer orders start at `pending`
- Status badge colors: Amber, Green, Red

### Karigar Slip
- Hindi/English PDF via `fpdf2`
- Header, order details card, per-item blocks with image/sizes
- Share: generate PDF → upload to Supabase Storage → WhatsApp link

### Customer vs Admin Orders
- Customer: `source="customer"`, linked to `customer_id`
- Admin: `source="admin"`, no customer link
- Customers see only their own orders; admin sees all

### Editing & Deletion
- Admin can edit from Order Detail (loads all items into cart → re-save)
- Admin can delete from Home popup menu (with confirm dialog)
- Customers cannot edit or cancel

---

## 5. CATALOGUE AND PRICING

### Item Data Model (`rate_list` table)
- `item_number` (PK), `image_url`, `cost_price`, `selling_price`
- `category`, `sub_category`, `has_sizes`, `has_color`
- `is_available`, `status` ("new"|"priced"), `card_path`, `margin_percent`

### Item Addition
1. Nav bar → Add Item
2. Enter item number (auto-checks existence → pre-fills edit mode)
3. Select category (dynamic), sub-category
4. Toggle has_sizes / has_color
5. Pick image → Supabase Storage upload
6. Save → insert/update

### Customer Catalogue Organisation
- Categories from Supabase (active only)
- Items: `is_available=true` AND `selling_price > 0`
- Browsing: Dashboard → Categories → Subcategories (optional) → Items → Detail

### Costing Workflow
1. Nav bar → Costing → item list with costed status
2. Tap item → Costing Detail
3. Add materials from Material Master or type unlisted
4. Cards: material name, qty, rate, computed amount
5. Total cost auto-calculated
6. Default/custom margin → SP preview
7. Save → `item_materials` + updates `cost_price`/`selling_price`

### Material Master
- CRUD via Settings → Material Master
- Fields: name, rate, unit ("pcs" default)
- Used in Costing Detail dropdown

---

## 6. SYNC AND DATA

### Online Mode (Default)
- All reads/writes direct to Supabase REST API (httpx)
- Credentials hardcoded in `db.py` (env var override supported)
- Images: Supabase Storage bucket `product-images`
- PDFs: same bucket, `order-pdfs/` subfolder

### Offline Cache
- **Manual only** — Settings → Sync → Sync Now
- Downloads: rates + categories → `cache/catalog.json`; orders → `cache/orders.json`; images → `cache/images/`
- Cache is fallback — Supabase fresh data preferred
- No auto-sync on start

### What Works Offline
- Reading cached catalog, categories (filtered `is_active`), orders
- Images mapped to local paths if cached

### What Does NOT Work Offline
- All writes fail silently
- No offline write queue
- No connectivity detection
- No auto-sync

### Known Sync Limitations
- Some items have local filesystem `image_url` (not Supabase URLs) — invisible on other devices
- No delta sync — full re-download every time
- Sequential image download (blocks UI)

---

## 7. MISSING OR INCOMPLETE FEATURES

### Critical Issues
1. **Karigar Slip PDF Share broken** — "Unknown Control: Source" error when sharing
2. **`ft.Card` blocks touch events** — Partially fixed; some views still use `ft.Card`
3. **Local image paths don't sync across devices** — Some `image_url` values are local paths
4. **`ft.ListTile.on_click` unreliable in scrollable parents** — Home order list affected

### Partially Built
5. **No proper authentication** — Admin/Labour is tap-to-enter; Customer uses 8-digit PIN
6. **No connectivity detection** — App has no online/offline awareness
7. **Offline write queue not implemented** — Writes fail silently
8. **Order status: only 4 states** — No "In Progress"/"Ready"
9. **Cloudinary price cards: no caching** — Re-uploads every time

### Known Bugs
10. SnackBar overlay buildup mitigation not perfect
11. FilePicker appended multiple times in Manage Categories
12. Cart state not persisted across restarts
13. No pagination — all items/orders loaded at once
14. Full re-render on every navigation
15. N+1 query in home view
16. Android back button edge cases

### Security
17. Supabase credentials hardcoded (anon key, full access)
18. No RLS policies on Supabase
19. Client-side-only validation

### Not Yet Implemented
20. Push notifications
21. Inventory tracking
22. Payment tracking
23. Reports / analytics
24. Delivery tracking
25. Multi-language support (beyond slip)
26. Dark mode
27. Tablet-responsive layout
28. Desktop admin web panel
29. WhatsApp Business API integration
30. Barcode / QR scanning
31. Order templates
