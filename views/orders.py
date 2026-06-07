import flet as ft
# TODO: Fix WhatsApp Sharing for 0.28.3
# from flet import Share
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
from utils import *
import datetime

def view_order_type_picker(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields
    # End context injection

    def pick_single(_):
        state["order_mode"] = "single"
        go("category_picker")

    def pick_mixed(_):
        state["order_mode"] = "mixed"
        state["selected_category"] = None
        state["cart"] = []
        state["cart_uid"] = 0
        go("order_form")

    return ft.Container(
        expand=True,
        padding=24,
        content=ft.Column(
            spacing=24,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Container(height=40),
                ft.Text("New Order", size=24, weight="bold"),
                ft.Text("What type of order is this?",
                        size=14, color=ft.Colors.GREY_600),
                ft.Container(height=16),
                ft.Container(
                    on_click=pick_single,
                    ink=True,
                    padding=20,
                    border_radius=12,
                    bgcolor=ft.Colors.INDIGO_50,
                    border=ft.border.all(2, ft.Colors.INDIGO_200),
                    width=300,
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=8,
                        controls=[
                            ft.Icon(ft.Icons.CATEGORY, size=40, color=ft.Colors.INDIGO_600),
                            ft.Text("Single Category", size=16,
                                    weight="bold"),
                            ft.Text("All items from one category\n(e.g., only Chuda)",
                                    size=12, color=ft.Colors.GREY_600,
                                    text_align=ft.TextAlign.CENTER),
                        ],
                    ),
                ),
                ft.Container(
                    on_click=pick_mixed,
                    ink=True,
                    padding=20,
                    border_radius=12,
                    bgcolor=ft.Colors.AMBER_50,
                    border=ft.border.all(2, ft.Colors.AMBER_200),
                    width=300,
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=8,
                        controls=[
                            ft.Icon(ft.Icons.DASHBOARD, size=40, color=ft.Colors.AMBER_700),
                            ft.Text("Mixed Order", size=16,
                                    weight="bold"),
                            ft.Text("Items from multiple categories\n(e.g., Chuda + Kaleera + Raw Material)",
                                    size=12, color=ft.Colors.GREY_600,
                                    text_align=ft.TextAlign.CENTER),
                        ],
                    ),
                ),
            ],
        ),
    )

# ============================================================
# CATEGORY PICKER VIEW
# ============================================================

def view_category_picker(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields
    # End context injection

    def pick_category(cat):
        def _h(_):
            state["selected_category"] = cat
            state["cart"] = []
            state["cart_uid"] = 0
            go("order_form")
        return _h

    cards = []
    for cat in db.get_category_names(active_only=True):
        color = page.CATEGORY_COLORS.get(cat, ft.Colors.GREY_400)
        icon = page.CATEGORY_ICONS.get(cat, ft.Icons.CATEGORY)
        desc = page.CATEGORY_DESCRIPTIONS.get(cat, "")

        cards.append(
            ft.Container(
                on_click=pick_category(cat),
                padding=16,
                border_radius=12,
                ink=True,
                bgcolor=ft.Colors.WHITE,
                shadow=ft.BoxShadow(
                    spread_radius=0,
                    blur_radius=4,
                    color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK),
                    offset=ft.Offset(0, 2),
                ),
                alignment=ft.alignment.center,
                content=ft.Column(
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    spacing=8,
                    controls=[
                        ft.Icon(icon, size=48, color=color),
                        ft.Text(cat.replace("_", " "), size=14,
                                weight="bold"),
                        ft.Text(desc, size=11, color=ft.Colors.GREY_600,
                                text_align=ft.TextAlign.CENTER),
                    ],
                ),
            )
        )

    grid = ft.Row(
        spacing=10,
        wrap=True,
        controls=[ft.Container(c, width=170) for c in cards],
    )

    return ft.Container(
        expand=True,
        padding=16,
        content=ft.Column(
            spacing=16,
            scroll=ft.ScrollMode.AUTO,
            expand=True,
            controls=[
                ft.Text("What are you ordering?", size=22, weight="bold"),
                ft.Text("Pick a category to start", size=13, color=ft.Colors.GREY_600),
                grid,
            ],
        ),
    )

# ============================================================
# ORDER FORM VIEW (multi-item cart, pre-filtered by category)
# ============================================================

