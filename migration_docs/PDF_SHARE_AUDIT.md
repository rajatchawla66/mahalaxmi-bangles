# Audit Report: Legacy Flet PDF Share & Flutter Implementation Design (Revised)

This document audits the legacy Python Flet application's PDF generation/sharing implementation and details the updated architectural proposal, package choices, and phased rollout plan for the new Flutter-based Mahalaxmi apps, incorporating the business decision to simplify fonts and currency indicators.

---

## 1. Legacy Flet PDF Behavior Summary

In the legacy Flet application, the PDF generation and sharing feature worked as follows:
- **Trigger point:** Triggered manually on-demand by the user clicking the **📤 Share PDF** button inside the **Order Detail screen** (`views/orders.py`).
- **Generation library:** Used `fpdf2` (Python FPDF library) in `slip_pdf_generator.py` to draw custom A4 page layouts programmatically using lines, rectangles, colors (maroon/gold theme), and cells.
- **Image handling:** 
  - If a product image URL existed, it dynamically downloaded the image over HTTP via `httpx`.
  - Used Python's PIL (`Pillow`) library to open the image, compute its aspect ratio, downscale it to fit a strict bounding box size (`IMAGE_W = 30mm`, `MAX_IMAGE_H = 35mm`), and write the bytes to a local temporary file before drawing.
  - If the download failed or the item had no image, it rendered a light-grey placeholder box saying *"No Image"*.
  - Temporary files were cleaned up after generation.
- **Rupee / Hindi Font:** Loaded a custom local TrueType font file (`assets/fonts/HindiFont.ttf`) to support rendering Hindi text and the Rupee symbol (`₹`) without encoding errors.
- **Sharing Mechanism:**
  1. Saved the generated PDF locally in the app data storage folder.
  2. Uploaded the PDF file to a Supabase storage bucket (`product-images`) using `db.upload_pdf()`.
  3. Created a formatted text message with the Supabase public PDF URL.
  4. Opened WhatsApp via a standard launcher URL (`https://wa.me/?text=...`) to let the user share the link.

---

## 2. Exact Fields Included in Legacy PDF ("Karigar Slip")

Because the old PDF was designed strictly as a **Karigar Slip (production/artisan sheet)** for factory workers, it **did not show any prices, line totals, or payment summaries**. The fields included were:

- **Header:**
  - Business Name ("Mahalaxmi Bangles") & document title ("Karigar Slip").
  - Order ID.
  - Customer / Shop Name.
  - Order Date.
- **Metadata Card:**
  - Color.
  - Grind / Finish.
  - Box Type.
  - Order-level Notes (Additional Info).
- **Item Cards (repeating block):**
  - Item Number.
  - Product Image or placeholder.
  - Item-level Notes.
  - Sized quantities box (`2.2`, `2.4`, `2.6`, `2.8`, `2.10` counts) if sized.
  - Flat quantity count (e.g. `Qty: X`) if non-sized.
- **Footer:**
  - Total items count.
  - Sign-off line: "Authorized Signature".

---

## 3. Recommended Flutter PDF Variants

For the Flutter migration, we will create three distinct, role-based PDF layouts using a shared service. In accordance with the business decisions, all variants are English-only and use standard alphanumeric formatting without native currency symbol glyphs:

### A. Customer Confirmation PDF
- **Purpose:** Sent to customers for order verification, details confirmation, and billing record.
- **Contents:**
  - Business Name header & logo.
  - Order ID & date.
  - Customer Shop Name.
  - Order status.
  - Item lines (item number, size quantities, color, notes).
  - **Unit Price** and **Line Totals** formatted with prefix **`INR `** (e.g., `INR 1,200`). **Do not use the `₹` symbol.**
  - **Grand Total** formatted with prefix **`INR `**.
  - Footer note: *"Please confirm if any changes are required."*

### B. Admin Internal PDF
- **Purpose:** Used by administrators for record-keeping and complete order review.
- **Contents:**
  - All fields from the Customer PDF (with pricing formatted as **`INR `**). **Do not use the `₹` symbol.**
  - Customer Mobile number.
  - Customer ID.
  - Admin-only details if needed (e.g. internal notes, billing reference).

### C. Labour / Production PDF (Karigar Slip)
- **Purpose:** Given to factory workers to assemble the order.
- **Contents:**
  - Order ID & date.
  - Item lines (item number, size quantities, color, notes).
  - **Hides all financial values** (no pricing, line totals, or grand totals).
  - **Hides customer contact details** (keeps only the shop name for identification).
  - Fully in English.

---

## 4. Recommended Packages

To implement this functionality cleanly in Flutter across Android, iOS, and Web targets, the following packages are recommended:

1. **`pdf` (latest compatible version):**
   - **Reason:** Standard pure-Dart PDF creation library. Allows building layouts programmatically using standard widgets like `pw.Column`, `pw.Row`, `pw.Table`, and `pw.Paragraph`.
