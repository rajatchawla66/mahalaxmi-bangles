"""
Database layer — Supabase cloud backend.

Drop-in replacement for db.py. Same public API, same function signatures.
Uses Supabase REST API via httpx (lightweight, works on Android).

Setup:
    1. Create a Supabase project at supabase.com
    2. Set SUPABASE_URL and SUPABASE_KEY below (or via environment variables)
    3. Run the SQL schema in the Supabase SQL Editor
    4. Rename this file to db.py (or update imports in main.py)

All functions maintain the same signatures as the SQLite version.
"""

from __future__ import annotations

import os
import json
from urllib.parse import quote

try:
    import httpx
    HAS_HTTPX = True
except ImportError:
    HAS_HTTPX = False

# ----- Configuration -----
# Set these from environment variables or hardcode for testing
SUPABASE_URL = os.environ.get("SUPABASE_URL", "https://lgiepatlslklpxmeqkww.supabase.co")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnaWVwYXRsc2xrbHB4bWVxa3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMzYyMzEsImV4cCI6MjA5NTgxMjIzMX0.ciwTJjAjNeZ01tsZDUFgZ_ryQDQltloJQm_OQinryKQ")

IMAGES_FOLDER = "product_images"
os.makedirs(IMAGES_FOLDER, exist_ok=True)

CHUDA_SIZES = ["2.2", "2.4", "2.6", "2.8", "2.10"]
QTY_COLUMNS = ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]

# Valid categories (loaded from DB, with fallback)
_FALLBACK_CATEGORIES = ["Chuda", "Kaleera", "Raw_Material", "Metal_Bangles", "Seasonal"]


# ----- HTTP helpers -----
def _headers():
    return {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json",
        "Prefer": "return=representation",
    }


def _get(table: str, params: str = "", raise_errors: bool = False) -> list:
    """GET request to Supabase REST API. Returns list of dicts."""
    url = f"{SUPABASE_URL}/rest/v1/{table}?{params}"
    try:
        r = httpx.get(url, headers=_headers(), timeout=10)
        r.raise_for_status()
        return r.json()
    except Exception as e:
        if raise_errors:
            raise e
        return []


def _post(table: str, data: dict | list) -> list:
    """POST (insert) to Supabase. Returns inserted rows."""
    url = f"{SUPABASE_URL}/rest/v1/{table}"
    try:
        r = httpx.post(url, headers=_headers(), json=data, timeout=10)
        r.raise_for_status()
        return r.json()
    except Exception:
        return []


def _patch(table: str, params: str, data: dict) -> bool:
    """PATCH (update) rows matching params. Returns success."""
    url = f"{SUPABASE_URL}/rest/v1/{table}?{params}"
    try:
        r = httpx.patch(url, headers=_headers(), json=data, timeout=10)
        r.raise_for_status()
        return True
    except Exception:
        return False


def _delete(table: str, params: str) -> bool:
    """DELETE rows matching params."""
    url = f"{SUPABASE_URL}/rest/v1/{table}?{params}"
    try:
        r = httpx.delete(url, headers=_headers(), timeout=10)
        r.raise_for_status()
        return True
    except Exception:
        return False


# ----- Image upload -----
STORAGE_BUCKET = "product-images"


def upload_image(file_path: str, item_number: str) -> str:
    """Upload an image file to Supabase Storage and return the public URL.

    Args:
        file_path: Local path to the image file.
        item_number: Used to generate a unique filename.

    Returns:
        Public URL string on success, empty string on failure.
    """
    if not file_path or not os.path.exists(file_path):
        return ""

    # Generate a clean filename
    ext = file_path.rsplit(".", 1)[-1].lower() if "." in file_path else "jpg"
    safe_name = item_number.strip().replace("/", "_").replace("\\", "_").replace(" ", "_")
    storage_path = f"{safe_name}.{ext}"

    # Read file bytes
    with open(file_path, "rb") as f:
        file_bytes = f.read()

    # Determine content type
    content_type = "image/jpeg"
    if ext == "png":
        content_type = "image/png"

    # Upload to Supabase Storage (upsert — overwrites if exists)
    url = f"{SUPABASE_URL}/storage/v1/object/{STORAGE_BUCKET}/{storage_path}"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": content_type,
        "x-upsert": "true",
    }

    try:
        r = httpx.put(url, headers=headers, content=file_bytes, timeout=30)
        r.raise_for_status()
    except Exception:
        return ""

    # Return the public URL
    public_url = f"{SUPABASE_URL}/storage/v1/object/public/{STORAGE_BUCKET}/{storage_path}"
    return public_url


