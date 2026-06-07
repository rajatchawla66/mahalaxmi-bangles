# KNOWN ISSUES — Mahalaxmi Bangles Order Manager

## Critical Bugs

### 1. Karigar Slip PDF Share Issue ("Unknown Control: Source")
**Severity:** High  
**Location:** `views/orders.py` → `view_karigar_slip()`  
**Symptom:** When clicking on the Karigar slip share button, the app throws an "Unknown Control:Source" error and turns the left side of the screen red.  
**History / Log of Fix Attempts:**
1. **Initial Issue:** User reported "Failed to share, no module named fpdf".
2. **Attempt 1 (ReportLab):** Replaced `fpdf` with `ReportLab` to avoid missing module errors. However, relying on complex 3rd-party C-extensions caused build/runtime issues on Android.
3. **Attempt 2 (HTML/Markdown + Flet Share):** Migrated to generating a temporary file (Markdown/HTML) and using Flet's native `ft.Share()` control.
4. **Issue:** Encountered "Unknown Control: Share" error.
5. **Attempt 3 (Global Share Registration):** Registered `ft.Share()` globally by adding `page.services.append(share_service)` in `main.py` early in the app lifecycle. This successfully solved the Share control registration issue.
6. **Current Issue:** The sharing mechanism now hits a new framework error: `"Unknown Control:Source"`, which is likely caused by Flet internally parsing an unsupported property/control (possibly related to `ft.Image(src=...)` or an internal component invoked by the sharing logic) when rendering the slip or generating the share payload.
**Status:** Not fixed. User is migrating this issue to another AI model.

---

### 2. `ft.Card` Blocks Touch Events
**Severity:** High  
**Location:** `main.py` — multiple views use `ft.Card`  
**Symptom:** Interactive content (buttons, dropdowns, text fields) inside `ft.Card` becomes untappable when the card is inside a scrollable parent (`ft.ListView` or `ft.Column(scroll=AUTO)`).  
**Root Cause:** Flet 0.85's `ft.Card` widget captures touch events and doesn't propagate them to children in scrollable contexts.  
**Workaround:** Replace `ft.Card` with `ft.Container` using border styling:
```python
# BAD — blocks touches
ft.Card(elevation=3, content=ft.Container(...))

# GOOD — works reliably
ft.Container(
    padding=12,
    border_radius=10,
    bgcolor=ft.Colors.WHITE,
    border=ft.Border.all(1, ft.Colors.GREY_300),
    shadow=ft.BoxShadow(spread_radius=0, blur_radius=4,
                        color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK),
                        offset=ft.Offset(0, 2)),
    content=...
)
```
**Status:** Partially fixed. Some views still use `ft.Card` (e.g., `view_order_form()` customer card, catalogue items in `view_rate_list()`). These need migration.

**Affected Views:**
- `view_order_form()` — `customer_card` uses `ft.Card`
- `view_rate_list()` — catalogue items use `ft.Card`
- `view_manage_categories()` — category cards use `ft.Card`
- `view_order_detail()` — item blocks use `ft.Card`

---

### 2. Local Image Paths Don't Sync Across Devices
**Severity:** High  
**Location:** `db.py` → `rate_list.image_url` column  
**Symptom:** Some items have `image_url` values like `product_images/X.jpg` (local paths) instead of Supabase Storage URLs. These images are invisible on other devices.  
**Root Cause:** Early items were added before the Supabase Storage upload flow was implemented. Their `image_url` still points to local filesystem paths.  
**Fix Required:** Batch re-upload all items with local paths:
```python
# Pseudocode for migration script
items = db.get_rate_list()
for item in items:
    if item["image_url"] and not item["image_url"].startswith("http"):
        if os.path.exists(item["image_url"]):
            new_url = db.upload_image(item["image_url"], item["item_number"])
            db._patch("rate_list", f"item_number=eq.{item['item_number']}", {"image_url": new_url})
```
**Status:** Not fixed. Needs a one-time migration script.

---

### 3. `ft.ListTile.on_click` Unreliable in Scrollable Parents
**Severity:** Medium  
**Location:** `main.py` → `view_home()` (order list)  
**Symptom:** Tapping on order cards in the home view sometimes doesn't register, especially on Android.  
**Root Cause:** `ft.ListTile.on_click` doesn't fire reliably when the ListTile is inside a scrollable `ft.Column`.  
**Workaround:** Replace `ft.ListTile` with `ft.Container(on_click=...)`:
```python
# Current (unreliable):
ft.ListTile(on_click=on_order_tap(order["order_id"]), ...)

# Better:
ft.Container(
    on_click=on_order_tap(order["order_id"]),
    ink=True,
    padding=12,
    border_radius=8,
    bgcolor=ft.Colors.WHITE,
    content=ft.Row([...]),
)
```
**Status:** Not fixed. Home view still uses `ft.ListTile`.

---

## Medium Bugs

### 4. Cloudinary Price Card Generation is Slow
**Severity:** Medium  
**Location:** `db.py` → `generate_price_card_url()`  
**Symptom:** Sharing catalog items takes 3-5 seconds per item because each card requires: download image from Supabase → upload to Cloudinary → return URL.  
**Root Cause:** No caching of Cloudinary uploads. Every share re-uploads the image.  
**Fix Options:**
1. Cache the Cloudinary URL in `rate_list.card_path` after first generation
2. Pre-generate all cards during sync
3. Use Cloudinary's existing `public_id` to skip re-upload if already exists

**Status:** Not fixed.

---

