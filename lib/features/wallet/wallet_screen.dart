import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const OutlinedCard(
            gradient: BrandColors.heroGradient,
            borderColor: Colors.transparent,
            child: Row(
              children: [
                Icon(Icons.shield_rounded, color: BrandColors.amber, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tick the payment methods you have. We only use this to work out which bank offers you can use. '
                    'We never ask for card numbers, expiry dates or CVV.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          SectionTitle('${owned.length} selected', icon: Icons.credit_card),
          OutlinedCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final i in repo.instruments)
                  CheckboxListTile(
                    value: owned.contains(i.id),
                    activeColor: BrandColors.indigoMid,
                    onChanged: (_) => ref.read(walletProvider.notifier).toggle(i.id),
                    secondary: CircleAvatar(
                      backgroundColor: BrandColors.amberSoft,
                      child: Icon(i.kind == 'UPI' ? Icons.qr_code_2 : Icons.credit_card, color: BrandColors.indigo),
                    ),
                    title: Text(i.bank, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(i.kind),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
