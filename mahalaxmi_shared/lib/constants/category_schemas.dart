import '../models/enums.dart';
import 'size_charts.dart';

class CategorySchema {
  final List<String> fields;
  final List<String>? sizes;
  final String lineTotal;
  final String validation;
  final double? qtyMin;
  final double? qtyMax;
  final bool qtyIsInt;
  final List<String>? units;
  final String? defaultUnit;
  final int? notesMaxLength;

  const CategorySchema({
    required this.fields,
    this.sizes,
    required this.lineTotal,
    required this.validation,
    this.qtyMin,
    this.qtyMax,
    this.qtyIsInt = false,
    this.units,
    this.defaultUnit,
    this.notesMaxLength,
  });

  bool get isSized => fields.contains('sizes');
  bool get hasColor => fields.contains('color');

  static const Map<String, CategorySchema> hardcodedSchemas = {
    'Chuda': CategorySchema(
      fields: ['color', 'grind_type', 'box_type', 'sizes'],
      sizes: kChudaSizes,
      lineTotal: 'sum_sizes_x_price',
      validation: 'at_least_one_size_gt_zero',
    ),
    'Kaleera': CategorySchema(
      fields: ['color', 'quantity'],
      qtyMin: 1,
      qtyMax: 9999,
      qtyIsInt: true,
      lineTotal: 'qty_x_price',
      validation: 'qty_gte_1_and_color_required',
    ),
    'Raw_Material': CategorySchema(
      fields: ['sub_category_label', 'quantity', 'unit'],
      qtyMin: 0.01,
      qtyMax: 99999.99,
      qtyIsInt: false,
      units: kUnits,
      defaultUnit: 'pieces',
      lineTotal: 'qty_x_price',
      validation: 'qty_gt_zero',
    ),
    'Metal_Bangles': CategorySchema(
      fields: ['color', 'sizes'],
      sizes: kMetalBanglesSizes,
      lineTotal: 'sum_sizes_x_price',
      validation: 'at_least_one_size_gt_zero',
    ),
    'Seasonal': CategorySchema(
      fields: ['quantity', 'notes'],
      qtyMin: 1,
      qtyMax: 99999,
      qtyIsInt: true,
      notesMaxLength: 500,
      lineTotal: 'qty_x_price',
      validation: 'qty_gte_1',
    ),
  };
}

const kCategorySchemas = CategorySchema.hardcodedSchemas;
