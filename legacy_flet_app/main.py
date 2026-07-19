"""
Wholesale Bridal Chuda — Order Management (Flet edition)

Run on desktop/phone preview:
    flet run main.py

Build Android APK (after installing flet build prerequisites):
    flet build apk

Project layout:
    main.py    ← this file (Flet UI)
    auth.py    ← login + roles
    db.py      ← local SQLite operations
"""

from __future__ import annotations
from views import auth as v_auth, home as v_home, orders as v_orders, pricing as v_pricing, settings as v_settings, customer as v_customer, customers as v_customers, archive as v_archive, labour as v_labour

import os
import shutil
import urllib.parse
import datetime
import time
from pathlib import Path

import flet as ft

import db
from utils import *
import auth
import cache
import session_helper

# ---------- Constants ----------
COLOR_OPTIONS = ["Light Mehroon", "Dark Mehroon", "Red", "Rani", "Custom"]
BOX_OPTIONS = ["Jodi Box", "Mahal Box", "Flap Box", "Velvet Box"]
GRIND_OPTIONS = ["Gol / Internal-Grind", "Bina Gol / Non-Grind"]

# ---------- Category Schema Registry ----------
# These are now loaded dynamically from the database at runtime.
# The constants below serve as fallback defaults only.
CATEGORIES = ["Chuda", "Kaleera", "Raw_Material", "Metal_Bangles", "Seasonal"]
SUB_CATEGORIES = {"Raw_Material": ["Patti", "Nihar", "Box", "Bhawari"]}


def _load_categories_from_db():
    """Load active categories from DB. Returns (names_list, sub_categories_dict)."""
    try:
        cats = db.get_categories(active_only=True)
        names = [c["name"] for c in cats]
        subs = {}
        for c in cats:
            if c.get("sub_categories"):
                subs[c["name"]] = [s.strip() for s in c["sub_categories"].split(",") if s.strip()]
        return names if names else CATEGORIES, subs if subs else SUB_CATEGORIES
    except Exception:
        return CATEGORIES, SUB_CATEGORIES

CATEGORY_SCHEMAS = {
    "Chuda": {
        "fields": ["color", "grind_type", "box_type", "sizes"],
        "sizes": ["2.2", "2.4", "2.6", "2.8", "2.10"],
        "line_total": "sum_sizes_x_price",
        "validation": "at_least_one_size_gt_zero",
    },
    "Kaleera": {
        "fields": ["color", "quantity"],
        "qty_range": (1, 9999),
        "qty_type": "int",
        "line_total": "qty_x_price",
        "validation": "qty_gte_1_and_color_required",
    },
    "Raw_Material": {
        "fields": ["sub_category_label", "quantity", "unit"],
        "qty_range": (0.01, 99999.99),
        "qty_type": "float",
        "units": ["pieces", "kg", "meters"],
        "default_unit": "pieces",
        "line_total": "qty_x_price",
        "validation": "qty_gt_zero",
    },
    "Metal_Bangles": {
        "fields": ["color", "sizes"],
        "sizes": ["2.2", "2.4", "2.6", "2.8", "2.10"],
        "line_total": "sum_sizes_x_price",
        "validation": "at_least_one_size_gt_zero",
    },
    "Seasonal": {
        "fields": ["quantity", "notes"],
        "qty_range": (1, 99999),
        "qty_type": "int",
        "notes_max_length": 500,
        "line_total": "qty_x_price",
        "validation": "qty_gte_1",
    },
}


# ---------- Validation Engine ----------

def _safe_int(value) -> int:
    """Convert a value to int; non-numeric or negative values become 0."""
    try:
        n = int(value)
        return n if n >= 0 else 0
    except (TypeError, ValueError):
        return 0


