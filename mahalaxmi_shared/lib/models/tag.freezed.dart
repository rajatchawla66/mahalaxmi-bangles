// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TagMaster _$TagMasterFromJson(Map<String, dynamic> json) {
  return _TagMaster.fromJson(json);
}

/// @nodoc
mixin _$TagMaster {
  @JsonKey(name: 'id')
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'display_name')
  String get displayName => throw _privateConstructorUsedError;
  @JsonKey(name: 'category')
  String? get legacyCategory => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;
  List<String> get categories => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  String? get deletedAt => throw _privateConstructorUsedError;

  /// Serializes this TagMaster to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TagMaster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TagMasterCopyWith<TagMaster> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TagMasterCopyWith<$Res> {
  factory $TagMasterCopyWith(TagMaster value, $Res Function(TagMaster) then) =
      _$TagMasterCopyWithImpl<$Res, TagMaster>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      String name,
      @JsonKey(name: 'display_name') String displayName,
      @JsonKey(name: 'category') String? legacyCategory,
      @JsonKey(name: 'is_active') bool isActive,
      List<String> categories,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'deleted_at') String? deletedAt});
}

/// @nodoc
class _$TagMasterCopyWithImpl<$Res, $Val extends TagMaster>
    implements $TagMasterCopyWith<$Res> {
  _$TagMasterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TagMaster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? displayName = null,
    Object? legacyCategory = freezed,
    Object? isActive = null,
    Object? categories = null,
    Object? createdAt = freezed,
    Object? deletedAt = freezed,
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
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      legacyCategory: freezed == legacyCategory
          ? _value.legacyCategory
          : legacyCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TagMasterImplCopyWith<$Res>
    implements $TagMasterCopyWith<$Res> {
  factory _$$TagMasterImplCopyWith(
          _$TagMasterImpl value, $Res Function(_$TagMasterImpl) then) =
      __$$TagMasterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id') int? id,
      String name,
      @JsonKey(name: 'display_name') String displayName,
      @JsonKey(name: 'category') String? legacyCategory,
      @JsonKey(name: 'is_active') bool isActive,
      List<String> categories,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'deleted_at') String? deletedAt});
}

/// @nodoc
class __$$TagMasterImplCopyWithImpl<$Res>
    extends _$TagMasterCopyWithImpl<$Res, _$TagMasterImpl>
    implements _$$TagMasterImplCopyWith<$Res> {
  __$$TagMasterImplCopyWithImpl(
      _$TagMasterImpl _value, $Res Function(_$TagMasterImpl) _then)
      : super(_value, _then);

  /// Create a copy of TagMaster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? displayName = null,
    Object? legacyCategory = freezed,
    Object? isActive = null,
    Object? categories = null,
    Object? createdAt = freezed,
    Object? deletedAt = freezed,
  }) {
    return _then(_$TagMasterImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      legacyCategory: freezed == legacyCategory
          ? _value.legacyCategory
          : legacyCategory // ignore: cast_nullable_to_non_nullable
              as String?,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TagMasterImpl implements _TagMaster {
  const _$TagMasterImpl(
      {@JsonKey(name: 'id') this.id,
      required this.name,
      @JsonKey(name: 'display_name') required this.displayName,
      @JsonKey(name: 'category') this.legacyCategory,
      @JsonKey(name: 'is_active') this.isActive = true,
      final List<String> categories = const <String>[],
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'deleted_at') this.deletedAt})
      : _categories = categories;

  factory _$TagMasterImpl.fromJson(Map<String, dynamic> json) =>
      _$$TagMasterImplFromJson(json);

  @override
  @JsonKey(name: 'id')
  final int? id;
  @override
  final String name;
  @override
  @JsonKey(name: 'display_name')
  final String displayName;
  @override
  @JsonKey(name: 'category')
  final String? legacyCategory;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;
  final List<String> _categories;
  @override
  @JsonKey()
  List<String> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  @override
  String toString() {
    return 'TagMaster(id: $id, name: $name, displayName: $displayName, legacyCategory: $legacyCategory, isActive: $isActive, categories: $categories, createdAt: $createdAt, deletedAt: $deletedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TagMasterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.legacyCategory, legacyCategory) ||
                other.legacyCategory == legacyCategory) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      displayName,
      legacyCategory,
      isActive,
      const DeepCollectionEquality().hash(_categories),
      createdAt,
      deletedAt);

  /// Create a copy of TagMaster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TagMasterImplCopyWith<_$TagMasterImpl> get copyWith =>
      __$$TagMasterImplCopyWithImpl<_$TagMasterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TagMasterImplToJson(
      this,
    );
  }
}

abstract class _TagMaster implements TagMaster {
  const factory _TagMaster(
      {@JsonKey(name: 'id') final int? id,
      required final String name,
      @JsonKey(name: 'display_name') required final String displayName,
      @JsonKey(name: 'category') final String? legacyCategory,
      @JsonKey(name: 'is_active') final bool isActive,
      final List<String> categories,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'deleted_at') final String? deletedAt}) = _$TagMasterImpl;

  factory _TagMaster.fromJson(Map<String, dynamic> json) =
      _$TagMasterImpl.fromJson;

  @override
  @JsonKey(name: 'id')
  int? get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'display_name')
  String get displayName;
  @override
  @JsonKey(name: 'category')
  String? get legacyCategory;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;
  @override
  List<String> get categories;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'deleted_at')
  String? get deletedAt;

  /// Create a copy of TagMaster
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TagMasterImplCopyWith<_$TagMasterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
