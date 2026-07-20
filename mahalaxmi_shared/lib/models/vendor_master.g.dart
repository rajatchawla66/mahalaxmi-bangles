// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor_master.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VendorMasterImpl _$$VendorMasterImplFromJson(Map<String, dynamic> json) =>
    _$VendorMasterImpl(
      id: _parseId(json['id']),
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );

Map<String, dynamic> _$$VendorMasterImplToJson(_$VendorMasterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_active': instance.isActive,
    };
