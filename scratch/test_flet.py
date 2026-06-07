import flet as ft

def main(page: ft.Page):
    def logout(e=None):
        print("Logout called!")
        page.controls.clear()
        page.appbar = None
        page.add(ft.Text("Logged out!"))
        page.update()

    def build_appbar():
        return ft.AppBar(
            title=ft.Text("Home"),
            actions=[
                ft.PopupMenuButton(
                    items=[
                        ft.PopupMenuItem(text="Logout", on_click=logout)
                    ]
                )
            ]
        )

    page.appbar = build_appbar()
    page.add(ft.Text("Home Screen"))

ft.app(target=main)
