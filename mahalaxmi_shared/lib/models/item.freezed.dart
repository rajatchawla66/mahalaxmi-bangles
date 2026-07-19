// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RateItem _$RateItemFromJson(Map<String, dynamic> json) {
  return _RateItem.fromJson(json);
}

/// @nodoc
mixin _$RateItem {
  @JsonKey(name: 'item_number')
  String get itemNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String get imageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost_price')
  double get costPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'selling_price')
  double get sellingPrice => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_category')
  String? get subCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_sizes')
  bool get hasSizes => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_color')
  bool get hasColor => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_available')
  bool get isAvailable => throw _privateConstructorUsedError;
  @JsonKey(name: 'margin_percent')
  double get marginPercent => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  @JsonKey(name: 'available_sizes')
  List<String>? get availableSizes => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this RateItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RateItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RateItemCopyWith<RateItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RateItemCopyWith<$Res> {
  factory $RateItemCopyWith(RateItem value, $Res Function(RateItem) then) =
      _$RateItemCopyWithImpl<$Res, RateItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'cost_price') double costPrice,
      @JsonKey(name: 'selling_price') double sellingPrice,
      String category,
      @JsonKey(name: 'sub_category') String? subCategory,
      @JsonKey(name: 'has_sizes') bool hasSizes,
      @JsonKey(name: 'has_color') bool hasColor,
      @JsonKey(name: 'is_available') bool isAvailable,
      @JsonKey(name: 'margin_percent') double marginPercent,
      String status,
      List<String> tags,
      @JsonKey(name: 'available_sizes') List<String>? availableSizes,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$RateItemCopyWithImpl<$Res, $Val extends RateItem>
    implements $RateItemCopyWith<$Res> {
  _$RateItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RateItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemNumber = null,
    Object? imageUrl = null,
    Object? costPrice = null,
    Object? sellingPrice = null,
    Object? category = null,
    Object? subCategory = freezed,
    Object? hasSizes = null,
    Object? hasColor = null,
    Object? isAvailable = null,
    Object? marginPercent = null,
    Object? status = null,
    Object? tags = null,
    Object? availableSizes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      costPrice: null == costPrice
          ? _value.costPrice
          : costPrice // ignore: cast_nullable_to_non_nullable
              as double,
      sellingPrice: null == sellingPrice
          ? _value.sellingPrice
          : sellingPrice // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      hasSizes: null == hasSizes
          ? _value.hasSizes
          : hasSizes // ignore: cast_nullable_to_non_nullable
              as bool,
      hasColor: null == hasColor
          ? _value.hasColor
          : hasColor // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      marginPercent: null == marginPercent
          ? _value.marginPercent
          : marginPercent // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableSizes: freezed == availableSizes
          ? _value.availableSizes
          : availableSizes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RateItemImplCopyWith<$Res>
    implements $RateItemCopyWith<$Res> {
  factory _$$RateItemImplCopyWith(
          _$RateItemImpl value, $Res Function(_$RateItemImpl) then) =
      __$$RateItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'item_number') String itemNumber,
      @JsonKey(name: 'image_url') String imageUrl,
      @JsonKey(name: 'cost_price') double costPrice,
      @JsonKey(name: 'selling_price') double sellingPrice,
      String category,
      @JsonKey(name: 'sub_category') String? subCategory,
      @JsonKey(name: 'has_sizes') bool hasSizes,
      @JsonKey(name: 'has_color') bool hasColor,
      @JsonKey(name: 'is_available') bool isAvailable,
      @JsonKey(name: 'margin_percent') double marginPercent,
      String status,
      List<String> tags,
      @JsonKey(name: 'available_sizes') List<String>? availableSizes,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$RateItemImplCopyWithImpl<$Res>
    extends _$RateItemCopyWithImpl<$Res, _$RateItemImpl>
    implements _$$RateItemImplCopyWith<$Res> {
  __$$RateItemImplCopyWithImpl(
      _$RateItemImpl _value, $Res Function(_$RateItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of RateItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? itemNumber = null,
    Object? imageUrl = null,
    Object? costPrice = null,
    Object? sellingPrice = null,
    Object? category = null,
    Object? subCategory = freezed,
    Object? hasSizes = null,
    Object? hasColor = null,
    Object? isAvailable = null,
    Object? marginPercent = null,
    Object? status = null,
    Object? tags = null,
    Object? availableSizes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$RateItemImpl(
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      costPrice: null == costPrice
          ? _value.costPrice
          : costPrice // ignore: cast_nullable_to_non_nullable
              as double,
      sellingPrice: null == sellingPrice
          ? _value.sellingPrice
          : sellingPrice // ignore: cast_nullable_to_non_nullable
              as double,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      subCategory: freezed == subCategory
          ? _value.subCategory
          : subCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      hasSizes: null == hasSizes
          ? _value.hasSizes
          : hasSizes // ignore: cast_nullable_to_non_nullable
              as bool,
      hasColor: null == hasColor
          ? _value.hasColor
          : hasColor // ignore: cast_nullable_to_non_nullable
              as bool,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      marginPercent: null == marginPercent
          ? _value.marginPercent
          : marginPercent // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      availableSizes: freezed == availableSizes
          ? _value._availableSizes
          : availableSizes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RateItemImpl implements _RateItem {
  const _$RateItemImpl(
      {@JsonKey(name: 'item_number') required this.itemNumber,
      @JsonKey(name: 'image_url') this.imageUrl = '',
      @JsonKey(name: 'cost_price') this.costPrice = 0.0,
      @JsonKey(name: 'selling_price') this.sellingPrice = 0.0,
      required this.category,
      @JsonKey(name: 'sub_category') this.subCategory,
      @JsonKey(name: 'has_sizes') this.hasSizes = false,
      @JsonKey(name: 'has_color') this.hasColor = false,
      @JsonKey(name: 'is_available') this.isAvailable = true,
      @JsonKey(name: 'margin_percent') this.marginPercent = 0.0,
      this.status = 'new',
      final List<String> tags = const <String>[],
      @JsonKey(name: 'available_sizes') final List<String>? availableSizes,
      @JsonKey(name: 'created_at') this.createdAt})
      : _tags = tags,
        _availableSizes = availableSizes;

  factory _$RateItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$RateItemImplFromJson(json);

  @override
  @JsonKey(name: 'item_number')
  final String itemNumber;
  @override
  @JsonKey(name: 'image_url')
  final String imageUrl;
  @override
  @JsonKey(name: 'cost_price')
  final double costPrice;
  @override
  @JsonKey(name: 'selling_price')
  final double sellingPrice;
  @override
  final String category;
  @override
  @JsonKey(name: 'sub_category')
  final String? subCategory;
  @override
  @JsonKey(name: 'has_sizes')
  final bool hasSizes;
  @override
  @JsonKey(name: 'has_color')
  final bool hasColor;
  @override
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @override
  @JsonKey(name: 'margin_percent')
  final double marginPercent;
  @override
  @JsonKey()
  final String status;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<String>? _availableSizes;
  @override
  @JsonKey(name: 'available_sizes')
  List<String>? get availableSizes {
    final value = _availableSizes;
    if (value == null) return null;
    if (_availableSizes is EqualUnmodifiableListView) return _availableSizes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'RateItem(itemNumber: $itemNumber, imageUrl: $imageUrl, costPrice: $costPrice, sellingPrice: $sellingPrice, category: $category, subCategory: $subCategory, hasSizes: $hasSizes, hasColor: $hasColor, isAvailable: $isAvailable, marginPercent: $marginPercent, status: $status, tags: $tags, availableSizes: $availableSizes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RateItemImpl &&
            (identical(other.itemNumber, itemNumber) ||
                other.itemNumber == itemNumber) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.costPrice, costPrice) ||
                other.costPrice == costPrice) &&
            (identical(other.sellingPrice, sellingPrice) ||
                other.sellingPrice == sellingPrice) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.subCategory, subCategory) ||
                other.subCategory == subCategory) &&
            (identical(other.hasSizes, hasSizes) ||
                other.hasSizes == hasSizes) &&
            (identical(other.hasColor, hasColor) ||
                other.hasColor == hasColor) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            (identical(other.marginPercent, marginPercent) ||
                other.marginPercent == marginPercent) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._availableSizes, _availableSizes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      itemNumber,
      imageUrl,
      costPrice,
      sellingPrice,
      category,
      subCategory,
      hasSizes,
      hasColor,
      isAvailable,
      marginPercent,
      status,
      const DeepCollectionEquality().hash(_tags),
      const DeepCollectionEquality().hash(_availableSizes),
      createdAt);

  /// Create a copy of RateItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RateItemImplCopyWith<_$RateItemImpl> get copyWith =>
      __$$RateItemImplCopyWithImpl<_$RateItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RateItemImplToJson(
      this,
    );
  }
}

