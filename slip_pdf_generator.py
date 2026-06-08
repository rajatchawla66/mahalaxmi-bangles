from __future__ import annotations

import os
import tempfile
from typing import Optional


FONT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "assets", "fonts", "HindiFont.ttf",
)

BUSINESS_NAME = "Mahalaxmi Bangles"

# Layout (mm)
PDF_MARGIN = 12
USABLE_W = 186

# Colors
MAROON = (128, 0, 0)
GOLD = (184, 134, 11)
WARM_BG = (250, 245, 240)
LIGHT_GREY = (240, 240, 240)
MID_GREY = (200, 200, 200)
DARK_GREY = (100, 100, 100)
AMBER_BG = (255, 248, 200)

# Image dimensions (mm)
IMAGE_W = 30
MAX_IMAGE_H = 35
SIZES_BOX_W = 42
IMAGE_GAP = 4


def _init_pdf() -> FPDF:
    from fpdf import FPDF
    pdf = FPDF(orientation="P", unit="mm", format="A4")
    pdf.add_page()
    if os.path.exists(FONT_PATH):
        pdf.add_font("Hindi", "", FONT_PATH)
    else:
        pdf.add_font("Helvetica", "", "")
    return pdf


def _hline(pdf, x, y, w, color=MID_GREY, lw=0.3):
    pdf.set_draw_color(*color)
    pdf.set_line_width(lw)
    pdf.line(x, y, x + w, y)


# ── Header ────────────────────────────────────────────────────

def _draw_header(pdf: FPDF, order: dict, customer_name: str = ""):
    order_id = order.get("order_id", "—")
    customer = customer_name or order.get("customer_name", "—")
    order_date = order.get("order_date", "—")
    x = PDF_MARGIN
    w = USABLE_W
    y0 = pdf.get_y()

    _hline(pdf, x, y0, w, MAROON, 0.8)
    pdf.ln(5)

    pdf.set_text_color(*MAROON)
    pdf.set_font("Hindi", "", 20)
    pdf.cell(0, 8, BUSINESS_NAME, ln=True, align="C")
    pdf.ln(1)

    pdf.set_text_color(*GOLD)
    pdf.set_font("Hindi", "", 12)
    pdf.cell(0, 6, "Karigar Slip", ln=True, align="C")
    pdf.ln(1)

    pdf.set_text_color(*DARK_GREY)
    pdf.set_font("Hindi", "", 7)
    pdf.cell(0, 3, "PDF FORMAT VERSION: v2", ln=True, align="C")
    pdf.ln(2)

    _hline(pdf, x, pdf.get_y(), w)
    pdf.ln(4)

    pdf.set_text_color(*DARK_GREY)
    pdf.set_font("Hindi", "", 8)
    pdf.cell(42, 4, "Order #", align="L")
    pdf.cell(70, 4, "Customer", align="L")
    pdf.cell(0, 4, "Date", align="L")
    pdf.ln(4)

    pdf.set_text_color(*MAROON)
    pdf.set_font("Hindi", "", 10)
    pdf.cell(42, 6, str(order_id), align="L")
    pdf.cell(70, 6, str(customer), align="L")
    pdf.cell(0, 6, str(order_date), align="L")
    pdf.ln(8)


# ── Order Details Card ────────────────────────────────────────

