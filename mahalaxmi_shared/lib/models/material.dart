import 'package:freezed_annotation/freezed_annotation.dart';

part 'material.freezed.dart';
part 'material.g.dart';

@freezed
class Material with _$Material {
  const factory Material({
    @JsonKey(name: 'id') int? id,
    required String name,
    @Default(0.0) double rate,
    @Default('pcs') String unit,
    @Default('General') String category,
  }) = _Material;

  factory Material.fromJson(Map<String, Object?> json) =>
      _$MaterialFromJson(json);
}
