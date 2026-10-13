# Cunning Cat API (Cloudflare Worker)

The app never holds API keys. It calls this small server, and the server calls:

- **SerpApi (Google Shopping India):** live prices, product photos, every store's price, ratings, reviews and specs.
- **Claude API:** "Ask the Cat" chat and the AI verdict on each product.

Repeat searches are cached at Cloudflare's edge for 30 minutes, so they don't use up SerpApi credits.

## One-time setup (about 15 minutes)

1. **SerpApi:** sign up at serpapi.com. The free plan gives 250 searches a month, which is enough for testing. Copy your API key from the dashboard.
2. **Claude API:** sign up at console.anthropic.com, add a small credit (for example $5), then go to **API keys** → **Create key**.
3. **Cloudflare:** sign up at dash.cloudflare.com (free).
   1. Go to **Workers & Pages** → **Create** → **Create Worker**, name it `cunning-cat-api`, and click **Deploy**.
   2. Click **Edit code**, delete everything, paste the whole of `worker.js`, and click **Deploy**.
   3. Go to **Settings** → **Variables and secrets** and add:
      - `SERPAPI_KEY` (Secret): your SerpApi key
      - `ANTHROPIC_API_KEY` (Secret): your Claude key
      - `APP_KEY` (Secret): any long random text, for example 32 letters and digits
      - `AMAZON_TAG` (Text, optional): your Amazon Associates tag, for example `cunningcat-21`
      - `AFFILIATE_TEMPLATE` (Text, optional): your Cuelinks/EarnKaro link pattern, with `{url}` where the product link goes
   4. Optional, for price history: go to **Storage & Databases** → **KV** → **Create** a namespace named `cunning-cat-prices`. Then, in the Worker, open **Settings** → **Bindings** → **Add** → **KV namespace**, set the variable name to `PRICES`, and select that namespace.
   5. Copy the Worker URL, for example `https://cunning-cat-api.<you>.workers.dev`. Open `<url>/health` and check that it shows `"live":true,"ai":true`.
4. **GitHub repo:** go to **Settings** → **Secrets and variables** → **Actions**.
   - On the **Variables** tab, create `CC_API_BASE` = the Worker URL.
   - On the **Secrets** tab, create `CC_APP_KEY` = the same value as `APP_KEY`.
   - The next CI build produces a **live** APK. Without these settings, the APK stays in demo mode.

## Endpoints

| Path | What it returns |
|---|---|
| `GET /health` | Whether the live and AI keys are set |
| `GET /search?q=` | Products with photo, price, discount, store, rating |
| `GET /product?token=` | Every store's price (cheapest first), offers, photos, reviews, specs, our price history |
| `GET /insights?token=` | AI verdict (buy, wait, or consider alternatives), pros, cons, who it suits |
| `POST /ask` | Ask the Cat: understands the need, searches, and picks the best 3 with reasons |

Every call except `/health` needs the header `x-cc-key: <APP_KEY>`.

## Tests

`node --test server/worker.test.mjs` (Node 18 or later; uses a fake network, so no keys are needed).
