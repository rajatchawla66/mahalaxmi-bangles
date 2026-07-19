import 'package:riverpod/riverpod.dart';

class TradingMarginSettings {
  final String marginType; // 'flat' | 'percent'
  final double flatAmount;
  final double marginPercent;

  const TradingMarginSettings({
    this.marginType = 'percent',
    this.flatAmount = 10,
    this.marginPercent = 15,
  });

  TradingMarginSettings copyWith({
    String? marginType,
    double? flatAmount,
    double? marginPercent,
  }) {
    return TradingMarginSettings(
      marginType: marginType ?? this.marginType,
      flatAmount: flatAmount ?? this.flatAmount,
      marginPercent: marginPercent ?? this.marginPercent,
    );
  }
}

final tradingMarginSettingsProvider =
    StateNotifierProvider<TradingMarginSettingsNotifier, TradingMarginSettings>(
  (_) => TradingMarginSettingsNotifier(),
);

class TradingMarginSettingsNotifier
    extends StateNotifier<TradingMarginSettings> {
  TradingMarginSettingsNotifier() : super(const TradingMarginSettings());

  void setMarginType(String type) {
    state = state.copyWith(marginType: type);
  }

  void setFlatAmount(double amount) {
    state = state.copyWith(flatAmount: amount);
  }

  void setMarginPercent(double percent) {
    state = state.copyWith(marginPercent: percent);
  }
}
