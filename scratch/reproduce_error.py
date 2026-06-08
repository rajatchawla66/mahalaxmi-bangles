"""Minimal reproduction of the Admin Items tab error."""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import flet as ft

print("1. ft.Wrap exists?", hasattr(ft, "Wrap"))

# Simulate what pricing.py:551 does
badge_ctrls = [
    ft.Text("CH-001", size=14, weight="bold"),
    ft.Container(padding=ft.Padding(5,1,5,1), bgcolor=ft.Colors.BLUE_50,
                 border_radius=4, content=ft.Text("Chuda", size=10)),
]
print("2. badge_ctrls created OK")

try:
    wrap = ft.Wrap(spacing=6, run_spacing=2, controls=badge_ctrls)
    print("3. ft.Wrap created OK")
except AttributeError as e:
    print(f"3. ft.Wrap FAILED: {e}")

try:
    row = ft.Row(controls=badge_ctrls, wrap=True, spacing=6, run_spacing=2)
    print("4. ft.Row(wrap=True) created OK")
except Exception as e:
    print(f"4. ft.Row(wrap=True) FAILED: {e}")

print("\nDone.")
