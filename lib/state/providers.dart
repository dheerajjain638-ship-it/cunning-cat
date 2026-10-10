import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../domain/advisor.dart';
import '../domain/effective_price.dart';

final repositoryProvider = Provider<CatalogRepository>((ref) => MockCatalogRepository());

/// Payment instruments the user says they own (types only, never numbers).
class WalletNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'upi'};

  void toggle(String instrumentId) {
    final next = {...state};
    if (!next.remove(instrumentId)) next.add(instrumentId);
    state = next;
  }
}

final walletProvider = NotifierProvider<WalletNotifier, Set<String>>(WalletNotifier.new);

class WishlistItem {
  final String variantId;
  final int? targetPrice;
  const WishlistItem(this.variantId, {this.targetPrice});
}

class WishlistNotifier extends Notifier<List<WishlistItem>> {
  @override
  List<WishlistItem> build() => const [];

  bool contains(String variantId) => state.any((w) => w.variantId == variantId);

  void toggle(String variantId) {
    state = contains(variantId)
        ? state.where((w) => w.variantId != variantId).toList()
        : [...state, WishlistItem(variantId)];
  }

  void setTarget(String variantId, int? target) {
    state = [
      for (final w in state)
        if (w.variantId == variantId) WishlistItem(variantId, targetPrice: target) else w,
    ];
  }
}

final wishlistProvider =
    NotifierProvider<WishlistNotifier, List<WishlistItem>>(WishlistNotifier.new);

/// Recent searches typed by the user (this session).
class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String q) {
    final t = q.trim();
    if (t.isEmpty || t.startsWith('http')) return;
    state = [t, ...state.where((s) => s.toLowerCase() != t.toLowerCase())].take(6).toList();
  }
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

typedef SearchArgs = ({String query, String? categoryId});

final searchProvider = FutureProvider.autoDispose.family<List<Variant>, SearchArgs>(
  (ref, args) => ref.watch(repositoryProvider).search(args.query, categoryId: args.categoryId),
);

/// One line of facts per product, for lists, cards and alternatives.
class ProductSummary {
  final Variant variant;
  final PriceBreakdown? best;
  final DealVerdict? deal;
  final int storeCount;
  const ProductSummary(this.variant, this.best, this.deal, this.storeCount);

  /// How far today's price sits below the 90-day median (0.08 = 8% below).
  double get belowUsual {
    final d = deal;
    if (d == null || d.medianPrice == 0 || best == null) return 0;
    return (d.medianPrice - best!.listing.price) / d.medianPrice;
  }
}

Future<ProductSummary> _summarise(CatalogRepository repo, Variant v, List<Offer> offers, Set<String> owned,
    Map<String, String> labels, DateTime now) async {
  final listings = await repo.listingsFor(v.id);
  final ranked = rankBreakdowns([
    for (final l in listings)
      computeEffectivePrice(listing: l, offers: offers, ownedInstrumentIds: owned, now: now, instrumentLabels: labels),
  ]);
  PriceBreakdown? best;
  for (final b in ranked) {
    if (b.comparable && b.listing.authorisedSeller) {
      best = b;
      break;
    }
  }
  final history = await repo.history(v.id);
  final deal = best == null
      ? null
      : assessDeal(currentPrice: best.listing.price, mrp: best.listing.mrp, history: history, now: now);
  return ProductSummary(v, best, deal, listings.where((l) => l.authorisedSeller).length);
}

/// Summaries for the whole catalog, recomputed when the wallet changes.
final catalogSummaryProvider = FutureProvider<Map<String, ProductSummary>>((ref) async {
  final repo = ref.watch(repositoryProvider);
  final owned = ref.watch(walletProvider);
  final offers = await repo.offers();
  final labels = {for (final i in repo.instruments) i.id: i.label};
  final now = DateTime.now();
  final out = <String, ProductSummary>{};
  for (final v in repo.all) {
    out[v.id] = await _summarise(repo, v, offers, owned, labels, now);
  }
  return out;
});

/// Best deals right now: furthest below their usual price.
final dealsProvider = FutureProvider<List<ProductSummary>>((ref) async {
  final all = await ref.watch(catalogSummaryProvider.future);
  final deals = all.values.where((s) => s.best != null && s.belowUsual > 0.02).toList()
    ..sort((a, b) => b.belowUsual.compareTo(a.belowUsual));
  return deals.take(8).toList();
});

/// Everything the product screen needs, computed by the deterministic engine.
class ProductView {
  final Variant variant;
  final List<PriceBreakdown> ranked;
  final List<PricePoint> history;
  final DealVerdict? deal;
  final List<ReportDimension> reportCard;
  final List<ReviewInsight> insights;
  final List<Offer> offers;
  final List<Alternative> alternatives;
  final Verdict verdict;
  const ProductView({
    required this.variant,
    required this.ranked,
    required this.history,
    required this.deal,
    required this.reportCard,
    required this.insights,
    required this.offers,
    required this.alternatives,
    required this.verdict,
  });

  PriceBreakdown? get best {
    for (final b in ranked) {
      if (b.comparable && b.listing.authorisedSeller) return b;
    }
    return null;
  }

  /// Unauthorised listing priced far below authorised sellers: possible scam.
  bool isPriceAnomaly(PriceBreakdown b) {
    final others = ranked.where((x) => x.listing.authorisedSeller && x != b).toList();
    if (others.isEmpty) return false;
    final minOther = others.map((x) => x.listing.price).reduce((a, c) => a < c ? a : c);
    return !b.listing.authorisedSeller && b.listing.price < minOther * 0.8;
  }
}

final productProvider = FutureProvider.autoDispose.family<ProductView?, String>((ref, id) async {
  final repo = ref.watch(repositoryProvider);
  final owned = ref.watch(walletProvider);
  final variant = await repo.variant(id);
  if (variant == null) return null;
  final now = DateTime.now();
  final listings = await repo.listingsFor(id);
  final offers = await repo.offers();
  final labels = {for (final i in repo.instruments) i.id: i.label};
  final ranked = rankBreakdowns([
    for (final l in listings)
      computeEffectivePrice(listing: l, offers: offers, ownedInstrumentIds: owned, now: now, instrumentLabels: labels),
  ]);
  final history = await repo.history(id);
  PriceBreakdown? best;
  for (final b in ranked) {
    if (b.comparable && b.listing.authorisedSeller) {
      best = b;
      break;
    }
  }
  final deal = best == null
      ? null
      : assessDeal(currentPrice: best.listing.price, mrp: best.listing.mrp, history: history, now: now);
  final summaries = await ref.watch(catalogSummaryProvider.future);
  final alternatives = best == null
      ? <Alternative>[]
      : findAlternatives(
          variant: variant,
          budget: best.yourBest,
          catalog: repo.all,
          bestPrices: {
            for (final s in summaries.values)
              if (s.best != null) s.variant.id: s.best!.yourBest,
          },
        );
  final reportCard = await repo.reportCard(id);
  final storeIds = listings.map((l) => l.merchantId).toSet();
  return ProductView(
    variant: variant,
    ranked: ranked,
    history: history,
    deal: deal,
    reportCard: reportCard,
    insights: await repo.reviewInsights(id),
    offers: offers.where((o) => storeIds.contains(o.merchantId) && !o.validUntil.isBefore(now)).toList(),
    alternatives: alternatives,
    verdict: buildVerdict(
      variant: variant,
      best: best,
      deal: deal,
      reportCard: reportCard,
      alternatives: alternatives,
      merchants: repo.merchants,
    ),
  );
});
