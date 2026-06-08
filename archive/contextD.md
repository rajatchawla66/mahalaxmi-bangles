# Project Status Summary — Mahalaxmi Bangles

**Generated:** June 8, 2026 (Updated)

---

## 1. Current Architecture

### Tech Stack
| Layer | Technology | Version |
|-------|-----------|---------|
| UI Framework | Flet (Python-on-Flutter) | **0.28.3** |
| Python | CPython (in venv) | 3.11 |
| HTTP Client | httpx | 0.28.x |
| Database (Cloud) | Supabase (PostgreSQL REST API) | — |
| Offline Cache | Local JSON files | — |
| PDF Generation | fpdf2 + Pillow | — |
| APK Build | GitHub Actions CI | — |

### Flet 0.28.3 Migration Status — ✅ Complete
The app has been fully migrated from Flet 0.85.2 to **0.28.3**. All view files updated with 0.28.3-compatible APIs.

### Navigation System (Current)
- **Single-view flat model:** `page.controls` replacement approach
- **Android back interception:** Dummy `ft.View` at `page.views[0]` (interceptor), content at `page.views[1]`
- **State:** All global state in `page.state` dict; cleared on `logout()`
- **Session persistence:** `session_helper.py` — saves/loads/clears `customer_session.json` for all roles
- **Exit dialog:** `show_exit_dialog()` in `main.py:590` — uses `page.overlay.append(dlg)` (Flet 0.28.3-compatible)
- **Back behavior:** `on_view_pop_handler` calls `go_back()` without popping views; `go_back()` shows exit dialog on root pages

---

## 2. Recent Fixes (This Session)

| Bug | Symptom | Fix | Files Changed |
|-----|---------|-----|---------------|
| **APK Build Blocker** | `flet build apk` fails: "Package(s) objective_c require native assets" | Moved builds to GitHub Actions CI with Flutter 3.24.0 | `.github/workflows/build_apk.yml`, `.gitignore` |
| **Android Back → White Screen** | Back press minimizes app; reopen shows white screen | `render()` recreates interceptor at `page.views[0]` so `len >= 2` | `main.py` (1 line added) |
| **RangeError (length 12)** | Console flooded when opening Costing view | Removed `ResponsiveRow` and `expand=True` from Row children | `views/pricing.py`, `views/settings.py`, `views/orders.py` |
| **Logout from PopupMenu** | Logout silently fails on Home tab | Switched to `PopupMenuButton.on_select` with `data="logout"` | `main.py` |
| **Session restore for all roles** | Only customer session persisted | New `session_helper.py`; all roles saved on login, restored on app start | `session_helper.py`, `main.py`, `views/auth.py` |
| **Back → exit dialog** | No exit confirmation on root pages | `show_exit_dialog()` in `go_back()` for login/home/customer_dashboard | `main.py` |
| **Exit dialog not rendering** | Dialog never appeared on Android | Changed `page.dialog = dlg` → `page.overlay.append(dlg)` (wrong Flet 0.28.3 API) | `main.py` |
| **White screen after exit dialog** | Double-back minimized app | Removed `page.views.pop()` from `on_view_pop_handler`; added defensive view guard + `on_dismiss` handler | `main.py` |
| **APK package conflict** | "Package conflicts with existing package" on every install | Cached `~/.android/debug.keystore` via `actions/cache@v4` so all CI builds use the same signing key | `.github/workflows/build_apk.yml` |

---

## 3. Pending Tasks

### Build / APK
| Item | Status | Notes |
|------|--------|-------|
| Local Windows APK build | ❌ Blocked | Flutter 3.29.2 + `objective_c` native-assets incompatibility. No known workaround without modifying Flet CLI. |
| GitHub Actions CI build | ✅ Working | Pins Flutter 3.24.0. First APK built successfully on June 7, 2026. |
| Consistent APK signing | ✅ Fixed | Debug keystore cached via `actions/cache@v4`. First v1.0.8 build will still need uninstall; subsequent builds will update in-place. |
| `--template-ref 0.27.0` experiment | ❌ Failed | Packaging succeeds but Gradle fails: `webview_flutter_android` requires Dart 3.9, template caps at 3.7. |

### Features
| Item | Status |
|------|--------|
| Logout Button (Popup Menu fix) | ✅ Fixed (pending real Android device verification) |
| Navigation & Hardware Back Button | ✅ Fixed |
| Exit confirmation on root back | ✅ Fixed (overlay dialog, properly dismissible) |
| Session restore for all roles | ✅ Fixed (admin, labour, customer) |
| WhatsApp Sharing (Flet 0.28.3) | ❌ Blocked (`ft.Share` API changed) |

---

## 4. Session & Navigation Architecture

### Session File
- **Path:** `customer_session.json` in `FLET_APP_STORAGE_DATA` or `"."`
- **Format:** `{"role": "admin"|"labour"|"customer", "username": "...", "customer_mobile": "..."}`
- **Backward compatible:** Old customer-only sessions (no `role` field, just `name`/`mobile`) restored as customer
- **Helper module:** `session_helper.py` — `save_session(state)`, `load_session()`, `clear_session()`

### Navigation Flow
```
Login (Select Dashboard)
  ├── Admin → home
  ├── Labour → home
  └── Customer → customer_name_entry → customer_dashboard

Back Button:
  ├── Deep screens → nav_history pop → previous page
  ├── Root pages (home, customer_dashboard, login) → exit confirmation dialog
  │     ├── Cancel → render() restores content
  │     └── Exit → page.window.destroy()
  └── Unknown page → fallback to BACK_MAP or exit dialog
```

