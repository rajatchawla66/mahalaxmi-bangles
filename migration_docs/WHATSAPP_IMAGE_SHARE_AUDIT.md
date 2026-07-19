# WhatsApp Catalogue Image Share — Implementation Audit

> **Verdict: Feasible ✅** — The codebase has all the foundations needed. No architectural blockers.

---

## 1. Feasibility Verdict

**Feasible with low risk.** Every required primitive already exists:

| Primitive | Status | Location |
|-----------|--------|----------|
| Product image URLs in DB | ✅ | `rate_list.image_url` column |
| Image download from URL | ✅ | `OrderPdfService._downloadImage()` — HTTP with 5s timeout |
| Image decode/resize/encode | ✅ | `ImageProcessor.processImage()` — EXIF fix, resize, JPEG encode |
| Image compression utility | ✅ | `ImageProcessor` + `OrderPdfService._compressImage()` |
| Crop pipeline (4:5 portrait) | ✅ | `CropImageDialog` + `ImagePolicy` |
| Supabase Storage upload | ✅ | `StorageService` — `product-images` bucket |
| Multi-item selection UI | ⚠️ Partial | Admin catalogue has item cards but no multi-select mode |
| Canvas image compositing | ⚠️ Needs new code | No existing canvas-based card generator |
| Share images via Android sheet | ❌ Needs new package | Only `printing.sharePdf()` exists; no `share_plus` |
| Temp file storage | ❌ Needs new package | No `path_provider` dependency |

**Gap:** ~100-150 lines of new Dart code + 2 new package dependencies (`share_plus`, `path_provider`).

---

## 2. Recommended First Version

**Option C — Hybrid with a default** (recommended over pure A or pure B):

| Selected Items | Output Format | Rationale |
|----------------|---------------|-----------|
| 1–3 | One card per product (individual images) | Larger product visibility, easy forwarding |
| 4+ | Collage with 2 or 4 products per page | Fewer shares, paginated to keep images legible |
| Any | Allow admin to toggle "Individual" vs "Collage" | Power-user flexibility |

### Why not pure options

- **Option A (one per product):** 20 items → 20 separate shares, annoying to mass-send.
- **Option B (collage only):** 1 product alone gets lost inside a 4-up grid. Unclear what the share is for.
- **Option C:** Best of both. Default is smart, admin can override.

---

## 3. Recommended Output Format

### Image spec (single card)

| Property | Value |
|----------|-------|
| Aspect ratio | **4:5 portrait** (1080×1350) — matches existing `ImagePolicy.productAspectRatio` |
| Format | **JPEG** at **85% quality** |
| File size target | < 200 KB per card (survives WhatsApp compression well) |
| Orientation | Portrait (mobile-optimized) |

### Image spec (collage — 2-up or 4-up)

| Property | Value |
|----------|-------|
| Aspect ratio | 4:5 portrait (1080×1350) |
| Layout | 2 columns × 1 row (2-up) or 2×2 grid (4-up) |
| Format | JPEG at 82% quality |
| File size target | < 350 KB per collage page |

### Why JPEG over PNG

WhatsApp applies its own compression to PNGs too. JPEG at 85% produces:
- Sharper text than WhatsApp-compressed PNG (which blurs edges)
- 3-5× smaller file size
- Faster generation and share
- The `image` package already handles JPEG encoding (`ImageProcessor` uses `encodeJpg`)

### Layout design (single card)

```
┌─────────────────────────┐
│                         │
│                         │
│    PRODUCT IMAGE        │  ← Large, 4:5 crop, fills 70% of card height
│    (1080×945)           │
│                         │
│                         │
├─────────────────────────┤
│                         │
│   Item: BR-045         │  ← Bold item number
│   ₹ 1,250 /set         │  ← Rate, large font, Maroon color
│   Gold, Wedding        │  ← Tags (small, grey)
│                         │
│   ── Mahalaxmi Bangles ──│  ← Footer branding
│   Order on App 📱       │  ← CTA text
│                         │
└─────────────────────────┘
```

