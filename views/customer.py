import flet as ft
import db
import datetime
import os
import cache
from utils import *

# ============================================================
# CUSTOMER PIN LOGIN
# ============================================================

def view_customer_pin_login(page: ft.Page):
    state = page.state

    pin_input = ft.TextField(
        label="Enter 8-digit PIN",
        hint_text="PIN provided by shop",
        width=300,
        autofocus=True,
        keyboard_type=ft.KeyboardType.NUMBER,
        max_length=8,
        prefix_icon=ft.Icons.LOCK,
        text_align=ft.TextAlign.CENTER,
        border_radius=12,
        on_submit=lambda _: do_login(),
    )

    error_text = ft.Text("", color=ft.Colors.RED_600, size=13, visible=False)

    def do_login():
        pin = pin_input.value.strip()
        if len(pin) != 8 or not pin.isdigit():
            error_text.value = "Please enter a valid 8-digit PIN"
            error_text.visible = True
            page.update()
            return

        try:
            customer = db.get_customer_by_pin(pin)
        except Exception as e:
            error_text.value = f"Connection error: {e}"
            error_text.visible = True
            page.update()
            return

        if not customer:
            error_text.value = "Invalid PIN — customer not found"
            error_text.visible = True
            page.update()
            return

        if not customer.get("is_active", True):
            error_text.value = "This account has been blocked. Contact the shop."
            error_text.visible = True
            page.update()
            return

        # Success — set session
        state["role"] = "customer"
        state["customer_id"] = customer["id"]
        state["customer_shop_name"] = customer.get("shop_name", "")
        state["username"] = customer.get("shop_name", "")
        state["customer_mobile"] = customer.get("mobile", "")
        state["customer_cart"] = []

        # Update last_active_at
        try:
            db.set_customer_last_active(customer["id"])
        except Exception:
            pass

        # Save session
        import session_helper
        session_helper.save_session(state)

        page.go("customer_dashboard")

    return ft.Container(
        expand=True,
        padding=24,
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=16,
            controls=[
                ft.Icon(ft.Icons.STORE, size=60, color=ft.Colors.INDIGO_600),
                ft.Text("Welcome to Mahalaxmi Bangles", size=20, weight="bold"),
                ft.Text("Enter your shop PIN to continue", color=ft.Colors.GREY_600),
                pin_input,
                error_text,
                ft.FilledButton("Login", on_click=lambda _: do_login(), width=200),
            ]
        )
    )

# ============================================================
# CATEGORY GRID (NEW DASHBOARD)
# ============================================================