### 5. Android Back Button Navigation Edge Cases
**Severity:** Medium  
**Location:** `main.py` → `_on_view_pop()`, `go_back()`  
**Symptom:** In some navigation scenarios (e.g., deep navigation: home → order_detail → karigar_slip → back → back), the back button may not return to the expected page.  
**Root Cause:** `nav_history` stack can get out of sync with actual navigation when `go()` is called with the same target multiple times, or when `BACK_MAP` conflicts with history.  
**Workaround:** The `BACK_MAP` provides a fallback, but it doesn't always match user expectation.

**Status:** Partially mitigated. History stack is capped at 20 entries.

---

### 6. SnackBar Overlay Buildup
**Severity:** Low  
**Location:** `main.py` → `snack()` function  
**Symptom:** Rapid actions could theoretically stack multiple SnackBars in `page.overlay`.  
**Current Mitigation:** The `snack()` function clears previous SnackBars before adding a new one:
```python
page.overlay[:] = [c for c in page.overlay if not isinstance(c, ft.SnackBar)]
```
**Status:** Mitigated but not perfect — the FilePicker is also in `page.services` and could interact.

---

### 7. FilePicker Added Multiple Times
**Severity:** Low  
**Location:** `main.py` → `view_rate_list()`  
**Symptom:** Every time the rate list view is rendered, a new `ft.FilePicker` is appended to `page.services`. Over time, this accumulates unused pickers.  
**Root Cause:** `page.services.append(file_picker)` is called inside the view function which runs on every navigation to that page.  
**Fix:** Check if picker already exists, or move picker creation to `main()` scope.

**Status:** Not fixed.

---

## Technical Debt

### 9. No Error Handling for Network Failures
**Impact:** If Supabase is unreachable, all `_get()`, `_post()`, `_patch()`, `_delete()` silently return empty results or `False`.  
**Location:** `db.py` — all HTTP helper functions catch all exceptions and return defaults.  
**Symptom:** User sees empty lists or "saved" confirmations even when the operation failed.  
**Recommendation:** Add a connectivity check and show offline banner. Queue failed writes for retry.

---

### 10. No Input Sanitization for Supabase Queries
**Impact:** PostgREST filter values are URL-encoded via `urllib.parse.quote()` but not validated for injection.  
**Location:** `db.py` — all functions that build query params.  
**Risk:** Low (PostgREST is relatively safe), but item numbers with special characters could cause unexpected behavior.

---

### 11. Hardcoded Credentials in Source Code
**Impact:** Security risk. Anyone with access to the repo has full database access.  
**Location:** `db.py` lines 20-21  
**Recommendation:** 
1. Move to environment variables (already supported as fallback)
2. Implement Supabase Row Level Security (RLS)
3. Use Supabase Auth for proper user authentication

---

### 12. No Data Validation on Server Side
**Impact:** All validation is client-side only. A direct API call could insert invalid data.  
**Location:** Supabase has no RLS policies or database constraints beyond basic types.  
**Recommendation:** Add PostgreSQL CHECK constraints and RLS policies.

---

### 13. `view_order_detail()` Uses Legacy Category-Based Logic
**Impact:** The order detail view has hardcoded category checks (`if cat == "Chuda"`, `elif cat == "Kaleera"`) instead of using the item-level `has_sizes`/`has_color` flags.  
**Location:** `main.py` → `view_order_detail()` around line 1600  
**Symptom:** Dynamic categories (user-created) may not display correctly in order details.  
**Fix:** Refactor to use `has_sizes`/`has_color` from `order_items` or `rate_list`.

---

### 14. Cart State Not Persisted
**Impact:** If the app crashes or user accidentally navigates away during order creation, the entire cart is lost.  
**Location:** `state["cart"]` is in-memory only.  
**Recommendation:** Save cart to local storage (JSON file) and restore on app start.

---

### 15. No Pagination for Orders/Items
**Impact:** As the database grows, loading ALL orders/items on every view render will become slow.  
**Location:** `db.get_orders()`, `db.get_rate_list()` — no LIMIT/OFFSET.  
**Recommendation:** Add pagination with "Load More" button or infinite scroll.

---

## Flet 0.85 Framework Bugs (External)

### F1. `ft.ListView` Swallows Click Events
**Workaround:** Use `ft.Column(scroll=ft.ScrollMode.AUTO)` instead of `ft.ListView` for interactive content.

### F2. `ft.Card` Blocks Touch Propagation
**Workaround:** Use `ft.Container` with border/shadow styling.

### F3. FAB with `alignment` Expands and Blocks Touches
**Workaround:** Position FAB using `right=16, bottom=16` in `ft.Stack`:
```python
ft.Stack([
    body,
    ft.Container(content=fab, right=16, bottom=16),
])
```

### F4. `ft.Column` Does Not Accept `padding` Parameter
**Workaround:** Wrap in `ft.Container(padding=...)`.

---

## Performance Issues

### P1. Full Re-render on Every Navigation
**Impact:** Entire page is rebuilt from scratch on every `go()` call. No widget reuse.  
**Symptom:** Slight flicker on navigation, especially on slower Android devices.  
**Mitigation:** Keep views lightweight. Avoid heavy DB calls in view functions.

### P2. N+1 Query in Home View
**Impact:** For each order in the list, `db.get_order_items(order_id)` is called separately.  
**Location:** `view_home()` — iterates over all orders and fetches items for each.  
**Fix:** Add a batch query or join in Supabase.

### P3. Image Downloads Block UI During Sync
**Impact:** The sync operation downloads images sequentially, blocking the UI thread.  
**Location:** `cache.sync_all()` — synchronous httpx calls in a loop.  
**Fix:** Use async httpx or run sync in a background thread.
