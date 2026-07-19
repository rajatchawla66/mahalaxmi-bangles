import '../constants/category_schemas.dart';
import '../models/cart_item.dart';

int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value >= 0 ? value : 0;
  if (value is double) {
    final n = value.toInt();
    return n >= 0 ? n : 0;
  }
  if (value is String) {
    try {
      final n = int.tryParse(value);
      if (n != null && n >= 0) return n;
      final f = double.tryParse(value);
      if (f != null && f >= 0) return f.toInt();
      return 0;
    } catch (_) {
      return 0;
    }
  }
  return 0;
}

int _sumSizeQtys(CartItem item) {
  return item.qty22 + item.qty24 + item.qty26 + item.qty28 + item.qty210 + item.qty212;
}

String? _validateHasSizesItem(CartItem item, String category) {
  final total = _sumSizeQtys(item);
  if (total <= 0) {
    return 'At least one size must have quantity > 0 for $category item \'${item.itemNumber}\'';
  }
  return null;
}

String? _validateQtyItem(CartItem item, String category) {
  final qty = _safeInt(item.quantity);
  if (qty < 1) {
    return 'Quantity must be at least 1 for $category item \'${item.itemNumber}\'';
  }
  return null;
}

String? validateCartItem(CartItem item, String category) {
  final schema = kCategorySchemas[category];

  // Dynamic category — no known schema
  if (schema == null) {
    if (item.hasSizes) {
      return _validateHasSizesItem(item, category);
    }
    return _validateQtyItem(item, category);
  }

  // Item has sizes explicitly set — override schema
  if (item.hasSizes) {
    return _validateHasSizesItem(item, category);
  }

  // Apply schema-defined validation rule
  return _applySchemaRule(item, category, schema);
}

String? _applySchemaRule(CartItem item, String category, CategorySchema schema) {
  final rule = schema.validation;

  switch (rule) {
    case 'at_least_one_size_gt_zero':
      return _validateHasSizesItem(item, category);

    case 'qty_gte_1_and_color_required':
      final qty = _safeInt(item.quantity);
      if (qty < 1) {
        return 'Quantity must be at least 1 for $category item \'${item.itemNumber}\'';
      }
      if (item.hasColor) {
        final color = (item.color ?? '').trim();
        if (color.isEmpty) {
          return 'Color is required for $category item \'${item.itemNumber}\'';
        }
      }
      return null;

    case 'qty_gt_zero':
      return _validateRawMaterialQty(item);

    case 'qty_gte_1':
      final qty = _safeInt(item.quantity);
      if (qty < 1) {
        return 'Quantity must be at least 1 for $category item \'${item.itemNumber}\'';
      }
      return null;

    default:
      return 'Unknown validation rule: $rule';
  }
}

String? _validateRawMaterialQty(CartItem item) {
  final rawQty = item.quantity;
  if (rawQty <= 0) {
    return 'Quantity must be greater than 0 for Raw_Material item \'${item.itemNumber}\'';
  }
  if (rawQty < 0.01 || rawQty > 99999.99) {
    return 'Quantity must be between 0.01 and 99999.99 for Raw_Material item \'${item.itemNumber}\'';
  }
  final qtyStr = rawQty.toString();
  final dotIndex = qtyStr.indexOf('.');
  if (dotIndex >= 0 && qtyStr.length - dotIndex - 1 > 2) {
    return 'Quantity must have at most 2 decimal places for Raw_Material item \'${item.itemNumber}\'';
  }
  return null;
}

String? validateOrder(List<CartItem> cart, Map<String, dynamic> rateLookup) {
  if (cart.isEmpty) {
    return 'Cart is empty.';
  }
  for (final item in cart) {
    final itemNumber = item.itemNumber;
    if (itemNumber.isEmpty) {
      continue;
    }
    final itemInfo = rateLookup[itemNumber];
    if (itemInfo == null) {
      return 'Item \'$itemNumber\' not found in rate list';
    }
    final category =
        (item.category.isNotEmpty ? item.category : itemInfo['category'] as String? ?? '');
    if (category.isEmpty) {
      return 'Category not found for item \'$itemNumber\'';
    }
    final error = validateCartItem(item, category);
    if (error != null) {
      return error;
    }
  }
  return null;
}
