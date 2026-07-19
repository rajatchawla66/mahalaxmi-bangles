# Audit Report: Image Upload, Display Infrastructure, and Uniform Image Policy

This document audits the current image upload and rendering infrastructure across the Mahalaxmi Bangles Flutter apps (Customer and Admin) and details the proposed uniform image policy, package evaluations, implementation phases, and integration risks.

---

## 1. Current Image Infrastructure Summary

The current apps handle images using Supabase Storage and simple Flutter image rendering:
- **Storage Backend:** Supabase Storage bucket named `product-images`.
- **Upload logic:** Centralized in the `StorageService` class (`mahalaxmi_admin/lib/services/storage_service.dart`). It handles two categories of uploads:
  - **Category Covers:** Path `category_covers/$slug.$ext`.
  - **Product Items:** Path `items/$slug.$ext`.
- **Processing on Upload:** Images are uploaded **raw** (as uncompressed, uncropped `Uint8List` bytes read from picked files). No resizing, quality compression, sharpening, or format conversion (e.g. converting PNG/WebP to JPEG) is performed in Dart/Flutter.
- **On-Device Selection Limit:** Uses the standard `ImagePicker` plugin, which applies basic maximum constraints (`maxWidth: 1080`, `maxHeight: 1350`) natively on-device, but does not enforce a specific aspect ratio or quality compression level.
- **Cropping Support:** None. Currently, no cropping interface exists, meaning users cannot adjust which part of the image is uploaded.
- **Image Editing/Updates:** Currently, there is **no capability** to update or change an image in the Admin Item Edit page (`item_edit_page.dart`). Images can only be set during item creation in `add_item_page.dart`.

---

## 2. Current Image Storage Paths

The current file paths inside the Supabase `product-images` storage bucket are:
1. **Product / Item Images:** 
   - Path: `items/<item_number_slug>.<file_extension>`
   - Example: `items/101.jpg` or `items/chuda_design_2.png`
2. **Category Cover Images:** 
   - Path: `category_covers/<category_slug>.<file_extension>`
   - Example: `category_covers/chuda.jpg` or `category_covers/metal_bangles.png`

*Note: The file extension matches the original file picked by the user, making it less predictable than a standard standardized `.jpg` format.*

---

## 3. Current Display Dimensions & Aspect Ratios

Product and category images are displayed across the apps using different styles and fits:

