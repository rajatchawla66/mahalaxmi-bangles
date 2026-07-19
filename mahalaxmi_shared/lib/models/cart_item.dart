import 'chuda_customization_snapshot.dart';

class CartItem {
  final String itemNumber;
  final String category;
  final bool hasSizes;
  final bool hasColor;

  final int qty22;
  final int qty24;
  final int qty26;
  final int qty28;
  final int qty210;
  final int qty212;

  final double quantity;
  final String? unit;
  final String? color;
  final String? grindType;
  final String? boxType;
  final String? notes;
  final double unitPrice;
  final ChudaCustomizationSnapshot? customization;

  const CartItem({
    required this.itemNumber,
    this.category = 'Chuda',
    this.hasSizes = false,
    this.hasColor = false,
    this.qty22 = 0,
    this.qty24 = 0,
    this.qty26 = 0,
    this.qty28 = 0,
    this.qty210 = 0,
    this.qty212 = 0,
    this.quantity = 0,
    this.unit,
    this.color,
    this.grindType,
    this.boxType,
    this.notes,
    this.unitPrice = 0,
    this.customization,
  });

  int get totalSizeQty => qty22 + qty24 + qty26 + qty28 + qty210 + qty212;

  double get effectiveQuantity =>
      hasSizes ? totalSizeQty.toDouble() : quantity;

  Map<String, dynamic> toJson() => {
        'itemNumber': itemNumber,
        'category': category,
        'hasSizes': hasSizes,
        'hasColor': hasColor,
        'qty22': qty22,
        'qty24': qty24,
        'qty26': qty26,
        'qty28': qty28,
        'qty210': qty210,
        'qty212': qty212,
        'quantity': quantity,
        'unit': unit,
        'color': color,
        'grindType': grindType,
        'boxType': boxType,
        'notes': notes,
        'unitPrice': unitPrice,
        'customization': customization?.toJson(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        itemNumber: json['itemNumber'] as String,
        category: json['category'] as String? ?? '',
        hasSizes: json['hasSizes'] as bool? ?? false,
        hasColor: json['hasColor'] as bool? ?? false,
        qty22: json['qty22'] as int? ?? 0,
        qty24: json['qty24'] as int? ?? 0,
        qty26: json['qty26'] as int? ?? 0,
        qty28: json['qty28'] as int? ?? 0,
        qty210: json['qty210'] as int? ?? 0,
        qty212: json['qty212'] as int? ?? 0,
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String?,
        color: json['color'] as String?,
        grindType: json['grindType'] as String?,
        boxType: json['boxType'] as String?,
        notes: json['notes'] as String?,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        customization: json['customization'] != null
            ? ChudaCustomizationSnapshot.fromJson(
                json['customization'] as Map<String, dynamic>)
            : null,
      );

  CartItem copyWith({
    String? itemNumber,
    String? category,
    bool? hasSizes,
    bool? hasColor,
    int? qty22,
    int? qty24,
    int? qty26,
    int? qty28,
    int? qty210,
    int? qty212,
    double? quantity,
    String? unit,
    String? color,
    String? grindType,
    String? boxType,
    String? notes,
    double? unitPrice,
    ChudaCustomizationSnapshot? customization,
  }) {
    return CartItem(
      itemNumber: itemNumber ?? this.itemNumber,
      category: category ?? this.category,
      hasSizes: hasSizes ?? this.hasSizes,
      hasColor: hasColor ?? this.hasColor,
      qty22: qty22 ?? this.qty22,
      qty24: qty24 ?? this.qty24,
      qty26: qty26 ?? this.qty26,
      qty28: qty28 ?? this.qty28,
      qty210: qty210 ?? this.qty210,
      qty212: qty212 ?? this.qty212,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      grindType: grindType ?? this.grindType,
      boxType: boxType ?? this.boxType,
      notes: notes ?? this.notes,
      unitPrice: unitPrice ?? this.unitPrice,
      customization: customization ?? this.customization,
    );
  }
}
