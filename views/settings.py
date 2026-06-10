import flet as ft
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
from utils import *

def view_settings(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    def _save_margin(e):
        try:
            # e.control.parent.controls[0] is the TextField
            margin_tf = e.control.parent.controls[0]
            val = float(margin_tf.value)
            if db.save_default_margin(val):
                snack("✅ Default margin saved.")
            else:
                snack("❌ Failed to save default margin.")
        except ValueError:
            snack("❌ Invalid margin value.")
        page.update()

    # --- Shared state for Material Master ---
    materials_list = ft.Column(spacing=5)
    new_mat_name = ft.TextField(label="Material Name *", expand=2, height=45)
    new_mat_rate = ft.TextField(label="Rate", expand=1, height=45, keyboard_type=ft.KeyboardType.NUMBER)

    def refresh_materials():
        mats = db.get_materials()
        materials_list.controls.clear()
        if not mats:
            materials_list.controls.append(ft.Text("No materials added yet.", color=ft.Colors.GREY_600))
        else:
            for m in mats:
                def make_delete(mid):
                    def _h(e):
                        db.delete_material(mid)
                        refresh_materials()
                        page.update()
                    return _h
                
                materials_list.controls.append(
                    ft.ListTile(
                        title=ft.Text(m["name"]),
                        subtitle=ft.Text(f"Rs. {m['rate']} / {m['unit']}"),
                        trailing=ft.IconButton(
                            ft.Icons.DELETE, 
                            icon_color=ft.Colors.RED_400, 
                            on_click=make_delete(m["id"])
                        )
                    )
                )

    def add_material(e):
        n = (new_mat_name.value or "").strip()
        r_str = (new_mat_rate.value or "").strip()
        if not n:
            snack("Enter material name.", ft.Colors.RED_500)
            return
        r = 0.0
        if r_str:
            try:
                r = float(r_str)
            except:
                snack("Invalid rate.", ft.Colors.RED_500)
                return
        db.add_material(n, r, "pcs")
        new_mat_name.value = ""
        new_mat_rate.value = ""
        refresh_materials()
        page.update()
        new_mat_name.focus()

    # --- Card 1: Catalogue & Categories ---
    catalogue_card = ft.Card(
        content=ft.Container(
            padding=20,
            content=ft.Column(
                spacing=10,
                controls=[
                    ft.Text("Catalogue & Categories", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Add, edit, activate/deactivate categories and cover images.", size=12, color=ft.Colors.GREY_600),
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.CATEGORY, color=ft.Colors.BLUE_600),
                        title=ft.Text("Manage Categories", weight=ft.FontWeight.W_500),
                        subtitle=ft.Text("Add, edit, or remove item categories"),
                        trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
                        on_click=lambda _: go("manage_categories")
                    ),
                ]
            )
        )
    )

    # --- Card 2: Materials & Pricing ---
    pricing_card = ft.Card(
        content=ft.Container(
            padding=20,
            content=ft.Column(
                spacing=10,
                controls=[
                    ft.Text("Materials & Pricing", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Manage costing defaults and raw material rates.", size=12, color=ft.Colors.GREY_600),
                    ft.Row([
                        ft.TextField(
                            label="Default Margin %",
                            keyboard_type=ft.KeyboardType.NUMBER,
                            value=str(db.get_default_margin()),
                            width=160,
                            hint_text="e.g. 30"
                        ),
                        ft.FilledButton(
                            "💾 Save Margin",
                            on_click=lambda e: _save_margin(e)
                        )
                    ]),
                    ft.Divider(height=20),
                    ft.Text("Material Master", size=16, weight=ft.FontWeight.W_600),
                    ft.Text("Set rates here. Used in Cost Calculator.", size=11, color=ft.Colors.GREY_600),
                    ft.Row([
                        new_mat_name,
                        new_mat_rate,
                        ft.IconButton(ft.Icons.ADD_CIRCLE, icon_color=ft.Colors.GREEN_600, on_click=add_material)
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    ft.Divider(height=20),
                    materials_list
                ]
            )
        )
    )

    # --- Card 3: Account ---
    account_card = ft.Card(
        content=ft.Container(
            padding=20,
            content=ft.Column(
                spacing=5,
                controls=[
                    ft.Text("Account", size=18, weight=ft.FontWeight.BOLD),
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.PEOPLE, color=ft.Colors.INDIGO_700),
                        title=ft.Text("Manage Customers", weight=ft.FontWeight.W_500),
                        subtitle=ft.Text("Add, edit, block customers and manage PINs"),
                        trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
                        on_click=lambda _: go("manage_customers")
                    ),
                    ft.Divider(height=1),
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.ARCHIVE, color=ft.Colors.AMBER_700),
                        title=ft.Text("Archive Orders", weight=ft.FontWeight.W_500),
                        subtitle=ft.Text("View completed and cancelled orders"),
                        trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
                        on_click=lambda _: go("orders_archive")
                    ),
                    ft.Divider(height=1),
                    ft.ListTile(
                        leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED_500),
                        title=ft.Text("Logout", color=ft.Colors.RED_500, weight=ft.FontWeight.W_500),
                        on_click=logout
                    ),
                ]
            )
        )
    )

    refresh_materials()

    return ft.ListView(
        expand=True,
        padding=20,
        spacing=20,
        controls=[
            catalogue_card,
            pricing_card,
            account_card,
        ]
    )

