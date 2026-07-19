# FEATURE STATUS — Mahalaxmi Bangles Order Manager

## Legend

| Status | Meaning |
|--------|---------|
| ✅ Complete | Fully implemented and working |
| ⚠️ Partial | Implemented but has known issues or limitations |
| 🔲 Planned | Designed but not yet implemented |
| 💡 Idea | Discussed but no design exists |

---

## 1. Implemented Features (✅ Complete)

### 1.1 Role-Based Access
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Admin role selection | ✅ | `main.py` → `view_login()` | Simple button picker, no password |
| Labour role selection | ✅ | `main.py` → `view_login()` | Simple button picker, no password |
| Admin-only views hidden from labour | ✅ | `main.py` → `render()` | Rate list, costing, settings, FAB hidden |
| Price hiding for labour | ✅ | `main.py` → `view_home()`, `view_order_detail()` | Prices not shown to labour role |

### 1.2 Order Management
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Single-category order creation | ✅ | `main.py` → `view_order_form()` | Filter items by one category |
| Mixed-category order creation | ✅ | `main.py` → `view_order_form()` | Per-row category selection |
| Multi-item cart with add/remove | ✅ | `main.py` → `build_cart_row()` | Unique UID per row |
| Size-based quantities (2.2–2.10) | ✅ | `main.py` → `build_category_fields()` | +/- stepper UI |
| Single quantity input | ✅ | `main.py` → `build_category_fields()` | +/- stepper UI |
| Color selection with "Custom" option | ✅ | `main.py` → `_build_color_field()` | Dropdown + custom text field |
| Order validation before save | ✅ | `main.py` → `validate_order()` | Category-specific rules |
| Line total calculation | ✅ | `main.py` → `calculate_line_total()` | Per-item and grand total |
| Order summary with category grouping | ✅ | `main.py` → `build_order_summary()` | Groups, subtotals, grand total |
| Order list (home view) | ✅ | `main.py` → `view_home()` | Sorted by newest first |
| Order detail view | ✅ | `main.py` → `view_order_detail()` | Items grouped by category |
| Customer name + date + packing | ✅ | `main.py` → `view_order_form()` | Header fields |
| Additional info / notes | ✅ | `main.py` → `view_order_form()` | Free text field |

### 1.3 Rate List / Item Management
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Add new item | ✅ | `main.py` → `view_rate_list()` | Item number, category, prices, image |
| Edit existing item | ✅ | `main.py` → `view_rate_list()` | Auto-detect on item number input |
| Image upload from gallery/camera | ✅ | `main.py` → `pick_file()`, `take_photo()` | Via `ft.FilePicker` |
| Image upload to Supabase Storage | ✅ | `db.py` → `upload_image()` | Public bucket, upsert |
| Category assignment | ✅ | `main.py` → `view_rate_list()` | Dropdown with dynamic categories |
| Sub-category assignment | ✅ | `main.py` → `view_rate_list()` | Shows when category has sub-categories |
| Item availability toggle | ✅ | `main.py` → `view_rate_list()` | Switch control, persisted |
| has_sizes / has_color toggles | ✅ | `main.py` → `view_rate_list()` | Per-item property flags |
| Product catalogue view (Tab B) | ✅ | `main.py` → `render_catalogue()` | Grid with images, prices, badges |
| Edit from catalogue | ✅ | `main.py` → `make_edit_handler()` | Switches to Tab A with data populated |

### 1.4 Price Card Generation
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Desktop card generation (Pillow) | ✅ | `card_generator.py` | 1080×1080 JPEG with overlay |
| Android card generation (Cloudinary) | ✅ | `db.py` → `generate_price_card_url()` | URL-based text transformation |
| Card preview in rate list | ✅ | `main.py` → `view_rate_list()` | Shows generated card |
| Share card via WhatsApp | ✅ | `main.py` → `on_share_card()` | Deep link + gallery save |

### 1.5 Category Management
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| View all categories | ✅ | `main.py` → `view_manage_categories()` | With status badges |
| Add new category | ✅ | `main.py` → `view_manage_categories()` | Name, icon, color, description, subs, order_type |
| Activate/deactivate category | ✅ | `db.py` → `toggle_category_active()` | Soft delete |
| Delete category (if unused) | ✅ | `db.py` → `delete_category()` | Checks for items using it |
| Dynamic category loading | ✅ | `main.py` → `_load_categories_from_db()` | Fallback to hardcoded |
| Category icons and colors | ✅ | `main.py` → `_load_category_config()` | Mapped from string keys |
| Sub-categories (comma-separated) | ✅ | DB `categories.sub_categories` | Dynamic dropdown |

