import flet as ft
import db
from utils import *


def view_orders_archive(page: ft.Page):
    state = page.state
    go = page.go
    snack = page.snack

    archived = db.get_archived_orders()

    def on_order_tap(order_id):
        def _h(_):
            state["detail_order_id"] = order_id
            go("order_detail")
        return _h

    cards = []
    if not archived:
        cards.append(
            ft.Container(
                expand=True,
                alignment=ft.alignment.center,
                padding=60,
                content=ft.Column(
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=12,
                    controls=[
                        ft.Icon(ft.Icons.ARCHIVE, size=64, color=ft.Colors.GREY_400),
                        ft.Text("No archived orders", size=16, color=ft.Colors.GREY_600),
                        ft.Text("Completed and cancelled orders will appear here", size=13, color=ft.Colors.GREY_500),
                    ],
                ),
            )
        )
    else:
        for order in archived:
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
            status = (order.get("status") or "pending").lower()
            status_colors = {
                "completed": ft.Colors.GREEN_700,
                "cancelled": ft.Colors.RED_600,
            }
            status_bg = status_colors.get(status, ft.Colors.GREY_500)
            status_badge = ft.Container(
                padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                bgcolor=status_bg,
                border_radius=4,
                content=ft.Text(status.upper(), size=10, color=ft.Colors.WHITE, weight="bold"),
            )

            cards.append(
                ft.ListTile(
                    on_click=on_order_tap(order_id),
                    bgcolor=ft.Colors.WHITE,
                    leading=ft.Container(width=6, height=50, bgcolor=cat_color, border_radius=3),
                    title=ft.Row(
                        spacing=6,
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            status_badge,
                            ft.Text(f"Order #{order_id}  \u2022  {order.get('order_date', '')}", size=13, weight="bold"),
                        ],
                    ),
                    subtitle=ft.Column(
                        spacing=4,
                        controls=[
                            ft.Text(order.get("customer_name", ""), size=12, color=ft.Colors.GREY_700),
                            ft.Row(cat_chips, spacing=4, wrap=True) if cat_chips else ft.Container(),
                            ft.Text(f"\u20b9{order.get('total_amount', 0):,.2f}", size=13, weight="bold", color=ft.Colors.INDIGO_700),
                        ],
                    ),
                    trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT, color=ft.Colors.GREY_400),
                )
            )

    body = ft.Column(
        expand=True,
        spacing=8,
        scroll=ft.ScrollMode.AUTO,
        controls=cards,
    )

    return ft.Container(
        expand=True,
        padding=12,
        content=body,
    )
