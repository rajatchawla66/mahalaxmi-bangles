import flet as ft
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
from utils import *

def view_home(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    # Guard: prevent customers from accessing admin/labour home dashboard
    if state.get("role") == "customer":
        # Redirect customers to their dashboard
        state["current_page"] = "customer_dashboard"
        page.app_render()
        return ft.Container()
    snack = page.snack
    logout = page.logout
    # End context injection

    is_admin = state["role"] == "admin"
    
    # 1. Try Cache First
    cached_orders = cache.get_cached_orders()
    # If we have state data already, use it (it's the most "fresh")
    # Otherwise use cached_orders
    raw_orders = state.get("orders_cache", cached_orders)

    # --- NORMALIZE: Handle legacy cache format ({"order": ..., "items": ...}) ---
    orders_with_items = []
    for o in raw_orders:
        if isinstance(o, dict) and "order" in o and "items" in o:
            # Migrate old format to new nested format
            normalized = {**o["order"], "order_items": o["items"]}
            orders_with_items.append(normalized)
        else:
            orders_with_items.append(o)

    def on_order_tap(order_id):
        def _h(_):
            state["detail_order_id"] = order_id
            go("order_detail")
        return _h

    def fetch_latest_data():
        """Background fetch to refresh cache and UI."""
        try:
            latest = db.get_orders_with_items(raise_errors=True)
            state["orders_cache"] = latest
            # Update cache file too
            import json
            import time
            orders_data = {"orders": latest, "synced_at": time.time()}
            with open(cache._orders_path(), "w", encoding="utf-8") as f:
                json.dump(orders_data, f, ensure_ascii=False)
            
            # Refresh UI if we are still on home
            if state["current_page"] == "home":
                page.app_render()
        except Exception as e:
            pass

    # Always trigger a background fetch when entering the home screen to catch new orders.
    # The inner fetch_latest_data() handles updating state and refreshing UI.
    import threading
    threading.Thread(target=fetch_latest_data, daemon=True).start()

    # Ensure state has the initial cached values for immediate render
    if "orders_cache" not in state:
        state["orders_cache"] = orders_with_items

    order_cards = []
    if not orders_with_items:
        order_cards.append(
            ft.Container(
                expand=True,
                alignment=ft.alignment.center,
                padding=60,
                content=ft.Column(
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=12,
                    controls=[
                        ft.Icon(ft.Icons.INBOX, size=64, color=ft.Colors.GREY_400),
                        ft.Text("No orders yet", size=16, color=ft.Colors.GREY_600),
                        ft.Text("Tap + to create your first order", size=13, color=ft.Colors.GREY_500),
                    ],
                ),
            )
        )
    else:
        for order in orders_with_items:
            # Use embedded items instead of fetching separately
            line_items = order.get("order_items", [])
            # Determine categories present in this order
            cats_in_order = list(set(it.get("category", "Chuda") for it in line_items))
            cat_color = page.CATEGORY_COLORS.get(cats_in_order[0], ft.Colors.GREY_400) if cats_in_order else ft.Colors.GREY_400

            # Category chips
            cat_chips = []
            for cat in sorted(set(cats_in_order)):
                cat_chips.append(
                    ft.Container(
                        padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                        bgcolor=page.CATEGORY_COLORS.get(cat, ft.Colors.GREY_400),
                        border_radius=4,
                        content=ft.Text(cat.replace("_", " "), size=10, color=ft.Colors.WHITE),
                    )
                )

            # Card content
            card_controls = [
                ft.Text(f"Order #{order['order_id']}  •  {order['order_date']}",
                        size=13, weight="bold"),
            ]
            if is_admin:
                card_controls.append(
                    ft.Text(order["customer_name"], size=12, color=ft.Colors.GREY_700)
                )
            if cat_chips:
                card_controls.append(ft.Row(cat_chips, spacing=4, wrap=True))
            if is_admin:
                card_controls.append(
                    ft.Text(f"₹{order['total_amount']:,.2f}", size=14,
                            weight="bold", color=ft.Colors.INDIGO_700)
                )


            def make_delete_handler(oid):
                def _h(_):
                    def close_dlg(e):
                        page.pop_dialog()
                        page.update()
                    def confirm_delete(e):
                        import db
                        db.delete_order(oid)
                        snack(f"✅ Order #{oid} deleted!")
                        # We also need to remove it from cache
                        if "orders_cache" in state:
                            new_cache = []
                            for o in state["orders_cache"]:
                                current_id = o.get("order", o).get("order_id", o.get("id"))
                                if current_id != oid:
                                    new_cache.append(o)
                            state["orders_cache"] = new_cache
                        page.pop_dialog()
                        page.state["current_page"] = "home"
                        page.app_render()
                    dlg = ft.AlertDialog(
                        modal=True,
                        title=ft.Text("Confirm Delete"),
                        content=ft.Text(f"Are you sure you want to delete Order #{oid}?"),
                        actions=[
                            ft.TextButton("Cancel", on_click=close_dlg),
                            ft.TextButton("Delete", on_click=confirm_delete, style=ft.ButtonStyle(color=ft.Colors.RED)),
                        ],
                        actions_alignment=ft.MainAxisAlignment.END,
                    )
                    page.overlay.append(dlg)
                    dlg.open = True
                    page.update()
                    page.update()
                return _h

            # Each order as a tappable ListTile
            order_cards.append(
                ft.ListTile(
                    on_click=on_order_tap(order["order_id"]),
                    bgcolor=ft.Colors.WHITE,
                    leading=ft.Container(
                        width=6, height=50,
                        bgcolor=cat_color,
                        border_radius=3,
                    ),
                    title=ft.Text(
                        f"Order #{order['order_id']}  •  {order['order_date']}",
                        size=13, weight="bold",
                    ),
                    subtitle=ft.Column(
                        spacing=4,
                        controls=([ft.Text(order["customer_name"], size=12,
                                          color=ft.Colors.GREY_700)] if is_admin else [])
                        + ([ft.Row(cat_chips, spacing=4, wrap=True)] if cat_chips else [])
                        + ([ft.Text(f"₹{order['total_amount']:,.2f}", size=13,
                                   weight="bold",
                                   color=ft.Colors.INDIGO_700)] if is_admin else []),
                    ),

                    trailing=ft.IconButton(ft.Icons.DELETE, icon_color=ft.Colors.RED_500, on_click=make_delete_handler(order["order_id"])) if is_admin else ft.Icon(ft.Icons.CHEVRON_RIGHT, color=ft.Colors.GREY_400),
                )
            )

    def on_fab_click(_):
        go("order_type_picker")

    fab = ft.FloatingActionButton(
        icon=ft.Icons.ADD,
        bgcolor=ft.Colors.AMBER_600,
        foreground_color=ft.Colors.WHITE,
        on_click=on_fab_click,
    )

    body = ft.Container(
        expand=True,
        padding=12,
        content=ft.Column(
            expand=True, spacing=8,
            scroll=ft.ScrollMode.AUTO,
            controls=order_cards,
        ),
    )

    return ft.Stack(
        expand=True,
        controls=[
            body,
            ft.Container(
                content=fab,
                right=16,
                bottom=16,
            ),
        ],
    )

# ============================================================
# ORDER TYPE PICKER — Single category or Mixed
# ============================================================




