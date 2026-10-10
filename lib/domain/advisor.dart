import '../core/format.dart';
import '../data/models.dart';
import 'effective_price.dart';

/// Rule-based "Cunning Cat verdict" built only from computed facts
/// (prices from the engine, price history, ratings). It never invents numbers.
/// Phase 4 replaces the wording with a grounded LLM, but the facts stay these.

enum VerdictKind { buyNow, fairPrice, waitForDrop, considerAlternative, unavailable }

class Verdict {
  final VerdictKind kind;
  final String headline;
  final List<String> reasons;
  const Verdict(this.kind, this.headline, this.reasons);
}

class Alternative {
  final Variant variant;
  final int bestPrice;
  final String why;
  const Alternative(this.variant, this.bestPrice, this.why);
}

String merchantLabel(String id, List<Merchant> merchants) {
  for (final m in merchants) {
    if (m.id == id) return m.name;
  }
  return id;
}

Verdict buildVerdict({
  required Variant variant,
  required PriceBreakdown? best,
  required DealVerdict? deal,
  required List<ReportDimension> reportCard,
  required List<Alternative> alternatives,
  required List<Merchant> merchants,
}) {
  if (best == null) {
    return const Verdict(VerdictKind.unavailable, 'Not available right now',
        ['No store has a fresh, in-stock price. Add it to your wishlist and we will alert you.']);
  }
  final reasons = <String>[];
  final store = merchantLabel(best.listing.merchantId, merchants);
  reasons.add(best.instantSaving > 0
      ? 'Lowest price you can pay is ${rupees(best.yourBest)} on $store, after ${rupees(best.instantSaving)} in offers.'
      : 'Lowest price you can pay is ${rupees(best.yourBest)} on $store.');

  if (deal != null) reasons.add(deal.explanation);

  final scored = reportCard.where((d) => d.score != null && d.name != 'Long-term reliability').toList()
    ..sort((a, b) => b.score!.compareTo(a.score!));
  if (scored.isNotEmpty) {
    reasons.add('Rated ${variant.rating.toStringAsFixed(1)}★ from ${compact(variant.reviewCount)} ratings. '
        'Best at ${scored.first.name.toLowerCase()}; weakest at ${scored.last.name.toLowerCase()}.');
  }

  if (best.conditional.isNotEmpty) {
    final c = best.conditional.first;
    reasons.add('You could save ${rupees(c.extraSaving)} more: ${c.reason.toLowerCase()}.');
  }

  final better = alternatives.where((a) => a.variant.rating > variant.rating && a.bestPrice <= best.yourBest).toList();

  if (deal?.label == DealLabel.aboveUsual) {
    return Verdict(VerdictKind.waitForDrop, 'Wait: price is above its usual level', reasons);
  }
  if (better.isNotEmpty) {
    final a = better.first;
    reasons.add('${a.variant.familyName} is rated higher and costs ${rupees(a.bestPrice)}.');
    return Verdict(VerdictKind.considerAlternative, 'Good, but there is a better pick for the money', reasons);
  }
  if (deal?.label == DealLabel.lowestIn90Days || deal?.label == DealLabel.goodDeal) {
    return Verdict(VerdictKind.buyNow, 'Buy now: this is a good price', reasons);
  }
  return Verdict(VerdictKind.fairPrice, 'Fair price: buy if you need it now', reasons);
}

/// Same-category products within roughly the same budget, best rated first.
List<Alternative> findAlternatives({
  required Variant variant,
  required int budget,
  required List<Variant> catalog,
  required Map<String, int> bestPrices,
}) {
  final out = <Alternative>[];
  for (final v in catalog) {
    if (v.id == variant.id || v.category.id != variant.category.id) continue;
    final p = bestPrices[v.id];
    if (p == null || p < budget * 0.6 || p > budget * 1.2) continue;
    final diff = budget - p;
    final why = diff > 0
        ? '${rupees(diff)} cheaper · ${v.rating.toStringAsFixed(1)}★'
        : '${rupees(-diff)} more · ${v.rating.toStringAsFixed(1)}★';
    out.add(Alternative(v, p, why));
  }
  out.sort((a, b) {
    final r = b.variant.rating.compareTo(a.variant.rating);
    return r != 0 ? r : a.bestPrice.compareTo(b.bestPrice);
  });
  return out.take(4).toList();
}

/// Star distribution (5..1) consistent with an average rating; demo only.
List<double> starShares(double rating) {
  final five = ((rating - 3.0) / 2.0).clamp(0.15, 0.85);
  final four = (1 - five) * 0.55;
  final three = (1 - five - four) * 0.5;
  final two = (1 - five - four - three) * 0.4;
  final one = 1 - five - four - three - two;
  return [five, four, three, two, one];
}
