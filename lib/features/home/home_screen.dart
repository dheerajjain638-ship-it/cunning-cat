import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/catalog.dart' show merchants;
import '../../data/models.dart';
import '../../domain/advisor.dart' show merchantLabel;
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/product_cards.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  String _live = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _live = text.trim());
    });
  }

  void _openResults(String q, {String? categoryId}) {
    final query = q.trim();
    if (query.isEmpty && categoryId == null) return;
    ref.read(recentSearchesProvider.notifier).add(query);
    _focus.unfocus();
    context.push(Uri(path: '/search', queryParameters: {
      'q': query,
      if (categoryId != null) 'cat': categoryId,
    }).toString());
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (!text.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copy a product link from Amazon, Flipkart or another store first.')),
      );
      return;
    }
    _openResults(text);
  }

  @override
  Widget build(BuildContext context) {
    final searching = _live.isNotEmpty;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _hero(context)),
          if (searching)
            SliverToBoxAdapter(child: _LiveResults(query: _live, onSeeAll: () => _openResults(_live)))
          else ...[
            SliverToBoxAdapter(child: _categories(context)),
            const SliverToBoxAdapter(child: _DealsCarousel()),
            const SliverToBoxAdapter(child: _BankOffersStrip()),
            const SliverToBoxAdapter(child: _HowItWorks()),
            const SliverToBoxAdapter(child: _PopularList()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ],
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final recent = ref.watch(recentSearchesProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: BrandColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CatLogo(size: 44),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cunning Cat',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                    Text('Know more. Pay less. Buy better.',
                        style: TextStyle(color: BrandColors.amber, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const DemoBadge(),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            focusNode: _focus,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (q) => _openResults(q),
            decoration: InputDecoration(
              hintText: 'Search any product, brand or paste a link',
              prefixIcon: const Icon(Icons.search, color: BrandColors.indigoMid),
              suffixIcon: _controller.text.isEmpty
                  ? IconButton(
                      tooltip: 'Paste product link',
                      icon: const Icon(Icons.content_paste_rounded, color: BrandColors.indigoMid),
                      onPressed: _pasteLink,
                    )
                  : IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _live = '');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in recent.isEmpty ? const ['iPhone 16', 'Best phone under 30000', 'OLED TV', 'Earbuds'] : recent)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Icon(recent.isEmpty ? Icons.auto_awesome : Icons.history, size: 16, color: BrandColors.amber),
                      label: Text(s, style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      onPressed: () => _openResults(s),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories(BuildContext context) {
    final cats = ref.watch(repositoryProvider).categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Shop by category', icon: Icons.grid_view_rounded),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) {
              final c = cats[i];
              return GestureDetector(
                onTap: () => _openResults('', categoryId: c.id),
                child: Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [c.color, Color.lerp(c.color, BrandColors.indigo, 0.45)!]),
                        boxShadow: [BoxShadow(color: c.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Icon(c.icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 6),
                    Text(c.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Results that update as the user types.
class _LiveResults extends ConsumerWidget {
  const _LiveResults({required this.query, required this.onSeeAll});
  final String query;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider((query: query, categoryId: null)));
    final summaries = ref.watch(catalogSummaryProvider).valueOrNull ?? const {};
    return results.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: LinearProgressIndicator()),
      error: (e, _) => Padding(padding: const EdgeInsets.all(24), child: Text('Search failed: $e')),
      data: (items) {
        if (items.isEmpty) return _NoResults(query: query);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('${items.length} matches', icon: Icons.bolt,
                trailing: TextButton(onPressed: onSeeAll, child: const Text('See all'))),
            for (final v in items.take(6))
              if (summaries[v.id] != null) ProductListCard(summary: summaries[v.id]!),
          ],
        );
      },
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const CatLogo(size: 96),
          const SizedBox(height: 12),
          Text('No match for "$query" yet', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'The demo catalog has 45 products in 10 categories. Try a brand (Samsung, Apple, LG), '
            'a category (phone, TV, AC, fridge, earbuds) or paste a product link.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DealsCarousel extends ConsumerWidget {
  const _DealsCarousel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deals = ref.watch(dealsProvider).valueOrNull ?? const [];
    if (deals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Smartest deals today', icon: Icons.local_fire_department_rounded),
        SizedBox(
          height: 290,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 12),
            children: [for (final d in deals) DealCard(summary: d)],
          ),
        ),
      ],
    );
  }
}

class _BankOffersStrip extends ConsumerWidget {
  const _BankOffersStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    return FutureBuilder<List<Offer>>(
      future: repo.offers(),
      builder: (context, snap) {
        final now = DateTime.now();
        final offers = (snap.data ?? const <Offer>[])
            .where((o) => o.type == OfferType.bankCard && !o.validUntil.isBefore(now))
            .take(6)
            .toList();
        if (offers.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('Top bank offers this week', icon: Icons.credit_card,
                trailing: TextButton(onPressed: () => context.go('/wallet'), child: const Text('My cards'))),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final o = offers[i];
                  final m = merchants.firstWhere((x) => x.id == o.merchantId);
                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(colors: [m.color, Color.lerp(m.color, BrandColors.indigo, 0.6)!]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(merchantLabel(o.merchantId, merchants).toUpperCase(),
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Text(o.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text(o.minCart > 0 ? 'Min. order ${rupees(o.minCart)}' : 'No minimum',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) => Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: BrandColors.amberSoft,
                child: Icon(icon, color: BrandColors.indigo),
              ),
              const SizedBox(height: 6),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
    return OutlinedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Every product gets a full check', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              step(Icons.compare_arrows, 'All stores', 'Prices side by side'),
              step(Icons.credit_score, 'Your cards', 'Real price after offers'),
              step(Icons.reviews, 'Reviews', 'Pros, cons, scores'),
              step(Icons.schedule, 'Timing', 'Buy now or wait'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PopularList extends ConsumerWidget {
  const _PopularList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaries = ref.watch(catalogSummaryProvider);
    return summaries.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text('$e'),
      data: (all) {
        final list = all.values.toList()..sort((a, b) => b.variant.reviewCount.compareTo(a.variant.reviewCount));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle('Popular right now', icon: Icons.trending_up,
                trailing: TextButton(
                  onPressed: () => context.push('/search?q='),
                  child: Text('All ${all.length}'),
                )),
            for (final s in list.take(10)) ProductListCard(summary: s),
          ],
        );
      },
    );
  }
}
