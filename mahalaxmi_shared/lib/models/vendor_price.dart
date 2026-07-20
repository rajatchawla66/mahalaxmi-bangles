import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_price.freezed.dart';
part 'vendor_price.g.dart';

@freezed
class VendorPrice with _$VendorPrice {
  const factory VendorPrice({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'item_name') required String itemName,
    String? category,
    @JsonKey(name: 'vendor_name') required String vendorName,
    @JsonKey(name: 'cost_price') required double costPrice,
    @JsonKey(name: 'margin_type') @Default('percent') String marginType,
    @JsonKey(name: 'margin_value') @Default(0) double marginValue,
    @JsonKey(name: 'selling_price') required double sellingPrice,
    String? notes,
    @JsonKey(name: 'created_by') @Default('') String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _VendorPrice;

  factory VendorPrice.fromJson(Map<String, Object?> json) =>
      _$VendorPriceFromJson(json);
}
