// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vendor_price.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VendorPrice _$VendorPriceFromJson(Map<String, dynamic> json) {
  return _VendorPrice.fromJson(json);
}

/// @nodoc
mixin _$VendorPrice {
  @JsonKey(name: 'id')
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_name')
  String get itemName => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'vendor_name')
  String get vendorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_price')
  double get costPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'margin_type')
  String get marginType => throw _privateConstructorUsedError;
  @JsonKey(name: 'margin_value')
  double get marginValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'selling_price')
  double get sellingPrice => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this VendorPrice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VendorPrice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VendorPriceCopyWith<VendorPrice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VendorPriceCopyWith<$Res> {
  factory $VendorPriceCopyWith(
          VendorPrice value, $Res Function(VendorPrice) then) =
      _$VendorPriceCopyWithImpl<$Res, VendorPrice>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'item_name') String itemName,
      String? category,
      @JsonKey(name: 'vendor_name') String vendorName,
      @JsonKey(name: 'cost_price') double costPrice,
      @JsonKey(name: 'margin_type') String marginType,
      @JsonKey(name: 'margin_value') double marginValue,
      @JsonKey(name: 'selling_price') double sellingPrice,
      String? notes,
      @JsonKey(name: 'created_by') String createdBy,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$VendorPriceCopyWithImpl<$Res, $Val extends VendorPrice>
    implements $VendorPriceCopyWith<$Res> {
  _$VendorPriceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VendorPrice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemName = null,
    Object? category = freezed,
    Object? vendorName = null,
    Object? costPrice = null,
    Object? marginType = null,
    Object? marginValue = null,
    Object? sellingPrice = null,
    Object? notes = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
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
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      vendorName: null == vendorName
          ? _value.vendorName
          : vendorName // ignore: cast_nullable_to_non_nullable
              as String,
      costPrice: null == costPrice
          ? _value.costPrice
          : costPrice // ignore: cast_nullable_to_non_nullable
              as double,
      marginType: null == marginType
          ? _value.marginType
          : marginType // ignore: cast_nullable_to_non_nullable
              as String,
      marginValue: null == marginValue
          ? _value.marginValue
          : marginValue // ignore: cast_nullable_to_non_nullable
              as double,
      sellingPrice: null == sellingPrice
          ? _value.sellingPrice
          : sellingPrice // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VendorPriceImplCopyWith<$Res>
    implements $VendorPriceCopyWith<$Res> {
  factory _$$VendorPriceImplCopyWith(
          _$VendorPriceImpl value, $Res Function(_$VendorPriceImpl) then) =
      __$$VendorPriceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') String? id,
      @JsonKey(name: 'item_name') String itemName,
      String? category,
      @JsonKey(name: 'vendor_name') String vendorName,
      @JsonKey(name: 'cost_price') double costPrice,
      @JsonKey(name: 'margin_type') String marginType,
      @JsonKey(name: 'margin_value') double marginValue,
      @JsonKey(name: 'selling_price') double sellingPrice,
      String? notes,
      @JsonKey(name: 'created_by') String createdBy,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$VendorPriceImplCopyWithImpl<$Res>
    extends _$VendorPriceCopyWithImpl<$Res, _$VendorPriceImpl>
    implements _$$VendorPriceImplCopyWith<$Res> {
  __$$VendorPriceImplCopyWithImpl(
      _$VendorPriceImpl _value, $Res Function(_$VendorPriceImpl) _then)
      : super(_value, _then);

  /// Create a copy of VendorPrice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? itemName = null,
    Object? category = freezed,
    Object? vendorName = null,
    Object? costPrice = null,
    Object? marginType = null,
    Object? marginValue = null,
    Object? sellingPrice = null,
    Object? notes = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
  }) {
    return _then(_$VendorPriceImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      itemName: null == itemName
          ? _value.itemName
          : itemName // ignore: cast_nullable_to_non_nullable
              as String,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      vendorName: null == vendorName
          ? _value.vendorName
          : vendorName // ignore: cast_nullable_to_non_nullable
              as String,
      costPrice: null == costPrice
          ? _value.costPrice
          : costPrice // ignore: cast_nullable_to_non_nullable
              as double,
      marginType: null == marginType
          ? _value.marginType
          : marginType // ignore: cast_nullable_to_non_nullable
              as String,
      marginValue: null == marginValue
          ? _value.marginValue
          : marginValue // ignore: cast_nullable_to_non_nullable
              as double,
      sellingPrice: null == sellingPrice
          ? _value.sellingPrice
          : sellingPrice // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: null == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VendorPriceImpl implements _VendorPrice {
  const _$VendorPriceImpl(
      {@JsonKey(name: 'id') this.id,
      @JsonKey(name: 'item_name') required this.itemName,
      this.category,
      @JsonKey(name: 'vendor_name') required this.vendorName,
      @JsonKey(name: 'cost_price') required this.costPrice,
      @JsonKey(name: 'margin_type') this.marginType = 'percent',
      @JsonKey(name: 'margin_value') this.marginValue = 0,
      @JsonKey(name: 'selling_price') required this.sellingPrice,
      this.notes,
      @JsonKey(name: 'created_by') this.createdBy = '',
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$VendorPriceImpl.fromJson(Map<String, dynamic> json) =>
      _$$VendorPriceImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final String? id;
  @override
  @JsonKey(name: 'item_name')
  final String itemName;
  @override
  final String? category;
  @override
  @JsonKey(name: 'vendor_name')
  final String vendorName;
  @override
  @JsonKey(name: 'cost_price')
  final double costPrice;
  @override
  @JsonKey(name: 'margin_type')
  final String marginType;
  @override
  @JsonKey(name: 'margin_value')
  final double marginValue;
  @override
  @JsonKey(name: 'selling_price')
  final double sellingPrice;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'VendorPrice(id: $id, itemName: $itemName, category: $category, vendorName: $vendorName, costPrice: $costPrice, marginType: $marginType, marginValue: $marginValue, sellingPrice: $sellingPrice, notes: $notes, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VendorPriceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.itemName, itemName) ||
                other.itemName == itemName) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.vendorName, vendorName) ||
                other.vendorName == vendorName) &&
            (identical(other.costPrice, costPrice) ||
                other.costPrice == costPrice) &&
            (identical(other.marginType, marginType) ||
                other.marginType == marginType) &&
            (identical(other.marginValue, marginValue) ||
                other.marginValue == marginValue) &&
            (identical(other.sellingPrice, sellingPrice) ||
                other.sellingPrice == sellingPrice) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      itemName,
      category,
      vendorName,
      costPrice,
      marginType,
      marginValue,
      sellingPrice,
      notes,
      createdBy,
      createdAt);

  /// Create a copy of VendorPrice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VendorPriceImplCopyWith<_$VendorPriceImpl> get copyWith =>
      __$$VendorPriceImplCopyWithImpl<_$VendorPriceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VendorPriceImplToJson(
      this,
    );
  }
}