### Layout design (collage — 2-up)

```
┌───────────┬───────────┐
│           │           │
│  Image    │  Image    │
│           │           │
│  BR-045   │  BR-046   │
│  ₹1,250   │  ₹2,100   │
│           │           │
├───────────┴───────────┤
│   Mahalaxmi Bangles   │  ← Footer on each page
│   Order on App 📱     │
└───────────────────────┘
```

---

## 4. Recommended UI Entry Point

**Option 1 — Category Items Page** (recommended for v1)

Add to `CategoryItemsPage` (`mahalaxmi_admin/lib/features/catalogue/pages/category_items_page.dart`):

```
[Existing search bar...] [Sort ▼] [Filter ▼] [New: Share ▼]
┌─────────────────────────────────────────────────────────┐
│ ☐ Item card 1                              ₹1,250      │
│ ☐ Item card 2                              ₹2,100      │
│ ☐ Item card 3                                ₹800      │
│ ...                                                      │
└─────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│ 3 selected  [Generate Share Images ▶]    [Select All]  │
└─────────────────────────────────────────────────────────┘
```

### Why this fits

- All items of a category are already loaded (`adminCategoryItemsProvider`)
- Search/filter/sort already implemented — admin narrows down selection
- The existing `_ItemCard` widget can be wrapped with a `Checkbox` overlay
- A `FloatingActionButton` → `BottomAppBar` pattern for selected state
- No new route needed — can toggle selection mode inline

### Future options (v2+)

| Option | Use case |
|--------|----------|
| **Catalogue page** — multi-category select | Allow selecting from multiple categories at once |
| **Settings → Catalogue Share Tool** | Dedicated tool with preview & batch controls |
| **Customer-specific share** | Select items for a specific customer's price list |

---

## 5. Technical Approach

### Render strategy: Custom Canvas (recommended) vs Widget Screenshot

| Approach | Pros | Cons |
|----------|------|------|
| **Custom Canvas** (`dart:ui` `PictureRecorder` / `Canvas`) | Deterministic output, known dimensions, works in isolate, no widget tree dependency, no layout pass needed | Need to draw text/rects manually |
| **RepaintBoundary** → `toImage()` | Uses actual widget rendering, easy to prototype | Requires widget tree, 60fps frame-bound, can't run in isolate, fragile to theme changes |
| **`image` package composition** | Pure Dart, works in isolate, `img.drawImage()` API, existing dependency | Manual layout (no auto-text-wrapping) |

**Recommendation: `image` package composition** (pure Dart, already a dependency).

The `image` package (`mahalaxmi_shared/pubspec.yaml` already has `image: ^4.1.3`) can:
- `img.Image` create blank canvas of 1080×1350
- `img.drawImage()` composite product images
- `img.drawString()` / `img.drawText()` for item number, rate, branding
- `img.fillRect()` for backgrounds, borders
- `img.encodeJpg()` for output

This matches the existing pattern in `ImageProcessor` and `OrderPdfService._compressImage()`.

### Alternative: Widget screenshot with `RepaintBoundary`

If the card UI is complex and frequent layout changes are expected, a helper widget approach using `RepaintBoundary` + `RenderRepaintBoundary.toImage()` + `dart:ui` `Image.toByteData()` is valid for small batches (≤10 items). But for 20+ items, Canvas is safer.

**Decision:** Use `image` package composition for v1. Falls back gracefully on all devices and matches existing patterns.

### Data flow

```
Admin selects items in CategoryItemsPage
        │
        ▼
Collect List<RateItem> (already in memory from provider)
        │
        ▼
Call ShareCardGenerator.generate(List<RateItem>, options)
        │
        ├─ For each item: download image via http.get(url)
        │      │
        │      └─ On failure: use grey placeholder (same as OrderPdfService pattern)
        │
        ├─ For each output page (1-per-item or collage):
        │      │
        │      ├─ img.Image canvas = img.Image(1080, 1350)
        │      ├─ Fill background (white / cream)
        │      ├─ Draw product image (resized & positioned)
        │      ├─ Draw text: item number, rate, tags
        │      ├─ Draw branding footer
        │      └─ img.encodeJpg(canvas, quality: 85)
        │
        ├─ Write each JPEG to temp directory (path_provider)
        │
        └─ Share via share_plus: Share.shareXFiles([filePaths...])
```