import sqlite3
# =============================================================
# SCHEMA / INIT (no-op for Supabase — tables created via SQL)
# =============================================================
def init_db():
    """Ensure local SQLite schema is up-to-date for offline use."""
    if os.path.exists("chuda_business.db"):
        try:
            conn = sqlite3.connect("chuda_business.db")
            cursor = conn.cursor()
            cursor.execute("ALTER TABLE categories ADD COLUMN cover_image_url TEXT")
            conn.commit()
            conn.close()
        except sqlite3.OperationalError:
            # Column likely already exists
            pass
        except Exception:
            pass


# =============================================================
# CATEGORIES
# =============================================================
def get_categories(active_only: bool = False) -> list:
    params = "order=name.asc"
    if active_only:
        params += "&is_active=eq.true"
    return _get("categories", params)


def get_category_names(active_only: bool = True) -> list:
    return [c["name"] for c in get_categories(active_only=active_only)]


def add_category(name: str, icon: str = "CATEGORY", color: str = "GREY_400",
                 description: str = "", sub_categories: str = "",
                 order_type: str = "quantity",
                 cover_image_url: str | None = None) -> bool:
    if not name or not name.strip():
        return False
    result = _post("categories", {
        "name": name.strip(), "icon": icon, "color": color,
        "description": description, "sub_categories": sub_categories,
        "order_type": order_type,
        "cover_image_url": cover_image_url,
    })
    return len(result) > 0


def update_category(category_id: int, name: str, icon: str, color: str,
                    description: str, sub_categories: str,
                    order_type: str) -> bool:
    return _patch("categories", f"id=eq.{category_id}", {
        "name": name.strip(), "icon": icon, "color": color,
        "description": description, "sub_categories": sub_categories,
        "order_type": order_type,
    })


def update_category_cover(category_id: int, cover_image_url: str) -> bool:
    """Update the cover image URL for a category."""
    return _patch("categories", f"id=eq.{category_id}", {
        "cover_image_url": cover_image_url
    })


def upload_category_image(file_path: str, category_name: str) -> str:
    """Upload a category cover image to Supabase Storage.
    Path: category_covers/{category_name}.jpg
    """
    if not file_path or not os.path.exists(file_path):
        return ""

    ext = file_path.rsplit(".", 1)[-1].lower() if "." in file_path else "jpg"
    safe_name = category_name.strip().replace(" ", "_").lower()
    storage_path = f"category_covers/{safe_name}.{ext}"

    with open(file_path, "rb") as f:
        file_bytes = f.read()

    content_type = "image/png" if ext == "png" else "image/jpeg"
    url = f"{SUPABASE_URL}/storage/v1/object/{STORAGE_BUCKET}/{storage_path}"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": content_type,
        "x-upsert": "true",
    }

    try:
        r = httpx.put(url, headers=headers, content=file_bytes, timeout=30)
        r.raise_for_status()
        return f"{SUPABASE_URL}/storage/v1/object/public/{STORAGE_BUCKET}/{storage_path}"
    except Exception:
        return ""


def toggle_category_active(category_id: int, is_active: bool) -> bool:
    return _patch("categories", f"id=eq.{category_id}", {"is_active": is_active})


def delete_category(category_id: int) -> bool:
    # Check if items use this category
    cats = _get("categories", f"id=eq.{category_id}&select=name")
    if not cats:
        return False
    cat_name = cats[0]["name"]
    items = _get("rate_list", f"category=eq.{quote(cat_name)}&select=id&limit=1")
    if items:
        return False
    return _delete("categories", f"id=eq.{category_id}")


