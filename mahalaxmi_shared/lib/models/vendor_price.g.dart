// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VendorPriceImpl _$$VendorPriceImplFromJson(Map<String, dynamic> json) =>
    _$VendorPriceImpl(
      id: json['id'] as String?,
      itemName: json['item_name'] as String,
      category: json['category'] as String?,
      vendorName: json['vendor_name'] as String,
      costPrice: (json['cost_price'] as num).toDouble(),
      marginType: json['margin_type'] as String? ?? 'percent',
      marginValue: (json['margin_value'] as num?)?.toDouble() ?? 0,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$VendorPriceImplToJson(_$VendorPriceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_name': instance.itemName,
      'category': instance.category,
      'vendor_name': instance.vendorName,
      'cost_price': instance.costPrice,
      'margin_type': instance.marginType,
      'margin_value': instance.marginValue,
      'selling_price': instance.sellingPrice,
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
    };