def view_customer_dashboard(page: ft.Page):
    """Main customer entry grid showing categories — portrait tiles 2-per-row."""
    state = page.state

    # --- Data Loading Strategy: Fetch Once ---
    if state.get("customer_full_catalogue") is None:
        if cache.is_cache_available():
            raw = cache.get_cached_catalog()
            state["customer_full_catalogue"] = [it for it in raw if it.get("is_available", 1)]
            state["customer_categories"] = cache.get_cached_categories()
        else:
            state["customer_full_catalogue"] = db.get_customer_catalogue()
            state["customer_categories"] = db.get_categories(active_only=True)

    catalog = state["customer_full_catalogue"] or []
    categories = state["customer_categories"] or []

    # Calculate item counts per category in-memory
    counts = {}
    for it in catalog:
        cat_name = it.get("category", "Uncategorized")
        counts[cat_name] = counts.get(cat_name, 0) + 1

    # Build first-item-image lookup per category (fallback for missing cover)
    cat_first_image = {}
    for it in catalog:
        cname = it.get("category")
        if cname and it.get("image_url") and cname not in cat_first_image:
            cat_first_image[cname] = it["image_url"]

    # --- Search Handler ---
    def on_search_change(_):
        query = search_tf.value.strip()
        state["customer_search_query"] = query
        if len(query) >= 3:
            page.go("customer_search_results")

    def clear_search(_):
        search_tf.value = ""
        state["customer_search_query"] = ""
        page.update()

    search_tf = ft.TextField(
        value=state.get("customer_search_query", ""),
        hint_text="Search 500+ items...",
        prefix_icon=ft.Icons.SEARCH,
        border_radius=20,
        height=48,
        on_change=on_search_change,
        expand=True,
        suffix=ft.IconButton(ft.Icons.CLEAR, on_click=clear_search)
    )

    # --- Build Category Tiles (Portrait 3:4, 2 per row) ---
    sw = page.width or 360
    tile_w = (sw - 32 - 12) // 2  # 16px padding each side, 12px gap
    tile_h = int(tile_w * 4 / 3)  # 3:4 portrait ratio

    cat_tiles = []
    for cat in categories:
        cname = cat["name"]
        item_count = counts.get(cname, 0)
        if item_count == 0:
            continue

        # Cover image: category cover → first-item image → monogram
        cover_url = cat.get("cover_image_url") or cat_first_image.get(cname)

        def on_cat_click(e, c=cat):
            state["customer_selected_category"] = c["name"]
            state["customer_selected_subcategory"] = None
            subs_str = c.get("sub_categories", "").strip()
            if subs_str:
                state["customer_subcategories"] = [s.strip() for s in subs_str.split(",") if s.strip()]
                page.go("customer_subcategories")
            else:
                state["customer_subcategories"] = []
                page.go("customer_items")

        if cover_url:
            bg = ft.Image(src=cover_url, fit=ft.ImageFit.COVER, expand=True)
        else:
            initial = cname[0].upper() if cname else "?"
            bg = ft.Container(
                gradient=ft.LinearGradient(
                    colors=[ft.Colors.INDIGO_50, ft.Colors.INDIGO_100],
                    begin=ft.Alignment(-1, -1), end=ft.Alignment(1, 1)
                ),
                expand=True,
                alignment=ft.alignment.center,
                content=ft.Text(initial, size=44, weight=ft.FontWeight.W_200, color=ft.Colors.INDIGO_300),
            )

        tile = ft.Container(
            on_click=on_cat_click,
            width=tile_w,
            height=tile_h,
            border_radius=16,
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            border=ft.border.all(1, ft.Colors.GREY_200),
            content=ft.Stack([
                ft.Container(content=bg, left=0, top=0, right=0, bottom=0),
                ft.Container(
                    left=0, top=0, right=0, bottom=0,
                    gradient=ft.LinearGradient(
                        colors=[ft.Colors.TRANSPARENT, ft.Colors.with_opacity(0.87, ft.Colors.BLACK)],
                        begin=ft.Alignment(0, 0.35), end=ft.Alignment(0, 1),
                    ),
                ),
                ft.Container(
                    padding=10, alignment=ft.alignment.bottom_left,
                    content=ft.Column([
                        ft.Text(cname, size=14, weight="bold", color=ft.Colors.WHITE),
                    ], spacing=0, tight=True),
                ),
                ft.Container(
                    padding=ft.Padding(7, 2, 7, 2),
                    bgcolor=ft.Colors.with_opacity(0.85, ft.Colors.WHITE),
                    border_radius=10,
                    top=8, right=8,
                    content=ft.Text(f"{item_count}", size=11,
                                    weight=ft.FontWeight.W_600, color=ft.Colors.GREY_800),
                ),
            ]),
        )
        cat_tiles.append(tile)

    # --- Layout: manual rows of 2 (no ResponsiveRow) ---
    rows = []
    for i in range(0, len(cat_tiles), 2):
        pair = cat_tiles[i:i+2]
        rows.append(ft.Row(controls=pair, spacing=12))

    return ft.ListView(
        expand=True, padding=16, spacing=20,
        controls=[
            ft.Text(f"Namaste, {state['username']}!", size=18, weight=ft.FontWeight.W_500),
            ft.Row([search_tf, ft.IconButton(ft.Icons.ARROW_FORWARD,
                     on_click=lambda _: on_search_change(None))], spacing=10),
            ft.Text("Browse Categories", size=20, weight="bold"),
            *rows,
            ft.Container(height=40),
        ],
    )

