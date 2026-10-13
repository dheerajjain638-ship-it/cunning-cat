import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'data/live_models.dart';
import 'features/ask/ask_screen.dart';
import 'features/battle/battle_screen.dart';
import 'features/home/home_screen.dart';
import 'features/live/live_product_screen.dart';
import 'features/live/live_search_screen.dart';
import 'features/product/product_screen.dart';
import 'features/search/search_results_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/wallet/wallet_screen.dart';
import 'features/wishlist/wishlist_screen.dart';

GoRouter buildRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/ask', builder: (c, s) => const AskScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/wishlist', builder: (c, s) => const WishlistScreen())]),
            StatefulShellBranch(routes: [GoRoute(path: '/wallet', builder: (c, s) => const WalletScreen())]),
          ],
        ),
        GoRoute(
          path: '/search',
          builder: (c, s) => SearchResultsScreen(
            query: s.uri.queryParameters['q'] ?? '',
            categoryId: s.uri.queryParameters['cat'],
          ),
        ),
        GoRoute(
          path: '/live',
          builder: (c, s) => LiveSearchScreen(query: s.uri.queryParameters['q'] ?? ''),
        ),
        GoRoute(
          path: '/live/product',
          redirect: (c, s) => s.extra is LiveProduct ? null : '/',
          builder: (c, s) => LiveProductScreen(product: s.extra! as LiveProduct),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (c, s) => ProductScreen(variantId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/battle/:a/:b',
          builder: (c, s) => BattleScreen(leftId: s.pathParameters['a']!, rightId: s.pathParameters['b']!),
        ),
      ],
    );

class CunningCatApp extends StatefulWidget {
  const CunningCatApp({super.key});

  @override
  State<CunningCatApp> createState() => _CunningCatAppState();
}

class _CunningCatAppState extends State<CunningCatApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cunning Cat',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
