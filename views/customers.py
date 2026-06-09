import flet as ft
import db

def view_manage_customers(page: ft.Page):
    state = page.state
    go = page.go
    snack = page.snack

    search_tf = ft.TextField(
        hint_text="Search by shop name, owner, or mobile...",
        prefix_icon=ft.Icons.SEARCH,
        border_radius=20,
        height=48,
        expand=True,
        on_change=lambda _: refresh_list(search_tf.value.strip()),
    )

    customer_list = ft.ListView(expand=True, spacing=8, padding=10)

    def refresh_list(query: str = ""):
        try:
            all_customers = db.get_customers()
        except Exception:
            all_customers = []
        q = query.lower()
        if q:
            all_customers = [c for c in all_customers if
                q in c.get("shop_name", "").lower() or
                q in c.get("owner_name", "").lower() or
                q in c.get("mobile", "").lower()]
        cards = []
        for c in all_customers:
            cid = c["id"]
            is_active = c.get("is_active", True)
            pin = c.get("pin", "????")
            last_active = c.get("last_active_at", "")
            if last_active:
                try:
                    from datetime import datetime
                    dt = datetime.fromisoformat(last_active.replace("Z", "+00:00"))
                    last_active_str = dt.strftime("%d-%b %H:%M")
                except Exception:
                    last_active_str = last_active[:10] if last_active else "Never"
            else:
                last_active_str = "Never"

            status_color = ft.Colors.GREEN_700 if is_active else ft.Colors.RED_600
            status_label = "Active" if is_active else "Blocked"

            pin_row = ft.Row(spacing=4, controls=[
                ft.Text(pin, size=16, weight="bold", font_family="monospace"),
                ft.IconButton(ft.Icons.COPY, icon_size=16, tooltip="Copy PIN",
                    on_click=lambda _, p=pin: page.set_clipboard(p) or snack("📋 PIN copied!"),
                ),
            ])

            def make_block_handler(cid, currently_active):
                def _h(_):
                    db.set_customer_active(cid, not currently_active)
                    snack(f"{'🔓 Unblocked' if not currently_active else '🔒 Blocked'} customer")
                    refresh_list(search_tf.value.strip())
                    page.update()
                return _h

            def make_edit_handler(c):
                def _h(_):
                    open_edit_dialog(c)
                return _h

            cards.append(
                ft.Card(
                    elevation=2,
                    content=ft.Container(
                        padding=12,
                        content=ft.Column(spacing=6, controls=[
                            ft.Row([
                                ft.Text(c.get("shop_name", "?"), size=16, weight="bold", expand=True),
                                ft.Container(
                                    padding=ft.Padding(left=6, right=6, top=2, bottom=2),
                                    bgcolor=status_color,
                                    border_radius=4,
                                    content=ft.Text(status_label, size=10, color=ft.Colors.WHITE, weight="bold"),
                                ),
                            ]),
                            ft.Text(f"{c.get('owner_name', '')}  |  {c.get('mobile', '')}", size=12, color=ft.Colors.GREY_700),
                            ft.Row(spacing=12, controls=[
                                ft.Text("PIN:", size=11, color=ft.Colors.GREY_600),
                                pin_row,
                            ]),
                            ft.Row(spacing=8, controls=[
                                ft.Text(f"Last login: {last_active_str}", size=11, color=ft.Colors.GREY_500),
                            ]),
                            ft.Row(spacing=4, controls=[
                                ft.TextButton("✏️ Edit", on_click=make_edit_handler(c)),
                                ft.TextButton("🔒 Block" if is_active else "🔓 Unblock",
                                    on_click=make_block_handler(cid, is_active),
                                    style=ft.ButtonStyle(color=ft.Colors.RED_600 if is_active else ft.Colors.GREEN_700)),
                            ]),
                        ]),
                    ),
                )
            )
        customer_list.controls = cards
        page.update()

    def open_add_dialog(_):
        name_tf = ft.TextField(label="Shop Name *", autofocus=True)
        owner_tf = ft.TextField(label="Owner Name")
        mobile_tf = ft.TextField(label="Mobile", keyboard_type=ft.KeyboardType.PHONE)
        city_tf = ft.TextField(label="City")
        notes_tf = ft.TextField(label="Notes", multiline=True, min_lines=2, max_lines=4)

        def on_save(_):
            if not name_tf.value.strip():
                snack("Shop Name is required", ft.Colors.RED_400)
                return
            try:
                result = db.create_customer(
                    shop_name=name_tf.value.strip(),
                    owner_name=owner_tf.value.strip(),
                    mobile=mobile_tf.value.strip(),
                    city=city_tf.value.strip(),
                    notes=notes_tf.value.strip(),
                )
                if result:
                    pin = result.get("pin", "????")
                    dlg.open = False
                    page.update()
                    show_pin_dialog(name_tf.value.strip(), pin)
                    refresh_list()
                else:
                    snack("Failed to create customer", ft.Colors.RED_400)
            except Exception as e:
                snack(f"Error: {e}", ft.Colors.RED_400)

        dlg = ft.AlertDialog(
            modal=True,
            title=ft.Text("Add Customer"),
            content=ft.Column(width=300, spacing=10, controls=[
                name_tf, owner_tf, mobile_tf, city_tf, notes_tf,
            ], scroll=ft.ScrollMode.AUTO),
            actions=[
                ft.TextButton("Cancel", on_click=lambda _: close_dialog()),
                ft.FilledButton("Save", on_click=on_save),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        page.overlay.append(dlg)
        dlg.open = True
        page.update()

        def close_dialog():
            dlg.open = False
            page.update()

    def open_edit_dialog(c):
        name_tf = ft.TextField(label="Shop Name *", value=c.get("shop_name", ""), autofocus=True)
        owner_tf = ft.TextField(label="Owner Name", value=c.get("owner_name", ""))
        mobile_tf = ft.TextField(label="Mobile", value=c.get("mobile", ""), keyboard_type=ft.KeyboardType.PHONE)
        city_tf = ft.TextField(label="City", value=c.get("city", ""))
        notes_tf = ft.TextField(label="Notes", value=c.get("notes", ""), multiline=True, min_lines=2, max_lines=4)

        def on_save(_):
            if not name_tf.value.strip():
                snack("Shop Name is required", ft.Colors.RED_400)
                return
            try:
                db.update_customer(c["id"], {
                    "shop_name": name_tf.value.strip(),
                    "owner_name": owner_tf.value.strip(),
                    "mobile": mobile_tf.value.strip(),
                    "city": city_tf.value.strip(),
                    "notes": notes_tf.value.strip(),
                })
                dlg.open = False
                page.update()
                snack("✅ Customer updated")
                refresh_list()
            except Exception as e:
                snack(f"Error: {e}", ft.Colors.RED_400)

        dlg = ft.AlertDialog(
            modal=True,
            title=ft.Text("Edit Customer"),
            content=ft.Column(width=300, spacing=10, controls=[
                name_tf, owner_tf, mobile_tf, city_tf, notes_tf,
            ], scroll=ft.ScrollMode.AUTO),
            actions=[
                ft.TextButton("Cancel", on_click=lambda _: close_dialog()),
                ft.FilledButton("Save", on_click=on_save),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        page.overlay.append(dlg)
        dlg.open = True
        page.update()

        def close_dialog():
            dlg.open = False
            page.update()

    def show_pin_dialog(shop_name, pin):
        def close_dlg():
            dlg.open = False
            page.update()

        dlg = ft.AlertDialog(
            modal=True,
            title=ft.Text("🎉 Customer Created!"),
            content=ft.Column(width=280, spacing=10, controls=[
                ft.Text(f"Shop: {shop_name}", size=14, weight="bold"),
                ft.Divider(),
                ft.Text("Share this PIN with the customer:", size=12),
                ft.Container(
                    alignment=ft.alignment.center,
                    bgcolor=ft.Colors.INDIGO_50,
                    border_radius=8,
                    padding=12,
                    content=ft.Row([
                        ft.Text(pin, size=28, weight="bold", font_family="monospace", color=ft.Colors.INDIGO_700),
                        ft.IconButton(ft.Icons.COPY, icon_size=20, tooltip="Copy PIN",
                            on_click=lambda _: page.set_clipboard(pin) or snack("📋 PIN copied!"),
                        ),
                    ], alignment=ft.MainAxisAlignment.CENTER),
                ),
                ft.Text("Customer can log in with this 8-digit PIN.", size=11, color=ft.Colors.GREY_600),
            ]),
            actions=[ft.FilledButton("Done", on_click=lambda _: close_dlg())],
            actions_alignment=ft.MainAxisAlignment.CENTER,
        )
        page.overlay.append(dlg)
        dlg.open = True
        page.update()

    refresh_list()

    return ft.Column(expand=True, controls=[
        ft.Text("👥 Manage Customers", size=18, weight="bold"),
        ft.Container(height=8),
        ft.Row([search_tf, ft.IconButton(ft.Icons.ADD_CIRCLE, icon_color=ft.Colors.INDIGO_700, icon_size=32, tooltip="Add Customer", on_click=open_add_dialog)], spacing=8),
        ft.Divider(height=4),
        customer_list,
    ])
