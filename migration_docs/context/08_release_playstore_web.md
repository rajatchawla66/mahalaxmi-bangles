# 08 — Release, Play Store & Web

## APK Build (Customer App)

```bash
cd mahalaxmi_customer

# Standard — split by ABI
flutter build apk --release --split-per-abi

# Faster rebuild (skips Flutter validation when deps unchanged)
cd android && .\gradlew assembleRelease
```

### Signing
- Release signing via `key.properties` (production keystore)
- `android/app/build.gradle.kts` uses `signingConfigs.getByName("release")`
- Three split APKs generated in `build/app/outputs/flutter-apk/`

### Current Build Sizes (2026-07-05)
| ABI | Size |
|-----|------|
| `arm64-v8a` | 22.2 MB |
| `armeabi-v7a` | 19.5 MB |
| `x86_64` | 23.5 MB |

### AAB (Play Store)
```bash
flutter build appbundle --release
```
Produces `build/app/outputs/bundle/release/app-release.aab` (~46.4 MB).

## App Icon & Splash

- **Source:** `assets/app_icon.png` (1024×1024, white bg with centered watermark)
- **Adaptive icon:** White background, centered foreground, 15% safe-zone padding
- **Splash:** White background with centered `app_icon.png` — no animation
- **Configuration:** `flutter_launcher_icons` + `flutter_native_splash` dev dependencies in `pubspec.yaml`
- **No iOS config** (not targeting iOS for v0.1.0)

## Web Build

### Customer App
```bash
cd mahalaxmi_customer && flutter build web --release
```

- Output in `build/web/`
- Deployed at `https://app.mahalaxmibangles.com`
- Hosting: Cloudflare/Firebase (confirm current provider)

### Admin App (2026-07-06)
```bash
cd mahalaxmi_admin && flutter build web --release --dart-define-from-file=.env
```

- Output in `build/web/`
- Planned URL: `https://admin.mahalaxmibangles.com`
- Same codebase as Android APK — no separate web codebase

### Web Readiness Considerations

- `SystemNavigator.pop()` guarded with `kIsWeb` — SnackBar shown instead
- Image picker uses `Uint8List` network/bytes flow (web-compatible)
- PDF generation is client-side (no server dependency)
- No web-specific splash (handled by HTML/CSS separately)
- Session stored in `SharedPreferences` (works via `shared_preferences_web`)
- Share photo service uses `Uint8List` + `share_plus` (Web Share API on web, native share on mobile)

### Admin Web Hosting (Cloudflare Pages)

> ⚠️ **CRITICAL:** Admin web MUST be deployed behind Cloudflare Access. Do NOT deploy as an open public site until Supabase Auth/RLS hardening is complete.

#### Why No iOS IPA?

- No Mac/Xcode available in the current development environment
- No Apple Developer account enrolled
- Ad Hoc IPA requires both — cannot be built on Windows
- **Workaround:** Admin web on iPhone via Safari, protected by Cloudflare Access

#### Build Command

```bash
cd mahalaxmi_admin && flutter build web --release --dart-define-from-file=.env
```

#### Build Output

```
mahalaxmi_admin/build/web
```

#### Cloudflare Pages Setup

1. **Log in to Cloudflare Dashboard** → `dash.cloudflare.com`
2. **Go to Workers & Pages** → Create application → Pages
3. **Project name:** `admin-mahalaxmibangles`
4. **Deployment method:** Upload assets (or connect Git repo for auto-deploy)
5. **Build configuration (if using Git):**
   - Build command: `cd mahalaxmi_admin && flutter build web --release --dart-define-from-file=.env`
   - Build output directory: `mahalaxmi_admin/build/web`
   - Root directory: `/` (repo root)
6. **Custom domain:** Add `admin.mahalaxmibangles.com`
7. **DNS:** Cloudflare auto-creates CNAME record pointing to Pages deployment
8. **SSL:** Automatic (Cloudflare manages certificates)

#### SPA Rewrite (Required)

Cloudflare Pages automatically serves `index.html` for all paths — no manual `_redirects` file needed.

#### Cloudflare Access Setup (Required Before Launch)

This is the outer security gate that prevents public access to the admin app.

1. **Go to Cloudflare Zero Trust Dashboard** → `one.dash.cloudflare.com`
2. **Navigation:** Access → Applications → Add application
3. **Application type:** Self-hosted
4. **Configuration:**
   - Application name: `Mahalaxmi Admin`
   - Session duration: 24 hours (or as preferred)
   - Application domain: `admin.mahalaxmibangles.com`
5. **Add policy:**
   - Policy name: `Admin Only`
   - Action: Allow
   - Include → Emails: `your-email@example.com` (owner/admin email only)
   - Exclude: (leave empty)
6. **Login method:** One-time PIN (email OTP) — no additional identity provider needed
7. **Save**

**How it works:**
- When anyone visits `admin.mahalaxmibangles.com`, Cloudflare Access intercepts the request
- If not logged in or email not in allow-list → blocked with Cloudflare login page
- If email matches → Cloudflare issues a session cookie → user reaches the admin app
- The admin app's own route guards then check for a valid session

**Result:** Only the approved email address can access the admin web app. All other visitors are blocked at the Cloudflare edge, before reaching the Flutter app.

#### Security Notes

- Admin web is for owner/admin use only — not public-facing
- Cloudflare Access is the outer gate (prevents unauthorized access)
- Supabase RLS must protect data at the database level (web code is publicly downloadable like any browser app)
- Only anon/public Supabase key should be used in web build (no service-role keys)
- Admin authorization enforced by backend/RLS, not just hidden UI
- **Cloudflare Access does NOT replace Supabase Auth/RLS** — it's an additional layer

## Play Store Preparation

### Privacy Policy
- App uses customer PIN, phone, order data stored in Supabase
- Images stored in Supabase Storage `product-images` bucket
- No third-party analytics or ad SDKs
- Privacy policy needed before Play Store submission

### Data Safety Section (Play Console)
- **Personal data collected:** Name, phone, PIN (authentication only), order history
- **Data shared:** None (no third-party sharing)
- **Data encryption:** HTTPS for all API calls
- **Data deletion:** Account deactivation available via admin

### Steps Before Submission
1. Publish privacy policy page (link in app + Play Console)
2. Complete Play Console Data Safety form
3. Set up app signing by Google Play (or upload keystore)
4. Create store listing with screenshots (1080×1350 product feed, login page, etc.)
5. Set content rating questionnaire
6. Test AAB on internal testing track first

## Build Warnings (Non-blocking)

1. **Kotlin Gradle Plugin deprecation** — plugins `shared_preferences_android`, `url_launcher_android` apply KGP. Future Flutter versions will fail.
2. **Tree-shook MaterialIcons** — 99.7% reduction (expected, only used icons included).
