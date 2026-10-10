import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/common.dart';
import '../../state/providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(repositoryProvider);
    final owned = ref.watch(walletProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My cards & UPI')),
      body: ListView(
        children: [
          const OutlinedCard(
            child: Text(
              'Tick the payment methods you have. We use this only to work out which bank offers you can use. '
              'We never ask for card numbers, expiry dates or CVV.',
            ),
          ),
          for (final i in repo.instruments)
            CheckboxListTile(
              value: owned.contains(i.id),
              onChanged: (_) => ref.read(walletProvider.notifier).toggle(i.id),
              title: Text(i.bank),
              subtitle: Text(i.kind),
            ),
        ],
      ),
    );
  }
}