---

## 6. Required Packages

| Package | Version | Purpose | Currently present? |
|---------|---------|---------|-------------------|
| `share_plus` | ^10.0+ | Share image files via Android share sheet / WhatsApp | ❌ **Needs adding** |
| `path_provider` | ^2.1.0 | Get temp directory for generated images | ❌ **Needs adding** |
| `http` | ^1.1.0 | Download product images from Supabase URLs | ✅ Already in `mahalaxmi_shared` |
| `image` | ^4.1.3 | Decode, composite, resize, encode images | ✅ Already in `mahalaxmi_shared` |

### Where to add

- `share_plus` → `mahalaxmi_admin/pubspec.yaml` (only admin needs to share)
- `path_provider` → `mahalaxmi_admin/pubspec.yaml` (or `mahalaxmi_shared` if the generator lives in shared)

Both are mature, well-maintained packages with zero native setup on Android (no manifest changes needed for basic file sharing).

---

## 7. Data Fields Needed

| Field | Source | Display | Required? |
|-------|--------|---------|-----------|
| `itemNumber` | `RateItem.itemNumber` | Card heading | ✅ Required |
| `sellingPrice` | `RateItem.sellingPrice` | Rate display | ✅ Required |
| `imageUrl` | `RateItem.imageUrl` | Product image | ⚠️ Falls back to placeholder |
| `category` | `RateItem.category` | Optional subtitle | Optional |
| `tags` | `RateItem.tags` | Context chips | Optional |
| `subCategory` | `RateItem.subCategory` | Extra detail | Optional |

### Business rules for rate display

1. **Which field is the rate?** `sellingPrice` — matches customer app display.
2. **Zero-price items?** Exclude from selection by default. Show warning. Admin can override to include (they may want to share "Call for price" items).
3. **Hidden items (`isAvailable == false`)?** Exclude by default. Admin can override.
4. **Rate format:** `₹ {amount}` — matches app's existing customer price format. No change needed.
5. **Per set/per item?** The price is `sellingPrice` per unit as stored. Display `₹ X,XXX` without suffix (context is shared catalogue card).

---

## 8. Image Size / Quality Recommendation

### For individual cards (recommended default)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Canvas | 1080×1350 px | Matches `ImagePolicy.productOutputWidth/Height` |
| Image area | 1080×945 px (top 70%) | Leaves room for text + branding |
| Text area | 1080×405 px (bottom 30%) | Item number, price, tags, footer |
| JPEG quality | 85 | Balances size vs. WhatsApp re-compression |
| Expected file size | 120-180 KB | Under WhatsApp's ~300 KB perceptual compression limit |

### For collage (2-up or 4-up)

| Parameter | Value |
|-----------|-------|
| Canvas | 1080×1350 px |
| Per product cell | 540×540 (2-up) or 540×337 (4-up) |
| Image within cell | Fills cell width, height proportional |
| JPEG quality | 82 |
| Expected file size | 200-350 KB |

### WhatsApp compression behavior

- WhatsApp compresses images to ~920px width typically
- Our canvas is 1080px → WhatsApp will downscale slightly
- **Text at ≥24px on 1080px canvas** will survive at ~20px after compression — still readable
- JPEG at 85% quality gives a good starting point before WhatsApp's additional compression
- **Avoid small text** (<18px on 1080px canvas) — it will blur after WhatsApp compression
- Use bold weight for item number and price

### PNG vs JPEG verdict

**JPEG at 85% quality.** Rationale:
- `image` package has optimized `encodeJpg()` with quality control
- `encodePng()` is lossless but produces 2-4× larger files
- WhatsApp compresses both, but JPEG artifacts are more predictable
- Text can be rendered sharp by using high-contrast colors (dark text on white/cream background)

