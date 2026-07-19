# Admin Web Security & RLS Audit

> **Date:** 2026-07-06
> **Purpose:** Comprehensive security audit before deploying admin web app to `admin.mahalaxmibangles.com`
> **Scope:** Environment/config, auth/session, RLS policies, storage bucket, route guards

---

## 1. Environment & Config Audit

### 1.1 Service-Role Key Exposure

| App | Keys Used | Where Defined | Service-Role Key Found? |
|-----|-----------|---------------|------------------------|
| `mahalaxmi_customer` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `.env` → `main.dart` via `--dart-define` | ❌ No |
| `mahalaxmi_admin` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `.env` → `main.dart` via `--dart-define` | ❌ No |
| `mahalaxmi_labour` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | `.env` → `main.dart` via `--dart-define` | ❌ No |
| `mahalaxmi_shared` | None directly | Uses `fromEnvironment()` | ❌ No |

**Verdict:** ✅ No service-role keys in any Flutter client. All apps use the anon key only.

### 1.2 Key Exposure in Web Build

In Flutter Web builds, `String.fromEnvironment()` values are embedded in `main.dart.js` (the compiled JavaScript bundle). The anon key is **public by design** — Supabase anon keys are meant to be exposed to clients. Security relies on RLS policies.

**Risk:** The anon key is readable by inspecting browser network requests or decompiling the JS bundle.

**Mitigation:** Ensure RLS policies restrict what the anon role can do.

### 1.3 `.env` Files

| File | Contents | Gitignored? |
|------|----------|-------------|
| `mahalaxmi_admin/.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | ✅ Yes (`.gitignore` includes `.env`) |
| `mahalaxmi_customer/.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | ✅ Yes |
| `mahalaxmi_labour/.env` | `SUPABASE_URL`, `SUPABASE_ANON_KEY` | ✅ Yes |

**Verdict:** ✅ No secrets in version control.

---

## 2. Auth & Session Audit

### 2.1 Current Auth Architecture

| Component | File | Description |
|-----------|------|-------------|
| `AuthController` | `mahalaxmi_shared/lib/providers/auth_provider.dart` | Hardcoded `admin123` / `labour123` passwords |
| `SessionNotifier` | `mahalaxmi_shared/lib/providers/session_provider.dart` | `StateNotifier` managing `AppSession` state |
| `AppSession` | `mahalaxmi_shared/lib/models/app_session.dart` | Model with `AuthRole` enum (`none`, `admin`, `labour`, `customer`) |
| `SessionStorage` | `mahalaxmi_shared/lib/services/session_storage.dart` | Abstract class + `InMemorySessionStorage` (actual: `SharedPreferencesSessionStorage`) |
| Route Guards | `mahalaxmi_admin/lib/app/router.dart` | GoRouter `redirect` checks `appSessionProvider` |

### 2.2 Critical Security Findings

#### 🔴 CRITICAL: Hardcoded Passwords in Source Code

**File:** `mahalaxmi_shared/lib/providers/auth_provider.dart:19-20`

```dart
const _adminPassword = 'admin123';
const _labourPassword = 'labour123';
```

**Risk:** In Flutter Web builds, all Dart code is compiled to JavaScript and can be decompiled. These passwords are visible in browser DevTools → Sources or by searching the JS bundle.

**Impact:** Anyone can log in as admin by inspecting the source code.

**Current Mitigation:** None — passwords are plaintext constants.

**Recommended Fix:**
- **Option A (Quick):** Use Supabase Auth with email/password login + RLS `auth.uid()` checks
- **Option B (Medium):** Server-side login endpoint that validates credentials and returns a JWT
- **Option C (Minimal):** At minimum, obfuscate passwords or use environment variables (not visible in JS bundle)

**Priority:** Must fix before production web deployment.

#### 🟡 MEDIUM: Client-Side-Only Session Validation

**File:** `mahalaxmi_admin/lib/app/router.dart`

The GoRouter `redirect` checks `appSessionProvider` which reads from `SharedPreferences` (web: `localStorage`). This is a **client-side-only** guard.

