enum MaterialShape {
  qtyCards,
  qtySlider,
  toggleChoice,
  presetChips,
  manualQty,
  qtyPicker,
}

class ToggleOption {
  final String id;
  final String label;
  final String settingsKey;

  const ToggleOption({
    required this.id,
    required this.label,
    required this.settingsKey,
  });
}

class MaterialConfig {
  final String id;
  final String displayName;
  final MaterialShape shape;
  final bool hasFixedPrice;
  final String? settingsKey;
  final double defaultQty;
  final double? minQty;
  final double? maxQty;
  final double? stepQty;
  final List<double>? qtyOptions;
  final List<double>? presetOptions;
  final List<ToggleOption>? toggleOptions;
  final String? group;

  const MaterialConfig({
    required this.id,
    required this.displayName,
    required this.shape,
    this.hasFixedPrice = false,
    this.settingsKey,
    this.defaultQty = 1,
    this.minQty,
    this.maxQty,
    this.stepQty,
    this.qtyOptions,
    this.presetOptions,
    this.toggleOptions,
    this.group,
  });
}

const List<MaterialConfig> materialConfigs = [
  MaterialConfig(
    id: 'kadda',
    displayName: 'Kadda',
    shape: MaterialShape.qtyCards,
    qtyOptions: [1, 2, 3],
    defaultQty: 2,
  ),
  MaterialConfig(
    id: 'chudi',
    displayName: 'Chudi',
    shape: MaterialShape.qtySlider,
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
  ),
  MaterialConfig(
    id: 'nihar',
    displayName: 'Nihar',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'nihar',
    minQty: 3,
    maxQty: 6,
    stepQty: 0.5,
    defaultQty: 5,
  ),
  MaterialConfig(
    id: 'patti',
    displayName: 'Patti',
    shape: MaterialShape.toggleChoice,
    toggleOptions: [
      ToggleOption(
        id: 'gol',
        label: 'GOL',
        settingsKey: 'patti_gol',
      ),
      ToggleOption(
        id: 'without_gol',
        label: 'Without GOL',
        settingsKey: 'patti_without_gol',
      ),
    ],
  ),
  MaterialConfig(
    id: 'box',
    displayName: 'Box',
    shape: MaterialShape.presetChips,
    presetOptions: [15, 30, 55, 70, 90, 100, 120],
    defaultQty: 1,
  ),
  MaterialConfig(
    id: 'bangdi',
    displayName: 'Bangdi',
    shape: MaterialShape.qtyCards,
    qtyOptions: [1, 2],
    defaultQty: 2,
  ),
  MaterialConfig(
    id: 'dot_plain',
    displayName: 'Dot Plain',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'dot_plain',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Dots',
  ),
  MaterialConfig(
    id: 'dot_stone',
    displayName: 'Dot Stone',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'dot_stone',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Dots',
  ),
  MaterialConfig(
    id: 'dot_kundan',
    displayName: 'Dot Kundan',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'dot_kundan',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Dots',
  ),
  MaterialConfig(
    id: 'taj_stone',
    displayName: 'Taj Stone',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'taj_stone',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Dots',
  ),
  MaterialConfig(
    id: 'sunshine',
    displayName: 'Sunshine',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'sunshine',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Dots',
  ),
  MaterialConfig(
    id: 'misc_dot1',
    displayName: 'Misc Dot1',
    shape: MaterialShape.qtySlider,
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Misc Items',
  ),
  MaterialConfig(
    id: 'misc_dot2',
    displayName: 'Misc Dot2',
    shape: MaterialShape.qtySlider,
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Misc Items',
  ),
  MaterialConfig(
    id: 'moti103',
    displayName: 'Moti 103',
    shape: MaterialShape.qtySlider,
    hasFixedPrice: true,
    settingsKey: 'moti_103',
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Misc Items',
  ),
  MaterialConfig(
    id: 'kashmiri',
    displayName: 'Kashmiri',
    shape: MaterialShape.qtySlider,
    minQty: 1,
    maxQty: 3,
    stepQty: 0.5,
    defaultQty: 2,
    group: 'Misc Items',
  ),
  MaterialConfig(
    id: 'misc_item1',
    displayName: 'Misc Item1',
    shape: MaterialShape.qtyPicker,
    qtyOptions: [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5],
    defaultQty: 2,
    group: 'Misc Items',
  ),
  MaterialConfig(
    id: 'misc_item2',
    displayName: 'Misc Item2',
    shape: MaterialShape.qtyPicker,
    qtyOptions: [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5],
    defaultQty: 2,
    group: 'Misc Items',
  ),
];