def _draw_details_card(pdf: FPDF, order: dict):
    x = PDF_MARGIN
    w = USABLE_W
    pad = 3
    row_h = 6

    details = [
        ("Color", order.get("color")),
        ("Grind / Finish", order.get("grind_type")),
        ("Box Type", order.get("box_type")),
        ("Packing", order.get("packing_structure")),
    ]
    extra = order.get("additional_info", "")

    title_h = 8
    rows_h = len(details) * row_h
    extra_h = (row_h + 4) if extra else 0
    card_h = title_h + rows_h + extra_h + pad * 2

    y0 = pdf.get_y()
    if y0 + card_h > 277:
        pdf.add_page()
        y0 = pdf.get_y()

    pdf.set_fill_color(*WARM_BG)
    pdf.set_draw_color(*MAROON)
    pdf.set_line_width(0.5)
    pdf.rect(x, y0, w, card_h, "DF")

    pdf.set_text_color(*MAROON)
    pdf.set_font("Hindi", "", 11)
    pdf.set_xy(x + pad, y0 + pad)
    pdf.cell(0, title_h, "Order Details", ln=True)
    pdf.ln(2)

    col1_x = x + pad
    col2_x = x + w // 2 + pad
    col_w = w // 2 - pad * 2

    for label, val in details:
        cy = pdf.get_y()
        pdf.set_text_color(*DARK_GREY)
        pdf.set_font("Hindi", "", 8)
        pdf.set_xy(col1_x, cy)
        pdf.cell(col_w, row_h, label, align="L")

        pdf.set_text_color(*MAROON)
        pdf.set_font("Hindi", "", 10)
        pdf.set_xy(col2_x, cy)
        pdf.cell(col_w, row_h, str(val or "—"), align="L")
        pdf.set_y(cy + row_h)

    if extra:
        ey = pdf.get_y() + 2
        pdf.set_fill_color(*AMBER_BG)
        pdf.set_draw_color(*GOLD)
        pdf.set_line_width(0.3)
        pdf.rect(x + pad, ey, w - pad * 2, row_h + 2, "DF")
        pdf.set_text_color(*DARK_GREY)
        pdf.set_font("Hindi", "", 8)
        pdf.set_xy(x + pad + 2, ey + 1)
        pdf.cell(0, row_h, f"Notes: {extra}", align="L")
        pdf.set_y(ey + row_h + 4)
    else:
        pdf.set_y(y0 + card_h + 3)


# ── Item Block ────────────────────────────────────────────────

def _draw_item_block(pdf: FPDF, item: dict, image_path: Optional[str], w: float):
    x = PDF_MARGIN
    y0 = pdf.get_y()
    row_h = 5
    pad = 2
    center_x = x + IMAGE_W + IMAGE_GAP
    sizes_x = x + w - SIZES_BOX_W
    center_max_w = sizes_x - center_x - pad

    image_ok = image_path is not None and os.path.exists(image_path)
    img_disp_w = 0
    img_disp_h = 0

    if image_ok:
        try:
            from PIL import Image
            pi = Image.open(image_path)
            ratio = pi.width / pi.height if pi.height > 0 else 1
            img_disp_w = IMAGE_W
            img_disp_h = min(img_disp_w / ratio, MAX_IMAGE_H)
        except Exception:
            image_ok = False

    item_num = item.get("item_number", "—")
    notes = item.get("notes", "")
    center_lines = [f"Item: {item_num}"]
    if notes:
        center_lines.append(notes)
    center_text_h = len(center_lines) * row_h + pad * 2

    total_sets = sum(
        item.get(k, 0) for k in ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
    )
    flat_qty = item.get("quantity", 0) or 0
    size_lines = []
    if total_sets > 0:
        size_lines.append(f"Total: {total_sets}")
        for label, key in [
            ("2.2", "qty_2_2"), ("2.4", "qty_2_4"),
            ("2.6", "qty_2_6"), ("2.8", "qty_2_8"),
            ("2.10", "qty_2_10"),
        ]:
            q = item.get(key, 0)
            if q > 0:
                size_lines.append(f"{label}: {q}")
    elif flat_qty > 0:
        size_lines.append(f"Qty: {flat_qty}")

    sizes_text_h = (len(size_lines) * row_h + pad * 2) if size_lines else 0
    block_h = max(img_disp_h or 20, center_text_h, sizes_text_h) + pad * 2
    block_h = max(block_h, 24)

    space_left = 297 - 20 - pdf.get_y()
    if block_h > space_left:
        pdf.add_page()
        y0 = pdf.get_y()

    # Image / placeholder
    if image_ok and img_disp_w > 0:
        try:
            pdf.set_draw_color(*MID_GREY)
            pdf.set_line_width(0.3)
            pdf.rect(x, y0 + pad, img_disp_w, img_disp_h, "D")
            pdf.image(image_path, x=x, y=y0 + pad, w=img_disp_w, h=img_disp_h)
        except Exception:
            image_ok = False

    if not image_ok:
        ph_w = IMAGE_W
        ph_h = max(20, block_h - pad * 2)
        pdf.set_fill_color(*LIGHT_GREY)
        pdf.set_draw_color(*MID_GREY)
        pdf.set_line_width(0.3)
        pdf.rect(x, y0 + pad, ph_w, ph_h, "DF")
        pdf.set_text_color(*DARK_GREY)
        pdf.set_font("Hindi", "", 8)
        pdf.set_xy(x, y0 + pad)
        pdf.cell(ph_w, ph_h, "No Image", align="C")

    # Sizes box (right side)
    if size_lines:
        box_h = len(size_lines) * row_h + pad * 2
        pdf.set_fill_color(*WARM_BG)
        pdf.set_draw_color(*MID_GREY)
        pdf.set_line_width(0.3)
        pdf.rect(sizes_x, y0 + pad, SIZES_BOX_W, box_h, "DF")
        for i, line in enumerate(size_lines):
            pdf.set_text_color(*MAROON if i == 0 else DARK_GREY)
            pdf.set_font("Hindi", "", 10 if i == 0 else 8)
            pdf.set_xy(sizes_x + pad, y0 + pad + pad + i * row_h)
            pdf.cell(SIZES_BOX_W - pad * 2, row_h, line)

    # Center text
    pdf.set_text_color(*MAROON)
    pdf.set_font("Hindi", "", 10)
    pdf.set_xy(center_x, y0 + pad)
    pdf.cell(center_max_w, row_h, f"Item: {item_num}", ln=True)
    if notes:
        pdf.set_text_color(*DARK_GREY)
        pdf.set_font("Hindi", "", 8)
        pdf.set_x(center_x)
        pdf.cell(center_max_w, row_h, notes, ln=True)

    # Divider
    block_bottom = y0 + block_h
    _hline(pdf, x, block_bottom, w, LIGHT_GREY, 0.3)
    pdf.set_y(block_bottom + 3)


