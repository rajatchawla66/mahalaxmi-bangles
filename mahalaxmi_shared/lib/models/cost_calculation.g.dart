// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_calculation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CostCalculationImpl _$$CostCalculationImplFromJson(
        Map<String, dynamic> json) =>
    _$CostCalculationImpl(
      id: json['id'] as String?,
      itemName: json['item_name'] as String,
      itemNumber: json['item_number'] as String?,
      category: json['category'] as String? ?? '',
      subCategory: json['sub_category'] as String?,
      materials: json['materials'] as Map<String, dynamic>? ?? const {},
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      costingType: json['costing_type'] as String? ?? 'manufacturing',
      createdBy: json['created_by'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedBy: json['updated_by'] as String? ?? '',
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$CostCalculationImplToJson(
        _$CostCalculationImpl instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      'item_name': instance.itemName,
      'item_number': instance.itemNumber,
      'category': instance.category,
      'sub_category': instance.subCategory,
      'materials': instance.materials,
      'total_cost': instance.totalCost,
      'costing_type': instance.costingType,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_by': instance.updatedBy,
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