**Risk:** A user can:
1. Navigate directly to `admin.mahalaxmibangles.com/dashboard`
2. Manually set `localStorage` values to bypass the redirect
3. Access all admin screens without "real" authentication

**Impact:** Route guards prevent casual access but not determined attackers.

**Mitigation:**
1. **Add server-side session validation** — verify session token on sensitive API calls
2. **Use Supabase Auth** — JWT-based auth with `auth.uid()` in RLS policies
3. **Add Cloudflare Access** — Zero-trust proxy layer before the web app

#### 🟡 MEDIUM: Session Persistence on Web

**File:** `mahalaxmi_shared/lib/services/session_storage.dart`

Sessions persist in `localStorage` (web). A logged-in admin session survives page refresh and browser restart.

**Risk:** If a shared computer is used, the next user inherits the admin session.

**Mitigation:** Add session expiry timeout (e.g., 8 hours) or explicit logout on tab close.

### 2.3 Auth Flow Summary

```
Login Page → AuthController.loginAdmin(username, password)
         → Password matches hardcoded constant
         → SessionNotifier.login(AppSession.admin(username))
         → SharedPreferences.setString('app_session', json)
         → Session persists in localStorage
```

**No Supabase Auth involved.** No JWT. No server-side session creation.

---

## 3. RLS (Row-Level Security) Audit

### 3.1 Current RLS Status

Based on the legacy Flet SQL migrations and codebase analysis, **RLS is currently DISABLED on all tables**. The project was built with RLS disabled during development, with a plan to re-enable in Phase 10.

**Confirmation:** The `CONTEXT.md` states: "RLS: Currently disabled on all tables — re-enable before production (Phase 10)"

### 3.2 Tables Accessed by Anon Key (All Apps)

All three Flutter apps use the **same anon key**. Any table accessible via the anon key is accessible from all three apps AND from direct browser API calls.

#### Tables with Full CRUD via Anon Key

| Table | Customer Read? | Customer Write? | Admin Read? | Admin Write? | Risk Level |
|-------|---------------|-----------------|-------------|--------------|------------|
| `customers` | ✅ Read (login) | ✅ Update (`last_active_at`) | ✅ Full CRUD | ✅ Full CRUD | 🔴 **Critical** — contains PINs |
| `orders` | ✅ Read (my orders) | ✅ Insert (place order) | ✅ Full CRUD | ✅ Full CRUD | 🔴 High — financial data |
| `order_items` | ✅ Read (my orders) | ✅ Insert (place order) | ✅ Full CRUD | ✅ Full CRUD | 🔴 High — financial data |
| `rate_list` | ✅ Read (catalogue) | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — pricing data |
| `categories` | ✅ Read (dashboard) | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — business config |
| `cutmails` | ❌ None | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — production data |
| `cutmail_sizes` | ❌ None | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — production data |
| `chuda_customization_options` | ✅ Read (customization) | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — business config |
| `tag_master` | ✅ Read (tags) | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟢 Low |
| `app_settings` | ✅ Read (margin, labour cost) | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟡 Medium — business settings |
| `materials` | ❌ None | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟢 Low — admin only |
| `cost_breakdown` | ❌ None | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟢 Low — admin only |
| `item_materials` | ❌ None | ❌ None | ✅ Full CRUD | ✅ Full CRUD | 🟢 Low — admin only |

### 3.3 Specific RLS Risks

#### 🔴 CRITICAL: Customer PINs Exposed

**Table:** `customers`
**Field:** `pin` (8-digit numeric)
**Risk:** Any browser user can query `GET /rest/v1/customers?select=pin,shop_name` and retrieve all customer PINs.

**Impact:** Complete compromise of customer authentication. Anyone can impersonate any customer.

#### 🔴 HIGH: Order Data Exposed

**Table:** `orders` + `order_items`
**Risk:** Any browser user can read all order data (customer names, amounts, items, statuses) and modify/delete orders.

**Impact:** Financial data exposure. Order manipulation.

#### 🟡 MEDIUM: Storage Bucket Write Access

**Bucket:** `product-images`
**Risk:** The anon key may have write access to the storage bucket. An attacker could overwrite product images with malicious content.

