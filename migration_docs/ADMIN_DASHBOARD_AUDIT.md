# Admin Dashboard Audit

> **Date:** 2026-07-05
> **Purpose:** Audit current admin dashboard before redesign. No implementation changes yet.

---

## 1. Current Dashboard Summary

### Layout
- Simple scrollable `ListView` with `RefreshIndicator`
- 2-row summary card grid + "Recent Orders" title + recent order list
- Refresh button in AppBar + swipe-to-refresh

### Cards Currently Shown (5 stats)

| Card | Value | Color |
|------|-------|-------|
| Total | `stats.totalOrders` (all orders excl. deleted) | Blue |
| Pending | `stats.pendingOrders` | Yellow/amber |
| Confirmed | `stats.confirmedOrders` | Blue |
| Completed | `stats.completedOrders` | Green |
| Cancelled | `stats.cancelledOrders` | Red |

### Recent Orders Section
- Shows up to 10 most recent orders as `_OrderListItem` cards
- Each card: Order #, customer name, date, status badge (color-coded)
- Empty state: "No orders yet" centered text

### States
- **Loading:** `CircularProgressIndicator` centered
- **Error:** Cloud-off icon + error message + Retry button
- **Empty:** "No orders yet" text
- **Data:** Stats cards + recent order list

### What's Missing
- No catalogue stats (total items, available, unavailable)
- No customer stats (total, active, inactive)
- No cutmail stats (pending, reviewed)
- No today's orders or today activity
- No alerts (items missing price, categories missing cover, etc.)
- No quick actions (Create Order, Add Item, etc.)
- No navigation shortcuts to other tabs

---

## 2. Current Files/Providers

| File | Role |
|------|------|
| `mahalaxmi_admin/lib/features/dashboard/pages/dashboard_page.dart` | UI — `DashboardPage` (ConsumerWidget), `_StatCard`, `_OrderListItem` |
| `mahalaxmi_admin/lib/features/dashboard/providers/dashboard_provider.dart` | Provider — `DashboardStats` class + `dashboardStatsProvider` (FutureProvider) |
| `mahalaxmi_admin/lib/features/dashboard/providers/admin_orders_provider.dart` | Existing `adminAllOrdersProvider`, `adminArchivedOrdersProvider` |
| `mahalaxmi_admin/lib/features/catalogue/providers/admin_catalogue_provider.dart` | Existing `adminCategoriesWithStatsProvider`, `adminMissingPriceItemsProvider` |
| `mahalaxmi_admin/lib/features/customers/providers/admin_customers_provider.dart` | Existing `adminCustomersProvider` |
| `mahalaxmi_admin/lib/features/cutmail/providers/admin_cutmail_provider.dart` | Existing `adminCutmailsProvider`, `adminCutmailsByStatusProvider` |
| `mahalaxmi_shared/lib/providers/chuda_customization_provider.dart` | Existing `chudaCustomizationOptionsProvider` (active only) |

### How `dashboardStatsProvider` Works

```dart
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final orderRepo = ref.read(orderRepositoryProvider);
  final orders = await orderRepo.getOrdersWithItems();  // fetches ALL orders
  // Counts pending/confirmed/completed/cancelled by iterating
  // Takes first 10 as recent
  return DashboardStats(total, pending, confirmed, completed, cancelled, recent);
});
```

**Performance concern:** Fetches ALL orders every time dashboard opens. Counts are computed client-side by iterating the full list.

---

## 3. Data Currently Shown

All currently shown data comes from a single source:

| Data | Source | Method |
|------|--------|--------|
| Total orders count | `orderRepo.getOrdersWithItems()` | Fetches all, counts length |
| Pending orders count | Same query | Client-side filter by status |
| Confirmed orders count | Same query | Client-side filter by status |
| Completed orders count | Same query | Client-side filter by status |
| Cancelled orders count | Same query | Client-side filter by status |
| Recent 10 orders | Same query | Client-side `.sublist(0, 10)` |

### Soft-Delete Handling
- ✅ **Already correct:** `getOrdersWithItems()` includes `.isFilter('deleted_at', null)` — deleted orders are excluded from all counts and recent list.
- ✅ `getArchivedOrders()` also filters `deleted_at IS NULL`.

---

## 4. Data Available from Existing Repositories

