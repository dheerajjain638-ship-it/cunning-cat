# ADR 0005: Live data through our own API server

Date: 2026-10-13. Status: accepted.

## Context

Users want real, current prices with product photos from Amazon, Flipkart, Croma and other stores.

- **Amazon:** PA-API 5.0 is retired. Its replacement, the Creators API, requires an Associates account with at least 10 qualifying sales in the last 30 days.
- **Flipkart:** the Affiliate API (search, product feeds) requires an approved affiliate account.
- **Croma, Reliance Digital, Tata CLiQ:** reached through networks such as Cuelinks. These networks give tracking links, not price feeds.
- **Program rules:** Amazon's and Flipkart's programme rules also limit mobile-app use without approval, and limit incentives or cashback for using affiliate links.

## Decision

1. All live data goes through `server/worker.js`, a Cloudflare Worker. API keys stay on the server, and the app only knows the Worker URL plus an app key.
2. **Phase A (now):** use SerpApi's Google Shopping India and Immersive Product APIs. These provide search with photos, the price at every store, offers, ratings, reviews and specs. Results are cached at the edge, for 30 minutes for searches and 2 hours for product pages.
3. Affiliate links are added on the server:
   - **Amazon links:** our Associates tag.
   - **Other stores:** the Cuelinks/EarnKaro wrapper template.
   - Store links are unwrapped from Google redirects first.
4. **Phase B:** once approved, add Amazon's Creators API and Flipkart's Affiliate API as extra sources for fresher prices and full coverage. The app does not change, because the Worker keeps the same response shape.
5. **AI:** Claude (claude-haiku-4-5 by default, configurable) is used for "Ask the Cat" and for product verdicts. It may use only the store and review data we pass in.
6. **Price history:** we record each product's lowest price daily in Workers KV, which builds our own price history over time.
7. Builds without `CC_API_BASE` run on the demo catalog, so tests and offline demos keep working.

## Consequences

- **Costs:** SerpApi credits (free up to 250 searches a month, then $25–$150 a month) and Claude usage (fractions of a rupee per question).
- **Wishlist alerts:** price alerts on Amazon items need Amazon's written OK (Operating Agreement, policy 31) before launch.
- **Cashback:** cashback to users is offered only on stores whose programme allows cashback traffic. It is never offered on Amazon or Flipkart direct links.
