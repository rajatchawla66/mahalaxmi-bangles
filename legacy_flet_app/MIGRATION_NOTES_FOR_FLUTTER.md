# MIGRATION NOTES FOR FLUTTER — Critical Knowledge Transfer

> **Target Architecture:** Flutter (Dart) + Supabase + Riverpod + Isar (APK) + GoRouter
> Two projects: `mahalaxmi_admin` (APK) + `mahalaxmi_customer` (APK + Web/PWA)
> One shared package: `mahalaxmi_shared` (models, repos, providers)
> See ARCHITECTURE_OVERVIEW.md for current Flet architecture.

## A. Supabase Layer — Easiest Port

The current `db.py` uses raw REST via httpx. Flutter's `supabase-dart` / `supabase-flutter` packages are official and well-maintained.

### Mapping

```
Current Flet (db.py)              Flutter (supabase-flutter)
─────────────────────             ──────────────────────────
_get("rate_list", params)         supabase.from("rate_list").select(params)
_post("orders", data)             supabase.from("orders").insert(data)
_patch("rate_list", data, id)     supabase.from("rate_list").update(data).eq("id", id)
_delete("tag_master", id)         supabase.from("tag_master").delete().eq("id", id)
_get("tag_master", cs...)         supabase.from("tag_master").select().contains("tags", [tag])
```

### Offline

```
Current (cache.py)                Flutter
─────────────────                 ──────
JSON file dump/load               Isar database (typed, indexed)
catalog.json / orders.json        Isar collections: Item, Order
sync_meta.json                    Isar SyncMeta collection
```

**Critical:** The `tags` JSONB column on rate_list maps 1:1 to a Dart `List<String>` field. The `categories` JSONB on tag_master also maps to `List<String>`.

## B. Navigation Patterns

| Current (Flet) | Flutter Equivalent |
|----------------|-------------------|
| `page.go("customer_items")` | GoRouter: `context.go("/customer/items")` |
| `go_back()` with BACK_MAP | GoRouter: `context.pop()` |
| `page.views[interceptor, content]` | GoRouter ShellRoute for persistent UI |
| `state["current_page"]` | GoRouter's `state.uri` or Riverpod state |
| BACK_MAP dict | GoRouter redirect + custom logic |

## C. State Management

| Current (Flet page.state) | Flutter (Riverpod) |
|--------------------------|-------------------|
| `state["cart"]` | `cartProvider` (StateNotifier) |
| `state["customer_selected_tag"]` | `selectedTagProvider` (StateProvider) |
| `state["customer_category_cache"]` | `categoryItemsProvider` (FutureProvider.family) |
| `state["selected_tags"]` (edit form) | Local state in widget |
| `state["customer_cart"]` | `customerCartProvider` |

**Key Insight:** Riverpod's `FutureProvider.family` with parameter (category name) directly replaces the `customer_category_cache` dict pattern.

## D. Tag Filter Implementation — Already Designed

The P4 tag filter in `views/customer.py` (lines 532-650) was built with migration in mind:
- **No DB call** — tags come from loaded items
- **In-place filter** via `_rebuild_items()` — same pattern as Flutter's `setState()`
- **Factory functions** avoid closure bugs — same pattern as Dart closures
- **Horizontally scrollable** `Row(scroll=AUTO)` — direct Flutter equivalent

**Flutter equivalent:** `ListView.builder` with `filteredItems` computed from `selectedTag` + `allItems`.

## E. Flet-Specific Workarounds NOT Needed in Flutter

| Flet Workaround | Why Not Needed in Flutter |
|-----------------|---------------------------|
| `page.overlay.append(dlg)` | Flutter: `showDialog()` (native, no overlay issues) |
| No `page.dialog = dlg` | Flutter Dialogs are first-class |
| No `page.overlay.remove(dlg)` | Flutter: `Navigator.pop(context)` |
| `on_change` not `on_select` | Flutter Dropdown uses `onChanged` |
| No `ResponsiveRow` | Flutter: `LayoutBuilder` + `GridView` work properly |
| No `expand=True` inside Row | Flutter: `Expanded` widget works correctly |
| No `ft.ListTile.on_click` | Flutter: `ListTile.onTap` works reliably |
| RangeError in ListView | Flutter ListView.builder is robust |
| `connectivity_banner()` | Flutter: `connectivity_plus` package |
| `page.platform` detection | Flutter: `dart:io` Platform or `Theme.of(context).platform` |
| No `page.client_storage` | Flutter: `shared_preferences` package |
| Thread-based background work | Flutter: `Isolate` or `workmanager` plugin |
| No native share sheet | Flutter: `share_plus` plugin (multi-image) |
| No `Intent.ACTION_SEND_MULTIPLE` | Flutter: `share_plus` natively supports this |

## F. Critical Business Logic to Port

1. **`db.py`** — all Supabase REST calls (mechanical port, ~850 lines)
2. **`views/pricing.py:on_save_and_generate()`** — 5-step save with rollback logic (most complex business logic)
3. **`utils.py:resize_product_image()`** — image pipeline (reimplement in Dart with Image package)
4. **`views/customer.py:place_order()`** — cart -> order flow with validation
5. **`views/customer.py:_get_category_items()`** — per-category lazy cache pattern
6. **`views/settings.py:view_tag_master()`** — tag CRUD with multi-category chips
7. **`cache.py`** — offline sync (replace with Isar)

## G. Database Schema (Unchanged in Migration)

All tables, columns, RLS settings remain identical. The Flutter app uses the same Supabase project.

**Tables:** customers, categories, rate_list, orders, order_items, materials, cost_breakdown, item_materials, app_settings, tag_master

**Key columns in rate_list:** item_number, image_url, cost_price, selling_price, category, sub_category, has_sizes, has_color, is_available, margin_percent, status, tags (JSONB)

**Key columns in tag_master:** id, name, display_name, category (TEXT), is_active, categories (JSONB), created_at

## H. Migration Order (Recommended)

```
Phase 1: Shared package (5 days)
  - Dart models for all 10+ tables
  - Supabase repository ported from db.py
  - Riverpod providers for shared state

Phase 2: Customer APK (7 days)
  - PIN login -> Dashboard -> Catalogue -> Tag filter -> Item Detail -> Cart -> Order
  - Push notifications (FCM)
  - Isar offline cache

Phase 3: Admin APK (10 days)
  - All admin screens
  - Native plugins: camera, share_plus, workmanager
  - Full offline with Isar

Phase 4: Customer Web (3 days)
  - Same Flutter code as Phase 2
  - Web-safe renderer (html or canvaskit)
  - PWA manifest + service worker
  - iPhone testing
```

## I. Known Pitfalls to Avoid

1. **Don't use `dart:io` in shared package** — breaks web builds. Use `universal_io` or layer-separate.
2. **Isar doesn't support web** — use Drift (SQLite WASM) or localStorage for web offline.
3. **`share_plus` is APK-only** — guard with `if (!kIsWeb)` or use `url_launcher` for web sharing.
4. **CanvasKit vs HTML renderer** — test both on iPhone. HTML is lighter but has widget limitations.
5. **Supabase RLS** — currently disabled on tag_master. Re-enable with proper policies before production.
6. **GoRouter declarative routing** — different mental model from Flet's imperative `page.go()`. Plan routes upfront.
7. **Riverpod providers as state replacement** — `page.state` dict is easy but error-prone. Riverpod's compile-time safety is a net improvement.