def _get_valid_categories() -> list:
    names = get_category_names(active_only=False)
    return names if names else _FALLBACK_CATEGORIES


def _get_valid_sub_categories(category: str) -> list:
    cats = _get("categories", f"name=eq.{quote(category)}&select=sub_categories")
    if cats and cats[0].get("sub_categories"):
        return [s.strip() for s in cats[0]["sub_categories"].split(",") if s.strip()]
    return []


# =============================================================
# RATE LIST
# =============================================================
def add_rate_item(item_number: str, image_url: str,
                  cost_price: float, selling_price: float,
                  category: str,
                  sub_category: str | None = None,
                  has_sizes: bool = False,
                  has_color: bool = False) -> bool:
    """Add a new item. Category is mandatory."""
    if not category or category not in _get_valid_categories():
        return False
    valid_subs = _get_valid_sub_categories(category)
    if valid_subs and (sub_category is None or sub_category not in valid_subs):
        return False

    result = _post("rate_list", {
        "item_number": item_number,
        "image_url": image_url,
        "cost_price": cost_price,
        "selling_price": selling_price,
        "category": category,
        "sub_category": sub_category,
        "has_sizes": has_sizes,
        "has_color": has_color,
    })
    return len(result) > 0


def get_rate_list() -> list:
    rows = _get("rate_list", "order=item_number.asc")
    # Map image_url to image_url for backward compatibility
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def get_rate_lookup() -> dict:
    rows = _get("rate_list", "select=item_number,image_url,cost_price,selling_price,category,has_sizes,has_color,sub_category")
    result = {}
    for r in rows:
        r["image_url"] = r.get("image_url", "")
        result[r["item_number"]] = r
    return result


def get_image_lookup() -> dict:
    rows = _get("rate_list", "select=item_number,image_url")
    return {r["item_number"]: r.get("image_url", "") for r in rows}


def get_item_by_number(item_number: str):
    if not item_number:
        return None
    rows = _get("rate_list", f"item_number=eq.{quote(item_number)}")
    if rows:
        rows[0]["image_url"] = rows[0].get("image_url", "")
        return rows[0]
    return None


def get_available_items(category: str | None = None) -> list:
    params = "is_available=eq.true&order=item_number.asc"
    if category:
        params += f"&category=eq.{quote(category)}"
    rows = _get("rate_list", params)
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def get_customer_catalogue() -> list:
    """Fetch items for customer browsing. 
    Only items where is_available=true, and must have selling_price > 0.
    """
    params = "is_available=eq.true&selling_price=gt.0&order=item_number.asc"
    rows = _get("rate_list", params)
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def get_customer_catalogue_by_category(category: str, sub_category: str = None) -> list:
    """Fetch items filtered by category and optional sub-category."""
    params = f"category=eq.{quote(category)}&is_available=eq.true&selling_price=gt.0&image_url=not.is.null&order=item_number.asc"
    if sub_category:
        params += f"&sub_category=eq.{quote(sub_category)}"
    
    rows = _get("rate_list", params)
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def get_all_items_with_cards(raise_errors: bool = False) -> list:
    rows = _get("rate_list", "order=item_number.asc", raise_errors=raise_errors)
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def update_item_prices(item_number: str, cost_price: float,
                       selling_price: float) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "cost_price": cost_price, "selling_price": selling_price,
    })


def update_item_category(item_number: str, category: str,
                         sub_category: str | None = None) -> bool:
    """Update category. Category is mandatory."""
    if not category or category not in _get_valid_categories():
        return False
    valid_subs = _get_valid_sub_categories(category)
    if valid_subs and (sub_category is None or sub_category not in valid_subs):
        return False
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "category": category, "sub_category": sub_category,
    })


def set_item_availability(item_number: str, is_available: bool) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "is_available": is_available,
    })


def update_item_card_path(item_number: str, card_path: str) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "card_path": card_path,
    })


def update_item_image_and_card(item_number: str, image_url: str,
                               card_path: str) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "image_url": image_url, "card_path": card_path,
    })


def update_item_properties(item_number: str, has_sizes: bool, has_color: bool) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "has_sizes": has_sizes, "has_color": has_color,
    })


