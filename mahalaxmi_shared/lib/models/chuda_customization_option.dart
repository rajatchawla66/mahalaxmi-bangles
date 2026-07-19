import 'package:freezed_annotation/freezed_annotation.dart';

part 'chuda_customization_option.freezed.dart';
part 'chuda_customization_option.g.dart';

@freezed
class ChudaCustomizationOption with _$ChudaCustomizationOption {
  const factory ChudaCustomizationOption({
    @JsonKey(name: 'id') @Default(0) int id,
    @JsonKey(name: 'group_type') required String groupType,
    required String name,
    @JsonKey(name: 'price_difference') @Default(0.0) double priceDifference,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _ChudaCustomizationOption;

  factory ChudaCustomizationOption.fromJson(Map<String, dynamic> json) =>
      _$ChudaCustomizationOptionFromJson(json);
}
