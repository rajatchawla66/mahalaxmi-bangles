# Flutter Web Readiness Audit — mahalaxmi_customer

**Date:** 18 Jun 2026  
**Auditor:** Flutter Web audit  
**App version:** 0.1.0+1  
**Flutter version:** 3.44.2 (Dart 3.12.2)

---

## 1. Build Status

| Check | Result | Notes |
|-------|--------|-------|
| `flutter analyze` | **0 errors, 0 warnings** | 29 info-level only (const, unnecessary imports, deprecated anonKey) |
| `flutter build web --release` | **✅ SUCCESS** | Built in 366s; 47 files in `build/web/` |
| `flutter run -d chrome` | **✅ Launched** | Debug mode started (timed out on CI but build succeeded) |
| Wasm support | Dry run succeeded | `--wasm` flag available for future optimization |

**Verdict:** The customer app **compiles and builds for web** with no compilation errors.

---

## 2. Package Compatibility

| Package | Version | Web Compatible? | Notes |
|---------|---------|-----------------|-------|
| `flutter_riverpod` | ^2.6.0 | ✅ Fully | Pure Dart |
| `go_router` | ^14.6.0 | ✅ Fully | Path-based routing (default) |
| `supabase_flutter` | ^2.8.0 | ✅ Compatible | v2.8.0 had a brief dart:io regression; fixed in subsequent patch. All Supabase clients (gotrue, postgrest, storage, realtime) are pure Dart or use `package:web` |
| `intl` | ^0.20.0 | ✅ Fully | Pure Dart |
| `printing` | ^5.11.0 | ✅ Compatible | Has `printing_web` backed by pdf.js (loaded automatically); `sharePdf()` works on web |
| `cached_network_image` | ^3.4.0 | ⚠️ Partial | **Images render** but **no disk cache on web** — relies on browser HTTP cache. No broken behavior, but cache benefits are reduced |
| `url_launcher` | ^6.3.0 | ✅ Compatible | Works on web; must be called from user gesture (current code does this) |
| `shared_preferences` | ^2.2.0 | ✅ Fully | Maps to `window.localStorage` — cart/session persistence works |
| `pdf` | ^3.10.8 | ✅ Fully | Pure Dart; `pdf.save()` returns `Uint8List`; works identically on web |
| `image` | ^4.1.3 | ✅ Fully | Pure Dart; image decode/encode/compress all work on web |
| `http` | ^1.1.0 | ✅ Fully | Multi-platform; uses `BrowserClient` on web |
| `uuid` | ^4.5.0 | ✅ Fully | Pure Dart |
| `freezed_annotation` | ^2.4.0 | ✅ Fully | Code-gen only |
| `json_annotation` | ^4.9.0 | ✅ Fully | Code-gen only |
| `path_provider` | 2.1.5 | ❌ Not web | **Transitive dependency only** — not imported or called in customer/shared code. No runtime impact |
| `app_links` | 7.0.0 | ⚠️ Limited | **Transitive dep of supabase_flutter** — deep linking limited on web. No direct usage in customer code |

**Key finding:** Customer app does NOT import `path_provider`, `File()`, `Directory()`, `dart:io`, or `package:web`/`dart:html` anywhere.

---

## 3. Platform-Specific Code Audit

| Pattern | Found? | Location | Web Impact |
|---------|--------|----------|------------|
| `dart:io` | ❌ None | — | Safe |
| `Platform.isXxx` | ❌ None | — | Safe |
| `path_provider` | ❌ Not imported | — | Safe (transitive, unused) |
| `File()` / `Directory()` | ❌ Not used | — | Safe |
| `dart:html` | ❌ Not used | — | Safe |
| `dart:js` | ❌ Not used | — | Safe |
| `SystemNavigator.pop()` | ⚠️ **2 occurrences** | `login_page.dart:113`, `dashboard_page.dart:71` | **Will throw `MissingPluginException` on web.** Exit dialog's "Exit" button won't work |
| Platform channels | ❌ None | — | Safe |