def validate_cart_item(item: dict, category: str) -> str | None:
    """Validate a single cart item based on its category rules.

    Returns an error message string if invalid, or None if valid.
    Dispatches to category-specific validation based on CATEGORY_SCHEMAS.
    For user-created categories not in CATEGORY_SCHEMAS, uses the order_type
    from the DB to determine validation rules.
    """
    schema = CATEGORY_SCHEMAS.get(category)
    if schema is None:
        # Dynamic category — validate based on item's actual properties
        has_sizes = bool(item.get("_has_sizes", False))
        if has_sizes:
            size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
            total = sum(_safe_int(item.get(k, 0)) for k in size_keys)
            if total <= 0:
                return f"At least one size must have quantity > 0 for {category} item '{item.get('item_number', '')}'"
            return None
        else:
            try:
                qty = int(item.get("quantity", 0) or 0)
            except (TypeError, ValueError):
                qty = 0
            if qty < 1:
                return f"Quantity must be at least 1 for {category} item '{item.get('item_number', '')}'"
            return None

    # For ALL categories (including hardcoded ones): if the item has _has_sizes
    # flag set, override the category's default validation with size-based check.
    # This handles cases like a Raw_Material item that has sizes enabled.
    has_sizes = bool(item.get("_has_sizes", False))
    if has_sizes:
        size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
        total = sum(_safe_int(item.get(k, 0)) for k in size_keys)
        if total <= 0:
            return f"At least one size must have quantity > 0 for {category} item '{item.get('item_number', '')}'"
        return None

    # If item explicitly does NOT have sizes, validate quantity (whole number >= 1)
    if "_has_sizes" in item and not has_sizes:
        try:
            qty = int(item.get("quantity", 0) or 0)
        except (TypeError, ValueError):
            qty = 0
        if qty < 1:
            return f"Quantity must be at least 1 for {category} item '{item.get('item_number', '')}'"
        return None

    # Fallback: use the category's default validation rule
    rule = schema["validation"]

    if rule == "at_least_one_size_gt_zero":
        # Chuda / Metal_Bangles: at least one size quantity must be > 0
        size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
        total = sum(_safe_int(item.get(k, 0)) for k in size_keys)
        if total <= 0:
            return f"At least one size must have quantity > 0 for {category} item '{item.get('item_number', '')}'"
        return None

    if rule == "qty_gte_1_and_color_required":
        # Kaleera: quantity >= 1 AND color must be selected
        try:
            qty = int(item.get("quantity", 0) or 0)
        except (TypeError, ValueError):
            qty = 0
        if qty < 1:
            return f"Quantity must be at least 1 for Kaleera item '{item.get('item_number', '')}'"
        color = (item.get("color") or "").strip()
        if not color:
            return f"Color is required for Kaleera item '{item.get('item_number', '')}'"
        return None

    if rule == "qty_gt_zero":
        # Raw_Material: quantity in [0.01, 99999.99] with max 2 decimal places
        raw_qty = item.get("quantity")
        if raw_qty is None or raw_qty == "":
            return f"Quantity must be greater than 0 for Raw_Material item '{item.get('item_number', '')}'"
        try:
            qty = float(raw_qty)
        except (TypeError, ValueError):
            return f"Quantity must be greater than 0 for Raw_Material item '{item.get('item_number', '')}'"
        if qty < 0.01 or qty > 99999.99:
            return f"Quantity must be between 0.01 and 99999.99 for Raw_Material item '{item.get('item_number', '')}'"
        # Check max 2 decimal places
        qty_str = str(raw_qty)
        if "." in qty_str:
            decimals = qty_str.split(".")[-1]
            if len(decimals) > 2:
                return f"Quantity must have at most 2 decimal places for Raw_Material item '{item.get('item_number', '')}'"
        return None

    if rule == "qty_gte_1":
        # Seasonal: quantity >= 1
        try:
            qty = int(item.get("quantity", 0) or 0)
        except (TypeError, ValueError):
            qty = 0
        if qty < 1:
            return f"Quantity must be at least 1 for Seasonal item '{item.get('item_number', '')}'"
        return None

    return f"Unknown validation rule: {rule}"


def validate_order(cart: list, rate_lookup: dict) -> str | None:
    """Validate all items in the cart. Returns the first error found, or None.

    Args:
        cart: list of cart item dicts
        rate_lookup: dict mapping item_number -> item info dict (must include 'category')
    """
    for item in cart:
        item_number = item.get("item_number")
        if not item_number:
            continue
        item_info = rate_lookup.get(item_number)
        if item_info is None:
            return f"Item '{item_number}' not found in rate list"
        category = item.get("category") or item_info.get("category", "")
        if not category:
            return f"Category not found for item '{item_number}'"
        # Ensure item-level property flags are set for validation
        if "_has_sizes" not in item:
            item["_has_sizes"] = bool(item_info.get("has_sizes", 0))
        if "_has_color" not in item:
            item["_has_color"] = bool(item_info.get("has_color", 0))
        error = validate_cart_item(item, category)
        if error:
            return error
    return None


# ---------- Line Total Calculator ----------