2. **`printing` (latest compatible version):**
   - **Reason:** Exposes `Printing.sharePdf(...)` which launches the platform's **native Share Sheet** with the raw PDF bytes. This eliminates the need to upload files to Supabase or manually write files to disk before sharing on mobile devices, and avoids local storage permission prompts.
3. **`path_provider` (latest compatible version):**
   - **Reason:** Required to retrieve temp directories if local caching or disk writing is needed (Phase 2+).
4. **`http` or shared HTTP utility:**
   - **Reason:** Required in Phase PDF-2 to download image bytes from Supabase storage URLs to draw them in the PDF.

---

## 5. Suggested Shared Architecture

We will implement the generation logic in a centralized service inside `mahalaxmi_shared` so both apps can reuse it:

- **Shared Package (`mahalaxmi_shared`):**
  - **New File:** `lib/services/order_pdf_service.dart`.
  - **Font Choice:** Uses the standard default Helvetica font built into the PDF standard. This avoids bundling custom TrueType font (`.ttf`) files (like `HindiFont.ttf`) in Phase PDF-1, preventing all encoding/font load bugs. Custom fonts are deferred as an optional future enhancement.
  - **Exposed API:**
    ```dart
    class OrderPdfService {
      static Future<Uint8List> generateCustomerPdf(Order order) async { ... }
      static Future<Uint8List> generateAdminPdf(Order order) async { ... }
      static Future<Uint8List> generateLabourPdf(Order order) async { ... }
    }
    ```
- **Admin App (`mahalaxmi_admin`):**
  - Tapping **Share PDF** in `OrderDetailPage` will show a dialog prompting the user to choose: **Customer Confirmation**, **Karigar Slip (Labour)**, or **Admin Internal**.
  - Calls `OrderPdfService` to generate bytes, then uses `Printing.sharePdf(bytes: pdfBytes, filename: 'order_${order.orderId}.pdf')` to trigger the system share sheet.
- **Customer App (`mahalaxmi_customer`):**
  - Tapping **Share PDF** in `MyOrdersPage` or on the order success screen will directly trigger `generateCustomerPdf(...)` and open the share sheet.

---

## 6. Known Risks & Technical Concerns

1. **Images in PDF:**
   - *Risk:* Fetching image URLs synchronously over the network during PDF generation can fail due to timeouts, invalid links, or offline usage.
   - *Mitigation:* In Phase PDF-1, we bypass this risk completely by generating **text-only and image-free** documents. In Phase PDF-2, network loading will be introduced with strong error catch safeguards and offline fallbacks.
2. **Rupee Symbol / Font Encoding:**
   - *Mitigation:* We bypass this risk completely by using standard alphanumeric English characters and the **`INR `** currency prefix rather than the unicode `₹` symbol, which works natively on built-in PDF fonts.
3. **PDF File Size:**
   - *Mitigation:* Text-only PDFs are extremely lightweight (typically <50KB), ensuring fast generation, instant uploads, and minimal network data usage.
4. **Data Safety / Fallbacks:**
   - *Mitigation:* The service must handle missing or null fields gracefully (e.g. using `shopName.isEmpty ? '-' : shopName`) rather than throwing null pointer exceptions and failing the generation. It must rely on the existing `lineTotal` business logic verified in calculations.

---

## 7. Phased Implementation Plan

The PDF implementation will be split into the following sequential phases:

### Phase PDF-1: Text-Only PDF Generation & Sharing (Simplified)
- Add `pdf` and `printing` to dependencies.
- Implement `OrderPdfService` in `mahalaxmi_shared` utilizing default built-in fonts (Helvetica).
- Format all prices using the `INR <amount>` convention (e.g. `INR 1500`). **Do not use the `₹` symbol.**
- Do not use Hindi/Rupee font in Phase PDF-1; keep Labour/Karigar slip English-only.
- Create three text-only layouts:
  1. **Customer Confirmation PDF** (with pricing as `INR`).
  2. **Admin Internal PDF** (with pricing as `INR` + customer details).
  3. **Labour/Karigar Slip** (no pricing, English-only).
- Add variant selector sheet in Admin `OrderDetailPage`.
- Add customer confirmation trigger in Customer `MyOrdersPage` and order success dialog.
- Open share dialog using the native share sheet (`Printing.sharePdf`) directly:
  - Do not upload PDF to Supabase initially.
  - Avoid any storage permission complexity.
- Ensure that if any field is missing, a blank or dash is shown rather than crashing.
- Respect existing `OrderItem.lineTotal` logic and correctly support both size-based and quantity-based items.

### Phase PDF-2: Add Product Images
- Implement asynchronous image downloading inside `OrderPdfService`.
- Add robust error catching for network images (offline fallbacks).
- Compress image sizes to keep generated PDF files compact.

### Phase PDF-3: Polish & Enhancements (Only If Needed)
- Add preview screens inside the apps using the `printing` package's `PdfPreview` widget.
- Add direct "Save to Downloads" action button on web environments.
- Introduce custom fonts as optional future enhancement only if needed.
