import os
import urllib.parse
import shutil
import flet as ft
from pathlib import Path
import db

__all__ = [
    'PACKING_OPTIONS',
    '_load_categories_from_db',
    '_safe_int',
    'validate_cart_item',
    'validate_order',
    'calculate_line_total',
    '_is_valid_image',
    '_safe_launch_url'
]

PACKING_OPTIONS = [
    "2 Pair", "3 Pair", "4 Pair", "1 Box", "1 Dozen", "Half Dozen",
    "1 Set", "1 Piece", "500g", "1Kg", "1 Pkt", "Custom"
]

def _load_categories_from_db():
    cats = db.get_categories(active_only=True)
    subs = {}
    for c in cats:
        cname = c["name"]
        sc_str = c.get("sub_categories", "")
        if sc_str:
            sc_list = [x.strip() for x in sc_str.split(",") if x.strip()]
            subs[cname] = sc_list
        else:
            subs[cname] = []
    return [c["name"] for c in cats], subs

def _safe_int(value) -> int:
    try:
        return int(float(value))
    except (ValueError, TypeError):
        return 0

def validate_cart_item(item: dict, category: str) -> str | None:
    if not item.get("item_number", "").strip():
        return "Item number is required."
    
    if item.get("_has_sizes") or category in ["Chuda", "Metal_Bangles"]:
        total_size_qty = sum([
            item.get("qty_2_2", 0),
            item.get("qty_2_4", 0),
            item.get("qty_2_6", 0),
            item.get("qty_2_8", 0),
            item.get("qty_2_10", 0)
        ])
        if total_size_qty <= 0:
            return "Select at least one size."
    else:
        try:
            q = float(item.get("quantity") or 0)
        except ValueError:
            q = 0
        if q <= 0:
            return "Quantity must be greater than 0."
    return None

def validate_order(cart: list, rate_lookup: dict) -> str | None:
    if not cart:
        return "Cart is empty."
    for ci in cart:
        if not ci.get("item_number", "").strip():
            return "An item in the cart has no item selected."
        
        if ci.get("_has_sizes") or ci.get("category") in ["Chuda", "Metal_Bangles"]:
            qty = sum([
                ci.get("qty_2_2", 0),
                ci.get("qty_2_4", 0),
                ci.get("qty_2_6", 0),
                ci.get("qty_2_8", 0),
                ci.get("qty_2_10", 0)
            ])
            if qty <= 0:
                return f"Select at least one size for {ci.get('item_number')}."
        else:
            try:
                q = float(ci.get("quantity") or 0)
            except ValueError:
                q = 0
            if q <= 0:
                return f"Enter a valid quantity for {ci.get('item_number')}."
    return None

def calculate_line_total(item: dict, category: str, unit_price: float) -> float:
    if item.get("_has_sizes") or category in ["Chuda", "Metal_Bangles"]:
        total_size_qty = sum([
            item.get("qty_2_2", 0),
            item.get("qty_2_4", 0),
            item.get("qty_2_6", 0),
            item.get("qty_2_8", 0),
            item.get("qty_2_10", 0)
        ])
        return float(unit_price * total_size_qty)
    else:
        try:
            base_qty = float(item.get("quantity") or 0)
        except ValueError:
            base_qty = 0
        return float(unit_price * base_qty)

def _is_valid_image(path: str) -> bool:
    if not path:
        return False
    if path.startswith("http://") or path.startswith("https://"):
        return True
    if not os.path.exists(path):
        return False
    return path.lower().endswith(('.png', '.jpg', '.jpeg', '.webp'))

def _safe_launch_url(page, url: str):
    import asyncio
    import inspect
    import webbrowser

    async def _do_launch():
        try:
            await page.launch_url(url)
        except Exception:
            pass

    try:
        if inspect.iscoroutinefunction(page.launch_url):
            asyncio.create_task(_do_launch())
        else:
            page.launch_url(url)
    except Exception:
        webbrowser.open(url)
