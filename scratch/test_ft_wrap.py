import flet as ft

print("=== Flet Wrap Availability Test ===")
print(f"hasattr(ft, 'Wrap'): {hasattr(ft, 'Wrap')}")

# Try to instantiate ft.Wrap
try:
    w = ft.Wrap(spacing=6, run_spacing=2, controls=[ft.Text("test")])
    print("ft.Wrap(...) succeeded")
except AttributeError as e:
    print(f"ft.Wrap(...) failed: {e}")

# Check ft.Row(wrap=True)
try:
    r = ft.Row(controls=[ft.Text("test")], wrap=True, spacing=6, run_spacing=6)
    print("ft.Row(wrap=True, ...) succeeded")
    print(f"  type: {type(r)}")
except Exception as e:
    print(f"ft.Row(wrap=True, ...) failed: {e}")

# List all Wrap-related names
wrap_names = [x for x in dir(ft) if 'wrap' in x.lower()]
print(f"\nWrap-related names in ft: {wrap_names}")

# Check for ResponsiveRow (also known problematic)
print(f"\nhasattr(ft, 'ResponsiveRow'): {hasattr(ft, 'ResponsiveRow')}")

print("\n=== Test Complete ===")
