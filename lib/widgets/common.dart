import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';

/// Shown on every screen while the app runs on demo data.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: BrandColors.amber.withValues(alpha: 0.15),
      child: const Text(
        'Demo data: prices, offers and scores are not real yet.',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class OutlinedCard extends StatelessWidget {
  const OutlinedCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.borderColor});
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? scheme.outlineVariant),
      ),
      child: child,
    );
  }
}

/// Small line chart of price history; no chart dependency needed.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.points, this.height = 72});
  final List<PricePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(points, Theme.of(context).colorScheme.primary)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.points, this.color);
  final List<PricePoint> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final prices = points.map((p) => p.lowestPrice).toList();
    final lo = prices.reduce((a, b) => a < b ? a : b).toDouble();
    final hi = prices.reduce((a, b) => a > b ? a : b).toDouble();
    final span = (hi - lo) == 0 ? 1.0 : hi - lo;
    final path = Path();
    for (var i = 0; i < prices.length; i++) {
      final x = size.width * i / (prices.length - 1);
      final y = size.height - (prices[i] - lo) / span * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    // Mark today's point.
    final lastY = size.height - (prices.last - lo) / span * (size.height - 8) - 4;
    canvas.drawCircle(Offset(size.width, lastY), 4, Paint()..color = BrandColors.amber);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.points != points || old.color != color;
}

class ScoreRow extends StatelessWidget {
  const ScoreRow({super.key, required this.dimension});
  final ReportDimension dimension;

  @override
  Widget build(BuildContext context) {
    final d = dimension;
    final scheme = Theme.of(context).colorScheme;
    final conf = switch (d.confidence) {
      Confidence.high => 'High confidence',
      Confidence.medium => 'Medium confidence',
      Confidence.low => 'Low confidence',
      null => 'Not scored',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(
                d.score == null ? 'Not enough evidence' : '${d.score!.toStringAsFixed(1)} / 10',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: d.score == null ? scheme.onSurfaceVariant : scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (d.score != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: d.score! / 10, minHeight: 6),
            ),
          const SizedBox(height: 6),
          Text(d.summary, style: Theme.of(context).textTheme.bodySmall),
          Text('$conf · ${d.evidenceCount} sources',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
