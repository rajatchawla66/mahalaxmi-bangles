// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cost_calculation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CostCalculation _$CostCalculationFromJson(Map<String, dynamic> json) {
  return _CostCalculation.fromJson(json);
}

/// @nodoc
mixin _$CostCalculation {
  @JsonKey(name: 'id', includeIfNull: false)
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_number')
  String? get itemNumber => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_category')
  String? get subCategory => throw _privateConstructorUsedError;
  Map<String, dynamic> get materials => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_cost')
  double get totalCost => throw _privateConstructorUsedError;
  @JsonKey(name: 'costing_type')
  String get costingType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_by')
  String get updatedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CostCalculation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CostCalculation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CostCalculationCopyWith<CostCalculation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CostCalculationCopyWith<$Res> {
  factory $CostCalculationCopyWith(
          CostCalculation value, $Res Function(CostCalculation) then) =
      _$CostCalculationCopyWithImpl<$Res, CostCalculation>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id', includeIfNull: false) String? id,
      @JsonKey(name: 'item_name') String itemName,
      @JsonKey(name: 'item_number') String? itemNumber,
      String category,
      @JsonKey(name: 'sub_category') String? subCategory,
      Map<String, dynamic> materials,
      @JsonKey(name: 'total_cost') double totalCost,
      @JsonKey(name: 'costing_type') String costingType,
      @JsonKey(name: 'created_by') String createdBy,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_by') String updatedBy,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$CostCalculationCopyWithImpl<$Res, $Val extends CostCalculation>
    implements $CostCalculationCopyWith<$Res> {
  _$CostCalculationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CostCalculation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemName = null,
    Object? itemNumber = freezed,
    Object? category = null,
    Object? subCategory = freezed,
    Object? materials = null,
    Object? totalCost = null,
    Object? costingType = null,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedBy = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      itemNumber: freezed == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      materials: null == materials
          ? _value.materials
          : materials // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      totalCost: null == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double,
      costingType: null == costingType
          ? _value.costingType
          : costingType // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedBy: null == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CostCalculationImplCopyWith<$Res>
    implements $CostCalculationCopyWith<$Res> {
  factory _$$CostCalculationImplCopyWith(_$CostCalculationImpl value,
          $Res Function(_$CostCalculationImpl) then) =
      __$$CostCalculationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id', includeIfNull: false) String? id,
      @JsonKey(name: 'item_name') String itemName,
      @JsonKey(name: 'item_number') String? itemNumber,
      String category,
      @JsonKey(name: 'sub_category') String? subCategory,
      Map<String, dynamic> materials,
      @JsonKey(name: 'total_cost') double totalCost,
      @JsonKey(name: 'costing_type') String costingType,
      @JsonKey(name: 'created_by') String createdBy,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_by') String updatedBy,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$CostCalculationImplCopyWithImpl<$Res>
    extends _$CostCalculationCopyWithImpl<$Res, _$CostCalculationImpl>
    implements _$$CostCalculationImplCopyWith<$Res> {
  __$$CostCalculationImplCopyWithImpl(
      _$CostCalculationImpl _value, $Res Function(_$CostCalculationImpl) _then)
      : super(_value, _then);

  /// Create a copy of CostCalculation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemName = null,
    Object? itemNumber = freezed,
    Object? category = null,
    Object? subCategory = freezed,
    Object? materials = null,
    Object? totalCost = null,
    Object? costingType = null,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedBy = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CostCalculationImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      itemNumber: freezed == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      materials: null == materials
          ? _value._materials
          : materials // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      totalCost: null == totalCost
          ? _value.totalCost
          : totalCost // ignore: cast_nullable_to_non_nullable
              as double,
      costingType: null == costingType
          ? _value.costingType
          : costingType // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedBy: null == updatedBy
          ? _value.updatedBy
          : updatedBy // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CostCalculationImpl extends _CostCalculation {
  const _$CostCalculationImpl(
      {@JsonKey(name: 'id', includeIfNull: false) this.id,
      @JsonKey(name: 'item_name') required this.itemName,
      @JsonKey(name: 'item_number') this.itemNumber,
      this.category = '',
      @JsonKey(name: 'sub_category') this.subCategory,
      final Map<String, dynamic> materials = const {},
      @JsonKey(name: 'total_cost') this.totalCost = 0,
      @JsonKey(name: 'costing_type') this.costingType = 'manufacturing',
      @JsonKey(name: 'created_by') this.createdBy = '',
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_by') this.updatedBy = '',
      @JsonKey(name: 'updated_at') this.updatedAt})
      : _materials = materials,
        super._();

  factory _$CostCalculationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CostCalculationImplFromJson(json);

  @override
  @JsonKey(name: 'id', includeIfNull: false)
  final String? id;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  @JsonKey(name: 'item_number')
  final String? itemNumber;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey(name: 'sub_category')
  final String? subCategory;
  final Map<String, dynamic> _materials;
  @override
  @JsonKey()
  Map<String, dynamic> get materials {
    if (_materials is EqualUnmodifiableMapView) return _materials;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_materials);
  }

  @override
  @JsonKey(name: 'total_cost')
  final double totalCost;
  @override
  @JsonKey(name: 'costing_type')
  final String costingType;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_by')
  final String updatedBy;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CostCalculation(id: $id, itemName: $itemName, itemNumber: $itemNumber, category: $category, subCategory: $subCategory, materials: $materials, totalCost: $totalCost, costingType: $costingType, createdBy: $createdBy, createdAt: $createdAt, updatedBy: $updatedBy, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CostCalculationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.itemNumber, itemNumber) ||
                other.itemNumber == itemNumber) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subCategory, subCategory) ||
                other.subCategory == subCategory) &&
            const DeepCollectionEquality()
                .equals(other._materials, _materials) &&
            (identical(other.totalCost, totalCost) ||
                other.totalCost == totalCost) &&
            (identical(other.costingType, costingType) ||
                other.costingType == costingType) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedBy, updatedBy) ||
                other.updatedBy == updatedBy) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      itemName,
      itemNumber,
      category,
      subCategory,
      const DeepCollectionEquality().hash(_materials),
      totalCost,
      costingType,
      createdBy,
      createdAt,
      updatedBy,
      updatedAt);

  /// Create a copy of CostCalculation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CostCalculationImplCopyWith<_$CostCalculationImpl> get copyWith =>
      __$$CostCalculationImplCopyWithImpl<_$CostCalculationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CostCalculationImplToJson(
      this,
    );
  }
}

