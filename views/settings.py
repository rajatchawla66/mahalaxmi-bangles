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

    items = ft.Column(spacing=2, controls=[
        ft.ListTile(
            leading=ft.Icon(ft.Icons.CATEGORY, color=ft.Colors.BLUE_600),
            title=ft.Text("Manage Categories", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("Add, edit, or remove item categories"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("manage_categories"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.PERCENT, color=ft.Colors.GREEN_700),
            title=ft.Text("Margin", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("Set default pricing margin percentage"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("settings_margin"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.INVENTORY_2, color=ft.Colors.ORANGE_700),
            title=ft.Text("Material Master", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("Manage raw material rates for costing"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("settings_materials"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.LABEL, color=ft.Colors.PURPLE_700),
            title=ft.Text("Tag Master", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("Manage product filter tags"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("tag_master"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.PEOPLE, color=ft.Colors.INDIGO_700),
            title=ft.Text("Manage Customers", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("Add, edit, block customers and manage PINs"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("manage_customers"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.ARCHIVE, color=ft.Colors.AMBER_700),
            title=ft.Text("Archive Orders", weight=ft.FontWeight.W_500),
            subtitle=ft.Text("View completed and cancelled orders"),
            trailing=ft.Icon(ft.Icons.CHEVRON_RIGHT),
            on_click=lambda _: go("orders_archive"),
        ),
        ft.Divider(height=1),
        ft.ListTile(
            leading=ft.Icon(ft.Icons.LOGOUT, color=ft.Colors.RED_500),
            title=ft.Text("Logout", color=ft.Colors.RED_500, weight=ft.FontWeight.W_500),
            on_click=logout,
        ),
    ])

    return ft.ListView(
        expand=True,
        padding=20,
        spacing=20,
        controls=[
            ft.Container(
                border_radius=8, bgcolor=ft.Colors.WHITE,
                border=ft.border.all(1, ft.Colors.GREY_200),
                shadow=ft.BoxShadow(spread_radius=0, blur_radius=4, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK), offset=ft.Offset(0, 2)),
                padding=ft.Padding(left=0, top=8, right=0, bottom=8),
                content=items,
            ),
        ]
    )

# MANAGE CATEGORIES VIEW (admin only)
# ============================================================

def view_settings_margin(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    margin_tf = ft.TextField(
        label="Default Margin %",
        keyboard_type=ft.KeyboardType.NUMBER,
        value=str(db.get_default_margin()),
        hint_text="e.g. 30",
    )

    def save_margin(_):
        try:
            val = float(margin_tf.value)
            if db.save_default_margin(val):
                snack("✅ Default margin saved.")
            else:
                snack("❌ Failed to save default margin.")
        except ValueError:
            snack("❌ Invalid margin value.")
        page.update()

    return ft.ListView(
        expand=True,
        padding=20,
        spacing=20,
        controls=[
            ft.Container(
                padding=20, border_radius=8, bgcolor=ft.Colors.WHITE,
                border=ft.border.all(1, ft.Colors.GREY_200),
                shadow=ft.BoxShadow(spread_radius=0, blur_radius=4, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK), offset=ft.Offset(0, 2)),
                content=ft.Column(spacing=16, controls=[
                    ft.Text("Default Margin %", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Set the default profit margin used in cost calculations.", size=12, color=ft.Colors.GREY_600),
                    margin_tf,
                    ft.FilledButton("💾 Save Margin", on_click=save_margin, height=44),
                ]),
            ),
        ],
    )


def view_settings_materials(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    new_mat_name = ft.TextField(label="Material Name *", expand=2, height=45)
    new_mat_rate = ft.TextField(label="Rate", expand=1, height=45, keyboard_type=ft.KeyboardType.NUMBER)
    materials_list = ft.Column(spacing=5)

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
                            on_click=make_delete(m["id"]),
                        ),
                    )
                )

    def add_material(_):
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

    refresh_materials()

    return ft.ListView(
        expand=True,
        padding=20,
        spacing=20,
        controls=[
            ft.Container(
                padding=20, border_radius=8, bgcolor=ft.Colors.WHITE,
                border=ft.border.all(1, ft.Colors.GREY_200),
                shadow=ft.BoxShadow(spread_radius=0, blur_radius=4, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK), offset=ft.Offset(0, 2)),
                content=ft.Column(spacing=12, controls=[
                    ft.Text("Material Master", size=18, weight=ft.FontWeight.BOLD),
                    ft.Text("Set raw material rates used in the Cost Calculator.", size=12, color=ft.Colors.GREY_600),
                    ft.Row([
                        new_mat_name,
                        new_mat_rate,
                        ft.IconButton(ft.Icons.ADD_CIRCLE, icon_color=ft.Colors.GREEN_600, on_click=add_material),
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    ft.Divider(height=1),
                    materials_list,
                ]),
            ),
        ],
    )


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

    # ---- Singleton FilePicker (reused across visits) ----
    if not hasattr(page, "_category_file_picker"):
        def _on_pick_result(e: ft.FilePickerResultEvent):
            if not e.files:
                return
            src = e.files[0].path
            ctx = getattr(page, "_category_picker_context", None)
            if ctx:
                cb = ctx.pop("callback", None)
                if cb:
                    cb(src)

        page._category_file_picker = ft.FilePicker(on_result=_on_pick_result)
        page.overlay.append(page._category_file_picker)
        page._category_picker_context = {}

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

    def pick_cover_new(_):
        page._category_picker_context["callback"] = lambda src: _new_cover_picked(src)
        page._category_file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)

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
                    page._category_picker_context["callback"] = lambda src: _change_cover_picked(src, cid, cname)
                    page._category_file_picker.pick_files(file_type=ft.FilePickerFileType.IMAGE)
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

            cards.append(ft.Container(
                padding=12, border_radius=8, bgcolor=ft.Colors.WHITE,
                border=ft.Border(
                    left=ft.BorderSide(4, cat_color),
                    right=ft.BorderSide(1, ft.Colors.GREY_200),
                    top=ft.BorderSide(1, ft.Colors.GREY_200),
                    bottom=ft.BorderSide(1, ft.Colors.GREY_200),
                ),
                shadow=ft.BoxShadow(spread_radius=0, blur_radius=4, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK), offset=ft.Offset(0, 2)),
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

    add_card = ft.Container(
        padding=12, border_radius=10, bgcolor=ft.Colors.WHITE,
        border=ft.border.all(1, ft.Colors.GREY_200),
        shadow=ft.BoxShadow(spread_radius=0, blur_radius=4, color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK), offset=ft.Offset(0, 2)),
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
# TAG MASTER
# ============================================================


def view_tag_master(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout

    display_name_tf = ft.TextField(label="Tag Name", height=45,
                                    hint_text="e.g. Kundan")
    _selected_categories = []
    _all_cats = [c.get("name", "") for c in db.get_categories(active_only=True)]

    cats_title = ft.Text("Categories", size=12, color=ft.Colors.GREY_600)
    cats_row = ft.Row(wrap=True, spacing=6, run_spacing=4)

    def _rebuild_cats_chips():
        cats_row.controls.clear()
        is_global = len(_selected_categories) == 0
        cats_row.controls.append(ft.Container(
            content=ft.Text("Global", size=12, weight=ft.FontWeight.W_500,
                             color=ft.Colors.WHITE if is_global else ft.Colors.BLACK87),
            padding=ft.Padding(left=10, right=10, top=4, bottom=4),
            border_radius=16,
            bgcolor=ft.Colors.INDIGO_400 if is_global else ft.Colors.GREY_200,
            ink=True,
            on_click=lambda _: _select_global(),
        ))
        for c in _all_cats:
            sel = c in _selected_categories
            bg = ft.Colors.INDIGO_400 if sel else ft.Colors.GREY_200
            fg = ft.Colors.WHITE if sel else ft.Colors.BLACK87
            cats_row.controls.append(ft.Container(
                content=ft.Text(c, size=12, color=fg),
                padding=ft.Padding(left=10, right=10, top=4, bottom=4),
                border_radius=16,
                bgcolor=bg,
                ink=True,
                on_click=lambda e, cn=c: _toggle_cat_chip(cn),
            ))

    def _select_global():
        _selected_categories.clear()
        _rebuild_cats_chips()
        cats_row.update()

    def _toggle_cat_chip(cat_name):
        if cat_name in _selected_categories:
            _selected_categories.remove(cat_name)
        else:
            _selected_categories.append(cat_name)
        _rebuild_cats_chips()
        cats_row.update()

    _rebuild_cats_chips()

    tag_list = ft.Column(spacing=6)

    def refresh_tags():
        tags = db.get_tag_master(active_only=False)
        tag_list.controls.clear()
        if not tags:
            tag_list.controls.append(
                ft.Text("No tags created yet.", color=ft.Colors.GREY_600, italic=True)
            )
        else:
            for t in tags:
                tid = t["id"]
                tag_name = t["name"]
                display_name = t.get("display_name", tag_name)
                cats = t.get("categories", [])
                is_active = t.get("is_active", True)

                def make_toggle(tid_inner, current_active, tag_name, display_name, categories):
                    def _h(e):
                        new_active = not current_active
                        ok = db.update_tag(tid_inner, tag_name, display_name,
                                           is_active=new_active, categories=categories)
                        if not ok:
                            snack("❌ Failed to update tag status.", ft.Colors.RED_400)
                        else:
                            refresh_tags()
                        page.update()
                    return _h

                def make_edit(t_inner, tag_name, display_name, categories, is_active):
                    def _h(e):
                        edit_dn = ft.TextField(label="Display Name", value=display_name)
                        edit_cats = list(categories)
                        edit_all_cats = [c.get("name", "") for c in db.get_categories(active_only=True)]
                        edit_cats_title = ft.Text("Categories", size=12, color=ft.Colors.GREY_600)
                        edit_cats_row = ft.Row(wrap=True, spacing=6, run_spacing=4)

                        def _rebuild_edit_chips():
                            edit_cats_row.controls.clear()
                            is_global = len(edit_cats) == 0
                            edit_cats_row.controls.append(ft.Container(
                                content=ft.Text("Global", size=12, weight=ft.FontWeight.W_500,
                                                 color=ft.Colors.WHITE if is_global else ft.Colors.BLACK87),
                                padding=ft.Padding(left=10, right=10, top=4, bottom=4),
                                border_radius=16,
                                bgcolor=ft.Colors.INDIGO_400 if is_global else ft.Colors.GREY_200,
                                ink=True,
                                on_click=lambda _: (_set_global_edit(), _rebuild_edit_chips(), edit_cats_row.update()),
                            ))
                            for c in edit_all_cats:
                                sel = c in edit_cats
                                bg = ft.Colors.INDIGO_400 if sel else ft.Colors.GREY_200
                                fg = ft.Colors.WHITE if sel else ft.Colors.BLACK87
                                edit_cats_row.controls.append(ft.Container(
                                    content=ft.Text(c, size=12, color=fg),
                                    padding=ft.Padding(left=10, right=10, top=4, bottom=4),
                                    border_radius=16,
                                    bgcolor=bg,
                                    ink=True,
                                    on_click=lambda e, cn=c: (_toggle_edit_cat(cn), _rebuild_edit_chips(), edit_cats_row.update()),
                                ))

                        def _set_global_edit():
                            edit_cats.clear()

                        def _toggle_edit_cat(cat_name):
                            if cat_name in edit_cats:
                                edit_cats.remove(cat_name)
                            else:
                                edit_cats.append(cat_name)

                        _rebuild_edit_chips()

                        edit_active_dd = ft.Dropdown(
                            label="Status",
                            options=[
                                ft.dropdown.Option("true", "Active"),
                                ft.dropdown.Option("false", "Inactive"),
                            ],
                            value=str(is_active).lower(),
                        )

                        def do_update(_):
                            new_dn = (edit_dn.value or "").strip()
                            new_cats = list(edit_cats)
                            new_active = edit_active_dd.value == "true"
                            if not new_dn:
                                snack("Display name required.", ft.Colors.RED_400)
                                return
                            ok = db.update_tag(
                                t_inner, tag_name, new_dn,
                                is_active=new_active, categories=new_cats,
                            )
                            if not ok:
                                snack("❌ Failed to update tag.", ft.Colors.RED_400)
                            else:
                                dlg.open = False
                                refresh_tags()
                                page.update()
                                snack("✅ Tag updated.", ft.Colors.GREEN_700)

                        dlg = ft.AlertDialog(
                            title=ft.Text(f"Edit: {display_name}"),
                            content=ft.Column([
                                edit_dn,
                                edit_cats_title,
                                edit_cats_row,
                                edit_active_dd,
                            ], tight=True, spacing=10, width=280),
                            actions=[
                                ft.TextButton("Cancel", on_click=lambda _: close_dlg(dlg)),
                                ft.FilledButton("Save", on_click=do_update),
                            ],
                        )
                        page.overlay.append(dlg)
                        dlg.open = True
                        page.update()
                    return _h

                def make_delete(t_inner, display_name):
                    def _h(e):
                        def confirm(_):
                            dlg.open = False
                            ok = db.delete_tag(t_inner)
                            if not ok:
                                snack("❌ Tag is used by items and cannot be deleted.", ft.Colors.RED_400)
                            else:
                                refresh_tags()
                                page.update()
                                snack("✅ Tag deleted.", ft.Colors.GREEN_700)
                            page.update()
                        def cancel(_):
                            dlg.open = False
                            page.update()
                        dlg = ft.AlertDialog(
                            title=ft.Text(f"Delete '{display_name}'?"),
                            content=ft.Text("This action cannot be undone.", size=13),
                            actions=[
                                ft.TextButton("Cancel", on_click=cancel),
                                ft.FilledButton("Delete", on_click=confirm, color=ft.Colors.WHITE, bgcolor=ft.Colors.RED_600),
                            ],
                        )
                        page.overlay.append(dlg)
                        dlg.open = True
                        page.update()
                    return _h

                active_color = ft.Colors.GREEN_700 if is_active else ft.Colors.GREY_400
                active_label = "● Active" if is_active else "○ Inactive"

                info_col = ft.Column([
                    ft.Row([
                        ft.Text(display_name, size=15, weight=ft.FontWeight.W_600),
                        ft.Container(
                            content=ft.Text(active_label, size=11, color=active_color, weight=ft.FontWeight.W_500),
                            padding=ft.Padding(left=8, right=8, top=3, bottom=3),
                            border_radius=12,
                            bgcolor=ft.Colors.with_opacity(0.1, active_color),
                        ),
                    ], spacing=8, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                    ft.Text(tag_name, size=11, color=ft.Colors.GREY_500),
                ])
                if cats:
                    for c in cats:
                        info_col.controls.append(
                            ft.Container(
                                content=ft.Text(c, size=10, color=ft.Colors.WHITE),
                                bgcolor=ft.Colors.INDIGO_400,
                                padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                                border_radius=8,
                            )
                        )
                else:
                    info_col.controls.append(
                        ft.Container(
                            content=ft.Text("Global", size=10, color=ft.Colors.WHITE),
                            bgcolor=ft.Colors.TEAL_400,
                            padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                            border_radius=8,
                        )
                    )

                actions_row = ft.Row([
                    ft.TextButton("✏️ Edit", on_click=make_edit(tid, tag_name, display_name, cats, is_active)),
                    ft.TextButton("🗑️ Delete", on_click=make_delete(tid, display_name),
                                   style=ft.ButtonStyle(color=ft.Colors.RED_600)),
                ], spacing=4)

                tag_list.controls.append(
                    ft.Container(
                        padding=ft.Padding(left=14, right=10, top=10, bottom=10),
                        border_radius=10,
                        border=ft.border.all(1, ft.Colors.GREY_200),
                        bgcolor=ft.Colors.WHITE,
                        content=ft.Column([
                            ft.Row([
                                info_col,
                                ft.Container(
                                    content=ft.Text("●", size=14, color=active_color),
                                    on_click=make_toggle(tid, is_active, tag_name, display_name, cats),
                                ),
                            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                                vertical_alignment=ft.CrossAxisAlignment.START),
                            ft.Row([
                                actions_row,
                            ], alignment=ft.MainAxisAlignment.END),
                        ], spacing=4),
                    )
                )
        page.update()

    def add_tag(_):
        dn = (display_name_tf.value or "").strip()
        if not dn:
            snack("Enter a tag name.", ft.Colors.RED_500)
            return

        slug = dn.strip().lower().replace(" ", "_")
        existing_tags = db.get_tag_master(active_only=False)
        if any(t["name"] == slug for t in existing_tags):
            snack(f"❌ Tag '{dn}' already exists.", ft.Colors.RED_400)
            return

        ok = db.add_tag(dn, dn, categories=list(_selected_categories))
        if not ok:
            snack("❌ Failed to create tag. Check: (1) Run the SQL migration in Supabase. (2) Disable RLS on tag_master table: ALTER TABLE tag_master DISABLE ROW LEVEL SECURITY;", ft.Colors.RED_400)
        else:
            display_name_tf.value = ""
            _selected_categories.clear()
            _rebuild_cats_chips()
            refresh_tags()
            snack("✅ Tag added.", ft.Colors.GREEN_700)
        page.update()

    def close_dlg(dlg):
        dlg.open = False
        page.update()

    refresh_tags()

    return ft.Column(
        expand=True, spacing=0, scroll=ft.ScrollMode.AUTO,
        controls=[
            ft.Container(
                padding=ft.Padding(left=20, right=20, top=16, bottom=8),
                content=ft.Column([
                    ft.Text("🏷️ Tag Master", size=22, weight=ft.FontWeight.BOLD),
                    ft.Text("Manage product tags used for customer filtering.",
                            size=12, color=ft.Colors.GREY_600),
                ], spacing=4),
            ),
            ft.Container(
                padding=ft.Padding(left=20, right=20, top=8, bottom=8),
                content=ft.Column([
                    display_name_tf,
                    cats_title,
                    cats_row,
                    ft.Row([
                        ft.Container(height=1, expand=True),
                        ft.IconButton(ft.Icons.ADD_CIRCLE, icon_color=ft.Colors.GREEN_600,
                                       icon_size=32, on_click=add_tag),
                    ], spacing=8, vertical_alignment=ft.CrossAxisAlignment.CENTER),
                ], spacing=8),
            ),
            ft.Divider(height=1),
            ft.Container(
                padding=ft.Padding(left=20, right=20, top=8, bottom=8),
                expand=True,
                content=tag_list,
            ),
        ],
    )


# ============================================================
# Top-level render dispatcher
# ============================================================




