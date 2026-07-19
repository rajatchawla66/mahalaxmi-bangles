// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Category _$CategoryFromJson(Map<String, dynamic> json) {
  return _Category.fromJson(json);
}

/// @nodoc
mixin _$Category {
  @JsonKey(name: 'id')
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get icon => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'sub_categories')
  String get subCategories => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_type')
  String get orderType => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_image_url')
  String? get coverImageUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_sizes')
  bool get hasSizes => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_subcategories')
  bool get hasSubcategories => throw _privateConstructorUsedError;
  @JsonKey(name: 'sort_order')
  int get sortOrder => throw _privateConstructorUsedError;
  @JsonKey(name: 'size_chart')
  List<String>? get sizeChart => throw _privateConstructorUsedError;

  /// Serializes this Category to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryCopyWith<Category> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryCopyWith<$Res> {
  factory $CategoryCopyWith(Category value, $Res Function(Category) then) =
      _$CategoryCopyWithImpl<$Res, Category>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      String name,
      String icon,
      String color,
      String description,
      @JsonKey(name: 'sub_categories') String subCategories,
      @JsonKey(name: 'order_type') String orderType,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'cover_image_url') String? coverImageUrl,
      @JsonKey(name: 'has_sizes') bool hasSizes,
      @JsonKey(name: 'has_subcategories') bool hasSubcategories,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'size_chart') List<String>? sizeChart});
}

/// @nodoc
class _$CategoryCopyWithImpl<$Res, $Val extends Category>
    implements $CategoryCopyWith<$Res> {
  _$CategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? icon = null,
    Object? color = null,
    Object? description = null,
    Object? subCategories = null,
    Object? orderType = null,
    Object? isActive = null,
    Object? coverImageUrl = freezed,
    Object? hasSizes = null,
    Object? hasSubcategories = null,
    Object? sortOrder = null,
    Object? sizeChart = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      subCategories: null == subCategories
          ? _value.subCategories
          : subCategories // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      coverImageUrl: freezed == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasSizes: null == hasSizes
          ? _value.hasSizes
          : hasSizes // ignore: cast_nullable_to_non_nullable
              as bool,
      hasSubcategories: null == hasSubcategories
          ? _value.hasSubcategories
          : hasSubcategories // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      sizeChart: freezed == sizeChart
          ? _value.sizeChart
          : sizeChart // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryImplCopyWith<$Res>
    implements $CategoryCopyWith<$Res> {
  factory _$$CategoryImplCopyWith(
          _$CategoryImpl value, $Res Function(_$CategoryImpl) then) =
      __$$CategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      String name,
      String icon,
      String color,
      String description,
      @JsonKey(name: 'sub_categories') String subCategories,
      @JsonKey(name: 'order_type') String orderType,
      @JsonKey(name: 'is_active') bool isActive,
      @JsonKey(name: 'cover_image_url') String? coverImageUrl,
      @JsonKey(name: 'has_sizes') bool hasSizes,
      @JsonKey(name: 'has_subcategories') bool hasSubcategories,
      @JsonKey(name: 'sort_order') int sortOrder,
      @JsonKey(name: 'size_chart') List<String>? sizeChart});
}

