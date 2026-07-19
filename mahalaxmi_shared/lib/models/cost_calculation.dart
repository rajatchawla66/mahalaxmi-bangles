import 'package:freezed_annotation/freezed_annotation.dart';

part 'cost_calculation.freezed.dart';
part 'cost_calculation.g.dart';

@freezed
class CostCalculation with _$CostCalculation {
  const factory CostCalculation({
    @JsonKey(name: 'id', includeIfNull: false) String? id,
    @JsonKey(name: 'item_name') required String itemName,
    @JsonKey(name: 'item_number') String? itemNumber,
    @Default('') String category,
    @JsonKey(name: 'sub_category') String? subCategory,
    @Default({}) Map<String, dynamic> materials,
    @JsonKey(name: 'total_cost') @Default(0) double totalCost,
    @JsonKey(name: 'costing_type') @Default('manufacturing') String costingType,
    @JsonKey(name: 'created_by') @Default('') String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_by') @Default('') String updatedBy,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CostCalculation;

  const CostCalculation._();

  factory CostCalculation.fromJson(Map<String, Object?> json) =>
      _$CostCalculationFromJson(json);
}
