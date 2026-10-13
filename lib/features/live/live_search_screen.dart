import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/live_models.dart';
import '../../state/live_providers.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';

enum LiveSort { relevance, priceLow, priceHigh, rating, discount }

/// Real-time results from Google Shopping India: photos, prices, stores, ratings.
class LiveSearchScreen extends ConsumerStatefulWidget {
  const LiveSearchScreen({super.key, required this.query});
  final String query;

  @override
  ConsumerState<LiveSearchScreen> createState() => _LiveSearchScreenState();
}

class _LiveSearchScreenState extends ConsumerState<LiveSearchScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.query);
  late String _query = widget.query.trim();
  LiveSort _sort = LiveSort.relevance;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(t);
    setState(() => _query = t);
  }

  List<LiveProduct> _sorted(List<LiveProduct> items) {
    final list = [...items];
    switch (_sort) {
      case LiveSort.relevance:
        break;
      case LiveSort.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case LiveSort.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case LiveSort.rating:
        list.sort((a, b) => ((b.rating ?? 0) * 1000 + (b.reviews ?? 0).clamp(0, 999))
            .compareTo((a.rating ?? 0) * 1000 + (a.reviews ?? 0).clamp(0, 999)));
      case LiveSort.discount:
        list.sort((a, b) => (b.discountPct ?? 0).compareTo(a.discountPct ?? 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: _submit,
            decoration: const InputDecoration(
              hintText: 'Search live prices',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? const SizedBox.shrink() : _results(),
    );
  }

  Widget _results() {
    final async = ref.watch(liveSearchProvider(_query));
    return async.when(
      loading: () => const _SearchingView(),
      error: (e, _) => Center(
        child: ErrorRetry(message: '$e', onRetry: () => ref.invalidate(liveSearchProvider(_query))),
      ),
      data: (items) {
        if (items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(32),
            children: [
              const CatLogo(size: 96),
              const SizedBox(height: 12),
              Text('No store sells "$_query" right now',
                  textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              const Text('Try fewer words, a brand name or a model number.', textAlign: TextAlign.center),
            ],
          );
        }
        final list = _sorted(items);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    const LiveBadge(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${list.length} results across Indian stores',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final s in LiveSort.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(switch (s) {
                            LiveSort.relevance => 'Best match',
                            LiveSort.priceLow => 'Price: low to high',
                            LiveSort.priceHigh => 'Price: high to low',
                            LiveSort.rating => 'Top rated',
                            LiveSort.discount => 'Biggest discount',
                          }),
                          selected: _sort == s,
                          onSelected: (_) => setState(() => _sort = s),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 296,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => LiveProductCard(product: list[i]),
                  childCount: list.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Text(
                  'Prices are collected live from store listings. We may earn a commission when you buy, '
                  'at no extra cost to you.',
                  style: TextStyle(fontSize: 11, color: BrandColors.slate),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchingView extends StatelessWidget {
  const _SearchingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CatLogo(size: 84),
          SizedBox(height: 14),
          SizedBox(width: 160, child: LinearProgressIndicator()),
          SizedBox(height: 12),
          Text('Checking Amazon, Flipkart, Croma and more…', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