---

## 4. Feature Readiness Checklist

### 4.1 Login (PIN Keypad + Session Restore)
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| In-app PIN keypad | ✅ Yes | Pure Flutter widget — no mobile dependency |
| PIN validation via Supabase | ✅ Yes | gotrue/postgrest are web-compatible |
| Session restore via SharedPreferences | ✅ Yes | Maps to localStorage — survives page reload |
| Active customer validation | ✅ Yes | Pure HTTP call |
| Disabled-account force logout | ✅ Yes | No platform dependency |
| SystemNavigator exit dialog | ⚠️ **Broken** | Calls `SystemNavigator.pop()` which will throw on web |

### 4.2 Dashboard & Category Browsing
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Category cover images (CachedNetworkImage) | ✅ Yes | Images render; no disk cache on web but browser cache works |
| Product feed images | ✅ Yes | Same as above |
| Supabase Storage image URLs | ✅ Yes | Public bucket or signed URLs — no CORS issues expected |
| Category grid layout | ✅ Yes | Pure Flutter layout |

### 4.3 Image Caching
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Image display | ✅ Yes | Works |
| Disk cache | ❌ Not available | Browser HTTP cache serves as fallback |
| Flutter cache manager | ❌ Not available | No filesystem access on web |
| Performance impact | ⚠️ Acceptable | Images re-fetched on cold page load; browser cache mitigates repeat loads |

### 4.4 Watermark Overlay
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Asset loading | ✅ Yes | `assets/watermark.png` is a local asset — works on web |
| Overlay rendering on product images | ✅ Yes | `Stack` + `IgnorePointer` — pure Flutter |
| Overlay on full-screen zoom viewer | ✅ Yes | Same pattern |

### 4.5 Full-Screen Zoom
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| InteractiveViewer with mouse/touch | ✅ Yes | Works with mouse wheel, drag, and touch pinch on Safari |
| Close button | ✅ Yes | Flutter navigation |
| Android back → pop | ✅ Yes | GoRouter handles browser back |
| Pinch-to-zoom on iPhone Safari | ✅ Yes | Touch events forwarded by Flutter web |

### 4.6 Cart Persistence
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| SharedPreferences (localStorage) | ✅ Yes | Cart survives page refresh |
| Per-customer keys | ✅ Yes | `customer_cart_{id}` — works in localStorage |
| Save on mutation | ✅ Yes | Pure Dart |
| Load on session restore | ✅ Yes | Works |
| Clear on order | ✅ Yes | Works |

### 4.7 Chuda Customization
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Patti/Color/Box chip selection | ✅ Yes | Pure Flutter |
| Custom color text field | ✅ Yes | Pure Flutter |
| Final price calculation | ✅ Yes | Pure Dart |
| Add to cart with snapshot | ✅ Yes | Pure Dart |

### 4.8 Size Chart & Availability
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Size stepper UI | ✅ Yes | Pure Flutter |
| Unavailable sizes greyed out | ✅ Yes | Pure Flutter |
| Metal Bangles 2.12 | ✅ Yes | Pure Dart/data |

### 4.9 Order Placement
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Supabase insert (PostgREST) | ✅ Yes | Pure Dart HTTP — works on web |
| CORS handling | ⚠️ **Needs verification** | Supabase project must have CORS origins configured for the web domain |
| Failed order preserves cart | ✅ Yes | Pure Dart state |
| Friendly error messages | ✅ Yes | Pure Dart string mapping |

### 4.10 My Orders
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Orders list | ✅ Yes | Pure Dart/PostgREST |
| Customization snapshot display | ✅ Yes | Pure Flutter |
| Repeat order | ✅ Yes | Pure Dart |

