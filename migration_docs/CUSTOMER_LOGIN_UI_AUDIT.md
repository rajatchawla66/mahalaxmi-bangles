# Customer Login UI Audit — Flet vs Flutter

## 1. Comparison Table

| Element | Old Flet Login | Current Flutter Login | Status |
|---------|---------------|----------------------|--------|
| **Business name** | "Mahalaxmi Bangles" (26pt, w300) | On landing page only (28pt, w300) | Missing on login page |
| **Logo** | watermark.png, 140×140, centered | watermark.png, 100×100, on landing + login | Present on login |
| **Tagline** | "Wholesale Bridal Chuda Manufacturer" (12pt) | On landing page only | Missing on login |
| **GST** | 08AHPPC2086C1ZI in gold-bordered card | Not present | ❌ Missing |
| **Address** | I-10, Gate No 5, Bada Bazar, Sri Ganganagar, Rajasthan | Not present | ❌ Missing |
| **WhatsApp contact** | `wa.me/917976482969` with CHAT icon card | Not present | ❌ Missing |
| **Instagram** | `instagram.com/mb_sgnr/` with CAMERA icon card | Not present | ❌ Missing |
| **Google Maps** | `maps.app.goo.gl/b6qLbcbSAfPvRZGB7` with LOCATION icon card | Not present | ❌ Missing |
| **YouTube** | Coming soon, PLAY_CIRCLE icon card | Not present | ❌ Missing |
| **Heritage text** | "Serving the bangle industry for more than 20 years." | Not present | ❌ Missing |
| **PIN field** | 8-digit numeric, centered, lock icon, 280px wide | 8-digit numeric, obscured, centered, 24pt font | ✅ Equivalent |
| **Login button** | Maroon `#800020`, 200×44, radius 22 | Maroon `kMaroon`, full-width, radius 12, spinner loading | ✅ Better in Flutter |
| **Error handling** | Red text below field, visible=false toggle | Maroon error banner with background fill | ✅ Better in Flutter |
| **Disabled account** | "Your account is blocked. Please contact Mahalaxmi Bangles." | "Your account has been disabled. Please contact Mahalaxmi Bangles." | ✅ Equivalent |
| **"Secure & Trusted" label** | Green lock icon + muted text | Not present | ❌ Missing |
| **Admin/Labour links** | Two TextButtons "Admin Login" + "Labour Login" | "Admin / Staff Login" on landing page (no-op) | ❌ Broken |
| **Back button** | None on branded login; legacy had back arrow | TextButton "Back" → landing page | ✅ Present |
| **Exit dialog** | System exit on back from root | PopScope with confirm dialog | ✅ Equivalent |
| **Session restore** | JSON file in app storage | SharedPreferences with validation | ✅ Better in Flutter |
| **Image caching** | No cache | CachedNetworkImage added Phase 1 | ✅ Better in Flutter |

---

## 2. Old Flet Login Screen Layout

```
┌─────────────────────────────────────┐
│          (top spacer 24px)          │
│         ┌─────────────┐             │
│         │  watermark  │  140×140    │
│         │    .png     │             │
│         └─────────────┘             │
│                                     │
│       Mahalaxmi Bangles             │  26pt, w300, dark
│  Wholesale Bridal Chuda Mfr.        │  12pt, muted
│                                     │
│       ── ✦ ──                       │  gold divider
│                                     │
│  ┌─────────────────────────────┐    │
│  │  GST: 08AHPPC2086C1ZI       │    │  transparent gold border
│  └─────────────────────────────┘    │
│                                     │
│       Enter Customer PIN            │  14pt, bold
│  ┌─────────────────────────────┐    │
│  │ 🔒    ••••••••              │    │  PIN field
│  └─────────────────────────────┘    │
│                                     │
│     ┌───────────────────────┐       │
│     │       Continue        │       │  Maroon #800020
│     └───────────────────────┘       │
│                                     │
│  🔒 Secure & Trusted                │
│                                     │
│  I-10, Gate No 5, Bada Bazar        │
│  Sri Ganganagar, Rajasthan          │
│                                     │
│       Connect With Us               │  section header
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
│  │ 📷   │ │ 💬   │ │ 📍   │ │ ▶️   ││  2×2 contact cards
│  │ Insta │ │ What- │ │ Maps  │ │ You- ││  145×68 each
│  │       │ │ sApp  │ │       │ │ Tube ││
│  └──────┘ └──────┘ └──────┘ └──────┘│
│                                     │
│  ┌─────────────────────────────┐    │
│  │ Serving the bangle industry │    │  gold-tinted heritage
│  │ ... for more than 20 years  │    │  container
│  └─────────────────────────────┘    │
│                                     │
│        Admin Login                   │  TextButton
│        Labour Login                  │  TextButton
└─────────────────────────────────────┘
```

