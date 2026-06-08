import flet as ft
import db
import datetime
import os
import cache
from utils import *

# ============================================================
# CUSTOMER ENTRY
# ============================================================

def view_customer_name_entry(page: ft.Page):
    """View for customer to enter their shop name and mobile."""
    state = page.state
    
    name_tf = ft.TextField(
        label="Shop Name *",
        hint_text="Enter your shop name",
        width=300,
        autofocus=True
    )
    mobile_tf = ft.TextField(
        label="Mobile Number (Optional)",
        hint_text="e.g., 9876543210",
        width=300,
        keyboard_type=ft.KeyboardType.PHONE
    )

    async def on_submit(_):
        if not name_tf.value.strip():
            page.snack("Shop name is required", ft.Colors.RED_400)
            return
        
        # Save to session state
        state["role"] = "customer"
        state["username"] = name_tf.value.strip()
        state["customer_mobile"] = mobile_tf.value.strip()
        state["customer_cart"] = [] # Clear/Init customer cart
        
        # Save to persistent storage for next app open
        import json, os
        session_file = os.path.join(os.environ.get("FLET_APP_STORAGE_DATA", "."), "customer_session.json")
        try:
            with open(session_file, "w") as f:
                json.dump({
                    "role": "customer",
                    "name": state["username"],
                    "mobile": state["customer_mobile"]
                }, f)
        except Exception:
            pass
        
        page.go("customer_dashboard")


    return ft.Container(
        expand=True,
        padding=24,
        content=ft.Column(
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20,
            controls=[
                ft.Icon(ft.Icons.STORE, size=60, color=ft.Colors.INDIGO_600),
                ft.Text("Welcome to Mahalaxmi Bangles", size=20, weight="bold"),
                ft.Text("Please enter your details to browse", color=ft.Colors.GREY_600),
                name_tf,
                mobile_tf,
                ft.FilledButton("Enter Shop", on_click=on_submit, width=200),
            ]
        )
    )

# ============================================================
# CATEGORY GRID (NEW DASHBOARD)
# ============================================================

def view_customer_dashboard(page: ft.Page):
    """Main customer entry grid showing categories."""
    state = page.state
    
    # --- Data Loading Strategy: Fetch Once ---
    if state.get("customer_full_catalogue") is None:
        if cache.is_cache_available():
            state["customer_full_catalogue"] = cache.get_cached_catalog()
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
    # --- Build Category Cards ---
    cat_cards = []
    for cat in categories:
        cname = cat["name"]
        item_count = counts.get(cname, 0)
        if item_count == 0: continue # Hide empty categories for customers

        cover_url = cat.get("cover_image_url")
        
        # Determine background
        bg_content = None
        if cover_url:
            bg_content = ft.Image(src=cover_url, fit=ft.ImageFit.COVER, expand=True)
        else:
            # Solid gradient fallback
            bg_content = ft.Container(
                gradient=ft.LinearGradient(
                    colors=[ft.Colors.with_opacity(0.1, ft.Colors.BLACK), ft.Colors.with_opacity(0.4, ft.Colors.BLACK)],
                    begin=ft.Alignment(-1, -1), end=ft.Alignment(1, 1)
                ),
                expand=True
            )

        def on_cat_click(e, c=cat):
            state["customer_selected_category"] = c["name"]
            state["customer_selected_subcategory"] = None
            
            # Check for subcategories
            subs_str = c.get("sub_categories", "").strip()
            if subs_str:
                state["customer_subcategories"] = [s.strip() for s in subs_str.split(",") if s.strip()]
                page.go("customer_subcategories")
            else:
                state["customer_subcategories"] = []
                page.go("customer_items")

        card = ft.Container(
            on_click=on_cat_click,
            border_radius=16,
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            height=160,
            content=ft.Stack([
                # Background content (direct positioning)
                ft.Container(content=bg_content, left=0, top=0, right=0, bottom=0),
                # Dark overlay for text readability (direct positioning)
                ft.Container(
                    left=0, top=0, right=0, bottom=0,
                    gradient=ft.LinearGradient(
                        colors=[ft.Colors.TRANSPARENT, ft.Colors.with_opacity(0.87, ft.Colors.BLACK)],
                        begin=ft.Alignment(0, 0), end=ft.Alignment(0, 1)
                    )
                ),
                ft.Container(
                    padding=12,
                    alignment=ft.alignment.bottom_left,
                    content=ft.Column([
                        ft.Text(cname, size=16, weight="bold", color=ft.Colors.WHITE),
                        ft.Text(f"{item_count} items", size=11, color=ft.Colors.with_opacity(0.7, ft.Colors.WHITE)),
                    ], spacing=2, tight=True)
                )
            ])
        )
        cat_cards.append(card)

    # --- Layout ---
    view = ft.ListView(
        expand=True,
        padding=16,
        spacing=20,
        controls=[
            ft.Text(f"Namaste, {state['username']}!", size=18, weight=ft.FontWeight.W_500),
            ft.Row([search_tf, ft.IconButton(ft.Icons.ARROW_FORWARD, on_click=lambda _: on_search_change(None))], spacing=10),
            ft.Text("Browse Categories", size=20, weight="bold"),
            ft.ResponsiveRow(columns={"xs": 1, "sm": 12},
                controls=[ft.Column([c], col={"xs": 1, "sm": 4}) for c in cat_cards],
                spacing=12,
                run_spacing=12,
            ),
            ft.Container(height=40)
        ]
    )
    return view

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
# ITEM GRID
# ============================================================