# =============================================================
# ORDERS
# =============================================================
def create_order(header: dict, line_items: list) -> int:
    order_data = {
        "customer_name": header["customer_name"],
        "order_date": header["order_date"],
        "color": header.get("color"),
        "grind_type": header.get("grind_type"),
        "box_type": header.get("box_type"),
        "packing_structure": header.get("packing_structure"),
        "additional_info": header.get("additional_info"),
        "total_amount": header.get("total_amount", 0),
        "source": header.get("source", "admin"),
        "customer_mobile": header.get("customer_mobile"),
    }
    result = _post("orders", order_data)
    if not result:
        return 0
    new_order_id = result[0]["order_id"]

    # Insert line items
    items_data = []
    for li in line_items:
        items_data.append({
            "order_id": new_order_id,
            "item_number": li["item_number"],
            "category": li.get("category", "Chuda"),
            "qty_2_2": li.get("qty_2_2", 0),
            "qty_2_4": li.get("qty_2_4", 0),
            "qty_2_6": li.get("qty_2_6", 0),
            "qty_2_8": li.get("qty_2_8", 0),
            "qty_2_10": li.get("qty_2_10", 0),
            "quantity": li.get("quantity", 0) or 0,
            "unit": li.get("unit"),
            "color": li.get("color"),
            "grind_type": li.get("grind_type"),
            "box_type": li.get("box_type"),
            "notes": li.get("notes"),
            "unit_price": li.get("unit_price", 0),
        })
    if items_data:
        _post("order_items", items_data)

    return new_order_id



def update_order(order_id: int, header: dict, line_items: list) -> bool:
    order_data = {
        "customer_name": header["customer_name"],
        "order_date": header["order_date"],
        "color": header.get("color"),
        "grind_type": header.get("grind_type"),
        "box_type": header.get("box_type"),
        "packing_structure": header.get("packing_structure"),
        "additional_info": header.get("additional_info"),
        "total_amount": header.get("total_amount", 0),
    }
    _patch("orders", f"order_id=eq.{order_id}", order_data)
    _delete("order_items", f"order_id=eq.{order_id}")
    items_data = []
    for li in line_items:
        items_data.append({
            "order_id": order_id,
            "item_number": li["item_number"],
            "category": li.get("category", "Chuda"),
            "qty_2_2": li.get("qty_2_2", 0),
            "qty_2_4": li.get("qty_2_4", 0),
            "qty_2_6": li.get("qty_2_6", 0),
            "qty_2_8": li.get("qty_2_8", 0),
            "qty_2_10": li.get("qty_2_10", 0),
            "quantity": li.get("quantity"),
            "unit": li.get("unit"),
            "color": li.get("color"),
            "grind_type": li.get("grind_type"),
            "box_type": li.get("box_type"),
            "notes": li.get("notes"),
        })
    if items_data:
        _post("order_items", items_data)
    return True


def get_orders() -> list:
    return _get("orders", "order=order_id.desc")


def get_orders_with_items(raise_errors: bool = False) -> list:
    """Fetch all orders with their line items in a single query using Supabase embedding."""
    # Use select=*,order_items(*) to get nested items
    return _get("orders", "select=*,order_items(*)&order=order_id.desc", raise_errors=raise_errors)


def get_order_by_id(order_id: int) -> dict | None:
    """Fetch a single order by its ID, including items."""
    rows = _get("orders", f"order_id=eq.{order_id}&select=*,order_items(*)")
    return rows[0] if rows else None


def get_order_items(order_id: int) -> list:
    return _get("order_items", f"order_id=eq.{order_id}")


# =============================================================
# MATERIALS MASTER
# =============================================================

def get_materials() -> list:
    """Return all materials ordered by name."""
    return _get("materials", "order=name.asc")


def add_material(name: str, rate: float, unit: str = "pcs",
                 category: str = "General") -> bool:
    """Add a new material. Returns False if name already exists."""
    if not name or not name.strip():
        return False
    result = _post("materials", {
        "name": name.strip(),
        "rate": rate,
        "unit": unit,
        "category": category,
    })
    return len(result) > 0