def calculate_line_total(item: dict, category: str, unit_price: float) -> float:
    """Calculate the line total for a cart item based on its category formula.

    Pure function. Uses CATEGORY_SCHEMAS to determine the calculation method:
    - "sum_sizes_x_price" (Chuda, Metal_Bangles): sum of all size quantities × unit_price
    - "qty_x_price" (Kaleera, Raw_Material, Seasonal): quantity × unit_price

    Args:
        item: cart item dict with size quantities or quantity field
        category: the product category string
        unit_price: the item's selling price per unit

    Returns:
        Line total as a float rounded to 2 decimal places (Indian Rupee display).
    """
    schema = CATEGORY_SCHEMAS.get(category)
    if schema is None:
        # Dynamic category — determine formula from item's has_sizes flag
        has_sizes = bool(item.get("_has_sizes", False))
        if has_sizes:
            size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
            total_qty = sum(_safe_int(item.get(k, 0)) for k in size_keys)
            return round(total_qty * unit_price, 2)
        else:
            raw_qty = item.get("quantity", 0)
            try:
                qty = float(raw_qty) if raw_qty is not None else 0.0
            except (TypeError, ValueError):
                qty = 0.0
            return round(max(0, qty) * unit_price, 2)

    # For hardcoded categories: override formula based on item's _has_sizes flag
    if "_has_sizes" in item:
        has_sizes = bool(item.get("_has_sizes", False))
        if has_sizes:
            size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
            total_qty = sum(_safe_int(item.get(k, 0)) for k in size_keys)
            return round(total_qty * unit_price, 2)
        else:
            raw_qty = item.get("quantity", 0)
            try:
                qty = float(raw_qty) if raw_qty is not None else 0.0
            except (TypeError, ValueError):
                qty = 0.0
            return round(max(0, qty) * unit_price, 2)

    formula = schema.get("line_total", "")

    if formula == "sum_sizes_x_price":
        # Sum all size quantities using _safe_int for sanitization
        size_keys = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
        total_qty = sum(_safe_int(item.get(k, 0)) for k in size_keys)
        return round(total_qty * unit_price, 2)

    if formula == "qty_x_price":
        # Use the quantity field directly
        raw_qty = item.get("quantity", 0)
        try:
            qty = float(raw_qty) if raw_qty is not None else 0.0
        except (TypeError, ValueError):
            qty = 0.0
        if qty < 0:
            qty = 0.0
        return round(qty * unit_price, 2)

    return 0.00


# ---------- Order Summary Builder ----------

def build_order_summary(cart: list, rate_lookup: dict) -> dict:
    """Build an order summary grouped by category with subtotals.

    Pure function. Groups cart items by their category in alphabetical order,
    calculates item count and subtotal per group, and computes the grand total.
    Categories with zero items are excluded.

    Args:
        cart: list of cart item dicts (each must have 'item_number' and category-specific fields)
        rate_lookup: dict mapping item_number -> item info dict (may include 'category', 'selling_price')

    Returns:
        {
            'groups': [{'category': str, 'items': list, 'subtotal': float, 'count': int}],
            'grand_total': float
        }
    """
    # Collect items into category buckets
    category_buckets: dict[str, list] = {}

    for item in cart:
        item_number = item.get("item_number")
        if not item_number:
            continue

        item_info = rate_lookup.get(item_number, {})

        # Determine category: prefer rate_lookup, fall back to item dict
        category = item_info.get("category") or item.get("category", "Chuda")

        # Determine unit price from rate_lookup
        unit_price = float(item_info.get("selling_price", 0))

        # Calculate line total for this item
        line_total = calculate_line_total(item, category, unit_price)

        # Store item with its computed line_total for the summary
        enriched_item = {**item, "_line_total": line_total, "_category": category}

        if category not in category_buckets:
            category_buckets[category] = []
        category_buckets[category].append(enriched_item)

    # Build groups sorted alphabetically, excluding empty categories
    groups = []
    for category in sorted(category_buckets.keys()):
        items = category_buckets[category]
        subtotal = round(sum(i["_line_total"] for i in items), 2)
        groups.append({
            "category": category,
            "items": items,
            "subtotal": subtotal,
            "count": len(items),
        })

    grand_total = round(sum(g["subtotal"] for g in groups), 2)

    return {
        "groups": groups,
        "grand_total": grand_total,
    }


