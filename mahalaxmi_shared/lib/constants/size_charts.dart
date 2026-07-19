import '../models/enums.dart';
import '../models/category.dart';

const kMasterSizeOptions = ['2.2', '2.4', '2.6', '2.8', '2.10', '2.12'];
const kMetalBanglesSizes = ['2.4', '2.6', '2.8', '2.10', '2.12'];

List<String> getMasterSizeOptions() => List.from(kMasterSizeOptions);

List<String> getSizeChartForCategory(dynamic categoryOrName) {
  if (categoryOrName is Category) {
    final cat = categoryOrName;
    if (cat.sizeChart != null && cat.sizeChart!.isNotEmpty) {
      return List.from(cat.sizeChart!);
    }
    return _fallbackChart(cat.name);
  }
  if (categoryOrName is String) {
    return _fallbackChart(categoryOrName);
  }
  return [];
}

List<String> _fallbackChart(String category) {
  final trimmed = category.trim();
  if (trimmed == 'Chuda') return List.from(kChudaSizes);
  if (trimmed == 'Metal_Bangles') return List.from(kMetalBanglesSizes);
  return [];
}

bool categoryHasSizes(dynamic categoryOrName) {
  return getSizeChartForCategory(categoryOrName).isNotEmpty;
}

List<String> normalizeAvailableSizes(
    dynamic categoryOrName, List<String>? availableSizes) {
  final chart = getSizeChartForCategory(categoryOrName);
  if (chart.isEmpty) return [];
  if (availableSizes == null) return List.from(chart);
  return chart.where((s) => availableSizes.contains(s)).toList();
}

String sizeToColumn(String size) {
  return 'qty_${size.replaceAll('.', '_')}';
}
