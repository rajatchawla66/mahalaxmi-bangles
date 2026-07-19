# Image Loading & Caching Audit — 500+ Product Catalogue

## 1. Current Image Loading Summary

### Call Sites (12 total — all use bare `Image.network()`)

| # | Location | What loads | Resize params | Cache |
|---|----------|-----------|--------------|-------|
| 1 | `dashboard_page.dart:211` | Category cover (900×1200) | None | ❌ |
| 2 | `category_page.dart:264` | Product image (1080×1350) | None | ❌ |
| 3 | `item_detail_page.dart:154` | Product image preview | None | ❌ |
| 4 | `item_detail_page.dart:168` | Product image fullscreen | None | ❌ |
| 5 | `category_items_page.dart:636` | Product thumbnail (56×70) | None | ❌ |
| 6 | `catalogue_page.dart:237` | Category cover thumb (54×72) | None | ❌ |
| 7 | `item_edit_page.dart:363` | Product image preview | None | ❌ |
| 8 | `missing_price_items_page.dart:272` | Product thumbnail (56×70) | None | ❌ |
| 9 | `manage_categories_page.dart:135` | Category cover thumb (48×48) | None | ❌ |
| 10 | `manage_categories_page.dart:383` | Category cover edit dialog | None | ❌ |
| 11 | `admin_item_picker_sheet.dart:337` | Category cover (54×72) | None | ❌ |
| 12 | `admin_item_picker_sheet.dart:387` | Product image (44×55) | None | ❌ |

**Every single image** re-downloads at full resolution on every navigation, with no disk caching, no memory sizing, and no pre-warming.

---

## 2. Question-by-Question Answers

### Q1: Does dashboard load only category covers or also product images?
**Only category covers.** Dashboard shows a 2-column grid of 3:4 category cover images (900×1200 px). Product images are loaded only when the user taps into a category.

### Q2: Does category page fetch only selected category items?
**Yes — effectively.** `customerItemsByCategoryProvider` calls `getCustomerItemsByCategory(categoryName)` which fetches only items matching that category name. However, **all matching items are fetched at once** — no pagination/limit. For a category with 200+ products, all 200+ image URLs are loaded into a single list view.

### Q3: Are images cached across back navigation?
**No.** `Image.network()` has zero disk persistence. Flutter's `ImageCache` (in-memory only, default 1000 entries or ~50MB) holds decoded image buffers in RAM. Navigating back and re-entering will re-download if the memory cache was evicted. App restart clears everything.

### Q4: Are images cached after app close/reopen?
**No.** Nothing persists to disk. Every cold start is a full re-download of every image.

### Q5: Is Flutter's default Image.network cache enough?
**No, not for 500+ products.** Problems:
- **Default ImageCache**: ~1000 entries or ~50MB (whichever hits first). Each 1080×1350 image at 32-bit color is ~5.6MB in decoded RAM. Even 10 images can consume 56MB. With 50 items visible during a session, you'd exceed 100MB decoded RAM.
- **No disk cache**: Every navigation or cold start re-fetches everything from Supabase Storage, counting toward cached egress.
- **No `cacheWidth`/`cacheHeight`**: Images are decoded at full 1080×1350 resolution even when displayed at 56×70 in a list thumbnail.
- **No stale-while-revalidate**: No graceful offline/retry behavior.

### Q6: Should cached_network_image / flutter_cache_manager be added?
**Yes — strongly recommended for the customer app (and optionally admin).**

`cached_network_image` + `flutter_cache_manager` provides:
- **Disk cache**: Downloaded image bytes saved to local file system. Survives app restart. Reduces Supabase egress by 90%+ for repeat views.
- **Memory cache with sizing**: `cached_network_image` integrates with Flutter's `ImageCache` but with `cacheWidth`/`cacheHeight` to decode only the needed resolution.
- **Placeholder/error builders**: Better UX during loading (already has gradient fallback, but caching improves load-in speed).
- **Auto-eviction**: Manages disk usage within a configurable limit (default 200MB from `DefaultCacheManager`).

**Admin app** benefit is lower (admin re-views the same images less frequently), but still worthwhile for the catalogue list view.

### Q7: Should we generate a 720×900 feed image in addition to 1080×1350 full image?
**Yes — recommended.** Two-tier image strategy:

| Size | Resolution | Use Case | Quality |
|------|-----------|----------|---------|
| **Full** | 1080×1350 | Item detail page, fullscreen zoom, PDF share, WhatsApp share | 90% JPEG |
| **Feed** | 540×675 (or 720×900) | Category feed list thumbnails, admin thumbnails | 85% JPEG |

The feed image is roughly 1/4 the pixel count of the full image, meaning ~1/4 the download size (~50-80KB vs ~200-300KB).

**Naming convention:** `items/<slug>.jpg` (full) and `items/<slug>_feed.jpg` (feed). The repo/service falls back to full if feed missing.

**Rollout:** Only for new uploads. Old images use full image for both feed and detail (no migration needed — the UI falls back gracefully).

**Actual impact:** For a category with 50 products loading 720×900 feed images (~80KB each) instead of 1080×1350 full images (~250KB each), the payload drops from ~12.5MB to ~4MB — a **68% reduction** in per-navigation download.

### Q8: Should category item list use pagination/lazy loading?
**Yes — recommended for categories with 100+ items.**

Currently `getCustomerItemsByCategory()` fetches ALL items. With pagination:
- Fetch first page (e.g., 30 items) → display in list view
- As user scrolls near the bottom, fetch next page
- `ScrollController` + `ScrollNotification` or `ListView.builder` with a load-more trigger

