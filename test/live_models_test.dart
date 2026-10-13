import 'dart:convert';

import 'package:cunning_cat/data/live_api.dart';
import 'package:cunning_cat/data/live_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('LiveProduct parses prices, image and discount', () {
    final p = LiveProduct.fromJson({
      'id': '1',
      'token': 't',
      'title': 'Galaxy S25',
      'image': 'https://img/x.jpg',
      'price': 74999,
      'oldPrice': 80999,
      'store': 'Croma',
      'rating': 4.5,
      'reviews': 2310,
      'multipleStores': true,
    });
    expect(p.price, 74999);
    expect(p.discountPct, 7);
    expect(p.multipleStores, isTrue);
    expect(LiveProduct.fromJson({'id': '2', 'title': 'x', 'price': '₹499'}).price, 499);
  });

  test('LiveDetail sorts stores cheapest first and reads history', () {
    final d = LiveDetail.fromJson({
      'title': 'Galaxy S25',
      'images': ['a.jpg', 'b.jpg'],
      'stores': [
        {'name': 'Amazon.in', 'price': 74499, 'offers': ['10% off with HDFC']},
        {'name': 'Flipkart', 'price': 73999},
        {'name': 'Broken', 'price': null},
      ],
      'ratings': [
        {'stars': 5, 'count': 10},
        {'stars': 1, 'count': 2},
      ],
      'features': [
        {'name': 'Display', 'value': '6.2 in'},
      ],
      'history': [
        {'d': '2026-10-01', 'p': 76000},
        {'d': '2026-10-02', 'p': 73999},
      ],
    });
    expect(d.stores.map((s) => s.name), ['Flipkart', 'Amazon.in']);
    expect(d.cheapest!.price, 73999);
    expect(d.spread, 500);
    expect(d.ratings[5], 10);
    expect(d.history.length, 2);
    expect(d.features.single.name, 'Display');
  });

  test('AskAnswer keeps picks by product id', () {
    final a = AskAnswer.fromJson({
      'reply': 'Here you go',
      'query': 'phone',
      'products': [
        {'id': 'a', 'title': 'A', 'price': 100},
        {'id': 'b', 'title': 'B', 'price': 200},
      ],
      'picks': [
        {'id': 'b', 'why': 'Best camera'},
      ],
    });
    expect(a.products.length, 2);
    expect(a.picks['b'], 'Best camera');
    expect(AiInsight.fromJson({'verdict': 'consider_alternatives'}).verdict, AiVerdict.considerAlternatives);
  });

  test('LiveApi sends the app key and surfaces server errors', () async {
    final client = MockClient((req) async {
      expect(req.headers['x-cc-key'], 'secret');
      if (req.url.path == '/search') {
        return http.Response(jsonEncode({'products': [{'id': '1', 'title': 'X', 'price': 10}]}), 200);
      }
      return http.Response(jsonEncode({'error': 'Live search is not configured'}), 503);
    });
    final api = LiveApi(client: client, base: 'https://api.example/', appKey: 'secret');
    final results = await api.search('x');
    expect(results.single.title, 'X');
    await expectLater(api.product('t'), throwsA(isA<LiveApiException>()));
  });

  test('without a server URL the app stays in demo mode', () {
    expect(LiveConfig.enabled, isFalse);
  });
}
