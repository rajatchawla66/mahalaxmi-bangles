# 04 — Labour App (`mahalaxmi_labour`)

## Status

- **Beta stage** — minimal feature set, actively developed
- No session auth guard yet (planned for future update)
- Green-themed (`#2E7D32`) to distinguish from customer/admin apps

## Structure

- Standard Flutter app with GoRouter, Riverpod, Supabase init
- Depends on `mahalaxmi_shared` for models, repositories, providers

## Dashboard

- Single page with one entry card: "Add Cutmail"
- No other navigation or features in Phase 1

## Cutmail (Stock Check) Creation

- **Category selector:** Dropdown, defaults to `Metal_Bangles`
- **Item selector:** Shows available items from selected category
- **Item preview card:** Image thumbnail, item number, sub-category, category
- **Size-wise quantity fields:** Dynamically generated from category's `size_chart` (respects item's `available_sizes`)
- **Note field:** Multiline, optional
- **Submit:** Validates category/item/sizes, confirms all-zero quantities via dialog
- Creates `cutmails` header + `cutmail_sizes` rows in Supabase

## Limitations (Phase 1)

- Cutmail not linked to customer orders — general stock check only
- Labour cannot edit submitted cutmails (admin only)
- No date range filter
- Item/category cannot be changed after creation (edit restricted to quantities + note)