/// @nodoc
class __$$CategoryImplCopyWithImpl<$Res>
    extends _$CategoryCopyWithImpl<$Res, _$CategoryImpl>
    implements _$$CategoryImplCopyWith<$Res> {
  __$$CategoryImplCopyWithImpl(
      _$CategoryImpl _value, $Res Function(_$CategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? icon = null,
    Object? color = null,
    Object? description = null,
    Object? subCategories = null,
    Object? orderType = null,
    Object? isActive = null,
    Object? coverImageUrl = freezed,
    Object? hasSizes = null,
    Object? hasSubcategories = null,
    Object? sortOrder = null,
    Object? sizeChart = freezed,
  }) {
    return _then(_$CategoryImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      icon: null == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      subCategories: null == subCategories
          ? _value.subCategories
          : subCategories // ignore: cast_nullable_to_non_nullable
              as String,
      orderType: null == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      coverImageUrl: freezed == coverImageUrl
          ? _value.coverImageUrl
          : coverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      hasSizes: null == hasSizes
          ? _value.hasSizes
          : hasSizes // ignore: cast_nullable_to_non_nullable
              as bool,
      hasSubcategories: null == hasSubcategories
          ? _value.hasSubcategories
          : hasSubcategories // ignore: cast_nullable_to_non_nullable
              as bool,
      sortOrder: null == sortOrder
          ? _value.sortOrder
          : sortOrder // ignore: cast_nullable_to_non_nullable
              as int,
      sizeChart: freezed == sizeChart
          ? _value._sizeChart
          : sizeChart // ignore: cast_nullable_to_non_nullable
              as List<String>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryImpl extends _Category {
  const _$CategoryImpl(
      {@JsonKey(name: 'id') this.id,
      required this.name,
      this.icon = 'CATEGORY',
      this.color = 'GREY_400',
      this.description = '',
      @JsonKey(name: 'sub_categories') this.subCategories = '',
      @JsonKey(name: 'order_type') this.orderType = 'quantity',
      @JsonKey(name: 'is_active') this.isActive = true,
      @JsonKey(name: 'cover_image_url') this.coverImageUrl,
      @JsonKey(name: 'has_sizes') this.hasSizes = false,
      @JsonKey(name: 'has_subcategories') this.hasSubcategories = false,
      @JsonKey(name: 'sort_order') this.sortOrder = 0,
      @JsonKey(name: 'size_chart') final List<String>? sizeChart})
      : _sizeChart = sizeChart,
        super._();

  factory _$CategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int? id;
  @override
  final String name;
  @override
  @JsonKey()
  final String icon;
  @override
  @JsonKey()
  final String color;
  @override
  @JsonKey()
  final String description;
  @override
  @JsonKey(name: 'sub_categories')
  final String subCategories;
  @override
  @JsonKey(name: 'order_type')
  final String orderType;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  @override
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @override
  @JsonKey(name: 'has_sizes')
  final bool hasSizes;
  @override
  @JsonKey(name: 'has_subcategories')
  final bool hasSubcategories;
  @override
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  final List<String>? _sizeChart;
  @override
  @JsonKey(name: 'size_chart')
  List<String>? get sizeChart {
    final value = _sizeChart;
    if (value == null) return null;
    if (_sizeChart is EqualUnmodifiableListView) return _sizeChart;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, icon: $icon, color: $color, description: $description, subCategories: $subCategories, orderType: $orderType, isActive: $isActive, coverImageUrl: $coverImageUrl, hasSizes: $hasSizes, hasSubcategories: $hasSubcategories, sortOrder: $sortOrder, sizeChart: $sizeChart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.subCategories, subCategories) ||
                other.subCategories == subCategories) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.coverImageUrl, coverImageUrl) ||
                other.coverImageUrl == coverImageUrl) &&
            (identical(other.hasSizes, hasSizes) ||
                other.hasSizes == hasSizes) &&
            (identical(other.hasSubcategories, hasSubcategories) ||
                other.hasSubcategories == hasSubcategories) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            const DeepCollectionEquality()
                .equals(other._sizeChart, _sizeChart));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      icon,
      color,
      description,
      subCategories,
      orderType,
      isActive,
      coverImageUrl,
      hasSizes,
      hasSubcategories,
      sortOrder,
      const DeepCollectionEquality().hash(_sizeChart));

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      __$$CategoryImplCopyWithImpl<_$CategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryImplToJson(
      this,
    );
  }
}

abstract class _Category extends Category {
  const factory _Category(
          {@JsonKey(name: 'id') final int? id,
          required final String name,
          final String icon,
          final String color,
          final String description,
          @JsonKey(name: 'sub_categories') final String subCategories,
          @JsonKey(name: 'order_type') final String orderType,
          @JsonKey(name: 'is_active') final bool isActive,
          @JsonKey(name: 'cover_image_url') final String? coverImageUrl,
          @JsonKey(name: 'has_sizes') final bool hasSizes,
          @JsonKey(name: 'has_subcategories') final bool hasSubcategories,
          @JsonKey(name: 'sort_order') final int sortOrder,
          @JsonKey(name: 'size_chart') final List<String>? sizeChart}) =
      _$CategoryImpl;
  const _Category._() : super._();

  factory _Category.fromJson(Map<String, dynamic> json) =
      _$CategoryImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int? get id;
  @override
  String get name;
  @override
  String get icon;
  @override
  String get color;
  @override
  String get description;
  @override
  @JsonKey(name: 'sub_categories')
  String get subCategories;
  @override
  @JsonKey(name: 'order_type')
  String get orderType;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  @JsonKey(name: 'cover_image_url')
  String? get coverImageUrl;
  @override
  @JsonKey(name: 'has_sizes')
  bool get hasSizes;
  @override
  @JsonKey(name: 'has_subcategories')
  bool get hasSubcategories;
  @override
  @JsonKey(name: 'sort_order')
  int get sortOrder;
  @override
  @JsonKey(name: 'size_chart')
  List<String>? get sizeChart;

  /// Create a copy of Category
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryImplCopyWith<_$CategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
