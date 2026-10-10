import 'catalog.dart' as demo;
import 'models.dart';

/// The app talks to data only through this interface (API contract boundary).
/// Phase 3 swaps [MockCatalogRepository] for an HTTP implementation of the
/// backend's OpenAPI contract; screens do not change.
abstract class CatalogRepository {
  Future<List<Variant>> search(String query, {String? categoryId});
  Future<Variant?> variant(String id);
  Future<List<Listing>> listingsFor(String variantId);
  Future<List<Offer>> offers();
  Future<List<PricePoint>> history(String variantId);
  Future<List<ReportDimension>> reportCard(String variantId);
  Future<List<ReviewInsight>> reviewInsights(String variantId);
  List<Merchant> get merchants;
  List<PaymentInstrument> get instruments;
  List<Category> get categories;
  List<Variant> get all;
}

/// Turns a pasted retailer link into search words, e.g.
/// flipkart.com/samsung-galaxy-s25-navy-256-gb/p/itm... -> "samsung galaxy s25 navy 256 gb".
String? queryFromLink(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  String best = '';
  for (final seg in uri.pathSegments) {
    if (seg.contains('-') && seg.length > best.length) best = seg;
  }
  if (best.isEmpty) return null;
  return best.replaceAll(RegExp(r'[-_]+'), ' ').toLowerCase();
}

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  List<Merchant> get merchants => demo.merchants;

  @override
  List<PaymentInstrument> get instruments => demo.instruments;

  @override
  List<Category> get categories => demo.categories;

  @override
  List<Variant> get all => demo.variants;

  /// Scores a product against the words typed. Every word must match the
  /// product name, brand, category or a category synonym (prefix match, so
  /// "sams" finds Samsung). Returns 0 for no match.
  static int score(Variant v, List<String> words) {
    final name = '${v.familyName} ${v.variantLabel} ${v.brand}'.toLowerCase();
    final cat = '${v.category.label} ${v.category.synonyms.join(' ')}'.toLowerCase();
    final tokens = '$name $cat'.split(RegExp(r'[^a-z0-9.+]+')).where((t) => t.isNotEmpty).toList();
    var total = 0;
    for (final w in words) {
      if (name.contains(w)) {
        total += 3;
      } else if (tokens.any((t) => t.startsWith(w))) {
        total += 2;
      } else if (cat.contains(w)) {
        total += 1;
      } else {
        return 0;
      }
    }
    return total;
  }

  @override
  Future<List<Variant>> search(String query, {String? categoryId}) async {
    var q = query.trim().toLowerCase();
    if (q.startsWith('http')) q = queryFromLink(q) ?? '';
    final pool = categoryId == null ? demo.variants : demo.variants.where((v) => v.category.id == categoryId).toList();
    if (q.isEmpty) return pool;
    final words = q.split(RegExp(r'\s+')).where((w) => w.length > 1 || RegExp(r'\d').hasMatch(w)).toList();
    if (words.isEmpty) return pool;
    var scored = [for (final v in pool) (v, score(v, words))].where((e) => e.$2 > 0).toList();
    // A long pasted-link slug rarely matches every word; fall back to "most words".
    if (scored.isEmpty && words.length > 2) {
      scored = [
        for (final v in pool) (v, words.where((w) => score(v, [w]) > 0).length),
      ].where((e) => e.$2 >= (words.length / 2).ceil()).toList();
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in scored) e.$1];
  }

  @override
  Future<Variant?> variant(String id) async {
    for (final v in demo.variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  Future<List<Listing>> listingsFor(String variantId) async =>
      demo.buildListings(_clock()).where((l) => l.variantId == variantId).toList();

  @override
  Future<List<Offer>> offers() async => demo.buildOffers(_clock());

  @override
  Future<List<PricePoint>> history(String variantId) async {
    final listings = await listingsFor(variantId);
    final prices = listings.where((l) => l.authorisedSeller && l.inStock).map((l) => l.price).toList();
    if (prices.isEmpty) return const [];
    prices.sort();
    return demo.buildHistory(prices.first, _clock(), seed: demo.seedOf(variantId));
  }

  @override
  Future<List<ReportDimension>> reportCard(String variantId) async {
    final v = await variant(variantId);
    return v == null ? const [] : demo.buildReportCard(v);
  }

  @override
  Future<List<ReviewInsight>> reviewInsights(String variantId) async {
    final v = await variant(variantId);
    return v == null ? const [] : demo.buildInsights(v, demo.buildReportCard(v));
  }
}