| Screen / Area | Layout Context & Constraints | BoxFit & Fit Behavior |
| :--- | :--- | :--- |
| **Customer Dashboard** | GridView cell with `childAspectRatio: 0.72` | `BoxFit.cover` (Expanded widget; crops standard images to square-ish proportions depending on the card's width/height ratio). |
| **Customer Category Grid** | GridView cell with `childAspectRatio: 0.65` | `BoxFit.cover` (Expanded widget with `flex: 3`; crops standard images vertically to fit the vertical card). |
| **Customer Item Detail** | Container with a fixed `height: 360` and full width | `BoxFit.cover` (Crops standard images to fit a wide banner style). |
| **Customer Detail Zoom-in** | Popup Dialog with `InteractiveViewer` | `BoxFit.contain` (Displays original image without cropping, allowing pinch/zoom). |
| **Admin Category List** | ListTile leading widget with `width: 56`, `height: 56` | `BoxFit.cover` (Crops to 1:1 square). |
| **Admin Item List** | Row item thumbnail with `width: 56`, `height: 56` | `BoxFit.cover` (Crops to 1:1 square). |
| **Admin Item Edit Screen** | Top preview with `height: 200` and full width | `BoxFit.cover` (Crops standard images to fit a wide banner style). |
| **PDF Order Share** | Left Column container with `width: 220`, `height: 160` | `BoxFit.contain` (Fits the image inside the 220x160 bounding box without cropping). |

---

## 4. Current PDF Image Handling

In the recently updated Phase 2 PDF implementation:
- **Download Guard:** Dynamically downloads product images from Supabase storage URLs with a 5-second timeout.
- **On-Device Compression:** In `OrderPdfService._compressImage`, images exceeding `400` pixels in width or height are resized to `400x400` using the pure-Dart `image` package and encoded as JPEG at **80% quality**.
- **Display Layout:** The item card uses a two-column card layout, placing the product image in a `220x160` white card on the left with `BoxFit.contain`.
- **Placeholder:** Renders a light-grey `"No Image"` box if the item has no image or the download fails/times out.

---

## 5. Problems Identified

1. **Inconsistent Aspect Ratios:** Product images are stretched/cropped in 1:1 (list thumbnails), vertical rectangles (customer grids), wide landscape banners (detail page/edit page), and custom rectangles (PDF). This causes critical bangle details (design patterns, borders, sets) to be cut off unpredictably.
2. **Exif Rotation Issues:** Raw uploads do not strip Exif metadata. Depending on the device's camera orientation, some images may display rotated 90 or 180 degrees.
3. **No Crop Control:** Users cannot choose the focus area of the photo. Because bangle photos are highly detailed, auto-cropping blindly (e.g., center-crop) can cut off the ends of the bangles or decorative boxes.
4. **No Upload Compression/Formatting:** Users can upload massive original device camera photos (4MB+ PNG/HEIC) directly, consuming excessive Supabase storage bandwidth, slowing down PDF downloads, and delaying dashboard loading times.
5. **No Edit/Update Capability:** Once an item is added, admins have no way to replace or add an image for that item without deleting and recreating it.
6. **PDF Pattern Blurriness:** The current 400px limit on PDF images, while good for PDF file sizes, may make intricate bangle designs slightly blurry on high-resolution displays or when zoomed in.

---

## 6. Recommended Uniform Image Policy

To resolve these issues, we recommend standardizing on a uniform image policy:

### A. Product / Item Images
- **Aspect Ratio:** **4:3 landscape** (Provides enough horizontal width to display bangle sets and designs clearly).
- **Target Resolution:** **1200 × 900 px** (Maintains high-density clarity for details).
- **Minimum Accepted Resolution:** **800 × 600 px**.
- **File Format:** **JPEG (.jpg)** (All uploads must be converted to JPEG to standardize paths and reduce size).
- **Quality Setting:** **88% JPEG Compression** (Provides excellent clarity with optimized file size, typically under 180KB).
- **Use Cases:** Customer item grids, item detail page, admin catalogue list, admin item edit preview, and PDF share.

### B. Category Cover Images
- **Aspect Ratio:** **16:9 landscape** (Optimized for banners and promotional cards).
- **Target Resolution:** **1280 × 720 px**.
- **Minimum Accepted Resolution:** **960 × 540 px**.
- **File Format:** **JPEG (.jpg)**.
- **Quality Setting:** **85% JPEG Compression** (Banners require slightly less detail density than products, keeping file size under 120KB).
- **Use Cases:** Customer dashboard category cards, admin category list.

### C. PDF Sizing & Quality
- **Source:** Use the standard 4:3 product image.
- **Internal PDF Compression:** Downscale to **600 px width** (replaces 400px limit) with **82% quality** to preserve intricate bangle patterns while keeping total PDF file size under 250KB.

---

## 7. UI Display Standards

We recommend configuring UI widgets to respect the aspect ratio rules instead of using generic cropping:

1. **Customer Item Grid:** Render cards with a fixed 4:3 aspect ratio container for the image section (`BoxFit.cover`), ensuring vertical consistency.
2. **Customer Item Detail Page:** Show the product image inside a `pw.AspectRatio` or custom container matching a 4:3 ratio with `BoxFit.cover` or `BoxFit.contain`.
3. **Admin Item List:** Keep thumbnails bounded to a 4:3 ratio card.
4. **Admin Item Edit Preview:** Show the preview in a 4:3 box.
5. **Category Cards (Dashboard):** Wrap category cover images in a 16:9 ratio layout container.

---

## 8. Package Evaluation

We evaluated packages for cropping and processing support:

1. **`image_cropper` (Native Wrapper):**
   - *How it works:* Integrates native platform croppers (uCrop for Android, TOCropViewController for iOS, Cropper.js for Web).
   - *Pros:* Polished native experience, highly responsive.
   - *Cons:* Requires native configuration in `AndroidManifest.xml` and `Info.plist`, which complicates builds and can trigger theme mismatches. Web support requires manual JavaScript script/style imports in `index.html`.
2. **`crop_your_image` (Pure Flutter Widget):**
   - *How it works:* Renders cropping frames and interactions entirely inside Flutter widgets.
   - *Pros:* Fully cross-platform, zero native platform setups, looks and behaves identically on Android, iOS, and Web/PWA, easily embeddable into existing layouts or dialogs.
   - *Cons:* Basic UI controls (like "Rotate", "Crop", "Done" buttons) must be designed manually in the app layout.
3. **`image` (Dart Image Processing, already in use):**
   - Exposes robust APIs to crop, resize, sharpen, and encode bytes on-device in a background thread or asynchronous future.

**Recommendation:** We recommend using **`crop_your_image`** combined with the existing **`image`** package. It ensures zero Android build breakage, operates seamlessly on Web/PWA, and allows us to embed a unified Maroon-and-Gold themed crop sheet directly inside our Flutter apps.

---

## 9. Suggested Implementation Phases

We recommend implementing this policy in four progressive phases:

### Phase IMG-1: UI Standardization & Policy Definition
- Declare standardized aspect ratio constants (4:3 for items, 16:9 for covers) in the shared package.
- Update UI rendering across both customer and admin apps to enforce these aspect ratios (e.g. using `AspectRatio(aspectRatio: 4 / 3, child: ...)` widgets).
- Use placeholder gradients or fallback boxes uniformly when images are missing.
- Keep uploading raw bytes (no crop/compression yet).

### Phase IMG-2: Cropping & Compression on Upload (Admin App)
- Add the `crop_your_image` dependency to `mahalaxmi_admin`.
- Implement a Crop Modal inside `add_item_page.dart` (forcing 4:3) and `manage_categories_page.dart` (forcing 16:9).
- Integrate an image processing pipeline using the `image` package:
  1. Retrieve cropped image bytes.
  2. Re-orient based on Exif tags (`exif_transpose`).
  3. Resize to target size (1200x900 for items, 1280x720 for covers).
  4. Encode as JPEG at target quality (88% or 85%).
  5. Upload optimized bytes with `.jpg` file extension.

### Phase IMG-3: Catalogue Image Editing Support
- Update `item_edit_page.dart` to support updating/replacing product images.
- Integrate the Phase IMG-2 processing/cropping pipeline into this screen.

### Phase IMG-4: PDF Image Quality Boost & UI Cache
- Update `OrderPdfService` to compress downloaded product images to a maximum of 600px width (maintaining 4:3 ratio) at 82% quality to align with the new policy.
- Investigate caching solutions (like `CachedNetworkImage` or `flutter_cache_manager`) for the customer app if network image loading lag occurs.

---

## 10. Risks & Compatibility Notes

- **Legacy Images:** Existing images in Supabase Storage have various aspect ratios. Standardizing the UI to 4:3 or 16:9 layouts might result in legacy images appearing slightly cropped or padded. Using `BoxFit.cover` will avoid borders but might cut off details of uncropped legacy photos. This is acceptable as a transitional state until old items are replaced/updated.
- **Supabase Storage Size:** Restructuring current images is **not** required. We can maintain existing storage paths and begin writing new optimized images under the same folders. Standardizing the file extension to `.jpg` for new uploads will cause old links to remain valid while new links are fully normalized.
- **On-Device Memory Limits:** Processing 4K images on low-end Android devices in Dart using `package:image` can cause high memory usage. We should keep the picker's native `maxWidth` constraint (e.g., 1600px) active during image picking to restrict native memory consumption before processing.