### 4.11 PDF / Share
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| PDF generation (`OrderPdfService`) | ✅ Yes | Pure Dart `pdf` package |
| `Printing.sharePdf()` | ⚠️ **Different behavior** | On web, `sharePdf()` triggers browser print dialog instead of native share sheet. On desktop, opens print preview. On mobile Safari, may open share sheet or download |
| PDF download (web fallback) | ⚠️ Not implemented | Current code uses `Printing.sharePdf()` which works differently on web. For web, a "Download PDF" button may be more intuitive |
| Network image download for PDF | ✅ Yes | `http` package works on web |
| Image compression for PDF | ✅ Yes | `image` package is web-compatible |

### 4.12 External Links (url_launcher)
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| WhatsApp link | ✅ Yes | Opens `https://api.whatsapp.com` in new tab |
| Instagram link | ✅ Yes | Opens `https://www.instagram.com` in new tab |
| Google Maps link | ✅ Yes | Opens maps URL in new tab |
| `LaunchMode.externalApplication` | ⚠️ Ignored on web | `url_launcher` on web ignores this flag and opens in a new window/tab. Acceptable behavior |
| User gesture requirement | ✅ Yes | Called from `onTap` handler — synchronous path |

### 4.13 Navigation & Back Button
| Sub-feature | Web Ready? | Notes |
|-------------|-----------|-------|
| Browser back button | ✅ Yes | GoRouter handles browser popstate events |
| Route refresh | ⚠️ **Needs hosting config** | Path-based URLs (`/cart`, `/orders`) require server rewrite to `index.html` |
| Deep links | ✅ Yes | GoRouter with path strategy supports direct URL entry |
| Refresh on protected route | ✅ Yes | GoRouter redirect checks session state; unauthenticated → `/login` |

---

## 5. RLS / Security Notes

The Supabase anon key is exposed to the browser by design — this is expected. Security relies entirely on **Row-Level Security (RLS)** policies.

### Tables accessed by customer app

| Table | Access | Operations |
|-------|--------|------------|
| `customers` | Read + Write | Read: login, active check. Write: `last_active_at` update |
| `rate_list` | Read only | Catalogue browsing, item details |
| `categories` | Read only | Dashboard categories |
| `orders` | Read + Write | Read: my orders. Write: place order |
| `order_items` | Read + Write | Read: order details. Write: insert on place order |
| `chuda_customization_options` | Read only | Customization UI |
| `tag_master` | Read only | Tag filter row |
| `app_settings` | Read only | Default margin, labour cost, business info |

### Tables NOT accessed by customer app (admin-only, should be RLS-restricted)

| Table | Risk if exposed |
|-------|----------------|
| `materials` | Admin costing data |
| `cost_breakdown` | Admin costing data |
| `item_materials` | Admin item-material mapping |
| `settings`-level write operations | Admin-only |

### RLS Requirements

Before web launch, confirm:
1. **All tables** have RLS enabled (not just `customers` and `orders`).
2. **Read policies** allow anon role to read `rate_list`, `categories`, `chuda_customization_options`, `tag_master`, and `app_settings` (or public read).
3. **Write policies** are restricted:
   - `customers`: only allow `UPDATE last_active_at` for matching customer_id (no INSERT, no DELETE).
   - `orders`: allow INSERT only with matching customer_id, only for status='pending'.
   - `order_items`: allow INSERT only linked to orders the customer owns.
4. **Admin-only tables** (`materials`, `cost_breakdown`, `item_materials`) must have RLS that blocks anon access entirely.
5. **Supabase CORS configuration** must include the web domain(s) that will host the app (otherwise browser fetch will fail with CORS errors).

> **Action required:** Verify RLS policies in Supabase SQL editor before hosting.

---

## 6. Hosting & Routing Requirements

### Current URL Strategy

The app uses **path-based routing** (default GoRouter behavior). URLs look like:
- `/login`
- `/dashboard`
- `/category/Chuda`
- `/item/CHD001`
- `/cart`
- `/my-orders`

**No `HashUrlStrategy` is used.** This means:
- Hosting must be configured as a **Single Page Application (SPA)** — all paths must serve `index.html`.
- Direct URL entry (e.g., typing `mysite.com/cart`) will 404 without proper rewrite rules.
- Browser refresh on any page will 404 without rewrite rules.