# ============================================================
# Main entry
# ============================================================
async def main(page: ft.Page):
    print(f"DEBUG APP START: Initial state exists: {hasattr(page, 'state')}")
    page.on_error = lambda e: print(f"FLUTTER FRONTEND ERROR: {e.data}")
    page.title = "Mahalaxmi Bangles"
    page.theme_mode = ft.ThemeMode.LIGHT
    page.theme = ft.Theme(color_scheme_seed=ft.Colors.INDIGO)
    page.padding = 0
    page.bgcolor = ft.Colors.GREY_50

    db.init_db()

    # Handle Android back button
    def on_view_pop_handler(e):
        go_back()
    page.on_view_pop = on_view_pop_handler

    # Intercept logic: We always maintain at least one View in page.views
    # so that the system back button triggers on_view_pop instead of closing the app.
    page.views.clear()
    page.views.append(ft.View(route="base_interceptor", controls=[ft.Container()]))

    # ---------- Category visual config (loaded from DB) ----------
    def _load_category_config():
        """Build CATEGORY_COLORS, CATEGORY_ICONS, CATEGORY_DESCRIPTIONS from DB."""
        cats = db.get_categories(active_only=False)
        colors = {}
        icons = {}
        descs = {}
        # Map stored color/icon strings to ft.Colors/ft.Icons
        _color_map = {
            "INDIGO_400": ft.Colors.INDIGO_400,
            "AMBER_600": ft.Colors.AMBER_600,
            "GREEN_600": ft.Colors.GREEN_600,
            "BLUE_600": ft.Colors.BLUE_600,
            "PINK_400": ft.Colors.PINK_400,
            "RED_400": ft.Colors.RED_400,
            "PURPLE_400": ft.Colors.PURPLE_400,
            "TEAL_400": ft.Colors.TEAL_400,
            "ORANGE_400": ft.Colors.ORANGE_400,
            "CYAN_400": ft.Colors.CYAN_400,
            "GREY_400": ft.Colors.GREY_400,
        }
        _icon_map = {
            "CIRCLE": ft.Icons.CIRCLE,
            "NOTIFICATIONS": ft.Icons.NOTIFICATIONS,
            "INVENTORY_2": ft.Icons.INVENTORY_2,
            "PANORAMA_FISH_EYE": ft.Icons.PANORAMA_FISH_EYE,
            "LOCAL_FLORIST": ft.Icons.LOCAL_FLORIST,
            "CATEGORY": ft.Icons.CATEGORY,
            "DIAMOND": ft.Icons.DIAMOND,
            "STAR": ft.Icons.STAR,
            "FAVORITE": ft.Icons.FAVORITE,
            "SHOPPING_BAG": ft.Icons.SHOPPING_BAG,
        }
        for c in cats:
            colors[c["name"]] = _color_map.get(c.get("color", ""), ft.Colors.GREY_400)
            icons[c["name"]] = _icon_map.get(c.get("icon", ""), ft.Icons.CATEGORY)
            descs[c["name"]] = c.get("description", "")
        return colors, icons, descs

    CATEGORY_COLORS, CATEGORY_ICONS, CATEGORY_DESCRIPTIONS = _load_category_config()

    # --------- Session state ---------
    state = {
        "role": None,        # "admin" | "labour"
        "username": None,
        "current_page": "login",  # login | home | order_type_picker | category_picker | order_form | order_detail | rate_list | manage_categories | karigar_slip | sync_page
        "cart": [],          # list of dicts (cart rows for Order Form)
        "cart_uid": 0,
        "selected_category": None,
        "order_mode": "single",  # "single" or "mixed"
        "detail_order_id": None,
        "slip_order_id": None,
        "nav_history": [],   # stack of previous pages for back navigation
        "customer_selected_category": None,
        "customer_selected_subcategory": None,
        "customer_subcategories": [],
        "customer_search_query": "",
        "customer_selected_item": None,
        "customer_cart": [],
        "customer_mobile": None,
        "customer_full_catalogue": None,
        "customer_category_cache": {},
        "customer_categories": None,
        "customer_id": None,
        "customer_shop_name": None,
    }

    # --- Persisted Session Check ---
    session_data = session_helper.load_session()
    if session_data:
        role = session_data.get("role")
        if role == "admin":
            state["role"] = "admin"
            state["username"] = session_data.get("username", "Admin")
            state["current_page"] = "home"
        elif role == "labour":
            state["role"] = "labour"
            state["username"] = session_data.get("username", "Labour")
            state["current_page"] = "home"
        elif role == "customer" or (role is None and session_data.get("name")):
            state["role"] = "customer"
            state["username"] = session_data.get("name") or session_data.get("username", "")
            state["customer_mobile"] = session_data.get("customer_mobile") or session_data.get("mobile", "")
            state["customer_id"] = session_data.get("customer_id")
            state["customer_shop_name"] = session_data.get("customer_shop_name")
            state["customer_full_catalogue"] = None
            state["customer_category_cache"] = {}
            state["customer_categories"] = None
            state["current_page"] = "customer_dashboard"

    # Back navigation map: where each page should go back to
    BACK_MAP = {
        "home": None,
        "order_type_picker": "home",
        "category_picker": "order_type_picker",
        "order_form": "home",
        "order_detail": "home",
        "rate_list": "home",
        "add_item": "home",
        "catalogue": "home",
        "costing": "home",
        "costing_detail": "costing",
        "price_list": "home",
        "settings": "home",
        "manage_categories": "settings",
        "manage_customers": "settings",
        "settings_margin": "settings",
        "settings_materials": "settings",
        "tag_master": "settings",
        "karigar_slip": "order_detail",
        "production_checklist": "home",
        "sync_page": "settings",
        "orders_archive": "settings",
        "customer_login": "login",
        "customer_dashboard": "customer_login",
        "customer_subcategories": "customer_dashboard",
        "customer_items": "customer_dashboard", # Dynamic in go_back
        "customer_search_results": "customer_dashboard",
        "cart": "customer_dashboard",
        "customer_my_orders": "customer_dashboard",
        "item_image_viewer": "item_detail",
    }

    # ============================================================
    # Helpers
    # ============================================================
    def _is_valid_image(path: str) -> bool:
        """Check if an image path is usable (URL or existing local file)."""
        if not path:
            return False
        if path.startswith("http://") or path.startswith("https://"):
            return True
        return os.path.exists(path)

    def snack(msg: str, color=ft.Colors.GREEN_600):
        # Clear previous snackbars to prevent overlay buildup
        page.overlay[:] = [c for c in page.overlay if not isinstance(c, ft.SnackBar)]
        sb = ft.SnackBar(
            content=ft.Text(msg, color=ft.Colors.WHITE),
            bgcolor=color,
            duration=2000,
            show_close_icon=True,
            open=True,
        )
        page.overlay.append(sb)
        page.update()



    def go(target: str):
        # Push current page to history before navigating
        current = state["current_page"]
        root_pages = ["login", "home", "customer_dashboard"]
        if target in root_pages:
            state["nav_history"] = []
        elif current != target and current != "login":
            state["nav_history"].append(current)
            # Keep history manageable
            if len(state["nav_history"]) > 20:
                state["nav_history"] = state["nav_history"][-10:]
        
        # --- Show immediate loading state ---
        page.controls.clear()
        page.appbar = None
        page.navigation_bar = None
        page.add(
            ft.Container(
                expand=True,
                alignment=ft.alignment.center,
                content=ft.Column(
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    alignment=ft.MainAxisAlignment.CENTER,
                    controls=[
                        ft.ProgressRing(width=40, height=40, stroke_width=3),
                        ft.Container(height=10),
                        ft.Text("Loading...", size=14, color=ft.Colors.GREY_600),
                    ]
                )
            )
        )
        page.update()

        state["current_page"] = target
        try:
            render()
        except Exception as ex:
            snack(f"Navigation error: {ex}", ft.Colors.RED_400)

    def show_exit_dialog():
        if any(isinstance(c, ft.AlertDialog) and getattr(c, 'open', False) for c in page.overlay):
            return
        if len(page.views) < 2:
            page.views.append(ft.View(route="/", controls=[ft.Container()]))

        def handle_cancel(e):
            dlg.open = False
            page.update()
            render()

        def handle_exit(e):
            dlg.open = False
            page.update()
            import os as _os
            if page.platform == ft.PagePlatform.ANDROID:
                _os._exit(0)
            else:
                try:
                    page.window.destroy()
                except Exception as ex:
                    print(f"ERROR: page.window.destroy() failed: {ex}")

        dlg = ft.AlertDialog(
            title=ft.Text("Exit App?"),
            content=ft.Text("Are you sure you want to exit?"),
            actions=[
                ft.TextButton("Cancel", on_click=handle_cancel),
                ft.TextButton("Exit", on_click=handle_exit),
            ],
        )
        page.overlay.append(dlg)
        dlg.open = True
        page.update()

    def go_back():
        try:
            current = state["current_page"]

            if state["nav_history"]:
                prev = state["nav_history"].pop()
                state["current_page"] = prev
                render()
                return

            root_pages = ["login", "home", "customer_dashboard"]
            if current in root_pages:
                show_exit_dialog()
                return

            if current in BACK_MAP and BACK_MAP[current]:
                state["current_page"] = BACK_MAP[current]
                render()
            else:
                show_exit_dialog()
        except Exception as e:
            import traceback
            tb = traceback.format_exc()
            print(f"ERROR in go_back: {e}\n{tb}")
            snack(f"Back Error: {e}", ft.Colors.RED_400)

    def logout(_=None):
        print("logout called")
        session_helper.clear_session()
        state["role"] = None
        state["username"] = None
        state["cart"] = []
        state["selected_category"] = None
        state["nav_history"] = []
        state["customer_id"] = None
        state["customer_shop_name"] = None
        state["customer_mobile"] = None
        state["customer_cart"] = []
        state["customer_full_catalogue"] = None
        state["customer_category_cache"] = {}
        state["customer_categories"] = None
        state["customer_selected_category"] = None
        state["customer_selected_subcategory"] = None
        state["customer_search_query"] = None
        state["customer_selected_item"] = None
        state["current_page"] = "login"
        render()

    # ============================================================
    # UI COMPONENTS
    # ============================================================

    def build_app_bar(title: str, show_back=False):
        leading = None
        if show_back:
            leading = ft.IconButton(
                ft.Icons.ARROW_BACK,
                icon_color=ft.Colors.WHITE,
                on_click=lambda _: go_back(),
            )

        async def handle_direct_logout(_=None):
            import asyncio
            await asyncio.sleep(0.2)
            logout()
    
        return ft.AppBar(
            leading=leading,
            title=ft.Text(title, weight="bold"),
            bgcolor=ft.Colors.INDIGO_700,
            color=ft.Colors.WHITE,
            actions=[
                ft.IconButton(
                    icon=ft.Icons.LOGOUT,
                    icon_color=ft.Colors.RED_600,
                    tooltip="Logout",
                    on_click=handle_direct_logout,
                )
            ],
        )
    
    # ============================================================
    # NAVIGATION BAR (2 tabs: Home + Rate List for admin)
    # ============================================================
    def build_nav_bar():
        is_admin = state["role"] == "admin"
        if not is_admin:
            # Labour only has Home — no nav bar needed (FAB is hidden too)
            return None
    
        destinations = [
            ft.NavigationBarDestination(icon=ft.Icons.HOME, label="Home"),
            ft.NavigationBarDestination(icon=ft.Icons.ADD_PHOTO_ALTERNATE, label="Add Item"),
            ft.NavigationBarDestination(icon=ft.Icons.GRID_VIEW, label="Catalogue"),
            ft.NavigationBarDestination(icon=ft.Icons.CALCULATE, label="Costing"),
            ft.NavigationBarDestination(icon=ft.Icons.SETTINGS, label="Settings"),
        ]
        page_keys = ["home", "add_item", "catalogue", "costing", "settings"]
    
        try:
            selected = page_keys.index(state["current_page"])
        except ValueError:
            selected = 0
    
        def on_nav_change(e):
            go(page_keys[e.control.selected_index])
    
        return ft.NavigationBar(
            destinations=destinations,
            selected_index=selected,
            on_change=on_nav_change,
            bgcolor=ft.Colors.WHITE,
        )
    
    # ============================================================
    # DYNAMIC CATEGORY FIELD RENDERER — item-level properties
    # ============================================================
    def build_category_fields(category, item_data, callbacks):
        """Returns list of Flet controls based on item's has_sizes/has_color flags.
    
        The item_data dict should have '_has_sizes' and '_has_color' keys
        (set by the cart row builder from the rate_lookup).
        Falls back to category-based logic if those keys are missing.
        """
        on_change = callbacks.get("on_change", lambda: None)
        pg = callbacks.get("page", page)
        controls = []
    
        has_sizes = item_data.get("_has_sizes", False)
        has_color = item_data.get("_has_color", False)
    
        # --- Helper: +/- Stepper for whole numbers ---
        def _build_qty_stepper(label, key, min_val=0, max_val=99999):
            """Build a row with [-] [value] [+] for integer quantity."""
            # Ensure initial value is an int (not None)
            if item_data.get(key) is None:
                item_data[key] = 0
            initial = int(item_data.get(key, 0) or 0)
            item_data[key] = initial
    
            qty_text = ft.Text(
                str(initial),
                size=20, weight="bold",
                text_align=ft.TextAlign.CENTER,
                width=50,
            )
    
            def _update_qty(delta):
                current = int(item_data.get(key, 0) or 0)
                new_val = max(min_val, min(max_val, current + delta))
                item_data[key] = new_val
                qty_text.value = str(new_val)
                # Directly trigger callbacks and update
                try:
                    on_change()
                except Exception:
                    pass
                pg.update()
    
            def _dec(_):
                _update_qty(-1)
    
            def _inc(_):
                _update_qty(1)
    
            return ft.Container(
                padding=6,
                border=ft.border.all(1, ft.Colors.GREY_300),
                border_radius=8,
                content=ft.Row(
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=0,
                    controls=[
                        ft.Text(label, size=12, color=ft.Colors.GREY_700),
                        ft.Container(width=8),
                        ft.IconButton(
                            ft.Icons.REMOVE_CIRCLE_OUTLINE,
                            icon_color=ft.Colors.RED_400,
                            icon_size=28,
                            on_click=_dec,
                        ),
                        qty_text,
                        ft.IconButton(
                            ft.Icons.ADD_CIRCLE_OUTLINE,
                            icon_color=ft.Colors.GREEN_600,
                            icon_size=28,
                            on_click=_inc,
                        ),
                    ],
                ),
            )
    
        # --- Color dropdown with Custom option ---
        def _build_color_field():
            custom_tf = ft.TextField(
                label="Custom color",
                value=item_data.get("custom_color", ""),
                visible=(item_data.get("color") == "Custom"),
                expand=True,
            )
            color_dd = ft.Dropdown(
                label="Color",
                options=[ft.dropdown.Option(c) for c in COLOR_OPTIONS],
                value=item_data.get("color") or None,
                expand=True,
            )
    
            def _on_color_select(_e):
                item_data["color"] = color_dd.value or ""
                custom_tf.visible = (color_dd.value == "Custom")
                if color_dd.value != "Custom":
                    item_data.pop("custom_color", None)
                on_change()
                pg.update()
    
            def _on_custom_change(_e):
                item_data["custom_color"] = custom_tf.value or ""
                on_change()
                pg.update()
    
            color_dd.on_change = _on_color_select
            custom_tf.on_change = _on_custom_change
            return [color_dd, custom_tf]
    
        # --- Build controls based on item properties ---
    
        # Color (if item has color)
        if has_color:
            controls.extend(_build_color_field())
    
        # Sizes (if item has sizes) — 5 stepper rows
        if has_sizes:
            controls.append(ft.Text("Size-Wise Quantities",
                                    size=13, weight=ft.FontWeight.W_500,
                                    color=ft.Colors.GREY_800))
            size_steppers = []
            for size_label, qkey in zip(
                ["2.2", "2.4", "2.6", "2.8", "2.10"],
                ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"],
            ):
                size_steppers.append(_build_qty_stepper(size_label, qkey))
            controls.append(ft.Row(size_steppers, wrap=True, spacing=6, run_spacing=6))
        else:
            # Single quantity stepper (always shown if no sizes)
            controls.append(_build_qty_stepper("Qty", "quantity"))

        return controls