---

## 9. Step-by-Step Implementation Plan

### Phase 1 — Foundation (~2-3 hours)

**Step 1.1:** Add dependencies
- `share_plus: ^10.0.0` to `mahalaxmi_admin/pubspec.yaml`
- `path_provider: ^2.1.0` to `mahalaxmi_admin/pubspec.yaml`

**Step 1.2:** Create `ShareCardGenerator` service in `mahalaxmi_admin/lib/services/share_card_generator.dart`

```dart
class ShareCardResult {
  final List<File> generatedFiles;
  final int totalItems;
  final int failedImages;
}

class ShareCardGenerator {
  Future<ShareCardResult> generate({
    required List<RateItem> items,
    required ShareCardMode mode,   // individual | collage
    required int collageColumns,   // 1 (individual), 2, or 4
  }) async {
    // 1. Download all images concurrently (http.get)
    // 2. For each page: composite using img package
    // 3. Save each page to temp dir (path_provider)
    // 4. Return list of files
  }
}
```

### Phase 2 — Card Layouts (~3-4 hours)

**Step 2.1:** Implement single-item card layout
- White background with rounded corners (simulated with fillRect)
- Product image in top 70%
- Item number (bold, 28px)
- Rate (₹ format, 36px, maroon color)
- Tags if present (small, grey)
- Footer: "Mahalaxmi Bangles" + "Order on App" text

**Step 2.2:** Implement collage card layout (2-up)
- 2 cells side by side
- Each cell: image top, item number + rate below
- Footer branding at page bottom

**Step 2.3:** Implement collage card layout (4-up)
- 2×2 grid
- Simplified per-cell: image + item number + rate
- Footer branding at page bottom

**Step 2.4:** Handle missing images
- Draw a grey placeholder (same as PDF fallback)
- Track failed downloads per item (include in `ShareCardResult`)

### Phase 3 — Admin UI (~3-4 hours)

**Step 3.1:** Add multi-select state to `CategoryItemsPage`
- Toggle button in AppBar to enter selection mode
- `Set<String> _selectedItemNumbers` state
- Checkbox overlay on each `_ItemCard`
- Bottom bar showing count + action button

**Step 3.2:** Add share action bottom sheet
- "Generate Share Images" button in bottom bar
- On tap: show bottom sheet with options:
  - Mode: Individual / Collage
  - Items per page (if collage): 2 or 4
  - Include zero-price items? toggle (if any selected)
  - "Generate" button

**Step 3.3:** Generation + preview dialog
- Show a `CircularProgressIndicator` with "Generating X images..."
- On complete: show preview dialog with thumbnails
- "Share All" button → `Share.shareXFiles()`

**Step 3.4:** Cleanup generated files after share or page dispose
- Delete temp files from temp directory

### Phase 4 — Polish & Edge Cases (~2 hours)

