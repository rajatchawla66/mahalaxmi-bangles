# Labour App Status Audit

## 1. Labour App Folder / Build Status

**Finding: No separate Labour Flutter app exists.**

There is no `mahalaxmi_labour` directory in the repository. The labour role is embedded inside `mahalaxmi_admin` — same APK, same build config. This is by design, per `EXPECTED_FLUTTER_FEATURES_FROM_FLET.md` line 81:

> *"Target APK: `mahalaxmi_admin` (labour role within admin APK — no separate APK)"*

| Item | Status |
|------|--------|
| Separate Flutter project | ❌ Does not exist |
| `pubspec.yaml` | ❌ N/A |
| `main.dart` | ❌ N/A |
| `AndroidManifest.xml` | ❌ N/A |
| Build script | ❌ N/A |

**Implication:** Any labour features must be built inside `mahalaxmi_admin` with role-based gating.

---

## 2. Current Implemented Screens

### 2.1 Labour Login
| Detail | Status |
|--------|--------|
| File | `mahalaxmi_admin/lib/features/auth/pages/login_page.dart` |
| UI | Separate "Labour" card with password field — "Production checklist — no pricing" |
| Auth method | `AuthController.loginLabour()` in `mahalaxmi_shared/lib/providers/auth_provider.dart` |
| Password | Hardcoded `labour123` (same as legacy Flet) |
| Session | Creates `AppSession.labour(username)` with `AuthRole.labour` |
| **Behaviour after login** | Redirects to `/dashboard` — same dashboard as admin with **no role-based gating** |

### 2.2 Labour Dashboard
| Detail | Status |
|--------|--------|
| **Dedicated labour dashboard** | ❌ **NOT implemented** |
| Current behaviour | Labour sees the exact same admin dashboard (order stats, catalogue counts, customers, settings) |
| Price hiding | ❌ **NOT implemented** — labour can see all prices |
| FAB visibility | ❌ **NOT implemented** — labour sees FABs (should be hidden) |

### 2.3 Production Checklist
| Detail | Status |
|--------|--------|
| **Feature** | ❌ **NOT implemented in Flutter** |
| Legacy Flet | ✅ Full implementation in `views/labour.py` (~247 lines) |
| Features | Image-first cards, per-size status toggle (pending/prepared/not_available), progress summary, JSONB persistence |
| Data model | ✅ `OrderItem.productionStatus` field exists in `mahalaxmi_shared/lib/models/order.dart:48` |
| Repository method | ❌ **Missing** — no `updateProductionStatus()` in any repository |
| Route | ❌ **Missing** — no `/production-checklist/:orderId` route |

### 2.4 Labour PDF (Karigar Slip)
| Detail | Status |
|--------|--------|
| **Feature** | ✅ Fully implemented |
| File | `mahalaxmi_shared/lib/services/order_pdf_service.dart:36` — `generateLabourPdf()` |
| Sharing | `mahalaxmi_admin/lib/features/orders/pages/order_detail_page.dart:106` — "Karigar Slip (Labour)" menu item |
| Price hiding | ✅ Labour slip has no pricing |

---

## 3. Current Implemented Features

| # | Feature | Status | Location |
|---|---------|--------|----------|
| 1 | Labour auth role + session | ✅ Complete | `shared/lib/models/app_session.dart` |
| 2 | Labour login (hardcoded PW) | ✅ Complete | `shared/lib/providers/auth_provider.dart:35-41` |
| 3 | Labour login UI card | ✅ Complete | `admin/lib/features/auth/pages/login_page.dart:118-128` |
| 4 | Labour cost setting | ✅ Complete | `shared/lib/repositories/settings_repository.dart:32-35` |
| 5 | Labour cost provider | ✅ Complete | `shared/lib/providers/app_settings_provider.dart:9-11` |
| 6 | Karigar PDF slip (no pricing) | ✅ Complete | `shared/lib/services/order_pdf_service.dart` |
| 7 | Order model with `productionStatus` | ✅ Complete | `shared/lib/models/order.dart:48-49` |

---

## 4. Missing / Incomplete Features

### Must-have (required for parity with legacy Flet)

