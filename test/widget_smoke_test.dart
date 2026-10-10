import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cunning_cat/app.dart';

void main() {
  testWidgets('home screen renders brand, search and demo banner', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CunningCatApp()));
    await tester.pumpAndSettle();
    expect(find.text('Cunning Cat'), findsOneWidget);
    expect(find.text('Search a product or paste a link'), findsOneWidget);
    expect(find.textContaining('Demo data'), findsOneWidget);
  });

  testWidgets('opening a product shows your best price', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CunningCatApp()));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Samsung Galaxy S25'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Samsung Galaxy S25'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR BEST PRICE'), findsOneWidget);
    expect(find.text('Compare stores'), findsOneWidget);
  });
}
