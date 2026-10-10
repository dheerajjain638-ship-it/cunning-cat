import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/advisor.dart';
import '../../domain/effective_price.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.variantId});
  final String variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(productProvider(variantId));
    return Scaffold(
      body: view.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (v) => v == null ? const Center(child: Text('Product not found')) : _ProductBody(view: v),
      ),
    );
  }
}

class _ProductBody extends ConsumerWidget {
  const _ProductBody({required this.view});
  final ProductView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final owned = ref.watch(walletProvider);
    final wishlisted = ref.watch(wishlistProvider).any((w) => w.variantId == view.variant.id);
    final merchantName = {for (final m in repo.merchants) m.id: m.name};
    final best = view.best;
    final v = view.variant;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 300,
          backgroundColor: BrandColors.indigo,
          foregroundColor: Colors.white,
          title: Text(v.familyName, style: const TextStyle(color: Colors.white, fontSize: 16)),
          actions: [
            IconButton(
              tooltip: wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
              icon: Icon(wishlisted ? Icons.favorite : Icons.favorite_border),
              onPressed: () {
                ref.read(wishlistProvider.notifier).toggle(v.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(wishlisted ? 'Removed from wishlist' : 'Added to wishlist. Set a target price there.')));
              },
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(gradient: BrandColors.heroGradient),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 60, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ProductImage(variant: v, size: 130, radius: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const DemoBadge(),
                          const SizedBox(height: 8),
                          Text(v.familyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          Text(v.variantLabel, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          RatingStars(rating: v.rating, count: v.reviewCount),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final e in v.keySpecs.entries)
                    Chip(label: Text('${e.key}: ${e.value}'), visualDensity: VisualDensity.compact),
                ],
              ),
            ),
            _VerdictCard(verdict: view.verdict),
            if (best != null)
              _BestPriceCard(best: best, merchant: merchantName[best.listing.merchantId] ?? '', deal: view.deal),
            const SectionTitle('Compare stores', icon: Icons.storefront_rounded),
            for (final b in view.ranked)
              _StoreTile(
                breakdown: b,
                merchant: merchantName[b.listing.merchantId] ?? b.listing.merchantId,
                isBest: identical(b, best),
                anomaly: view.isPriceAnomaly(b),
              ),
            SectionTitle('Bank & card offers', icon: Icons.credit_card,
                trailing: TextButton(onPressed: () => context.go('/wallet'), child: const Text('My cards'))),
            _OffersCard(offers: view.offers, owned: owned, merchantName: merchantName, instruments: repo.instruments),
            if (view.history.isNotEmpty) ...[
              const SectionTitle('Price history · buy now or wait?', icon: Icons.show_chart),
              _HistoryCard(view: view),
            ],
            const SectionTitle('Review intelligence', icon: Icons.reviews_rounded),
            _ReviewsCard(view: view),
            const SectionTitle('Report card', icon: Icons.fact_check_rounded),
            OutlinedCard(child: Column(children: [for (final d in view.reportCard) ScoreRow(dimension: d)])),
            if (view.alternatives.isNotEmpty) ...[
              const SectionTitle('Better options in your budget', icon: Icons.swap_horiz_rounded),
              for (final a in view.alternatives) _AlternativeTile(base: v, alt: a),
            ],
            if (best != null) ...[
              const SectionTitle('Thinking of EMI?', icon: Icons.calendar_month),
              _EmiCard(price: best.yourBest),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Text(
                'How we rank: the lowest price you can actually pay, using only fresh prices from authorised sellers. '
                'We may earn a commission when you buy through our links. Commission never affects ranking.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.verdict});
  final Verdict verdict;

  @override
  Widget build(BuildContext context) {
    final (color, soft, icon) = switch (verdict.kind) {
      VerdictKind.buyNow => (BrandColors.emerald, BrandColors.emeraldSoft, Icons.thumb_up_alt_rounded),
      VerdictKind.fairPrice => (BrandColors.indigoMid, const Color(0xFFE0E7FF), Icons.check_circle_rounded),
      VerdictKind.waitForDrop => (BrandColors.coral, BrandColors.coralSoft, Icons.hourglass_top_rounded),
      VerdictKind.considerAlternative => (BrandColors.amber, BrandColors.amberSoft, Icons.swap_horiz_rounded),
      VerdictKind.unavailable => (BrandColors.slate, const Color(0xFFF1F5F9), Icons.notifications_active),
    };
    return OutlinedCard(
      color: soft,
      borderColor: color.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CatLogo(size: 30),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("CUNNING CAT'S VERDICT",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: BrandColors.indigo)),
              ),
              Icon(icon, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(verdict.headline, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 8),
          for (final r in verdict.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r, style: const TextStyle(color: Color(0xFF1F2937)))),
                ],
              ),
            ),
          const Text('Built from the prices, offers and reviews on this page.',
              style: TextStyle(fontSize: 11, color: BrandColors.slate)),
        ],
      ),
    );
  }
}

