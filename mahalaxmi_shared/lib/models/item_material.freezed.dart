// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_material.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItemMaterial _$ItemMaterialFromJson(Map<String, dynamic> json) {
  return _ItemMaterial.fromJson(json);
}

/// @nodoc
mixin _$ItemMaterial {
  @JsonKey(name: 'item_number')
  String get itemNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_id')
  int? get materialId => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_name')
  String get materialName => throw _privateConstructorUsedError;
  double get qty => throw _privateConstructorUsedError;
  @JsonKey(name: 'rate_per_unit')
  double get ratePerUnit => throw _privateConstructorUsedError;

  /// Serializes this ItemMaterial to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItemMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItemMaterialCopyWith<ItemMaterial> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItemMaterialCopyWith<$Res> {
  factory $ItemMaterialCopyWith(
          ItemMaterial value, $Res Function(ItemMaterial) then) =
      _$ItemMaterialCopyWithImpl<$Res, ItemMaterial>;
  @useResult
  $Res call(
      {@JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'material_id') int? materialId,
      @JsonKey(name: 'material_name') String materialName,
      double qty,
      @JsonKey(name: 'rate_per_unit') double ratePerUnit});
}

/// @nodoc
class _$ItemMaterialCopyWithImpl<$Res, $Val extends ItemMaterial>
    implements $ItemMaterialCopyWith<$Res> {
  _$ItemMaterialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItemMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemNumber = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? qty = null,
    Object? ratePerUnit = null,
  }) {
    return _then(_value.copyWith(
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: freezed == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as int?,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      ratePerUnit: null == ratePerUnit
          ? _value.ratePerUnit
          : ratePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItemMaterialImplCopyWith<$Res>
    implements $ItemMaterialCopyWith<$Res> {
  factory _$$ItemMaterialImplCopyWith(
          _$ItemMaterialImpl value, $Res Function(_$ItemMaterialImpl) then) =
      __$$ItemMaterialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'material_id') int? materialId,
      @JsonKey(name: 'material_name') String materialName,
      double qty,
      @JsonKey(name: 'rate_per_unit') double ratePerUnit});
}

/// @nodoc
class __$$ItemMaterialImplCopyWithImpl<$Res>
    extends _$ItemMaterialCopyWithImpl<$Res, _$ItemMaterialImpl>
    implements _$$ItemMaterialImplCopyWith<$Res> {
  __$$ItemMaterialImplCopyWithImpl(
      _$ItemMaterialImpl _value, $Res Function(_$ItemMaterialImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItemMaterial
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemNumber = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? qty = null,
    Object? ratePerUnit = null,
  }) {
    return _then(_$ItemMaterialImpl(
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      materialId: freezed == materialId
          ? _value.materialId
          : materialId // ignore: cast_nullable_to_non_nullable
              as int?,
      materialName: null == materialName
          ? _value.materialName
          : materialName // ignore: cast_nullable_to_non_nullable
              as String,
      qty: null == qty
          ? _value.qty
          : qty // ignore: cast_nullable_to_non_nullable
              as double,
      ratePerUnit: null == ratePerUnit
          ? _value.ratePerUnit
          : ratePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemMaterialImpl implements _ItemMaterial {
  const _$ItemMaterialImpl(
      {@JsonKey(name: 'item_number') required this.itemNumber,
      @JsonKey(name: 'material_id') this.materialId,
      @JsonKey(name: 'material_name') this.materialName = '',
      this.qty = 0.0,
      @JsonKey(name: 'rate_per_unit') this.ratePerUnit = 0.0});

  factory _$ItemMaterialImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemMaterialImplFromJson(json);

  @override
  @JsonKey(name: 'item_number')
  final String itemNumber;
  @override
  @JsonKey(name: 'material_id')
  final int? materialId;
  @override
  @JsonKey(name: 'material_name')
  final String materialName;
  @override
  @JsonKey()
  final double qty;
  @override
  @JsonKey(name: 'rate_per_unit')
  final double ratePerUnit;

  @override
  String toString() {
    return 'ItemMaterial(itemNumber: $itemNumber, materialId: $materialId, materialName: $materialName, qty: $qty, ratePerUnit: $ratePerUnit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemMaterialImpl &&
            (identical(other.itemNumber, itemNumber) ||
                other.itemNumber == itemNumber) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.ratePerUnit, ratePerUnit) ||
                other.ratePerUnit == ratePerUnit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, itemNumber, materialId, materialName, qty, ratePerUnit);

  /// Create a copy of ItemMaterial
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemMaterialImplCopyWith<_$ItemMaterialImpl> get copyWith =>
      __$$ItemMaterialImplCopyWithImpl<_$ItemMaterialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemMaterialImplToJson(
      this,
    );
  }
}

abstract class _ItemMaterial implements ItemMaterial {
  const factory _ItemMaterial(
          {@JsonKey(name: 'item_number') required final String itemNumber,
          @JsonKey(name: 'material_id') final int? materialId,
          @JsonKey(name: 'material_name') final String materialName,
          final double qty,
          @JsonKey(name: 'rate_per_unit') final double ratePerUnit}) =
      _$ItemMaterialImpl;

  factory _ItemMaterial.fromJson(Map<String, dynamic> json) =
      _$ItemMaterialImpl.fromJson;

  @override
  @JsonKey(name: 'item_number')
  String get itemNumber;
  @override
  @JsonKey(name: 'material_id')
  int? get materialId;
  @override
  @JsonKey(name: 'material_name')
  String get materialName;
  @override
  double get qty;
  @override
  @JsonKey(name: 'rate_per_unit')
  double get ratePerUnit;

  /// Create a copy of ItemMaterial
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemMaterialImplCopyWith<_$ItemMaterialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
