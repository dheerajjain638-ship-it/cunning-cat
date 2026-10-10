# ADR-0004: Deterministic effective-price engine

**Status:** Accepted (v0, app-side). **Date:** 2026-10-10. **Author:** Claude. **Reviewer:** ChatGPT (pending).

## Decision
All prices shown to users come from deterministic code (`lib/domain/effective_price.dart`, mirrored server-side in Phase 3). The LLM never computes or states a price except by quoting this engine's output.

## Rules (v0)
1. Base = item price + delivery fee.
2. Offers that are expired go to `excluded`.
3. Offers needing a bigger cart, a membership, a first order, an exchange, or a card the user doesn't own go to `conditional`. They are never part of `yourBest`.
4. **Guaranteed** = base minus the best *instant* offer per stack group among offers open to everyone.
5. **Your best** = base minus the best instant offer per stack group among offers the user is eligible for.
6. Deferred cashback is reported separately and never subtracted.
7. Only one offer per stack group applies. The highest saving wins, and on a tie an instant offer beats cashback.
8. Prices older than 24h are `stale`. Stale and out-of-stock listings rank after fresh ones and cannot be called "best".

## Known simplification
Every discount is computed on the item price, not on the price after other discounts. Retailer-specific ordering (for example coupon before bank offer) comes in the Pricing & Offer Rules Spec (document 6).

## Tests
`test/effective_price_test.dart` covers: ineligible card, eligible card, conflicting offers, expired coupon, deferred cashback, minimum cart, membership, delivery fee, stale price, out of stock, EMI cost, inflated MRP, and insufficient history.