class _BestPriceCard extends StatelessWidget {
  const _BestPriceCard({required this.best, required this.merchant, required this.deal});
  final PriceBreakdown best;
  final String merchant;
  final DealVerdict? deal;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      gradient: BrandColors.heroGradient,
      borderColor: Colors.transparent,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YOUR BEST PRICE',
                style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: BrandColors.amber, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(rupees(best.yourBest),
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(width: 10),
                if (best.base > best.yourBest)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(rupees(best.base),
                        style: const TextStyle(
                            color: Colors.white60, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            Text('on $merchant · checked ${ageLabel(best.listing.observedAt)}'),
            if (best.instantSaving > 0)
              Text('You save ${rupees(best.instantSaving)} with offers you can use',
                  style: const TextStyle(color: BrandColors.amber, fontWeight: FontWeight.w700)),
            if (best.deferredCashback > 0) Text('+ ${rupees(best.deferredCashback)} cashback later'),
            if (deal?.mrpLooksInflated ?? false)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Heads up: the big "% off" is measured against MRP, not the usual selling price.',
                    style: TextStyle(fontSize: 12)),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: BrandColors.amber, foregroundColor: BrandColors.indigo),
                onPressed: () => _openStore(context, best.listing.outboundUrl),
                icon: const Icon(Icons.shopping_bag_rounded),
                label: Text('Buy on $merchant'),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Affiliate link: we may earn a commission at no cost to you.', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

Future<void> _openStore(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the store.')));
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.breakdown, required this.merchant, required this.isBest, required this.anomaly});
  final PriceBreakdown breakdown;
  final String merchant;
  final bool isBest;
  final bool anomaly;

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final l = b.listing;
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall;
    return OutlinedCard(
      borderColor: isBest ? BrandColors.emerald : (anomaly ? BrandColors.coral : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(merchant, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
              if (isBest)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Pill('BEST', color: BrandColors.emerald, background: BrandColors.emeraldSoft),
                ),
              Text(rupees(b.yourBest), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          if (b.instantSaving > 0) Text('List price ${rupees(b.base)} · you save ${rupees(b.instantSaving)}', style: small),
          Text('Sold by ${l.sellerName}${l.authorisedSeller ? '' : ' (not an authorised seller)'} · checked ${ageLabel(l.observedAt)}',
              style: small?.copyWith(color: scheme.onSurfaceVariant)),
          if (!l.inStock) _flag('Out of stock', BrandColors.coral),
          if (b.stale) _flag('Price may have changed: last checked over 24 h ago', BrandColors.coral),
          if (anomaly) _flag('Price far below authorised sellers. Check seller and warranty before buying.', BrandColors.coral),
          for (final a in b.yourOffers) _offerLine(Icons.check_circle, BrandColors.emerald, '${a.offer.title}: -${rupees(a.saving)}'),
          for (final a in b.cashbackOffers)
            _offerLine(Icons.schedule, BrandColors.emerald, '${a.offer.title}: ${rupees(a.saving)} back later'),
          for (final c in b.conditional.take(2))
            _offerLine(Icons.lock_outline, BrandColors.coral, 'Could save ${rupees(c.extraSaving)} more: ${c.reason}.'),
        ],
      ),
    );
  }

  Widget _flag(String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _offerLine(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _OffersCard extends StatelessWidget {
  const _OffersCard({required this.offers, required this.owned, required this.merchantName, required this.instruments});
  final List<Offer> offers;
  final Set<String> owned;
  final Map<String, String> merchantName;
  final List<PaymentInstrument> instruments;

  @override
  Widget build(BuildContext context) {
    final usable = <Offer>[];
    final locked = <Offer>[];
    for (final o in offers) {
      final ok = !o.needsExtraCondition &&
          (o.requiredInstrumentIds.isEmpty || o.requiredInstrumentIds.any(owned.contains));
      (ok ? usable : locked).add(o);
    }
    String needs(Offer o) {
      if (o.needsExtraCondition) return o.conditionNote ?? 'Extra conditions';
      final names = [for (final i in instruments) if (o.requiredInstrumentIds.contains(i.id)) i.label];
      return 'Needs ${names.join(' or ')}';
    }

    Widget row(Offer o, bool can) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(can ? Icons.check_circle : Icons.lock_outline,
                  size: 18, color: can ? BrandColors.emerald : BrandColors.slate),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${merchantName[o.merchantId] ?? o.merchantId}: ${o.title}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      [
                        if (!can) needs(o),
                        if (o.minCart > 0) 'Min. order ${rupees(o.minCart)}',
                        if (o.cap != null) 'Max ${rupees(o.cap!)}',
                        if (!o.instant) 'Cashback arrives later',
                        'Checked ${ageLabel(o.verifiedAt)}',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: BrandColors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You can use (${usable.length})', style: const TextStyle(fontWeight: FontWeight.w900, color: BrandColors.emerald)),
          if (usable.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('None yet. Add the cards you own in My cards to unlock bank offers.'),
            ),
          for (final o in usable) row(o, true),
          const Divider(height: 24),
          Text('Unlock with another card or condition (${locked.length})',
              style: const TextStyle(fontWeight: FontWeight.w900, color: BrandColors.slate)),
          for (final o in locked) row(o, false),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.view});
  final ProductView view;

  @override
  Widget build(BuildContext context) {
    final d = view.deal;
    final prices = view.history.map((p) => p.lowestPrice).toList()..sort();
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Sparkline(points: view.history),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('Lowest', rupees(prices.first)),
              _stat('Usual', rupees(d?.medianPrice ?? prices[prices.length ~/ 2])),
              _stat('Highest', rupees(prices.last)),
            ],
          ),
          if (d != null) ...[
            const SizedBox(height: 10),
            Text(d.explanation, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          const SizedBox(height: 4),
          const Text('Big sale events (Diwali, Republic Day, Independence Day) usually bring the year\'s lowest prices.',
              style: TextStyle(fontSize: 12, color: BrandColors.slate)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: BrandColors.slate)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.view});
  final ProductView view;

  @override
  Widget build(BuildContext context) {
    final v = view.variant;
    final shares = starShares(v.rating);
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(v.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
                  RatingStars(rating: v.rating, size: 14),
                  const SizedBox(height: 4),
                  Text('${compact(v.reviewCount)} ratings', style: const TextStyle(fontSize: 12, color: BrandColors.slate)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(width: 14, child: Text('${5 - i}', style: const TextStyle(fontSize: 12))),
                            const Icon(Icons.star_rounded, size: 12, color: BrandColors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: shares[i],
                                  minHeight: 7,
                                  color: i < 2 ? BrandColors.emerald : (i == 2 ? BrandColors.amber : BrandColors.coral),
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                            SizedBox(
                                width: 36,
                                child: Text('${(shares[i] * 100).round()}%',
                                    textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          for (final i in view.insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(i.positive ? Icons.add_circle_rounded : Icons.remove_circle_rounded,
                      size: 18, color: i.positive ? BrandColors.emerald : BrandColors.coral),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(i.text, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(i.source, style: const TextStyle(fontSize: 11, color: BrandColors.slate)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Text('Summarised from ratings and reviews. Live sources and citations arrive with real data.',
              style: TextStyle(fontSize: 11, color: BrandColors.slate)),
        ],
      ),
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.base, required this.alt});
  final Variant base;
  final Alternative alt;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ProductImage(variant: alt.variant, size: 56, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/product/${alt.variant.id}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alt.variant.familyName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${rupees(alt.bestPrice)} · ${alt.why}', style: const TextStyle(fontSize: 12, color: BrandColors.slate)),
                ],
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () => context.push('/battle/${base.id}/${alt.variant.id}'),
            child: const Text('Compare'),
          ),
        ],
      ),
    );
  }
}

class _EmiCard extends StatefulWidget {
  const _EmiCard({required this.price});
  final int price;

  @override
  State<_EmiCard> createState() => _EmiCardState();
}

class _EmiCardState extends State<_EmiCard> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    // Demo assumptions: 15% p.a. bank rate, ₹199 processing fee.
    final r = trueEmiCost(
      principal: widget.price,
      annualRatePercent: 15,
      months: _months,
      processingFee: 199,
      noCost: true,
    );
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3 mo')),
              ButtonSegment(value: 6, label: Text('6 mo')),
              ButtonSegment(value: 9, label: Text('9 mo')),
              ButtonSegment(value: 12, label: Text('12 mo')),
            ],
            selected: {_months},
            onSelectionChanged: (s) => setState(() => _months = s.first),
          ),
          const SizedBox(height: 12),
          Text('"No-cost" EMI: ${rupees(r.monthly)} a month', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('Real extra cost about ${rupees(r.extraCost)}: GST on interest ${rupees(r.gstOnInterest)} '
              '+ processing fee ${rupees(r.processingFeeWithGst)}.'),
          const SizedBox(height: 4),
          Text('Assumes 15% p.a. bank rate and ₹199 fee. Your bank\'s terms may differ.',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
