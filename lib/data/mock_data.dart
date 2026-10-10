import 'models.dart';

/// DEMO DATA ONLY. Product names are real models; every price, offer,
/// score and review insight below is invented for building and testing the
/// app. Nothing here should be shown to the public.

const merchants = <Merchant>[
  Merchant(id: 'amazon', name: 'Amazon'),
  Merchant(id: 'flipkart', name: 'Flipkart'),
  Merchant(id: 'croma', name: 'Croma'),
  Merchant(id: 'reliance', name: 'Reliance Digital'),
];

const instruments = <PaymentInstrument>[
  PaymentInstrument(id: 'hdfc_cc', bank: 'HDFC Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'hdfc_dc', bank: 'HDFC Bank', kind: 'Debit card'),
  PaymentInstrument(id: 'sbi_cc', bank: 'SBI', kind: 'Credit card'),
  PaymentInstrument(id: 'icici_cc', bank: 'ICICI Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'axis_cc', bank: 'Axis Bank', kind: 'Credit card'),
  PaymentInstrument(id: 'kotak_cc', bank: 'Kotak', kind: 'Credit card'),
  PaymentInstrument(id: 'upi', bank: 'Any bank', kind: 'UPI'),
];

const variants = <Variant>[
  Variant(
    id: 'galaxy-s25-256-navy',
    familyName: 'Samsung Galaxy S25',
    brand: 'Samsung',
    category: Category.mobiles,
    variantLabel: '12GB / 256GB · Navy',
    keySpecs: {'Display': '6.2" 120Hz', 'Storage': '256 GB', 'RAM': '12 GB', 'Battery': '4000 mAh'},
  ),
  Variant(
    id: 'iphone-16-128-black',
    familyName: 'Apple iPhone 16',
    brand: 'Apple',
    category: Category.mobiles,
    variantLabel: '128GB · Black',
    keySpecs: {'Display': '6.1" 60Hz', 'Storage': '128 GB', 'Chip': 'A18'},
  ),
  Variant(
    id: 'pixel-9-256-obsidian',
    familyName: 'Google Pixel 9',
    brand: 'Google',
    category: Category.mobiles,
    variantLabel: '12GB / 256GB · Obsidian',
    keySpecs: {'Display': '6.3" 120Hz', 'Storage': '256 GB', 'RAM': '12 GB'},
  ),
  Variant(
    id: 'macbook-air-m3-13-256',
    familyName: 'Apple MacBook Air 13 (M3)',
    brand: 'Apple',
    category: Category.laptops,
    variantLabel: '8GB / 256GB · Midnight',
    keySpecs: {'Chip': 'M3', 'RAM': '8 GB', 'SSD': '256 GB', 'Weight': '1.24 kg'},
  ),
  Variant(
    id: 'sony-bravia-55-x80l',
    familyName: 'Sony Bravia 55" X80L',
    brand: 'Sony',
    category: Category.televisions,
    variantLabel: '55 inch · 4K',
    keySpecs: {'Size': '55"', 'Resolution': '4K', 'Refresh': '60Hz'},
  ),
];

DateTime _ago(DateTime now, {int minutes = 0, int hours = 0}) =>
    now.subtract(Duration(minutes: minutes, hours: hours));

List<Listing> buildListings(DateTime now) => [
      // Galaxy S25
      Listing(id: 'l1', variantId: 'galaxy-s25-256-navy', merchantId: 'amazon', sellerName: 'Appario Retail', authorisedSeller: true, price: 80999, mrp: 92999, deliveryFee: 0, inStock: true, observedAt: _ago(now, minutes: 18), outboundUrl: 'https://www.amazon.in/'),
      Listing(id: 'l2', variantId: 'galaxy-s25-256-navy', merchantId: 'flipkart', sellerName: 'Flipkart Seller A', authorisedSeller: true, price: 79999, mrp: 92999, deliveryFee: 0, inStock: true, observedAt: _ago(now, minutes: 42), outboundUrl: 'https://www.flipkart.com/'),
      Listing(id: 'l3', variantId: 'galaxy-s25-256-navy', merchantId: 'croma', sellerName: 'Croma', authorisedSeller: true, price: 81490, mrp: 92999, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 3), outboundUrl: 'https://www.croma.com/'),
      Listing(id: 'l4', variantId: 'galaxy-s25-256-navy', merchantId: 'reliance', sellerName: 'Reliance Digital', authorisedSeller: true, price: 78999, mrp: 92999, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 30), outboundUrl: 'https://www.reliancedigital.in/'),
      // iPhone 16
      Listing(id: 'l5', variantId: 'iphone-16-128-black', merchantId: 'amazon', sellerName: 'Appario Retail', authorisedSeller: true, price: 72900, mrp: 79900, deliveryFee: 0, inStock: true, observedAt: _ago(now, minutes: 25), outboundUrl: 'https://www.amazon.in/'),
      Listing(id: 'l6', variantId: 'iphone-16-128-black', merchantId: 'flipkart', sellerName: 'Flipkart Seller B', authorisedSeller: true, price: 71999, mrp: 79900, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 1), outboundUrl: 'https://www.flipkart.com/'),
      Listing(id: 'l7', variantId: 'iphone-16-128-black', merchantId: 'croma', sellerName: 'Croma', authorisedSeller: true, price: 73490, mrp: 79900, deliveryFee: 0, inStock: false, observedAt: _ago(now, hours: 2), outboundUrl: 'https://www.croma.com/'),
      // Pixel 9
      Listing(id: 'l8', variantId: 'pixel-9-256-obsidian', merchantId: 'flipkart', sellerName: 'Flipkart Seller C', authorisedSeller: true, price: 74999, mrp: 79999, deliveryFee: 0, inStock: true, observedAt: _ago(now, minutes: 55), outboundUrl: 'https://www.flipkart.com/'),
      Listing(id: 'l9', variantId: 'pixel-9-256-obsidian', merchantId: 'amazon', sellerName: 'Unknown Seller', authorisedSeller: false, price: 52999, mrp: 79999, deliveryFee: 99, inStock: true, observedAt: _ago(now, hours: 2), outboundUrl: 'https://www.amazon.in/'),
      // MacBook Air
      Listing(id: 'l10', variantId: 'macbook-air-m3-13-256', merchantId: 'amazon', sellerName: 'Appario Retail', authorisedSeller: true, price: 94990, mrp: 114900, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 1), outboundUrl: 'https://www.amazon.in/'),
      Listing(id: 'l11', variantId: 'macbook-air-m3-13-256', merchantId: 'croma', sellerName: 'Croma', authorisedSeller: true, price: 96990, mrp: 114900, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 4), outboundUrl: 'https://www.croma.com/'),
      // Sony TV
      Listing(id: 'l12', variantId: 'sony-bravia-55-x80l', merchantId: 'amazon', sellerName: 'Cloudtail', authorisedSeller: true, price: 64990, mrp: 99900, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 2), outboundUrl: 'https://www.amazon.in/'),
      Listing(id: 'l13', variantId: 'sony-bravia-55-x80l', merchantId: 'flipkart', sellerName: 'Flipkart Seller D', authorisedSeller: true, price: 65490, mrp: 99900, deliveryFee: 0, inStock: true, observedAt: _ago(now, hours: 5), outboundUrl: 'https://www.flipkart.com/'),
    ];

