# Requirements Document

## Introduction

Expand the wholesale bridal Chuda/bangle Flet Android app's Create Order page to support multiple product categories beyond Chuda. The system currently handles only Chuda orders with fixed fields (Color, Grind Type, Box Type, Packing Structure, size-wise quantities). This feature introduces a category-aware order form that dynamically adapts its input fields based on the selected product category, supports seasonal items that can be added/removed, and maintains backward compatibility with existing Chuda order workflows.

## Glossary

- **Order_System**: The Flet-based Android application that manages wholesale bridal product orders
- **Category**: A top-level product classification (Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal)
- **Sub_Category**: A secondary classification within a category (e.g., Patti, Nihar, Box, Bhawari within Raw_Material)
- **Rate_List**: The existing catalog of items with item_number, image, cost_price, and selling_price
- **Cart**: The in-memory collection of line items being added to an order before saving
- **Category_Schema**: The set of attributes (fields, sizes, options) that define how a category's items are ordered
- **Seasonal_Item**: A product that is temporarily available in the market and can be added or removed from the catalog without affecting permanent categories

## Requirements

### Requirement 1: Product Category Management

**User Story:** As an admin, I want to define and manage product categories, so that the order form can support different types of products with their specific attributes.

#### Acceptance Criteria

1. THE Order_System SHALL present the following categories as selectable options that cannot be added, renamed, or deleted by the admin: Chuda, Kaleera, Raw_Material, Metal_Bangles, and Seasonal
2. WHEN an admin adds a new item to the Rate_List, THE Order_System SHALL require the admin to assign exactly one Category to the item before the item can be saved
3. IF an admin attempts to save a new Rate_List item without selecting a Category, THEN THE Order_System SHALL prevent the save and display a validation message indicating that a Category is required
4. WHERE the Category is Raw_Material, THE Order_System SHALL require the admin to assign exactly one Sub_Category from: Patti, Nihar, Box, Bhawari
5. WHEN an admin edits an existing Rate_List item, THE Order_System SHALL allow the admin to change the assigned Category and Sub_Category
6. THE Order_System SHALL store the Category as a non-null field and Sub_Category as a nullable field in the rate_list table in the local SQLite database alongside existing rate_list fields

### Requirement 2: Category-Specific Order Attributes for Chuda

**User Story:** As an admin, I want Chuda items in the order form to retain their existing attribute fields, so that the current workflow is preserved.

#### Acceptance Criteria

1. WHEN a cart line item belongs to the Chuda Category, THE Order_System SHALL display the following attribute fields: Color (selectable from: Light Mehroon, Dark Mehroon, Red, Rani, Custom), Grind Type (Gol / Internal-Grind, Bina Gol / Non-Grind), Box Type (selectable from: Jodi Box, Mahal Box, Flap Box, Velvet Box), and Packing Structure
2. IF the admin selects "Custom" as the Color value, THEN THE Order_System SHALL display a free-text input field for the admin to specify the custom color name
3. WHEN a cart line item belongs to the Chuda Category, THE Order_System SHALL display size-wise quantity inputs for sizes: 2.2, 2.4, 2.6, 2.8, and 2.10, each accepting a non-negative integer value with a minimum of 0 and a maximum of 9999
4. WHEN a cart line item belongs to the Chuda Category, THE Order_System SHALL calculate the line total as the sum of all size quantities multiplied by the item selling price, displayed in Indian Rupees rounded to two decimal places
5. IF a Chuda cart line item has all size quantities equal to zero at order save time, THEN THE Order_System SHALL prevent order submission and display an error message indicating that at least one size must have a quantity greater than zero

### Requirement 3: Category-Specific Order Attributes for Kaleera

**User Story:** As an admin, I want Kaleera items to have their own relevant attribute fields, so that I can capture the correct specifications for Kaleera orders.

#### Acceptance Criteria