### 1.6 Costing Calculator
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Material master (CRUD) | ✅ | `main.py` → `view_settings()` | Add/delete materials with rates |
| Cost breakdown per item | ✅ | `main.py` → `view_costing()` | Add materials with quantities |
| Auto-calculate CP from materials | ✅ | `main.py` → `_recalculate()` | Sum of (qty × rate) + labour |
| Margin % → SP calculation | ✅ | `main.py` → `_recalculate()` | CP × (1 + margin/100) |
| Save pricing to rate_list | ✅ | `db.py` → `save_item_pricing()` | Updates CP, SP, margin, status |
| Labour cost setting | ✅ | `db.py` → `get_labour_cost()` | From app_settings |
| Default margin setting | ✅ | `db.py` → `get_default_margin()` | From app_settings |
| Load existing cost breakdown | ✅ | `db.py` → `get_cost_breakdown()` | Restores when item selected |

### 1.7 Sharing & Export
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Share catalog via WhatsApp | ✅ | `main.py` → `view_share_catalog()` | Multi-select + text message |
| Price card URLs in share message | ✅ | `main.py` → `share_whatsapp()` | Cloudinary URLs embedded |
| Karigar slip (artisan work order) | ✅ | `views/orders.py` → `view_karigar_slip()` | No prices, Hindi labels, images |
| Karigar slip WhatsApp share | ⚠️ | `views/orders.py` → `share_slip()` | Currently broken (Unknown Control: Source error) |
| Select all / clear all for sharing | ✅ | `main.py` → `view_share_catalog()` | Bulk selection controls |

### 1.8 Offline Cache
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Manual sync trigger | ✅ | `main.py` → `view_sync_page()` | "Sync Now" button |
| Download catalog to JSON | ✅ | `cache.py` → `sync_all()` | Items + categories |
| Download orders to JSON | ✅ | `cache.py` → `sync_all()` | Orders + line items |
| Download images locally | ✅ | `cache.py` → `sync_all()` | Skip if already cached |
| Progress callback during sync | ✅ | `cache.py` → `sync_all(on_progress)` | Progress bar in UI |
| Last sync time display | ✅ | `cache.py` → `get_last_sync_time()` | Human-readable |
| Read cached catalog | ✅ | `cache.py` → `get_cached_catalog()` | With local image paths |

### 1.9 Navigation & UX
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Bottom navigation bar (admin) | ✅ | `main.py` → `build_nav_bar()` | 5 tabs |
| Back navigation with history | ✅ | `main.py` → `go_back()` | Stack + BACK_MAP fallback |
| Android back button support | ✅ | `main.py` → `page.on_view_pop` | Calls go_back() |
| App bar with sync + menu | ✅ | `main.py` → `build_app_bar()` | Sync icon + popup menu |
| SnackBar notifications | ✅ | `main.py` → `snack()` | Color-coded, auto-dismiss |
| FAB for new order (admin only) | ✅ | `main.py` → `view_home()` | Positioned bottom-right |

### 1.10 Settings
| Feature | Status | Location | Notes |
|---------|--------|----------|-------|
| Default margin % setting | ✅ | `main.py` → `view_settings()` | Persisted to app_settings |
| Labour cost setting | ✅ | `main.py` → `view_settings()` | Persisted to app_settings |
| Shop name setting | ✅ | `main.py` → `view_settings()` | Used in price cards |
| Material master management | ✅ | `main.py` → `view_settings()` | Add/delete materials |
| Navigate to categories | ✅ | `main.py` → `view_settings()` | Link to manage_categories |
| Navigate to sync | ✅ | `main.py` → `view_settings()` | Link to sync_page |

---

## 2. Partially Implemented Features (⚠️)

### 2.1 Offline Mode
| Feature | Status | Issue |
|---------|--------|-------|
| Read cached data when offline | ⚠️ | Cache exists but UI doesn't automatically fall back to it |
| Offline write queue | ⚠️ | Not implemented — writes fail silently when offline |
| Auto-detect connectivity | ⚠️ | No connectivity check exists |

### 2.2 Price List View
| Feature | Status | Issue |
|---------|--------|-------|
| View priced items | ⚠️ | Works but not accessible from nav bar (no dedicated tab) |
| Filter/search in price list | ⚠️ | No search functionality |

### 2.3 Order Editing
| Feature | Status | Issue |
|---------|--------|-------|
| View order details | ✅ | Works |
| Edit existing order | ✅ | Added in home tab (`views/home.py`) |
| Delete order | ✅ | Added in home tab (`views/home.py`) |
| Order status tracking | ⚠️ | No status field (pending/in-progress/complete) |
| Order status tracking | ⚠️ | No status field (pending/in-progress/complete) |

---

## 3. Planned Features (🔲 Not Yet Implemented)

### 3.1 Proper Authentication
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| Email/password login via Supabase Auth | High | Replace role picker with real auth |
| JWT token-based API access | High | Replace anon key with user tokens |
| Row Level Security (RLS) policies | High | Admin: full CRUD, Labour: read orders only |
| Password reset flow | Medium | Via Supabase Auth email |
| Session persistence | Medium | Remember login across app restarts |

### 3.2 Real-Time Sync (Supabase Realtime)
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| Labour sees new orders instantly | High | Subscribe to orders table changes |
| Admin sees when labour views order | Low | Presence/read receipts |
| Live order status updates | Medium | WebSocket subscription |