abstract class _CostCalculation extends CostCalculation {
  const factory _CostCalculation(
          {@JsonKey(name: 'id', includeIfNull: false) final String? id,
          @JsonKey(name: 'item_name') required final String itemName,
          @JsonKey(name: 'item_number') final String? itemNumber,
          final String category,
          @JsonKey(name: 'sub_category') final String? subCategory,
          final Map<String, dynamic> materials,
          @JsonKey(name: 'total_cost') final double totalCost,
          @JsonKey(name: 'costing_type') final String costingType,
          @JsonKey(name: 'created_by') final String createdBy,
          @JsonKey(name: 'created_at') final DateTime? createdAt,
          @JsonKey(name: 'updated_by') final String updatedBy,
          @JsonKey(name: 'updated_at') final DateTime? updatedAt}) =
      _$CostCalculationImpl;
  const _CostCalculation._() : super._();

  factory _CostCalculation.fromJson(Map<String, dynamic> json) =
      _$CostCalculationImpl.fromJson;

  @override
  @JsonKey(name: 'id', includeIfNull: false)
  String? get id;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  @JsonKey(name: 'item_number')
  String? get itemNumber;
  @override
  String get category;
  @override
  @JsonKey(name: 'sub_category')
  String? get subCategory;
  @override
  Map<String, dynamic> get materials;
  @override
  @JsonKey(name: 'total_cost')
  double get totalCost;
  @override
  @JsonKey(name: 'costing_type')
  String get costingType;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_by')
  String get updatedBy;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of CostCalculation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CostCalculationImplCopyWith<_$CostCalculationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
