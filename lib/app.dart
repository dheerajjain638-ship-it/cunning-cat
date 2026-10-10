import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/product/product_screen.dart';
import 'features/search/search_results_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/wishlist/wishlist_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => MainShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wishlist', builder: (c, s) => const WishlistScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: '/wallet', builder: (c, s) => const WalletScreen())]),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (c, s) => SearchResultsScreen(query: s.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/product/:id',
      builder: (c, s) => ProductScreen(variantId: s.pathParameters['id']!),
    ),
  ],
);

class CunningCatApp extends StatelessWidget {
  const CunningCatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cunning Cat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
