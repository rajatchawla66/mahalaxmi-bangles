import flet as ft
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
from utils import *

def view_add_item(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout

    picked_path = {"value": ""}
    editing_existing = {"flag": False}

    # ---- Image picking (callback-based for Flet 0.28.3) ----
    def on_pick_result(e: ft.FilePickerResultEvent):
        if not e.files:
            return
        src = e.files[0].path
        if not src:
            snack("No path on this platform.", ft.Colors.ORANGE_600)
            return
        ext = src.rsplit(".", 1)[-1].lower()
        tmp_path = os.path.join(db.IMAGES_FOLDER, f"_pending.{ext}")
        try:
            shutil.copy(src, tmp_path)
        except Exception as ex:
            snack(f"Image copy failed: {ex}", ft.Colors.RED_500)
            return
        picked_path["value"] = tmp_path
        preview_img.content = ft.Image(
            src=tmp_path, width=120, height=120,
            fit=ft.ImageFit.COVER, border_radius=8,
        )
        page.update()

    file_picker = ft.FilePicker(on_result=on_pick_result)
    page.overlay.append(file_picker)

    def pick_file(_):
        file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)

    def take_photo(_):
        file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)

    # ---- Form Controls ----
    mode_text = ft.Text("🆕 New item", color=ft.Colors.GREEN_600, size=13)
    item_tf = ft.TextField(label="Item Number *", hint_text="e.g., CH-786")

    category_dd = ft.Dropdown(
        label="Category *",
        options=[ft.dropdown.Option(c) for c in db.get_category_names(active_only=True)],
        value=None,
        expand=True,
    )
    _, _subs = _load_categories_from_db()
    _all_sub_options = []
    for subs_list in _subs.values():
        _all_sub_options.extend(subs_list)
    _all_sub_options = list(set(_all_sub_options)) or ["Patti", "Nihar", "Box", "Bhawari"]

    sub_category_dd = ft.Dropdown(
        label="Sub-Category *",
        options=[ft.dropdown.Option(sc) for sc in _all_sub_options],
        value=None,
        expand=True,
        visible=False,
    )

    def _on_category_select(_e):
        _, _dynamic_subs = _load_categories_from_db()
        selected_cat_name = category_dd.value
        if selected_cat_name and selected_cat_name in _dynamic_subs:
            sub_category_dd.options = [
                ft.dropdown.Option(sc) for sc in _dynamic_subs[selected_cat_name]
            ]
            sub_category_dd.visible = True
        else:
            sub_category_dd.visible = False
            sub_category_dd.value = None
        page.update()

    category_dd.on_change = _on_category_select

    availability_switch = ft.Switch(
        label="Available for orders", value=True, visible=False,
    )

    has_sizes_switch = ft.Switch(label="Has sizes (2.2–2.10)?", value=False)
    has_color_switch = ft.Switch(label="Has color?", value=False)

    def _on_availability_toggle(_e):
        item_no = (item_tf.value or "").strip()
        if item_no and editing_existing["flag"]:
            db.set_item_availability(item_no, availability_switch.value)
            snack(f"{'✅ Available' if availability_switch.value else '🚫 Unavailable'}: {item_no}")
            page.update()

    availability_switch.on_change = _on_availability_toggle

    preview_img = ft.Container(
        width=120, height=120,
        bgcolor=ft.Colors.GREY_200, border_radius=8,
        alignment=ft.alignment.center,
        content=ft.Text("No image", color=ft.Colors.GREY_600),
    )

    # ---- Item lookup on keystroke ----
    def on_item_lookup(_e):
        item_no = (item_tf.value or "").strip()
        if not item_no:
            mode_text.value = "🆕 New item"
            mode_text.color = ft.Colors.GREEN_600
            editing_existing["flag"] = False
            category_dd.value = None
            sub_category_dd.value = None
            sub_category_dd.visible = False
            availability_switch.visible = False
            availability_switch.value = True
            page.update()
            return
        existing = db.get_item_by_number(item_no)
        if existing:
            editing_existing["flag"] = True
            mode_text.value = "✏️ Editing existing item"
            mode_text.color = ft.Colors.BLUE_600
            category_dd.value = existing.get("category") or None
            _, _dynamic_subs = _load_categories_from_db()
            existing_cat = existing.get("category", "")
            if existing_cat in _dynamic_subs and _dynamic_subs[existing_cat]:
                sub_category_dd.options = [
                    ft.dropdown.Option(sc) for sc in _dynamic_subs[existing_cat]
                ]
                sub_category_dd.visible = True
                sub_category_dd.value = existing.get("sub_category") or None
            else:
                sub_category_dd.visible = False
                sub_category_dd.value = None
            availability_switch.visible = True
            availability_switch.value = bool(existing.get("is_available", 1))
            has_sizes_switch.value = bool(existing.get("has_sizes", 0))
            has_color_switch.value = bool(existing.get("has_color", 0))
            if _is_valid_image(existing.get("image_url", "")):
                preview_img.content = ft.Image(
                    src=existing["image_url"], width=120, height=120,
                    fit=ft.ImageFit.COVER, border_radius=8,
                )
            else:
                preview_img.content = ft.Text("No image", color=ft.Colors.GREY_600)
        else:
            editing_existing["flag"] = False
            mode_text.value = "🆕 New item"
            mode_text.color = ft.Colors.GREEN_600
            availability_switch.visible = False
            availability_switch.value = True
        page.update()

    item_tf.on_change = on_item_lookup

    # ---- Pre-fill from catalogue edit ----
    edit_item = state.get("edit_item")
    if edit_item:
        item_tf.value = edit_item.get("item_number", "")
        item_tf.read_only = True
        on_item_lookup(None)
        state.pop("edit_item", None)

    # ---- Save Item ---
    def on_save_and_generate(_):
        item_no = (item_tf.value or "").strip()
        if not item_no:
            snack("Enter an Item Number.", ft.Colors.RED_500)
            return

        selected_category = category_dd.value
        if not selected_category:
            snack("Category is required.", ft.Colors.RED_500)
            return

        selected_sub_category = None
        _, _dynamic_subs = _load_categories_from_db()
        if selected_category in _dynamic_subs and _dynamic_subs[selected_category]:
            selected_sub_category = sub_category_dd.value
            if not selected_sub_category:
                snack(f"Sub-category is required for {selected_category}.", ft.Colors.RED_500)
                return

        existing = db.get_item_by_number(item_no)
        sp_val = existing["selling_price"] if existing else 0.0
        cp_val = existing["cost_price"] if existing else 0.0

        final_image_url = ""
        src = picked_path.get("value", "")
        if src and os.path.exists(src):
            snack("Uploading image...", ft.Colors.BLUE_400)
            uploaded_url = db.upload_image(src, item_no)
            if uploaded_url:
                final_image_url = uploaded_url
            else:
                ext = src.rsplit(".", 1)[-1].lower()
                safe = item_no.replace("/", "_").replace("\\", "_")
                final_image_url = os.path.join(db.IMAGES_FOLDER, f"{safe}.{ext}")
                try:
                    shutil.move(src, final_image_url)
                except Exception:
                    shutil.copy(src, final_image_url)
            picked_path["value"] = ""
        elif existing and existing.get("image_url"):
            final_image_url = existing["image_url"]

        if existing:
            db.update_item_prices(item_no, cp_val, sp_val)
            db.update_item_image_and_card(item_no, final_image_url, "")
            db.update_item_category(item_no, selected_category, selected_sub_category)
            db.update_item_properties(item_no, has_sizes_switch.value, has_color_switch.value)
        else:
            db.add_rate_item(item_no, final_image_url, cp_val, sp_val,
                             category=selected_category,
                             sub_category=selected_sub_category,
                             has_sizes=has_sizes_switch.value,
                             has_color=has_color_switch.value)

        snack("✅ Item saved!")
        if "catalog_cache" in state:
            del state["catalog_cache"]

        # Reset all form fields for the next item
        item_tf.value = ""
        item_tf.read_only = False
        category_dd.value = None
        sub_category_dd.value = None
        sub_category_dd.visible = False
        preview_img.content = ft.Text("No image", color=ft.Colors.GREY_600)
        mode_text.value = "🆕 New item"
        mode_text.color = ft.Colors.GREEN_600
        editing_existing["flag"] = False
        availability_switch.visible = False
        availability_switch.value = True
        picked_path["value"] = ""

        page.update()

    return ft.Column(
        scroll=ft.ScrollMode.AUTO,
        spacing=10,
        controls=[
            ft.Card(elevation=3, content=ft.Container(padding=12, border_radius=10, content=ft.Column(
                spacing=10, controls=[
                    ft.Text("➕ Add / Edit Item", size=16, weight="bold"),
                    mode_text,
                    ft.Column(controls=[item_tf], spacing=10),
                    ft.Row(spacing=10, controls=[
                        category_dd,
                        sub_category_dd,
                    ]),
                    availability_switch,
                    ft.Row([has_sizes_switch, has_color_switch], spacing=16),
                    ft.Row(spacing=10, controls=[
                        preview_img,
                        ft.Column(width=120, spacing=8, controls=[
                            ft.OutlinedButton("📷 Camera", on_click=take_photo, width=120),
                            ft.OutlinedButton("🖼️ Gallery", on_click=pick_file, width=120),
                        ]),
                    ]),
                    ft.FilledButton(
                        "💾 Save Item", icon=ft.Icons.SAVE,
                        on_click=on_save_and_generate, height=48, width=300,
                    ),
                ],
            ))),
            ft.Container(height=24),
        ],
    )


