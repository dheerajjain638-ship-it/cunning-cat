import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// Product Battle: two products side by side with a winner per row.
class BattleScreen extends ConsumerWidget {
  const BattleScreen({super.key, required this.leftId, required this.rightId});
  final String leftId;
  final String rightId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(productProvider(leftId));
    final b = ref.watch(productProvider(rightId));
    return Scaffold(
      appBar: AppBar(title: const Text('Product Battle')),
      body: (a.valueOrNull == null || b.valueOrNull == null)
          ? Center(
              child: a.hasError || b.hasError ? const Text('Could not load products') : const CircularProgressIndicator())
          : _BattleBody(left: a.value!, right: b.value!),
    );
  }
}

class _BattleBody extends StatelessWidget {
  const _BattleBody({required this.left, required this.right});
  final ProductView left;
  final ProductView right;

  @override
  Widget build(BuildContext context) {
    final lp = left.best?.yourBest;
    final rp = right.best?.yourBest;
    final rows = <_Row>[
      _Row('Your best price', lp == null ? '—' : rupees(lp), rp == null ? '—' : rupees(rp),
          lp == null || rp == null ? 0 : (lp < rp ? -1 : (rp < lp ? 1 : 0))),
      _Row('Rating', '${left.variant.rating}★', '${right.variant.rating}★',
          left.variant.rating.compareTo(right.variant.rating) * -1),
      _Row('Ratings count', compact(left.variant.reviewCount), compact(right.variant.reviewCount),
          left.variant.reviewCount.compareTo(right.variant.reviewCount) * -1),
    ];
    final aspects = <String>{
      for (final d in left.reportCard) d.name,
      for (final d in right.reportCard) d.name,
    };
    for (final name in aspects) {
      double? s(ProductView v) {
        for (final d in v.reportCard) {
          if (d.name == name) return d.score;
        }
        return null;
      }

      final ls = s(left), rs = s(right);
      rows.add(_Row(name, ls?.toStringAsFixed(1) ?? '—', rs?.toStringAsFixed(1) ?? '—',
          ls == null || rs == null ? 0 : (ls > rs ? -1 : (rs > ls ? 1 : 0))));
    }
    final specKeys = <String>{...left.variant.keySpecs.keys, ...right.variant.keySpecs.keys};
    for (final k in specKeys) {
      rows.add(_Row(k, left.variant.keySpecs[k] ?? '—', right.variant.keySpecs[k] ?? '—', 0));
    }
    final leftWins = rows.where((r) => r.winner < 0).length;
    final rightWins = rows.where((r) => r.winner > 0).length;
    final pick = leftWins == rightWins
        ? null
        : (leftWins > rightWins ? left.variant.familyName : right.variant.familyName);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: _head(context, left)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: CircleAvatar(
                  backgroundColor: BrandColors.amber,
                  child: Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: BrandColors.indigo)),
                ),
              ),
              Expanded(child: _head(context, right)),
            ],
          ),
        ),
        OutlinedCard(
          gradient: BrandColors.heroGradient,
          borderColor: Colors.transparent,
          child: Row(
            children: [
              const CatLogo(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pick == null
                      ? 'It is a tie on our checks. Pick on price or the feature you care about most.'
                      : 'Cunning Cat pick: $pick wins ${leftWins > rightWins ? leftWins : rightWins}–'
                          '${leftWins > rightWins ? rightWins : leftWins} on our checks.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        OutlinedCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final r in rows)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4))),
                  ),
                  child: Column(
                    children: [
                      Text(r.label, style: const TextStyle(fontSize: 12, color: BrandColors.slate, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: _cell(r.left, r.winner < 0)),
                          Expanded(child: _cell(r.right, r.winner > 0)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _head(BuildContext context, ProductView v) => GestureDetector(
        onTap: () => context.push('/product/${v.variant.id}'),
        child: Column(
          children: [
            ProductImage(variant: v.variant, size: 110),
            const SizedBox(height: 8),
            Text(v.variant.familyName,
                textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _cell(String text, bool win) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (win) const Icon(Icons.emoji_events_rounded, size: 16, color: BrandColors.amber),
          if (win) const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: win ? FontWeight.w900 : FontWeight.w500, color: win ? BrandColors.emerald : null)),
          ),
        ],
      );
}

class _Row {
  final String label;
  final String left;
  final String right;

  /// -1 left wins, 1 right wins, 0 tie / not comparable.
  final int winner;
  _Row(this.label, this.left, this.right, this.winner);
}
