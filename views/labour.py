import flet as ft
import db
from utils import *

STATUS_STYLES = {
    "pending": (ft.Colors.GREY_400, "⬜ Pending"),
    "prepared": (ft.Colors.GREEN_600, "✅ Prepared"),
    "not_available": (ft.Colors.RED_500, "⚠ Not Available"),
}

SIZE_KEYS = ["2.2", "2.4", "2.6", "2.8", "2.10"]
QTY_COLUMN_MAP = {
    "2.2": "qty_2_2", "2.4": "qty_2_4", "2.6": "qty_2_6",
    "2.8": "qty_2_8", "2.10": "qty_2_10",
}

STATUS_CYCLE = ["pending", "prepared", "not_available"]


def _next_status(current: str) -> str:
    try:
        idx = STATUS_CYCLE.index(current)
        return STATUS_CYCLE[(idx + 1) % len(STATUS_CYCLE)]
    except ValueError:
        return "pending"


def _build_progress_summary(order_items: list) -> str:
    total = 0
    prepared = 0
    for item in order_items:
        ps = item.get("production_status")
        if not ps or ps == {}:
            ps = {}
        if isinstance(ps, str):
            try:
                import json
                ps = json.loads(ps)
            except (json.JSONDecodeError, TypeError):
                ps = {}
        # Count sized items
        has_sizes = any(_safe_int(item.get(QTY_COLUMN_MAP.get(s, ""), 0)) > 0 for s in SIZE_KEYS)
        if has_sizes:
            for s in SIZE_KEYS:
                qty = _safe_int(item.get(QTY_COLUMN_MAP[s], 0))
                if qty > 0:
                    total += 1
                    if ps.get(s) == "prepared":
                        prepared += 1
        else:
            qty = _safe_int(item.get("quantity", 0))
            if qty > 0:
                total += 1
                if ps.get("single") == "prepared":
                    prepared += 1
    return f"Prepared {prepared} / {total}"


