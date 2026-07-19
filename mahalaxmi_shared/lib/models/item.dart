import 'package:freezed_annotation/freezed_annotation.dart';

part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class RateItem with _$RateItem {
  const factory RateItem({
    @JsonKey(name: 'item_number') required String itemNumber,
    @JsonKey(name: 'image_url') @Default('') String imageUrl,
    @JsonKey(name: 'cost_price') @Default(0.0) double costPrice,
    @JsonKey(name: 'selling_price') @Default(0.0) double sellingPrice,
    required String category,
    @JsonKey(name: 'sub_category') String? subCategory,
    @JsonKey(name: 'has_sizes') @Default(false) bool hasSizes,
    @JsonKey(name: 'has_color') @Default(false) bool hasColor,
    @JsonKey(name: 'is_available') @Default(true) bool isAvailable,
    @JsonKey(name: 'margin_percent') @Default(0.0) double marginPercent,
    @Default('new') String status,
    @Default(<String>[]) List<String> tags,
    @JsonKey(name: 'available_sizes') List<String>? availableSizes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _RateItem;

  factory RateItem.fromJson(Map<String, Object?> json) =>
      _$RateItemFromJson(json);
}
