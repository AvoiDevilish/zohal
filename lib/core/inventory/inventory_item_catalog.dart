import 'inventory_item.dart';

const _usdaDateNote =
    'Reference profile from USDA FoodData Central for dates; local cultivar values may vary.';

const _usdaNutNote =
    'Reference profile from USDA FoodData Central; cultivar, origin and processing can change values.';

const _usdaIngredientNote =
    'Reference profile from USDA FoodData Central; supplier-specific composition may vary.';

NutritionProfile _datesNutrition() => const NutritionProfile(
  energyKcal: 282,
  proteinG: 2.45,
  totalFatG: 0.39,
  saturatedFatG: 0.032,
  carbohydrateG: 75.03,
  totalSugarG: 63.35,
  fiberG: 8.0,
  sodiumMg: 2,
  calciumMg: 39,
  ironMg: 1.02,
  magnesiumMg: 43,
  phosphorusMg: 62,
  potassiumMg: 656,
  source: 'USDA FoodData Central — dates, reference profile',
  note: _usdaDateNote,
);

const _walnutNutrition = NutritionProfile(
  energyKcal: 654,
  proteinG: 15.23,
  totalFatG: 65.21,
  saturatedFatG: 6.126,
  carbohydrateG: 13.71,
  totalSugarG: 2.61,
  fiberG: 6.7,
  sodiumMg: 2,
  calciumMg: 98,
  ironMg: 2.91,
  magnesiumMg: 158,
  phosphorusMg: 346,
  potassiumMg: 441,
  source: 'USDA FoodData Central — walnuts, English, raw',
  note: _usdaNutNote,
);

const _almondNutrition = NutritionProfile(
  energyKcal: 579,
  proteinG: 21.15,
  totalFatG: 49.93,
  saturatedFatG: 3.802,
  carbohydrateG: 21.55,
  totalSugarG: 4.35,
  fiberG: 12.5,
  sodiumMg: 1,
  calciumMg: 269,
  ironMg: 3.71,
  magnesiumMg: 270,
  phosphorusMg: 481,
  potassiumMg: 733,
  source: 'USDA FoodData Central — almonds, whole, raw',
  note: _usdaNutNote,
);

const _peanutNutrition = NutritionProfile(
  energyKcal: 567,
  proteinG: 25.8,
  totalFatG: 49.24,
  saturatedFatG: 6.28,
  carbohydrateG: 16.13,
  totalSugarG: 4.72,
  fiberG: 8.5,
  sodiumMg: 18,
  calciumMg: 92,
  ironMg: 4.58,
  magnesiumMg: 168,
  phosphorusMg: 376,
  potassiumMg: 705,
  source: 'USDA FoodData Central — peanuts, raw',
  note: _usdaNutNote,
);

const _cashewNutrition = NutritionProfile(
  energyKcal: 553,
  proteinG: 18.22,
  totalFatG: 43.85,
  saturatedFatG: 7.783,
  carbohydrateG: 30.19,
  totalSugarG: 5.91,
  fiberG: 3.3,
  sodiumMg: 12,
  calciumMg: 37,
  ironMg: 6.68,
  magnesiumMg: 292,
  phosphorusMg: 593,
  potassiumMg: 660,
  source: 'USDA FoodData Central — cashews, raw',
  note: _usdaNutNote,
);

const _sesameNutrition = NutritionProfile(
  energyKcal: 573,
  proteinG: 17.73,
  totalFatG: 49.67,
  saturatedFatG: 6.957,
  carbohydrateG: 23.45,
  totalSugarG: 0.3,
  fiberG: 11.8,
  sodiumMg: 11,
  calciumMg: 975,
  ironMg: 14.55,
  magnesiumMg: 351,
  phosphorusMg: 629,
  potassiumMg: 468,
  source: 'USDA FoodData Central — sesame seeds, whole, dried',
  note: _usdaIngredientNote,
);

const _gingerNutrition = NutritionProfile(
  energyKcal: 335,
  proteinG: 9.0,
  totalFatG: 4.24,
  saturatedFatG: 1.683,
  carbohydrateG: 71.62,
  totalSugarG: 3.39,
  fiberG: 14.1,
  sodiumMg: 27,
  calciumMg: 114,
  ironMg: 19.8,
  magnesiumMg: 214,
  phosphorusMg: 168,
  potassiumMg: 1320,
  source: 'USDA FoodData Central — ginger, ground',
  note: _usdaIngredientNote,
);

const _chickpeaFlourNutrition = NutritionProfile(
  energyKcal: 387,
  proteinG: 22.39,
  totalFatG: 6.69,
  saturatedFatG: 0.693,
  carbohydrateG: 57.82,
  totalSugarG: 10.85,
  fiberG: 10.8,
  sodiumMg: 64,
  calciumMg: 45,
  ironMg: 4.86,
  magnesiumMg: 166,
  phosphorusMg: 318,
  potassiumMg: 846,
  source: 'USDA FoodData Central — chickpea flour reference',
  note: _usdaIngredientNote,
);

const _starchNutrition = NutritionProfile(
  energyKcal: 381,
  proteinG: 0.26,
  totalFatG: 0.05,
  saturatedFatG: 0.009,
  carbohydrateG: 91.27,
  totalSugarG: 0.0,
  fiberG: 0.9,
  sodiumMg: 9,
  calciumMg: 2,
  ironMg: 0.47,
  magnesiumMg: 3,
  phosphorusMg: 13,
  potassiumMg: 3,
  source: 'USDA FoodData Central — starch reference',
  note:
      'Provisional generic starch profile; exact source (corn, wheat, potato, etc.) should be selected when supplier specification is known.',
);

