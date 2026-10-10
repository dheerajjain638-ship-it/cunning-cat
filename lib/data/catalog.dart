import 'package:flutter/material.dart';

import 'models.dart';

/// DEMO CATALOG. Product names are real models; prices, ratings and review
/// counts are invented reference values used only to generate demo listings.
/// Real data arrives from approved retailer and affiliate feeds (Phase 3).

const categories = <Category>[
  Category(id: 'mobiles', label: 'Mobiles', icon: Icons.smartphone, color: Color(0xFF6366F1),
      aspects: ['Camera', 'Battery', 'Performance', 'Display'], synonyms: ['phone', 'phones', 'mobile', 'smartphone', '5g']),
  Category(id: 'laptops', label: 'Laptops', icon: Icons.laptop_mac, color: Color(0xFF0EA5E9),
      aspects: ['Performance', 'Battery', 'Build quality', 'Display'], synonyms: ['laptop', 'notebook', 'macbook', 'computer']),
  Category(id: 'tvs', label: 'TVs', icon: Icons.tv, color: Color(0xFF8B5CF6),
      aspects: ['Picture quality', 'Sound', 'Smart features', 'Value for money'], synonyms: ['tv', 'television', 'smart tv', 'oled', 'qled']),
  Category(id: 'audio', label: 'Audio', icon: Icons.headphones, color: Color(0xFFEC4899),
      aspects: ['Sound quality', 'Noise cancellation', 'Comfort', 'Battery'], synonyms: ['headphones', 'earbuds', 'earphones', 'buds', 'tws', 'airpods']),
  Category(id: 'watches', label: 'Watches', icon: Icons.watch, color: Color(0xFF14B8A6),
      aspects: ['Fitness tracking', 'Battery', 'Display', 'App support'], synonyms: ['watch', 'smartwatch', 'smart watch', 'band']),
  Category(id: 'tablets', label: 'Tablets', icon: Icons.tablet_mac, color: Color(0xFFF97316),
      aspects: ['Display', 'Performance', 'Battery', 'Accessories'], synonyms: ['tablet', 'ipad', 'tab']),
  Category(id: 'fridges', label: 'Fridges', icon: Icons.kitchen, color: Color(0xFF22C55E),
      aspects: ['Cooling', 'Energy efficiency', 'Noise', 'Space'], synonyms: ['fridge', 'refrigerator', 'refrigerators']),
  Category(id: 'washing', label: 'Washing', icon: Icons.local_laundry_service, color: Color(0xFF06B6D4),
      aspects: ['Wash quality', 'Energy efficiency', 'Noise', 'After-sales service'], synonyms: ['washing machine', 'washer', 'front load', 'top load']),
  Category(id: 'acs', label: 'ACs', icon: Icons.ac_unit, color: Color(0xFF3B82F6),
      aspects: ['Cooling', 'Energy efficiency', 'Noise', 'After-sales service'], synonyms: ['ac', 'air conditioner', 'split ac', 'inverter ac']),
  Category(id: 'cameras', label: 'Cameras', icon: Icons.photo_camera, color: Color(0xFFEF4444),
      aspects: ['Image quality', 'Video', 'Autofocus', 'Battery'], synonyms: ['camera', 'dslr', 'mirrorless', 'action camera', 'vlog']),
];

Category categoryById(String id) => categories.firstWhere((c) => c.id == id);

const merchants = <Merchant>[
  Merchant(id: 'amazon', name: 'Amazon', color: Color(0xFFFF9900)),
  Merchant(id: 'flipkart', name: 'Flipkart', color: Color(0xFF2874F0)),
  Merchant(id: 'croma', name: 'Croma', color: Color(0xFF00B5AD)),
  Merchant(id: 'reliance', name: 'Reliance Digital', color: Color(0xFFE42529)),
  Merchant(id: 'tatacliq', name: 'Tata CLiQ', color: Color(0xFF7B2D8E)),
];