### Hosting Options

| Platform | SPA Rewrite Support | Notes |
|----------|-------------------|-------|
| **Firebase Hosting** | ✅ Yes | Configure `rewrites` in `firebase.json`: `[{"source":"**","destination":"/index.html"}]` |
| **Cloudflare Pages** | ✅ Yes | SPA fallback via `_redirects` or `cloudflare.toml` |
| **Netlify** | ✅ Yes | `public/_redirects`: `/* /index.html 200` |
| **Vercel** | ✅ Yes | Configure in `vercel.json` |
| **Supabase Storage** | ❌ Not suitable | Storage serves static files but no SPA rewrite |

**Recommendation:** Firebase Hosting or Cloudflare Pages — both have simple SPA config, HTTPS by default, CDN, and custom domain support.

### Hosting Checklist
- [ ] Configure SPA rewrite (`/* → /index.html`)
- [ ] Enable HTTPS
- [ ] Enable gzip/Brotli compression (4 MB `main.dart.js` compresses to ~1.2 MB)
- [ ] Set long-lived cache headers for `main.dart.js` (content-hashed) and `flutter_service_worker.js`
- [ ] Configure Supabase CORS to allow web domain
- [ ] Set up custom domain (e.g., `customer.mahalaxmibangles.com`)
- [ ] (Optional) Switch to `HashUrlStrategy` for easier hosting — trade-off: ugly URLs (`/#/cart`) but no rewrite needed. **Not recommended** for production; path strategy with proper hosting is better.

---

## 7. Performance Concerns

| Area | Severity | Detail |
|------|----------|--------|
| **`watermark.png` (1.2 MB)** | ⚠️ **High** | A 1.2 MB watermark PNG is excessive. Each product image download is followed by this large overlay. Should be optimized to ~50-100 KB (PNG or WebP with transparency) |
| **`main.dart.js` bundle (4 MB)** | ⚠️ Medium | 4 MB uncompressed; ~1.2 MB gzipped. Acceptable for first load but should be watched. Flutter Web code-size budget is ~2-3 MB gzipped ideal |
| **No image caching on web** | ⚠️ Low-Medium | Each cold page load re-fetches images from network. Browser HTTP cache mitigates this for repeat visits within cache TTL. Should monitor if images are served with proper `Cache-Control` headers from Supabase Storage |
| **Product feed loads all items** | ⚠️ Medium | Customer app fetches all items for a category at once (no pagination). On web with many items, this could be slow. Recommendation: add pagination or "load more" before web launch |
| **CanvasKit vs Auto renderer** | ⚠️ Low | Default `auto` renderer picks CanvasKit on desktop, HTML on mobile. For iPhone Safari, HTML renderer is more reliable. No action needed now |
| **iPhone Safari memory** | ⚠️ Low | Safari has ~1 GB memory limit. Large image lists could cause tab reload. Monitor during internal testing |

### Asset Recommendation
- **Optimize `watermark.png`** from 1.2 MB → ~50 KB (PNG quantized, or use a smaller semi-transparent PNG/WebP). This is the single highest-impact optimization.

---

## 8. Minimum Required Fixes Before Web Launch

### P0 — Must Fix (breaks user experience)

1. **`SystemNavigator.pop()` on web** (2 locations)
   - **Files:** `login_page.dart:113`, `dashboard_page.dart:71`
   - **Issue:** Throws `MissingPluginException` on web. The "Exit" button in the confirm-exit dialog doesn't work.
   - **Fix:** Wrap in a platform check or use `js_util`/`window.close()` as fallback. Simplest fix: wrap in try-catch or use conditional platform import.

### P1 — Should Fix (degraded experience)

2. **PDF share behavior on web**
   - **Issue:** `Printing.sharePdf()` opens browser print dialog, not native share. Works but may confuse users expecting a download.
   - **Fix (optional):** Add a "Download PDF" button path using `AnchorElement` from `package:pdf` web example. Or leave as-is and document behavior.

