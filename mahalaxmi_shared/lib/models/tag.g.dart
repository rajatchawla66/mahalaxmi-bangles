// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TagMasterImpl _$$TagMasterImplFromJson(Map<String, dynamic> json) =>
    _$TagMasterImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      legacyCategory: json['category'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      createdAt: json['created_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
    );

Map<String, dynamic> _$$TagMasterImplToJson(_$TagMasterImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'display_name': instance.displayName,
      'category': instance.legacyCategory,
      'is_active': instance.isActive,
      'categories': instance.categories,
      'created_at': instance.createdAt,
      'deleted_at': instance.deletedAt,
    };