**Files at risk:**
- `product-images/items/*.jpg` — product images
- `product-images/category_covers/*.jpg` — category covers
- `product-images/order-pdfs/*.pdf` — order PDFs (if generated)

### 3.4 What RLS Should Enforce

#### Customer App (anon role)
| Table | Read Policy | Write Policy |
|-------|------------|--------------|
| `customers` | Read own row only (`id = auth.uid()` or `pin` match) | Update `last_active_at` only |
| `orders` | Read own orders only (`customer_id` match) | Insert only with own `customer_id`, status='pending' |
| `order_items` | Read items for own orders | Insert only linked to own orders |
| `rate_list` | Read all (`is_available = true`) | None |
| `categories` | Read all (`is_active = true`) | None |
| `chuda_customization_options` | Read all (`is_active = true`) | None |
| `tag_master` | Read all | None |
| `app_settings` | Read all | None |

#### Admin App (anon role — needs admin verification)
| Table | Read Policy | Write Policy |
|-------|------------|--------------|
| `customers` | Read all | Full CRUD (admin role) |
| `orders` | Read all | Full CRUD (admin role) |
| `order_items` | Read all | Full CRUD (admin role) |
| `rate_list` | Read all | Full CRUD (admin role) |
| `categories` | Read all | Full CRUD (admin role) |
| `cutmails` | Read all | Full CRUD (admin role) |
| `cutmail_sizes` | Read all | Full CRUD (admin role) |
| `chuda_customization_options` | Read all | Full CRUD (admin role) |
| `tag_master` | Read all | Full CRUD (admin role) |
| `app_settings` | Read all | Full CRUD (admin role) |
| `materials` | Read all | Full CRUD (admin role) |
| `cost_breakdown` | Read all | Full CRUD (admin role) |
| `item_materials` | Read all | Full CRUD (admin role) |

#### Labour App (anon role)
| Table | Read Policy | Write Policy |
|-------|------------|--------------|
| `customers` | None | None |
| `orders` | None | None |
| `cutmails` | Read all | Create only |
| `cutmail_sizes` | Read all | Create only |
| `rate_list` | Read all | None |
| `categories` | Read all | None |

---

## 4. Storage Bucket Audit

### 4.1 Current Configuration

**Bucket:** `product-images`
**Visibility:** Public (images accessible via public URLs)

### 4.2 Storage Operations by App

| App | Operation | File | Path |
|-----|-----------|------|------|
| Admin | Upload category cover | `storage_service.dart` | `category_covers/{slug}.jpg` |
| Admin | Upload product image | `storage_service.dart` | `items/{slug}.jpg` |
| Admin | Upload order PDF | (not implemented) | `order-pdfs/slip_{id}.pdf` |
| Customer | Read only | Various | Via public URLs |

### 4.3 Storage Risks

| Risk | Severity | Detail |
|------|----------|--------|
| Anon key can upload/overwrite files | 🔴 High | Any browser user can upload to `product-images` bucket |
| No file size limits enforced client-side | 🟡 Medium | Large uploads could consume storage quota |
| No file type validation | 🟡 Medium | Attacker could upload executable files |
| Public URLs expose raw file access | 🟡 Medium | Direct file access without auth |

### 4.4 Recommended Storage Policies

```sql
-- Allow public read
CREATE POLICY "Public read access" ON storage.objects
  FOR SELECT USING (bucket_id = 'product-images');

-- Allow authenticated upload only (admin role)
CREATE POLICY "Admin upload access" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'product-images' AND auth.role() = 'authenticated');

-- Allow authenticated update only (admin role)
CREATE POLICY "Admin update access" ON storage.objects
  FOR UPDATE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');

-- Allow authenticated delete only (admin role)
CREATE POLICY "Admin delete access" ON storage.objects
  FOR DELETE USING (bucket_id = 'product-images' AND auth.role() = 'authenticated');
```

---

## 5. Route Guard Audit

### 5.1 Admin App Routes

