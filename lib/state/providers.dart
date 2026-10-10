import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/repository.dart';
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

final searchProvider = FutureProvider.autoDispose.family<List<Variant>, String>(
  (ref, query) => ref.watch(repositoryProvider).search(query),
);

/// Everything the product screen needs, computed by the deterministic engine.
class ProductView {
  final Variant variant;
  final List<PriceBreakdown> ranked;
  final List<PricePoint> history;
  final DealVerdict? deal;
  final List<ReportDimension> reportCard;
  final List<ReviewInsight> insights;
  const ProductView({
    required this.variant,
    required this.ranked,
    required this.history,
    required this.deal,
    required this.reportCard,
    required this.insights,
  });

  PriceBreakdown? get best {
    for (final b in ranked) {
      if (b.comparable) return b;
    }
    return null;
  }

  /// Authorised listing priced far below others: possible counterfeit/scam.
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
  final breakdowns = [
    for (final l in listings)
      computeEffectivePrice(
        listing: l,
        offers: offers,
        ownedInstrumentIds: owned,
        now: now,
        instrumentLabels: labels,
      ),
  ];
  final ranked = rankBreakdowns(breakdowns);
  final history = await repo.history(id);
  final reference = ranked.where((b) => b.comparable && b.listing.authorisedSeller).toList();
  final deal = reference.isEmpty
      ? null
      : assessDeal(
          currentPrice: reference.first.listing.price,
          mrp: reference.first.listing.mrp,
          history: history,
          now: now,
        );
  return ProductView(
    variant: variant,
    ranked: ranked,
    history: history,
    deal: deal,
    reportCard: await repo.reportCard(id),
    insights: await repo.reviewInsights(id),
  );
});