### Orders (OrderRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Pending orders count | ✅ Yes | `getOrdersWithItems()` → client-side count | Full table scan |
| Confirmed orders count | ✅ Yes | Same | Full table scan |
| Completed orders count | ✅ Yes | Same | Full table scan |
| Cancelled orders count | ✅ Yes | Same | Full table scan |
| Recent orders | ✅ Yes | `getOrdersWithItems()` + sublist | Full table scan |
| Today's orders | ❌ No dedicated query | Would need date filter on DB | Could add lightweight |
| Archived orders | ✅ Yes | `getArchivedOrders()` | Archived status filter |
| Deleted orders excluded | ✅ Yes | `.isFilter('deleted_at', null)` in all queries | Already applied |

### Catalogue (ItemRepository + CategoryRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Total items | ✅ Yes | `getAllItems()` → `.length` | Full table scan |
| Available items | ✅ Yes | `getAllItems()` → filter by `isAvailable` | Full table scan |
| Unavailable items | ✅ Yes | `getAllItems()` → filter by `!isAvailable` | Full table scan |
| Category count | ✅ Yes | `getCategories()` → `.length` | Lightweight |
| Category-wise item count | ✅ Yes | `adminCategoriesWithStatsProvider` already computes this | Full item scan |
| Items missing image | ✅ Possible | `getAllItems()` → filter `imageUrl.isEmpty` | Full table scan |
| Items without price | ✅ Yes | `adminMissingPriceItemsProvider` already exists | Full table scan |
| Items low/no sizes | ❌ Not directly | Would need to check `available_sizes` per item | Would require scan |

### Customers (CustomerRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Total customers | ✅ Yes | `getCustomers()` → `.length` | Full table scan |
| Active customers | ✅ Yes | `getCustomers()` → filter `isActive` | Full table scan |
| Inactive customers | ✅ Yes | `getCustomers()` → filter `!isActive` | Full table scan |
| Recently added | ✅ Yes | `getCustomers()` ordered by `created_at DESC` — first few | Full table scan |
| Customers with missing mobile | ✅ Yes | `getCustomers()` → filter | Full table scan |

### Cutmail (CutmailRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Pending count | ✅ Yes | `getCutmails(status: 'pending')` | DB-filtered |
| Reviewed count | ✅ Yes | `getCutmails(status: 'reviewed')` | DB-filtered |
| Archived count | ✅ Yes | `getCutmails(status: 'archived')` | DB-filtered |
| Latest cutmails | ✅ Yes | `getCutmails(limit: 5)` — already supports limit param | Lightweight |
| Metal Bangles summary | ✅ Possible | `getCutmails(category: 'Metal_Bangles')` | DB-filtered |
| Zero-qty sizes | ❌ Not directly | Would need cutmail_sizes join | Moderate |

### Chuda Customization (ChudaCustomizationRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Active Patti options count | ✅ Yes | `getActiveOptions()` → filter by `groupType == 'patti'` | Lightweight |
| Active Color options count | ✅ Yes | Same → filter by `groupType == 'color'` | Lightweight |
| Active Box options count | ✅ Yes | Same → filter by `groupType == 'box'` | Lightweight |
| Missing defaults | ⚠️ Partial | Would need to check `is_default == true` per group | Lightweight |

### Settings (SettingsRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Default margin | ✅ Yes | `getDefaultMargin()` | Single row lookup |
| Labour cost | ✅ Yes | `getLabourCost()` | Single row lookup |

### Tag Master (TagRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Total tags | ✅ Yes | `getTagMaster()` → `.length` | Lightweight |
| Active tags | ✅ Yes | `getTagMaster(activeOnly: true)` → `.length` | Lightweight |

### Materials (MaterialRepository)

| Data | Available? | Method | Cost |
|------|-----------|--------|------|
| Total materials | ✅ Yes | `getMaterials()` → `.length` | Lightweight |

---

## 5. Missing Data / Repository Methods

For a complete dashboard, these lightweight methods would be useful additions to repositories:

### OrderRepository
```dart
// Lightweight count queries — no need to fetch all rows
Future<int> getOrdersCountByStatus(String status);  // SELECT count(*) WHERE status=X AND deleted_at IS NULL
Future<int> getTodayOrdersCount();                  // SELECT count(*) WHERE order_date = today
Future<List<Order>> getRecentOrders({int limit});   // Same as getOrdersWithItems but with DB limit
```

