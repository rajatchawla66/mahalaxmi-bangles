"""
Offline cache layer.

Syncs catalog (items + images) and orders from Supabase to local storage.
Provides fallback data when the device is offline.

Usage:
    import cache
    cache.sync_all(on_progress=callback)  # downloads everything
    items = cache.get_cached_catalog()     # returns cached items
    orders = cache.get_cached_orders()     # returns cached orders
"""

from __future__ import annotations

import os
import json
import time
import threading

try:
    import httpx
except ImportError:
    httpx = None

import db

def _download_bg(url, local_path):
    try:
        if httpx:
            r = httpx.get(url, timeout=15)
            if r.status_code == 200:
                with open(local_path, "wb") as f:
                    f.write(r.content)
    except Exception:
        pass

def download_image_if_missing(url, local_path):
    if not os.path.exists(local_path) and url.startswith("http"):
        threading.Thread(target=_download_bg, args=(url, local_path), daemon=True).start()

# ----- Cache directory -----
def _cache_dir() -> str:
    base = os.environ.get("FLET_APP_STORAGE_DATA", ".")
    path = os.path.join(base, "cache")
    os.makedirs(path, exist_ok=True)
    return path


def _images_dir() -> str:
    path = os.path.join(_cache_dir(), "images")
    os.makedirs(path, exist_ok=True)
    return path


CATALOG_FILE = property(lambda self: "")  # not used as property


def _catalog_path() -> str:
    return os.path.join(_cache_dir(), "catalog.json")


def _orders_path() -> str:
    return os.path.join(_cache_dir(), "orders.json")


def _meta_path() -> str:
    return os.path.join(_cache_dir(), "sync_meta.json")


# =============================================================
# SYNC
# =============================================================

def sync_all(on_progress=None):
    """Full sync: download catalog + orders + images.

    Args:
        on_progress: callback(current, total, message) called during sync.
                     If None, runs silently.

    Returns:
        dict with keys: items_synced, images_synced, orders_synced, errors
    """
    result = {"items_synced": 0, "images_synced": 0, "orders_synced": 0, "errors": []}

    def _progress(current, total, msg):
        if on_progress:
            on_progress(current, total, msg)

    # Step 1: Sync catalog (items + categories)
    _progress(0, 100, "Fetching catalog...")
    try:
        items = db.get_rate_list()
        categories = db.get_categories(active_only=False)
    except Exception as e:
        result["errors"].append(f"Failed to fetch catalog: {e}")
        return result

    # Save catalog JSON
    catalog_data = {
        "items": items,
        "categories": categories,
        "synced_at": time.time(),
    }
    with open(_catalog_path(), "w", encoding="utf-8") as f:
        json.dump(catalog_data, f, ensure_ascii=False)
    result["items_synced"] = len(items)

    # Step 2: Sync orders
    _progress(10, 100, "Fetching orders...")
    try:
        # Fetch everything in one go to avoid N+1 queries
        orders_with_items = db.get_orders_with_items()
    except Exception as e:
        result["errors"].append(f"Failed to fetch orders: {e}")
        orders_with_items = []

    orders_data = {
        "orders": orders_with_items,
        "synced_at": time.time(),
    }
    with open(_orders_path(), "w", encoding="utf-8") as f:
        json.dump(orders_data, f, ensure_ascii=False)
    result["orders_synced"] = len(orders_with_items)

    # Step 3: Download images (Items + Categories)
    _progress(20, 100, "Downloading images...")
    images_to_download = []
    
    # Product images
    for item in items:
        img_url = item.get("image_url", "")
        if img_url and img_url.startswith("http"):
            safe_name = item["item_number"].replace("/", "_").replace("\\", "_").replace(" ", "_")
            local_path = os.path.join(_images_dir(), f"{safe_name}.jpg")
            if not os.path.exists(local_path):
                images_to_download.append((img_url, local_path, item["item_number"]))

    # Category cover images
    for cat in categories:
        cat_url = cat.get("cover_image_url")
        if cat_url and cat_url.startswith("http"):
            safe_name = f"cat_{cat['id']}"
            local_path = os.path.join(_images_dir(), f"{safe_name}.jpg")
            if not os.path.exists(local_path):
                images_to_download.append((cat_url, local_path, f"Category: {cat['name']}"))

    total_images = len(images_to_download)
    for idx, (url, local_path, label) in enumerate(images_to_download):
        progress_pct = 20 + int((idx / max(total_images, 1)) * 75)
        _progress(progress_pct, 100, f"Image {idx+1}/{total_images}: {label}")
        try:
            r = httpx.get(url, timeout=15)
            if r.status_code == 200:
                with open(local_path, "wb") as f:
                    f.write(r.content)
                result["images_synced"] += 1
        except Exception:
            result["errors"].append(f"Failed to download image for {label}")

    # Step 4: Save sync metadata
    _progress(98, 100, "Finishing...")
    meta = {
        "last_sync": time.time(),
        "items_count": len(items),
        "orders_count": len(orders_with_items),
        "images_count": result["images_synced"],
    }
    with open(_meta_path(), "w", encoding="utf-8") as f:
        json.dump(meta, f)

    _progress(100, 100, "Done!")
    return result