InventoryItem _food({
  required String id,
  required String name,
  required String englishName,
  required String category,
  required NutritionProfile nutrition,
  String? notes,
}) {
  return InventoryItem(
    id: id,
    name: name,
    englishName: englishName,
    type: InventoryItemType.rawMaterial,
    category: category,
    unit: 'g',
    unitConversions: const [
      InventoryUnitConversion(unit: 'kg', toBaseFactor: 1000),
    ],
    isFood: true,
    nutrition: nutrition,
    notes: notes,
  );
}

InventoryItem _packaging({
  required String id,
  required String name,
  required String category,
}) {
  return InventoryItem(
    id: id,
    name: name,
    englishName: name,
    type: InventoryItemType.packaging,
    category: category,
    unit: 'piece',
    isFood: false,
  );
}

List<InventoryItem> get initialInventoryItems => [
  _food(
    id: 'raw_date_khesht',
    name: 'خرما خشت',
    englishName: 'Khesht date',
    category: 'خرما',
    nutrition: _datesNutrition(),
    notes:
        '«خشت» احتمالاً به خاستگاه/نام تجاری منطقه‌ای اشاره دارد؛ تا زمان تأیید رقم دقیق، پروفایل عمومی خرما استفاده می‌شود.',
  ),
  _food(
    id: 'raw_date_pit',
    name: 'هسته خرما',
    englishName: 'Date pit',
    category: 'هسته خرما',
    nutrition: _datesNutrition(),
    notes: 'محصول جانبی قابل استفاده حاصل از جداسازی هسته خرما؛ ضایعات نیست.',
  ),
  _food(
    id: 'raw_date_kabkab',
    name: 'خرما کبکاب',
    englishName: 'Kabkab date',
    category: 'خرما',
    nutrition: _datesNutrition(),
    notes:
        'برای کبکاب داده عمومی رقم‌محور یکسان و قابل اتکای آزمایشگاهی پیدا نشد؛ پروفایل مرجع خرما فعلاً استفاده می‌شود.',
  ),
  _food(
    id: 'raw_date_asali_rutab',
    name: 'رطب عسلی',
    englishName: 'Asali rutab date',
    category: 'خرما',
    nutrition: _datesNutrition(),
    notes:
        'رطب عسلی به‌عنوان خرمای نرم/رطب ثبت شده است؛ مقادیر تغذیه‌ای با پروفایل مرجع خرما موقتاً برآورد می‌شوند.',
  ),
  _food(
    id: 'raw_date_borazjan',
    name: 'خرما برازجان',
    englishName: 'Borazjan date',
    category: 'خرما',
    nutrition: _datesNutrition(),
    notes:
        '«برازجان» می‌تواند خاستگاه/منطقه باشد نه رقم مستقل؛ تا تعیین رقم دقیق، پروفایل مرجع خرما استفاده می‌شود.',
  ),
  _food(
    id: 'raw_walnut_iranian',
    name: 'گردو ایرانی',
    englishName: 'Iranian walnut',
    category: 'آجیل',
    nutrition: _walnutNutrition,
  ),
  _food(
    id: 'raw_almond',
    name: 'بادام درختی',
    englishName: 'Almond',
    category: 'آجیل',
    nutrition: _almondNutrition,
  ),
  _food(
    id: 'raw_peanut',
    name: 'بادام زمینی',
    englishName: 'Peanut',
    category: 'آجیل',
    nutrition: _peanutNutrition,
  ),
  _food(
    id: 'raw_cashew',
    name: 'بادام هندی',
    englishName: 'Cashew',
    category: 'آجیل',
    nutrition: _cashewNutrition,
  ),
  _food(
    id: 'raw_sesame',
    name: 'کنجد',
    englishName: 'Sesame seed',
    category: 'مواد اولیه',
    nutrition: _sesameNutrition,
  ),
  _food(
    id: 'raw_ground_ginger',
    name: 'پودر زنجبیل',
    englishName: 'Ground ginger',
    category: 'مواد اولیه',
    nutrition: _gingerNutrition,
  ),
  _food(
    id: 'raw_chickpea_flour',
    name: 'آرد نخودچی',
    englishName: 'Chickpea flour',
    category: 'مواد اولیه',
    nutrition: _chickpeaFlourNutrition,
  ),
  _food(
    id: 'raw_food_starch',
    name: 'پودر نشاسته',
    englishName: 'Food starch',
    category: 'مواد اولیه',
    nutrition: _starchNutrition,
  ),
  _packaging(
    id: 'pack_container_100g',
    name: 'ظرف ۱۰۰ گرمی',
    category: 'ظرف',
  ),
  _packaging(
    id: 'pack_container_400g',
    name: 'ظرف ۴۰۰ گرمی',
    category: 'ظرف',
  ),
  _packaging(
    id: 'pack_container_500g',
    name: 'ظرف ۵۰۰ گرمی',
    category: 'ظرف',
  ),
  _packaging(
    id: 'pack_container_1kg',
    name: 'ظرف یک کیلویی',
    category: 'ظرف',
  ),
  _packaging(
    id: 'pack_label',
    name: 'لیبل',
    category: 'ملزومات بسته‌بندی',
  ),
  _packaging(
    id: 'pack_fork',
    name: 'چنگال',
    category: 'ملزومات بسته‌بندی',
  ),
  _packaging(
    id: 'pack_wax_paper',
    name: 'کاغذ روغنی بین طبقات',
    category: 'ملزومات بسته‌بندی',
  ),
];