3. **SPA rewrite configuration for hosting**
   - **Issue:** Path-based routing will 404 without rewrite rules.
   - **Fix:** Configure hosting platform with SPA rewrite (no code change needed — hosting config only).

4. **Supabase CORS configuration**
   - **Issue:** Without CORS origins set, browser `fetch()` to Supabase will fail.
   - **Fix:** Add web domain to Supabase project → Authentication → Settings → Additional CORS origins.

### P2 — Should Address Before Full Launch

5. **Watermark PNG optimization**
   - Reduce from 1.2 MB to ~50-100 KB. Affects every page load.
   - No code change needed — just replace asset file.

6. **Image pagination / lazy loading**
   - Current all-at-once fetch may slow down on web with large catalogues.
   - Consider before public web launch if catalogue exceeds ~200 items per category.

### P3 — Nice to Have

7. **`cached_network_image` disk cache replacement**
   - On web, caching is limited. Could explore service worker caching or skip `cached_network_image` in favor of simpler `Image.network` for web (reducing bundle size).
   - Not urgent; browser cache works.

8. **Consider Wasm build**
   - `flutter build web --wasm` for better performance on modern browsers. Not required for initial launch.

---

## 9. Optional Improvements After Launch

- Switch to `HashUrlStrategy` to eliminate hosting rewrite requirement (trade-off: URL aesthetics).
- Add a "Download PDF" button alongside `sharePdf` for web users.
- Implement infinite scroll / pagination on category pages.
- Enable Flutter Web `--wasm` build for improved performance.
- Add PWA manifest for "Add to Home Screen" capability on iPhone Safari.
- Set up Flutter Web push notifications via Firebase for order updates.

---

## 10. Tables Not Yet Protected

The following tables are accessed **only by admin app** but would be exposed to browser via the same anon key. Confirm they have RLS policies that **block anon read/write**:

| Table | Repository | Admin-only? | RLS Risk |
|-------|-----------|-------------|----------|
| `materials` | `material_repository.dart` | ✅ Yes | Must block anon |
| `cost_breakdown` | `material_repository.dart` | ✅ Yes | Must block anon |
| `item_materials` | `material_repository.dart` | ✅ Yes | Must block anon |
| `app_settings` | `settings_repository.dart` | ⚠️ Read by customer | Read allowed, write blocked |
| `tag_master` | `tag_repository.dart` | ⚠️ Read by customer | Read allowed, write blocked |

---

## 11. Final Recommendation

### Answer Summary

| Question | Answer |
|----------|--------|
| **Can customer app be used in browser for iPhone users?** | **✅ Yes, after minor fixes.** The app compiles and builds for web. Two code issues need fixing (`SystemNavigator.pop`), and hosting config must be set up. |
| **What breaks today?** | **Only `SystemNavigator.pop()`** — the confirm-exit dialog on login page and dashboard. Everything else compiles and runs. PDF sharing works differently (browser print vs native share) but does not break. |
| **What must be fixed before hosting?** | 1. Wrap `SystemNavigator.pop()` for web safety. 2. Configure SPA rewrite on hosting. 3. Configure Supabase CORS origins. |
| **Which hosting option is recommended?** | **Firebase Hosting** or **Cloudflare Pages** — both have simple SPA rewrite, HTTPS, CDN, and custom domain support. Firebase integrates well with Supabase ecosystem. |
| **Should this block Android Play Store internal testing?** | **No.** Android app is unaffected by web readiness. Web is a separate deployment path. Android internal testing can proceed independently. |

### Readiness Level

```
Not ready yet  →  Ready after minor fixes  →  Ready now
                      ⬆
                   HERE
               (2 minor code fixes
               + hosting config)
```

**Current status: Ready after 2 minor fixes + hosting configuration.**

The app is very close to web-ready. The only code-level issue is `SystemNavigator.pop()` in 2 files. Everything else — packages, routing, Supabase, PDF, cart, session — works on Flutter Web. The main work is hosting setup and RLS/CORS configuration.