# ============================================================
# SUBCATEGORY GRID
# ============================================================

def view_customer_subcategories(page: ft.Page):
    state = page.state
    category = state.get("customer_selected_category")
    subs = state.get("customer_subcategories", [])
    catalog = state.get("customer_full_catalogue", [])

    if not category:
        page.go("customer_dashboard")
        return ft.Container()

    # Calculate item counts per subcategory
    sub_counts = {}
    sub_covers = {} # Use first item image as cover
    for it in catalog:
        if it.get("category") == category:
            sub_name = it.get("sub_category")
            if sub_name:
                sub_counts[sub_name] = sub_counts.get(sub_name, 0) + 1
                if sub_name not in sub_covers and it.get("image_url"):
                    sub_covers[sub_name] = it["image_url"]

    # --- Build Cards ---
    sub_cards = []
    
    # 1. "View All" Option
    def on_all_click(_):
        state["customer_selected_subcategory"] = None
        page.go("customer_items")

    sub_cards.append(
        ft.Container(
            on_click=on_all_click,
            height=100,
            border_radius=12,
            bgcolor=ft.Colors.INDIGO_50,
            border=ft.border.all(1, ft.Colors.INDIGO_100),
            padding=16,
            content=ft.Row([
                ft.Icon(ft.Icons.GRID_VIEW_ROUNDED, color=ft.Colors.INDIGO_600, size=30),
                ft.Column([
                    ft.Text(f"All {category}", size=15, weight="bold", color=ft.Colors.INDIGO_700),
                    ft.Text("View full collection", size=11, color=ft.Colors.GREY_600)
                ], spacing=2, expand=True)
            ])
        )
    )

    # 2. Specific Subcategories
    grid_items = []
    for sname in subs:
        count = sub_counts.get(sname, 0)
        if count == 0: continue
        
        cover = sub_covers.get(sname)
        
        def make_click(sn):
            def _h(_):
                state["customer_selected_subcategory"] = sn
                page.go("customer_items")
            return _h

        grid_items.append(
            ft.Container(
                on_click=make_click(sname),
                border_radius=12,
                clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
                height=140,
                content=ft.Stack([
                    # Background image/fallback
                    ft.Container(
                        content=ft.Image(src=cover, fit=ft.ImageFit.COVER, expand=True) if cover else 
                                 ft.Container(bgcolor=ft.Colors.GREY_200, expand=True),
                        left=0, top=0, right=0, bottom=0
                    ),
                    # Dark overlay
                    ft.Container(
                        left=0, top=0, right=0, bottom=0,
                        gradient=ft.LinearGradient(
                            colors=[ft.Colors.TRANSPARENT, ft.Colors.with_opacity(0.87, ft.Colors.BLACK)],
                            begin=ft.Alignment(0, 0.2), end=ft.Alignment(0, 1)
                        )
                    ),
                    ft.Container(
                        padding=10, alignment=ft.alignment.bottom_left,
                        content=ft.Column([
                            ft.Text(sname, size=14, weight="bold", color=ft.Colors.WHITE),
                            ft.Text(f"{count} items", size=10, color=ft.Colors.with_opacity(0.7, ft.Colors.WHITE)),
                        ], spacing=0, tight=True)
                    )
                ])
            )
        )

    return ft.ListView(
        expand=True, padding=16, spacing=15,
        controls=[
            ft.Text(category, size=24, weight="bold"),
            sub_cards[0], # View All
            ft.ResponsiveRow(columns={"xs": 1, "sm": 12},
                controls=[ft.Column([it], col={"xs": 1, "sm": 4}) for it in grid_items],
                spacing=12,
                run_spacing=12,
            )
        ]
    )

# ============================================================
# SHARED ITEM CARD BUILDER
# ============================================================