1. WHEN a cart line item belongs to the Kaleera Category, THE Order_System SHALL display a quantity input field accepting an integer value between 1 and 9999 (number of sets)
2. WHEN a cart line item belongs to the Kaleera Category, THE Order_System SHALL display a Color selection field with the same color options available to Chuda items, including a Custom option that reveals a free-text color name input
3. WHEN a cart line item belongs to the Kaleera Category, THE Order_System SHALL calculate the line total as quantity multiplied by the item selling price
4. IF the admin attempts to save an order containing a Kaleera line item with quantity less than 1 or no color selected, THEN THE Order_System SHALL prevent the save and display an error message indicating the missing or invalid field

### Requirement 4: Category-Specific Order Attributes for Raw Material

**User Story:** As an admin, I want Raw Material items to capture weight or unit-based quantities with their sub-category, so that I can accurately order supplies.

#### Acceptance Criteria

1. WHEN a cart line item belongs to the Raw_Material Category, THE Order_System SHALL display the Sub_Category label (Patti, Nihar, Box, or Bhawari) as a read-only indicator derived from the item's Rate_List assignment
2. WHEN a cart line item belongs to the Raw_Material Category, THE Order_System SHALL display a quantity input field accepting numeric values from 0.01 to 99,999.99 with up to 2 decimal places, and a unit selector with options: pieces, kg, meters defaulting to "pieces"
3. WHEN a cart line item belongs to the Raw_Material Category, THE Order_System SHALL calculate the line total as quantity multiplied by the item selling price
4. IF the admin attempts to save an order containing a Raw_Material line item with quantity equal to zero or empty, THEN THE Order_System SHALL prevent the save and display an error message indicating that a quantity greater than zero is required

### Requirement 5: Category-Specific Order Attributes for Metal Bangles

**User Story:** As an admin, I want Metal Bangle items to capture size and quantity information appropriate for bangles, so that I can place accurate metal bangle orders.

#### Acceptance Criteria

1. WHEN a cart line item belongs to the Metal_Bangles Category, THE Order_System SHALL display size-wise quantity inputs for sizes: 2.2, 2.4, 2.6, 2.8, and 2.10, each accepting integer values from 0 to 9999
2. WHEN a cart line item belongs to the Metal_Bangles Category, THE Order_System SHALL display a Color selection field with the same color options available to the Chuda Category, including a custom color text entry option
3. WHEN a cart line item belongs to the Metal_Bangles Category, THE Order_System SHALL calculate the line total as the sum of all size quantities multiplied by the item selling price, displaying 0 when all size quantities are zero
4. IF a size quantity input for a Metal_Bangles line item contains a non-numeric or negative value, THEN THE Order_System SHALL treat that input as 0 and display 0 in the field
5. WHEN saving an order containing Metal_Bangles items, THE Order_System SHALL require at least one size quantity greater than 0 per Metal_Bangles line item

### Requirement 6: Category-Specific Order Attributes for Seasonal Items

**User Story:** As an admin, I want Seasonal items to have a flexible order form, so that I can order items that vary in nature throughout the year.

#### Acceptance Criteria

1. WHEN a cart line item belongs to the Seasonal Category, THE Order_System SHALL display a quantity input field accepting integer values from 1 to 99,999
2. WHEN a cart line item belongs to the Seasonal Category, THE Order_System SHALL display a free-text notes field for specifying item-specific details, accepting up to 500 characters
3. WHEN a cart line item belongs to the Seasonal Category, THE Order_System SHALL calculate the line total as quantity multiplied by the item selling price and display the result in Indian Rupee format
4. IF the quantity field for a Seasonal cart line item is empty or zero, THEN THE Order_System SHALL prevent order submission and display an error message indicating that quantity must be at least 1

### Requirement 7: Seasonal Item Lifecycle Management

**User Story:** As an admin, I want to easily add and remove seasonal items from the catalog, so that the rate list reflects what is currently available in the market.

#### Acceptance Criteria