---

## 3. Current Flutter Login Screen Layout

```
┌─────────────────────────────────────┐
│                                     │
│         ┌─────────────┐             │
│         │  watermark  │  100×100    │
│         │    .png     │             │
│         └─────────────┘             │
│                                     │
│         Customer Login              │  22pt, w700, dark
│  Enter your 8-digit PIN to continue │  14pt, muted
│                                     │
│  ┌─────────────────────────────┐    │
│  │       ••••••••              │    │  24pt, centered
│  └─────────────────────────────┘    │
│                                     │
│  ┌─── Error message (if any) ───┐   │  maroon bg, 8% opacity
│  └──────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │           Login             │    │  full-width, maroon
│  └─────────────────────────────┘    │
│                                     │
│            < Back                   │  TextButton
│                                     │
└─────────────────────────────────────┘
```

---

## 4. Missing Items (from Flet but absent in Flutter)

| Priority | Item | Reason |
|----------|------|--------|
| **P0** | WhatsApp contact link | Customers need support for forgotten PIN / account issues |
| **P0** | Business address | Establishes trust; physical location visible |
| **P1** | Heritage/description text | Brand identity |
| **P1** | "Secure & Trusted" label | Reassurance for PIN entry |
| **P1** | Contact cards section (WhatsApp, Maps, Instagram) | OLD FLET STYLE — 2×2 grid of contact cards |
| **P2** | GST number | B2B trust signal |
| **P2** | Instagram link | Social presence |
| **P2** | YouTube link | Promotional content (coming soon) |
| **P2** | GST display card | Professional appearance |
| **P3** | Admin/Labour login buttons | Low-use; admin has own app |

---

## 5. Recommended New Flutter Login Layout

```
┌─────────────────────────────────────┐
│  ← scrollable column →              │
│                                     │
│         ┌─────────────┐             │
│         │  watermark  │  120×120    │  slightly smaller than Flet
│         │    .png     │             │
│         └─────────────┘             │
│                                     │
│       Mahalaxmi Bangles             │  26pt, w300, kDark
│  Wholesale Bridal Chuda Mfr.        │  12pt, kMuted
│                                     │
│       ─── ✦ ───                     │  gold divider
│                                     │
│  ┌─────────────────────────────┐    │
│  │  GST: 08AHPPC2086C1ZI       │    │  transparent kGold border card
│  └─────────────────────────────┘    │
│                                     │
│       Enter Customer PIN            │  14pt, bold, kDark
│  ┌─────────────────────────────┐    │
│  │ 🔒    ••••••••              │    │  24pt, centered (keep current)
│  └─────────────────────────────┘    │
│                                     │
│  ┌─── Error/Disabled msg ───────┐   │  existing maroon banner
│  └──────────────────────────────┘   │
│                                     │
│     ┌───────────────────────┐       │
│     │        Login          │       │  existing maroon button
│     └───────────────────────┘       │
│                                     │
│  🔒 Secure & Trusted                │  12pt, kMuted, lock icon
│                                     │
│  ┌─────────────────────────────┐    │
│  │ I-10, Gate No 5, Bada Bazar │    │  centered, 12pt, kMuted
│  │ Sri Ganganagar, Rajasthan   │    │
│  └─────────────────────────────┘    │
│                                     │
│       Connect With Us               │  14pt, bold, kDark
│                                     │
│  ┌───────────┐ ┌───────────┐        │
│  │ 💬        │ │ 📍        │        │  2 contact cards
│  │ WhatsApp  │ │ Maps      │        │  (Instagram deferred)
│  └───────────┘ └───────────┘        │
│                                     │
│  Serving the bangle industry with   │
│  trust, quality & tradition for     │  heritage text, gold-tinted
│  more than 20 years.                │
│                                     │
│            < Back                   │  existing TextButton
│                                     │
└─────────────────────────────────────┘
```

### Layout rules:
- **Scrollable**: Whole page wrapped in `SingleChildScrollView` to handle small phones + keyboard
- **Top alignment**: Content starts from top (not centered) — more content to show
- **PIN field + Login button**: Keep current implementation (maroon button, spinner, validation, disabled-account banner)
- **Contact cards**: 2 per row, matching Flet's visual style but using Flutter `Card` widgets with `InkWell`

---

## 6. Recommended Business Info Fields

