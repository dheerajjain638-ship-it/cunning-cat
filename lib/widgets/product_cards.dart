import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/catalog.dart' show merchants;
import '../domain/advisor.dart' show merchantLabel;
import '../domain/effective_price.dart';
import '../state/providers.dart';
import 'common.dart';

Widget dealPill(ProductSummary s) {
  final d = s.deal;
  if (d == null) return const SizedBox.shrink();
  final pct = (s.belowUsual * 100).round();
  return switch (d.label) {
    DealLabel.lowestIn90Days =>
      const Pill('Lowest in 90 days', color: BrandColors.emerald, background: BrandColors.emeraldSoft, icon: Icons.trending_down),
    DealLabel.goodDeal =>
      Pill('$pct% below usual', color: BrandColors.emerald, background: BrandColors.emeraldSoft, icon: Icons.trending_down),
    DealLabel.aboveUsual =>
      const Pill('Above usual: wait', color: BrandColors.coral, background: BrandColors.coralSoft, icon: Icons.trending_up),
    _ => const Pill('Typical price', color: BrandColors.slate, background: Color(0xFFF1F5F9)),
  };
}

/// Full-width result row: image, name, rating, your best price, badges.
class ProductListCard extends StatelessWidget {
  const ProductListCard({super.key, required this.summary});
  final ProductSummary summary;

  @override
  Widget build(BuildContext context) {
    final v = summary.variant;
    final best = summary.best;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: () => context.push('/product/${v.id}'),
      child: OutlinedCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(variant: v, size: 84),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.familyName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(v.variantLabel, style: TextStyle(color: muted, fontSize: 12)),
                  const SizedBox(height: 4),
                  RatingStars(rating: v.rating, count: v.reviewCount, size: 13),
                  const SizedBox(height: 6),
                  if (best != null) ...[
                    Text(rupees(best.yourBest), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(
                      'Best at ${merchantLabel(best.listing.merchantId, merchants)} · ${summary.storeCount} stores compared',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ] else
                    Text('Out of stock everywhere', style: TextStyle(color: muted)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      dealPill(summary),
                      if (best != null && best.instantSaving > 0)
                        Pill('Offers save ${rupees(best.instantSaving)}',
                            color: BrandColors.indigo, background: BrandColors.amberSoft, icon: Icons.local_offer),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact card for horizontal carousels on the home screen.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.summary});
  final ProductSummary summary;

  @override
  Widget build(BuildContext context) {
    final v = summary.variant;
    final best = summary.best!;
    return GestureDetector(
      onTap: () => context.push('/product/${v.id}'),
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(variant: v, size: 148, radius: 14),
            const SizedBox(height: 8),
            Text(v.familyName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(rupees(best.yourBest), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            dealPill(summary),
          ],
        ),
      ),
    );
  }
}
