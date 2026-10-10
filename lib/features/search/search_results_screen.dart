import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../home/home_screen.dart';

class SearchResultsScreen extends ConsumerWidget {
  const SearchResultsScreen({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchProvider(query));
    final isLink = query.startsWith('http');
    return Scaffold(
      appBar: AppBar(title: Text(isLink ? 'Product from your link' : 'Results for "$query"')),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Something went wrong: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No matching products yet. Try a brand and model, e.g. "Galaxy S25".'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final v = items[i];
              return ListTile(
                leading: CircleAvatar(child: Icon(iconForCategory(v.category))),
                title: Text(v.familyName),
                subtitle: Text(v.variantLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/product/${v.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
