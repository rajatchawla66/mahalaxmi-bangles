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

    def _build_order_cards(orders_list):
        """Build order card widgets from a normalized orders list."""

        def _production_summary(order_items):
            prepared = 0
            not_available = 0
            total = 0
            has_data = False
            for item in order_items:
                raw_ps = item.get("production_status")
                if not raw_ps or raw_ps == {}:
                    continue
                if isinstance(raw_ps, str):
                    try:
                        import json as _json
                        ps = _json.loads(raw_ps)
                    except Exception:
                        ps = {}
                else:
                    ps = raw_ps
                if ps:
                    has_data = True
                has_sizes = any(item.get(f"qty_2_{s}", 0) > 0 for s in ["2", "4", "6", "8", "10"])
                if has_sizes:
                    for sk in ["2.2", "2.4", "2.6", "2.8", "2.10"]:
                        qty_col = f"qty_{sk.replace('.', '_')}"
                        if item.get(qty_col, 0) > 0:
                            total += 1
                            st = ps.get(sk, "pending")
                            if st == "prepared":
                                prepared += 1
                            elif st == "not_available":
                                not_available += 1
                else:
                    qty = item.get("quantity", 0) or 0
                    if qty > 0:
                        total += 1
                        st = ps.get("single", "pending")
                        if st == "prepared":
                            prepared += 1
                        elif st == "not_available":
                            not_available += 1
            return prepared, not_available, total, has_data
        cards = []
        if not orders_list:
            cards.append(
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
            return cards

        for order in orders_list:
            raw_status = order.get("status")
            order_status = (raw_status or "pending").lower()
            if order_status in ("completed", "cancelled"):
                continue
            line_items = order.get("order_items", [])
            cats_in_order = list(set(it.get("category", "Chuda") for it in line_items))
            cat_color = page.CATEGORY_COLORS.get(cats_in_order[0], ft.Colors.GREY_400) if cats_in_order else ft.Colors.GREY_400

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

            order_id = order["order_id"]
            raw_status = order.get("status")
            status = (raw_status or "pending").lower()
            status_colors = {
                "pending": ft.Colors.AMBER_700,
                "confirmed": ft.Colors.GREEN_700,
                "cancelled": ft.Colors.RED_600,
            }
            status_bg = status_colors.get(status, ft.Colors.GREY_500)
            status_badge = ft.Container(
                padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                bgcolor=status_bg,
                border_radius=4,
                content=ft.Text(status.upper(), size=10, color=ft.Colors.WHITE, weight="bold"),
            )

            def make_delete_handler(oid):
                def _h(_):
                    def close_dlg(e):
                        dlg.open = False
                        page.update()
                    def confirm_delete(e):
                        import db
                        ok = db.delete_order(oid)
                        if not ok:
                            snack(f"❌ Failed to delete Order #{oid}", ft.Colors.RED_400)
                            dlg.open = False
                            page.update()
                            return
                        snack(f"✅ Order #{oid} deleted!")
                        if "orders_cache" in state:
                            new_cache = []
                            for o in state["orders_cache"]:
                                current_id = o.get("order", o).get("order_id", o.get("id"))
                                if current_id != oid:
                                    new_cache.append(o)
                            state["orders_cache"] = new_cache
                        dlg.open = False
                        _cards_column.controls = _build_order_cards(state.get("orders_cache", []))
                        page.update()
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

            def make_status_handler(oid, new_status):
                def _h(_):
                    import db
                    ok = db.set_order_status(oid, new_status)
                    if not ok:
                        snack(f"❌ Failed to update Order #{oid}", ft.Colors.RED_400)
                        return
                    label = new_status.capitalize()
                    snack(f"{'✅' if new_status == 'confirmed' else '🛑'} Order #{oid} {label}!")
                    if "orders_cache" in state:
                        for o in state["orders_cache"]:
                            current_id = o.get("order", o).get("order_id", o.get("id"))
                            if current_id == oid:
                                if isinstance(o, dict) and "order" in o:
                                    o["order"]["status"] = new_status
                                else:
                                    o["status"] = new_status
                                break
                    _cards_column.controls = _build_order_cards(state.get("orders_cache", []))
                    page.update()
                return _h

            # Title row with inline status badge
            title_controls = [
                status_badge,
                ft.Text(f"Order #{order_id}  •  {order.get('order_date', '')}", size=13, weight="bold"),
            ]
            title_row = ft.Row(spacing=6, vertical_alignment=ft.CrossAxisAlignment.CENTER, controls=title_controls)

            # Subtitle (no status badge — moved to title)
            subtitle_controls = []
            if is_admin:
                subtitle_controls.append(ft.Text(order.get("customer_name", ""), size=12, color=ft.Colors.GREY_700))
            if cat_chips:
                subtitle_controls.append(ft.Row(cat_chips, spacing=4, wrap=True))
            if is_admin:
                subtitle_controls.append(ft.Text(f"₹{order.get('total_amount', 0):,.2f}", size=13, weight="bold", color=ft.Colors.INDIGO_700))
            # Production summary (admin only)
            if is_admin:
                prod_prepared, prod_na, prod_total, prod_has_data = _production_summary(line_items)
                if prod_has_data:
                    prod_parts = []
                    if prod_prepared > 0:
                        prod_parts.append(f"✅ {prod_prepared}/{prod_total}")
                    if prod_na > 0:
                        prod_parts.append(f"⚠ {prod_na}")
                    subtitle_controls.append(
                        ft.Text(f"Production: {'  '.join(prod_parts)}", size=11, color=ft.Colors.GREY_700)
                    )

            # Trailing: popup menu for pending/confirmed admin orders; chevron for labour
            if is_admin and status == "pending":
                popup_items = [
                    ft.PopupMenuItem(text="Confirm", icon=ft.Icons.CHECK_CIRCLE, on_click=make_status_handler(order_id, "confirmed")),
                    ft.PopupMenuItem(text="Cancel", icon=ft.Icons.CANCEL, on_click=make_status_handler(order_id, "cancelled")),
                    ft.PopupMenuItem(text="Delete", icon=ft.Icons.DELETE, on_click=make_delete_handler(order_id)),
                ]
                trailing = ft.PopupMenuButton(icon=ft.Icons.MORE_VERT, icon_color=ft.Colors.GREY_600, items=popup_items)
            elif is_admin and status == "confirmed":
                trailing = ft.PopupMenuButton(
                    icon=ft.Icons.MORE_VERT, icon_color=ft.Colors.GREY_600,
                    items=[ft.PopupMenuItem(text="Mark Completed", icon=ft.Icons.CHECK_CIRCLE, on_click=make_status_handler(order_id, "completed"))],
                )
            elif not is_admin:
                trailing = ft.Icon(ft.Icons.CHEVRON_RIGHT, color=ft.Colors.GREY_400)
            else:
                trailing = None

            cards.append(
                ft.ListTile(
                    on_click=on_order_tap(order_id),
                    bgcolor=ft.Colors.WHITE,
                    leading=ft.Container(width=6, height=50, bgcolor=cat_color, border_radius=3),
                    title=title_row,
                    subtitle=ft.Column(spacing=4, controls=subtitle_controls),
                    trailing=trailing,
                )
            )
        return cards

    order_cards = _build_order_cards(orders_with_items)

    # Persistent scrollable column for targeted in-place updates
    _cards_column = ft.Column(
        expand=True, spacing=8,
        scroll=ft.ScrollMode.AUTO,
        controls=order_cards,
    )

    def fetch_latest_data():
        """Background fetch to refresh cache and UI via targeted update."""
        try:
            latest = db.get_orders_with_items(raise_errors=True)
            state["orders_cache"] = latest
            import json
            import time
            orders_data = {"orders": latest, "synced_at": time.time()}
            with open(cache._orders_path(), "w", encoding="utf-8") as f:
                json.dump(orders_data, f, ensure_ascii=False)

            if state["current_page"] == "home":
                _cards_column.controls = _build_order_cards(latest)
                page.update()
        except Exception:
            pass

    import threading
    threading.Thread(target=fetch_latest_data, daemon=True).start()

    if "orders_cache" not in state:
        state["orders_cache"] = orders_with_items

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
        content=_cards_column,
    )

    return ft.Stack(
        expand=True,
        controls=[
            body,
            ft.Container(content=fab, right=16, bottom=16),
        ],
    )

# ============================================================
# ORDER TYPE PICKER — Single category or Mixed
# ============================================================




