import 'dart:math' as math;

import '../data/models.dart';

/// Deterministic effective-price engine (ADR-0004).
///
/// The LLM never computes prices. Every number shown to the user comes from
/// this code and carries an explanation of each offer applied.
///
/// Three tiers:
///  * guaranteed  - price + delivery minus offers anyone can use right now
///  * yourBest    - also uses payment instruments the user says they own
///  * conditional - offers needing something we can't confirm (membership,
///                  first order, exchange, a card the user doesn't own,
///                  a bigger cart); shown separately, never in yourBest.
///
/// v0 simplification (documented in ADR-0004): each offer's discount is
/// computed on the listing's item price, not on the price after other
/// discounts. Retailer-specific ordering rules come with the offer rules spec.

class AppliedOffer {
  final Offer offer;
  final int saving;
  const AppliedOffer(this.offer, this.saving);
}

class ConditionalOffer {
  final Offer offer;

  /// Extra saving over what the user already gets in this offer's stack group.
  final int extraSaving;
  final String reason;
  const ConditionalOffer(this.offer, this.extraSaving, this.reason);
}

class ExcludedOffer {
  final Offer offer;
  final String reason;
  const ExcludedOffer(this.offer, this.reason);
}

class PriceBreakdown {
  final Listing listing;
  final int base; // item price + delivery
  final int guaranteed;
  final int yourBest;
  final List<AppliedOffer> guaranteedOffers;
  final List<AppliedOffer> yourOffers; // instant offers in yourBest
  final int deferredCashback; // arrives later, never subtracted
  final List<AppliedOffer> cashbackOffers;
  final List<ConditionalOffer> conditional;
  final List<ExcludedOffer> excluded;
  final bool stale;

  const PriceBreakdown({
    required this.listing,
    required this.base,
    required this.guaranteed,
    required this.yourBest,
    required this.guaranteedOffers,
    required this.yourOffers,
    required this.deferredCashback,
    required this.cashbackOffers,
    required this.conditional,
    required this.excluded,
    required this.stale,
  });

  int get instantSaving => base - yourBest;

  /// Only fresh, in-stock listings may be called "cheapest".
  bool get comparable => listing.inStock && !stale;
}

/// Saving an offer gives on [itemPrice], respecting percent, flat and cap.
int offerSaving(Offer offer, int itemPrice) {
  var raw = (itemPrice * offer.percent / 100).floor() + offer.flat;
  if (offer.cap != null) raw = math.min(raw, offer.cap!);
  return math.max(0, math.min(raw, itemPrice));
}

/// Picks the single best offer per stack group. Ties prefer instant offers.
List<AppliedOffer> _bestPerGroup(Iterable<Offer> offers, int itemPrice) {
  final best = <String, AppliedOffer>{};
  for (final o in offers) {
    final s = offerSaving(o, itemPrice);
    if (s <= 0) continue;
    final current = best[o.stackGroup];
    final better = current == null ||
        s > current.saving ||
        (s == current.saving && o.instant && !current.offer.instant);
    if (better) best[o.stackGroup] = AppliedOffer(o, s);
  }
  return best.values.toList();
}

int _sum(Iterable<AppliedOffer> xs) => xs.fold(0, (a, b) => a + b.saving);

PriceBreakdown computeEffectivePrice({
  required Listing listing,
  required List<Offer> offers,
  required Set<String> ownedInstrumentIds,
  required DateTime now,
  Map<String, String> instrumentLabels = const {},
  Duration staleAfter = const Duration(hours: 24),
}) {
  final price = listing.price;
  final base = price + listing.deliveryFee;

  final excluded = <ExcludedOffer>[];
  final openToAll = <Offer>[];
  final personal = <Offer>[];
  final locked = <Offer, String>{};

  for (final o in offers.where((o) => o.merchantId == listing.merchantId)) {
    if (o.validUntil.isBefore(now)) {
      excluded.add(ExcludedOffer(o, 'Expired'));
    } else if (price < o.minCart) {
      locked[o] = 'Needs a cart value of at least ₹${o.minCart}';
    } else if (o.needsExtraCondition) {
      locked[o] = o.conditionNote ?? 'Has extra conditions';
    } else if (o.requiredInstrumentIds.isEmpty) {
      openToAll.add(o);
    } else if (o.requiredInstrumentIds.any(ownedInstrumentIds.contains)) {
      personal.add(o);
    } else {
      final names = o.requiredInstrumentIds
          .map((id) => instrumentLabels[id] ?? id)
          .join(' or ');
      locked[o] = 'Needs $names';
    }
  }

  // Guaranteed tier: instant offers open to everyone.
  final guaranteedOffers = _bestPerGroup(openToAll.where((o) => o.instant), price);
  final guaranteed = math.max(0, base - _sum(guaranteedOffers));

  // Your-best tier: everything the user is eligible for, best per group.
  final picks = _bestPerGroup([...openToAll, ...personal], price);
  final yourOffers = picks.where((a) => a.offer.instant).toList();
  final cashbackOffers = picks.where((a) => !a.offer.instant).toList();
  final yourBest = math.max(0, base - _sum(yourOffers));

  // Conditional: only show offers that would beat the current pick in their group.
  final groupSaving = {for (final a in picks) a.offer.stackGroup: a.saving};
  final conditional = <ConditionalOffer>[];
  locked.forEach((o, reason) {
    final potential = offerSaving(o, math.max(price, o.minCart));
    final extra = potential - (groupSaving[o.stackGroup] ?? 0);
    if (extra > 0) conditional.add(ConditionalOffer(o, extra, reason));
  });
  conditional.sort((a, b) => b.extraSaving.compareTo(a.extraSaving));

  return PriceBreakdown(
    listing: listing,
    base: base,
    guaranteed: guaranteed,
    yourBest: yourBest,
    guaranteedOffers: guaranteedOffers,
    yourOffers: yourOffers,
    deferredCashback: _sum(cashbackOffers),
    cashbackOffers: cashbackOffers,
    conditional: conditional,
    excluded: excluded,
    stale: now.difference(listing.observedAt) > staleAfter,
  );
}