| # | Feature | Legacy Flet | Flutter Status | Effort |
|---|---------|-------------|----------------|--------|
| 1 | **Labour dashboard** (order cards, no prices, no FAB) | `views/home.py:10-354` | ❌ Missing | ~2h |
| 2 | **Production checklist** (image cards, per-size status toggle, progress) | `views/labour.py:1-247` | ❌ Missing | ~6h |
| 3 | **Price hiding for labour role** in all views | `main.py:render()` | ❌ Missing | ~1h |
| 4 | **Role-based router redirect** (labour → labour dashboard, not admin dashboard) | `main.py:476-477` | ❌ Missing | ~0.5h |
| 5 | **Repository method** for `production_status` update | `db.py:751-764` | ❌ Missing | ~1h |
| 6 | **Route** for production checklist (`/production-checklist/:orderId`) | `main.py:974-976` | ❌ Missing | ~0.5h |

**Total estimated effort: ~11 hours**

### Not planned (never existed even in legacy Flet)

| Feature | Description |
|---------|-------------|
| Labourer/worker profiles | Names, contact, skills, wages |
| Attendance tracking | Daily check-in/out |
| Advance payments | Salary advances |
| Salary/wage processing | Monthly salary |
| Settlement | Final payout calculation |

---

## 5. Build / Analyze Status

| App | Command | Result |
|-----|---------|--------|
| `mahalaxmi_admin` | `dart analyze` | **0 errors** (only pre-existing info diagnostics) |
| `mahalaxmi_shared` | `dart analyze` | **0 errors** |
| `mahalaxmi_admin` | `flutter build apk` | Builds successfully (last build: admin APK was built) |

**No labour-specific build issues exist** because the labour role is entirely inside `mahalaxmi_admin` and doesn't add any separate build targets.

---

## 6. Supabase / Data Dependencies

| Dependency | Status | Notes |
|------------|--------|-------|
| `order_items.production_status` (JSONB) | ✅ Column exists in DB | Migration: `sql/migration_add_production_status.sql` — already applied to production |
| `app_settings.labour_cost_flat` | ✅ Setting exists | Read by `settings_repository.dart:32-35` |
| `auth` table for labour users | ❌ Not used | Labour auth uses hardcoded password, not Supabase |
| Labour-specific tables (attendance, advances, salary) | ❌ Don't exist | Never created even in legacy |

---

## 7. Admin-Labour Integration Status

| Feature | Status | Details |
|---------|--------|---------|
| Admin can add/edit labourers | ❌ Not in Flutter | Legacy didn't have this either |
| Admin can assign PIN | ❌ Not in Flutter | Hardcoded `labour123` only |
| Admin can mark attendance | ❌ Not in Flutter | Never existed |
| Admin can manage advances | ❌ Not in Flutter | Never existed |
| Admin can do settlements | ❌ Not in Flutter | Never existed |
| Admin sees production status on orders | ❌ Not in Flutter | Legacy Flet had read-only production status in order detail |
| Admin can share Karigar slip | ✅ Implemented | Order detail page → "Karigar Slip (Labour)" |

---

## 8. Security / Isolation Status

### Issues Found

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| 1 | **Labour sees full admin dashboard** | **HIGH** | After login, labour is redirected to the identical admin dashboard with orders, catalogue, customers, settings — all visible |
| 2 | **Labour sees prices** | **HIGH** | No price-hiding logic exists in any view. Labour can see selling price, cost price, line totals |
| 3 | **Labour sees FABs** | **MEDIUM** | Labour sees "Create Order", "Add Item" buttons — should not |
| 4 | **Labour can access all routes** | **HIGH** | Router has no `isLabour` checks. Labour can navigate to `/catalogue`, `/customers`, `/settings` |
| 5 | **Hardcoded password** | **MEDIUM** | `labour123` is hardcoded in shared provider. No way for admin to change it. |
| 6 | **No session isolation** | **LOW** | Session reuses same `AppSession` infrastructure — working correctly for basic auth |

### What Works Correctly
- `AuthRole.labour` is correctly set in the session
- `session.isLabour` property returns correct value
- Session persistence works for labour (same `SharedPreferencesSessionStorage`)

---

## 9. Known Bugs / Risks

