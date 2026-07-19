// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryImpl _$$CategoryImplFromJson(Map<String, dynamic> json) =>
    _$CategoryImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'CATEGORY',
      color: json['color'] as String? ?? 'GREY_400',
      description: json['description'] as String? ?? '',
      subCategories: json['sub_categories'] as String? ?? '',
      orderType: json['order_type'] as String? ?? 'quantity',
      isActive: json['is_active'] as bool? ?? true,
      coverImageUrl: json['cover_image_url'] as String?,
      hasSizes: json['has_sizes'] as bool? ?? false,
      hasSubcategories: json['has_subcategories'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      sizeChart: (json['size_chart'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$$CategoryImplToJson(_$CategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.icon,
      'color': instance.color,
      'description': instance.description,
      'sub_categories': instance.subCategories,
      'order_type': instance.orderType,
      'is_active': instance.isActive,
      'cover_image_url': instance.coverImageUrl,
      'has_sizes': instance.hasSizes,
      'has_subcategories': instance.hasSubcategories,
      'sort_order': instance.sortOrder,
      'size_chart': instance.sizeChart,
    };
