import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/live_api.dart';
import '../../data/live_models.dart';
import '../../state/live_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';

const askSuggestions = [
  'Best phone under ₹25,000 for camera',
  'Quiet 1.5 ton AC for a bedroom',
  'Laptop for college coding under ₹60,000',
  'Gift for my dad under ₹3,000',
  'Earbuds with the best noise cancelling',
  'Washing machine for a family of 4',
];

/// "Ask the Cat": describe what you need in plain words; the Cat searches live
/// prices and picks the best three with reasons.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    final done = ref.read(askProvider.notifier).send(text);
    _scrollToEnd();
    await done;
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(askProvider);
    final enabled = LiveConfig.enabled;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CatLogo(size: 32),
            SizedBox(width: 8),
            Text('Ask the Cat'),
          ],
        ),
        actions: [
          if (state.messages.isNotEmpty)
            IconButton(
              tooltip: 'New chat',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(askProvider.notifier).reset(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.messages.isEmpty
                ? _Welcome(enabled: enabled, onPick: _send)
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: state.messages.length + (state.busy ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) return const _Thinking();
                      return _MessageView(message: state.messages[i]);
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: enabled && !state.busy,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: enabled ? 'What are you shopping for?' : 'Ask the Cat needs live mode',
                        prefixIcon: const Icon(Icons.auto_awesome, color: BrandColors.amber),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: BrandColors.indigoMid),
                    onPressed: enabled && !state.busy ? () => _send(_controller.text) : null,
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.enabled, required this.onPick});
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: BrandColors.heroGradient, borderRadius: BorderRadius.circular(24)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CatLogo(size: 64),
              SizedBox(height: 10),
              Text('Tell me what you need.',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              SizedBox(height: 6),
              Text(
                'Say it like you would to a friend. I search live prices across Indian stores, '
                'read the reviews, and pick the best three for you, with reasons.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (!enabled)
          const OutlinedCard(
            child: Text(
              'This test build runs on demo data. Ask the Cat switches on when the app is connected '
              'to the Cunning Cat server (live prices + AI).',
            ),
          ),
        const Text('Try asking', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in askSuggestions)
              ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 16, color: BrandColors.amber),
                label: Text(s),
                onPressed: enabled ? () => onPick(s) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CatLogo(size: 28),
          SizedBox(width: 8),
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Flexible(child: Text('Searching stores and reading reviews…')),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (message.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 4, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BrandColors.indigoMid,
            borderRadius: BorderRadius.circular(18).copyWith(bottomRight: const Radius.circular(4)),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.white)),
        ),
      );
    }
    final answer = message.answer;
    final products = _ordered(answer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 8), child: CatLogo(size: 28)),
            const SizedBox(width: 6),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4, right: 32),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: message.isError ? BrandColors.coralSoft : scheme.surface,
                  borderRadius: BorderRadius.circular(18).copyWith(topLeft: const Radius.circular(4)),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                child: Text(message.text),
              ),
            ),
          ],
        ),
        if (products.isNotEmpty)
          SizedBox(
            height: 318,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(34, 6, 4, 6),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: 172,
                child: LiveProductCard(product: products[i], pickReason: answer!.picks[products[i].id]),
              ),
            ),
          ),
      ],
    );
  }

  /// The Cat's picks first, then the rest.
  List<LiveProduct> _ordered(AskAnswer? a) {
    if (a == null) return const [];
    final picked = [for (final p in a.products) if (a.picks.containsKey(p.id)) p];
    final rest = [for (final p in a.products) if (!a.picks.containsKey(p.id)) p];
    return [...picked, ...rest];
  }
}
