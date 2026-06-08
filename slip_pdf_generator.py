from __future__ import annotations

import os
import tempfile
from io import BytesIO
from typing import Optional

from PIL import Image
from fpdf import FPDF

FONT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "assets", "fonts", "HindiFont.ttf",
)

BUSINESS_NAME = "Mahalaxmi Bangles"
PDF_MARGIN = 15
CELL_H = 7
IMAGE_WIDTH_MM = 45


def _mm_to_pt(mm: float) -> float:
    return mm * 2.835


def _init_pdf() -> FPDF:
    pdf = FPDF(orientation="P", unit="mm", format="A4")
    pdf.add_page()
    if os.path.exists(FONT_PATH):
        pdf.add_font("Hindi", "", FONT_PATH)
    else:
        pdf.add_font("Helvetica", "", "")
    return pdf


def _section_header(pdf: FPDF, text: str):
    pdf.set_font("Hindi", "", 13)
    pdf.set_fill_color(230, 230, 230)
    pdf.cell(0, 7, text, ln=True, fill=True)
    pdf.ln(2)


def _draw_item_block(
    pdf: FPDF,
    item: dict,
    image_path: Optional[str],
    w: float,
):
    col_left = pdf.get_x()
    start_y = pdf.get_y()

    image_available = image_path is not None and os.path.exists(image_path)

    text_col_w = w
    if image_available:
        text_col_w = w - IMAGE_WIDTH_MM - 4

    pdf.set_font("Hindi", "", 10)
    item_num = item.get("item_number", "—")

    notes = item.get("notes", "")

    total_sets = sum(
        item.get(k, 0) for k in ["qty_2_2", "qty_2_4", "qty_2_6", "qty_2_8", "qty_2_10"]
    )
    flat_qty = item.get("quantity", 0) or 0

    sizes_summary = ""
    size_parts = []
    for label, key in [
        ("2.2", "qty_2_2"), ("2.4", "qty_2_4"), ("2.6", "qty_2_6"),
        ("2.8", "qty_2_8"), ("2.10", "qty_2_10"),
    ]:
        q = item.get(key, 0)
        if q > 0:
            size_parts.append(f"{label}: {q}")
    if size_parts:
        sizes_summary = ", ".join(size_parts)

    lines = [f"Item: {item_num}"]
    if total_sets > 0:
        lines.append(f"Total sets: {total_sets}")
        if sizes_summary:
            lines.append(f"Sizes: {sizes_summary}")
    elif flat_qty > 0:
        lines.append(f"Qty: {flat_qty}")

    if notes:
        lines.append(f"Notes: {notes}")

    line_height = 5
    block_h = max(len(lines) * line_height + 4, IMAGE_WIDTH_MM * 0.75 + 4)
    block_h = min(block_h, 60)

    space_left = pdf.h - pdf.b_margin - pdf.get_y()
    if block_h > space_left:
        pdf.add_page()
        start_y = pdf.get_y()

    if image_available:
        try:
            img = Image.open(image_path)
            img_w, img_h = img.size
            ratio = img_w / img_h if img_h > 0 else 1
            disp_w = IMAGE_WIDTH_MM
            disp_h = disp_w / ratio
            if disp_h > 35:
                disp_h = 35
                disp_w = disp_h * ratio
            pdf.image(image_path, x=col_left, y=start_y, w=disp_w, h=disp_h)
        except Exception:
            pass

    text_x = col_left + (IMAGE_WIDTH_MM + 4 if image_available else 0)
    pdf.set_xy(text_x, start_y)
    pdf.set_font("Hindi", "", 9)
    for line in lines:
        pdf.set_x(text_x)
        pdf.cell(text_col_w, line_height, line, ln=True)

    end_y = max(start_y + block_h, pdf.get_y())
    pdf.set_y(end_y + 3)


def create_slip_pdf(
    order: dict,
    line_items: list,
    image_lookup: dict,
    output_path: str,
    customer_name: str = "",
) -> bool:
    try:
        pdf = _init_pdf()
        usable_w = pdf.w - 2 * PDF_MARGIN

        pdf.set_font("Hindi", "", 18)
        pdf.cell(0, 10, BUSINESS_NAME, ln=True, align="C")
        pdf.set_font("Hindi", "", 13)
        pdf.cell(0, 7, "Karigar Slip", ln=True, align="C")
        pdf.ln(2)

        order_id = order.get("order_id", "—")
        order_date = order.get("order_date", "—")
        customer = customer_name or order.get("customer_name", "—")
        pdf.set_font("Hindi", "", 10)
        pdf.cell(0, CELL_H, f"Order #{order_id}  |  {customer}  |  {order_date}", ln=True)
        pdf.ln(2)

        _section_header(pdf, "Order Details")
        details = [
            ("Color", order.get("color")),
            ("Grind / Finish", order.get("grind_type")),
            ("Box Type", order.get("box_type")),
            ("Packing", order.get("packing_structure")),
        ]
        pdf.set_font("Hindi", "", 10)
        for label, val in details:
            text = f"{label}:  {val or '—'}"
            pdf.cell(0, CELL_H, text, ln=True)
        pdf.ln(1)

        extra = order.get("additional_info", "")
        if extra:
            pdf.set_font("Hindi", "", 10)
            pdf.set_fill_color(255, 243, 205)
            pdf.cell(0, CELL_H, f"Notes: {extra}", ln=True, fill=True)
            pdf.ln(2)

        _section_header(pdf, "Items")
        pdf.ln(1)

        for item in line_items:
            item_num = item.get("item_number", "")
            img_url = image_lookup.get(item_num, "")
            temp_img_path = None

            if img_url:
                temp_img_path = _download_image(img_url, item_num)
            _draw_item_block(pdf, item, temp_img_path, usable_w)
            if temp_img_path:
                _try_remove(temp_img_path)

        pdf.ln(3)
        total_items = len(line_items)
        pdf.set_font("Hindi", "", 10)
        pdf.cell(0, CELL_H, f"Total items in order: {total_items}", ln=True)

        pdf.output(output_path)
        return True

    except Exception as e:
        print(f"ERROR in create_slip_pdf: {e}")
        return False


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