def _build_item_card(item, on_view_details):
    """Build a one-column product card (shared by items grid and search)."""
    img_url = item.get("image_url")

    if img_url:
        img = ft.Container(
            width=110, height=110,
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            border_radius=8,
            content=ft.Image(
                src=img_url, width=110, height=110, fit=ft.ImageFit.COVER,
                error_content=ft.Container(
                    width=110, height=110, bgcolor=ft.Colors.GREY_100,
                    alignment=ft.alignment.center,
                    content=ft.Icon(ft.Icons.IMAGE_NOT_SUPPORTED, color=ft.Colors.GREY_400, size=24),
                ),
            ),
        )
    else:
        img = ft.Container(
            width=110, height=110, bgcolor=ft.Colors.GREY_100,
            border_radius=8, alignment=ft.alignment.center,
            content=ft.Icon(ft.Icons.IMAGE_NOT_SUPPORTED, color=ft.Colors.GREY_400, size=24),
        )

    badges = []
    if bool(item.get("has_sizes", 0)):
        badges.append(ft.Container(
            padding=ft.Padding(5, 1, 5, 1),
            bgcolor=ft.Colors.AMBER_50, border_radius=3,
            content=ft.Text("Multiple Sizes", size=9, color=ft.Colors.AMBER_800, weight=ft.FontWeight.W_500),
        ))
    if bool(item.get("has_color", 0)):
        badges.append(ft.Container(
            padding=ft.Padding(5, 1, 5, 1),
            bgcolor=ft.Colors.PURPLE_50, border_radius=3,
            content=ft.Text("Colors Available", size=9, color=ft.Colors.PURPLE_700, weight=ft.FontWeight.W_500),
        ))

    return ft.Container(
        border_radius=12, bgcolor=ft.Colors.WHITE,
        border=ft.border.all(1, ft.Colors.GREY_200),
        padding=10,
        content=ft.Row([
            img,
            ft.Column([
                ft.Text(item.get("item_number", ""), size=11, color=ft.Colors.GREY_400),
                ft.Text(f"₹{item.get('selling_price', 0)}", size=20,
                        color=ft.Colors.GREEN_700, weight=ft.FontWeight.W_700),
                ft.Row(badges, spacing=4) if badges else ft.Container(height=0),
                ft.FilledButton(
                    "View Details",
                    on_click=on_view_details,
                    height=32,
                    style=ft.ButtonStyle(
                        shape=ft.RoundedRectangleBorder(radius=8),
                        bgcolor=ft.Colors.BLUE_900,
                        color=ft.Colors.WHITE,
                    ),
                ),
            ], spacing=4, expand=True),
        ], alignment=ft.MainAxisAlignment.START, spacing=12),
    )


# ============================================================
# ITEM GRID (One-Column Redesign)
# ============================================================

def view_customer_items(page: ft.Page):
    state = page.state
    catalog = state.get("customer_full_catalogue", [])
    category = state.get("customer_selected_category")
    subcategory = state.get("customer_selected_subcategory")

    if not category:
        page.go("customer_dashboard")
        return ft.Container()

    items = []
    for it in catalog:
        if it.get("category") == category:
            if not subcategory or it.get("sub_category") == subcategory:
                items.append(it)

    item_cards = []
    for it in items:
        def on_details(e, item=it):
            state["customer_selected_item"] = item
            page.go("item_detail")
        item_cards.append(_build_item_card(it, on_details))

    return ft.ListView(
        expand=True,
        padding=16,
        spacing=12,
        controls=item_cards if item_cards else [
            ft.Container(
                expand=True, padding=40, alignment=ft.alignment.center,
                content=ft.Text("No items found", color=ft.Colors.GREY_500),
            ),
        ],
    )


# ============================================================
# SEARCH RESULTS (Reuses same card style)
# ============================================================