### page.views Invariant
- Always `len(page.views) >= 2` = `[interceptor, content_view]`
- `on_view_pop_handler` no longer pops views — just calls `go_back()`
- `show_exit_dialog()` defensively appends a placeholder if `len < 2` (handles Flet auto-pop on some Android versions)
- `render()` clears + re-adds both views atomically

### Exit Dialog
- **API:** `page.overlay.append(dlg)` with `on_dismiss` handler
- **Stacking guard:** Checks if any `ft.AlertDialog` is already open in overlay
- **Cancel:** Closes dialog → `on_dismiss` fires → `render()` restores content views
- **Exit:** Sets `_exiting` flag, closes dialog, calls `page.window.destroy()`
- **Back-dismiss:** Android back on dialog calls `on_dismiss` → `render()` (same as Cancel)

---

## 5. Known Variables & Environment Hacks

### Build Environment Hacks
```powershell
# Force UTF-8 encoding (required for PowerShell):
$env:PYTHONIOENCODING='utf-8'

# Disable Flet CLI rich output (avoids rendering artifacts):
$env:FLET_CLI_NO_RICH_OUTPUT='true'

# Set console to UTF-8:
chcp 65001

# Flutter native-assets experiment (DOES NOT WORK for packaging step):
$env:DART_VM_OPTIONS='--enable-experiment=native-assets'
```

### Why `DART_VM_OPTIONS` doesn't work
The error occurs during `dart run serious_python:main package` in the **"Packaging Python app"** step. `DART_VM_OPTIONS` applies to the Dart VM but `--enable-experiment=native-assets` must be a CLI argument to `dart run`, not an env var. Flet CLI hardcodes the `dart run` command without the experiment flag. This flag only affects the later `flutter build` step (via `--flutter-build-args`), which never runs because packaging fails first.

### Python Environments
| Env | Python | Flet | Location | Status |
|-----|--------|------|----------|--------|
| venv (primary) | 3.11 | 0.28.3 | `venv\` | ✅ Development |
| System Python 3.14 | 3.14.5 | 0.28.3 | `C:\Users\rajat\AppData\Local\Python\bin\python.exe` | ⚠️ Was 0.85.2, upgraded to 0.28.3 |
| System Python 3.11 | 3.11.9 | 0.28.3 | `C:\Program Files\Python311\` | ✅ Used for CI-compatible builds |

### Flutter SDK Cache
- **Auto-downloaded by Flet:** `C:\Users\rajat\flutter\3.29.2\` (always 3.29.2, hardcoded in Flet 0.28.3 CLI)
- **CI uses:** Flutter 3.24.0 (via `subosito/flutter-action@v2`)

### Git / CI
| Item | Value |
|------|-------|
| Remote | `https://github.com/rajatchawla66/mahalaxmi-bangles.git` |
| Branch | `main` |
| CI endpoint | https://github.com/rajatchawla66/mahalaxmi-bangles/actions |
| Token | Classic PAT with `repo` + `workflow` scopes (provided by user) |
| Latest version | v1.0.8 (build 4) |
| Signing key | Cached `~/.android/debug.keystore` via `actions/cache@v4` |

---

## 6. Key Files

| File | Purpose | Notes |
|------|---------|-------|
| `main.py` | Entry point, navigation, state, exit dialog, app bar | Most frequently modified. Contains `go()`, `go_back()`, `render()`, `show_exit_dialog()`, `logout()` |
| `session_helper.py` | Session save/load/clear | Small module, low risk |
| `views/auth.py` | Role selection login screen | Pick_role saves session for admin/labour |
| `views/customer.py` | Customer catalogue, cart, item detail | NOT modified in recent session |
| `.github/workflows/build_apk.yml` | CI build | Pins Flutter 3.24.0. Caches debug keystore. |
| `pyproject.toml` | Flet build config | NOT modified in recent session |
| `contextD.md` | This file | Session status tracker |

---

## 7. Risk Assessment

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| White screen on real Android device (back button) | High | Low | No pop in `on_view_pop_handler`; dialog handler restores views via `render()` |
| `page.window.destroy()` fails on Android | Medium | Medium | Wrapped in try/except; app stays open if close fails |
| Exit dialog not rendering (Flet 0.28.3 overlay API issues) | Medium | Low | Uses same `page.overlay.append()` pattern as 2 other dialogs in codebase |
| First v1.0.8 build needs uninstall/reinstall | Low | Certain | Keystore cache populated after first build; subsequent builds update in-place |
| Session file path `"."` on Android when `FLET_APP_STORAGE_DATA` unset | Medium | Medium | `os.makedirs()` called; no crash, but session won't survive restart |
| GitHub Actions cache eviction (7-day inactivity) | Low | Low | Rare for active project; if happens, one-time uninstall/reinstall needed |

---

## 8. Quick Reference

```bash
# Run locally (desktop):
cd C:\Users\rajat\Labour-receipt
venv\Scripts\activate
flet run main.py

# Trigger CI build:
git push  # OR go to Actions tab → "Run workflow"

# Download APK:
# Actions → latest run → Artifacts → mahalaxmi-bangles-v1.0.8.zip
```
