// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cost_breakdown.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CostBreakdown _$CostBreakdownFromJson(Map<String, dynamic> json) {
  return _CostBreakdown.fromJson(json);
}

/// @nodoc
mixin _$CostBreakdown {
  @JsonKey(name: 'id')
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_number')
  String get itemNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_id')
  int? get materialId => throw _privateConstructorUsedError;
  @JsonKey(name: 'material_name')
  String get materialName => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String get unit => throw _privateConstructorUsedError;
  @JsonKey(name: 'rate_per_unit')
  double get ratePerUnit => throw _privateConstructorUsedError;
  @JsonKey(name: 'line_total')
  double get lineTotal => throw _privateConstructorUsedError;

  /// Serializes this CostBreakdown to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CostBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CostBreakdownCopyWith<CostBreakdown> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CostBreakdownCopyWith<$Res> {
  factory $CostBreakdownCopyWith(
          CostBreakdown value, $Res Function(CostBreakdown) then) =
      _$CostBreakdownCopyWithImpl<$Res, CostBreakdown>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      @JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'material_id') int? materialId,
      @JsonKey(name: 'material_name') String materialName,
      double quantity,
      String unit,
      @JsonKey(name: 'rate_per_unit') double ratePerUnit,
      @JsonKey(name: 'line_total') double lineTotal});
}

/// @nodoc
class _$CostBreakdownCopyWithImpl<$Res, $Val extends CostBreakdown>
    implements $CostBreakdownCopyWith<$Res> {
  _$CostBreakdownCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CostBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemNumber = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? quantity = null,
    Object? unit = null,
    Object? ratePerUnit = null,
    Object? lineTotal = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
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
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      ratePerUnit: null == ratePerUnit
          ? _value.ratePerUnit
          : ratePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      lineTotal: null == lineTotal
          ? _value.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CostBreakdownImplCopyWith<$Res>
    implements $CostBreakdownCopyWith<$Res> {
  factory _$$CostBreakdownImplCopyWith(
          _$CostBreakdownImpl value, $Res Function(_$CostBreakdownImpl) then) =
      __$$CostBreakdownImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      @JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'material_id') int? materialId,
      @JsonKey(name: 'material_name') String materialName,
      double quantity,
      String unit,
      @JsonKey(name: 'rate_per_unit') double ratePerUnit,
      @JsonKey(name: 'line_total') double lineTotal});
}

/// @nodoc
class __$$CostBreakdownImplCopyWithImpl<$Res>
    extends _$CostBreakdownCopyWithImpl<$Res, _$CostBreakdownImpl>
    implements _$$CostBreakdownImplCopyWith<$Res> {
  __$$CostBreakdownImplCopyWithImpl(
      _$CostBreakdownImpl _value, $Res Function(_$CostBreakdownImpl) _then)
      : super(_value, _then);

  /// Create a copy of CostBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemNumber = null,
    Object? materialId = freezed,
    Object? materialName = null,
    Object? quantity = null,
    Object? unit = null,
    Object? ratePerUnit = null,
    Object? lineTotal = null,
  }) {
    return _then(_$CostBreakdownImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
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
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: null == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String,
      ratePerUnit: null == ratePerUnit
          ? _value.ratePerUnit
          : ratePerUnit // ignore: cast_nullable_to_non_nullable
              as double,
      lineTotal: null == lineTotal
          ? _value.lineTotal
          : lineTotal // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CostBreakdownImpl implements _CostBreakdown {
  const _$CostBreakdownImpl(
      {@JsonKey(name: 'id') this.id,
      @JsonKey(name: 'item_number') required this.itemNumber,
      @JsonKey(name: 'material_id') this.materialId,
      @JsonKey(name: 'material_name') this.materialName = '',
      this.quantity = 0.0,
      this.unit = 'pcs',
      @JsonKey(name: 'rate_per_unit') this.ratePerUnit = 0.0,
      @JsonKey(name: 'line_total') this.lineTotal = 0.0});

  factory _$CostBreakdownImpl.fromJson(Map<String, dynamic> json) =>
      _$$CostBreakdownImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int? id;
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
  final double quantity;
  @override
  @JsonKey()
  final String unit;
  @override
  @JsonKey(name: 'rate_per_unit')
  final double ratePerUnit;
  @override
  @JsonKey(name: 'line_total')
  final double lineTotal;

  @override
  String toString() {
    return 'CostBreakdown(id: $id, itemNumber: $itemNumber, materialId: $materialId, materialName: $materialName, quantity: $quantity, unit: $unit, ratePerUnit: $ratePerUnit, lineTotal: $lineTotal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CostBreakdownImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemNumber, itemNumber) ||
                other.itemNumber == itemNumber) &&
            (identical(other.materialId, materialId) ||
                other.materialId == materialId) &&
            (identical(other.materialName, materialName) ||
                other.materialName == materialName) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.ratePerUnit, ratePerUnit) ||
                other.ratePerUnit == ratePerUnit) &&
            (identical(other.lineTotal, lineTotal) ||
                other.lineTotal == lineTotal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, itemNumber, materialId,
      materialName, quantity, unit, ratePerUnit, lineTotal);

  /// Create a copy of CostBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CostBreakdownImplCopyWith<_$CostBreakdownImpl> get copyWith =>
      __$$CostBreakdownImplCopyWithImpl<_$CostBreakdownImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CostBreakdownImplToJson(
      this,
    );
  }
}

abstract class _CostBreakdown implements CostBreakdown {
  const factory _CostBreakdown(
          {@JsonKey(name: 'id') final int? id,
          @JsonKey(name: 'item_number') required final String itemNumber,
          @JsonKey(name: 'material_id') final int? materialId,
          @JsonKey(name: 'material_name') final String materialName,
          final double quantity,
          final String unit,
          @JsonKey(name: 'rate_per_unit') final double ratePerUnit,
          @JsonKey(name: 'line_total') final double lineTotal}) =
      _$CostBreakdownImpl;

  factory _CostBreakdown.fromJson(Map<String, dynamic> json) =
      _$CostBreakdownImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int? get id;
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
  double get quantity;
  @override
  String get unit;
  @override
  @JsonKey(name: 'rate_per_unit')
  double get ratePerUnit;
  @override
  @JsonKey(name: 'line_total')
  double get lineTotal;

  /// Create a copy of CostBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CostBreakdownImplCopyWith<_$CostBreakdownImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