| Route | Guard | Protection Level |
|-------|-------|------------------|
| `/login` | None (public) | ✅ Correct |
| `/dashboard` | `appSessionProvider` check | ⚠️ Client-side only |
| `/orders` | `appSessionProvider` check | ⚠️ Client-side only |
| `/catalogue` | `appSessionProvider` check | ⚠️ Client-side only |
| `/customers` | `appSessionProvider` check | ⚠️ Client-side only |
| `/settings` | `appSessionProvider` check | ⚠️ Client-side only |
| `/catalogue/:name` | `appSessionProvider` check | ⚠️ Client-side only |
| `/catalogue/:name/edit/:item` | `appSessionProvider` check | ⚠️ Client-side only |
| `/customers/:id` | `appSessionProvider` check | ⚠️ Client-side only |
| `/orders/:id` | `appSessionProvider` check | ⚠️ Client-side only |

### 5.2 Guard Implementation

```dart
// From admin/router.dart
redirect: (context, state) {
  final session = ref.read(appSessionProvider);
  final isLoggedIn = session.role == AuthRole.admin || session.role == AuthRole.labour;
  
  if (!isLoggedIn && !state.matchedLocation.startsWith('/login')) {
    return '/login';
  }
  // ...
}
```

**Risk:** This is purely client-side. The session is stored in `localStorage`. An attacker can:
1. Set `localStorage['app_session']` to a valid JSON string
2. Navigate to any admin route
3. The redirect will not block them

**Mitigation:** Add server-side JWT validation or use Supabase Auth.

---

## 6. CORS Configuration

### 6.1 Current Status

Supabase projects have default CORS settings that allow `localhost` origins. For production web deployment, the following domains must be added to Supabase CORS configuration:

### 6.2 Required CORS Origins

| Domain | Purpose |
|--------|---------|
| `https://app.mahalaxmibangles.com` | Customer web app |
| `https://admin.mahalaxmibangles.com` | Admin web app |
| `https://*.mahalaxmibangles.com` | Wildcard for subdomains |

### 6.3 How to Configure

1. Go to Supabase Dashboard → Project Settings → API
2. Scroll to "Additional CORS origins"
3. Add the domains listed above
4. Save changes

---

## 7. Threat Model

### 7.1 Attack Vectors

| Vector | Likelihood | Impact | Current Mitigation |
|--------|-----------|--------|-------------------|
| Direct REST API calls with anon key | 🔴 High | 🔴 Critical | None — RLS disabled |
| Password brute-force | 🟡 Medium | 🔴 Critical | None — no rate limiting |
| Session hijacking via localStorage | 🟡 Medium | 🔴 High | None — no JWT expiry |
| Storage bucket abuse | 🟡 Medium | 🟡 Medium | None — anon key has write access |
| Image/file upload malicious content | 🟡 Medium | 🟡 Medium | None — no file type validation |
| Order data scraping | 🔴 High | 🟡 Medium | None — full read access |
| Customer PIN enumeration | 🔴 High | 🔴 Critical | None — full read access |

### 7.2 Attacker Profile

**External attacker (no credentials):**
- Can query all tables via REST API
- Can read all customer PINs
- Can read/modify/delete all orders
- Can upload/overwrite product images
- Can access all business data

**This is the most critical security gap in the entire application.**

---

## 8. Recommendations

### 8.1 Immediate (Before Web Launch)

| Priority | Action | Effort |
|----------|--------|--------|
| 🔴 P0 | **Migrate auth to Supabase Auth** — Replace hardcoded passwords with JWT-based auth. Use `auth.uid()` in RLS policies. | High |
| 🔴 P0 | **Enable RLS on all tables** — Apply RLS policies as described in Section 3.4 | Medium |
| 🔴 P0 | **Restrict storage bucket** — Add RLS policies for `product-images` bucket | Low |
| 🟡 P1 | **Add Cloudflare Access** — Zero-trust proxy before admin web app | Medium |
| 🟡 P1 | **Configure CORS** — Add production domains to Supabase CORS settings | Low |

### 8.2 Short-Term (Within 2 Weeks)

