/// Real-time data from the Cunning Cat API (server/worker.js), which reads
/// Google Shopping India for prices, photos, stores and reviews.

double? _d(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9.]'), ''));
  return null;
}

int? _i(Object? v) => _d(v)?.round();

String? _s(Object? v) => v is String && v.isNotEmpty ? v : null;

List<String> _strings(Object? v) => v is List ? [for (final x in v) if (x is String && x.isNotEmpty) x] : const [];

List<Map<String, dynamic>> _maps(Object? v) =>
    v is List ? [for (final x in v) if (x is Map) Map<String, dynamic>.from(x)] : const [];

/// One search result: a product as one store lists it.
class LiveProduct {
  final String id;
  final String? token;
  final String title;
  final String? image;
  final double price;
  final double? oldPrice;
  final String? store;
  final String? storeIcon;
  final double? rating;
  final int? reviews;
  final bool multipleStores;
  final String? delivery;
  final String? link;

  const LiveProduct({
    required this.id,
    required this.title,
    required this.price,
    this.token,
    this.image,
    this.oldPrice,
    this.store,
    this.storeIcon,
    this.rating,
    this.reviews,
    this.multipleStores = false,
    this.delivery,
    this.link,
  });

  factory LiveProduct.fromJson(Map<String, dynamic> j) => LiveProduct(
        id: '${j['id'] ?? j['title']}',
        token: _s(j['token']),
        title: '${j['title'] ?? ''}',
        image: _s(j['image']),
        price: _d(j['price']) ?? 0,
        oldPrice: _d(j['oldPrice']),
        store: _s(j['store']),
        storeIcon: _s(j['storeIcon']),
        rating: _d(j['rating']),
        reviews: _i(j['reviews']),
        multipleStores: j['multipleStores'] == true,
        delivery: _s(j['delivery']),
        link: _s(j['link']),
      );

  /// Percentage off the store's own "was" price, when it shows one.
  int? get discountPct {
    final old = oldPrice;
    if (old == null || old <= price || old == 0) return null;
    final pct = ((1 - price / old) * 100).round();
    return pct >= 1 ? pct : null;
  }
}

class LiveStore {
  final String name;
  final String? logo;
  final String? link;
  final double price;
  final double? oldPrice;
  final double? total;
  final List<String> offers;
  final double? rating;
  final int? reviews;
  final String? tag;
  final String? shipping;
  final String? emi;

  const LiveStore({
    required this.name,
    required this.price,
    this.logo,
    this.link,
    this.oldPrice,
    this.total,
    this.offers = const [],
    this.rating,
    this.reviews,
    this.tag,
    this.shipping,
    this.emi,
  });

  factory LiveStore.fromJson(Map<String, dynamic> j) => LiveStore(
        name: '${j['name'] ?? 'Store'}',
        logo: _s(j['logo']),
        link: _s(j['link']),
        price: _d(j['price']) ?? 0,
        oldPrice: _d(j['oldPrice']),
        total: _d(j['total']),
        offers: _strings(j['offers']),
        rating: _d(j['rating']),
        reviews: _i(j['reviews']),
        tag: _s(j['tag']),
        shipping: _s(j['shipping']),
        emi: _s(j['emi']),
      );
}

class LiveInsight {
  final String point;
  final String snippet;
  final List<String> pros;
  final List<String> cons;
  final String? source;
  const LiveInsight(this.point, this.snippet, this.pros, this.cons, this.source);

  factory LiveInsight.fromJson(Map<String, dynamic> j) => LiveInsight(
      '${j['point'] ?? ''}', '${j['snippet'] ?? ''}', _strings(j['pros']), _strings(j['cons']), _s(j['source']));
}

class LiveReview {
  final String title;
  final String text;
  final double? rating;
  final String? user;
  final String? source;
  final String? date;
  const LiveReview(this.title, this.text, this.rating, this.user, this.source, this.date);

  factory LiveReview.fromJson(Map<String, dynamic> j) => LiveReview('${j['title'] ?? ''}', '${j['text'] ?? ''}',
      _d(j['rating']), _s(j['user']), _s(j['source']), _s(j['date']));
}

class LiveFeature {
  final String name;
  final String value;
  const LiveFeature(this.name, this.value);
}

class LiveHistoryPoint {
  final DateTime date;
  final double price;
  const LiveHistoryPoint(this.date, this.price);
}

