import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
class TagMaster with _$TagMaster {
  const factory TagMaster({
    @JsonKey(name: 'id') int? id,
    required String name,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'category') String? legacyCategory,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @Default(<String>[]) List<String> categories,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'deleted_at') String? deletedAt,
  }) = _TagMaster;

  factory TagMaster.fromJson(Map<String, Object?> json) =>
      _$TagMasterFromJson(json);
}