| # | Risk | Impact | Likelihood |
|---|------|--------|------------|
| 1 | Labour user accidentally edits/deletes catalogue items | Data loss | Medium — labour can currently access catalogue edit screens |
| 2 | Labour sees customer PII and pricing | Privacy/compliance violation | High — all customer screens are visible |
| 3 | Labour creates orders fraudulently | Financial | Low — labour can access order creation |
| 4 | Hardcoded `labour123` leak | Unauthorized access | Low-moderate — shared across all installations |

---

## 10. Recommended Next Implementation Phases

### Phase A — Security Gate (Critical, ~2h)

1. **Add `isLabour` check in router redirect** — After login, redirect labour to a restricted dashboard (or the same dashboard but gated). Block access to `/catalogue/*`, `/customers/*`, `/settings/*`, `/orders/create`.
2. **Hide FAB conditionally** — In pages where FAB exists, check `session.isLabour` and hide it.
3. **Add route guard** — A `beforeRedirect` that checks labour role against allowed routes.

### Phase B — Price Hiding (~1h)

1. Check `session.isLabour` in all order-related views and hide price columns.
2. Replace price values with "—" or similar placeholder.

### Phase C — Labour Dashboard (~2h)

1. Create or modify the dashboard page to show order cards without prices when `isLabour`.
2. Add production summary to order cards (showing prepared/total count).
3. Replace "View Order" tap behaviour with direct link to production checklist.

### Phase D — Production Checklist (~6h)

1. Add `updateProductionStatus(orderId, itemNumber, statusMap)` to `item_repository.dart`.
2. Create production checklist page at `/production-checklist/:orderId`.
3. Image-first cards, per-size status toggle (pending→prepared→not_available→back to pending).
4. Progress summary header.
5. Persist to `order_items.production_status` JSONB after each toggle.

### Phase E — Admin Production Status Read (~1h)

1. Show read-only production status tiles in admin order detail page.

---

## 11. Impact on Customer Play Store Internal Testing

**Labour app does NOT block customer Play Store internal testing.**

### Reasons

1. **Labour is embedded in admin APK, not customer APK** — Customer app (`mahalaxmi_customer`) has zero labour dependencies.
2. **No shared blocking dependencies** — Customer app only uses `mahalaxmi_shared` for models/ repositories/ auth. Labour features are entirely in `mahalaxmi_admin`.
3. **Customer app passes `flutter analyze` with 0 errors** — No labour code touches customer app.
4. **Legacy Flet labour features never included workforce management** — The legacy "Labour" feature was strictly a production order checklist (karigar/artisan work tracking). It was never a full HR/attendance system.
5. **Admin APK can be released separately** — Labour features can ship in a later admin APK update without affecting the customer app.

### Recommendation

- ✅ **Proceed with customer Play Store internal testing** independently.
- The labour production checklist can be developed and released in a future admin APK update (Phase 8 from migration plan).
- The hardcoded password `labour123` and missing security gates should be addressed before any admin APK public release, but do not affect customer testing.

---

## Summary Answers

### 1. Is the Labour app usable right now?
**No.** While labour login works, after login the user sees the full admin dashboard with prices, catalogue CRUD, customer PII, settings, and order creation — none of which should be visible to labour. The core labour feature (production checklist) is not implemented.

### 2. Is the Labour app ready for APK testing?
**No.** The security isolation (price hiding, route blocking, FAB hiding) must be implemented before anyone other than developers tests it. Without these gates, a labour user has full admin access.

### 3. Is the Labour app required before customer Play Store internal testing?
**No.** The customer app is entirely independent. Labour features live in `mahalaxmi_admin` and do not block customer release.

### 4. What is the minimum work needed to make the Labour app usable?
**~11 hours** split across:
- **Phase A (~2h):** Security gates — route blocking, FAB hiding, price hiding
- **Phase B (~1h):** Price hiding in order views
- **Phase C (~2h):** Labour dashboard with order cards (no prices)
- **Phase D (~6h):** Production checklist with image cards, status toggle, progress, persistence

Minimum viable security fix (~30 min): Add `isLabour` check to router redirect to block `/catalogue`, `/customers`, `/settings`, and `/orders/create`. This alone makes the app safe enough for basic testing of the production checklist.
