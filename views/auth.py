import flet as ft
import db
import os
import urllib.parse
import shutil
from pathlib import Path
import cache
import session_helper
from utils import *

def view_login(page: ft.Page):
    state = page.state
    go = page.go
    go_back = page.go_back
    snack = page.snack
    logout = page.logout
    # End context injection

    def pick_role(role):
        def _h(_):
            state["role"] = role
            if role == "customer":
                state["current_page"] = "customer_name_entry"
            else:
                state["username"] = role
                state["current_page"] = "home"
                session_helper.save_session(state)
            go(state["current_page"])
        return _h

    return ft.Container(
        expand=True,
        alignment=ft.alignment.center,
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=20,
            controls=[
                ft.Text(
                    "Mahalaxmi Bangles",
                    size=30, weight="bold",
                    color=ft.Colors.INDIGO_700,
                ),
                ft.Text("💍 Wholesale Order Management", size=14, color=ft.Colors.GREY_600),
                ft.Container(height=16),
                ft.Text("Select Dashboard", size=16, color=ft.Colors.GREY_800),
                ft.FilledButton(
                    "👑 Admin Dashboard",
                    on_click=pick_role("admin"),
                    width=280, height=48,
                ),
                ft.OutlinedButton(
                    "🔨 Labour Dashboard",
                    on_click=pick_role("labour"),
                    width=280, height=48,
                ),
                ft.OutlinedButton(
                    "🛍️ Customer Dashboard",
                    on_click=pick_role("customer"),
                    width=280, height=48,
                ),
            ],
        ),
    )

# ============================================================
# APP BAR
# ============================================================



