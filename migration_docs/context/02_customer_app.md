# 02 — Customer App (`mahalaxmi_customer`)

## Login

- PIN-based (8-digit), uses in-app numeric keypad (no mobile keyboard)
- Business info header: name, tagline, GST, address, contact cards (Instagram, WhatsApp, Maps)
- Session persisted via `SharedPreferences` — survives app restarts
- Forced logout on deactivation validated at: session restore, app resume, and before placing order
- Web-safe exit confirmation (`kIsWeb` guard on `SystemNavigator.pop()`)

## Catalogue Flow

- Dashboard: category grid with 3:4 cover images, name overlay, gradient
- Categories ordered by `sort_order ASC`, then `name ASC`
- Category page: one-column vertical feed of 4:5 product images
- Tag filter row (horizontal scroll, shows when >1 unique tag per category)
- Stale tag filter reset on category switch via `didUpdateWidget`
- Pull-to-refresh on category page (works even with empty filter results)

## Image Display

- All customer images use `CachedNetworkImage` (200MB LRU disk cache)
- Watermark overlay (`watermark.png`, 26% opacity, 70% size, centered, `IgnorePointer`)
- Full-screen image viewer: black scaffold, `InteractiveViewer` (1x-5x zoom), close button
- 4:5 portrait aspect ratio for product images; 3:4 for category covers
- Cache invalidation note: admin image replacement may serve stale cache until expiry

## Cart & Persistence

- Cart persisted per-customer in `SharedPreferences` (`customer_cart_{customerId}`)
- Auto-saved on every mutation via `ref.listen` in `app.dart`
- Restored on cold start after session restore
- Cleared only on successful order placement
- Preserved on logout/disable (admin may re-enable)
- Switched carts when different customer logs in

## Chuda Customisation

- Patti type, Patti Color (with custom color text fallback), Box options
- Options fetched from `chuda_customization_options` table (admin-configurable)
- Defaults auto-selected on first open (async-safe — awaits `FutureProvider.future` in `_addToCart`)
- Collapsible UI: collapsed by default, shows summary; tap to expand full chip selectors
- Quantity section moved above customization for faster add-to-cart
- Customised price: `unitPrice = basePrice + customizationTotal`
- Customization snapshot saved to `order_items.customization` JSONB

### Critical Fixes (bugfix history reference)
- First-open default bug: `_ensureChudaDefaultsReady()` awaits `FutureProvider.future`
- Cart price bug: `_addToCart` was using base price only without `_customisationTotal`

## Size Chart & Available Sizes

- Category-level `size_chart` JSONB defines available sizes per category
- Item-level `available_sizes` JSONB (null = all category sizes available)
- Unavailable sizes shown greyed out with "Not available" label
- All sizes handled as strings; Chuda: `['2.2','2.4','2.6','2.8','2.10']`, Metal Bangles: `['2.4','2.6','2.8','2.10','2.12']`

## Orders

- My Orders page: list of past orders with status, items, customization chips
- Repeat order / Add Again — carries over customization snapshot and customised price
- PDF share via `OrderPdfService` — text layout with Helvetica, INR formatting, product images
- Soft-deleted orders excluded from customer view

## Error Handling

- `CustomerErrorMessages` maps raw exceptions to friendly messages (7 leak points fixed)
- Categories: SocketException → "No internet connection"
- Data errors → "Could not load data. Please try again."
- Generic → "Something went wrong. Please try again."

## Web Readiness

- Live at `https://app.mahalaxmibangles.com`
- Exit confirmation uses `kIsWeb` — shows SnackBar instead of `SystemNavigator.pop()`
- Image picker web-compatible (`Uint8List` flow)
- PDF output used via `flutter_pdf` (client-side generation)
