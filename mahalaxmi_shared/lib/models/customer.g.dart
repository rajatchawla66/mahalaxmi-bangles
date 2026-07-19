// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerImpl _$$CustomerImplFromJson(Map<String, dynamic> json) =>
    _$CustomerImpl(
      id: (json['id'] as num?)?.toInt(),
      pin: json['pin'] as String,
      shopName: json['shop_name'] as String,
      ownerName: json['owner_name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      city: json['city'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      lastActiveAt: json['last_active_at'] as String?,
    );

Map<String, dynamic> _$$CustomerImplToJson(_$CustomerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pin': instance.pin,
      'shop_name': instance.shopName,
      'owner_name': instance.ownerName,
      'mobile': instance.mobile,
      'city': instance.city,
      'notes': instance.notes,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
      'last_active_at': instance.lastActiveAt,
    };
