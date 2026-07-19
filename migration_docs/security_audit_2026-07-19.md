# Security Audit Report — 2026-07-19

**Scope:** GitHub repository, Supabase project, CI/CD, dependencies, Flutter client code
**Auditor:** Automated scan

---

## 🔴 CRITICAL

### 1. GitHub PAT exposed in git history
- **Token:** `ghp_***` (redacted — see commit `180abb7` for full value)
- **Committed in:** `180abb7` (2 locations in `PROJECT_MEMORY.md`)
- **Removed in:** `aed6f4b` — but still recoverable from git history
- **Scopes:** `repo` + `workflow`
- **Action:** Revoke at `github.com/settings/tokens` if not already done. Token may already be regenerated (ref: earlier commit messages claim regeneration).

### 2. RLS disabled on all production tables
- All business tables (`customers`, `orders`, `rate_list`, `categories`, `order_items`, `chuda_customization_options`, `app_settings`, `materials`, `cost_breakdown`, `item_materials`, `tag_master`) have **no RLS**.
- Anon key is embedded in web JS bundle → anyone can query the Supabase REST API directly.
- **Critical exposure:** `GET /rest/v1/customers?select=pin,shop_name,mobile` returns all customer PINs, enabling full impersonation.
- 4 tables with RLS enabled (`cutmails`, `cutmail_sizes`, `cost_calculations`, `material_settings`) use `FOR ALL USING (true)` — no actual protection.
- Full RLS hardening script exists at `migration_docs/007_admin_web_rls_hardening.sql` (613 lines) but was **never applied**.

### 3. No Supabase Auth — hardcoded passwords
- **File:** `mahalaxmi_shared/lib/providers/auth_provider.dart:19-20`
- `const _adminPassword = 'admin123';`
- `const _labourPassword = 'labour123';`
- Single shared password for all users of each role, visible in web JS bundle via DevTools.
- No rate limiting, no hashing, no server-side validation.
- Session stored as plain JSON in `localStorage`/`SharedPreferences`, trivially forgeable by setting `localStorage['app_session']`.

---

## 🔴 HIGH

### 4. Labour app `.gitignore` missing `.env`
- **File:** `mahalaxmi_labour/.gitignore` (45 lines)
- Missing `.env` exclusion. Currently saved by root `.gitignore` line 69 (`.env`). If root `.gitignore` is ever removed or modified, the labour app's `.env` (containing `SUPABASE_ANON_KEY`) would be committed.

### 5. Labour app missing `INTERNET` permission
- **File:** `mahalaxmi_labour/android/app/src/main/AndroidManifest.xml`
- No `<uses-permission android:name="android.permission.INTERNET"/>`. Release builds may fail silently on network calls.

### 6. Storage bucket unprotected
- Anon key can upload/overwrite files in `product-images` bucket. No RLS on storage operations.

---

## 🟡 MEDIUM

### 7. Test file hits production database
- **File:** `mahalaxmi_shared/test/scratch_db_test.dart`
- Contains hardcoded Supabase URL and anon key; runs `client.from('categories').select('*')` against production when executed.

### 8. CI actions not pinned to SHA digests
- **File:** `.github/workflows/ios_build.yml`
  - `actions/checkout@v4` (line 11)
  - `subosito/flutter-action@v2` (line 13)
  - `actions/upload-artifact@v4` (line 91)
- Mutable version tags — if a tag is updated to a malicious version, the workflow will execute it.

### 9. Secrets written via `echo` (shell injection risk)
- **File:** `.github/workflows/ios_build.yml:75-76`
- `echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" > .env`
- If a secret contained shell-special characters (`$`, `` ` ``, `\`), injection is possible. Supabase anon key is a safe base64 JWT, but defense-in-depth recommends `env:` context or a dedicated action.

### 10. No `.gitattributes`
- No `.gitattributes` file in the repository root. Cross-platform line endings may cause spurious diffs. Binary files (PNG, JPG, PDF) lack diff hints.

### 11. Plaintext session storage
- **File:** `mahalaxmi_shared/lib/services/session_storage.dart:30-57`
- Session data stored as plain JSON in `SharedPreferences`/`localStorage`.
- **File:** `mahalaxmi_shared/lib/services/cart_persistence_service.dart:7-39`
- Cart data stored as plain JSON keyed by customer ID.

### 12. No session expiry
- Sessions persist indefinitely in `localStorage`/`SharedPreferences` until explicit logout. On a shared computer, the next user inherits the admin session.

### 13. CORS not configured
- No production domains (`app.mahalaxmibangles.com`, `admin.mahalaxmibangles.com`) configured in Supabase CORS settings.

---

## 🟢 LOW

### 14. Development `applicationId` (`com.example.*`)
- **File:** `mahalaxmi_admin/android/app/build.gradle.kts:20` — `applicationId = "com.example.mahalaxmi_admin"`
- **File:** `mahalaxmi_admin/lib/features/catalogue/pages/add_item_page.dart:100` — `MethodChannel('com.example.mahalaxmi_admin/file_picker')`
- `com.example` is marked by Google as for development only. Change to `com.mahalaxmibangles.*` before Play Store publication.

### 15. Debug print statements in production code
- **File:** `mahalaxmi_shared/lib/repositories/customer_repository.dart:111,117,119,126`
- **File:** `mahalaxmi_shared/lib/services/cart_persistence_service.dart:30`
- `debugPrint()` calls only execute in debug mode. Low risk.

### 16. Hardcoded anon key in legacy/doc files
- `mahalaxmi_shared/test/scratch_db_test.dart:8` — test file
- `EXPECTED_FLUTTER_FEATURES_FROM_FLET.md:242` — documentation

### 17. HTTP client without certificate pinning
- `order_pdf_service.dart:43`, `share_photo_service.dart:65` — uses `http.get()` without pinning. Acceptable for this use case (all requests to Supabase HTTPS).

---

## ✅ Already Good

| Item | Status |
|------|--------|
| `.env` files gitignored in all 3 apps | ✅ Confirmed — none ever committed |
| No `service_role` key in any Flutter client | ✅ Confirmed — anon key only |
| Repository pattern followed | ✅ No direct Supabase calls from UI |
| All dependencies use caret constraints | ✅ Lock files tracked, no known CVEs |
| No `http://` connections | ✅ All HTTPS |
| No `eval()` / code injection | ✅ Clean |
| pubspec.lock files tracked | ✅ Reproducible builds |

---

## Priority Fixes

```
P0: Revoke compromised PAT (if not already done)
P0: Apply 007_admin_web_rls_hardening.sql (after auth migration)
P0: Migrate auth to Supabase Auth (replace hardcoded passwords)
P1: Add .env to mahalaxmi_labour/.gitignore
P1: Add INTERNET permission to mahalaxmi_labour AndroidManifest.xml
P1: Add storage bucket RLS policies
P1: Rename scratch_db_test.dart to .skip
P2: Pin CI actions to SHA digests
P2: Use env: context for secrets in CI
P2: Create .gitattributes
P2: Add session expiry (8-hour timeout)
P2: Configure CORS in Supabase dashboard
P3: Change com.example to com.mahalaxmibangles.*
P3: Remove or guard debugPrint statements
```
