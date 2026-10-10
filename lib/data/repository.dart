import 'mock_data.dart' as mock;
import 'models.dart';

/// The app talks to data only through this interface (API contract boundary).
/// Phase 3 swaps [MockCatalogRepository] for an HTTP implementation of the
/// backend's OpenAPI contract; screens do not change.
abstract class CatalogRepository {
  Future<List<Variant>> search(String query);
  Future<Variant?> variant(String id);
  Future<List<Listing>> listingsFor(String variantId);
  Future<List<Offer>> offers();
  Future<List<PricePoint>> history(String variantId);
  Future<List<ReportDimension>> reportCard(String variantId);
  Future<List<ReviewInsight>> reviewInsights(String variantId);
  List<Merchant> get merchants;
  List<PaymentInstrument> get instruments;
  List<Variant> get trending;
}

class MockCatalogRepository implements CatalogRepository {
  MockCatalogRepository({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  @override
  List<Merchant> get merchants => mock.merchants;

  @override
  List<PaymentInstrument> get instruments => mock.instruments;

  @override
  List<Variant> get trending => mock.variants;

  @override
  Future<List<Variant>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return mock.variants;
    // A pasted product link: in production the backend resolves the URL to a
    // variant. In the demo we match on known retailer domains.
    if (q.startsWith('http')) return mock.variants.take(1).toList();
    final words = q.split(RegExp(r'\s+'));
    return mock.variants.where((v) {
      final hay = '${v.displayName} ${v.brand} ${v.category.label}'.toLowerCase();
      return words.every(hay.contains);
    }).toList();
  }

  @override
  Future<Variant?> variant(String id) async {
    for (final v in mock.variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  Future<List<Listing>> listingsFor(String variantId) async =>
      mock.buildListings(_clock()).where((l) => l.variantId == variantId).toList();

  @override
  Future<List<Offer>> offers() async => mock.buildOffers(_clock());

  @override
  Future<List<PricePoint>> history(String variantId) async {
    final listings = await listingsFor(variantId);
    final authorised = listings.where((l) => l.authorisedSeller).map((l) => l.price);
    if (authorised.isEmpty) return const [];
    final low = authorised.reduce((a, b) => a < b ? a : b);
    return mock.buildHistory(low, _clock(), seed: variantId.length);
  }

  @override
  Future<List<ReportDimension>> reportCard(String variantId) async =>
      mock.reportCards[variantId] ?? const [];

  @override
  Future<List<ReviewInsight>> reviewInsights(String variantId) async =>
      mock.reviewInsights[variantId] ?? const [];
}