def update_material(material_id: int, name: str, rate: float,
                    unit: str, category: str) -> bool:
    """Update an existing material."""
    return _patch("materials", f"id=eq.{material_id}", {
        "name": name.strip(),
        "rate": rate,
        "unit": unit,
        "category": category,
    })


def delete_material(material_id: int) -> bool:
    """Delete a material."""
    return _delete("materials", f"id=eq.{material_id}")


# =============================================================
# COST BREAKDOWN
# =============================================================

def get_cost_breakdown(item_number: str) -> list:
    """Return all cost breakdown rows for an item."""
    return _get("cost_breakdown", f"item_number=eq.{quote(item_number)}&order=id.asc")


def save_cost_breakdown(item_number: str, rows: list) -> bool:
    """Replace all cost breakdown rows for an item.

    Args:
        item_number: The item to save costs for.
        rows: list of dicts with keys: material_name, quantity, unit, rate_per_unit, line_total
              Optionally: material_id
    """
    # Delete existing rows
    _delete("cost_breakdown", f"item_number=eq.{quote(item_number)}")

    # Insert new rows
    if not rows:
        return True
    insert_data = []
    for r in rows:
        insert_data.append({
            "item_number": item_number,
            "material_id": r.get("material_id"),
            "material_name": r.get("material_name", ""),
            "quantity": r.get("quantity", 0),
            "unit": r.get("unit", "pcs"),
            "rate_per_unit": r.get("rate_per_unit", 0),
            "line_total": r.get("line_total", 0),
        })
    result = _post("cost_breakdown", insert_data)
    return len(result) > 0


# =============================================================
# APP SETTINGS
# =============================================================

def get_setting(key: str, default: str = "") -> str:
    """Get a single app setting value."""
    rows = _get("app_settings", f"key=eq.{quote(key)}")
    if rows:
        return rows[0].get("value", default)
    return default


def set_setting(key: str, value: str) -> bool:
    """Set an app setting (upsert)."""
    # Try update first
    ok = _patch("app_settings", f"key=eq.{quote(key)}", {"value": value})
    if not ok:
        # Insert if doesn't exist
        result = _post("app_settings", {"key": key, "value": value})
        return len(result) > 0
    return True


def get_default_margin() -> float:
    """Get the default margin percentage."""
    try:
        return float(get_setting("default_margin_percent", "30"))
    except (ValueError, TypeError):
        return 30.0


def get_labour_cost() -> float:
    """Get the flat labour cost."""
    try:
        return float(get_setting("labour_cost_flat", "50"))
    except (ValueError, TypeError):
        return 50.0


# =============================================================
# RATE LIST — extended for costing workflow
# =============================================================

def save_item_pricing(item_number: str, cost_price: float,
                      selling_price: float, margin_percent: float) -> bool:
    """Save calculated prices and mark item as 'priced'."""
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "cost_price": cost_price,
        "selling_price": selling_price,
        "margin_percent": margin_percent,
        "status": "priced",
    })


def get_priced_items() -> list:
    """Return items that have been priced (status='priced' and SP > 0)."""
    rows = _get("rate_list", "status=eq.priced&selling_price=gt.0&order=item_number.asc")
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


def get_unpriced_items() -> list:
    """Return items that haven't been priced yet."""
    rows = _get("rate_list", "status=eq.new&order=item_number.asc")
    for r in rows:
        r["image_url"] = r.get("image_url", "")
    return rows


# =============================================================
# CLOUDINARY PRICE CARD GENERATION
# =============================================================

CLOUDINARY_CLOUD_NAME = "duwvd4t6j"
CLOUDINARY_UPLOAD_PRESET = "ml_default"


