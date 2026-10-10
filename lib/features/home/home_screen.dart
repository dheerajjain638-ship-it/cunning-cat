import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) {
    if (q.trim().isEmpty) return;
    context.push(Uri(path: '/search', queryParameters: {'q': q.trim()}).toString());
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
    _search(text);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(repositoryProvider);
    final owned = ref.watch(walletProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            const DemoBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.pets, color: BrandColors.amber, size: 28),
                  const SizedBox(width: 8),
                  Text('Cunning Cat', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Know more. Pay less. Buy better.', style: textTheme.bodyMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: const InputDecoration(
                  hintText: 'Search a product or paste a link',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.link, size: 18),
                    label: const Text('Paste product link'),
                    onPressed: _pasteLink,
                  ),
                  for (final c in Category.values)
                    ActionChip(label: Text(c.label), onPressed: () => _search(c.label)),
                ],
              ),
            ),
            if (owned.length <= 1)
              OutlinedCard(
                color: BrandColors.indigo.withValues(alpha: 0.06),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, color: BrandColors.indigo),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Add the cards you own to see your real price after bank offers. No card numbers needed.'),
                    ),
                    TextButton(onPressed: () => context.go('/wallet'), child: const Text('Add')),
                  ],
                ),
              ),
            const SectionTitle('Popular right now'),
            for (final v in repo.trending)
              ListTile(
                leading: CircleAvatar(child: Icon(_iconFor(v.category))),
                title: Text(v.familyName),
                subtitle: Text(v.variantLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/product/${v.id}'),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(Category c) => switch (c) {
      Category.mobiles => Icons.smartphone,
      Category.laptops => Icons.laptop_mac,
      Category.televisions => Icons.tv,
    };

IconData iconForCategory(Category c) => _iconFor(c);
