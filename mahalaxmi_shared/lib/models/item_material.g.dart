// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_material.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ItemMaterialImpl _$$ItemMaterialImplFromJson(Map<String, dynamic> json) =>
    _$ItemMaterialImpl(
      itemNumber: json['item_number'] as String,
      materialId: (json['material_id'] as num?)?.toInt(),
      materialName: json['material_name'] as String? ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      ratePerUnit: (json['rate_per_unit'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$ItemMaterialImplToJson(_$ItemMaterialImpl instance) =>
    <String, dynamic>{
      'item_number': instance.itemNumber,
      'material_id': instance.materialId,
      'material_name': instance.materialName,
      'qty': instance.qty,
      'rate_per_unit': instance.ratePerUnit,
    };