# MANAGE CATEGORIES VIEW (admin only)
# ============================================================

def view_manage_categories(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    categories = db.get_categories(active_only=False)
    picked_cover = {"path": ""}

    # Available icon and color options
    icon_options = ["CIRCLE", "NOTIFICATIONS", "INVENTORY_2",
                    "PANORAMA_FISH_EYE", "LOCAL_FLORIST", "CATEGORY",
                    "DIAMOND", "STAR", "FAVORITE", "SHOPPING_BAG"]
    color_options = ["INDIGO_400", "AMBER_600", "GREEN_600", "BLUE_600",
                     "PINK_400", "RED_400", "PURPLE_400", "TEAL_400",
                     "ORANGE_400", "CYAN_400", "GREY_400"]
    order_type_options = ["sizes", "quantity", "quantity_with_unit",
                          "quantity_with_notes"]

    # Cover image preview for "Add New"
    preview_img = ft.Container(
        width=120, height=120, bgcolor=ft.Colors.GREY_200,
        border_radius=8, alignment=ft.alignment.center,
        content=ft.Text("No cover image", size=10, color=ft.Colors.GREY_500),
    )

    # ---- File picker (callback-based for Flet 0.28.3) ----
    _picker_ctx = {}

    def _new_cover_picked(src):
        picked_cover["path"] = src
        preview_img.content = ft.Image(src=src, width=120, height=120, fit=ft.ImageFit.COVER, border_radius=8)
        preview_img.update()

    def _change_cover_picked(src, cid, cname):
        snack(f"Uploading cover for {cname}...", ft.Colors.BLUE_400)
        url = db.upload_category_image(src, cname)
        if url:
            ok = db.update_category_cover(cid, url)
            if ok:
                snack("✅ Cover image updated!")
                refresh_cat_list()
                page.update()
            else:
                snack("❌ Failed to update DB", ft.Colors.RED_500)
        else:
            snack("❌ Upload failed", ft.Colors.RED_500)

    def on_pick_result(e: ft.FilePickerResultEvent):
        if not e.files:
            return
        src = e.files[0].path
        cb = _picker_ctx.pop("callback", None)
        if cb:
            cb(src)

    file_picker = ft.FilePicker(on_result=on_pick_result)
    page.overlay.append(file_picker)

    def pick_cover_new(_):
        _picker_ctx["callback"] = lambda src: _new_cover_picked(src)
        file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)

    # --- Add new category form ---
    name_tf = ft.TextField(label="Category Name *", hint_text="e.g., Payal")
    icon_dd = ft.Dropdown(
        label="Icon",
        options=[ft.dropdown.Option(i) for i in icon_options],
        value="CATEGORY", expand=True,
    )
    color_dd = ft.Dropdown(
        label="Color",
        options=[ft.dropdown.Option(c) for c in color_options],
        value="GREY_400", expand=True,
    )
    desc_tf = ft.TextField(label="Description", hint_text="Short description")
    sub_cats_tf = ft.TextField(
        label="Sub-categories (comma separated)",
        hint_text="e.g., Type A, Type B",
    )
    order_type_dd = ft.Dropdown(
        label="Order Type",
        options=[ft.dropdown.Option(o) for o in order_type_options],
        value="quantity", expand=True,
    )

    cat_list_column = ft.Column(spacing=10)

    def refresh_cat_list():
        nonlocal categories
        categories = db.get_categories(active_only=False)
        # Also refresh the global config
        
        page.CATEGORY_COLORS, page.CATEGORY_ICONS, page.CATEGORY_DESCRIPTIONS = page._load_category_config()

        cards = []
        for cat in categories:
            is_active = bool(cat.get("is_active", 1))
            cat_color = page.CATEGORY_COLORS.get(cat["name"], ft.Colors.GREY_400)
            cover_url = cat.get("cover_image_url")

            def make_toggle_handler(cid, current_active):
                def _h(_):
                    db.toggle_category_active(cid, not current_active)
                    snack(f"{'Activated' if not current_active else 'Deactivated'}: {cat['name']}")
                    refresh_cat_list()
                    page.update()
                return _h

            def make_delete_handler(cid, cname):
                def _h(_):
                    ok = db.delete_category(cid)
                    if ok:
                        snack(f"Deleted: {cname}")
                    else:
                        snack(f"Cannot delete '{cname}' — items are using it.",
                              ft.Colors.RED_500)
                    refresh_cat_list()
                    page.update()
                return _h

            def make_change_cover_handler(cid, cname):
                def _h(_):
                    _picker_ctx["callback"] = lambda src: _change_cover_picked(src, cid, cname)
                    file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)
                return _h

            status_badge = ft.Container(
                padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                bgcolor=ft.Colors.GREEN_100 if is_active else ft.Colors.RED_100,
                border_radius=4,
                content=ft.Text(
                    "Active" if is_active else "Inactive",
                    size=10,
                    color=ft.Colors.GREEN_800 if is_active else ft.Colors.RED_800,
                ),
            )

            # Thumbnail
            thumb = ft.Container(
                width=56, height=56, border_radius=8, bgcolor=ft.Colors.GREY_100,
                alignment=ft.alignment.center,
                content=ft.Image(src=cover_url, fit=ft.ImageFit.COVER, border_radius=8) if cover_url else
                        ft.Icon(page.CATEGORY_ICONS.get(cat["name"], ft.Icons.CATEGORY), color=cat_color, size=24)
            )

            cards.append(ft.Card(
                elevation=2,
                content=ft.Container(
                    padding=12,
                    border=ft.Border(left=ft.BorderSide(4, cat_color)),
                    border_radius=8,
                    content=ft.Column(spacing=6, controls=[
                        ft.Row([
                            thumb,
                            ft.Column(expand=True, spacing=2, controls=[
                                ft.Text(cat["name"], size=15, weight="bold"),
                                ft.Text(cat.get("description", ""), size=11,
                                        color=ft.Colors.GREY_700),
                            ]),
                            status_badge,
                        ], spacing=10),
                        ft.Row([
                            ft.Text(f"Type: {cat.get('order_type', 'quantity')}",
                                    size=11, color=ft.Colors.GREY_600),
                            ft.Text(
                                f"Subs: {cat.get('sub_categories', '') or '—'}",
                                size=11, color=ft.Colors.GREY_600,
                            ),
                        ], spacing=12),
                        ft.Row([
                            ft.TextButton(
                                "Deactivate" if is_active else "Activate",
                                on_click=make_toggle_handler(cat["id"], is_active),
                            ),
                            ft.TextButton("🖼️ Cover", on_click=make_change_cover_handler(cat["id"], cat["name"])),
                            ft.TextButton(
                                "Delete",
                                on_click=make_delete_handler(cat["id"], cat["name"]),
                                style=ft.ButtonStyle(color=ft.Colors.RED_500),
                            ),
                        ], spacing=8),
                    ]),
                ),
            ))
        cat_list_column.controls = cards

    async def add_new_category(_):
        name = (name_tf.value or "").strip()
        if not name:
            snack("Category name is required.", ft.Colors.RED_500)
            return
        
        cover_url = None
        if picked_cover["path"]:
            snack(f"Uploading cover for {name}...", ft.Colors.BLUE_400)
            cover_url = db.upload_category_image(picked_cover["path"], name)

        ok = db.add_category(
            name=name,
            icon=icon_dd.value or "CATEGORY",
            color=color_dd.value or "GREY_400",
            description=(desc_tf.value or "").strip(),
            sub_categories=(sub_cats_tf.value or "").strip(),
            order_type=order_type_dd.value or "quantity",
            cover_image_url=cover_url
        )
        if ok:
            name_tf.value = ""
            desc_tf.value = ""
            sub_cats_tf.value = ""
            preview_img.content = ft.Text("No cover image", size=10, color=ft.Colors.GREY_500)
            picked_cover["path"] = ""
            snack(f"✅ Category '{name}' added!")
            refresh_cat_list()
            page.update()
        else:
            snack(f"Category '{name}' already exists.", ft.Colors.RED_500)

    refresh_cat_list()

    add_card = ft.Card(
        elevation=3,
        content=ft.Container(
            padding=12, border_radius=10,
            content=ft.Column(spacing=10, controls=[
                ft.Text("➕ Add New Category", size=16, weight="bold"),
                ft.Row([
                    preview_img,
                    ft.Column([
                        ft.ElevatedButton("📷 Cover", icon=ft.Icons.IMAGE, on_click=pick_cover_new),
                        ft.Text("Recommended: 4:3 ratio", size=10, color=ft.Colors.GREY_600),
                    ], spacing=5)
                ], spacing=15),
                name_tf,
                ft.Row(spacing=10, controls=[
                    icon_dd,
                    color_dd,
                ]),
                desc_tf,
                sub_cats_tf,
                order_type_dd,
                ft.FilledButton(
                    "💾 Add Category", icon=ft.Icons.ADD,
                    on_click=add_new_category, height=44, expand=True,
                ),
            ]),
        ),
    )

    body = ft.ListView(
        expand=True, spacing=12, padding=12,
        controls=[
            add_card,
            ft.Text("📂 All Categories", size=16, weight="bold"),
            cat_list_column,
            ft.Container(height=24),
        ],
    )
    return body