### ItemRepository
```dart
Future<int> getItemsCount();                        // SELECT count(*)
Future<int> getAvailableItemsCount();               // SELECT count(*) WHERE is_available=true
Future<int> getItemsMissingImageCount();            // SELECT count(*) WHERE image_url IS NULL OR image_url=''
```

### CustomerRepository
```dart
Future<int> getCustomersCount();                    // SELECT count(*)
Future<int> getActiveCustomersCount();              // SELECT count(*) WHERE is_active=true
Future<List<Customer>> getRecentCustomers({int limit});  // Lightweight recent customers
```

### CutmailRepository
```dart
Future<int> getCutmailsCountByStatus(String status);     // SELECT count(*) WHERE status=X
```

### CategoryRepository
```dart
Future<int> getCategoriesMissingCoverCount();       // SELECT count(*) WHERE cover_image_url IS NULL
```

> **Note:** These are optimization suggestions. The current approach of fetching all rows works for current data sizes but won't scale. Count queries via PostgREST are more complex because PostgREST doesn't expose raw `count(*)` in the REST API without enabling it server-side.

---

## 6. Dashboard Improvement Opportunities

### Current Gaps
1. **Only order data** — No catalogue, customer, cutmail, or alert data
2. **No today's focus** — No "today's orders" or "today's activity"
3. **No alerts** — Items missing price/cover, pending cutmails, inactive categories all invisible
4. **No quick actions** — User must navigate to other tabs for any action
5. **No navigation shortcuts** — Can't jump to orders/catalogue/customers from dashboard
6. **Heavy query** — `getOrdersWithItems()` fetches ALL orders with ALL items, then counts client-side
7. **No pagination** — Recent orders capped at 10 but still fetched in full query

### Strengths to Preserve
1. ✅ Refresh button + pull-to-refresh
2. ✅ Error/loading/empty states
3. ✅ Compact stat cards
4. ✅ Clean `_StatCard` widget (reusable)
5. ✅ Soft-delete already handled correctly
6. ✅ Repository pattern — no direct Supabase in UI

---

## 7. Suggested Ideal Dashboard Layout

### Section 1 — Top Summary Row (4 compact cards)
```
┌──────────┬──────────┬──────────┬──────────┐
│ Pending  │ Confirmed│ Completed│ Pending  │
│ Orders   │ Orders   │ Today    │ Cutmail  │
│   12     │    8     │    3     │    5     │
│ (yellow) │ (blue)   │ (green)  │ (orange) │
└──────────┴──────────┴──────────┴──────────┘
```

### Section 2 — Quick Actions Row (icon buttons)
```
[ + Create Order ]  [ + Add Item ]  [ + Add Customer ]  [ + Add Cutmail ]
```

### Section 3 — Alerts / Needs Attention
```
⚠ 3 items without price         → Tap to view
⚠ 2 categories missing cover    → Tap to view
⚠ 5 cutmails pending review     → Tap to view
```

### Section 4 — Today's Activity
```
Today's Orders (3)
┌─────────────────────────────────────────┐
│ Order #42 · Ramesh · ₹12,500 · Pending │
│ Order #41 · Suresh · ₹8,200 · Confirmed│
│ Order #40 · Priya  · ₹15,000 · Pending │
└─────────────────────────────────────────┘
```

### Section 5 — Quick Stats Row (compact)
```
Total Items: 142 │ Available: 128 │ Customers: 45 │ Categories: 8
```

### Section 6 — Navigation Shortcuts
```
[ Orders ]  [ Catalogue ]  [ Customers ]  [ Cutmail ]  [ Settings ]
```

---

## 8. Performance Risks

| Risk | Severity | Detail |
|------|----------|--------|
| `getOrdersWithItems()` fetches ALL rows | 🔴 High | Currently fetches ALL orders with ALL items every time dashboard loads. If dataset grows to thousands of orders, this will become slow and bandwidth-heavy |
| No server-side counts | 🔴 High | All counts are computed client-side after fetching full data |
| Multiple parallel fetches | 🟡 Medium | If we add catalogue + customers + cutmail stats, dashboard would fire 4-5 separate queries |
| PostgREST count limitations | 🟡 Medium | PostgREST can return `count` via `?select=count` or `?head=true` but these need to be enabled in Supabase/PostgREST config |