# =============================================================
# READ CACHE
# =============================================================

def is_cache_available() -> bool:
    """Check if a local cache exists."""
    return os.path.exists(_catalog_path())


def get_last_sync_time() -> str:
    """Return human-readable last sync time, or 'Never'."""
    if not os.path.exists(_meta_path()):
        return "Never"
    try:
        with open(_meta_path(), "r") as f:
            meta = json.load(f)
        ts = meta.get("last_sync", 0)
        if ts == 0:
            return "Never"
        elapsed = time.time() - ts
        if elapsed < 60:
            return "Just now"
        elif elapsed < 3600:
            return f"{int(elapsed/60)} min ago"
        elif elapsed < 86400:
            return f"{int(elapsed/3600)} hours ago"
        else:
            return f"{int(elapsed/86400)} days ago"
    except Exception:
        return "Unknown"


def get_cached_catalog() -> list:
    """Return cached items list, or empty list if no cache."""
    if not os.path.exists(_catalog_path()):
        return []
    try:
        with open(_catalog_path(), "r", encoding="utf-8") as f:
            data = json.load(f)
        items = data.get("items", [])
        # Map image URLs to local cached paths where available
        for item in items:
            img_url = item.get("image_url", "") or item.get("image_url", "")
            if img_url and img_url.startswith("http"):
                safe_name = item["item_number"].replace("/", "_").replace("\\", "_").replace(" ", "_")
                local_path = os.path.join(_images_dir(), f"{safe_name}.jpg")
                if os.path.exists(local_path):
                    item["image_url"] = local_path
                else:
                    download_image_if_missing(img_url, local_path)
        return items
    except Exception:
        return []


def get_cached_categories() -> list:
    """Return cached categories list, filtered to active only (matches online behavior)."""
    if not os.path.exists(_catalog_path()):
        return []
    try:
        with open(_catalog_path(), "r", encoding="utf-8") as f:
            data = json.load(f)
        categories = data.get("categories", [])
        # Filter to active only — match online get_categories(active_only=True)
        categories = [c for c in categories if c.get("is_active", True)]
        # Map cover URLs to local cached paths
        for cat in categories:
            cat_url = cat.get("cover_image_url")
            if cat_url and cat_url.startswith("http"):
                safe_name = f"cat_{cat['id']}"
                local_path = os.path.join(_images_dir(), f"{safe_name}.jpg")
                if os.path.exists(local_path):
                    cat["cover_image_url"] = local_path
        return categories
    except Exception:
        return []


def get_cached_orders() -> list:
    """Return cached orders (each with nested items), or empty list."""
    if not os.path.exists(_orders_path()):
        return []
    try:
        with open(_orders_path(), "r", encoding="utf-8") as f:
            data = json.load(f)
        return data.get("orders", [])
    except Exception:
        return []


def get_cached_image_url(item_number: str) -> str:
    """Return local cached image path for an item, or empty string."""
    safe_name = item_number.replace("/", "_").replace("\\", "_").replace(" ", "_")
    local_path = os.path.join(_images_dir(), f"{safe_name}.jpg")
    if os.path.exists(local_path):
        return local_path
    return ""