# ── Footer ────────────────────────────────────────────────────

def _draw_footer(pdf: FPDF, total_items: int):
    _hline(pdf, PDF_MARGIN, pdf.get_y(), USABLE_W, MID_GREY, 0.3)
    pdf.ln(4)

    pdf.set_text_color(*MAROON)
    pdf.set_font("Hindi", "", 11)
    pdf.cell(0, 7, f"Total items: {total_items}", ln=True, align="R")
    pdf.ln(3)

    pdf.set_text_color(*DARK_GREY)
    pdf.set_font("Hindi", "", 9)
    pdf.cell(0, 5, "Thank you", ln=True, align="C")
    pdf.ln(7)

    sig_x = PDF_MARGIN + USABLE_W - 60
    pdf.set_draw_color(*MID_GREY)
    pdf.set_line_width(0.3)
    pdf.line(sig_x, pdf.get_y(), sig_x + 50, pdf.get_y())
    pdf.set_text_color(*DARK_GREY)
    pdf.set_font("Hindi", "", 8)
    pdf.set_xy(sig_x, pdf.get_y() + 1)
    pdf.cell(50, 4, "Authorized Signature", align="C")


# ── Main Entry Point ──────────────────────────────────────────

def create_slip_pdf(
    order: dict,
    line_items: list,
    image_lookup: dict,
    output_path: str,
    customer_name: str = "",
) -> bool:
    try:
        pdf = _init_pdf()
        _draw_header(pdf, order, customer_name)
        _draw_details_card(pdf, order)

        _hline(pdf, PDF_MARGIN, pdf.get_y(), USABLE_W, MID_GREY, 0.3)
        pdf.ln(4)
        pdf.set_text_color(*MAROON)
        pdf.set_font("Hindi", "", 11)
        pdf.cell(0, 7, "Items", ln=True)
        pdf.ln(2)

        for item in line_items:
            item_num = item.get("item_number", "")
            img_url = image_lookup.get(item_num, "")
            temp_img_path = None
            if img_url:
                temp_img_path = _download_image(img_url, item_num)
            _draw_item_block(pdf, item, temp_img_path, USABLE_W)
            if temp_img_path:
                _try_remove(temp_img_path)

        pdf.ln(2)
        _draw_footer(pdf, len(line_items))
        pdf.output(output_path)
        return True
    except Exception as e:
        print(f"ERROR in create_slip_pdf: {e}")
        return False


# ── Helpers (unchanged) ───────────────────────────────────────

def _download_image(url: str, item_num: str) -> Optional[str]:
    if not url:
        return None
    import httpx
    try:
        r = httpx.get(url, timeout=15)
        if r.status_code != 200 or len(r.content) < 100:
            return None
        ext = "jpg"
        if url.lower().endswith(".png"):
            ext = "png"
        tmp = tempfile.NamedTemporaryFile(
            prefix=f"slip_img_{item_num}_",
            suffix=f".{ext}",
            delete=False,
        )
        tmp.write(r.content)
        tmp.close()
        return tmp.name
    except Exception:
        return None


def _try_remove(path: str):
    try:
        if path and os.path.exists(path):
            os.remove(path)
    except Exception:
        pass