### 3.3 Auto-Sync on App Start
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| Sync catalog on app launch | High | Background sync after login |
| Sync only changes (delta sync) | Medium | Use `updated_at` timestamps |
| Sync indicator in app bar | Low | Show when syncing |

### 3.4 Image Compression Before Upload
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| Resize images to max 1080px | Medium | Reduce upload size |
| JPEG quality reduction (80%) | Medium | Faster uploads on mobile data |
| Progressive JPEG for faster display | Low | Better UX on slow connections |

**Challenge:** Pillow doesn't work on Android. Options:
- Use Flet's built-in image manipulation (if available in future versions)
- Use Cloudinary's upload transformations to resize server-side
- Accept full-size uploads (current behavior)

### 3.5 Status Badges on Items
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| 🟡 Yellow badge for unpriced items | Medium | In Items tab catalogue |
| 🟢 Green badge for priced items | Medium | In Items tab catalogue |
| 🔴 Red badge for unavailable items | Medium | Already partially implemented |
| Filter by status in catalogue | Low | Dropdown filter |

### 3.6 Full Offline Mode
| Feature | Priority | Design Notes |
|---------|----------|--------------|
| Queue writes when offline | High | Local JSON queue |
| Sync queued writes when back online | High | Process queue on connectivity restore |
| Conflict resolution (last-write-wins) | Medium | Timestamp-based |
| Offline indicator in UI | Medium | Banner or icon |
| Optimistic UI updates | Low | Show changes immediately, sync later |

---

## 4. Feature Ideas (💡 No Design Yet)

### 4.1 Business Features
| Idea | Rationale |
|------|-----------|
| Order status workflow (Pending → In Progress → Ready → Delivered) | Track order lifecycle |
| Payment tracking (paid/unpaid/partial) | Business accounting |
| Customer database with order history | Repeat customer management |
| Inventory tracking (stock levels) | Know when to reorder materials |
| Monthly/weekly sales reports | Business analytics |
| Bulk order import (Excel/CSV) | For large wholesale orders |
| Order templates (repeat orders) | Common orders saved as templates |
| Discount/offer management | Seasonal pricing |

### 4.2 Technical Features
| Idea | Rationale |
|------|-----------|
| Push notifications (new order for labour) | Real-time alerts |
| Barcode/QR scanning for item lookup | Faster item selection |
| Voice input for order creation | Hands-free in workshop |
| PDF export for orders/invoices | Professional documentation |
| Multi-language support (Hindi/English) | Karigar slip already has Hindi |
| Dark mode | User preference |
| Tablet layout (responsive) | Larger screen optimization |
| Desktop admin panel (web) | Manage from computer |

### 4.3 Integration Ideas
| Idea | Rationale |
|------|-----------|
| WhatsApp Business API (automated messages) | Order confirmations |
| Google Sheets export | Familiar reporting tool |
| Tally/accounting software integration | Financial records |
| Delivery tracking integration | Logistics |

---

## 5. Feature Dependency Map

```
Proper Authentication (3.1)
    └── Required for: Real-Time Sync (3.2)
    └── Required for: Row Level Security
    └── Required for: Multi-device support

Auto-Sync (3.3)
    └── Depends on: Connectivity detection
    └── Enables: Full Offline Mode (3.6)

Full Offline Mode (3.6)
    └── Depends on: Auto-Sync (3.3)
    └── Depends on: Write queue implementation
    └── Depends on: Conflict resolution strategy

Image Compression (3.4)
    └── Blocked by: No Pillow on Android
    └── Alternative: Cloudinary server-side resize

Status Badges (3.5)
    └── Depends on: rate_list.status field (already exists)
    └── Independent feature, can be done anytime
```

---

## 6. Migration History

| Version | Change | Date |
|---------|--------|------|
| v0.1 | Streamlit web app (`app.py`) | Legacy |
| v0.2 | Migrated to Flet + SQLite (`db_sqlite_backup.py`) | — |
| v0.3 | Migrated to Supabase (`db.py` / `db_supabase.py`) | — |
| v0.4 | Added multi-category orders | — |
| v0.5 | Added costing calculator + material master | — |
| v0.6 | Added Cloudinary price cards (Android-compatible) | — |
| v0.7 | Added offline cache + sync | — |
| v0.8 | Added share catalog + category management | Current |

---

## 7. Recommended Next Steps (Priority Order)

1. **Fix `ft.Card` touch blocking** — Replace all `ft.Card` with `ft.Container` in interactive views
2. **Fix local image paths** — Run migration script to upload all local images to Supabase Storage
3. **Add proper authentication** — Supabase Auth with email/password
4. **Add auto-sync on app start** — Background catalog sync after login
5. **Add order status tracking** — Pending → In Progress → Ready → Delivered
6. **Add offline write queue** — Queue failed writes, sync when online
7. **Add image compression** — Use Cloudinary upload transformations
8. **Split `main.py`** — Extract views into separate modules for maintainability