# ============================================================
# HOME VIEW — Order list + FAB
# ============================================================
    page.state = state
    page.go = lambda t: go(t)
    page.go_back = lambda: go_back()
    page.snack = lambda m, c=ft.Colors.GREEN_600: snack(m, c)
    page.logout = lambda e=None: logout()
    page.build_app_bar = build_app_bar
    page.build_nav_bar = build_nav_bar
    page._load_category_config = _load_category_config
    page.CATEGORY_COLORS = CATEGORY_COLORS
    page.CATEGORY_ICONS = CATEGORY_ICONS
    page.CATEGORY_DESCRIPTIONS = CATEGORY_DESCRIPTIONS
    page.build_category_fields = build_category_fields

    def render():
        if any(isinstance(c, ft.AlertDialog) and getattr(c, 'open', False) for c in page.overlay):
            return
        state = page.state
        # Clear previous UI on the current view
        page.controls.clear()
        page.appbar = None
        page.navigation_bar = None
        cur = state.get("current_page")
        role = state.get("role")

        # Customer catalogue refresh handler
        def _customer_refresh(_):
            try:
                # Clear per-category cache so next tap fetches fresh from DB
                state["customer_category_cache"] = {}
                fresh_cats = db.get_categories(active_only=True)
                state["customer_categories"] = fresh_cats
            except Exception as ex:
                snack(f"❌ Refresh failed: {ex}", ft.Colors.RED_400)
                return
            snack("✅ Catalogue refreshed")
            render()

        _refresh_icon = ft.IconButton(ft.Icons.REFRESH, icon_color=ft.Colors.WHITE, tooltip="Refresh Catalogue", on_click=_customer_refresh)
        _my_orders_icon = ft.IconButton(ft.Icons.RECEIPT_LONG, icon_color=ft.Colors.WHITE, tooltip="My Orders", on_click=lambda _: go("customer_my_orders"))

        body = None
        appbar = None
        navbar = None

        # --- Routing ---
        if cur == "login":
            body = v_auth.view_login(page)
        elif cur == "home":
            appbar = build_app_bar("Home", show_back=False)
            navbar = build_nav_bar()
            body = v_home.view_home(page)
        elif cur == "order_type_picker":
            appbar = build_app_bar("New Order", show_back=True)
            body = v_orders.view_order_type_picker(page)
        elif cur == "category_picker":
            appbar = build_app_bar("Select Category", show_back=True)
            body = v_orders.view_category_picker(page)
        elif cur == "order_form":
            appbar = build_app_bar("Order Form", show_back=True)
            body = v_orders.view_order_form(page)
        elif cur == "order_detail":
            appbar = build_app_bar("Order Detail", show_back=True)
            body = v_orders.view_order_detail(page)
        elif cur == "rate_list":
            appbar = build_app_bar("Catalogue", show_back=True)
            body = v_pricing.view_catalogue(page)
        elif cur == "add_item":
            appbar = build_app_bar("Add Item", show_back=True)
            body = v_pricing.view_add_item(page)
        elif cur == "catalogue":
            appbar = build_app_bar("Catalogue", show_back=True)
            body = v_pricing.view_catalogue(page)
        elif cur == "costing":
            appbar = build_app_bar("Costing", show_back=True)
            body = v_pricing.view_costing(page)
        elif cur == "costing_detail":
            appbar = build_app_bar("Costing Detail", show_back=True)
            body = v_pricing.view_costing_detail(page)
        elif cur == "settings":
            appbar = build_app_bar("Settings", show_back=True)
            body = v_settings.view_settings(page)
        elif cur == "manage_categories":
            appbar = build_app_bar("Manage Categories", show_back=True)
            body = v_settings.view_manage_categories(page)
        elif cur == "manage_customers":
            appbar = build_app_bar("Manage Customers", show_back=True)
            body = v_customers.view_manage_customers(page)
        elif cur == "settings_margin":
            appbar = build_app_bar("Default Margin %", show_back=True)
            body = v_settings.view_settings_margin(page)
        elif cur == "settings_materials":
            appbar = build_app_bar("Material Master", show_back=True)
            body = v_settings.view_settings_materials(page)
        elif cur == "tag_master":
            appbar = build_app_bar("Tag Master", show_back=True)
            body = v_settings.view_tag_master(page)
        elif cur == "karigar_slip":
            appbar = build_app_bar("Karigar Slip", show_back=True)
            body = v_orders.view_karigar_slip(page)
        elif cur == "production_checklist":
            appbar = build_app_bar("Production Checklist", show_back=True)
            body = v_labour.view_production_checklist(page)
        elif cur == "sync_page":
            appbar = build_app_bar("Sync", show_back=True)
            body = v_settings.view_sync_page(page)
        # Customer Pages
        elif cur == "customer_login":
            appbar = build_app_bar("Customer Login", show_back=True)
            body = v_customer.view_customer_pin_login(page)
        elif cur == "customer_dashboard":
            cart_count = len(state.get("customer_cart", []))
            appbar = build_app_bar(state.get("username", "Catalogue"), show_back=False)
            cart_stack = ft.Stack([
                ft.IconButton(ft.Icons.SHOPPING_CART, icon_color=ft.Colors.WHITE, on_click=lambda _: go("cart")),
                ft.Container(
                    content=ft.Text(str(cart_count), size=10, color=ft.Colors.WHITE, weight="bold"),
                    bgcolor=ft.Colors.RED_500, border_radius=10, padding=3,
                    right=5, top=5, visible=cart_count > 0
                )
            ])
            appbar.actions = [_my_orders_icon, _refresh_icon, cart_stack] + appbar.actions[:1]
            body = v_customer.view_customer_dashboard(page)
        elif cur == "customer_subcategories":
            cart_count = len(state.get("customer_cart", []))
            appbar = build_app_bar(state.get("customer_selected_category", "Subcategories"), show_back=True)
            cart_stack = ft.Stack([
                ft.IconButton(ft.Icons.SHOPPING_CART, icon_color=ft.Colors.WHITE, on_click=lambda _: go("cart")),
                ft.Container(
                    content=ft.Text(str(cart_count), size=10, color=ft.Colors.WHITE, weight="bold"),
                    bgcolor=ft.Colors.RED_500, border_radius=10, padding=3,
                    right=5, top=5, visible=cart_count > 0
                )
            ])
            appbar.actions = [_refresh_icon, cart_stack]
            body = v_customer.view_customer_subcategories(page)
        elif cur == "customer_items":
            cart_count = len(state.get("customer_cart", []))
            title = state.get("customer_selected_category", "Items")
            appbar = build_app_bar(title, show_back=True)
            cart_stack = ft.Stack([
                ft.IconButton(ft.Icons.SHOPPING_CART, icon_color=ft.Colors.WHITE, on_click=lambda _: go("cart")),
                ft.Container(
                    content=ft.Text(str(cart_count), size=10, color=ft.Colors.WHITE, weight="bold"),
                    bgcolor=ft.Colors.RED_500, border_radius=10, padding=3,
                    right=5, top=5, visible=cart_count > 0
                )
            ])
            appbar.actions = [_refresh_icon, cart_stack]
            body = v_customer.view_customer_items(page)
        elif cur == "customer_search_results":
            cart_count = len(state.get("customer_cart", []))
            appbar = build_app_bar("Search Results", show_back=True)
            cart_stack = ft.Stack([
                ft.IconButton(ft.Icons.SHOPPING_CART, icon_color=ft.Colors.WHITE, on_click=lambda _: go("cart")),
                ft.Container(
                    content=ft.Text(str(cart_count), size=10, color=ft.Colors.WHITE, weight="bold"),
                    bgcolor=ft.Colors.RED_500, border_radius=10, padding=3,
                    right=5, top=5, visible=cart_count > 0
                )
            ])
            appbar.actions = [_refresh_icon, cart_stack]
            body = v_customer.view_customer_search(page)
        elif cur == "item_detail":
            appbar = build_app_bar("Item Detail", show_back=True)
            body = v_customer.view_item_detail(page)
        elif cur == "item_image_viewer":
            appbar = None
            body = v_customer.view_item_image_viewer(page)
        elif cur == "cart":
            appbar = build_app_bar("Your Cart", show_back=True)
            body = v_customer.view_cart(page)
        elif cur == "orders_archive":
            appbar = build_app_bar("Archive Orders", show_back=True)
            body = v_archive.view_orders_archive(page)
        elif cur == "customer_my_orders":
            appbar = build_app_bar("My Orders", show_back=True)
            body = v_customer.view_customer_my_orders(page)
        else:
            body = ft.Text("Page not found")

        # Keep interceptor at index 0 so page.views always has >= 2 views
        # This prevents Android from minimizing/closing the app on back press.
        page.views.clear()
        page.views.append(ft.View(route="base_interceptor", controls=[ft.Container()]))
        view = ft.View(
            route="/",
            controls=[body] if body else [],
            appbar=appbar,
            navigation_bar=navbar,
            padding=0,
            bgcolor=ft.Colors.GREY_50
        )
        page.views.append(view)
        page.update()

    # expose render as app_render for views
    page.app_render = lambda: render()
    # Initial render
    render()

if __name__ == "__main__":
    ft.app(target=main)



