import flet as ft
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
import session_helper
from utils import *

_CREAM = "#FFF8F0"
_GOLD = ft.Colors.AMBER_700
_MAROON = "#800020"
_DARK = ft.Colors.GREY_900
_MUTED = ft.Colors.GREY_600


def view_login(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout

    # ============================================================
    # Admin / Labour handlers
    # ============================================================
    def _admin_login(_):
        state["role"] = "admin"
        state["username"] = "admin"
        state["current_page"] = "home"
        session_helper.save_session(state)
        go("home")

    def _labour_login(_):
        state["role"] = "labour"
        state["username"] = "labour"
        state["current_page"] = "home"
        session_helper.save_session(state)
        go("home")

    # ============================================================
    # Customer PIN login
    # ============================================================
    pin_input = ft.TextField(
        label="Enter 8-digit PIN",
        hint_text="PIN provided by shop",
        width=280,
        autofocus=True,
        keyboard_type=ft.KeyboardType.NUMBER,
        max_length=8,
        prefix_icon=ft.Icons.LOCK,
        text_align=ft.TextAlign.CENTER,
        border_radius=12,
        on_submit=lambda _: do_login(),
    )

    error_text = ft.Text("", color=ft.Colors.RED_600, size=13, visible=False)

    def do_login():
        pin = pin_input.value.strip()
        if len(pin) != 8 or not pin.isdigit():
            error_text.value = "Please enter a valid 8-digit PIN"
            error_text.visible = True
            page.update()
            return
        try:
            customer = db.get_customer_by_pin(pin)
        except Exception:
            error_text.value = "Unable to connect. Please check your internet connection and try again."
            error_text.visible = True
            page.update()
            return
        if not customer:
            error_text.value = "Invalid PIN. Please check and try again."
            error_text.visible = True
            page.update()
            return
        if not customer.get("is_active", True):
            error_text.value = "Your account is blocked. Please contact Mahalaxmi Bangles."
            error_text.visible = True
            page.update()
            return
        state["role"] = "customer"
        state["customer_id"] = customer["id"]
        state["customer_shop_name"] = customer.get("shop_name", "")
        state["username"] = customer.get("shop_name", "")
        state["customer_mobile"] = customer.get("mobile", "")
        state["customer_cart"] = []
        try:
            db.set_customer_last_active(customer["id"])
        except Exception:
            pass
        session_helper.save_session(state)
        go("customer_dashboard")

    # ============================================================
    # UI helpers
    # ============================================================
    def _gold_divider():
        return ft.Row(
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=8,
            controls=[
                ft.Container(height=1, width=50, bgcolor=_GOLD),
                ft.Text("✦", color=_GOLD, size=12),
                ft.Container(height=1, width=50, bgcolor=_GOLD),
            ],
        )

    def _contact_card(label, icon_name, url=None, coming_soon=False):
        def _open(_):
            if coming_soon:
                snack("Tutorial video coming soon")
                return
            if url:
                page.launch_url(url)
        return ft.Container(
            width=145,
            height=68,
            border_radius=12,
            border=ft.border.all(1, ft.Colors.with_opacity(0.15, _GOLD)),
            bgcolor=ft.Colors.WHITE,
            on_click=_open,
            content=ft.Column(
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=2,
                controls=[
                    ft.Icon(icon_name, color=_GOLD, size=22),
                    ft.Text(label, size=11, color=_DARK, weight="bold"),
                    ft.Text(
                        "Coming Soon" if coming_soon else "",
                        size=8, color=_MUTED,
                        visible=coming_soon,
                    ),
                ],
            ),
        )

    # ============================================================
    # Build page
    # ============================================================
    return ft.Container(
        expand=True,
        bgcolor=_CREAM,
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=0,
            controls=[
                # Top spacer
                ft.Container(height=24),

                # Watermark logo
                ft.Container(
                    height=140,
                    alignment=ft.alignment.center,
                    content=ft.Image(
                        src="assets/watermark.png",
                        height=140, width=140,
                        opacity=1.0,
                        fit=ft.ImageFit.CONTAIN,
                    ),
                ),
                ft.Container(height=6),

                # Firm name
                ft.Text(
                    "Mahalaxmi Bangles",
                    size=26, weight=ft.FontWeight.W_300,
                    color=_DARK,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=4),

                # Subtitle
                ft.Text(
                    "Wholesale Bridal Chuda Manufacturer",
                    size=12, color=_MUTED,
                    text_align=ft.TextAlign.CENTER,
                ),
                ft.Container(height=20),

                # Gold ornamental divider
                _gold_divider(),
                ft.Container(height=16),

                # GST row (single line, transparent)
                ft.Container(
                    padding=ft.padding.symmetric(horizontal=24, vertical=8),
                    border_radius=8,
                    border=ft.border.all(1, ft.Colors.with_opacity(0.12, _GOLD)),
                    content=ft.Row(
                        alignment=ft.MainAxisAlignment.CENTER,
                        spacing=6,
                        controls=[
                            ft.Text("GST", size=9, color=_MUTED),
                            ft.Text(
                                "08AHPPC2086C1ZI",
                                size=12, color=_DARK, weight="bold",
                                selectable=True,
                            ),
                        ],
                    ),
                ),
                ft.Container(height=24),

                # PIN input section
                ft.Text("Enter Customer PIN", size=15, weight="bold", color=_DARK),
                ft.Container(height=10),
                pin_input,
                error_text,
                ft.Container(height=12),

                # Continue button
                ft.Container(
                    width=200, height=44,
                    border_radius=22,
                    bgcolor=_MAROON,
                    on_click=lambda _: do_login(),
                    alignment=ft.alignment.center,
                    content=ft.Text(
                        "Continue", color=ft.Colors.WHITE,
                        size=15, weight="bold",
                    ),
                ),
                ft.Container(height=14),

                # Secure & Trusted
                ft.Row(
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=4,
                    controls=[
                        ft.Icon(ft.Icons.LOCK, size=12, color=ft.Colors.GREEN_700),
                        ft.Text("Secure & Trusted", size=11, color=_MUTED),
                    ],
                ),
                ft.Container(height=24),

                # Business address
                ft.Container(
                    width=280,
                    content=ft.Column(
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        spacing=1,
                        controls=[
                            ft.Text(
                                "I-10, Gate No 5, Bada Bazar",
                                size=11, color=_MUTED,
                                text_align=ft.TextAlign.CENTER,
                            ),
                            ft.Text(
                                "Sri Ganganagar, Rajasthan",
                                size=11, color=_MUTED,
                                text_align=ft.TextAlign.CENTER,
                            ),
                        ],
                    ),
                ),
                ft.Container(height=20),

                # Contact cards 2x2
                ft.Text("Connect With Us", size=13, weight="bold", color=_DARK),
                ft.Container(height=10),
                ft.Column(spacing=8, controls=[
                    ft.Row(
                        spacing=12,
                        alignment=ft.MainAxisAlignment.CENTER,
                        controls=[
                            _contact_card(
                                "Instagram", ft.Icons.CAMERA_ALT,
                                "https://www.instagram.com/mb_sgnr/",
                            ),
                            _contact_card(
                                "WhatsApp", ft.Icons.CHAT,
                                "https://api.whatsapp.com/send?phone=917976482969"
                                "&text=Hi%2C%20I%20need%20help%20with%20the%20"
                                "Customer%20Pin%20in%20the%20app.",
                            ),
                        ],
                    ),
                    ft.Row(
                        spacing=12,
                        alignment=ft.MainAxisAlignment.CENTER,
                        controls=[
                            _contact_card(
                                "Visit Showroom", ft.Icons.LOCATION_ON,
                                "https://maps.app.goo.gl/b6qLbcbSAfPvRZGB7",
                            ),
                            _contact_card(
                                "YouTube", ft.Icons.PLAY_CIRCLE,
                                coming_soon=True,
                            ),
                        ],
                    ),
                ]),
                ft.Container(height=24),

                # Heritage container
                ft.Container(
                    padding=16,
                    width=300,
                    border_radius=12,
                    bgcolor=ft.Colors.with_opacity(0.08, _GOLD),
                    border=ft.border.all(1, ft.Colors.with_opacity(0.2, _GOLD)),
                    content=ft.Column(
                        spacing=2,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Text(
                                "Serving the bangle industry with trust,",
                                size=12, color=_MUTED,
                                text_align=ft.TextAlign.CENTER,
                            ),
                            ft.Text(
                                "quality & tradition for more than 20 years.",
                                size=12, color=_MUTED,
                                text_align=ft.TextAlign.CENTER,
                            ),
                        ],
                    ),
                ),
                ft.Container(height=16),

                # Bottom ornamental divider
                _gold_divider(),
                ft.Container(height=16),

                # Admin / Labour login links
                ft.Row(
                    alignment=ft.MainAxisAlignment.CENTER,
                    spacing=4,
                    controls=[
                        ft.TextButton(
                            content=ft.Text("Admin Login", size=12, color=_MUTED),
                            on_click=_admin_login,
                        ),
                        ft.Text("|", size=12, color=ft.Colors.GREY_300),
                        ft.TextButton(
                            content=ft.Text("Labour Login", size=12, color=_MUTED),
                            on_click=_labour_login,
                        ),
                    ],
                ),
                ft.Container(height=40),
            ],
        ),
    )