- Handle 0 items selected (disable button)
- Handle all images failed (show error, don't share empty)
- Handle permission denial (show snackbar)
- Handle very large selection (20+): batch generation, show per-page progress
- Add "Select All" / "Deselect All" in selection mode
- Verify dark theme compatibility (if admin uses dark mode)
- Write widget tests for selection mode

### Estimated Total Effort: **10-13 hours**

---

## 10. Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Memory crash with 20+ images** | Medium | High | Download sequentially in batches of 5; dispose each decoded image after compositing; use `Uint8List` sparingly |
| **Broken image URLs** | Medium | Low | Grey placeholder fallback (same pattern as `OrderPdfService`) |
| **WhatsApp quality loss makes text unreadable** | Low | Medium | Test with real WhatsApp; use bold 28px+ for critical text; high contrast (dark on white) |
| **Slow generation on low-end Android** | Medium | Medium | Show progress indicator per item; use isolate (compute()) for off-main-thread image processing |
| **Old legacy images with wrong aspect ratios** | High | Medium | Crop to 4:5 center inside the card using `img.copyCrop()` — same logic as existing crop pipeline |
| **Generated files not cleaned up** | Medium | Low | Delete temp dir on app start; use `Directory(await getTemporaryDirectory())..delete(recursive: true)` for old files |
| **Share intent not finding WhatsApp** | Low | Low | Android share sheet shows all compatible apps; WhatsApp will be listed |
| **CORS issues if future web/PWA** | Low (future) | Medium | All images served from Supabase Storage which supports CORS; no web embedding planned yet |
| **Admin accidentally shares unpublished items** | Low | High | Warn if any selected item has `isAvailable == false` or `sellingPrice == 0`; require confirmation |

---

## 11. Manual Testing Plan

### Pre-flight checklist
- [ ] `flutter pub get` succeeds in admin app
- [ ] `flutter analyze mahalaxmi_admin` — 0 errors
- [ ] Build succeeds: `flutter build apk --debug`

### Functional tests

| # | Test | Expected | Pass |
|---|------|----------|------|
| 1 | Open admin Catalogue → tap a category | Category items load with cards | |
| 2 | Tap share button in AppBar | Selection mode activates, checkboxes appear | |
| 3 | Select 1 item → tap "Generate" | Single share card generated (1080×1350) | |
| 4 | Select 3 items → generate individual | 3 separate JPEG files, each with one product | |
| 5 | Select 5 items → generate (auto-collage) | 2 collage pages (4+1 or 3+2, depending on algorithm) | |
| 6 | Select items with zero price (with override) | Warning shown, cards still generated | |
| 7 | Select items with no image | Grey placeholder instead of product image | |
| 8 | Tap "Share All" after generation | Android share sheet opens with generated images | |
| 9 | Share to WhatsApp from share sheet | Images arrive in WhatsApp with correct layout | |
| 10 | Text readability after WhatsApp send | Item number and rate are readable, not blurry | |
| 11 | Select 0 items → tap generate | Button disabled or shows "Select items first" | |
| 12 | Exit select mode without sharing | Checkboxes disappear, normal mode restored | |
| 13 | Kill app, reopen, check temp dir | Temp files cleaned up | |
| 14 | Toggle between Individual and Collage mode | Different layouts generated correctly | |
| 15 | Rapidly generate twice | Second generation overwrites/cleans up first set | |

### Regression tests

| # | Test | Expected | Pass |
|---|------|----------|------|
| 16 | Normal item card tap still opens edit page | Selection mode off → tap → edit | |
| 17 | Search/filter still works in selection mode | Search narrows items, checkbox state preserved | |
| 18 | Add item FAB still works | FAB navigates to add page | |
| 19 | Pull-to-refresh still works | Items reload, selection cleared | |
| 20 | Back button during selection mode | Selection cleared, exits selection mode | |

---

## Appendix: Code References

| Component | File | Uses |
|-----------|------|------|
| Image download | `mahalaxmi_shared/lib/services/order_pdf_service.dart:41-51` | `_downloadImage()` pattern to reuse |
| Image compression | `mahalaxmi_shared/lib/utils/image_processor.dart` | `processImage()` resize + JPEG encode |
| Image resize | `mahalaxmi_shared/lib/services/order_pdf_service.dart:54-71` | `_compressImage()` pattern |
| Image policy | `mahalaxmi_shared/lib/constants/image_policy.dart` | `productAspectRatio`, output dimensions |
| Item data model | `mahalaxmi_shared/lib/models/item.dart` | `RateItem` — all fields |
| Category items page | `mahalaxmi_admin/lib/features/catalogue/pages/category_items_page.dart` | UI entry point for v1 |
| Admin catalogue provider | `mahalaxmi_admin/lib/features/catalogue/providers/admin_catalogue_provider.dart` | `adminCategoryItemsProvider` |
| Storage upload | `mahalaxmi_admin/lib/services/storage_service.dart` | Supabase bucket reference |
| PDF image fallback | `mahalaxmi_shared/lib/services/order_pdf_service.dart:260-291` | Grey "No Image" placeholder pattern |
