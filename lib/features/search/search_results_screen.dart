import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/repository.dart' show queryFromLink;
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/product_cards.dart';

enum SortBy { relevance, priceLow, priceHigh, rating, bestDeal }

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query, this.categoryId});
  final String query;
  final String? categoryId;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _controller;
  late String _query;
  String? _category;
  SortBy _sort = SortBy.relevance;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = widget.query;
    _category = widget.categoryId;
    final shown = _query.startsWith('http') ? (queryFromLink(_query) ?? '') : _query;
    _controller = TextEditingController(text: shown);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String t) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _query = t);
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final results = ref.watch(searchProvider((query: _query, categoryId: _category)));
    final summaries = ref.watch(catalogSummaryProvider).valueOrNull ?? const {};
    final fromLink = widget.query.startsWith('http');

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextField(
            controller: _controller,
            autofocus: widget.query.isEmpty && widget.categoryId == null,
            onChanged: _onChanged,
            onSubmitted: (q) {
              ref.read(recentSearchesProvider.notifier).add(q);
              setState(() => _query = q);
            },
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search products',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (fromLink)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: BrandColors.amberSoft, borderRadius: BorderRadius.circular(12)),
              child: const Text('We read the product name from your link and matched it to our catalog.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in repo.categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      avatar: Icon(c.icon, size: 16, color: c.color),
                      label: Text(c.label),
                      selected: _category == c.id,
                      onSelected: (_) => setState(() => _category = _category == c.id ? null : c.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
              data: (items) {
                final list = [for (final v in items) if (summaries[v.id] != null) summaries[v.id]!];
                switch (_sort) {
                  case SortBy.relevance:
                    break;
                  case SortBy.priceLow:
                    list.sort((a, b) => (a.best?.yourBest ?? 1 << 30).compareTo(b.best?.yourBest ?? 1 << 30));
                  case SortBy.priceHigh:
                    list.sort((a, b) => (b.best?.yourBest ?? 0).compareTo(a.best?.yourBest ?? 0));
                  case SortBy.rating:
                    list.sort((a, b) => b.variant.rating.compareTo(a.variant.rating));
                  case SortBy.bestDeal:
                    list.sort((a, b) => b.belowUsual.compareTo(a.belowUsual));
                }
                if (list.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(32),
                    children: const [
                      CatLogo(size: 96),
                      SizedBox(height: 12),
                      Text('No match in the demo catalog yet',
                          textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      SizedBox(height: 6),
                      Text('Try a brand (Samsung, Apple, LG), a category (phone, TV, AC, fridge, earbuds), or clear the filter.',
                          textAlign: TextAlign.center),
                    ],
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('${list.length} products · prices include your card offers',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          PopupMenuButton<SortBy>(
                            initialValue: _sort,
                            onSelected: (s) => setState(() => _sort = s),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: SortBy.relevance, child: Text('Most relevant')),
                              PopupMenuItem(value: SortBy.priceLow, child: Text('Price: low to high')),
                              PopupMenuItem(value: SortBy.priceHigh, child: Text('Price: high to low')),
                              PopupMenuItem(value: SortBy.rating, child: Text('Highest rated')),
                              PopupMenuItem(value: SortBy.bestDeal, child: Text('Best deal vs usual price')),
                            ],
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Row(children: [Icon(Icons.sort, size: 18), SizedBox(width: 4), Text('Sort')]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final s in list) ProductListCard(summary: s),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
