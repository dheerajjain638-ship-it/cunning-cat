import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/live_models.dart';
import '../../data/models.dart' show PricePoint;
import '../../state/live_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';

/// One product across every store: photos, AI verdict, price table, reviews, specs.
class LiveProductScreen extends ConsumerWidget {
  const LiveProductScreen({super.key, required this.product});
  final LiveProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = product.token!;
    final detail = ref.watch(liveDetailProvider(token));
    return Scaffold(
      body: detail.when(
        loading: () => CustomScrollView(slivers: [
          _gallery(context, [if (product.image != null) product.image!]),
          SliverToBoxAdapter(child: _titleBlock(context, product.title, product.rating, product.reviews)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                LinearProgressIndicator(),
                SizedBox(height: 10),
                Text('Comparing every store for you…'),
              ]),
            ),
          ),
        ]),
        error: (e, _) => CustomScrollView(slivers: [
          _gallery(context, [if (product.image != null) product.image!]),
          SliverToBoxAdapter(child: ErrorRetry(message: '$e', onRetry: () => ref.invalidate(liveDetailProvider(token)))),
          if (product.link != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton(
                  onPressed: () => openStoreLink(context, product.link),
                  child: Text('Open on ${product.store ?? 'store'} (${rupees(product.price)})'),
                ),
              ),
            ),
        ]),
        data: (d) {
          final images = d.images.isNotEmpty ? d.images : [if (product.image != null) product.image!];
          return CustomScrollView(
            slivers: [
              _gallery(context, images),
              SliverToBoxAdapter(
                child: _titleBlock(context, d.title.isEmpty ? product.title : d.title, d.rating ?? product.rating,
                    d.reviews ?? product.reviews),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _BestPriceHero(detail: d, fallback: product),
                  _AiVerdictCard(token: token),
                  if (d.history.length >= 2) _HistoryCard(history: d.history),
                  if (d.stores.isNotEmpty) _StoresCard(stores: d.stores),
                  if (d.insights.isNotEmpty) _BuyersSayCard(insights: d.insights),
                  if (d.ratings.isNotEmpty || d.userReviews.isNotEmpty) _ReviewsCard(detail: d),
                  if (d.features.isNotEmpty) _SpecsCard(features: d.features),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
                    child: Text(
                      'Prices and reviews are gathered live from public store listings and can change at checkout. '
                      'We may earn a commission when you buy through our links. It never changes your price.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: BrandColors.slate),
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _gallery(BuildContext context, List<String> images) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 320,
      backgroundColor: Colors.white,
      foregroundColor: BrandColors.indigo,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 48, 24, 16),
          child: images.isEmpty ? const NetImage(null, iconSize: 72) : _Gallery(images: images),
        ),
      ),
    );
  }

  Widget _titleBlock(BuildContext context, String title, double? rating, int? reviews) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
          if (rating != null) ...[
            const SizedBox(height: 6),
            RatingStars(rating: rating, count: reviews, size: 16),
          ],
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});
  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => NetImage(widget.images[i], iconSize: 72),
          ),
        ),
        if (widget.images.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? BrandColors.indigoMid : BrandColors.slate.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _BestPriceHero extends StatelessWidget {
  const _BestPriceHero({required this.detail, required this.fallback});
  final LiveDetail detail;
  final LiveProduct fallback;

  @override
  Widget build(BuildContext context) {
    final best = detail.cheapest;
    final price = best?.price ?? fallback.price;
    final store = best?.name ?? fallback.store ?? 'the store';
    final link = best?.link ?? fallback.link;
    final count = detail.stores.length;
    return OutlinedCard(
      gradient: BrandColors.heroGradient,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BEST PRICE RIGHT NOW',
              style: TextStyle(color: BrandColors.amber, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(rupees(price), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          Text(count > 1 ? 'at $store · lowest of $count stores' : 'at $store',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          if (detail.spread >= 1) ...[
            const SizedBox(height: 10),
            Pill('You save ${rupees(detail.spread)} vs the costliest store',
                color: BrandColors.indigo, background: BrandColors.amber, icon: Icons.savings_rounded),
          ],
          if (best != null && best.offers.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final o in best.offers.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 14, color: BrandColors.amber),
                    const SizedBox(width: 6),
                    Expanded(child: Text(o, style: const TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: BrandColors.amber, foregroundColor: BrandColors.indigo),
              onPressed: link == null ? null : () => openStoreLink(context, link),
              icon: const Icon(Icons.shopping_bag_rounded),
              label: Text('Buy on $store', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiVerdictCard extends ConsumerWidget {
  const _AiVerdictCard({required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ai = ref.watch(aiInsightProvider(token));
    return ai.when(
      loading: () => const OutlinedCard(
        child: Row(
          children: [
            CatLogo(size: 36),
            SizedBox(width: 12),
            Expanded(child: Text('The Cat is reading reviews and comparing prices…')),
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (a) {
        final (label, color, soft, icon) = switch (a.verdict) {
          AiVerdict.buy => ('Good buy', BrandColors.emerald, BrandColors.emeraldSoft, Icons.verified_rounded),
          AiVerdict.wait => ('Wait for a better price', BrandColors.amber, BrandColors.amberSoft, Icons.schedule_rounded),
          AiVerdict.considerAlternatives =>
            ('Look at alternatives', BrandColors.coral, BrandColors.coralSoft, Icons.swap_horiz_rounded),
          AiVerdict.unknown => ('Mixed picture', BrandColors.slate, const Color(0xFFF1F5F9), Icons.help_outline),
        };
        return OutlinedCard(
          borderColor: color.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CatLogo(size: 30),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("CUNNING CAT'S AI VERDICT",
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
                  ),
                  Pill(label, color: color, background: soft, icon: icon),
                ],
              ),
              const SizedBox(height: 10),
              if (a.headline.isNotEmpty)
                Text(a.headline, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              if (a.summary.isNotEmpty) ...[const SizedBox(height: 4), Text(a.summary)],
              const SizedBox(height: 10),
              for (final p in a.pros) _bullet(Icons.check_circle_rounded, BrandColors.emerald, p),
              for (final c in a.cons) _bullet(Icons.remove_circle_rounded, BrandColors.coral, c),
              if (a.bestFor != null) _labelled('Best for', a.bestFor!),
              if (a.skipIf != null) _labelled('Skip if', a.skipIf!),
              if (a.priceAdvice != null) _labelled('Price', a.priceAdvice!),
              const SizedBox(height: 6),
              const Text('AI summary of store listings and buyer reviews. Double-check key specs before buying.',
                  style: TextStyle(fontSize: 11, color: BrandColors.slate)),
            ],
          ),
        );
      },
    );
  }

  Widget _bullet(IconData icon, Color color, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Expanded(child: Text(text))],
        ),
      );

  Widget _labelled(String label, String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: text),
        ])),
      );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.history});
  final List<LiveHistoryPoint> history;

  @override
  Widget build(BuildContext context) {
    final prices = history.map((h) => h.price).toList();
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    final now = prices.last;
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRICE HISTORY (TRACKED BY CUNNING CAT)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          Sparkline(points: [for (final h in history) PricePoint(h.date, h.price.round())]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _stat('Lowest', rupees(low))),
              Expanded(child: _stat('Now', rupees(now))),
              Expanded(child: _stat('Highest', rupees(high))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: BrandColors.slate)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}

class _StoresCard extends StatelessWidget {
  const _StoresCard({required this.stores});
  final List<LiveStore> stores;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return OutlinedCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMPARE ${stores.length} STORES',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          for (var i = 0; i < stores.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            InkWell(
              onTap: stores[i].link == null ? null : () => openStoreLink(context, stores[i].link),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: NetImage(stores[i].logo, iconSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(stores[i].name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w800)),
                              ),
                              if (i == 0) ...[
                                const SizedBox(width: 6),
                                const Pill('Lowest',
                                    color: BrandColors.emerald, background: BrandColors.emeraldSoft),
                              ],
                            ],
                          ),
                          for (final o in stores[i].offers.take(2))
                            Text(o, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: muted)),
                          if (stores[i].emi != null)
                            Text(stores[i].emi!, style: TextStyle(fontSize: 11, color: muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rupees(stores[i].price), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                        if (stores[i].oldPrice != null && stores[i].oldPrice! > stores[i].price)
                          Text(rupees(stores[i].oldPrice!),
                              style: TextStyle(fontSize: 11, color: muted, decoration: TextDecoration.lineThrough)),
                        if (i > 0)
                          Text('+${rupees(stores[i].price - stores[0].price)}',
                              style: const TextStyle(fontSize: 11, color: BrandColors.coral, fontWeight: FontWeight.w700)),
                        const Icon(Icons.open_in_new_rounded, size: 14, color: BrandColors.indigoMid),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BuyersSayCard extends StatelessWidget {
  const _BuyersSayCard({required this.insights});
  final List<LiveInsight> insights;

  @override
  Widget build(BuildContext context) {
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('WHAT BUYERS SAY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          for (final x in insights.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (x.point.isNotEmpty) Text(x.point, style: const TextStyle(fontWeight: FontWeight.w800)),
                  if (x.snippet.isNotEmpty)
                    Text(x.snippet, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  if (x.pros.isNotEmpty || x.cons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final p in x.pros.take(3))
                            Pill(p, color: BrandColors.emerald, background: BrandColors.emeraldSoft, icon: Icons.add),
                          for (final c in x.cons.take(2))
                            Pill(c, color: BrandColors.coral, background: BrandColors.coralSoft, icon: Icons.remove),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.detail});
  final LiveDetail detail;

  @override
  Widget build(BuildContext context) {
    final total = detail.ratings.values.fold<int>(0, (a, b) => a + b);
    final scheme = Theme.of(context).colorScheme;
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RATINGS & REVIEWS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          if (total > 0)
            for (var s = 5; s >= 1; s--)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(width: 24, child: Text('$s★', style: const TextStyle(fontWeight: FontWeight.w700))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (detail.ratings[s] ?? 0) / total,
                          minHeight: 8,
                          color: s >= 4 ? BrandColors.emerald : (s == 3 ? BrandColors.amber : BrandColors.coral),
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(compact(detail.ratings[s] ?? 0),
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
          for (final r in detail.userReviews.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (r.rating != null) RatingStars(rating: r.rating!, size: 12),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text([r.user, r.source].whereType<String>().join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  if (r.title.isNotEmpty) Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (r.text.isNotEmpty)
                    Text(r.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.features});
  final List<LiveFeature> features;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KEY SPECS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: Text(f.name, style: TextStyle(color: muted, fontSize: 13))),
                  Expanded(child: Text(f.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