# ============================================================
# COSTING VIEW — Cost Calculator
# ============================================================

def view_sync_page(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    status_text = ft.Text("", size=13, color=ft.Colors.GREY_700)
    progress_bar = ft.ProgressBar(value=0, visible=False)
    progress_label = ft.Text("", size=12, color=ft.Colors.GREY_600)
    last_sync_text = ft.Text(
        f"Last synced: {cache.get_last_sync_time()}",
        size=13, color=ft.Colors.GREY_600,
    )
    result_column = ft.Column(spacing=6)

    def do_sync(_):
        progress_bar.visible = True
        progress_bar.value = 0
        status_text.value = "Starting sync..."
        result_column.controls = []
        page.update()

        def on_progress(current, total, msg):
            progress_bar.value = current / max(total, 1)
            progress_label.value = msg
            page.update()

        result = cache.sync_all(on_progress=on_progress)

        progress_bar.visible = False
        progress_label.value = ""
        last_sync_text.value = f"Last synced: {cache.get_last_sync_time()}"

        result_column.controls = [
            ft.Text(f"✅ {result['items_synced']} items synced", color=ft.Colors.GREEN_700),
            ft.Text(f"✅ {result['orders_synced']} orders synced", color=ft.Colors.GREEN_700),
            ft.Text(f"✅ {result['images_synced']} images downloaded", color=ft.Colors.GREEN_700),
        ]
        if result["errors"]:
            result_column.controls.append(
                ft.Text(f"⚠️ {len(result['errors'])} errors", color=ft.Colors.ORANGE_600)
            )
            for err in result["errors"][:5]:
                result_column.controls.append(
                    ft.Text(f"  • {err}", size=11, color=ft.Colors.GREY_600)
                )

        status_text.value = "Sync complete!"
        snack("✅ Offline sync complete!")
        page.update()

    return ft.Container(
        expand=True,
        padding=20,
        content=ft.Column(
            spacing=16,
            scroll=ft.ScrollMode.AUTO,
            expand=True,
            controls=[
                ft.Icon(ft.Icons.CLOUD_DOWNLOAD, size=48, color=ft.Colors.INDIGO_400),
                ft.Text("Offline Sync", size=22, weight="bold"),
                ft.Text(
                    "Download catalog and orders for offline use.\n"
                    "Images are compressed for faster download.",
                    size=13, color=ft.Colors.GREY_600,
                ),
                last_sync_text,
                ft.Container(height=8),
                ft.FilledButton(
                    "🔄 Sync Now",
                    icon=ft.Icons.SYNC,
                    on_click=do_sync,
                    height=48,
                    width=250,
                ),
                progress_bar,
                progress_label,
                status_text,
                result_column,
            ],
        ),
    )

# ============================================================
# Top-level render dispatcher
# ============================================================