1. WHEN an admin sets the is_available field of a Seasonal item to false, THE Order_System SHALL hide the item from the item selection dropdown in the Create Order form
2. WHEN an admin sets the is_available field of a previously unavailable Seasonal item to true, THE Order_System SHALL show the item in the item selection dropdown again
3. THE Order_System SHALL retain historical order data for Seasonal items even after the item is marked unavailable, and SHALL display the item name and attributes when viewing past orders containing that item
4. IF a Seasonal item is marked unavailable while it exists in an unsaved cart, THEN THE Order_System SHALL retain the item in the current cart session until the order is saved or discarded

### Requirement 8: Dynamic Order Form Rendering

**User Story:** As an admin, I want the order form to automatically adapt when I select an item, so that I only see fields relevant to that item's category.

#### Acceptance Criteria

1. WHEN an item is selected in a cart row, THE Order_System SHALL determine the item Category from the Rate_List and render only the attribute fields defined for that Category within the same cart row
2. WHEN the selected item in a cart row is changed to an item of a different Category, THE Order_System SHALL clear all previously entered attribute values and replace the attribute fields with those appropriate for the new Category
3. THE Order_System SHALL allow mixing items from different categories within the same order without limiting the number of distinct categories per order
4. WHEN no item is selected in a cart row, THE Order_System SHALL display only the item selection dropdown without any category-specific attribute fields

### Requirement 9: Order-Level vs Item-Level Attributes

**User Story:** As an admin, I want shared order preferences (like packing structure) to apply at the order level while category-specific attributes apply per item, so that I do not repeat common information.

#### Acceptance Criteria

1. THE Order_System SHALL capture Customer Name, Order Date, Packing Structure, and Additional Info as order-level fields displayed once at the top of the order form and applied to all items in the order
2. THE Order_System SHALL capture Color, Grind Type, Box Type, sizes, quantities, and unit as item-level fields within each cart row, rendering only the fields applicable to the item's Category
3. WHEN an order contains only Chuda items, THE Order_System SHALL display Color, Grind Type, and Box Type at the order level and pre-fill each Chuda cart row with those order-level values as defaults that can be overridden per item
4. WHEN a non-Chuda item is added to an order that previously contained only Chuda items, THE Order_System SHALL retain the order-level Color, Grind Type, and Box Type values as defaults for existing Chuda items but SHALL NOT apply them to the non-Chuda item

### Requirement 10: Database Schema Extension

**User Story:** As a developer, I want the database schema to support multi-category orders, so that all category-specific data is persisted correctly.

#### Acceptance Criteria

1. THE Order_System SHALL store a category field (NOT NULL, one of: Chuda, Kaleera, Raw_Material, Metal_Bangles, Seasonal) and an optional sub_category field in the rate_list table
2. THE Order_System SHALL store an is_available boolean field in the rate_list table defaulting to true
3. THE Order_System SHALL store item-level attributes (color, grind_type, box_type, quantity, unit, notes) in the order_items table per line item, allowing NULL for attributes not applicable to the item's category
4. WHEN the database is initialized, THE Order_System SHALL migrate existing rate_list items to the Chuda Category by setting category to "Chuda" for all rows where category is NULL, without modifying or deleting any other fields
5. WHEN the database is initialized, THE Order_System SHALL migrate existing order_items records to include item-level color, grind_type, and box_type copied from the parent order header for each record where those fields are NULL
6. IF the migration has already been applied (no NULL category values exist in rate_list), THEN THE Order_System SHALL skip the migration step without error, ensuring idempotent execution

### Requirement 11: Order Summary with Category Breakdown

**User Story:** As an admin, I want the order summary to show a breakdown by category, so that I can quickly review what types of products are in the order.

#### Acceptance Criteria

1. THE Order_System SHALL display the order summary grouped by Category in alphabetical order, showing the number of line items and the sum of line totals as a subtotal per Category
2. THE Order_System SHALL display the grand total as the sum of all category subtotals across all categories in the order
3. WHEN viewing a saved order, THE Order_System SHALL display each line item with its Category label and the category-specific attributes that were captured at order time
4. IF a category group contains zero line items after item removal, THEN THE Order_System SHALL hide that category group from the summary display
