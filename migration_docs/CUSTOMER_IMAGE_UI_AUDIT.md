# Audit Report: Customer UI Image Display & Recommendations (Revised)

This document audits the customer application UI layout changes, details the business decisions regarding image layout, compares the results with the legacy Flet UI, and summarizes the newly implemented one-column product feed.

---

## 1. Business Decisions & Core Rationale

- **WhatsApp-Like Browsing Experience:** The core customer browsing flow has been changed from a two-column grid to a **one-column vertical product feed** of large cards. This replicates how customers typically review jewellery catalogues on WhatsApp—scrolling down a feed showing 1 to 1.5 item cards per viewport.
- **Priority of Visibility Over Density:** Product design clarity and pattern detail visibility are prioritized over showing multiple items at once.
- **Role of the Item Detail Page:** The item detail page is reserved primarily for **ordering configuration** (selecting sizes, selecting custom colors, entering quantities, and adding items to the cart), rather than serving as the only place to inspect the bangle design.
- **Defferred Cropping Policy:** The client-side image cropping and forced upload dimensions policy has been deferred until the new one-column UI feed is visually confirmed and reviewed by stakeholders.

---

## 2. Updated Customer Screen Layouts & Fits

We have revised the layouts to implement the one-column catalogue experience:

### A. Customer Dashboard (Category Cards)
- **Layout:** `GridView.builder` with `crossAxisCount: 2` (two columns) and `childAspectRatio: 0.72`.
- **Fitting Style:** Uses `BoxFit.cover`. The category names are located in a white card at the bottom of each tile.
- **Status:** Maintained as is, since category cards act as structural headers and are not meant for product inspection.

### B. Category Item List (Items Feed) — 🟢 RENEWED
- **Layout:** Replaced the two-column grid with a **one-column `ListView.separated`** with `16px` separator spacing.
- **Card Styling:** Rendered inside a clean white card with rounded corners (`borderRadius: 16`), elevated shadow, and gold/maroon subtle border borders (`#E0D5C0`).
- **Image Section:** Embedded as a full-width image container utilizing an **aspect ratio of 4:5 portrait** (`aspectRatio: 4 / 5`). This occupies the main visual space of the screen.
  - *Fitting style:* During transition, uses `BoxFit.cover` to fill the card dynamically. If a product image is horizontal, `BoxFit.cover` crops it cleanly.
- **Details Section:** Placed directly below the image (not side-by-side or overlaid):
  - Shop/Item number (secondary, `#757575`).
  - Item category name in bold slate text (`#212121`).
  - Item selling price formatted as `₹<amount>/set` in green.
  - Active Tag chips in a horizontal wrap list.
  - A full-width outlined button: **"Select Sizes & Order"** with Maroon branding text and border.
- **Navigation:** Tapping anywhere on the card or clicking the button routes to the item detail page.

### C. Product / Item Detail Page
- **Layout:** Single column scroll view.
- **Image Section:** Fixed `height: 360` with `BoxFit.cover` (which is zoomable via tap-to-fullscreen dialog).
- **Status:** Maintained. The detail page remains the checkout/order page for size/color entry.

---

## 3. Comparison with Legacy Flet UI

- **Flet Grid vs. Flutter ListView:** The old Flet app had a one-column vertical scroll view of cards with `height=350` and `fit=COVER`. The new Flutter feed uses an `aspectRatio: 4/5` card wrapper, which fits portrait screens even more consistently and renders larger images.
- **Visual Clarity:** The new one-column layout resolves the "cut-off bangle patterns" problem of the two-column grid by dedicating 100% of the screen width to the product card. Product designs are immediately visible during scrolling, exactly like WhatsApp attachments.

---

## 4. Answers to Core Questions

1. **For customer mobile portrait usage, what is the best product image ratio?**
   - **Recommendation:** **4:5 portrait** (or **3:4 portrait**). It maximizes screen real estate on vertical mobile layouts, aligning with modern social commerce feeds (e.g. WhatsApp, Instagram catalog).
2. **For category covers, what is the best ratio?**
   - **Recommendation:** **16:9 banner**.
3. **Should item grid and item detail use the same product image crop?**
   - **Yes.** Aligning both views to the same aspect ratio avoids formatting discrepancies.
4. **Should PDF use the same product image or a larger contain-fit version?**
   - **Same Image.** The PDF column uses a `220x160` box (~1.375 aspect ratio), which matches a 4:3 or standard crop well. 4:5 can be fitted using `BoxFit.contain` inside the PDF template.
5. **Would square product images cut bangle designs?**
   - **Yes.** Square crops cut off the end pieces of bangle sets.
6. **Would 4:3 images make mobile grid too short?**
   - In a one-column feed, 4:3 images would make cards slightly shorter, while 4:5 makes cards taller and emphasizes the designs more. 4:5 is visually preferred for the WhatsApp-like feel.
7. **Should product image display use BoxFit.cover or BoxFit.contain?**
   - **BoxFit.cover** is visually superior as it fills the card completely, but it requires admins to crop files correctly during upload. During the transition phase, `BoxFit.cover` is preferred to maintain a sleek, standardized UI card design.
8. **Should customer app offer tap-to-zoom everywhere?**
   - **Yes.** Enabled on the detail screen via fullscreen dialog.

---

## 5. Risks of Square vs. 4:3/4:5 Product Images

- **Square (1:1) Risks:** Crops the left/right sides of bangle boxes, causing loss of detail on set endpoints.
- **Portrait (4:5 / 3:4) Risks:** Since bangles are photographed horizontally, a portrait crop forces the photographer to include top/bottom empty space or crop the sides. During upload, admins must use the cropping tool to choose a centered view that displays the bangles clearly.
