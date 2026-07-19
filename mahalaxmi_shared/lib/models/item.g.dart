// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RateItemImpl _$$RateItemImplFromJson(Map<String, dynamic> json) =>
    _$RateItemImpl(
      itemNumber: json['item_number'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String,
      subCategory: json['sub_category'] as String?,
      hasSizes: json['has_sizes'] as bool? ?? false,
      hasColor: json['has_color'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
      marginPercent: (json['margin_percent'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'new',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      availableSizes: (json['available_sizes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$RateItemImplToJson(_$RateItemImpl instance) =>
    <String, dynamic>{
      'item_number': instance.itemNumber,
      'image_url': instance.imageUrl,
      'cost_price': instance.costPrice,
      'selling_price': instance.sellingPrice,
      'category': instance.category,
      'sub_category': instance.subCategory,
      'has_sizes': instance.hasSizes,
      'has_color': instance.hasColor,
      'is_available': instance.isAvailable,
      'margin_percent': instance.marginPercent,
      'status': instance.status,
      'tags': instance.tags,
      'available_sizes': instance.availableSizes,
      'created_at': instance.createdAt?.toIso8601String(),
    };