| Field | Value | Storage |
|-------|-------|---------|
| `businessName` | "Mahalaxmi Bangles" | Constants file |
| `tagline` | "Wholesale Bridal Chuda Manufacturer" | Constants file |
| `gst` | "08AHPPC2086C1ZI" | Constants file |
| `address` | "I-10, Gate No 5, Bada Bazar\nSri Ganganagar, Rajasthan" | Constants file |
| `phone` | "+917976482969" | Constants file |
| `whatsappUrl` | `https://api.whatsapp.com/send?phone=917976482969&text=Hi%2C%20I%20need%20help%20with%20the%20Customer%20Pin%20in%20the%20app.` | Constants file |
| `mapsUrl` | `https://maps.app.goo.gl/b6qLbcbSAfPvRZGB7` | Constants file |
| `instagramUrl` | `https://www.instagram.com/mb_sgnr/` | Constants file (deferred) |
| `heritageText` | "Serving the bangle industry with trust, quality & tradition for more than 20 years." | Constants file |

**Recommendation for v1:** Put all in `mahalaxmi_customer/lib/constants/business_info.dart` (new file). Hardcoded. Admin-editable via Supabase can be a future enhancement (Phase 2).

---

## 7. Required Packages

| Package | Needed for | Current status |
|---------|-----------|---------------|
| `url_launcher` | Opening WhatsApp, Maps, Instagram, phone links | **Not present** — must add to `mahalaxmi_customer/pubspec.yaml` |

No other packages needed. The `cached_network_image` package is already added (Phase 1).

---

## 8. Recommended Implementation Phases

### Phase 1 — Constants + layout scaffolding (safe, pure UI)

| Step | File | Change |
|------|------|--------|
| 1 | `mahalaxmi_customer/lib/constants/business_info.dart` | NEW — all business details, URL constants |
| 2 | `login_page.dart` | Add scrollable layout, business header section, address, heritage text |
| 3 | `theme.dart` (optional) | Add gold divider helper if not already present |
| 4 | Run `dart analyze` | Verify no regressions |

**No `url_launcher` needed yet.** Contact cards can exist as inert UI (showing the buttons but doing nothing on tap).

### Phase 2 — External links (requires `url_launcher`)

| Step | File | Change |
|------|------|--------|
| 1 | `mahalaxmi_customer/pubspec.yaml` | Add `url_launcher: ^6.3.0` |
| 2 | `login_page.dart` | Wire `onTap` on contact cards to `launchUrl()` |
| 3 | Run `dart analyze` | Verify |
| 4 | Build APK, test on device | Verify WhatsApp/Maps open correctly |

### Phase 3 — Admin-editable business info (future)

| Step | File | Change |
|------|------|--------|
| 1 | `supabase` | Add `business_config` table or column |
| 2 | `mahalaxmi_shared` | Add repository/provider for config |
| 3 | `login_page.dart` | Replace constants read with provider read |

---

## 9. Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| **Long login page on small phones** | `SingleChildScrollView` handles overflow; keyboard pushes content |
| **PIN field hidden behind keyboard** | `SingleChildScrollView` + `resizeToAvoidBottomInset: true` (default) |
| **`url_launcher` permission on Android** | Only needs `<queries><intent>` in manifest for VIEW intents — `url_launcher` handles this |
| **WhatsApp not installed** | `launchUrl` with `LaunchMode.externalApplication` — system shows chooser or browser fallback |
| **No internet** | Contact cards silently fail (no crash) — `launchUrl` throws catchable `PlatformException` |
| **Gold divider not matching theme** | Use existing `kGold` color, simple `Container` with height:1, width:40 |
| **Login regression** | Core login logic unchanged — only wrapping in scroll view + adding decorative elements above |
| **Back navigation broken** | Keep existing `TextButton("Back")` behavior — no router changes |

---

## 10. Manual Testing Plan

1. **Landing page**: Verify "Mahalaxmi Bangles" + tagline + watermark shown correctly
2. **Login page scroll**: Open on 4" phone — verify all content reachable by scrolling
3. **Keyboard handling**: Tap PIN field — verify keyboard pushes content, page scrolls, login button visible
4. **PIN login**: Enter correct PIN → verify navigates to dashboard (existing flow unchanged)
5. **Wrong PIN**: Enter wrong PIN → verify error message shown (existing flow unchanged)
6. **Disabled account**: Login with disabled customer → verify disabled message shown (existing flow unchanged)
7. **Contact cards (if wired)**: Tap WhatsApp → verify opens WhatsApp with pre-filled message
8. **Contact cards (if wired)**: Tap Maps → verify opens Google Maps to showroom location
9. **Back button**: Tap "Back" → verify returns to landing page
10. **Session restore**: Login, kill app, reopen → verify goes to dashboard (no login screen)
11. **Analyze**: `dart analyze mahalaxmi_customer` → zero errors
12. **Build**: `flutter build apk` → success