| Priority | Action | Effort |
|----------|--------|--------|
| 🟡 P2 | **Add session expiry** — Auto-logout after 8 hours of inactivity | Low |
| 🟡 P2 | **Add rate limiting** — Prevent brute-force on login endpoint | Low |
| 🟡 P2 | **Audit storage file types** — Validate uploaded files are images/PDFs only | Low |

### 8.3 Medium-Term (Before Production)

| Priority | Action | Effort |
|----------|--------|--------|
| 🟢 P3 | **Move passwords to environment variables** — At minimum, don't hardcode in source | Low |
| 🟢 P3 | **Add audit logging** — Track who modified orders/customers | Medium |
| 🟢 P3 | **Implement 2FA for admin** — TOTP or SMS verification | High |

---

## 9. Migration Path to Supabase Auth

### 9.1 Current Flow
```
Admin enters password → AuthController checks hardcoded constant → Session stored in SharedPreferences
```

### 9.2 Target Flow
```
Admin enters email/password → Supabase Auth.login() → JWT stored in Supabase session → RLS policies check auth.uid()
```

### 9.3 Changes Required

1. **Create admin users in Supabase Auth** — Each admin gets a Supabase Auth account (email + password)
2. **Update `auth_provider.dart`** — Replace hardcoded password check with `Supabase.instance.client.auth.signInWithPassword()`
3. **Update RLS policies** — Use `auth.uid()` to identify the current user
4. **Update `session_provider.dart`** — Store Supabase session instead of custom session
5. **Update route guards** — Check `Supabase.instance.client.auth.currentUser` instead of custom session

### 9.4 Benefits

- Server-side password validation (no hardcoded secrets in client)
- JWT-based session with expiry
- RLS policies can enforce per-user access control
- Audit trail via Supabase Auth logs
- Support for MFA/2FA

---

## 10. SQL Migration Files Prepared

See the following migration files for RLS hardening:

- **`migration_docs/007_admin_web_rls_hardening.sql`** — Full RLS policies for all tables
- **`migration_docs/008_storage_bucket_policies.sql`** — Storage bucket access control

> ⚠️ **DO NOT run these migrations automatically.** Review and run manually in Supabase SQL Editor after confirming the auth migration path.

---

## 11. Summary

| Area | Status | Risk |
|------|--------|------|
| Service-role keys | ✅ Not exposed | 🟢 Low |
| Hardcoded passwords | 🔴 Exposed in source | 🔴 Critical |
| Client-side auth | 🟡 localStorage-based | 🔴 Critical |
| RLS policies | 🔴 Disabled on all tables | 🔴 Critical |
| Storage bucket | 🔴 No write restrictions | 🔴 High |
| Route guards | 🟡 Client-side only | 🟡 Medium |
| CORS configuration | ⚠️ Needs setup | 🟡 Medium |

**Overall Risk Level:** 🔴 **CRITICAL** — Must address before production web deployment.

**Recommended Approach:**
1. ✅ Add Cloudflare Access (P1) — **DONE** (interim outer gate)
2. Migrate to Supabase Auth (P0)
3. Enable RLS with proper policies (P0)
4. Configure CORS (P1)

### Interim Protection: Cloudflare Access

Cloudflare Access has been deployed as an interim security layer while Supabase Auth/RLS hardening is pending.

**What Cloudflare Access does:**
- Blocks all visitors at the Cloudflare edge before they reach the Flutter app
- Only approved email addresses can access `admin.mahalaxmibangles.com`
- Login via one-time PIN (email OTP)

**What Cloudflare Access does NOT do:**
- Does not protect against Supabase REST API calls with the anon key
- Does not enforce database-level access control
- Does not replace RLS policies
- Does not protect against hardcoded password exposure in the JS bundle

**Remaining risks after Cloudflare Access:**
1. Anyone with the anon key can still call Supabase REST API directly (bypassing the web app)
2. Hardcoded passwords are still visible in the compiled JS bundle
3. No server-side session validation
4. No database-level row access control

**These risks remain until Supabase Auth/RLS hardening is complete.**

---

*This audit was conducted on 2026-07-06. Findings apply to the codebase as of that date.*
