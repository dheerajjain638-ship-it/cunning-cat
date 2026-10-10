import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/effective_price.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class ProductScreen extends ConsumerWidget {
  const ProductScreen({super.key, required this.variantId});
  final String variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(productProvider(variantId));
    final wishlisted = ref.watch(wishlistProvider).any((w) => w.variantId == variantId);
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: wishlisted ? 'Remove from wishlist' : 'Add to wishlist',
            icon: Icon(wishlisted ? Icons.favorite : Icons.favorite_border),
            onPressed: () => ref.read(wishlistProvider.notifier).toggle(variantId),
          ),
        ],
      ),
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
    final merchantName = {for (final m in repo.merchants) m.id: m.name};
    final textTheme = Theme.of(context).textTheme;
    final best = view.best;
    final v = view.variant;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const DemoBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(v.familyName, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
          child: Text(v.variantLabel, style: textTheme.bodyMedium),
        ),
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

        // ---- Verdict card ----
        if (best != null)
          _BestPriceCard(best: best, merchant: merchantName[best.listing.merchantId] ?? '', deal: view.deal)
        else
          const OutlinedCard(child: Text('No fresh, in-stock price right now. Add it to your wishlist for an alert.')),

        // ---- Compare stores ----
        const SectionTitle('Compare stores'),
        for (final b in view.ranked)
          _StoreTile(
            breakdown: b,
            merchant: merchantName[b.listing.merchantId] ?? b.listing.merchantId,
            isBest: identical(b, best),
            anomaly: view.isPriceAnomaly(b),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextButton.icon(
            onPressed: () => context.go('/wallet'),
            icon: const Icon(Icons.credit_card),
            label: const Text('Update my cards to recalculate'),
          ),
        ),

        // ---- Price history ----
        if (view.history.isNotEmpty) ...[
          const SectionTitle('Price history (120 days)'),
          OutlinedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Sparkline(points: view.history),
                const SizedBox(height: 8),
                if (view.deal != null) Text(view.deal!.explanation),
              ],
            ),
          ),
        ],

        // ---- Report card ----
        if (view.reportCard.isNotEmpty) ...[
          const SectionTitle('Report card'),
          OutlinedCard(
            child: Column(children: [for (final d in view.reportCard) ScoreRow(dimension: d)]),
          ),
        ],

        // ---- Owners and experts say ----
        if (view.insights.isNotEmpty) ...[
          const SectionTitle('What owners and experts say'),
          OutlinedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final i in view.insights)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(
                      i.positive ? Icons.thumb_up_alt_outlined : Icons.thumb_down_alt_outlined,
                      color: i.positive ? BrandColors.emerald : BrandColors.coral,
                    ),
                    title: Text(i.text),
                    subtitle: Text(i.source),
                  ),
              ],
            ),
          ),
        ],

        // ---- EMI ----
        if (best != null) ...[
          const SectionTitle('Thinking of EMI?'),
          _EmiCard(price: best.yourBest),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Text(
            'How we rank: lowest price you can actually pay, using only fresh prices. '
            'We may earn a commission when you buy through our links. Commission never affects ranking.',
            style: textTheme.bodySmall,
          ),
        ),
      ],
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
    final textTheme = Theme.of(context).textTheme;
    return OutlinedCard(
      color: BrandColors.indigo,
      borderColor: BrandColors.indigo,
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YOUR BEST PRICE', style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: BrandColors.amber, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(rupees(best.yourBest),
                style: textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            Text('on $merchant · price checked ${ageLabel(best.listing.observedAt)}'),
            if (best.instantSaving > 0)
              Text('You save ${rupees(best.instantSaving)} with offers you can use',
                  style: const TextStyle(color: BrandColors.amber, fontWeight: FontWeight.w600)),
            if (best.deferredCashback > 0) Text('+ ${rupees(best.deferredCashback)} cashback later'),
            if (deal != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_dealLabel(deal!.label), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (deal!.mrpLooksInflated)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Heads up: the big "% off" is measured against MRP, not the usual selling price.'),
                ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: BrandColors.amber, foregroundColor: BrandColors.indigo),
                onPressed: () => _openStore(context, best.listing.outboundUrl),
                child: Text('Buy on $merchant'),
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

String _dealLabel(DealLabel l) => switch (l) {
      DealLabel.lowestIn90Days => 'Lowest in 90 days',
      DealLabel.goodDeal => 'Good deal',
      DealLabel.typicalPrice => 'Typical price',
      DealLabel.aboveUsual => 'Above usual price: consider waiting',
      DealLabel.notEnoughHistory => 'New: not enough price history',
    };

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
      borderColor: isBest ? BrandColors.emerald : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(merchant, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
              if (isBest)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Text('BEST', style: TextStyle(color: BrandColors.emerald, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              Text(rupees(b.yourBest), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          if (b.instantSaving > 0)
            Text('List price ${rupees(b.base)} · you save ${rupees(b.instantSaving)}', style: small),
          Text('Sold by ${l.sellerName}${l.authorisedSeller ? '' : ' (not an authorised seller)'} · checked ${ageLabel(l.observedAt)}',
              style: small?.copyWith(color: scheme.onSurfaceVariant)),
          if (!l.inStock) _flag('Out of stock', BrandColors.coral),
          if (b.stale) _flag('Price may have changed: last checked over 24 h ago', BrandColors.coral),
          if (anomaly) _flag('Price far below authorised sellers. Check seller and warranty before buying.', BrandColors.coral),
          for (final a in b.yourOffers) _offerLine(Icons.check_circle, BrandColors.emerald, '${a.offer.title}: -${rupees(a.saving)}'),
          for (final a in b.cashbackOffers) _offerLine(Icons.schedule, BrandColors.emerald, '${a.offer.title}: ${rupees(a.saving)} back later'),
          for (final c in b.conditional.take(3))
            _offerLine(Icons.lock_outline, BrandColors.coral, 'Could save ${rupees(c.extraSaving)} more: ${c.offer.title}. ${c.reason}.'),
        ],
      ),
    );
  }

  Widget _flag(String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
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
    // Typical demo assumptions: 15% p.a. bank rate, ₹199 processing fee.
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
          Text('"No-cost" EMI: ${rupees(r.monthly)} a month',
              style: const TextStyle(fontWeight: FontWeight.w700)),
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
