# Cunning Cat

*Know more. Pay less. Buy better.*

Cunning Cat is an AI shopping decision app for India. It answers three questions on one screen: the right product, the right store and card, and the right time to buy.

**Status: v0.1 (Phase 1).** The Android and iOS app shell runs on **demo data**. No real prices, offers or reviews are connected yet.

## What's in v0.1

| Screen | What it does |
| --- | --- |
| Find (home) | Search by name, paste a product link, browse by category, see trending products |
| Product | Your best price, compare stores, offers applied and locked, price history, deal verdict, inflated-MRP warning, report card with confidence, review insights, true EMI cost, affiliate disclosure |
| Wishlist | Track products and set target prices |
| My cards | Tick the cards and UPI you own (types only, never card numbers) to personalise bank offers |

## Architecture (app side)

```
lib/
  core/       theme (brand colours), formatting (₹, "checked 12 min ago")
  data/       models, CatalogRepository interface, MockCatalogRepository (demo data)
  domain/     effective_price.dart: deterministic price engine, EMI cost, deal verdict
  state/      Riverpod providers (wallet, wishlist, product view)
  features/   screens: home, search, product, wallet, wishlist, shell
  widgets/    shared UI (demo banner, sparkline, score rows)
test/         price-engine benchmark tests + widget smoke tests
```

- Screens never touch data directly. Everything goes through `CatalogRepository`. In Phase 3 an HTTP implementation of the backend API replaces the mock, and no screen code changes.
- Prices are computed only by `domain/effective_price.dart` (ADR-0004), never by an LLM.

## Build

CI (`.github/workflows/ci.yml`) runs analyze and tests on every push, then builds an installable APK. To get it, open the run in the **Actions** tab and download **cunning-cat-android-apk**. The iOS compile check runs when the workflow is started manually.

Local build, on a machine with Flutter 3.27.4:

```
bash tool/ensure_platforms.sh
flutter pub get
flutter test
flutter run
```
