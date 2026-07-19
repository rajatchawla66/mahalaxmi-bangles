# Mahalaxmi Flutter Workspace

## Workspace Structure

```
workspace/                          # C:\Users\rajat\Labour-receipt
│
├── legacy_flet_app/                # FROZEN — Flet reference implementation
│   ├── main.py                     # Entry point (Python/Flet)
│   ├── db.py                       # Supabase database layer
│   ├── views/                      # Flet UI views (customer, pricing, orders, settings, ...)
│   ├── assets/                     # Fonts (HindiFont.ttf), icons, watermarks
│   ├── sql/                        # SQL migrations (tags, categories, production status, ...)
│   ├── android/                    # Flet-embedded Android APK build files
│   ├── .github/workflows/          # GitHub Actions CI (Flet APK build)
│   ├── *.md                        # Architecture docs, project memory, audits
│   └── mahalaxmi_flet_backup_*.zip # Full source backup
│
├── mahalaxmi_shared/               # Shared Dart package
│   ├── lib/
│   │   ├── models/                 # Freezed data models
│   │   ├── repositories/           # Supabase data access layer
│   │   ├── services/               # Business logic
│   │   ├── providers/              # Riverpod providers
│   │   ├── constants/              # App-wide constants
│   │   ├── theme/                  # Shared theme definitions
│   │   ├── utils/                  # Utility functions
│   │   └── widgets/                # Shared Flutter widgets
│   └── pubspec.yaml
│
├── mahalaxmi_customer/             # Customer Flutter app
│   ├── lib/
│   │   ├── main.dart               # Entry point (+ Supabase init)
│   │   ├── app/
│   │   │   ├── app.dart            # MaterialApp.router widget
│   │   │   ├── router.dart         # GoRouter configuration
│   │   │   └── theme.dart          # Customer theme (deep purple)
│   │   ├── features/               # Feature modules (catalogue, cart, orders)
│   │   └── core/                   # Core utilities, extensions
│   └── pubspec.yaml
│
├── mahalaxmi_admin/                # Admin Flutter app
│   ├── lib/
│   │   ├── main.dart               # Entry point (+ Supabase init)
│   │   ├── app/
│   │   │   ├── app.dart            # MaterialApp.router widget
│   │   │   ├── router.dart         # GoRouter configuration
│   │   │   └── theme.dart          # Admin theme (blue)
│   │   ├── features/               # Feature modules (dashboard, items, orders, settings)
│   │   └── core/                   # Core utilities, extensions
│   └── pubspec.yaml
│
├── migration_docs/                 # Flutter migration documentation
│
├── FLUTTER_WORKSPACE_README.md     # This file
└── .gitignore                      # Workspace-level gitignore
```

---

## Purpose of Each Project

| Project | Type | Platform | Purpose |
|---------|------|----------|---------|
| `legacy_flet_app/` | Python/Flet (frozen) | Android APK | Reference implementation — do NOT modify |
| `mahalaxmi_shared/` | Dart package | — | Shared models, repositories, services, widgets, theme |
| `mahalaxmi_customer/` | Flutter app | Android APK (primary), Web/PWA (iPhone fallback) | Customer catalogue, tag filter, cart, order placement |
| `mahalaxmi_admin/` | Flutter app | Android APK | Inventory, pricing, order management, settings |

---

## Dependency Strategy

```
mahalaxmi_customer ──┐
                     ├── mahalaxmi_shared ── supabase_flutter
mahalaxmi_admin   ───┘
```

- `mahalaxmi_shared` is consumed by both Flutter apps via `path:` dependency in `pubspec.yaml`
- Each app has its own dependency tree (`go_router`, `flutter_riverpod`, etc.)
- Feature-specific dependencies live only in the app that needs them (e.g., `image_picker` in admin, `share_plus` in customer)

---

## Supabase Safety Rule

**NEVER modify existing Supabase tables/schema.**

The Flutter migration must adapt to the current production schema:
- `rate_list` table with `tags` JSONB, `card_path` TEXT
- `tag_master` table with `categories` JSONB
- `order_items` table with `production_status` JSONB

If testing is required, create a **separate Supabase testing project** — never risk production data.

---

## Customer APK / Web Relationship

- **Customer Android APK** is the PRIMARY target
  - Push notifications (FCM)
  - Offline-first via Isar
  - App icon retention on home screen
  - Native share sheet (share_plus)
- **Customer Web/PWA** is the iPhone/browser FALLBACK
  - Same Flutter code, compiled to Web
  - No push notifications
  - No offline persistence (browser limitations)
  - Web-safe renderer (HTML or CanvasKit)

Both share the same `lib/` source and are built from the same Flutter project.

---

## Admin / Customer Separation

Two separate Flutter projects because:
- Different dependency trees (admin needs `image_picker`, `workmanager`, etc.)
- Independent release cycles
- Independent versioning
- Lower accidental coupling
- Cleaner long-term maintenance

---

## Migration Phases

| Phase | Scope | Status |
|-------|-------|--------|
| **0** | Workspace reorganization | ✅ DONE |
| **1** | `mahalaxmi_shared` — models + repositories (port of `db.py`) | 📋 TODO |
| **2** | `mahalaxmi_shared` — providers + services | 📋 TODO |
| **3** | Customer APK — catalogue + tag filter + cart + order | 📋 TODO |
| **4** | Customer Web/PWA — same code, web testing on iPhone | 📋 TODO |
| **5** | Admin APK — all admin flows | 📋 TODO |
| **6** | Push notifications (FCM) | 📋 TODO |
| **7** | Offline support (Isar) | 📋 TODO |

---

## Rules for Future Development

1. **Flet is frozen** — no new features in `legacy_flet_app/`. Only critical bug fixes if the Flutter migration is blocked by a production issue.
2. **Supabase schema is immutable** — the Flutter app must work with the current schema. Schema changes are a separate, independent process.
3. **Shared package first** — always implement shared logic (models, repositories) in `mahalaxmi_shared` before using it in either app.
4. **No feature work before foundation** — do not build UI screens until the shared package provides the required models/repositories/providers.
5. **Each app is independently buildable** — `mahalaxmi_customer` and `mahalaxmi_admin` must each be able to `flutter build` without the other present.
6. **No hardcoded secrets** — Supabase URL and anon key must use `--dart-define` or environment variables, never committed to source.
7. **Do NOT use `flutter create` inside existing projects** — the platform directories (android/, ios/, web/) must be generated once via `flutter create --project-name mahalaxmi_customer` when Flutter SDK is first set up.
8. **Keep the legacy reference alive** — `legacy_flet_app/` is the source of truth for business logic until the Flutter implementation is verified in production.

---

## First-Time Setup (When Flutter SDK Is Available)

```bash
# Install Flutter SDK (https://docs.flutter.dev/get-started/install)
# Then generate platform directories for each Flutter app:

cd workspace/mahalaxmi_customer
flutter create --project-name mahalaxmi_customer --platforms android,web .

cd ../mahalaxmi_admin
flutter create --project-name mahalaxmi_admin --platforms android .

cd ../mahalaxmi_shared
dart pub get

# Run either app from the workspace root:
cd ../mahalaxmi_customer
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

> **Note:** `flutter create` will overwrite the `lib/` directory if its contents differ.  
> Restore the custom `lib/` after running `flutter create`, or create the project in a temp directory and copy the generated `android/`, `ios/`, `web/` folders into the existing project.

---

**Version:** 1.0.0  
**Generated:** 2026-06-13  
**Workspace:** C:\Users\rajat\Labour-receipt
