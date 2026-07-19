# PROJECT HANDOVER — Mahalaxmi Bangles Order Manager

## 1. Project Overview

**App Name:** Mahalaxmi Bangles Order Manager  
**Purpose:** Wholesale bridal bangle (chuda) order management for a small business  
**Target Users:**
- **Admin** — Business owner: creates orders, manages rate list, prices items, shares catalogs
- **Labour** — Workshop worker: views orders and karigar (artisan) slips, no access to prices
- **Customer** — Shop owner: browses categorized catalogue, adds items to cart, places orders

**Tech Stack:**
- **Frontend/UI:** Python + Flet 0.85 (Python-on-Flutter framework)
- **Target Platform:** Android APK (also runs on desktop for development)
- **Database:** Supabase (PostgreSQL) via REST API
- **HTTP Client:** httpx (lightweight, works on Android)
- **Image Storage:** Supabase Storage (public bucket: `product-images`)
- **Price Card Generation:** Cloudinary (text overlay transformations) for Android
- **Offline Cache:** Local JSON files + downloaded images

---

## 2. File Structure & Responsibilities

### Active Source Files

| File | Lines | Purpose |
|------|-------|---------|
| `main.py` | ~1000 | **App entry point & UI Core** — async navigation, global state, validation, order calculation, Android back-button interception |
| `views/` | (dir) | **Extracted UI Modules** — `home.py`, `orders.py`, `pricing.py`, `settings.py`, `auth.py`, `customer.py` |
| `db.py` | ~800 | **Supabase REST API layer** — all CRUD operations via httpx; includes category cover image support |
| `cache.py` | ~250 | **Offline sync** — downloads catalog + categories + images to local JSON/files |
| `requirements.txt` | 2 | Dependencies: `flet>=0.85.0`, `httpx>=0.27.0` |

---

## 3. How to Run

### Desktop Development
```bash
pip install flet>=0.85.0 httpx>=0.27.0
flet run main.py
```

### Build Android APK
```bash
flet build apk
```

### Entry Point
```python
if __name__ == "__main__":
    ft.run(main)
```

---

## 4. Application Architecture

### Asynchronous Core
The application has been migrated to a fully asynchronous architecture (`async main`, `async render`, `async go`). This is required for compatibility with `page.shared_preferences` and modern Flet event handling.

### State Management
All state is held in a single `state` dictionary inside `main()`:
```python
state = {
    "role": None,           # "admin" | "labour" | "customer"
    "username": None,
    "current_page": "login",
    "nav_history": [],      # stack for back navigation
    "customer_full_catalogue": None, # in-memory cache of all items
    "customer_categories": None,     # in-memory cache of categories
}
```

### Navigation System
- **`go(target)`** — pushes current page to `nav_history`, sets new page, calls `render()`.
- **`go_back()`** — pops from `nav_history`, falls back to `BACK_MAP`, or triggers `show_exit_dialog()` if at a root screen.
- **Android back button interception** — `page.views` is managed to always have a depth of at least 2 (using a `base_interceptor` view). This forces Android to trigger `on_view_pop` instead of closing the app.

---

## 11. Critical Flet 0.85.2 Constraints

| Constraint | Correct Usage |
|-----------|---------------|
| App entry | `async def main(page: ft.Page): ... ft.run(main)` |
| Local Storage | `await page.shared_preferences.set/get/remove()` |
| UI Refresh | `page.update()` (Synchronous) |
| Android Back | Must have `len(page.views) > 1` to trigger `on_view_pop` |
| Column Padding | Use `ft.Padding(l, t, r, b)` NOT `ft.padding.only` |
| Stack Layers | Children of `ft.Stack` use `left, top, right, bottom` directly NOT `ft.Positioned` |
| Dropdown | Use `on_select` NOT `on_change` |

---

## 18. Handover Notes for Next AI Model

**Current Active Bug Focus: Android Back-Button & Root Exiting**

### 1. The Blank/White Screen Bug
- **Symptom:** Pressing the Android back button on a root screen (Admin Home or Customer Dashboard) results in a blank white screen.
- **Technical Context:** We use a flat navigation model (adding controls to one View). To intercept the back button, we keep a dummy `interceptor` view at `page.views[0]`. When system back is pressed, Flet pops the visible view at `page.views[1]`, leaving only the interceptor.
- **Current Problem:** The code calls `await render()` inside `show_exit_dialog()` to restore the UI, but it doesn't consistently prevent the white screen on all devices.

### 2. Customer Session Persistence
- **Implementation:** Customer details (role, username, mobile) are saved to `page.shared_preferences`.
- **Current Issue:** Tapping "Enter Shop" from the name entry screen should clear `nav_history` so the user cannot navigate back to the entry form. The exact sequence of `page.go` vs `state["nav_history"] = []` is critical.

### 3. Navigation Unification
- In-app back buttons and the hardware back button must both use `go_back()`.
- Navigation calls must be wrapped in `page.run_task(...)` when triggered from synchronous contexts (lambdas).

**Goal:** Ensure the app never shows a blank screen, never returns to "Name Entry" after the session starts, and correctly shows the "Confirm Exit" popup at root screens.