const instruments = <PaymentInstrument>[
  PaymentInstrument(id: 'hdfc_cc', bank: 'HDFC Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'hdfc_dc', bank: 'HDFC Bank', kind: 'Debit card'),
  PaymentInstrument(id: 'sbi_cc', bank: 'SBI', kind: 'Credit card'),
  PaymentInstrument(id: 'icici_cc', bank: 'ICICI Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'axis_cc', bank: 'Axis Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'kotak_cc', bank: 'Kotak', kind: 'Credit card'),
  PaymentInstrument(id: 'apay_icici', bank: 'Amazon Pay ICICI', kind: 'Credit card'),
  PaymentInstrument(id: 'fk_axis', bank: 'Flipkart Axis Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'upi', bank: 'Any bank', kind: 'UPI'),
];

Variant _v(String id, String brand, String family, String label, String cat, int price, double rating, int reviews,
        Map<String, String> specs) =>
    Variant(
      id: id,
      brand: brand,
      familyName: family,
      variantLabel: label,
      category: categoryById(cat),
      basePrice: price,
      rating: rating,
      reviewCount: reviews,
      keySpecs: specs,
    );

final variants = <Variant>[
  // Mobiles
  _v('galaxy-s25-256-navy', 'Samsung', 'Samsung Galaxy S25', '12GB / 256GB · Navy', 'mobiles', 80999, 4.4, 18420, {'Display': '6.2" 120Hz', 'Storage': '256 GB', 'RAM': '12 GB', 'Battery': '4000 mAh'}),
  _v('iphone-16-128-black', 'Apple', 'Apple iPhone 16', '128GB · Black', 'mobiles', 72900, 4.6, 31250, {'Display': '6.1" 60Hz', 'Storage': '128 GB', 'Chip': 'A18'}),
  _v('pixel-9-256-obsidian', 'Google', 'Google Pixel 9', '12GB / 256GB · Obsidian', 'mobiles', 74999, 4.3, 6120, {'Display': '6.3" 120Hz', 'Storage': '256 GB', 'RAM': '12 GB'}),
  _v('oneplus-13-256', 'OnePlus', 'OnePlus 13', '12GB / 256GB · Black Eclipse', 'mobiles', 69999, 4.5, 9870, {'Display': '6.82" 120Hz', 'Storage': '256 GB', 'Battery': '6000 mAh'}),
  _v('galaxy-a56-256', 'Samsung', 'Samsung Galaxy A56', '8GB / 256GB · Graphite', 'mobiles', 41999, 4.2, 7340, {'Display': '6.7" 120Hz', 'Storage': '256 GB', 'Battery': '5000 mAh'}),
  _v('redmi-note-14-pro-plus', 'Xiaomi', 'Redmi Note 14 Pro+', '8GB / 256GB · Titan Black', 'mobiles', 29999, 4.2, 22510, {'Display': '6.67" 120Hz', 'Storage': '256 GB', 'Battery': '6200 mAh'}),
  _v('vivo-v40-256', 'Vivo', 'Vivo V40', '8GB / 256GB · Lotus Purple', 'mobiles', 34999, 4.3, 5480, {'Display': '6.78" 120Hz', 'Storage': '256 GB', 'Battery': '5500 mAh'}),
  _v('nothing-phone-3a-128', 'Nothing', 'Nothing Phone (3a)', '8GB / 128GB · White', 'mobiles', 24999, 4.3, 8810, {'Display': '6.77" 120Hz', 'Storage': '128 GB', 'Battery': '5000 mAh'}),
  _v('moto-edge-50-fusion', 'Motorola', 'Motorola Edge 50 Fusion', '8GB / 128GB · Forest Blue', 'mobiles', 22999, 4.1, 12900, {'Display': '6.7" 144Hz', 'Storage': '128 GB', 'Battery': '5000 mAh'}),
  // Laptops
  _v('macbook-air-m3-13-256', 'Apple', 'Apple MacBook Air 13 (M3)', '8GB / 256GB · Midnight', 'laptops', 94990, 4.7, 4120, {'Chip': 'M3', 'RAM': '8 GB', 'SSD': '256 GB', 'Weight': '1.24 kg'}),
  _v('dell-inspiron-3530-i5', 'Dell', 'Dell Inspiron 15 3530', 'Core i5 · 16GB / 512GB', 'laptops', 58990, 4.1, 2380, {'CPU': 'Core i5', 'RAM': '16 GB', 'SSD': '512 GB', 'Screen': '15.6" FHD'}),
  _v('hp-pavilion-14-i5', 'HP', 'HP Pavilion 14', 'Core i5 · 16GB / 512GB', 'laptops', 64990, 4.2, 1650, {'CPU': 'Core i5', 'RAM': '16 GB', 'SSD': '512 GB', 'Screen': '14" FHD'}),
  _v('lenovo-ideapad-slim5-r7', 'Lenovo', 'Lenovo IdeaPad Slim 5', 'Ryzen 7 · 16GB / 512GB', 'laptops', 67990, 4.4, 2990, {'CPU': 'Ryzen 7', 'RAM': '16 GB', 'SSD': '512 GB', 'Screen': '14" OLED'}),
  _v('asus-tuf-a15-4050', 'ASUS', 'ASUS TUF Gaming A15', 'Ryzen 7 · RTX 4050 · 16GB', 'laptops', 79990, 4.3, 3710, {'CPU': 'Ryzen 7', 'GPU': 'RTX 4050', 'RAM': '16 GB', 'Screen': '15.6" 144Hz'}),
  // TVs
  _v('sony-bravia-55-x80l', 'Sony', 'Sony Bravia 55" X80L', '55 inch · 4K', 'tvs', 64990, 4.5, 6230, {'Size': '55"', 'Resolution': '4K', 'Refresh': '60Hz'}),
  _v('samsung-55-crystal-4k', 'Samsung', 'Samsung 55" Crystal 4K', '55 inch · 4K', 'tvs', 43990, 4.3, 14800, {'Size': '55"', 'Resolution': '4K', 'Refresh': '60Hz'}),
  _v('lg-55-oled-b4', 'LG', 'LG 55" OLED B4', '55 inch · 4K OLED', 'tvs', 119990, 4.6, 1240, {'Size': '55"', 'Panel': 'OLED', 'Refresh': '120Hz'}),
  _v('xiaomi-43-x-4k', 'Xiaomi', 'Xiaomi 43" X Series', '43 inch · 4K', 'tvs', 24999, 4.2, 19600, {'Size': '43"', 'Resolution': '4K', 'Refresh': '60Hz'}),
  _v('tcl-55-qled', 'TCL', 'TCL 55" QLED', '55 inch · 4K QLED', 'tvs', 38990, 4.1, 5320, {'Size': '55"', 'Panel': 'QLED', 'Refresh': '60Hz'}),
  // Audio
  _v('sony-wh1000xm5', 'Sony', 'Sony WH-1000XM5', 'Wireless ANC · Black', 'audio', 26990, 4.5, 15400, {'Type': 'Over-ear', 'ANC': 'Yes', 'Battery': '30 h'}),
  _v('airpods-pro-2', 'Apple', 'Apple AirPods Pro (2nd gen)', 'USB-C', 'audio', 22900, 4.6, 21300, {'Type': 'In-ear', 'ANC': 'Yes', 'Battery': '6 h (30 h case)'}),
  _v('jbl-tune-770nc', 'JBL', 'JBL Tune 770NC', 'Wireless ANC · Blue', 'audio', 6999, 4.2, 8800, {'Type': 'Over-ear', 'ANC': 'Yes', 'Battery': '44 h'}),
  _v('oneplus-buds-3', 'OnePlus', 'OnePlus Buds 3', 'ANC · Metallic Gray', 'audio', 4999, 4.2, 11200, {'Type': 'In-ear', 'ANC': 'Yes', 'Battery': '10 h'}),
  _v('boat-airdopes-141', 'boAt', 'boAt Airdopes 141', 'TWS · Bold Black', 'audio', 1199, 3.9, 254000, {'Type': 'In-ear', 'ANC': 'No', 'Battery': '42 h total'}),
  // Watches
  _v('apple-watch-s10-46', 'Apple', 'Apple Watch Series 10', '46mm · GPS', 'watches', 46900, 4.6, 3200, {'Size': '46 mm', 'GPS': 'Yes', 'Battery': '18 h'}),
  _v('galaxy-watch7-40', 'Samsung', 'Samsung Galaxy Watch7', '40mm · Bluetooth', 'watches', 29999, 4.3, 4100, {'Size': '40 mm', 'GPS': 'Yes', 'Battery': '40 h'}),
  _v('amazfit-active-2', 'Amazfit', 'Amazfit Active 2', 'AMOLED · Black', 'watches', 12999, 4.2, 2600, {'Display': 'AMOLED', 'GPS': 'Yes', 'Battery': '10 days'}),
  _v('noise-colorfit-pro6', 'Noise', 'Noise ColorFit Pro 6', 'AMOLED · Jet Black', 'watches', 4999, 4.0, 18300, {'Display': 'AMOLED', 'GPS': 'No', 'Battery': '7 days'}),
  // Tablets
  _v('ipad-10-64', 'Apple', 'Apple iPad (10th gen)', '64GB · Wi-Fi · Blue', 'tablets', 32900, 4.6, 9100, {'Display': '10.9"', 'Storage': '64 GB', 'Chip': 'A14'}),
  _v('galaxy-tab-s9-fe-128', 'Samsung', 'Samsung Galaxy Tab S9 FE', '8GB / 128GB · Wi-Fi', 'tablets', 32999, 4.4, 6700, {'Display': '10.9"', 'Storage': '128 GB', 'Pen': 'Included'}),
  _v('xiaomi-pad-6-256', 'Xiaomi', 'Xiaomi Pad 6', '8GB / 256GB · Graphite', 'tablets', 26999, 4.4, 12400, {'Display': '11" 144Hz', 'Storage': '256 GB', 'Battery': '8840 mAh'}),
  // Fridges
  _v('lg-242l-3star', 'LG', 'LG 242L Frost Free', '3 Star · Double Door', 'fridges', 27990, 4.3, 9800, {'Capacity': '242 L', 'Rating': '3 Star', 'Type': 'Frost free'}),
  _v('samsung-236l-3star', 'Samsung', 'Samsung 236L Frost Free', '3 Star · Double Door', 'fridges', 25990, 4.2, 12100, {'Capacity': '236 L', 'Rating': '3 Star', 'Type': 'Frost free'}),
  _v('whirlpool-192l-4star', 'Whirlpool', 'Whirlpool 192L Direct Cool', '4 Star · Single Door', 'fridges', 15990, 4.1, 21500, {'Capacity': '192 L', 'Rating': '4 Star', 'Type': 'Direct cool'}),
  _v('haier-325l-3star', 'Haier', 'Haier 325L Frost Free', '3 Star · Double Door', 'fridges', 33990, 4.2, 3400, {'Capacity': '325 L', 'Rating': '3 Star', 'Type': 'Frost free'}),
  // Washing machines
  _v('lg-8kg-front-5star', 'LG', 'LG 8kg Front Load', '5 Star · Inverter', 'washing', 36990, 4.4, 8700, {'Capacity': '8 kg', 'Type': 'Front load', 'Rating': '5 Star'}),
  _v('samsung-7kg-top', 'Samsung', 'Samsung 7kg Top Load', '5 Star · Fully Automatic', 'washing', 21990, 4.2, 14300, {'Capacity': '7 kg', 'Type': 'Top load', 'Rating': '5 Star'}),
  _v('ifb-6-5kg-front', 'IFB', 'IFB 6.5kg Front Load', '5 Star · Inverter', 'washing', 26990, 4.1, 6200, {'Capacity': '6.5 kg', 'Type': 'Front load', 'Rating': '5 Star'}),
  // ACs
  _v('voltas-1-5t-3star', 'Voltas', 'Voltas 1.5 Ton Split AC', '3 Star · Inverter', 'acs', 33990, 4.1, 11800, {'Capacity': '1.5 Ton', 'Rating': '3 Star', 'Type': 'Inverter split'}),
  _v('lg-1-5t-5star', 'LG', 'LG 1.5 Ton Split AC', '5 Star · Dual Inverter', 'acs', 45990, 4.3, 7600, {'Capacity': '1.5 Ton', 'Rating': '5 Star', 'Type': 'Inverter split'}),
  _v('daikin-1-5t-3star', 'Daikin', 'Daikin 1.5 Ton Split AC', '3 Star · Inverter', 'acs', 38990, 4.3, 9900, {'Capacity': '1.5 Ton', 'Rating': '3 Star', 'Type': 'Inverter split'}),
  _v('bluestar-1t-3star', 'Blue Star', 'Blue Star 1 Ton Split AC', '3 Star · Inverter', 'acs', 30990, 4.0, 4300, {'Capacity': '1 Ton', 'Rating': '3 Star', 'Type': 'Inverter split'}),
  // Cameras
  _v('sony-zv-e10-kit', 'Sony', 'Sony ZV-E10 Vlog Camera', '16-50mm kit', 'cameras', 61990, 4.5, 2100, {'Sensor': 'APS-C 24MP', 'Video': '4K', 'Lens': '16-50 mm'}),
  _v('canon-r50-kit', 'Canon', 'Canon EOS R50', '18-45mm kit', 'cameras', 68990, 4.6, 1500, {'Sensor': 'APS-C 24MP', 'Video': '4K', 'Lens': '18-45 mm'}),
  _v('gopro-hero13', 'GoPro', 'GoPro HERO13 Black', 'Action camera', 'cameras', 44990, 4.4, 1900, {'Video': '5.3K', 'Waterproof': '10 m', 'Stabilisation': 'HyperSmooth'}),
];

/// Stable pseudo-random number from a string (no dart:math Random, so the
/// demo looks the same every time).
int seedOf(String s) => s.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);

DateTime _ago(DateTime now, int minutes) => now.subtract(Duration(minutes: minutes));

const _urls = {
  'amazon': 'https://www.amazon.in/',
  'flipkart': 'https://www.flipkart.com/',
  'croma': 'https://www.croma.com/',
  'reliance': 'https://www.reliancedigital.in/',
  'tatacliq': 'https://www.tatacliq.com/',
};

List<Listing> buildListings(DateTime now) {
  final out = <Listing>[];
  for (final v in variants) {
    final h = seedOf(v.id);
    final count = 3 + h % 3; // 3-5 stores
    final start = h % merchants.length;
    for (var i = 0; i < count; i++) {
      final m = merchants[(start + i) % merchants.length];
      final delta = ((h >> (i * 3)) % 9 - 3) / 100; // -3% .. +5%
      final price = ((v.basePrice * (1 + delta)) / 10).round() * 10 - 1;
      final stale = i == 3 && h % 4 == 0;
      out.add(Listing(
        id: '${v.id}-${m.id}',
        variantId: v.id,
        merchantId: m.id,
        sellerName: m.id == 'amazon' || m.id == 'flipkart' ? '${m.name} verified seller' : m.name,
        authorisedSeller: true,
        price: price,
        mrp: (v.basePrice * 1.22 / 100).round() * 100 - 1,
        deliveryFee: price < 499 ? 40 : 0,
        inStock: !(i == 2 && h % 6 == 0),
        observedAt: _ago(now, stale ? 31 * 60 : 5 + (h >> i) % 240),
        outboundUrl: _urls[m.id]!,
      ));
    }
    // A suspiciously cheap unauthorised seller on some phones (anomaly demo).
    if (v.category.id == 'mobiles' && h % 3 == 0) {
      out.add(Listing(
        id: '${v.id}-unknown',
        variantId: v.id,
        merchantId: 'amazon',
        sellerName: 'Unknown marketplace seller',
        authorisedSeller: false,
        price: (v.basePrice * 0.7).round(),
        mrp: (v.basePrice * 1.22).round(),
        deliveryFee: 99,
        inStock: true,
        observedAt: _ago(now, 50),
        outboundUrl: _urls['amazon']!,
      ));
    }
  }
  return out;
}

List<Offer> buildOffers(DateTime now) {
  final soon = now.add(const Duration(days: 10));
  final checked = now.subtract(const Duration(hours: 6));
  Offer o(String id, String m, OfferType t, String title,
          {Set<String> needs = const {}, double percent = 0, int flat = 0, int? cap, int minCart = 0,
          bool instant = true, required String group, DateTime? until, String? condition}) =>
      Offer(
        id: id,
        merchantId: m,
        type: t,
        title: title,
        requiredInstrumentIds: needs,
        percent: percent,
        flat: flat,
        cap: cap,
        minCart: minCart,
        instant: instant,
        stackGroup: group,
        validUntil: until ?? soon,
        needsExtraCondition: condition != null,
        conditionNote: condition,
        verifiedAt: checked,
      );
  return [
    o('o1', 'amazon', OfferType.bankCard, '10% off with HDFC Bank credit cards', needs: {'hdfc_cc'}, percent: 10, cap: 3000, minCart: 5000, group: 'bank'),
    o('o2', 'amazon', OfferType.bankCard, '₹2,000 off with ICICI Bank credit cards', needs: {'icici_cc'}, flat: 2000, minCart: 30000, group: 'bank'),
    o('o3', 'amazon', OfferType.coupon, '₹500 coupon on product page', flat: 500, minCart: 3000, group: 'coupon'),
    o('o4', 'amazon', OfferType.bankCard, '5% back with Amazon Pay ICICI card', needs: {'apay_icici'}, percent: 5, instant: false, group: 'bank'),
    o('o5', 'amazon', OfferType.membership, 'Extra ₹1,000 for Prime members', flat: 1000, minCart: 20000, group: 'membership', condition: 'Needs Amazon Prime membership'),
    o('o6', 'flipkart', OfferType.bankCard, '₹3,000 off with SBI credit cards', needs: {'sbi_cc'}, flat: 3000, minCart: 40000, group: 'bank'),
    o('o7', 'flipkart', OfferType.bankCard, '10% off with Axis Bank credit cards', needs: {'axis_cc'}, percent: 10, cap: 1500, minCart: 5000, group: 'bank'),
    o('o8', 'flipkart', OfferType.bankCard, '5% back with Flipkart Axis Bank card', needs: {'fk_axis'}, percent: 5, cap: 4000, instant: false, group: 'bank'),
    o('o9', 'flipkart', OfferType.upi, '₹750 off with UPI', needs: {'upi'}, flat: 750, minCart: 10000, group: 'upi'),
    o('o10', 'flipkart', OfferType.exchange, 'Up to ₹6,000 extra on exchange', flat: 6000, minCart: 15000, group: 'exchange', condition: 'Needs an eligible old device to exchange'),
    o('o11', 'croma', OfferType.bankCard, '7.5% off with HDFC Bank cards', needs: {'hdfc_cc', 'hdfc_dc'}, percent: 7.5, cap: 5000, minCart: 10000, group: 'bank'),
    o('o12', 'croma', OfferType.coupon, 'Festive coupon FEST1000', flat: 1000, group: 'coupon', until: now.subtract(const Duration(days: 1))),
    o('o13', 'reliance', OfferType.bankCard, '10% off with Kotak credit cards', needs: {'kotak_cc'}, percent: 10, cap: 2500, minCart: 5000, group: 'bank'),
    o('o14', 'reliance', OfferType.bankCard, '₹1,500 off with ICICI Bank cards', needs: {'icici_cc'}, flat: 1500, minCart: 20000, group: 'bank'),
    o('o15', 'tatacliq', OfferType.bankCard, '10% off with ICICI Bank credit cards', needs: {'icici_cc'}, percent: 10, cap: 2000, minCart: 5000, group: 'bank'),
    o('o16', 'tatacliq', OfferType.firstOrder, '₹1,000 off your first order', flat: 1000, minCart: 5000, group: 'coupon', condition: 'Only on your first Tata CLiQ order'),
  ];
}

/// 120 days of synthetic lowest-price history ending near [current].
/// [level] > 1 means the product usually sold above today's price.
List<PricePoint> buildHistory(int current, DateTime now, {required int seed}) {
  final level = 0.92 + (seed % 17) / 100; // 0.92 .. 1.08
  final points = <PricePoint>[];
  for (var d = 120; d >= 1; d--) {
    final wave = ((d * 7 + seed * 13) % 23) - 11;
    final saleDip = (d > 40 && d < 48) ? -0.07 : 0.0;
    points.add(PricePoint(now.subtract(Duration(days: d)), (current * (level + wave / 500 + saleDip)).round()));
  }
  points.add(PricePoint(now, current));
  return points;
}

/// Demo aspect scores derived from the rating, labelled as demo in the UI.
List<ReportDimension> buildReportCard(Variant v) {
  final h = seedOf(v.id);
  final conf = v.reviewCount > 5000
      ? Confidence.high
      : v.reviewCount > 1500
          ? Confidence.medium
          : Confidence.low;
  final dims = <ReportDimension>[];
  for (var i = 0; i < v.category.aspects.length; i++) {
    final raw = v.rating * 2 + (((h >> (i * 4)) % 17) - 8) / 10;
    final score = (raw.clamp(5.0, 9.6) * 10).round() / 10;
    final evidence = (v.reviewCount ~/ (8 + i * 3)).clamp(3, 9999);
    dims.add(ReportDimension(
      name: v.category.aspects[i],
      score: score,
      confidence: conf,
      summary: score >= 8.5
          ? 'A clear strength in owner and expert reviews.'
          : score >= 7.5
              ? 'Good for most buyers; a few mixed reports.'
              : 'Mixed reviews. Check if this matters to you.',
      evidenceCount: evidence,
    ));
  }
  final enough = v.reviewCount >= 3000;
  dims.add(ReportDimension(
    name: 'Long-term reliability',
    score: enough ? ((v.rating * 2 - 0.4).clamp(5.0, 9.4) * 10).round() / 10 : null,
    confidence: enough ? Confidence.low : null,
    summary: enough ? 'Based on owners using it for 6+ months.' : 'Not enough long-term ownership reports yet.',
    evidenceCount: enough ? v.reviewCount ~/ 40 : 2,
  ));
  return dims;
}

List<ReviewInsight> buildInsights(Variant v, List<ReportDimension> card) {
  final scored = card.where((d) => d.score != null && d.name != 'Long-term reliability').toList()
    ..sort((a, b) => b.score!.compareTo(a.score!));
  if (scored.isEmpty) return const [];
  final src = 'Reviews (demo, ${v.reviewCount} ratings)';
  return [
    ReviewInsight(text: 'Owners rate the ${scored[0].name.toLowerCase()} highly (${scored[0].score}/10)', positive: true, source: src),
    if (scored.length > 1)
      ReviewInsight(text: '${scored[1].name} is a strong point (${scored[1].score}/10)', positive: true, source: src),
    ReviewInsight(text: '${scored.last.name} gets mixed reviews (${scored.last.score}/10)', positive: false, source: src),
  ];
}