def view_catalogue(page: ft.Page):
    state = page.state
    go = page.go
    snack = page.snack

    catalogue_list = ft.Column(spacing=10)

    def render_catalogue():
        cached_items = cache.get_cached_catalog()
        items = state.get("catalog_cache", cached_items)

        def fetch_latest_catalog():
            try:
                latest = db.get_all_items_with_cards(raise_errors=True)
                state["catalog_cache"] = latest
                import json
                import time
                cats = db.get_categories(active_only=False)
                catalog_data = {"items": latest, "categories": cats, "synced_at": time.time()}
                with open(cache._catalog_path(), "w", encoding="utf-8") as f:
                    json.dump(catalog_data, f, ensure_ascii=False)
                if state["current_page"] in ("rate_list", "catalogue"):
                    render_catalogue()
                    page.update()
            except Exception:
                pass

        if "catalog_cache" not in state:
            import threading
            threading.Thread(target=fetch_latest_catalog, daemon=True).start()
            state["catalog_cache"] = items

        if not items:
            catalogue_list.controls = [
                ft.Container(
                    ft.Text("No items yet.", color=ft.Colors.GREY_600), padding=12,
                )
            ]
            return

        cards = []
        for it in items:
            is_unavailable = not bool(it.get("is_available", 1))
            item_opacity = 0.5 if is_unavailable else 1.0

            if _is_valid_image(it.get("image_url", "")):
                img = ft.Image(src=it["image_url"], width=90, height=90,
                               fit=ft.ImageFit.COVER, border_radius=8,
                               opacity=item_opacity)
            else:
                img = ft.Container(width=90, height=90,
                                   bgcolor=ft.Colors.GREY_200, border_radius=8,
                                   alignment=ft.alignment.center,
                                   content=ft.Text("—", color=ft.Colors.GREY_500),
                                   opacity=item_opacity)
            margin = it["selling_price"] - it["cost_price"]
            badge_ctrls = [ft.Text(it["item_number"], size=14, weight="bold")]
            item_category = it.get("category", "Chuda")
            badge_ctrls.append(ft.Container(
                padding=ft.Padding(left=5, right=5, top=1, bottom=1),
                bgcolor=ft.Colors.BLUE_50, border_radius=4,
                content=ft.Text(item_category, size=10, color=ft.Colors.BLUE_700),
            ))
            if is_unavailable:
                badge_ctrls.append(ft.Container(
                    padding=ft.Padding(left=5, right=5, top=1, bottom=1),
                    bgcolor=ft.Colors.RED_50, border_radius=4,
                    content=ft.Text("Unavailable", size=10, color=ft.Colors.RED_700),
                ))

            def make_delete_handler(item_number):
                def _h(_):
                    def close_dlg(e):
                        dlg_modal.open = False
                        page.update()
                    def confirm_delete(e):
                        db.delete_item(item_number)
                        if "catalog_cache" in state:
                            state["catalog_cache"] = [x for x in state["catalog_cache"] if x["item_number"] != item_number]
                        dlg_modal.open = False
                        snack(f"✅ Item {item_number} deleted!")
                        render_catalogue()
                        page.update()
                    dlg_modal = ft.AlertDialog(
                        modal=True,
                        title=ft.Text("Confirm Delete"),
                        content=ft.Text(f"Are you sure you want to delete {item_number}?"),
                        actions=[
                            ft.TextButton("Cancel", on_click=close_dlg),
                            ft.TextButton("Delete", on_click=confirm_delete, style=ft.ButtonStyle(color=ft.Colors.RED)),
                        ],
                        actions_alignment=ft.MainAxisAlignment.END,
                    )
                    page.overlay.append(dlg_modal)
                    dlg_modal.open = True
                    page.update()
                    page.update()
                return _h

            def make_edit_handler(item_data):
                def _h(_):
                    state["edit_item"] = item_data
                    go("add_item")
                return _h

            def make_avail_handler(item_number, currently_available):
                def _h(_):
                    new_val = not currently_available
                    db.set_item_availability(item_number, new_val)
                    if "catalog_cache" in state:
                        for x in state["catalog_cache"]:
                            if x["item_number"] == item_number:
                                x["is_available"] = new_val
                                break
                    snack(f"{'✅ Visible' if new_val else '🚫 Hidden'}: {item_number}")
                    render_catalogue()
                    page.update()
                return _h

            cards.append(ft.Card(
                elevation=3,
                content=ft.Container(
                    padding=10, border_radius=10,
                    content=ft.Column(spacing=6, controls=[
                        ft.Row(spacing=8, controls=[
                            img,
                            ft.Column(width=180, spacing=3, controls=[
                                ft.Row(badge_ctrls, spacing=6, wrap=True, run_spacing=2),
                                ft.Text(f"CP: ₹{it['cost_price']:.0f}  •  SP: ₹{it['selling_price']:.0f}", size=12),
                                ft.Text(f"Margin: ₹{margin:.0f}", size=11, color=ft.Colors.GREY_700),
                            ]),
                        ]),
                        ft.Row([
                            ft.TextButton("✏️ Edit", on_click=make_edit_handler(it)),
                            ft.TextButton("Hide" if not is_unavailable else "Show", on_click=make_avail_handler(it["item_number"], not is_unavailable), style=ft.ButtonStyle(color=ft.Colors.ORANGE_600 if not is_unavailable else ft.Colors.GREEN_600)),
                            ft.IconButton(ft.Icons.DELETE, icon_color=ft.Colors.RED_500, on_click=make_delete_handler(it["item_number"])),
                        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    ]),
                ),
            ))
        catalogue_list.controls = cards

    render_catalogue()

    return ft.Column(
        expand=True,
        scroll=ft.ScrollMode.AUTO,
        spacing=10,
        controls=[
            ft.Text("📦 Product Catalogue", size=16, weight="bold"),
            catalogue_list,
            ft.Container(height=24),
        ],
    )

# ============================================================
# KARIGAR SLIP VIEW (mobile-printable, no customer / no prices)
# ============================================================


def view_costing(page: ft.Page):
    print("DEBUG: costing list opened")
    state = page.state
    go = page.go
    snack = page.snack

    all_items = db.get_all_items_costing_status() or []
    
    search_tf = ft.TextField(
        label="🔍 Search by item number or category",
        border_radius=12,
        prefix_icon=ft.Icons.SEARCH
    )
    
    item_count_text = ft.Text(f"{len(all_items)} items", color=ft.Colors.GREY_600, size=12)
    items_column = ft.Column(spacing=0)

    def open_item_costing(item):
        state["costing_item"] = item
        go("costing_detail")

    def build_list(items):
        controls = []
        for item in items:
            sp = item.get("selling_price")
            cp = item.get("cost_price")
            
            if sp and float(sp) > 0:
                badge_bg = ft.Colors.GREEN_50
                badge_content = ft.Text(f"✅ ₹{float(sp):,.0f}", color=ft.Colors.GREEN_700, size=12, weight="bold")
            elif cp and float(cp) > 0:
                badge_bg = ft.Colors.AMBER_50
                badge_content = ft.Text("⚠️ No SP", color=ft.Colors.AMBER_700, size=12)
            else:
                badge_bg = ft.Colors.RED_50
                badge_content = ft.Text("❌ Not costed", color=ft.Colors.RED_400, size=12)
            
            badge = ft.Container(
                bgcolor=badge_bg,
                border_radius=20,
                padding=ft.Padding(left=10, top=4, right=10, bottom=4),
                content=badge_content
            )
            
            img_path = item.get("image_url")
            if img_path and _is_valid_image(img_path):
                img_widget = ft.Image(src=img_path, width=56, height=56, fit="cover", border_radius=8)
            else:
                img_widget = ft.Container(
                    width=56, height=56, bgcolor=ft.Colors.GREY_200, border_radius=8,
                    content=ft.Text((item.get("item_number") or "  ")[:2], color=ft.Colors.GREY_500, size=16, weight="bold"),
                    alignment=ft.Alignment(0, 0)
                )
            
            row = ft.Container(
                padding=10,
                border=ft.Border(bottom=ft.border.BorderSide(1, ft.Colors.GREY_200)),
                bgcolor=ft.Colors.WHITE,
                ink=True,
                on_click=lambda e, i=item: open_item_costing(i),
                content=ft.Row(
                    spacing=12,
                    controls=[
                        img_widget,
                        ft.Column(
                            width=180,
                            spacing=2,
                            controls=[
                                ft.Text(item.get("item_number", ""), size=15, weight="bold"),
                                ft.Text(item.get("category", "") or "—", size=12, color=ft.Colors.GREY_600)
                            ]
                        ),
                        badge
                    ]
                )
            )
            controls.append(row)
        items_column.controls = controls

    def filter_costing_list(e):
        query = search_tf.value.strip().lower()
        filtered = [i for i in all_items if query in (i.get("item_number") or "").lower() or query in (i.get("category") or "").lower()]
        build_list(filtered)
        item_count_text.value = f"{len(filtered)} items"
        page.update()
        
    search_tf.on_change = filter_costing_list
    build_list(all_items)

    return ft.ListView(
        expand=True,
        padding=12,
        spacing=0,
        controls=[
            search_tf,
            item_count_text,
            items_column
        ]
    )

def view_costing_detail(page: ft.Page):
    state = page.state
    go_back = page.go_back
    snack = page.snack

    item = state.get("costing_item")
    if not item:
        go_back()
        return ft.Container()
        
    item_number = item.get("item_number", "")
    category = item.get("category", "")
    img_path = item.get("image_url")
    
    if img_path and _is_valid_image(img_path):
        item_photo = ft.Image(src=img_path, width=64, height=64, fit="cover", border_radius=8)
    else:
        item_photo = ft.Container(
            width=64, height=64, bgcolor=ft.Colors.GREY_200, border_radius=8,
            content=ft.Text(item_number[:2], color=ft.Colors.GREY_500, size=16, weight="bold"),
            alignment=ft.Alignment(0, 0)
        )

    material_master = db.get_all_materials_from_master() or []
    existing_materials = db.get_item_materials(item_number) or []
    default_margin = db.get_default_margin()
    stored_sp = {"value": float(item.get("selling_price") or 0.0)}
    total_cost_state = {"value": float(item.get("cost_price") or 0.0)}

    total_cost_text = ft.Text(f"Total Cost: ₹{total_cost_state['value']:,.2f}", size=16, weight="bold", color=ft.Colors.INDIGO_800)
    selling_price_text = ft.Text(f"₹{stored_sp['value']:,.0f}", size=26, weight="bold", color=ft.Colors.GREEN_800)
    material_rows = ft.Column(spacing=8)
    custom_margin_tf = ft.TextField(value=str(default_margin), width=90, keyboard_type=ft.KeyboardType.NUMBER)

    def recalculate_selling_price():
        margin = default_margin if switch.value else float(custom_margin_tf.value or 0)
        sp = total_cost_state["value"] * (1 + margin / 100)
        stored_sp["value"] = sp
        selling_price_text.value = f"₹{sp:,.0f}"
        page.update()

    def on_margin_switch(e):
        custom_margin_row.visible = not switch.value
        recalculate_selling_price()

    switch = ft.Switch(value=True, on_change=on_margin_switch)
    custom_margin_row = ft.Row(
        visible=False,
        controls=[
            ft.Text("Custom margin %:", size=14),
            custom_margin_tf
        ]
    )
    custom_margin_tf.on_change = lambda e: recalculate_selling_price()

    def recalculate_totals():
        total = 0.0
        for card in material_rows.controls:
            qty_tf = card.qty_tf
            rate_tf = card.rate_tf
            amt_text = card.amt_text
            try:
                qty = float(qty_tf.value or 0)
                rate = float(rate_tf.value or 0)
                amt = qty * rate
                amt_text.value = f"₹{amt:,.2f}"
                total += amt
            except Exception:
                pass
        total_cost_state["value"] = total
        total_cost_text.value = f"Total Cost: ₹{total:,.2f}"
        recalculate_selling_price()

    def create_material_row(m_name="", qty=0, rate=0, is_unlisted=False):
        amt = qty * rate

        qty_tf = ft.TextField(label="Qty", value=str(qty) if qty else "", keyboard_type=ft.KeyboardType.NUMBER, expand=True)
        rate_tf = ft.TextField(label="Rate", value=str(rate) if rate else "", keyboard_type=ft.KeyboardType.NUMBER, expand=True)
        amt_text = ft.Text(f"₹{amt:,.2f}", weight="bold", color=ft.Colors.INDIGO_700)

        qty_tf.on_change = lambda e: recalculate_totals()
        rate_tf.on_change = lambda e: recalculate_totals()

        def on_dd_select(e):
            sel = e.control.value
            for m in material_master:
                if m.get("name") == sel:
                    rate_tf.value = str(m.get("rate", 0))
                    recalculate_totals()
                    break

        if is_unlisted or (m_name and m_name not in [m.get("name") for m in material_master]):
            name_ctrl = ft.TextField(label="Material name", value=m_name, expand=True)
            name_ctrl.data = "unlisted"
        else:
            name_ctrl = ft.Dropdown(
                label="Material",
                value=m_name if m_name else None,
                options=[ft.dropdown.Option(m.get("name")) for m in material_master],
                on_change=on_dd_select,
                expand=True,
            )
            name_ctrl.data = "listed"

        def remove_row(e):
            try:
                material_rows.controls.remove(card)
                recalculate_totals()
                page.update()
            except ValueError:
                pass

        card = ft.Container(
            bgcolor=ft.Colors.GREY_50, border_radius=8, padding=12,
            content=ft.Column(spacing=8, controls=[
                ft.Row(spacing=8, controls=[
                    name_ctrl,
                    ft.IconButton(ft.Icons.DELETE_OUTLINE, icon_color=ft.Colors.RED_400, on_click=remove_row),
                ]),
                ft.Row(spacing=8, controls=[
                    qty_tf,
                    rate_tf,
                ]),
                ft.Row([
                    amt_text,
                ]),
            ]),
        )
        card.name_ctrl = name_ctrl
        card.qty_tf = qty_tf
        card.rate_tf = rate_tf
        card.amt_text = amt_text
        return card

    for m in existing_materials:
        material_rows.controls.append(create_material_row(m.get("material_name"), m.get("qty"), m.get("rate_per_unit")))

    def add_listed(_):
        material_rows.controls.append(create_material_row())
        page.update()

    def add_unlisted(_):
        material_rows.controls.append(create_material_row(is_unlisted=True))
        page.update()

    def save_costing(_):
        if not material_rows.controls:
            snack("❌ At least one material row must exist")
            return

        materials_list = []
        for card in material_rows.controls:
            name_ctrl = card.name_ctrl
            qty_tf = card.qty_tf
            rate_tf = card.rate_tf

            m_name = name_ctrl.value
            if not m_name or not m_name.strip():
                snack("❌ Material name cannot be empty")
                return

            try:
                qty = float(qty_tf.value or 0)
                if qty <= 0:
                    snack("❌ All material rows must have qty > 0")
                    return
                rate = float(rate_tf.value or 0)
            except ValueError:
                snack("❌ Invalid quantity or rate")
                return

            materials_list.append({
                "material_name": m_name,
                "qty": qty,
                "rate_per_unit": rate,
                "amount": qty * rate
            })

        cost_price = total_cost_state["value"]
        selling_price = stored_sp["value"]

        if db.save_item_materials(item_number, materials_list) and db.save_item_costing(item_number, cost_price, selling_price):
            if "catalog_cache" in state:
                del state["catalog_cache"]

            import cache
            try:
                import os
                c_path = cache._catalog_path()
                if os.path.exists(c_path):
                    os.remove(c_path)
            except Exception:
                pass

            snack(f"✅ Costing saved for {item_number}. SP: ₹{selling_price:,.0f}")
            go_back()
        else:
            snack("❌ Error saving costing")

    sp_preview = ft.Container(
        bgcolor=ft.Colors.GREEN_50, border_radius=10, padding=14,
        content=ft.Column([
            ft.Text("Calculated Selling Price", size=12, color=ft.Colors.GREY_600),
            selling_price_text
        ])
    )

    header_row = ft.Row([
        ft.Row([
            ft.IconButton(ft.Icons.ARROW_BACK, on_click=lambda _: go_back()),
            ft.Column([
                ft.Text(item_number, size=18, weight="bold"),
                ft.Text(category, size=13, color=ft.Colors.GREY_600)
            ], spacing=2)
        ], spacing=4),
        item_photo
    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)

    return ft.ListView(
        expand=True,
        padding=16,
        controls=[
            header_row,
            ft.Divider(),
            ft.Text("🧱 Materials Used", size=15, weight="bold"),
            material_rows,
            ft.OutlinedButton("➕ Add Material", icon=ft.Icons.ADD, on_click=add_listed),
            ft.TextButton("+ Add unlisted material", on_click=add_unlisted),
            total_cost_text,
            ft.Column([
                ft.Divider(),
                ft.Text("📊 Margin & Selling Price", size=15, weight="bold"),
                ft.Row([
                    ft.Text(f"Use default margin ({default_margin:.0f}%)?", size=14),
                    switch
                ]),
                custom_margin_row,
                sp_preview,
                ft.FilledButton("💾 Save Costing", icon=ft.Icons.SAVE, height=50, on_click=save_costing)
            ])
        ]
    )