### Mitigations
1. **Add `limit` parameter** to `getOrdersWithItems()` for recent orders only — no need to fetch all 1000+ orders just to show top 10
2. **Use DB-filtered counts** where possible: `getCutmails(status: 'pending')` already supports this
3. **Separate lightweight dashboard provider** that fires parallel queries for counts only
4. **Cache dashboard stats** with a refresh interval or manual refresh only (not auto-refresh on every navigation)
5. **Add `.count()` support** in Supabase queries (`PostgrestQueryBuilder.count()` with `SelectCountType.exact`)

---

## 9. Recommended Phase 1 Dashboard Redesign

### What to Add First (No Schema Changes Needed)

All of these use existing repositories/providers:

**Stats (use existing providers async, cache results):**
- Pending orders count
- Confirmed orders count
- Completed today count (or recent orders)
- Pending cutmail count (via `adminCutmailsByStatusProvider('pending')`)
- Total items / available items (via existing providers)
- Active customers (via `adminCustomersProvider` → filter client-side)
- Categories count (via `adminCategoriesWithStatsProvider`)

**Alerts (computed from existing data):**
- Items without price (`adminMissingPriceItemsProvider`)
- Categories missing cover image (iterate categories, check `imageUrl`)
- Cutmails pending review (from cutmail provider)
- Customers recently disabled (from customers provider)

**Quick Actions (just navigation):**
- Create Order → navigate to create order page
- Add Item → navigate to add item page
- Add Customer → navigate to customers
- Add Cutmail → navigate to cutmail add
- Manage Chuda Customization → navigate to settings

### Dashboard Data Provider — Proposed Architecture

```dart
// Single combined provider that fires parallel async queries
final adminDashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final results = await Future.wait([
    ref.read(adminAllOrdersProvider.future),
    ref.read(adminCategoriesWithStatsProvider.future),
    ref.read(adminCustomersProvider.future),
    ref.read(adminCutmailsByStatusProvider('pending').future),
  ]);
  // Merge into DashboardData model
});
```

### Widget Changes (Minimal)
- Extract `_StatCard` into reusable widget file
- Create `_AlertTile` widget for needs-attention section
- Create `_QuickActionButton` widget
- Keep existing `_OrderListItem` for recent orders

---

## 10. Recommended Phase 2 Improvements

| Improvement | Requires | Effort |
|------------|----------|--------|
| Server-side count queries | New Supabase RPC or PostgREST count config | Medium |
| Today's orders with date filter | New repository method | Low |
| Dashboard auto-refresh | Timer-based refresh or supabase realtime | Medium |
| Widget-level caching to avoid refetch on tab switch | Riverpod `keepAlive` or `AutoDispose` config | Low |
| Pagination for recent orders | Add limit/offset to query | Low |
| Chuda default option missing check | New repository method | Low |
| Items missing images count | New repository method | Low |
| Cutmail with zero-qty sizes alert | New repository method | Medium |

---

## 11. Questions / Decisions Needed

1. **How should dashboard stats be refreshed?**
   - Manual pull-to-refresh only (current pattern) — simplest
   - Auto-refresh on every tab switch (when user navigates from Orders to Dashboard)
   - Timer-based auto-refresh (e.g., every 60 seconds)
   - Recommend: Manual refresh + refresh on tab switch

2. **Should we optimize counts with DB-level queries now?**
   - Current data volume is small, so fetching all rows works
   - If the dataset is under ~500 orders, no optimization needed yet
   - Recommend: Keep client-side counts for Phase 1, optimize in Phase 2 if slow

3. **Quick actions — should they navigate directly or show bottom sheets?**
   - Create Order: Navigator push to create order page
   - Add Item: Navigator push to add item page
   - Recommend: Direct navigation for v1

4. **Should "Today's Orders" use a date filter or just show recent 5?**
   - Date filter requires new repository method
   - "Recent 5 orders" works with existing `getOrdersWithItems()` + 5 limit
   - Recommend: "Recent 5" for Phase 1, "Today's Orders" for Phase 2

---

## Summary

| Question | Answer |
|----------|--------|
| **What is currently available?** | 5 order stats (total/pending/confirmed/completed/cancelled) + 10 recent orders. All from one heavy query. |
| **What should be shown on dashboard first?** | Pending orders, pending cutmail, active customers, total/available items, alerts (missing price, missing cover, cutmails to review), quick actions (create order, add item, add cutmail) |
| **What can be implemented without schema changes?** | Everything listed above uses existing repositories and tables. No new database columns or tables needed. |
| **What should not be added yet?** | Real-time auto-refresh, server-side count queries, complex pagination — defer to Phase 2 unless performance is already an issue. |
