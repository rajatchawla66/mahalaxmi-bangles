// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cost_breakdown.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CostBreakdownImpl _$$CostBreakdownImplFromJson(Map<String, dynamic> json) =>
    _$CostBreakdownImpl(
      id: (json['id'] as num?)?.toInt(),
      itemNumber: json['item_number'] as String,
      materialId: (json['material_id'] as num?)?.toInt(),
      materialName: json['material_name'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? 'pcs',
      ratePerUnit: (json['rate_per_unit'] as num?)?.toDouble() ?? 0.0,
      lineTotal: (json['line_total'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$CostBreakdownImplToJson(_$CostBreakdownImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_number': instance.itemNumber,
      'material_id': instance.materialId,
      'material_name': instance.materialName,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'rate_per_unit': instance.ratePerUnit,
      'line_total': instance.lineTotal,
    };
