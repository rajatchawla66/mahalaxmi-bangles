// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vendor_master.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VendorMaster _$VendorMasterFromJson(Map<String, dynamic> json) {
  return _VendorMaster.fromJson(json);
}

/// @nodoc
mixin _$VendorMaster {
  @JsonKey(name: 'id', fromJson: _parseId)
  int? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_active')
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this VendorMaster to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VendorMaster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VendorMasterCopyWith<VendorMaster> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VendorMasterCopyWith<$Res> {
  factory $VendorMasterCopyWith(
          VendorMaster value, $Res Function(VendorMaster) then) =
      _$VendorMasterCopyWithImpl<$Res, VendorMaster>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _parseId) int? id,
      String name,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class _$VendorMasterCopyWithImpl<$Res, $Val extends VendorMaster>
    implements $VendorMasterCopyWith<$Res> {
  _$VendorMasterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VendorMaster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? isActive = null,
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
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VendorMasterImplCopyWith<$Res>
    implements $VendorMasterCopyWith<$Res> {
  factory _$$VendorMasterImplCopyWith(
          _$VendorMasterImpl value, $Res Function(_$VendorMasterImpl) then) =
      __$$VendorMasterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _parseId) int? id,
      String name,
      @JsonKey(name: 'is_active') bool isActive});
}

/// @nodoc
class __$$VendorMasterImplCopyWithImpl<$Res>
    extends _$VendorMasterCopyWithImpl<$Res, _$VendorMasterImpl>
    implements _$$VendorMasterImplCopyWith<$Res> {
  __$$VendorMasterImplCopyWithImpl(
      _$VendorMasterImpl _value, $Res Function(_$VendorMasterImpl) _then)
      : super(_value, _then);

  /// Create a copy of VendorMaster
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? isActive = null,
  }) {
    return _then(_$VendorMasterImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VendorMasterImpl implements _VendorMaster {
  const _$VendorMasterImpl(
      {@JsonKey(name: 'id', fromJson: _parseId) this.id,
      required this.name,
      @JsonKey(name: 'is_active') this.isActive = true});

  factory _$VendorMasterImpl.fromJson(Map<String, dynamic> json) =>
      _$$VendorMasterImplFromJson(json);

  @override
  @JsonKey(name: 'id', fromJson: _parseId)
  final int? id;
  @override
  final String name;
  @override
  @JsonKey(name: 'is_active')
  final bool isActive;

  @override
  String toString() {
    return 'VendorMaster(id: $id, name: $name, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VendorMasterImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, isActive);

  /// Create a copy of VendorMaster
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VendorMasterImplCopyWith<_$VendorMasterImpl> get copyWith =>
      __$$VendorMasterImplCopyWithImpl<_$VendorMasterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VendorMasterImplToJson(
      this,
    );
  }
}

abstract class _VendorMaster implements VendorMaster {
  const factory _VendorMaster(
      {@JsonKey(name: 'id', fromJson: _parseId) final int? id,
      required final String name,
      @JsonKey(name: 'is_active') final bool isActive}) = _$VendorMasterImpl;

  factory _VendorMaster.fromJson(Map<String, dynamic> json) =
      _$VendorMasterImpl.fromJson;

  @override
  @JsonKey(name: 'id', fromJson: _parseId)
  int? get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'is_active')
  bool get isActive;

  /// Create a copy of VendorMaster
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VendorMasterImplCopyWith<_$VendorMasterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