def view_customer_items(page: ft.Page):
    state = page.state
    category = state.get("customer_selected_category")
    subcategory = state.get("customer_selected_subcategory")
    catalog = state.get("customer_full_catalogue", [])

    if not category:
        page.go("customer_dashboard")
        return ft.Container()

    # Filter items locally
    items = []
    for it in catalog:
        if it.get("category") == category:
            if not subcategory or it.get("sub_category") == subcategory:
                items.append(it)

    # --- Item Card Builder ---
    item_cards = []
    for it in items:
        img_url = it.get("image_url")
        item_no = it.get("item_number", "—")
        price = it.get("selling_price", 0)

        def on_item_click(e, item=it):
            state["customer_selected_item"] = item
            page.go("item_detail")

        def on_quick_add(e, item=it):
            # Check if item needs selection
            if bool(item.get("has_sizes", 0)) or bool(item.get("has_color", 0)):
                state["customer_selected_item"] = item
                page.go("item_detail")
            else:
                # Add directly
                cart_item = {
                    'item_number': item.get('item_number'),
                    'category': item.get('category'),
                    'unit_price': item.get('selling_price', 0),
                    'quantity': 1
                }
                state.setdefault('customer_cart', []).append(cart_item)
                page.snack(f"✅ {item_no} added to cart")
                page.app_render() # Update UI (cart icon)

        card = ft.Container(
            on_click=on_item_click,
            border_radius=12,
            bgcolor=ft.Colors.WHITE,
            border=ft.border.all(1, ft.Colors.GREY_200),
            clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
            content=ft.Column(spacing=0, controls=[
                ft.Image(
                    src=img_url if img_url else "",
                    height=160,
                    fit=ft.ImageFit.COVER,
                    error_content=ft.Container(
                        height=160, bgcolor=ft.Colors.GREY_100,
                        content=ft.Icon(ft.Icons.IMAGE_NOT_SUPPORTED, color=ft.Colors.GREY_400)
                    )
                ),
                ft.Container(
                    padding=10,
                    content=ft.Column([
                        ft.Text(item_no, weight="bold", size=13, overflow=ft.TextOverflow.ELLIPSIS),
                        ft.Row([
                            ft.Text(f"₹{price}", color=ft.Colors.GREEN_700, weight=ft.FontWeight.W_600, size=13, expand=True),
                            ft.IconButton(ft.Icons.ADD_SHOPPING_CART, icon_size=18, icon_color=ft.Colors.INDIGO_600, 
                                          on_click=on_quick_add, padding=0)
                        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
                    ], spacing=2)
                )
            ])
        )
        item_cards.append(card)

    breadcrumb = category
    if subcategory:
        breadcrumb += f" > {subcategory}"

    return ft.Column(
        expand=True,
        controls=[
            ft.Container(
                padding=ft.Padding(16, 16, 16, 8),
                content=ft.Row([
                    ft.Icon(ft.Icons.HOME_ROUNDED, size=16, color=ft.Colors.GREY_600),
                    ft.Text(breadcrumb, size=13, color=ft.Colors.GREY_600, weight=ft.FontWeight.W_500)
                ], spacing=8)
            ),
            ft.GridView(
                expand=True,
                padding=12,
                runs_count=2,
                max_extent=200,
                child_aspect_ratio=0.72,
                spacing=10,
                run_spacing=10,
                controls=[ft.Column([c]) for c in item_cards]
            )
        ]
    )

# ============================================================
# SEARCH RESULTS
# ============================================================

def view_customer_search(page: ft.Page):
    state = page.state
    catalog = state.get("customer_full_catalogue", [])
    
    # Results Grid (placeholder)
    results_grid = ft.GridView(
        expand=True,
        padding=12,
        runs_count=2,
        max_extent=200,
        child_aspect_ratio=0.72,
        spacing=10,
        run_spacing=10,
    )

    results_header = ft.Text(size=15, weight="bold")

    def update_results(query: str):
        query = query.lower().strip()
        if not query:
            page.go("customer_dashboard")
            return

        filtered = [i for i in catalog if 
            query in (i.get("item_number") or "").lower() or 
            query in (i.get("category") or "").lower() or 
            query in (i.get("sub_category") or "").lower()]

        item_cards = []
        for it in filtered:
            img_url = it.get("image_url")
            item_no = it.get("item_number", "—")
            price = it.get("selling_price", 0)
            cat_name = it.get("category", "")

            def on_item_click(e, item=it):
                state["customer_selected_item"] = item
                page.go("item_detail")

            card = ft.Container(
                on_click=on_item_click,
                border_radius=12,
                bgcolor=ft.Colors.WHITE,
                border=ft.border.all(1, ft.Colors.GREY_200),
                clip_behavior=ft.ClipBehavior.ANTI_ALIAS,
                content=ft.Column(spacing=0, controls=[
                    ft.Image(
                        src=img_url if img_url else "",
                        height=150,
                        fit=ft.ImageFit.COVER,
                        error_content=ft.Container(
                            height=150, bgcolor=ft.Colors.GREY_100,
                            content=ft.Icon(ft.Icons.IMAGE_NOT_SUPPORTED, color=ft.Colors.GREY_400)
                        )
                    ),
                    ft.Container(
                        padding=10,
                        content=ft.Column([
                            ft.Text(item_no, weight="bold", size=13, overflow=ft.TextOverflow.ELLIPSIS),
                            ft.Row([
                                ft.Text(f"₹{price}", color=ft.Colors.GREEN_700, weight=ft.FontWeight.W_600, size=13),
                                ft.Text(cat_name, size=10, color=ft.Colors.GREY_500, italic=True, expand=True, text_align=ft.TextAlign.RIGHT)
                            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
                        ], spacing=2)
                    )
                ])
            )
            item_cards.append(ft.Column([card]))

        results_header.value = f"Results for '{query}' ({len(filtered)})"
        results_grid.controls = item_cards
        
        # If no results, show empty state
        if not filtered:
            results_grid.controls = [
                ft.Container(
                    expand=True, padding=40, alignment=ft.alignment.center,
                    content=ft.Column([
                        ft.Icon(ft.Icons.SEARCH_OFF, size=60, color=ft.Colors.GREY_300),
                        ft.Text(f"No results for '{query}'", color=ft.Colors.GREY_600),
                    ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10)
                )
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
        autofocus=True, # Keep focus when navigating here
        suffix=ft.IconButton(ft.Icons.CLEAR, on_click=lambda _: update_results(""))
    )

    # Initial load
    update_results(state.get("customer_search_query", ""))

    return ft.Column(
        expand=True,
        controls=[
            ft.Container(
                padding=16,
                content=ft.Row([search_tf], spacing=10)
            ),
            ft.Container(
                padding=ft.Padding(16, 0, 16, 8),
                content=results_header
            ),
            results_grid
        ]
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