abstract class _RateItem implements RateItem {
  const factory _RateItem(
      {@JsonKey(name: 'item_number') required final String itemNumber,
      @JsonKey(name: 'image_url') final String imageUrl,
      @JsonKey(name: 'cost_price') final double costPrice,
      @JsonKey(name: 'selling_price') final double sellingPrice,
      required final String category,
      @JsonKey(name: 'sub_category') final String? subCategory,
      @JsonKey(name: 'has_sizes') final bool hasSizes,
      @JsonKey(name: 'has_color') final bool hasColor,
      @JsonKey(name: 'is_available') final bool isAvailable,
      @JsonKey(name: 'margin_percent') final double marginPercent,
      final String status,
      final List<String> tags,
      @JsonKey(name: 'available_sizes') final List<String>? availableSizes,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$RateItemImpl;

  factory _RateItem.fromJson(Map<String, dynamic> json) =
      _$RateItemImpl.fromJson;

  @override
  @JsonKey(name: 'item_number')
  String get itemNumber;
  @override
  @JsonKey(name: 'image_url')
  String get imageUrl;
  @override
  @JsonKey(name: 'cost_price')
  double get costPrice;
  @override
  @JsonKey(name: 'selling_price')
  double get sellingPrice;
  @override
  String get category;
  @override
  @JsonKey(name: 'sub_category')
  String? get subCategory;
  @override
  @JsonKey(name: 'has_sizes')
  bool get hasSizes;
  @override
  @JsonKey(name: 'has_color')
  bool get hasColor;
  @override
  @JsonKey(name: 'is_available')
  bool get isAvailable;
  @override
  @JsonKey(name: 'margin_percent')
  double get marginPercent;
  @override
  String get status;
  @override
  List<String> get tags;
  @override
  @JsonKey(name: 'available_sizes')
  List<String>? get availableSizes;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of RateItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RateItemImplCopyWith<_$RateItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