abstract class _VendorPrice implements VendorPrice {
  const factory _VendorPrice(
          {@JsonKey(name: 'id') final String? id,
          @JsonKey(name: 'item_name') required final String itemName,
          final String? category,
          @JsonKey(name: 'vendor_name') required final String vendorName,
          @JsonKey(name: 'cost_price') required final double costPrice,
          @JsonKey(name: 'margin_type') final String marginType,
          @JsonKey(name: 'margin_value') final double marginValue,
          @JsonKey(name: 'selling_price') required final double sellingPrice,
          final String? notes,
          @JsonKey(name: 'created_by') final String createdBy,
          @JsonKey(name: 'created_at') final DateTime? createdAt}) =
      _$VendorPriceImpl;

  factory _VendorPrice.fromJson(Map<String, dynamic> json) =
      _$VendorPriceImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  String? get id;
  @override
  @JsonKey(name: 'item_name')
  String get itemName;
  @override
  String? get category;
  @override
  @JsonKey(name: 'vendor_name')
  String get vendorName;
  @override
  @JsonKey(name: 'cost_price')
  double get costPrice;
  @override
  @JsonKey(name: 'margin_type')
  String get marginType;
  @override
  @JsonKey(name: 'margin_value')
  double get marginValue;
  @override
  @JsonKey(name: 'selling_price')
  double get sellingPrice;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of VendorPrice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VendorPriceImplCopyWith<_$VendorPriceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
