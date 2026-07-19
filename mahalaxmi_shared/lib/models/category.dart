import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

@freezed
class Category with _$Category {
  const factory Category({
    @JsonKey(name: 'id') int? id,
    required String name,
    @Default('CATEGORY') String icon,
    @Default('GREY_400') String color,
    @Default('') String description,
    @JsonKey(name: 'sub_categories') @Default('') String subCategories,
    @JsonKey(name: 'order_type') @Default('quantity') String orderType,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'cover_image_url') String? coverImageUrl,
    @JsonKey(name: 'has_sizes') @Default(false) bool hasSizes,
    @JsonKey(name: 'has_subcategories') @Default(false) bool hasSubcategories,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'size_chart') List<String>? sizeChart,
  }) = _Category;
  const Category._();

  factory Category.fromJson(Map<String, Object?> json) =>
      _$CategoryFromJson(json);

  List<String> get subCategoryList {
    if (subCategories.isEmpty) return [];
    return subCategories
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
