import 'package:flutter_test/flutter_test.dart';

import 'package:cunning_cat/data/models.dart';
import 'package:cunning_cat/domain/effective_price.dart';

/// Benchmark scenarios from the Master Spec (section 7), as unit tests.
void main() {
  final now = DateTime(2026, 10, 10, 12);
  final later = now.add(const Duration(days: 5));

  Listing listing({int price = 80000, int delivery = 0, Duration age = const Duration(minutes: 10), bool inStock = true, String id = 'l'}) =>
      Listing(
        id: id,
        variantId: 'v',
        merchantId: 'm',
        sellerName: 'S',
        authorisedSeller: true,
        price: price,
        mrp: 100000,
        deliveryFee: delivery,
        inStock: inStock,
        observedAt: now.subtract(age),
        outboundUrl: 'https://example.com',
      );

  Offer offer(String id, {Set<String> needs = const {}, double percent = 0, int flat = 0, int? cap, int minCart = 0,
          bool instant = true, String group = 'bank', DateTime? until, bool extra = false}) =>
      Offer(
        id: id,
        merchantId: 'm',
        type: OfferType.bankCard,
        title: id,
        requiredInstrumentIds: needs,
        percent: percent,
        flat: flat,
        cap: cap,
        minCart: minCart,
        instant: instant,
        stackGroup: group,
        validUntil: until ?? later,
        needsExtraCondition: extra,
        conditionNote: extra ? 'Needs membership' : null,
        verifiedAt: now,
      );

  final hdfcCc = offer('hdfc_cc_10pct', needs: {'hdfc_cc'}, percent: 10, cap: 3000);
  final coupon = offer('coupon_500', flat: 500, group: 'coupon');
  final labels = {'hdfc_cc': 'HDFC Bank Credit card'};

  PriceBreakdown run(List<Offer> offers, Set<String> owned, {Listing? l}) => computeEffectivePrice(
        listing: l ?? listing(),
        offers: offers,
        ownedInstrumentIds: owned,
        now: now,
        instrumentLabels: labels,
      );

  test('percent offer respects cap', () {
    expect(offerSaving(hdfcCc, 80000), 3000);
    expect(offerSaving(hdfcCc, 20000), 2000);
  });

  test('ineligible bank offer: debit card does not unlock a credit-card offer', () {
    final b = run([hdfcCc, coupon], {'hdfc_dc'});
    expect(b.yourBest, 79500);
    expect(b.yourOffers.map((a) => a.offer.id), isNot(contains('hdfc_cc_10pct')));
    expect(b.conditional.single.offer.id, 'hdfc_cc_10pct');
    expect(b.conditional.single.reason, contains('HDFC Bank Credit card'));
  });

  test('eligible card lowers your best price but not the guaranteed price', () {
    final b = run([hdfcCc, coupon], {'hdfc_cc'});
    expect(b.guaranteed, 79500);
    expect(b.yourBest, 76500);
    expect(b.instantSaving, 3500);
  });

  test('conflicting discounts in one stack group: only the best applies', () {
    final sbi = offer('sbi_flat_4000', needs: {'sbi_cc'}, flat: 4000);
    final b = run([hdfcCc, sbi], {'hdfc_cc', 'sbi_cc'});
    expect(b.yourOffers.length, 1);
    expect(b.yourOffers.single.offer.id, 'sbi_flat_4000');
    expect(b.yourBest, 76000);
  });

  test('expired coupon is excluded and never applied', () {
    final expired = offer('old_coupon', flat: 1000, group: 'coupon', until: now.subtract(const Duration(hours: 1)));
    final b = run([expired], {});
    expect(b.yourBest, 80000);
    expect(b.excluded.single.reason, 'Expired');
  });

  test('deferred cashback is reported separately, not subtracted', () {
    final axis = offer('axis_5pct_cb', needs: {'axis_cc'}, percent: 5, cap: 4000, instant: false);
    final b = run([axis], {'axis_cc'});
    expect(b.yourBest, 80000);
    expect(b.deferredCashback, 4000);
  });

  test('minimum cart not met becomes a conditional offer', () {
    final big = offer('big_cart', flat: 5000, minCart: 100000, group: 'cart');
    final b = run([big], {});
    expect(b.yourBest, 80000);
    expect(b.conditional.single.reason, contains('cart value'));
  });

  test('membership offer is conditional, never in your best price', () {
    final prime = offer('prime_1000', flat: 1000, group: 'membership', extra: true);
    final b = run([prime], {});
    expect(b.yourBest, 80000);
    expect(b.conditional.single.extraSaving, 1000);
  });

  test('delivery fee is included in the payable amount', () {
    final b = run([], {}, l: listing(delivery: 99));
    expect(b.base, 80099);
    expect(b.yourBest, 80099);
  });

  test('outdated price is stale and ranked after fresh prices even if cheaper', () {
    final fresh = run([], {}, l: listing(id: 'fresh', price: 80000));
    final stale = run([], {}, l: listing(id: 'stale', price: 70000, age: const Duration(hours: 30)));
    expect(stale.stale, isTrue);
    final ranked = rankBreakdowns([stale, fresh]);
    expect(ranked.first.listing.id, 'fresh');
  });

  test('out-of-stock listing is not comparable', () {
    final b = run([], {}, l: listing(inStock: false));
    expect(b.comparable, isFalse);
  });

  test('no-cost EMI still costs GST on interest plus processing fee', () {
    final r = trueEmiCost(principal: 60000, annualRatePercent: 15, months: 6, processingFee: 199, noCost: true);
    expect(r.monthly, 10000);
    expect(r.totalInterest, closeTo(2652, 5));
    expect(r.processingFeeWithGst, 235);
    expect(r.extraCost, r.gstOnInterest + 235);
  });

  test('inflated MRP is flagged when the price is usual', () {
    final history = [for (var d = 0; d < 90; d++) PricePoint(now.subtract(Duration(days: d)), 80000)];
    final v = assessDeal(currentPrice: 80000, mrp: 120000, history: history, now: now);
    expect(v.mrpLooksInflated, isTrue);
  });

  test('too little history gives no verdict', () {
    final history = [for (var d = 0; d < 5; d++) PricePoint(now.subtract(Duration(days: d)), 80000)];
    final v = assessDeal(currentPrice: 80000, mrp: 90000, history: history, now: now);
    expect(v.label, DealLabel.notEnoughHistory);
  });
}
