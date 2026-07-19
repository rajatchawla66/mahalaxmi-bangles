# 01 — Project Overview

## Business

- **Mahalaxmi Bangles** — wholesale bridal chuda and bangles manufacturer
- **Location:** Sri Ganganagar, Rajasthan
- **GST:** 08AHPPC2086C1ZI
- B2B/customer catalogue ordering system with admin and labour workflows

## App Ecosystem

| App | Flavour | Purpose | Status |
|-----|---------|---------|--------|
| `mahalaxmi_customer` | Customer-facing | Browse catalogue, place orders, track history | Production |
| `mahalaxmi_admin` | Admin | Dashboard, orders, catalogue, customers, settings | Production |
| `mahalaxmi_labour` | Labour | Cutmail/stock-check creation (beta) | Beta |
| `mahalaxmi_shared` | Shared package | Models, repositories, providers, services, constants | All apps depend on it |

## Folder Structure

```
/ (root)
├── mahalaxmi_customer/     — Customer Flutter app
├── mahalaxmi_admin/        — Admin Flutter app
├── mahalaxmi_labour/       — Labour Flutter app
├── mahalaxmi_shared/       — Shared Dart package
├── migration_docs/          — SQL migrations, audit docs, context files
├── assets/                  — Shared assets (watermark.png, app_icon.png)
├── legacy_flet_app/         — Deleted 2026-07-19 (Flutter migration complete)
└── CONTEXT.md               — This file (essential context)
```

## Backend

- **Supabase** (PostgreSQL + Storage + Auth + Realtime)
- **Supabase Storage:** `product-images` bucket — `items/<slug>.jpg`, `category_covers/<slug>.jpg`
- **Auth:** PIN-based customer login (custom, not Supabase Auth). Admin uses Supabase Auth (email).
- **RLS:** Currently disabled on all tables

## Architecture Rules

1. **Repository pattern** — all Supabase queries go through repositories in `mahalaxmi_shared`. UI never calls Supabase directly.
2. **Riverpod** for state management — `FutureProvider`/`StateNotifierProvider` patterns used across all apps.
3. **GoRouter** for navigation — named routes with redirect guards for auth.
4. **`mahalaxmi_shared`** is a Dart package (not a Flutter package) — no Flutter dependency in shared code.
5. **Session persistence** via `SharedPreferencesSessionStorage` — customer/admin sessions survive app restarts.
6. **Sizes as strings** — `'2.10'` stored/passed as text, never parsed as numeric to avoid `2.10 → 2.1` truncation.
7. **Category names** — raw names (`Chuda`, `Metal_Bangles`) used internally; display-friendly formatting only in UI.

## Key Dependencies

- `flutter_riverpod` / `riverpod_annotation`
- `go_router`
- `supabase_flutter` / `postgrest`
- `shared_preferences` (session + cart persistence)
- `cached_network_image` (customer app image cache)
- `crop_your_image` (admin crop UI)
- `pdf` / `printing` (order PDF generation)
- `share_plus` (WhatsApp photo share, PDF share)
- `image` (bitmap font rendering, image compression)
- `url_launcher` (contact links on login page)
- `flutter_native_splash` / `flutter_launcher_icons` (branding)
