# 05 — Database Schema

## Tables

### `categories`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `name` | text | Raw name internally (e.g. `Metal_Bangles`) |
| `display_name` | text | Readable name for UI |
| `is_active` | bool | |
| `sort_order` | int | Admin-controlled display order |
| `size_chart` | jsonb | List of size strings: `["2.2","2.4","2.6","2.8","2.10"]` |
| `image_url` | text | Category cover image path |
| `created_at` | timestamptz | |

### `rate_list` (items)
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `item_number` | text | |
| `category` | text | Raw category name (matches `categories.name`) |
| `sub_category` | text | |
| `selling_price` | numeric | 0.0 = hidden from customers |
| `cost_price` | numeric | |
| `margin` | numeric | Auto-calculated percentage |
| `tags` | jsonb | `["tag1","tag2"]` |
| `available_sizes` | jsonb | Null = all category sizes; `["2.4","2.6"]` to limit |
| `has_sizes` | bool | |
| `has_colors` | bool | |
| `image_url` | text | Supabase Storage path |
| `is_available` | bool | |
| `is_active` | bool | |

### `orders`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `customer_id` | int8 FK → customers | |
| `status` | text | pending/confirmed/completed/cancelled |
| `total_amount` | numeric | |
| `deleted_at` | timestamptz | Soft-delete timestamp (null = active) |
| `deleted_by` | text | Admin who deleted |
| `delete_reason` | text | Reason for deletion |
| `created_at` | timestamptz | |

### `order_items`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `order_id` | int8 FK → orders | |
| `item_id` | int8 FK → rate_list | |
| `item_number` | text | Snapshot at order time |
| `unit_price` | numeric | Customized price if Chuda |
| `quantity` | int | Stored as integer |
| `qty_2_2` / `qty_2_4` / `qty_2_6` / `qty_2_8` / `qty_2_10` / `qty_2_12` | int | Per-size quantities |
| `customization` | jsonb | Chuda snapshot: pattiName, colorName, boxName, price diffs |
| `image_url` | text | |

### `customers`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `name` | text | |
| `pin` | text | 8-digit PIN (hashed) |
| `phone` | text | |
| `is_active` | bool | |
| `last_active_at` | timestamptz | Updated on catalogue access |

### `cutmails`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `category_name` | text | Snapshot |
| `item_id` | int8 FK → rate_list | |
| `item_number` | text | Snapshot |
| `status` | text | pending/reviewed/archived |
| `notes` | text | Optional |
| `reviewed_by` | text | Admin name |
| `reviewed_at` | timestamptz | |
| `created_at` | timestamptz | Indexed DESC |

### `cutmail_sizes`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `cutmail_id` | int8 FK → cutmails | CASCADE delete |
| `size` | text | e.g. `2.4` — stored as text |
| `quantity` | int | |

### `chuda_customization_options`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `group` | text | patti / color / box |
| `name` | text | Display name |
| `price_difference` | numeric | Added to base price |
| `is_default` | bool | Auto-selected |
| `is_active` | bool | |

### `vendor_master`
| Column | Type | Notes |
|--------|------|-------|
| `id` | bigserial PK | Returns as String from PostgREST (bigint) |
| `name` | text | Vendor display name |
| `is_active` | bool | Inactive vendors hidden from dropdowns |

### `vendor_prices`
| Column | Type | Notes |
|--------|------|-------|
| `id` | text PK | UUID |
| `item_name` | text | |
| `category` | text | Required — must match `categories.name` |
| `vendor_name` | text | FK-like to `vendor_master.name` |
| `cost_price` | numeric | |
| `selling_price` | numeric | |
| `margin_type` | text | `percent` or `flat` |
| `margin_value` | numeric | |
| `notes` | text | Optional |
| `created_at` | timestamptz | |

### `rate_list` — additional columns

| Column | Type | Notes |
|--------|------|-------|
| `vendor` | text | Vendor name assigned to catalogue item (FK-like to `vendor_master.name`). Nullable. |

### `tag_master`
| Column | Type | Notes |
|--------|------|-------|
| `id` | int8 PK | |
| `name` | text | |
| `is_active` | bool | |

## Migrations

| File | Description |
|------|-------------|
| `migration_docs/005_cutmail.sql` | `cutmails` + `cutmail_sizes` tables, indexes, RLS |
| `migration_docs/006_soft_delete_orders.sql` | `deleted_at`/`deleted_by`/`delete_reason` on `orders`, indexes |

Additional ad-hoc columns added manually: `available_sizes`, `qty_2_12`, `size_chart`, `sort_order`, `customization`, `vendor` on `rate_list`.

Tables added via Supabase SQL editor: `vendor_master` (2026-07-19), `vendor_prices` (2026-07-19).

## Supabase Notes

- **RLS:** Currently disabled on all tables. When enabled, soft-delete filter policy should exclude `deleted_at IS NOT NULL`.
- **Storage:** `product-images` bucket — public read, authenticated write
- **Image paths:** `items/<item_number_slug>.jpg`, `category_covers/<category_slug>.jpg`
- **No realtime subscriptions** used yet