Pagination reduces:
- Initial load time
- Memory pressure from decoded images
- Supabase egress (only fetch what's visible)

**Implementation note:** `postgrest-dart` supports `.range(start, end)` for offset-based pagination.

### Q9: What DB/schema or path changes are needed?

| Change | Type | Effort | Impact |
|--------|------|--------|--------|
| `cached_network_image` dependency | pubspec.yaml | Trivial | — |
| Add `_feed.jpg` to upload pipeline in `storage_service.dart` | Code change | Small | New uploads only |
| Feed URL lookup (e.g., suffix convention in code, not DB) | Code convention | Trivial | No schema change |
| Pagination with `.range()` in item repository | Code change | Small | Reduces payload |
| `cacheWidth`/`cacheHeight` on `CachedNetworkImage` | Code change | Trivial | Reduces decoded memory |

**No DB schema or table changes required.** Feed images are addressed by a URL convention (`_feed.jpg` suffix), not a separate DB column.

### Q10: How to handle old existing images?
**Three-tier fallback strategy (no migration):**

1. First, try `items/<slug>_feed.jpg` (new convention)
2. If 404, fall back to `items/<slug>.jpg` (legacy) decoded at a smaller display size via `cacheWidth`/`cacheHeight`
3. If 404, show error placeholder

This means old images don't need to be migrated or regenerated. Over time, as items are edited and re-uploaded, they naturally get feed images. The `cacheWidth`/`cacheHeight` on the display side ensures legacy images are still decoded at a reasonable size for thumbnails.

---

## 3. Recommended Implementation (Phased)

### Phase 1 — Instant win (no new images needed)

| Change | Files | Egress Impact |
|--------|-------|--------------|
| Replace `Image.network` with `CachedNetworkImage` in customer app | `dashboard_page.dart`, `category_page.dart`, `item_detail_page.dart` | **-90% repeat views** |
| Add `cacheWidth`/`cacheHeight` to thumbnails | `category_page.dart` (feed list), all admin thumbnails | **-75% decoded memory** |
| Configure `DefaultCacheManager` max size (200MB) | `main.dart` | Prevents unbounded disk growth |

**No schema changes. No storage changes. No upload pipeline changes.**

Customer app only: Add `cached_network_image` to `mahalaxmi_customer/pubspec.yaml`.

Admin app: Lower priority, but same benefit if added.

### Phase 2 — Feed image generation

| Change | Files | Egress Impact |
|--------|-------|--------------|
| After upload in `storage_service.dart`, also generate and upload `<slug>_feed.jpg` at 720×900 (or 540×675) | `storage_service.dart` | **-68% first-view payload** |
| Add `getProductFeedImageUrl(String slug)` helper that appends `_feed.jpg` | `image_policy.dart` or utility | — |
| In `category_page.dart` feed list, load `feed` variant; fall back to full with `cacheWidth` | `category_page.dart` | See above |

**No DB schema changes.**

### Phase 3 — Pagination (future)

| Change | Files | Egress Impact |
|--------|-------|--------------|
| Add `.range(offset, limit)` to `getCustomerItemsByCategory()` | `item_repository.dart` | **-80% for deep catalogs** |
| Add scroll controller + load-more in `category_page.dart` | `category_page.dart` | — |
| Consider Supabase `count=exact` for total | `item_repository.dart` | — |

---

## 4. Egress Reduction Estimates (Customer Only)

| Scenario | Current (per session) | Phase 1 | Phase 1+2 | Phase 1+2+3 |
|----------|----------------------|---------|-----------|-------------|
| Browse dashboard (8 covers) | 8 × 250KB = 2MB | +disk cache: ~200KB* | ~200KB* | ~200KB* |
| Open 1 category (50 items feed) | 50 × 250KB = 12.5MB | 12.5MB first, ~1.25MB repeat | 50 × 80KB = 4MB | 30 × 80KB = 2.4MB |
| View 5 item details | 5 × 250KB = 1.25MB | ~125KB repeat | ~125KB repeat | ~125KB repeat |
| **Total first session** | **~15.75MB** | **~15.75MB** | **~6.4MB** | **~4.8MB** |
| **Total repeat session** | **~15.75MB** | **~1.6MB** | **~0.7MB** | **~0.7MB** |

*Dashboard covers are 900×1200 → ~250KB each. With disk cache, repeat views cost ~0 egress.

---

## 5. Risk & Mitigation

| Risk | Mitigation |
|------|-----------|
| `cached_network_image` adds 2 deps, ~50KB APK size | Acceptable. Most Flutter apps use this package. |
| Feed images double storage usage | Feed image is 1/4 the pixels at slightly lower quality — roughly 1/3 the file size. Increase is ~33% more storage, offset by drastic egress reduction. |
| Cache invalidation when image is replaced | `CachedNetworkImage` respects `cacheKey` based on URL. If image is updated (same URL, new bytes), HTTP cache headers (Cache-Control: no-cache) or force-refresh via `cacheManager.emptyCache()` on repo refresh. |
| Supabase Storage doesn't auto-delete old feed images | Acceptable. Orphaned feed images are tiny; can clean via storage admin later. |
| Pagination breaks existing category screen layout | The current `ListView.separated` is compatible. Only need to add scroll callback. |

---

## 6. Recommended Immediate Action

| Priority | Action | Why now |
|----------|--------|---------|
| **P0** | Add `cached_network_image` to customer app | Zero code risk, instant egress reduction on repeat views |
| **P1** | Add `cacheWidth`/`cacheHeight` to all `CachedNetworkImage` calls in customer app | Drastically reduces decoded memory (images decoded at display size, not 1080×1350) |
| **P2** | Generate feed image (540×675) alongside full image on upload | Reduces first-view payload by 68% |
| **P3** | Pagination via `.range()` on category items | Prepares for 500+ product scaling |

Do not implement yet — this report is for review. Only the P0 `cached_network_image` change is simple enough to implement immediately.
