class ChudaCustomizationSnapshot {
  final String pattiName;
  final double pattiPriceDiff;
  final String colorName;
  final double colorPriceDiff;
  final String? customColorText;
  final String boxName;
  final double boxPriceDiff;
  final double totalDifference;

  const ChudaCustomizationSnapshot({
    required this.pattiName,
    this.pattiPriceDiff = 0,
    required this.colorName,
    this.colorPriceDiff = 0,
    this.customColorText,
    required this.boxName,
    this.boxPriceDiff = 0,
    this.totalDifference = 0,
  });

  Map<String, dynamic> toJson() => {
        'pattiName': pattiName,
        'pattiPriceDiff': pattiPriceDiff,
        'colorName': colorName,
        'colorPriceDiff': colorPriceDiff,
        'customColorText': customColorText,
        'boxName': boxName,
        'boxPriceDiff': boxPriceDiff,
        'totalDifference': totalDifference,
      };

  factory ChudaCustomizationSnapshot.fromJson(Map<String, dynamic> json) =>
      ChudaCustomizationSnapshot(
        pattiName: json['pattiName'] as String? ?? '',
        pattiPriceDiff: (json['pattiPriceDiff'] as num?)?.toDouble() ?? 0,
        colorName: json['colorName'] as String? ?? '',
        colorPriceDiff: (json['colorPriceDiff'] as num?)?.toDouble() ?? 0,
        customColorText: json['customColorText'] as String?,
        boxName: json['boxName'] as String? ?? '',
        boxPriceDiff: (json['boxPriceDiff'] as num?)?.toDouble() ?? 0,
        totalDifference: (json['totalDifference'] as num?)?.toDouble() ?? 0,
      );

  ChudaCustomizationSnapshot copyWith({
    String? pattiName,
    double? pattiPriceDiff,
    String? colorName,
    double? colorPriceDiff,
    String? customColorText,
    String? boxName,
    double? boxPriceDiff,
    double? totalDifference,
  }) {
    return ChudaCustomizationSnapshot(
      pattiName: pattiName ?? this.pattiName,
      pattiPriceDiff: pattiPriceDiff ?? this.pattiPriceDiff,
      colorName: colorName ?? this.colorName,
      colorPriceDiff: colorPriceDiff ?? this.colorPriceDiff,
      customColorText: customColorText ?? this.customColorText,
      boxName: boxName ?? this.boxName,
      boxPriceDiff: boxPriceDiff ?? this.boxPriceDiff,
      totalDifference: totalDifference ?? this.totalDifference,
    );
  }
}
