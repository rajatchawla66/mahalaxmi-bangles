# Customer App — Real-Device Test Checklist

**Build:** `app-debug.apk` (debug, 148.5 MB, multi-arch)
**Built:** 2026-06-13
**Test device:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ (fill in)
**Android version:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ (fill in)

---

## Installation & Launch

- [ ] APK installs successfully
- [ ] App opens without crash
- [ ] No "Unfortunately app has stopped" on launch

## Landing Page (Phase 2.1)

- [ ] Landing page renders correctly (watermark branding, Mahalaxmi Bangles)
- [ ] "Customer Login" button is visible and tappable

## PIN Login (Phase 2.1)

- [ ] PIN input field accepts numbers only
- [ ] Incorrect PIN shows error ("Invalid PIN")
- [ ] Valid PIN (matching Supabase `customers` table) logs in successfully
- [ ] After login, navigates to dashboard automatically
- [ ] Relaunching app after login goes directly to dashboard (session persistence)

## Dashboard — Category Grid (Phase 2.2)

- [ ] Category grid loads from Supabase (`is_available = true` only)
- [ ] Loading spinner appears briefly on slow connections
- [ ] Category cards display cover images (or maroon gradient fallback)
- [ ] Pull-to-refresh works
- [ ] Empty state with "No categories available" if no categories exist
- [ ] Error state with retry button if network fails
- [ ] Cart icon (badge) visible in AppBar
- [ ] Overflow menu shows "My Orders" and "Logout"
- [ ] Tapping a category card navigates to items grid

## Category Items Grid (Phase 2.3)

- [ ] Items load for selected category (`is_available = true` + `selling_price > 0`)
- [ ] Item cards show image (or maroon fallback), item number, price, tags
- [ ] "NEW" badge on new items
- [ ] Loading / error / empty states work
- [ ] Pull-to-refresh works
- [ ] Cart icon badge visible
- [ ] Back button returns to dashboard
- [ ] Tapping an item card navigates to item detail

## Item Detail (Phase 2.4)

- [ ] Large product image loads (or maroon gradient fallback)
- [ ] Tapping image opens full-screen viewer (InteractiveViewer)
- [ ] Item number, category breadcrumb, price, tags displayed
- [ ] Color dropdown appears only for items with `has_color == true`
- [ ] "Custom" color shows text input
- [ ] Size steppers (2.2, 2.4, 2.6, 2.8, 2.10) appear only for items with `has_sizes == true`
- [ ] Single quantity stepper appears for non-sized items
- [ ] Live summary updates: total sets, line total (via `calculateLineTotal`)
- [ ] Bottom bar shows quantity + amount + "Add to Cart" button

## Add to Cart (Phase 2.4)

- [ ] Adding without selecting colour shows error (if `has_color`)
- [ ] Adding with zero sized quantities shows error
- [ ] Adding with zero single quantity shows error
- [ ] Valid add shows green snackbar "added to cart"
- [ ] Re-adding same item with same colour shows "quantity updated in cart"
- [ ] After adding, auto-navigates back to category page (600ms delay)
- [ ] Cart badge count increments

## Cart Screen (Phase 2.5)

- [ ] Cart icon in AppBar navigates to `/cart`
- [ ] Empty cart shows icon + "Your cart is empty" + "Browse Catalogue"
- [ ] Browse Catalogue returns to dashboard
- [ ] Cart lines display: item number, category, colour, size chips, single qty
- [ ] Line total matches `calculateLineTotal` calculation
- [ ] Remove button works (uses `cartProvider.notifier.removeItem`)
- [ ] Summary bar shows items count, sets count, grand total
- [ ] "Place Order" button is visible

## Place Order (Phase 2.6)

- [ ] Tapping "Place Order" opens confirmation bottom sheet
- [ ] Confirmation shows shop name, items, sets, total
- [ ] Cancel returns to cart unchanged
- [ ] Confirm shows loading spinner
- [ ] On success: success dialog with order number appears
- [ ] Cart is empty after successful order
- [ ] "Continue Shopping" navigates to dashboard
- [ ] On failure (e.g. network): error snackbar, cart preserved
- [ ] Order appears in Supabase `orders` table with `source = 'customer'`
- [ ] Order items appear in `order_items` table with correct quantities

## My Orders (Phase 2.7)

- [ ] "My Orders" in dashboard menu navigates to `/my-orders`
- [ ] Orders list loads (only orders for current `customer_id`)
- [ ] Order cards: order #, date, status badge, item/sets count, total
- [ ] Status badges: pending (gold), confirmed (blue), completed (green), cancelled (red)
- [ ] Tapping an order expands line items
- [ ] Line items: item number, colour, size chips, single qty, line total
- [ ] Order total footer at bottom of expanded section
- [ ] Empty state: "No orders yet" + "Browse Catalogue"
- [ ] Pull-to-refresh works
- [ ] Error state with retry
- [ ] Back button returns to dashboard

## Logout & Session

- [ ] Logout from dashboard menu works
- [ ] After logout, returns to landing page
- [ ] After logout, cannot access `/dashboard` directly (redirect to `/login`)

## Navigation & UX

- [ ] Android back button works correctly throughout app
- [ ] No navigation loops or dead-ends
- [ ] All routes accessible from appropriate navigation
- [ ] No blank screens encountered
- [ ] App does not crash during normal usage (5+ minutes of browsing)

## Performance Observations

| Aspect | Notes |
|--------|-------|
| Cold start time | ms |
| Image load speed | |
| Grid scroll smoothness | |
| Cart add responsiveness | |
| Order placement speed | |
| Memory usage | |

## Issues Found

| # | Severity | Page | Description |
|---|----------|------|-------------|
| 1 | | | |
| 2 | | | |
| 3 | | | |

## Sign-off

**Tested by:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**Date:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
**Overall verdict:** ⬜ Pass / ⬜ Pass with issues / ⬜ Fail
