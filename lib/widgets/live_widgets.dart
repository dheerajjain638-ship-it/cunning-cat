import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../data/live_models.dart';

/// Product photo from the web, cached on the phone, with a branded placeholder.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.contain, this.iconSize = 36});
  final String? url;
  final BoxFit fit;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final u = url;
    final fallback = Center(child: Icon(Icons.image_outlined, size: iconSize, color: BrandColors.slate.withValues(alpha: 0.5)));
    if (u == null || u.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: u,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, __) => Container(color: const Color(0xFFF1F0F9)),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

/// Opens a store page in the browser or the store's own app.
Future<void> openStoreLink(BuildContext context, String? url) async {
  final messenger = ScaffoldMessenger.of(context);
  final uri = url == null ? null : Uri.tryParse(url);
  final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) messenger.showSnackBar(const SnackBar(content: Text('Could not open the store.')));
}

void openLiveProduct(BuildContext context, LiveProduct p) {
  if (p.token != null) {
    context.push('/live/product', extra: p);
  } else {
    openStoreLink(context, p.link);
  }
}

/// Grid tile for one live result: photo, price, discount, store, rating.
class LiveProductCard extends StatelessWidget {
  const LiveProductCard({super.key, required this.product, this.pickReason});
  final LiveProduct product;
  final String? pickReason;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final scheme = Theme.of(context).colorScheme;
    final pct = p.discountPct;
    final picked = pickReason != null;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => openLiveProduct(context, p),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: picked ? BrandColors.amber : scheme.outlineVariant.withValues(alpha: 0.6), width: picked ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: NetImage(p.image),
                      ),
                    ),
                    if (pct != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _Badge('$pct% OFF', BrandColors.emerald),
                      ),
                    if (picked)
                      const Positioned(right: 8, top: 8, child: _Badge("CAT'S PICK", BrandColors.amber, dark: true)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.25)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(rupees(p.price),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        if (p.oldPrice != null && pct != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(rupees(p.oldPrice!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurfaceVariant,
                                    decoration: TextDecoration.lineThrough)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (p.storeIcon != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(width: 14, height: 14, child: NetImage(p.storeIcon, iconSize: 12)),
                          ),
                        Expanded(
                          child: Text(p.multipleStores ? '${p.store ?? 'Store'} + more' : (p.store ?? ''),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (p.rating != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: BrandColors.amber),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              '${p.rating!.toStringAsFixed(1)}${p.reviews != null ? ' (${compact(p.reviews!)})' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (pickReason != null && pickReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(pickReason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: BrandColors.indigoMid, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color, {this.dark = false});
  final String text;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(
              color: dark ? BrandColors.indigo : Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
    );
  }
}

/// Small green "LIVE" badge shown when prices come from the stores in real time.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: BrandColors.emerald, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: Colors.white),
          SizedBox(width: 4),
          Text('LIVE PRICES',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
        ],
      ),
    );
  }
}

/// Friendly error with a retry button.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: BrandColors.slate),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Try again')),
        ],
      ),
    );
  }
}
