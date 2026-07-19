import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_material.freezed.dart';
part 'item_material.g.dart';

@freezed
class ItemMaterial with _$ItemMaterial {
  const factory ItemMaterial({
    @JsonKey(name: 'item_number') required String itemNumber,
    @JsonKey(name: 'material_id') int? materialId,
    @JsonKey(name: 'material_name') @Default('') String materialName,
    @Default(0.0) double qty,
    @JsonKey(name: 'rate_per_unit') @Default(0.0) double ratePerUnit,
  }) = _ItemMaterial;

  factory ItemMaterial.fromJson(Map<String, Object?> json) =>
      _$ItemMaterialFromJson(json);
}