/// Everything we know about one product across stores.
class LiveDetail {
  final String title;
  final String? brand;
  final List<String> images;
  final double? rating;
  final int? reviews;
  final String? priceRange;
  final Map<int, int> ratings;
  final List<LiveStore> stores;
  final List<LiveFeature> features;
  final String? description;
  final List<LiveInsight> insights;
  final List<LiveReview> userReviews;
  final List<LiveHistoryPoint> history;

  const LiveDetail({
    required this.title,
    this.brand,
    this.images = const [],
    this.rating,
    this.reviews,
    this.priceRange,
    this.ratings = const {},
    this.stores = const [],
    this.features = const [],
    this.description,
    this.insights = const [],
    this.userReviews = const [],
    this.history = const [],
  });

  factory LiveDetail.fromJson(Map<String, dynamic> j) {
    final stores = [for (final s in _maps(j['stores'])) LiveStore.fromJson(s)]
        .where((s) => s.price > 0)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    final history = <LiveHistoryPoint>[];
    for (final h in _maps(j['history'])) {
      final date = DateTime.tryParse('${h['d']}');
      final p = _d(h['p']);
      if (date != null && p != null) history.add(LiveHistoryPoint(date, p));
    }
    return LiveDetail(
      title: '${j['title'] ?? ''}',
      brand: _s(j['brand']),
      images: _strings(j['images']),
      rating: _d(j['rating']),
      reviews: _i(j['reviews']),
      priceRange: _s(j['priceRange']),
      ratings: {
        for (final r in _maps(j['ratings']))
          if (_i(r['stars']) != null) _i(r['stars'])!: _i(r['count']) ?? 0,
      },
      stores: stores,
      features: [
        for (final f in _maps(j['features']))
          if (_s(f['name']) != null && _s(f['value']) != null) LiveFeature(f['name'] as String, f['value'] as String),
      ],
      description: _s(j['description']),
      insights: [for (final x in _maps(j['insights'])) LiveInsight.fromJson(x)],
      userReviews: [for (final x in _maps(j['userReviews'])) LiveReview.fromJson(x)],
      history: history,
    );
  }

  LiveStore? get cheapest => stores.isEmpty ? null : stores.first;

  /// How much the cheapest store saves versus the dearest one.
  double get spread => stores.length < 2 ? 0 : stores.last.price - stores.first.price;
}

enum AiVerdict { buy, wait, considerAlternatives, unknown }

/// The Cat's AI read of a product (Claude, using only the store and review data).
class AiInsight {
  final AiVerdict verdict;
  final String headline;
  final String summary;
  final List<String> pros;
  final List<String> cons;
  final String? bestFor;
  final String? skipIf;
  final String? priceAdvice;

  const AiInsight({
    required this.verdict,
    required this.headline,
    required this.summary,
    this.pros = const [],
    this.cons = const [],
    this.bestFor,
    this.skipIf,
    this.priceAdvice,
  });

  factory AiInsight.fromJson(Map<String, dynamic> j) => AiInsight(
        verdict: switch (j['verdict']) {
          'buy' => AiVerdict.buy,
          'wait' => AiVerdict.wait,
          'consider_alternatives' => AiVerdict.considerAlternatives,
          _ => AiVerdict.unknown,
        },
        headline: '${j['headline'] ?? ''}',
        summary: '${j['summary'] ?? ''}',
        pros: _strings(j['pros']),
        cons: _strings(j['cons']),
        bestFor: _s(j['bestFor']),
        skipIf: _s(j['skipIf']),
        priceAdvice: _s(j['priceAdvice']),
      );
}

/// One answer from "Ask the Cat".
class AskAnswer {
  final String reply;
  final String? query;
  final List<LiveProduct> products;

  /// Product id -> why the Cat picked it.
  final Map<String, String> picks;

  const AskAnswer({required this.reply, this.query, this.products = const [], this.picks = const {}});

  factory AskAnswer.fromJson(Map<String, dynamic> j) => AskAnswer(
        reply: '${j['reply'] ?? ''}',
        query: _s(j['query']),
        products: [for (final p in _maps(j['products'])) LiveProduct.fromJson(p)],
        picks: {
          for (final p in _maps(j['picks']))
            if (p['id'] != null) '${p['id']}': '${p['why'] ?? ''}',
        },
      );
}