def view_order_form(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields
    # End context injection

    is_mixed = state.get("order_mode") == "mixed"
    selected_cat = state.get("selected_category") or None

    # --- CACHE OPTIMIZATION: Try local cache first ---
    all_available = cache.get_cached_catalog()
    if not all_available:
        # Fallback to DB if cache is empty
        if is_mixed:
            all_available = db.get_available_items()
        else:
            all_available = db.get_available_items(selected_cat)
    
    # Filter available items (in DB it's done server side, in cache we do it here)
    all_available = [it for it in all_available if it.get("is_available", 1)]
    
    if is_mixed:
        rate_lookup = {item["item_number"]: item for item in all_available}
    else:
        available_items = [it for it in all_available if not selected_cat or it.get("category") == selected_cat]
        rate_lookup = {item["item_number"]: item for item in available_items}

    item_numbers = list(rate_lookup.keys())
    active_categories = db.get_category_names(active_only=True)

    # ----- Order-level header inputs -----
    customer_tf = ft.TextField(
        label="Customer Name *", 
        value=state.get("edit_order_customer", ""),
        hint_text="e.g., Sharma Bangles"
    )
    date_tf = ft.TextField(
        label="Order Date",
        value=state.get("edit_order_date", datetime.date.today().isoformat()),
        hint_text="YYYY-MM-DD",
    )
    packing_dd = ft.Dropdown(
        label="Packing Structure",
        options=[ft.dropdown.Option(p) for p in PACKING_OPTIONS],
        value=state.get("edit_order_packing", PACKING_OPTIONS[0]),
        expand=True,
    )
    notes_tf = ft.TextField(
        label="Additional Info",
        value=state.get("edit_order_notes", ""),
        multiline=True,
        min_lines=2,
        max_lines=4,
        hint_text="Any custom requests, special instructions",
    )

    # ----- Cart rendering -----
    cart_column = ft.Column(spacing=12)
    summary_total_items = ft.Text("0", size=16, weight="bold")
    summary_total_sets = ft.Text("0", size=16, weight="bold")
    summary_total_amount = ft.Text("₹0.00", size=16, weight="bold")
    summary_rows_column = ft.Column(spacing=4)

    def refresh_summary():
        total_items = len(state["cart"])
        total_qty = 0
        total_amount = 0.0

        rows = [
            ft.Row([
                ft.Container(ft.Text("Item", weight="bold"), expand=2),
                ft.Container(ft.Text("Qty", weight="bold"), expand=1),
                ft.Container(ft.Text("Line ₹", weight="bold"), expand=2),
            ])
        ]
        for ci in state["cart"]:
            item_no = ci.get("item_number", "")
            category = ci.get("category", selected_cat)
            unit_price = (
                rate_lookup.get(item_no, {}).get("selling_price", 0)
                if item_no else 0
            )
            # Ensure _has_sizes is set for line total calculation
            if "_has_sizes" not in ci and item_no:
                ci["_has_sizes"] = bool(rate_lookup.get(item_no, {}).get("has_sizes", 0))
            line_total = calculate_line_total(ci, category, unit_price) if category else 0.0

            # Determine display quantity based on item properties
            if ci.get("_has_sizes"):
                qty_display = sum(_safe_int(ci.get(k, 0)) for k in db.QTY_COLUMNS)
            else:
                qty_display = ci.get("quantity", 0) or 0

            total_qty += qty_display if isinstance(qty_display, (int, float)) else 0
            total_amount += line_total
            rows.append(
                ft.Row([
                    ft.Container(ft.Text(item_no or "—"), expand=2),
                    ft.Container(ft.Text(str(qty_display)), expand=1),
                    ft.Container(ft.Text(f"₹{line_total:,.2f}"), expand=2),
                ])
            )

        summary_rows_column.controls = rows
        summary_total_items.value = str(total_items)
        summary_total_sets.value = str(int(total_qty))
        summary_total_amount.value = f"₹{total_amount:,.2f}"
        return total_amount

    def _stat_card_wrap(label, value_ctrl):
        return ft.Container(
            width=100, padding=8, border_radius=10,
            bgcolor=ft.Colors.INDIGO_50,
            content=ft.Column(
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=2,
                controls=[value_ctrl, ft.Text(label, size=11, color=ft.Colors.GREY_700)],
            ),
        )

    def render_cart():
        cart_column.controls = [build_cart_row(ci) for ci in state["cart"]]
        refresh_summary()
        page.update()

    def _reset_cart_item_attributes(ci):
        ci["qty_2_2"] = 0
        ci["qty_2_4"] = 0
        ci["qty_2_6"] = 0
        ci["qty_2_8"] = 0
        ci["qty_2_10"] = 0
        ci["quantity"] = None
        ci["unit"] = None
        ci["color"] = None
        ci["grind_type"] = None
        ci["box_type"] = None
        ci["notes"] = None
        ci["sub_category"] = None

    def build_cart_row(ci):
        uid = ci["uid"]

        image_ctrl = ft.Image(
            src="", width=100, height=100,
            fit=ft.ImageFit.COVER, border_radius=8, visible=False,
        )
        placeholder_ctrl = ft.Container(
            width=100, height=100,
            bgcolor=ft.Colors.GREY_200, border_radius=8,
            alignment=ft.alignment.center,
            content=ft.Text("Pick item", size=11, color=ft.Colors.GREY_600),
            visible=True,
        )
        sp_text = ft.Text("", size=11, color=ft.Colors.GREY_700)
        line_total_text = ft.Text("", size=12, color=ft.Colors.GREY_700)
        category_fields_column = ft.Column(spacing=8)

        # In mixed mode: track which category is selected for this row
        row_category = {"value": ci.get("category", "")}

        # Item dropdown — will be rebuilt when category changes in mixed mode
        item_dd = ft.Dropdown(
            label="Item Number",
            value=ci["item_number"] or None,
            options=[],
            expand=True,
        )

        def _get_items_for_row():
            """Get item options based on mode and row category."""
            if is_mixed:
                cat = row_category["value"]
                if cat:
                    return [it["item_number"] for it in all_available
                            if it.get("category") == cat]
                return []
            else:
                return item_numbers

        def _refresh_item_options():
            """Rebuild item dropdown options."""
            opts = _get_items_for_row()
            item_dd.options = [ft.dropdown.Option(x) for x in opts]

        _refresh_item_options()

        def update_preview(item_no):
            info = rate_lookup.get(item_no)
            if info and _is_valid_image(info.get("image_url", "")):
                image_ctrl.src = info["image_url"]
                image_ctrl.visible = True
                placeholder_ctrl.visible = False
                sp_text.value = f"SP: ₹{info['selling_price']:.2f}"
            elif info:
                image_ctrl.visible = False
                placeholder_ctrl.content = ft.Text("No image", color=ft.Colors.GREY_600)
                placeholder_ctrl.visible = True
                sp_text.value = f"SP: ₹{info['selling_price']:.2f}"
            else:
                image_ctrl.visible = False
                placeholder_ctrl.content = ft.Text("Pick item", size=11, color=ft.Colors.GREY_600)
                placeholder_ctrl.visible = True
                sp_text.value = ""

        def refresh_line_total():
            item_no = ci.get("item_number", "")
            category = ci.get("category", selected_cat or "")
            unit_price = (
                rate_lookup.get(item_no, {}).get("selling_price", 0) if item_no else 0
            )
            line_total = calculate_line_total(ci, category, unit_price) if category else 0.0
            line_total_text.value = f"Line ₹{line_total:,.2f}"

        def rebuild_category_fields():
            category = ci.get("category", selected_cat or "")
            if not category:
                category_fields_column.controls = []
                return
            item_no = ci.get("item_number", "")
            item_info = rate_lookup.get(item_no, {})
            ci["_has_sizes"] = bool(item_info.get("has_sizes", 0))
            ci["_has_color"] = bool(item_info.get("has_color", 0))

            callbacks = {
                "on_change": lambda: [refresh_line_total(), refresh_summary()],
                "page": page,
            }
            fields = build_category_fields(category, ci, callbacks)
            category_fields_column.controls = fields

        def on_item_change(e):
            new_item = item_dd.value or ""
            old_category = ci.get("category", "")
            ci["item_number"] = new_item
            update_preview(new_item)

            if new_item:
                item_info = rate_lookup.get(new_item, {})
                new_category = item_info.get("category", row_category["value"] or selected_cat or "")
                ci["category"] = new_category
                ci["sub_category"] = item_info.get("sub_category")
                if new_category != old_category:
                    _reset_cart_item_attributes(ci)
                    ci["category"] = new_category
                    ci["sub_category"] = item_info.get("sub_category")
            else:
                ci["category"] = row_category["value"] or selected_cat or ""
                _reset_cart_item_attributes(ci)

            rebuild_category_fields()
            refresh_line_total()
            refresh_summary()
            page.update()

        item_dd.on_select = on_item_change

        # Category dropdown for mixed mode
        row_cat_dd = None
        if is_mixed:
            row_cat_dd = ft.Dropdown(
                label="Category",
                options=[ft.dropdown.Option(c) for c in active_categories],
                value=row_category["value"] or None,
                expand=True,
            )

            def on_row_cat_change(e):
                row_category["value"] = row_cat_dd.value or ""
                ci["category"] = row_category["value"]
                # Clear item selection when category changes
                ci["item_number"] = ""
                item_dd.value = None
                _reset_cart_item_attributes(ci)
                _refresh_item_options()
                update_preview("")
                category_fields_column.controls = []
                refresh_line_total()
                refresh_summary()
                page.update()

            row_cat_dd.on_select = on_row_cat_change

        def remove_row(_):
            state["cart"] = [x for x in state["cart"] if x["uid"] != uid]
            render_cart()

        image_area = ft.Stack(
            [placeholder_ctrl, image_ctrl], width=100, height=100,
        )

        update_preview(ci["item_number"])
        rebuild_category_fields()
        refresh_line_total()

        # Build the row controls
        row_controls = [
            ft.Row(
                [
                    ft.Text(f"Item #{state['cart'].index(ci) + 1}",
                            weight="bold"),
                    ft.IconButton(
                        ft.Icons.DELETE_OUTLINE,
                        icon_color=ft.Colors.RED_500,
                        on_click=remove_row, tooltip="Remove",
                    ),
                ],
                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
            ),
        ]
        # Add category dropdown in mixed mode
        if row_cat_dd:
            row_controls.append(row_cat_dd)

        row_controls.extend([
            ft.Row(
                [image_area, ft.Column([item_dd, sp_text], expand=True, spacing=4)],
                spacing=10,
            ),
            category_fields_column,
            line_total_text,
        ])

        return ft.Container(
            padding=10, border_radius=10,
            bgcolor=ft.Colors.WHITE,
            border=ft.border.all(1, ft.Colors.GREY_300),
            content=ft.Column(spacing=8, controls=row_controls),
        )

    def add_cart_row(_):
        if not is_mixed and not item_numbers:
            snack("Add items to the Rate List first.", ft.Colors.ORANGE_600)
            return
        if is_mixed and not all_available:
            snack("Add items to the Rate List first.", ft.Colors.ORANGE_600)
            return
        state["cart_uid"] += 1
        state["cart"].append({
            "uid": state["cart_uid"],
            "item_number": "",
            "category": selected_cat or "",
            "qty_2_2": 0, "qty_2_4": 0, "qty_2_6": 0,
            "qty_2_8": 0, "qty_2_10": 0,
            "quantity": 0, "unit": None, "color": None,
            "grind_type": None, "box_type": None,
            "notes": None, "sub_category": None,
        })
        render_cart()

    def save_order(_):
        if not customer_tf.value.strip():
            snack("Please enter Customer Name.", ft.Colors.RED_500)
            return
        if not state["cart"]:
            snack("Add at least one item.", ft.Colors.RED_500)
            return
        if any(not ci["item_number"] for ci in state["cart"]):
            snack("Every cart row must have an item selected.", ft.Colors.RED_500)
            return

        validation_error = validate_order(state["cart"], rate_lookup)
        if validation_error:
            snack(validation_error, ft.Colors.RED_500)
            return

        total_amount = 0.0
        line_items = []
        for ci in state["cart"]:
            category = ci.get("category", selected_cat)
            unit_price = rate_lookup.get(ci["item_number"], {}).get("selling_price", 0)
            line_total = calculate_line_total(ci, category, unit_price)
            total_amount += line_total
            line_items.append({
                "item_number": ci["item_number"],
                "category": category,
                "qty_2_2": ci.get("qty_2_2", 0),
                "qty_2_4": ci.get("qty_2_4", 0),
                "qty_2_6": ci.get("qty_2_6", 0),
                "qty_2_8": ci.get("qty_2_8", 0),
                "qty_2_10": ci.get("qty_2_10", 0),
                "quantity": ci.get("quantity"),
                "unit": ci.get("unit"),
                "color": ci.get("color"),
                "grind_type": ci.get("grind_type"),
                "box_type": ci.get("box_type"),
                "notes": ci.get("notes"),
                "unit_price": unit_price,
            })

        header_data = {
            "customer_name": customer_tf.value.strip(),
            "order_date": date_tf.value.strip(),
            "color": None,
            "grind_type": None,
            "box_type": None,
            "packing_structure": packing_dd.value,
            "additional_info": notes_tf.value.strip(),
            "total_amount": total_amount,
        }

        if state.get("edit_order_id"):
            db.update_order(state["edit_order_id"], header_data, line_items)
            snack(f"✅ Order #{state['edit_order_id']} updated (₹{total_amount:,.2f})")
            
            for k in ["edit_order_id", "edit_order_customer", "edit_order_date", "edit_order_packing", "edit_order_notes"]:
                if k in state:
                    del state[k]
        else:
            new_id = db.create_order(
                header=header_data,
                line_items=line_items,
            )
            snack(f"✅ Order #{new_id} saved (₹{total_amount:,.2f})")

        state["cart"] = []
        go("home")

    # Build the view
    render_cart()

    summary_column = ft.Column(spacing=6, controls=[
        ft.Container(
            content=summary_rows_column,
            bgcolor=ft.Colors.GREY_100, padding=8, border_radius=8,
        ),
        ft.Row(
            [
                _stat_card_wrap("Items", summary_total_items),
                _stat_card_wrap("Total Sets", summary_total_sets),
                _stat_card_wrap("Amount", summary_total_amount),
            ],
            alignment=ft.MainAxisAlignment.SPACE_AROUND,
            wrap=True,
        ),
    ])

    customer_card = ft.Card(
        elevation=3,
        content=ft.Container(
            padding=12, border_radius=10,
            content=ft.Column(spacing=10, controls=[
                ft.Text("👤 Order Details", size=16, weight="bold"),
                ft.Row(spacing=10, controls=[
                    customer_tf,
                    date_tf,
                ]),
                ft.Row(spacing=10, controls=[
                    packing_dd,
                    notes_tf,
                ]),
            ]),
        ),
    )

    items_header = ft.Row(
        [
            ft.Text("🛒 Items", size=16, weight="bold"),
            ft.FilledTonalButton("➕ Add Item", on_click=add_cart_row, disabled=not item_numbers),
        ],
        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
    )

    items_card = ft.Card(
        elevation=3,
        content=ft.Container(
            padding=12, border_radius=10,
            content=ft.Column(spacing=10, controls=[items_header, cart_column]),
        ),
    )

    summary_card = ft.Card(
        elevation=3,
        content=ft.Container(
            padding=12, border_radius=10,
            content=ft.Column(spacing=10, controls=[
                ft.Text("📊 Summary", size=16, weight="bold"),
                summary_column,
            ]),
        ),
    )

    save_button = ft.FilledButton(
        "💾 Save Order", icon=ft.Icons.SAVE,
        on_click=save_order, height=48, expand=True,
    )

    body = ft.ListView(
        expand=True, spacing=12, padding=12,
        controls=[
            customer_card,
            items_card,
            summary_card,
            ft.Row([save_button]),
            ft.Container(height=24),
        ],
    )
    return body

# ============================================================
# ORDER DETAIL VIEW
# ============================================================

def view_order_detail(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields
    # End context injection

    order_id = state.get("detail_order_id")
    if not order_id:
        return ft.Container(content=ft.Text("No order selected"), padding=16)

    # Fetch order and its items in ONE targeted query
    order = db.get_order_by_id(order_id)
    if not order:
        return ft.Container(content=ft.Text("Order not found"), padding=16)

    is_admin = state["role"] == "admin"
    # Nested items are already in order["order_items"]
    line_items = order.get("order_items", [])

    # Header
    header_controls = [
        ft.Text(f"Order #{order['order_id']}", size=18, weight="bold"),
        ft.Text(f"Date: {order['order_date']}", size=13, color=ft.Colors.GREY_700),
    ]
    if is_admin:
        header_controls.append(ft.Text(f"Customer: {order['customer_name']}", size=14))
    if order.get("packing_structure"):
        header_controls.append(ft.Text(f"Packing: {order['packing_structure']}", size=12, color=ft.Colors.GREY_700))
    if order.get("additional_info"):
        header_controls.append(ft.Text(f"Notes: {order['additional_info']}", size=12, italic=True, color=ft.Colors.GREY_700))

    header_card = ft.Card(
        elevation=3,
        content=ft.Container(
            padding=14, border_radius=10,
            content=ft.Column(header_controls, spacing=6),
        ),
    )

    # Group line items by category
    category_groups = {}
    for it in line_items:
        cat = it.get("category", "Chuda")
        if cat not in category_groups:
            category_groups[cat] = []
        category_groups[cat].append(it)

    items_blocks = []
    grand_total_qty = 0

    for cat in sorted(category_groups.keys()):
        cat_items = category_groups[cat]
        cat_color = page.CATEGORY_COLORS.get(cat, ft.Colors.GREY_400)
        cat_rows = [
            ft.Container(
                padding=ft.Padding(left=6, right=6, top=3, bottom=3),
                bgcolor=cat_color,
                border_radius=4,
                content=ft.Text(f"{cat.replace('_', ' ')} ({len(cat_items)} items)",
                                size=12, weight="bold", color=ft.Colors.WHITE),
            )
        ]

        for it in cat_items:
            item_no = it.get("item_number", "—")
            unit_price = it.get("unit_price", 0)
            attr_parts = []

            sizes_data = [
                ("2.2", it.get("qty_2_2", 0)), ("2.4", it.get("qty_2_4", 0)),
                ("2.6", it.get("qty_2_6", 0)), ("2.8", it.get("qty_2_8", 0)),
                ("2.10", it.get("qty_2_10", 0)),
            ]
            total_sets = sum(q for _, q in sizes_data)

            if total_sets > 0:
                grand_total_qty += total_sets
                size_str = " | ".join(f"{s}:{q}" for s, q in sizes_data if q > 0)
                attr_parts.append(f"Sets: {total_sets}")
                if size_str:
                    attr_parts.append(size_str)
                line_total = total_sets * unit_price
            else:
                qty = it.get("quantity") or 0
                try:
                    qty_val = float(qty)
                except ValueError:
                    qty_val = 0
                grand_total_qty += int(qty_val) if qty_val.is_integer() else qty_val
                
                unit = it.get("unit") or "pieces"
                if cat == "Raw_Material":
                    attr_parts.append(f"Qty: {qty} {unit}")
                else:
                    attr_parts.append(f"Qty: {qty}")
                line_total = qty_val * unit_price

            # Common attributes (Color, Grind, Box, Notes)
            if it.get("color"):
                attr_parts.append(f"Color: {it['color']}")
            if it.get("grind_type"):
                attr_parts.append(f"Grind: {it['grind_type']}")
            if it.get("box_type"):
                attr_parts.append(f"Box: {it['box_type']}")
            if it.get("notes"):
                attr_parts.append(f"Notes: {it['notes']}")

            item_info_controls = [
                ft.Text(item_no, weight="bold", size=13),
            ]
            if attr_parts:
                item_info_controls.append(
                    ft.Text(" • ".join(attr_parts), size=11, color=ft.Colors.GREY_700)
                )

            row_controls = [ft.Column(item_info_controls, expand=True, spacing=2)]
            if is_admin:
                row_controls.append(
                    ft.Text(f"₹{line_total:,.2f}", size=12, color=ft.Colors.GREY_800)
                )
            cat_rows.append(ft.Row(row_controls, spacing=8))

        items_blocks.append(
            ft.Card(
                elevation=2,
                content=ft.Container(
                    padding=10, border_radius=8,
                    border=ft.Border(left=ft.BorderSide(4, cat_color)),
                    content=ft.Column(cat_rows, spacing=6),
                ),
            )
        )

    # Total and actions
    total_controls = [
        ft.Text(f"Total quantity: {grand_total_qty}", size=13, color=ft.Colors.GREY_700),
    ]
    if is_admin:
        total_controls.append(
            ft.Text(f"Total: ₹{order['total_amount']:,.2f}", size=16,
                    weight="bold", color=ft.Colors.INDIGO_700)
        )

    def open_slip(_):
        state["slip_order_id"] = order_id
        go("karigar_slip")

    def open_edit_order(_):
        state["edit_order_id"] = order_id
        state["edit_order_customer"] = order.get("customer_name", "")
        state["edit_order_date"] = order.get("order_date", "")
        state["edit_order_packing"] = order.get("packing_structure", "")
        state["edit_order_notes"] = order.get("additional_info", "")
        
        cart = []
        uid = 0
        for item in line_items:
            uid += 1
            ci = dict(item)
            ci["uid"] = uid
            cart.append(ci)
            
        state["cart"] = cart
        state["cart_uid"] = uid
        state["order_mode"] = "mixed"
        state["selected_category"] = None
        go("order_form")

    action_row = ft.Row([
        ft.FilledButton("Edit Order", icon=ft.Icons.EDIT,
                          style=ft.ButtonStyle(bgcolor=ft.Colors.BLUE_600, color=ft.Colors.WHITE),
                          on_click=open_edit_order),
        ft.FilledTonalButton("🧾 Karigar Slip", icon=ft.Icons.RECEIPT, on_click=open_slip),
    ], wrap=True)

    body_controls = [header_card] + items_blocks + [
        ft.Container(
            padding=12,
            content=ft.Column(total_controls + [action_row], spacing=8),
        ),
        ft.Container(height=24),
    ]

    return ft.ListView(expand=True, spacing=12, padding=12, controls=body_controls)

# ============================================================
# RATE LIST VIEW (admin only) — Two sub-tabs (KEPT)
# ============================================================

def view_karigar_slip(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    build_category_fields = page.build_category_fields
    # End context injection

    # TODO: Fix WhatsApp Sharing for 0.28.3
    # Find the Share service (previously registered globally in main.py via page.services)
    # share_ctrl = None
    # for svc in page.overlay:
    #     if isinstance(svc, ft.Share):
    #         share_ctrl = svc
    #         break
    # if not share_ctrl:
    #     share_ctrl = ft.Share()
    #     page.overlay.append(share_ctrl)

    order_id = state.get("slip_order_id")
    if not order_id:
        return ft.Container(content=ft.Text("No order selected"), padding=16)

    all_orders = {o["order_id"]: o for o in db.get_orders()}
    order = all_orders.get(order_id)
    if not order:
        return ft.Container(content=ft.Text("Order not found"), padding=16)

    line_items = db.get_order_items(order_id)
    image_lookup = db.get_image_lookup()

    header_card = ft.Container(
        padding=14,
        border=ft.border.all(2, ft.Colors.BLACK),
        border_radius=10,
        bgcolor=ft.Colors.WHITE,
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=4,
            controls=[
                ft.Text("कारीगर पर्ची / Karigar Slip",
                        size=22, weight="bold"),
                ft.Text(f"Order #{order_id}  •  {order['order_date']}",
                        size=13, color=ft.Colors.GREY_700),
            ],
        ),
    )

    def _slip_row(label_hindi, value):
        return ft.Row([
            ft.Text(label_hindi, color=ft.Colors.GREY_700, size=13, expand=2),
            ft.Text(value or "—", weight="bold", expand=3),
        ])

    meta_grid = ft.Container(
        padding=12,
        border=ft.border.all(1, ft.Colors.GREY_400),
        border_radius=10,
        bgcolor=ft.Colors.WHITE,
        content=ft.Column(spacing=6, controls=[
            _slip_row("रंग (Color)", order["color"]),
            _slip_row("फिनिशिंग (Gol ya Bina Gol)", order["grind_type"]),
            _slip_row("बॉक्स का प्रकार (Box Type)", order["box_type"]),
            _slip_row("पैकिंग का तरीका (Packing)", order["packing_structure"]),
        ]),
    )

    extra_block = None
    if order["additional_info"]:
        extra_block = ft.Container(
            padding=10,
            border=ft.border.all(1, ft.Colors.GREY_400),
            border_radius=8,
            bgcolor=ft.Colors.AMBER_50,
            content=ft.Text(
                f"विशेष निर्देश (Extra Notes): {order['additional_info']}",
                size=13,
            ),
        )

    item_blocks = []
    for it in line_items:
        img_path = image_lookup.get(it["item_number"])
        if img_path and _is_valid_image(img_path):
            photo = ft.Image(
                src=img_path, width=200, height=200,
                fit=ft.ImageFit.CONTAIN, border_radius=8,
            )
        else:
            photo = ft.Container(
                width=200, height=200,
                bgcolor=ft.Colors.GREY_200, border_radius=8,
                alignment=ft.alignment.center,
                content=ft.Text("कोई तस्वीर नहीं\n(No Image)",
                                text_align=ft.TextAlign.CENTER,
                                color=ft.Colors.GREY_600),
            )

        sizes_data = [
            ("2.2", it.get("qty_2_2", 0)), ("2.4", it.get("qty_2_4", 0)),
            ("2.6", it.get("qty_2_6", 0)), ("2.8", it.get("qty_2_8", 0)),
            ("2.10", it.get("qty_2_10", 0)),
        ]
        total_sets = sum(q for _, q in sizes_data)

        size_rows = []
        if total_sets > 0:
            size_rows.append(
                ft.Row([
                    ft.Container(ft.Text("साइज (Size)", weight="bold"), expand=1),
                    ft.Container(ft.Text("सेट (Sets)", weight="bold"), expand=1),
                ])
            )
            for s, q in sizes_data:
                if q > 0:
                    size_rows.append(ft.Row([
                        ft.Container(ft.Text(s), expand=1),
                        ft.Container(ft.Text(str(q), weight="bold"), expand=1),
                    ]))
        else:
            flat_qty = it.get("quantity") or 0
            size_rows.append(
                ft.Row([
                    ft.Container(ft.Text("मात्रा (Quantity)", weight="bold"), expand=1),
                    ft.Container(ft.Text(str(flat_qty), weight="bold"), expand=1),
                ])
            )

        item_blocks.append(
            ft.Container(
                padding=14,
                border=ft.border.all(2, ft.Colors.BLACK),
                border_radius=10,
                bgcolor=ft.Colors.WHITE,
                content=ft.Column(spacing=10, controls=[
                    ft.Row([
                        photo,
                        ft.Column(expand=True, spacing=8, controls=[
                            ft.Text(f"आइटम नंबर: {it['item_number']}",
                                    size=16, weight="bold"),
                            ft.Text(f"कुल सेट (Quantity): {total_sets}",
                                    size=15, weight="bold",
                                    color=ft.Colors.INDIGO_700),
                            ft.Container(
                                padding=8, bgcolor=ft.Colors.GREY_100,
                                border_radius=6,
                                content=ft.Column(size_rows, spacing=4),
                            ),
                        ]),
                    ], spacing=10),
                ]),
            )
        )

    def build_plain_text_slip(order_data, items):
        lines = [
            "*कारीगर पर्ची / Karigar Slip*",
            f"Order #{order_data['order_id']}  •  {order_data['order_date']}",
            "",
            f"रंग: {order_data['color'] or '—'}",
            f"फिनिशिंग: {order_data['grind_type'] or '—'}",
            f"बॉक्स: {order_data['box_type'] or '—'}",
            f"पैकिंग: {order_data['packing_structure'] or '—'}",
        ]
        if order_data["additional_info"]:
            lines.append(f"विशेष: {order_data['additional_info']}")
        lines.append("")
        lines.append("*आइटम विवरण:*")
        for item in items:
            sets_in = (item["qty_2_2"] + item["qty_2_4"] + item["qty_2_6"]
                       + item["qty_2_8"] + item["qty_2_10"])
            lines.append(f"\n• आइटम नंबर: *{item['item_number']}*")
            lines.append(f"  कुल सेट: *{sets_in}*")
            for label, q in [
                ("2.2", item["qty_2_2"]), ("2.4", item["qty_2_4"]),
                ("2.6", item["qty_2_6"]), ("2.8", item["qty_2_8"]),
                ("2.10", item["qty_2_10"]),
            ]:
                if q > 0:
                    lines.append(f"    {label} → {q}")
        return "\n".join(lines)

    def _make_whatsapp_url(text):
        return f"https://wa.me/?text={urllib.parse.quote(text)}"

    async def share_slip(_):
        # TODO: Fix WhatsApp Sharing for 0.28.3
        # try:
        #     import pdf_generator
        #     from pathlib import Path
        #     import db
        #
        #     # Generate the PDF
        #     out_path = Path(db.IMAGES_FOLDER).parent / f"slip_{order_id}.pdf"
        #     pdf_generator.create_slip_pdf(order, line_items, str(out_path))
        #
        #     snack("PDF generated! Opening share menu...", ft.Colors.BLUE_700)
        #     await share_ctrl.share_files([ft.ShareFile(str(out_path))])
        #
        # except Exception as e:
        #     snack(f"Failed to share: {str(e)}", ft.Colors.RED_700)
        snack("Sharing disabled temporarily for migration.", ft.Colors.ORANGE_700)

    action_buttons = ft.Row(
        [
            ft.OutlinedButton(
                "← Back",
                icon=ft.Icons.ARROW_BACK,
                on_click=lambda _: go("order_detail"),
            ),
            ft.FilledButton(
                "📤 Share PDF",
                icon=ft.Icons.SHARE,
                on_click=share_slip,
            ),
        ],
        alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
        wrap=True,
    )

    controls = [header_card, meta_grid]
    if extra_block:
        controls.append(extra_block)
    controls.append(ft.Text("आइटम विवरण / Items", size=16, weight="bold"))
    controls.extend(item_blocks)
    controls.append(action_buttons)
    controls.append(ft.Container(height=20))

    return ft.Container(
        padding=16, expand=True,
        content=ft.Column(controls, spacing=12, scroll=ft.ScrollMode.AUTO, expand=True),
    )

# ============================================================
# SETTINGS VIEW (admin only)
# ============================================================