def view_customer_search(page: ft.Page):
    state = page.state
    catalog = state.get("customer_full_catalogue", [])

    results_header = ft.Text(size=15, weight="bold")
    results_list = ft.ListView(expand=True, padding=16, spacing=12)

    def update_results(query: str):
        query = query.lower().strip()
        if not query:
            page.go("customer_dashboard")
            return

        filtered = [i for i in catalog if
            query in (i.get("item_number") or "").lower() or
            query in (i.get("category") or "").lower() or
            query in (i.get("sub_category") or "").lower()]

        cards = []
        for it in filtered:
            def on_details(e, item=it):
                state["customer_selected_item"] = item
                page.go("item_detail")
            cards.append(_build_item_card(it, on_details))

        results_header.value = f"Results for '{query}' ({len(filtered)})"
        results_list.controls = cards if cards else [
            ft.Container(
                expand=True, padding=40, alignment=ft.alignment.center,
                content=ft.Column([
                    ft.Icon(ft.Icons.SEARCH_OFF, size=60, color=ft.Colors.GREY_300),
                    ft.Text(f"No results for '{query}'", color=ft.Colors.GREY_600),
                ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10),
            ),
        ]
        page.update()

    def on_search_change(e):
        state["customer_search_query"] = search_tf.value
        update_results(search_tf.value)

    search_tf = ft.TextField(
        value=state.get("customer_search_query", ""),
        hint_text="Search items...",
        prefix_icon=ft.Icons.SEARCH,
        border_radius=20,
        height=48,
        on_change=on_search_change,
        expand=True,
        autofocus=True,
        suffix=ft.IconButton(ft.Icons.CLEAR, on_click=lambda _: update_results("")),
    )

    update_results(state.get("customer_search_query", ""))

    return ft.Column(
        expand=True,
        controls=[
            ft.Container(padding=16, content=ft.Row([search_tf], spacing=10)),
            ft.Container(padding=ft.Padding(16, 0, 16, 8), content=results_header),
            results_list,
        ],
    )

# ============================================================
# ITEM DETAIL & CART (MAINTAINED)
# ============================================================

def view_item_detail(page: ft.Page):
    """Detail view for a selected catalogue item — premium B2B redesign."""
    state = page.state
    item = state.get('customer_selected_item')
    if not item:
        page.go('customer_dashboard')
        return ft.Container()

    has_sizes = bool(item.get('has_sizes', 0))
    has_color = bool(item.get('has_color', 0))

    # ─── Helper: QtyStepper ────────────────────────────────────────
    class QtyStepper:
        """Plain Python helper — NOT a Flet Control subclass.
        Exposes .value (str) for add_to_cart() compatibility.
        """
        def __init__(self, size_label, initial=0, on_change=None):
            self._val = initial
            self._on_change = on_change

            self.qty_text = ft.Text(
                str(self._val), size=16, weight=ft.FontWeight.W_600,
                width=32, text_align=ft.TextAlign.CENTER,
            )

            def on_minus(e):
                if self._val > 0:
                    self._val -= 1
                    self.qty_text.value = str(self._val)
                    self.qty_text.update()
                    if self._on_change:
                        self._on_change()

            def on_plus(e):
                self._val += 1
                self.qty_text.value = str(self._val)
                self.qty_text.update()
                if self._on_change:
                    self._on_change()

            self.row = ft.Row(
                controls=[
                    ft.Container(
                        width=48,
                        content=ft.Text(
                            size_label, weight=ft.FontWeight.W_600, size=14,
                        ),
                    ),
                    ft.IconButton(
                        ft.Icons.REMOVE_CIRCLE_OUTLINE, icon_size=22,
                        icon_color=ft.Colors.BLUE_900, on_click=on_minus,
                    ),
                    self.qty_text,
                    ft.IconButton(
                        ft.Icons.ADD_CIRCLE_OUTLINE, icon_size=22,
                        icon_color=ft.Colors.BLUE_900, on_click=on_plus,
                    ),
                ],
                alignment=ft.MainAxisAlignment.START,
                spacing=2,
            )

        @property
        def value(self):
            return str(self._val)

    # ─── Summary controls (declared early for closure capture) ─────
    summary_sets_text = ft.Text("0", size=16, weight=ft.FontWeight.W_700)
    summary_amount_text = ft.Text(
        "₹0", size=16, weight=ft.FontWeight.W_700, color=ft.Colors.GREEN_700,
    )
    cta_qty_text = ft.Text(
        "0 sets", size=13, color=ft.Colors.GREY_700, weight=ft.FontWeight.W_500,
    )
    cta_amount_text = ft.Text(
        "₹0", size=15, weight=ft.FontWeight.W_700, color=ft.Colors.GREEN_700,
    )

    # ─── Image section ─────────────────────────────────────────────
    img_url = item.get("image_url")
    image_section = None
    if img_url:
        image_section = ft.Container(
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            border_radius=16,
            shadow=ft.BoxShadow(
                spread_radius=0, blur_radius=8,
                color=ft.Colors.with_opacity(0.1, ft.Colors.BLACK),
                offset=ft.Offset(0, 4),
            ),
            content=ft.Image(
                src=img_url, height=300, width=float('inf'),
                fit=ft.ImageFit.COVER, border_radius=16,
                error_content=ft.Container(
                    height=300, bgcolor=ft.Colors.GREY_100,
                    alignment=ft.alignment.center,
                    content=ft.Icon(
                        ft.Icons.IMAGE_NOT_SUPPORTED, size=48,
                        color=ft.Colors.GREY_400,
                    ),
                ),
            ),
        )

    # ─── Product info card ─────────────────────────────────────────
    category = item.get('category', '')
    subcategory = item.get('sub_category', '')
    breadcrumb = f"{category} > {subcategory}" if subcategory else category

    info_card = ft.Container(
        border_radius=12, bgcolor=ft.Colors.WHITE,
        border=ft.border.all(1, ft.Colors.GREY_200),
        padding=16,
        content=ft.Row([
            ft.Column([
                ft.Text(
                    item.get("item_number", "—"),
                    size=20, weight=ft.FontWeight.W_700,
                ),
                ft.Container(
                    padding=ft.Padding(8, 3, 8, 3),
                    bgcolor=ft.Colors.BLUE_50,
                    border_radius=4,
                    content=ft.Text(
                        breadcrumb, size=11, color=ft.Colors.BLUE_700,
                        weight=ft.FontWeight.W_500,
                    ),
                ),
            ], spacing=8),
            ft.Column([
                ft.Text(
                    f"₹{item.get('selling_price', 0)}", size=22,
                    color=ft.Colors.GREEN_700, weight=ft.FontWeight.W_700,
                    text_align=ft.TextAlign.RIGHT,
                ),
                ft.Text(
                    "/set", size=12, color=ft.Colors.GREY_500,
                    text_align=ft.TextAlign.RIGHT,
                ),
            ], spacing=0, horizontal_alignment=ft.CrossAxisAlignment.END),
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
    )

    # ─── Color dropdown ────────────────────────────────────────────
    color_dd = None
    color_section = None
    if has_color:
        color_dd = ft.Dropdown(
            label="Select Colour",
            options=[ft.dropdown.Option(c) for c in ["Red", "Mehroon", "Rani", "Other"]],
        )
        color_section = ft.Container(
            border_radius=12, bgcolor=ft.Colors.WHITE,
            border=ft.border.all(1, ft.Colors.GREY_200),
            padding=12,
            content=color_dd,
        )

    # ─── Quantity section ──────────────────────────────────────────
    size_steppers = {}
    qty_card_controls = []

    if has_sizes:
        qty_card_controls.append(
            ft.Text("Select Quantity", size=16, weight=ft.FontWeight.W_600),
        )
        qty_card_controls.append(ft.Container(height=6))

        def update_summary():
            total_sets = 0
            for s in size_steppers.values():
                try:
                    total_sets += int(s.value or 0)
                except ValueError:
                    pass
            unit_price = item.get('selling_price', 0) or 0
            total_amount = total_sets * unit_price
            summary_sets_text.value = str(total_sets)
            summary_amount_text.value = f"₹{total_amount}"
            cta_qty_text.value = f"{total_sets} sets"
            cta_amount_text.value = f"₹{total_amount}"
            for t in (summary_sets_text, summary_amount_text,
                      cta_qty_text, cta_amount_text):
                t.update()

        for sz in ["2.2", "2.4", "2.6", "2.8", "2.10"]:
            stepper = QtyStepper(sz, on_change=update_summary)
            size_steppers[sz] = stepper
            qty_card_controls.append(
                ft.Container(
                    padding=ft.Padding(4, 2, 4, 2),
                    border=ft.border.only(
                        bottom=ft.border.BorderSide(1, ft.Colors.GREY_100),
                    ),
                    content=stepper.row,
                )
            )
    else:
        def update_summary():
            total_sets = 0
            try:
                total_sets = int(size_steppers.get("qty", object()).value or 0)
            except (ValueError, AttributeError):
                total_sets = 0
            unit_price = item.get('selling_price', 0) or 0
            total_amount = total_sets * unit_price
            summary_sets_text.value = str(total_sets)
            summary_amount_text.value = f"₹{total_amount}"
            cta_qty_text.value = f"{total_sets} sets"
            cta_amount_text.value = f"₹{total_amount}"
            for t in (summary_sets_text, summary_amount_text,
                      cta_qty_text, cta_amount_text):
                t.update()

        qty_stepper = QtyStepper("Qty", initial=1, on_change=update_summary)
        size_steppers["qty"] = qty_stepper
        qty_card_controls.append(
            ft.Container(
                padding=ft.Padding(4, 2, 4, 2),
                content=qty_stepper.row,
            )
        )

    quantity_card = ft.Container(
        border_radius=12, bgcolor=ft.Colors.WHITE,
        border=ft.border.all(1, ft.Colors.GREY_200),
        padding=16,
        content=ft.Column(qty_card_controls, spacing=0),
    )

    # ─── Order summary card ────────────────────────────────────────
    summary_card = ft.Container(
        border_radius=12, bgcolor=ft.Colors.GREY_50,
        border=ft.border.all(1, ft.Colors.GREY_200),
        padding=16,
        content=ft.Column([
            ft.Row([
                ft.Text("Total Sets", size=14, color=ft.Colors.GREY_700),
                summary_sets_text,
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Divider(height=10, color=ft.Colors.GREY_200),
            ft.Row([
                ft.Text("Estimated Total", size=14, weight=ft.FontWeight.W_600),
                summary_amount_text,
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Text(
                "Quantities can be updated before placing order",
                size=10, color=ft.Colors.GREY_400, italic=True,
            ),
        ], spacing=4),
    )

    # ─── add_to_cart (IDENTICAL to original — NO CHANGES) ──────────
    def add_to_cart(_):
        cart_item = {
            'item_number': item.get('item_number'),
            'category': item.get('category'),
            'unit_price': item.get('selling_price', 0),
        }
        if has_color:
            if not color_dd.value:
                page.snack("Please select a color", ft.Colors.RED_400)
                return
            cart_item['color'] = color_dd.value
        
        has_qty = False
        if has_sizes:
            for sz, tf in size_steppers.items():
                try:
                    val = int(tf.value or 0)
                except ValueError:
                    val = 0
                if val > 0:
                    cart_item[f"qty_{sz.replace('.','_')}"] = val
                    has_qty = True
        else:
            try:
                val = int(size_steppers["qty"].value or 0)
            except ValueError:
                val = 0
            if val > 0:
                cart_item["quantity"] = val
                has_qty = True
        
        if not has_qty:
            page.snack("Please enter quantity", ft.Colors.RED_400)
            return

        state.setdefault('customer_cart', []).append(cart_item)
        page.snack('✅ Added to cart')
        page.go_back()

    # ─── Assemble body controls ────────────────────────────────────
    body_controls = []
    if image_section is not None:
        body_controls.append(image_section)
    body_controls.append(info_card)
    if color_section is not None:
        body_controls.append(color_section)
    body_controls.append(quantity_card)
    body_controls.append(summary_card)
    body_controls.append(ft.Container(height=20))

    scroll_content = ft.Container(
        expand=True,
        padding=16,
        content=ft.Column(
            scroll=ft.ScrollMode.AUTO,
            expand=True,
            spacing=16,
            controls=body_controls,
        ),
    )

    # ─── Bottom CTA bar ────────────────────────────────────────────
    bottom_cta = ft.Container(
        bgcolor=ft.Colors.WHITE,
        border=ft.border.only(top=ft.border.BorderSide(1, ft.Colors.GREY_200)),
        padding=ft.Padding(16, 12, 16, 12),
        content=ft.Row([
            ft.Column([
                cta_qty_text,
                cta_amount_text,
            ], spacing=2),
            ft.FilledButton(
                "Add to Cart",
                icon=ft.Icons.ADD_SHOPPING_CART,
                on_click=add_to_cart,
                height=48,
                width=200,
                style=ft.ButtonStyle(
                    shape=ft.RoundedRectangleBorder(radius=12),
                    bgcolor=ft.Colors.BLUE_900,
                    color=ft.Colors.WHITE,
                ),
            ),
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN, spacing=12),
    )

    return ft.Column(
        expand=True,
        spacing=0,
        controls=[
            scroll_content,
            bottom_cta,
        ],
    )

def view_cart(page: ft.Page):
    """Cart view for customers."""
    state = page.state
    cart = state.get('customer_cart', [])
    
    if not cart:
        return ft.Container(
            expand=True,
            content=ft.Column(
                alignment=ft.MainAxisAlignment.CENTER,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                controls=[
                    ft.Icon(ft.Icons.SHOPPING_CART_OUTLINED, size=60, color=ft.Colors.GREY_400),
                    ft.Text("Your cart is empty", color=ft.Colors.GREY_600),
                    ft.FilledButton("Browse Catalogue", on_click=lambda _: page.go("customer_dashboard"))
                ]
            )
        )

    item_rows = []
    total_amount = 0
    for idx, ci in enumerate(cart):
        it_no = ci.get("item_number")
        up = ci.get("unit_price", 0)
        
        # Calculate qty
        qty = 0
        if any(k.startswith('qty_') for k in ci.keys()):
            qty = sum(ci.get(k, 0) for k in ci.keys() if k.startswith('qty_'))
        else:
            qty = ci.get("quantity", 0)
        
        line_total = up * qty
        total_amount += line_total
        
        def remove_it(e, i=idx):
            state['customer_cart'].pop(i)
            page.app_render()

        item_rows.append(
            ft.ListTile(
                title=ft.Text(f"{it_no} (x{qty})", weight="bold"),
                subtitle=ft.Text(f"Price: ₹{line_total}"),
                trailing=ft.IconButton(ft.Icons.DELETE_OUTLINE, icon_color=ft.Colors.RED_400, on_click=remove_it)
            )
        )

    def place_order(_):
        header = {
            'customer_name': state.get('username', 'Customer'),
            'customer_mobile': state.get('customer_mobile', ''),
            'order_date': datetime.datetime.now().strftime("%Y-%m-%d"),
            'total_amount': total_amount,
            'source': 'customer'
        }
        order_id = db.create_order(header, cart)
        if order_id:
            state['customer_cart'] = []
            page.snack(f"✅ Order #{order_id} placed successfully!")
            page.go("login")
        else:
            page.snack("❌ Failed to place order", ft.Colors.RED_400)

    return ft.ListView(
        expand=True,
        padding=16,
        controls=[
            ft.Text("Order Summary", size=22, weight="bold"),
            ft.Container(height=10),
            *item_rows,
            ft.Divider(),
            ft.Row([ft.Text("Total Amount:", size=16, weight="bold"), ft.Text(f"₹{total_amount}", size=20, color=ft.Colors.GREEN_700, weight="bold")], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Container(height=30),
            ft.FilledButton("Place Order", on_click=place_order, height=50, width=350),
            ft.OutlinedButton("Add More Items", on_click=lambda _: page.go("customer_dashboard"), height=50, width=350),
        ]
    )