/// Sorts breakdowns: comparable (fresh, in stock) first by yourBest,
/// then everything else.
List<PriceBreakdown> rankBreakdowns(List<PriceBreakdown> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    if (a.comparable != b.comparable) return a.comparable ? -1 : 1;
    return a.yourBest.compareTo(b.yourBest);
  });
  return sorted;
}

// ---------------------------------------------------------------------------
// True EMI cost (feature N3)
// ---------------------------------------------------------------------------

class EmiResult {
  final int monthly;
  final int totalInterest;
  final int gstOnInterest;
  final int processingFeeWithGst;

  /// What you pay on top of the upfront price over the whole EMI.
  final int extraCost;
  const EmiResult({
    required this.monthly,
    required this.totalInterest,
    required this.gstOnInterest,
    required this.processingFeeWithGst,
    required this.extraCost,
  });
}

/// For "no-cost" EMI the interest is given back as an upfront discount,
/// but banks still charge GST (18%) on the interest and a processing fee.
EmiResult trueEmiCost({
  required int principal,
  required double annualRatePercent,
  required int months,
  int processingFee = 0,
  bool noCost = false,
  double gstRate = 0.18,
}) {
  final r = annualRatePercent / 12 / 100;
  final double emi = r == 0
      ? principal / months
      : principal * r * math.pow(1 + r, months) / (math.pow(1 + r, months) - 1);
  final totalInterest = (emi * months - principal).round();
  final gst = (totalInterest * gstRate).round();
  final fee = (processingFee * (1 + gstRate)).round();
  final extra = noCost ? gst + fee : totalInterest + gst + fee;
  final monthly = noCost ? (principal / months).round() : emi.round();
  return EmiResult(
    monthly: monthly,
    totalInterest: totalInterest,
    gstOnInterest: gst,
    processingFeeWithGst: fee,
    extraCost: extra,
  );
}

// ---------------------------------------------------------------------------
// Deal quality + inflated-MRP detector (feature N2)
// ---------------------------------------------------------------------------

enum DealLabel { lowestIn90Days, goodDeal, typicalPrice, aboveUsual, notEnoughHistory }

class DealVerdict {
  final DealLabel label;
  final String explanation;
  final bool mrpLooksInflated;
  const DealVerdict(this.label, this.explanation, this.mrpLooksInflated);
}

DealVerdict assessDeal({
  required int currentPrice,
  required int mrp,
  required List<PricePoint> history,
  required DateTime now,
}) {
  final window = history
      .where((p) => now.difference(p.date) <= const Duration(days: 90))
      .map((p) => p.lowestPrice)
      .toList()
    ..sort();
  if (window.length < 14) {
    return const DealVerdict(
      DealLabel.notEnoughHistory,
      'We have under 14 days of price history, so we can\'t judge this deal yet.',
      false,
    );
  }
  final low = window.first;
  final median = window[window.length ~/ 2];
  final mrpDiscount = mrp > 0 ? (mrp - currentPrice) / mrp : 0.0;
  final inflated = mrpDiscount >= 0.30 && currentPrice >= median * 0.97;
  final pctOff = (mrpDiscount * 100).round();

  if (currentPrice <= low * 1.01) {
    return DealVerdict(DealLabel.lowestIn90Days,
        'Lowest price we have seen in 90 days.', inflated);
  }
  if (currentPrice <= median * 0.95) {
    return DealVerdict(DealLabel.goodDeal,
        'About ${((1 - currentPrice / median) * 100).round()}% below its usual price.', inflated);
  }
  if (currentPrice > median * 1.05) {
    return DealVerdict(DealLabel.aboveUsual,
        'Above its usual price. Consider waiting or setting an alert.', inflated);
  }
  return DealVerdict(
    DealLabel.typicalPrice,
    inflated
        ? 'The "$pctOff% off" is measured against MRP, but it has sold near this price for weeks.'
        : 'Close to its usual price over the last 90 days.',
    inflated,
  );
}
