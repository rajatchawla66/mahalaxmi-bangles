enum OrderStatus { pending, confirmed, cancelled, completed }

enum OrderSource { admin, customer }

enum ItemStatus { priced, new_ }

enum ProductionCycle { pending, prepared, notAvailable }

const productionCycleValues = ['pending', 'prepared', 'not_available'];

const kChudaSizes = ['2.2', '2.4', '2.6', '2.8', '2.10'];

const kQtyColumns = ['qty_2_2', 'qty_2_4', 'qty_2_6', 'qty_2_8', 'qty_2_10'];

const kColorOptions = [
  'Light Mehroon',
  'Dark Mehroon',
  'Red',
  'Rani',
  'Custom',
];

const kBoxOptions = [
  'Jodi Box',
  'Mahal Box',
  'Flap Box',
  'Velvet Box',
];

const kGrindOptions = [
  'Gol / Internal-Grind',
  'Bina Gol / Non-Grind',
];

const kDefaultUnit = 'pieces';
const kUnits = ['pieces', 'kg', 'meters'];

const kCustomerPinLength = 8;

enum CutmailStatus { pending, reviewed, archived }
const kOfflineThreshold = 3;
const kProductImageWidth = 1080;
const kProductImageHeight = 1350;
const kProductJpegQuality = 93;