List<Offer> buildOffers(DateTime now) {
  final soon = now.add(const Duration(days: 10));
  final checked = now.subtract(const Duration(hours: 6));
  return [
    Offer(id: 'o1', merchantId: 'amazon', type: OfferType.bankCard, title: '10% off with HDFC Bank credit cards', requiredInstrumentIds: const {'hdfc_cc'}, percent: 10, cap: 3000, minCart: 5000, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o2', merchantId: 'amazon', type: OfferType.bankCard, title: '₹2,000 off with ICICI Bank credit cards', requiredInstrumentIds: const {'icici_cc'}, flat: 2000, minCart: 30000, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o3', merchantId: 'amazon', type: OfferType.coupon, title: '₹500 coupon on product page', flat: 500, stackGroup: 'coupon', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o4', merchantId: 'flipkart', type: OfferType.bankCard, title: '5% cashback with Axis Bank credit cards', requiredInstrumentIds: const {'axis_cc'}, percent: 5, cap: 4000, instant: false, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o5', merchantId: 'flipkart', type: OfferType.bankCard, title: '₹3,000 off with SBI credit cards', requiredInstrumentIds: const {'sbi_cc'}, flat: 3000, minCart: 40000, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o6', merchantId: 'flipkart', type: OfferType.upi, title: '₹750 off with UPI', requiredInstrumentIds: const {'upi'}, flat: 750, stackGroup: 'upi', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o7', merchantId: 'flipkart', type: OfferType.exchange, title: 'Up to ₹6,000 extra on exchange', flat: 6000, stackGroup: 'exchange', validUntil: soon, needsExtraCondition: true, conditionNote: 'Needs an eligible old phone to exchange', verifiedAt: checked),
    Offer(id: 'o8', merchantId: 'croma', type: OfferType.bankCard, title: '7.5% off with HDFC Bank cards', requiredInstrumentIds: const {'hdfc_cc', 'hdfc_dc'}, percent: 7.5, cap: 5000, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o9', merchantId: 'croma', type: OfferType.coupon, title: 'Festive coupon FEST1000', flat: 1000, stackGroup: 'coupon', validUntil: now.subtract(const Duration(days: 1)), verifiedAt: checked),
    Offer(id: 'o10', merchantId: 'reliance', type: OfferType.bankCard, title: '10% off with Kotak credit cards', requiredInstrumentIds: const {'kotak_cc'}, percent: 10, cap: 2500, stackGroup: 'bank', validUntil: soon, verifiedAt: checked),
    Offer(id: 'o11', merchantId: 'amazon', type: OfferType.membership, title: 'Extra ₹1,000 for Prime members', flat: 1000, stackGroup: 'membership', validUntil: soon, needsExtraCondition: true, conditionNote: 'Needs Amazon Prime membership', verifiedAt: checked),
  ];
}

/// 120 days of synthetic lowest-price history around [basePrice].
List<PricePoint> buildHistory(int basePrice, DateTime now, {int seed = 1}) {
  final points = <PricePoint>[];
  for (var d = 120; d >= 0; d--) {
    final wave = ((d * 7 + seed * 13) % 23) - 11; // deterministic wiggle
    final saleDip = (d > 40 && d < 48) ? -0.08 : 0.0; // a past sale
    final price = (basePrice * (1.04 + wave / 400 + saleDip)).round();
    points.add(PricePoint(now.subtract(Duration(days: d)), price));
  }
  return points;
}

final reportCards = <String, List<ReportDimension>>{
  'galaxy-s25-256-navy': const [
    ReportDimension(name: 'Performance', score: 9.0, confidence: Confidence.high, summary: 'Fast in daily use and gaming; stays cool in most reviews.', evidenceCount: 42),
    ReportDimension(name: 'Camera', score: 8.4, confidence: Confidence.high, summary: 'Strong daylight photos; night video is average.', evidenceCount: 38),
    ReportDimension(name: 'Battery', score: 7.0, confidence: Confidence.medium, summary: 'A full day for most users; heavy users top up by evening.', evidenceCount: 27),
    ReportDimension(name: 'Long-term reliability', score: null, confidence: null, summary: 'Not enough ownership reports yet.', evidenceCount: 3),
  ],
  'iphone-16-128-black': const [
    ReportDimension(name: 'Performance', score: 9.1, confidence: Confidence.high, summary: 'Very fast; excellent software support.', evidenceCount: 51),
    ReportDimension(name: 'Camera', score: 8.6, confidence: Confidence.high, summary: 'Reliable photos and class-leading video.', evidenceCount: 44),
    ReportDimension(name: 'Battery', score: 7.6, confidence: Confidence.medium, summary: 'Comfortably lasts a day.', evidenceCount: 30),
    ReportDimension(name: 'Value for money', score: 6.5, confidence: Confidence.medium, summary: '60Hz screen and 128GB base storage at this price.', evidenceCount: 19),
  ],
};

final reviewInsights = <String, List<ReviewInsight>>{
  'galaxy-s25-256-navy': const [
    ReviewInsight(text: 'Compact and light for a flagship', positive: true, source: 'Expert reviews (6)'),
    ReviewInsight(text: 'Smooth 120Hz display', positive: true, source: 'Retailer reviews (demo)'),
    ReviewInsight(text: 'Charging is slower than rivals (25W)', positive: false, source: 'Expert reviews (5)'),
    ReviewInsight(text: 'Battery tight for heavy users', positive: false, source: 'Retailer reviews (demo)'),
  ],
};
