"""
Price-card image generator.

Builds a 1080x1080 social-ready product card from a product photo,
overlays a dark gradient bar at the bottom with shop name + item number
+ price, and pastes a semi-transparent logo in the top-right corner.

Public function:
    generate_price_card(product_photo_path, item_number, selling_price,
                        logo_path, output_folder, shop_name) -> str
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFont

# ----- Default output folder (works on desktop and Android via Flet) -----
DEFAULT_OUTPUT_FOLDER = os.path.join(
    os.environ.get("FLET_APP_STORAGE_DATA", "."),
    "generated_cards",
)

CARD_SIZE = (1080, 1080)
BAR_HEIGHT = 220
LOGO_SIZE = (120, 120)
LOGO_PADDING = 16


# ----- Font loading helpers -----
def _try_truetype(size: int, bold: bool = False):
    """Try a few common system fonts; fall back to PIL default."""
    candidates_bold = [
        "arialbd.ttf", "Arial Bold.ttf", "Helvetica-Bold.ttf",
        "DejaVuSans-Bold.ttf", "Roboto-Bold.ttf",
    ]
    candidates_regular = [
        "arial.ttf", "Arial.ttf", "Helvetica.ttf",
        "DejaVuSans.ttf", "Roboto-Regular.ttf",
    ]
    candidates = candidates_bold if bold else candidates_regular
    for name in candidates:
        try:
            return ImageFont.truetype(name, size=size)
        except (OSError, IOError):
            continue
    try:
        return ImageFont.load_default(size=size)  # PIL >= 10
    except TypeError:
        return ImageFont.load_default()


def _measure(draw: ImageDraw.ImageDraw, text: str, font) -> tuple[int, int]:
    """Return (width, height) of the rendered text for the given font."""
    try:
        x0, y0, x1, y1 = draw.textbbox((0, 0), text, font=font)
        return (x1 - x0, y1 - y0)
    except AttributeError:
        # Very old PIL fallback
        return draw.textsize(text, font=font)


# ----- Public API -----
def generate_price_card(
    product_photo_path: str,
    item_number: str,
    selling_price: float,
    logo_path: str,
    output_folder: str = DEFAULT_OUTPUT_FOLDER,
    shop_name: str = "Mahalaxmi Bangles",
) -> str:
    """Generate a 1080x1080 price card and save it as JPEG. Returns saved path."""
    os.makedirs(output_folder, exist_ok=True)

    # 1. Open product photo, resize to 1080x1080 RGBA
    base = Image.open(product_photo_path).convert("RGBA")
    base = base.resize(CARD_SIZE, Image.LANCZOS)

    # 2. Dark semi-transparent bar at the bottom
    overlay = Image.new("RGBA", CARD_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle(
        [(0, CARD_SIZE[1] - BAR_HEIGHT), (CARD_SIZE[0], CARD_SIZE[1])],
        fill=(0, 0, 0, 180),
    )

    # 3. Text on the bar
    font_shop = _try_truetype(28, bold=False)
    font_item = _try_truetype(52, bold=True)
    font_price = _try_truetype(38, bold=False)

    bar_top = CARD_SIZE[1] - BAR_HEIGHT
    bar_bottom = CARD_SIZE[1]

    # Three centered lines, evenly spaced inside the bar
    line1 = shop_name
    line2 = item_number
    line3 = f"₹{selling_price:,.0f}/-"

    # Vertical layout: divide bar into 3 zones
    pad_y = 12
    zone_h = (BAR_HEIGHT - pad_y * 2) / 3

    for idx, (text, font) in enumerate(
        [(line1, font_shop), (line2, font_item), (line3, font_price)]
    ):
        tw, th = _measure(draw, text, font)
        x = (CARD_SIZE[0] - tw) // 2
        zone_top = bar_top + pad_y + idx * zone_h
        y = int(zone_top + (zone_h - th) / 2)
        draw.text((x, y), text, fill=(255, 255, 255, 255), font=font)

    # 4. Logo in top-right corner with 70% opacity (skipped if missing)
    if logo_path and os.path.exists(logo_path):
        try:
            logo = Image.open(logo_path).convert("RGBA")
            logo = logo.resize(LOGO_SIZE, Image.LANCZOS)
            # Apply 70% opacity by scaling the alpha channel
            alpha = logo.split()[3].point(lambda a: int(a * 0.7))
            logo.putalpha(alpha)
            lx = CARD_SIZE[0] - LOGO_SIZE[0] - LOGO_PADDING
            ly = LOGO_PADDING
            overlay.paste(logo, (lx, ly), logo)
        except Exception:
            # Don't fail card generation if logo is broken
            pass

    # Composite overlay onto base
    composed = Image.alpha_composite(base, overlay)

    # 5. Save as JPEG
    safe_item = item_number.replace("/", "_").replace("\\", "_").strip()
    out_path = os.path.join(output_folder, f"{safe_item}_card.jpg")
    composed.convert("RGB").save(out_path, "JPEG", quality=92, optimize=True)

    return out_path


# =============================================================
# Module-load: ensure assets/logo.png exists as a placeholder
# =============================================================
def _ensure_placeholder_logo():
    assets_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets")
    os.makedirs(assets_dir, exist_ok=True)
    logo_path = os.path.join(assets_dir, "logo.png")
    if os.path.exists(logo_path):
        return
    try:
        img = Image.new("RGBA", (200, 200), (255, 255, 255, 255))
        d = ImageDraw.Draw(img)
        font = _try_truetype(48, bold=True)
        text = "LOGO"
        try:
            x0, y0, x1, y1 = d.textbbox((0, 0), text, font=font)
            tw, th = x1 - x0, y1 - y0
        except AttributeError:
            tw, th = d.textsize(text, font=font)
        d.text(
            ((200 - tw) // 2, (200 - th) // 2),
            text,
            fill=(0, 0, 0, 255),
            font=font,
        )
        img.save(logo_path, "PNG")
    except Exception:
        # Silent failure; the generator handles missing logo gracefully
        pass


_ensure_placeholder_logo()
