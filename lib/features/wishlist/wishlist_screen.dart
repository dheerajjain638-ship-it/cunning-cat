import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist & price alerts')),
      body: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  CatLogo(size: 110),
                  SizedBox(height: 12),
                  Text('Nothing tracked yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 6),
                  Text('Tap the heart on any product. Set a target price and Cunning Cat watches it for you.',
                      textAlign: TextAlign.center),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 24, top: 4),
              children: [for (final w in items) _WishTile(item: w)],
            ),
    );
  }
}

class _WishTile extends ConsumerWidget {
  const _WishTile({required this.item});
  final WishlistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(productProvider(item.variantId));
    return view.maybeWhen(
      data: (v) {
        if (v == null) return const SizedBox.shrink();
        final best = v.best;
        final hit = best != null && item.targetPrice != null && best.yourBest <= item.targetPrice!;
        return OutlinedCard(
          borderColor: hit ? BrandColors.emerald : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductImage(variant: v.variant, size: 64, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.push('/product/${item.variantId}'),
                      child: Text(v.variant.familyName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 4),
                    Text(best == null ? 'No fresh price right now' : 'Your best price: ${rupees(best.yourBest)}'),
                    Text(item.targetPrice == null ? 'No target set' : 'Alert at: ${rupees(item.targetPrice!)}',
                        style: const TextStyle(color: BrandColors.slate)),
                    if (hit)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Pill('Target reached', color: BrandColors.emerald, background: BrandColors.emeraldSoft,
                            icon: Icons.notifications_active),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _askTarget(context, ref, item),
                        icon: const Icon(Icons.notifications_none),
                        label: const Text('Set target price'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
    );
  }
}

Future<void> _askTarget(BuildContext context, WidgetRef ref, WishlistItem item) async {
  final controller = TextEditingController(text: item.targetPrice?.toString() ?? '');
  final value = await showDialog<int?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Alert me when the price is at or below'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(prefixText: '₹ '),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // Controller is left to GC: disposing here races the dialog's exit animation.
  if (value != null) ref.read(wishlistProvider.notifier).setTarget(item.variantId, value);
}