def generate_price_card_url(image_url: str, item_number: str,
                            selling_price: float,
                            shop_name: str = "Mahalaxmi Bangles") -> str:
    """Generate a price card by uploading image to Cloudinary and applying text overlay.

    Steps:
    1. Download image from Supabase (or use local path)
    2. Upload to Cloudinary with a stable public_id
    3. Return a transformation URL with text overlay

    Works on Android (no Pillow needed).

    Returns:
        Cloudinary URL with text overlay, or empty string on failure.
    """
    if not image_url:
        return ""

    from urllib.parse import quote as url_quote

    safe_item = item_number.replace("/", "_").replace("\\", "_").replace(" ", "_")
    price_text = f"Rs.{int(selling_price)}/-"
    public_id = f"cards/{safe_item}"

    # Step 1: Get image bytes
    img_bytes = None
    if image_url.startswith("http"):
        try:
            r = httpx.get(image_url, timeout=15)
            if r.status_code == 200 and len(r.content) > 100:
                img_bytes = r.content
        except Exception:
            pass
    elif os.path.exists(image_url):
        with open(image_url, "rb") as f:
            img_bytes = f.read()

    if not img_bytes:
        return ""

    # Step 2: Upload to Cloudinary (upsert via public_id)
    upload_url = f"https://api.cloudinary.com/v1_1/{CLOUDINARY_CLOUD_NAME}/image/upload"
    ext = image_url.rsplit(".", 1)[-1].lower() if "." in image_url else "jpg"
    content_type = "image/png" if ext == "png" else "image/jpeg"

    try:
        files = {"file": (f"product.{ext}", img_bytes, content_type)}
        data = {
            "upload_preset": CLOUDINARY_UPLOAD_PRESET,
            "public_id": public_id,
            "overwrite": "true",
        }
        r = httpx.post(upload_url, data=data, files=files, timeout=30)
        if r.status_code != 200:
            return ""
    except Exception:
        return ""

    # Step 3: Build transformation URL with text overlay
    card_url = (
        f"https://res.cloudinary.com/{CLOUDINARY_CLOUD_NAME}/image/upload/"
        f"w_1080,h_1080,c_fill/"
        f"l_text:Arial_30_bold:{url_quote(shop_name)},co_white,g_south,y_180/"
        f"l_text:Arial_52_bold:{url_quote(safe_item)},co_white,g_south,y_100/"
        f"l_text:Arial_38_bold:{url_quote(price_text)},co_white,g_south,y_35/"
        f"{public_id}.jpg"
    )
    return card_url

# =============================================================
# COSTING & MATERIALS
# =============================================================

def get_all_items_costing_status() -> list:
    return _get("rate_list", "select=item_number,category,image_url,cost_price,selling_price&order=item_number.asc")

def get_item_costing_detail(item_number: str):
    res = _get("rate_list", f"item_number=eq.{quote(item_number)}")
    return res[0] if res else None

def save_item_costing(item_number: str, cost_price: float, selling_price: float) -> bool:
    return _patch("rate_list", f"item_number=eq.{quote(item_number)}", {
        "cost_price": cost_price,
        "selling_price": selling_price
    })

def get_item_materials(item_number: str) -> list:
    return _get("item_materials", f"item_number=eq.{quote(item_number)}")

def save_item_materials(item_number: str, materials: list) -> bool:
    try:
        _delete("item_materials", f"item_number=eq.{quote(item_number)}")
        if materials:
            for m in materials:
                m["item_number"] = item_number
            _post("item_materials", materials)
        return True
    except Exception as e:
        print(f"Error saving materials: {e}")
        return False

def get_default_margin() -> float:
    try:
        res = _get("app_settings", "key=eq.default_margin")
        if res:
            return float(res[0]["value"])
    except Exception:
        pass
    return 30.0

def save_default_margin(margin: float) -> bool:
    try:
        res = _get("app_settings", "key=eq.default_margin")
        if res:
            return _patch("app_settings", "key=eq.default_margin", {"value": str(margin)})
        else:
            _post("app_settings", [{"key": "default_margin", "value": str(margin)}])
            return True
    except Exception:
        return False

def get_all_materials_from_master() -> list:
    return _get("materials", "order=name.asc")

def delete_item(item_number: str) -> bool:
    return _delete("rate_list", f"item_number=eq.{quote(item_number)}")

def delete_order(order_id: int) -> bool:
    _delete("order_items", f"order_id=eq.{order_id}")
    return _delete("orders", f"order_id=eq.{order_id}")
