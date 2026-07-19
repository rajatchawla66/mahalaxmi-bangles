// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chuda_customization_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChudaCustomizationOptionImpl _$$ChudaCustomizationOptionImplFromJson(
        Map<String, dynamic> json) =>
    _$ChudaCustomizationOptionImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      groupType: json['group_type'] as String,
      name: json['name'] as String,
      priceDifference: (json['price_difference'] as num?)?.toDouble() ?? 0.0,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ChudaCustomizationOptionImplToJson(
        _$ChudaCustomizationOptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_type': instance.groupType,
      'name': instance.name,
      'price_difference': instance.priceDifference,
      'is_default': instance.isDefault,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
    };
