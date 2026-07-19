import 'package:freezed_annotation/freezed_annotation.dart';

part 'cost_breakdown.freezed.dart';
part 'cost_breakdown.g.dart';

@freezed
class CostBreakdown with _$CostBreakdown {
  const factory CostBreakdown({
    @JsonKey(name: 'id') int? id,
    @JsonKey(name: 'item_number') required String itemNumber,
    @JsonKey(name: 'material_id') int? materialId,
    @JsonKey(name: 'material_name') @Default('') String materialName,
    @Default(0.0) double quantity,
    @Default('pcs') String unit,
    @JsonKey(name: 'rate_per_unit') @Default(0.0) double ratePerUnit,
    @JsonKey(name: 'line_total') @Default(0.0) double lineTotal,
  }) = _CostBreakdown;

  factory CostBreakdown.fromJson(Map<String, Object?> json) =>
      _$CostBreakdownFromJson(json);
}
