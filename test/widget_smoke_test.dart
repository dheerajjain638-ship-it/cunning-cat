import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cunning_cat/app.dart';

void main() {
  testWidgets('home shows brand, search, categories and popular products', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CunningCatApp()));
    await tester.pumpAndSettle();
    expect(find.text('Cunning Cat'), findsOneWidget);
    expect(find.text('Search any product, brand or paste a link'), findsOneWidget);
    expect(find.text('DEMO DATA'), findsWidgets);
    expect(find.text('Shop by category'), findsOneWidget);
  });

  testWidgets('typing shows live results and opens the product verdict', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CunningCatApp()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'galaxy s25');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Samsung Galaxy S25'), findsWidgets);
    await tester.tap(find.text('Samsung Galaxy S25').first);
    await tester.pumpAndSettle();
    expect(find.text("CUNNING CAT'S VERDICT"), findsOneWidget);
    expect(find.text('YOUR BEST PRICE'), findsOneWidget);
  });
}