def view_production_checklist(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields

    order_id = state.get("detail_order_id")
    if not order_id:
        return ft.Container(content=ft.Text("No order selected"), padding=16)

    order = db.get_order_by_id(order_id)
    if not order:
        return ft.Container(content=ft.Text("Order not found"), padding=16)

    line_items = order.get("order_items", [])
    image_lookup = db.get_image_lookup()

    progress_text = ft.Text(
        _build_progress_summary(line_items),
        size=14, weight="bold", color=ft.Colors.GREEN_700,
    )

    def _update_progress():
        progress_text.value = _build_progress_summary(line_items)
        page.update()

    def _make_toggle_handler(item_number: str, size_key: str, status_ref: dict):
        def _h(e):
            current = status_ref.get(size_key, "pending")
            next_st = _next_status(current)
            status_ref[size_key] = next_st

            # Persist all statuses for this item
            item_statuses = {}
            for sk in SIZE_KEYS:
                sk_val = status_ref.get(sk)
                if sk_val and sk_val != "pending":
                    item_statuses[sk] = sk_val
            # For non-sized items
            single_val = status_ref.get("single")
            if single_val and single_val != "pending":
                item_statuses["single"] = single_val

            db.update_item_production_status(order_id, item_number, item_statuses)
            _update_progress()
            e.control.update()
        return _h

    item_cards = []
    for item in line_items:
        item_no = item.get("item_number", "—")
        color = item.get("color")
        category = item.get("category", "")
        raw_ps = item.get("production_status")
        if isinstance(raw_ps, str):
            try:
                import json
                status_data = json.loads(raw_ps)
            except (json.JSONDecodeError, TypeError):
                status_data = {}
        elif isinstance(raw_ps, dict):
            status_data = raw_ps
        else:
            status_data = {}

        # Image
        img_url = image_lookup.get(item_no, "")
        if _is_valid_image(img_url):
            thumb = ft.Image(src=img_url, width=64, height=64, fit=ft.ImageFit.COVER, border_radius=8)
        else:
            thumb = ft.Container(
                width=64, height=64, bgcolor=ft.Colors.GREY_100, border_radius=8,
                alignment=ft.alignment.center,
                content=ft.Icon(ft.Icons.IMAGE, size=28, color=ft.Colors.GREY_400),
            )

        # Determine if sized item
        has_sizes = any(_safe_int(item.get(QTY_COLUMN_MAP.get(s, ""), 0)) > 0 for s in SIZE_KEYS)

        # Info column
        info_col = ft.Column(spacing=2, controls=[
            ft.Text(item_no, size=14, weight="bold"),
            ft.Row(spacing=4, controls=[
                ft.Container(
                    padding=ft.Padding(4, 1, 4, 1),
                    bgcolor=page.CATEGORY_COLORS.get(category, ft.Colors.GREY_400),
                    border_radius=3,
                    content=ft.Text(category.replace("_", " "), size=9, color=ft.Colors.WHITE, weight="bold"),
                ),
            ]),
        ])
        if color:
            info_col.controls.append(ft.Text(f"Color: {color}", size=11, color=ft.Colors.GREY_700))

        # Size rows
        size_rows = []
        if has_sizes:
            for s in SIZE_KEYS:
                qty_col = QTY_COLUMN_MAP[s]
                qty = _safe_int(item.get(qty_col, 0))
                if qty == 0:
                    continue

                current_st = status_data.get(s, "pending")
                st_color, st_label = STATUS_STYLES.get(current_st, STATUS_STYLES["pending"])

                status_btn = ft.Container(
                    on_click=_make_toggle_handler(item_no, s, status_data),
                    padding=ft.Padding(6, 3, 6, 3),
                    border_radius=6,
                    bgcolor=ft.Colors.with_opacity(0.1, st_color),
                    ink=True,
                    content=ft.Text(st_label, size=11, weight="bold", color=st_color),
                )

                size_rows.append(
                    ft.Container(
                        padding=ft.Padding(0, 0, 0, 4),
                        content=ft.Row(
                            spacing=8,
                            vertical_alignment=ft.CrossAxisAlignment.CENTER,
                            controls=[
                                ft.Container(width=40, content=ft.Text(s, size=13, weight="bold")),
                                ft.Container(width=40, content=ft.Text(str(qty), size=13)),
                                status_btn,
                            ],
                        ),
                    )
                )
        else:
            # Non-sized / simple quantity item
            qty = _safe_int(item.get("quantity", 0))
            current_st = status_data.get("single", "pending")
            st_color, st_label = STATUS_STYLES.get(current_st, STATUS_STYLES["pending"])

            status_btn = ft.Container(
                on_click=_make_toggle_handler(item_no, "single", status_data),
                padding=ft.Padding(6, 3, 6, 3),
                border_radius=6,
                bgcolor=ft.Colors.with_opacity(0.1, st_color),
                ink=True,
                content=ft.Text(st_label, size=11, weight="bold", color=st_color),
            )

            size_rows.append(
                ft.Container(
                    padding=ft.Padding(0, 0, 0, 4),
                    content=ft.Row(
                        spacing=8,
                        vertical_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Container(width=40, content=ft.Text("Qty", size=13, weight="bold")),
                            ft.Container(width=40, content=ft.Text(str(qty), size=13)),
                            status_btn,
                        ],
                    ),
                )
            )

        # Divider between sized rows for readability
        size_col = ft.Column(spacing=2, controls=size_rows)

        item_cards.append(
            ft.Container(
                padding=12, border_radius=10,
                bgcolor=ft.Colors.WHITE,
                border=ft.border.all(1, ft.Colors.GREY_200),
                content=ft.Column(spacing=8, controls=[
                    ft.Row(spacing=10, controls=[thumb, info_col]),
                    size_col,
                ]),
            )
        )

    # Header card
    header_card = ft.Container(
        padding=14, border_radius=10,
        bgcolor=ft.Colors.WHITE,
        border=ft.border.all(1, ft.Colors.GREY_200),
        content=ft.Column(spacing=6, controls=[
            ft.Text(f"📋 Production Checklist — Order #{order_id}", size=18, weight="bold"),
            ft.Text(order.get("order_date", ""), size=13, color=ft.Colors.GREY_700),
            progress_text,
        ]),
    )

    body = ft.Container(
        expand=True, padding=12,
        content=ft.Column(
            spacing=12, scroll=ft.ScrollMode.AUTO,
            controls=[header_card] + item_cards + [ft.Container(height=24)],
        ),
    )

    return body
