import 'package:flutter_test/flutter_test.dart';

import 'package:cunning_cat/data/catalog.dart';
import 'package:cunning_cat/data/repository.dart';
import 'package:cunning_cat/domain/advisor.dart';

void main() {
  final repo = MockCatalogRepository(clock: () => DateTime(2026, 10, 10, 12));

  test('catalog has 10 categories and 40+ products', () {
    expect(categories.length, 10);
    expect(variants.length, greaterThanOrEqualTo(40));
    expect(variants.map((v) => v.id).toSet().length, variants.length, reason: 'ids must be unique');
  });

  test('search matches brand prefixes and category synonyms', () async {
    expect((await repo.search('sams')).every((v) => v.brand == 'Samsung'), isTrue);
    expect((await repo.search('fridge')).every((v) => v.category.id == 'fridges'), isTrue);
    expect((await repo.search('earbuds')).isNotEmpty, isTrue);
    expect((await repo.search('galaxy s25')).first.id, 'galaxy-s25-256-navy');
  });

  test('search can filter by category and returns all for empty query', () async {
    expect((await repo.search('', categoryId: 'acs')).every((v) => v.category.id == 'acs'), isTrue);
    expect((await repo.search('')).length, variants.length);
  });

  test('pasted retailer link is turned into a search', () async {
    const link = 'https://www.flipkart.com/samsung-galaxy-s25-5g-navy-256-gb/p/itm123?pid=MOB';
    expect(queryFromLink(link), 'samsung galaxy s25 5g navy 256 gb');
    final results = await repo.search(link);
    expect(results.first.id, 'galaxy-s25-256-navy');
  });

  test('every product has listings from at least 3 stores', () async {
    for (final v in variants) {
      final l = await repo.listingsFor(v.id);
      expect(l.where((x) => x.authorisedSeller).length, greaterThanOrEqualTo(3), reason: v.id);
    }
  });

  test('alternatives stay in the same category and budget', () {
    final base = variants.firstWhere((v) => v.id == 'galaxy-s25-256-navy');
    final prices = {for (final v in variants) v.id: v.basePrice};
    final alts = findAlternatives(variant: base, budget: 80000, catalog: variants, bestPrices: prices);
    expect(alts, isNotEmpty);
    for (final a in alts) {
      expect(a.variant.category.id, 'mobiles');
      expect(a.bestPrice, inInclusiveRange(48000, 96000));
    }
  });

  test('star shares sum to 1', () {
    final s = starShares(4.3);
    expect(s.reduce((a, b) => a + b), closeTo(1.0, 1e-9));
  });
}
