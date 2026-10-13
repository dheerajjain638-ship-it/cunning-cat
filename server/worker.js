// Cunning Cat API: a Cloudflare Worker that sits between the app and paid data APIs.
//
// Why a server at all: the SerpApi and Claude API keys must never ship inside the app.
// The app only knows this Worker's URL and a shared APP_KEY.
//
// Endpoints (all JSON, all need header `x-cc-key: <APP_KEY>`):
//   GET  /health                     -> { ok, live, ai }
//   GET  /search?q=...&page=0        -> { query, products: [LiveProduct] }   (Google Shopping India)
//   GET  /product?token=...          -> LiveDetail (all stores, photos, reviews, specs, price history)
//   GET  /insights?token=...         -> AI verdict, pros, cons, who it suits     (Claude)
//   POST /ask  { message, history }  -> { reply, query, products, picks }        (Claude + search)
//
// Settings (Cloudflare dashboard -> Worker -> Settings -> Variables and secrets):
//   SERPAPI_KEY        secret  SerpApi key (live prices, photos, stores, reviews)
//   ANTHROPIC_API_KEY  secret  Claude API key (Ask the Cat, AI verdicts). Optional.
//   APP_KEY            secret  Any long random string; the same value goes into the app build.
//   CLAUDE_MODEL       text    Optional. Defaults to claude-haiku-4-5.
//   AMAZON_TAG         text    Optional. Your Amazon Associates tag, e.g. cunningcat-21.
//   AFFILIATE_TEMPLATE text    Optional. Wraps every other store link, e.g. a Cuelinks link:
//                              https://linksredirect.com/?cid=YOURCID&source=linkkit&url={url}
//   PRICES             KV      Optional KV namespace binding; stores daily lowest prices for history.

const SEARCH_TTL = 60 * 30; // 30 min: prices move, but not every minute
const PRODUCT_TTL = 60 * 60 * 2;
const INSIGHT_TTL = 60 * 60 * 24;

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') return cors(new Response(null, { status: 204 }));
    const url = new URL(request.url);
    try {
      if (url.pathname === '/health') {
        return json({ ok: true, live: !!env.SERPAPI_KEY, ai: !!env.ANTHROPIC_API_KEY });
      }
      if (env.APP_KEY && request.headers.get('x-cc-key') !== env.APP_KEY) {
        return json({ error: 'unauthorised' }, 401);
      }
      switch (url.pathname) {
        case '/search':
          return await cached(request, ctx, SEARCH_TTL, () => handleSearch(url, env));
        case '/product':
          return await cached(request, ctx, PRODUCT_TTL, () => handleProduct(url, env, ctx));
        case '/insights':
          return await cached(request, ctx, INSIGHT_TTL, () => handleInsights(url, env));
        case '/ask':
          if (request.method !== 'POST') return json({ error: 'POST only' }, 405);
          return json(await handleAsk(await request.json(), env));
        default:
          return json({ error: 'not found' }, 404);
      }
    } catch (e) {
      return json({ error: String(e && e.message ? e.message : e) }, e && e.status ? e.status : 500);
    }
  },
};

// ---------------------------------------------------------------- search

export async function searchProducts(query, env, page = 0) {
  if (!env.SERPAPI_KEY) throw httpError(503, 'Live search is not configured (SERPAPI_KEY missing).');
  const params = new URLSearchParams({
    engine: 'google_shopping',
    q: query,
    gl: 'in',
    hl: 'en',
    google_domain: 'google.co.in',
    location: 'India',
    api_key: env.SERPAPI_KEY,
  });
  if (page > 0) params.set('start', String(page * 40));
  const data = await getJson(`https://serpapi.com/search.json?${params}`);
  if (data.error && !/hasn't returned any results/i.test(data.error)) throw httpError(502, data.error);
  const raw = [...(data.shopping_results || []), ...(data.inline_shopping_results || [])];
  const seen = new Set();
  const products = [];
  for (const r of raw) {
    const p = normaliseResult(r, env);
    if (!p || seen.has(p.id)) continue;
    seen.add(p.id);
    products.push(p);
  }
  return products;
}

export function normaliseResult(r, env = {}) {
  const price = num(r.extracted_price);
  if (!r.title || price == null) return null;
  const token = r.immersive_product_page_token || null;
  const link = r.link || r.product_link || null;
  return {
    id: String(r.product_id || token || r.title).slice(0, 200),
    token,
    title: r.title,
    image: r.serpapi_thumbnail || r.thumbnail || (r.thumbnails && r.thumbnails[0]) || null,
    price,
    oldPrice: num(r.extracted_old_price),
    store: r.source || null,
    storeIcon: r.source_icon || null,
    rating: num(r.rating),
    reviews: num(r.reviews),
    multipleStores: !!r.multiple_sources,
    delivery: r.delivery || null,
    tag: r.tag || null,
    link: link ? affiliateLink(link, env) : null,
  };
}

async function handleSearch(url, env) {
  const q = (url.searchParams.get('q') || '').trim();
  if (!q) throw httpError(400, 'q is required');
  const page = Number(url.searchParams.get('page') || 0) || 0;
  return { query: q, products: await searchProducts(q, env, page) };
}

// ---------------------------------------------------------------- product

export async function productDetail(token, env) {
  if (!env.SERPAPI_KEY) throw httpError(503, 'Live search is not configured (SERPAPI_KEY missing).');
  const params = new URLSearchParams({
    engine: 'google_immersive_product',
    page_token: token,
    more_stores: 'true',
    api_key: env.SERPAPI_KEY,
  });
  const data = await getJson(`https://serpapi.com/search.json?${params}`);
  if (data.error) throw httpError(502, data.error);
  return normaliseDetail(data.product_results || {}, env);
}

export function normaliseDetail(p, env = {}) {
  const stores = (p.stores || [])
    .map((s) => ({
      name: s.name || 'Store',
      logo: s.logo || null,
      link: s.link ? affiliateLink(s.link, env) : null,
      price: num(s.extracted_price),
      oldPrice: num(s.extracted_original_price),
      total: num(s.extracted_total),
      offers: [...(s.details_and_offers || []), s.coupon, s.discount].filter(Boolean).map(String),
      rating: num(s.rating),
      reviews: num(s.reviews),
      tag: s.tag || null,
      shipping: s.shipping || null,
      emi: s.installments_description || null,
    }))
    .filter((s) => s.price != null)
    .sort((a, b) => a.price - b.price);
  const insights = [];
  for (const group of p.top_insights || []) {
    for (const item of group.items || []) {
      insights.push({
        point: item.key_point || item.title || '',
        snippet: item.snippet || '',
        pros: item.pros || [],
        cons: item.cons || [],
        source: item.source || null,
      });
    }
  }
  return {
    title: p.title || '',
    brand: p.brand || null,
    images: (p.thumbnails || []).slice(0, 8),
    rating: num(p.rating),
    reviews: num(p.reviews),
    priceRange: p.price_range || null,
    ratings: (p.ratings || []).map((r) => ({ stars: r.stars, count: r.amount })),
    stores,
    features: ((p.about_the_product && p.about_the_product.features) || [])
      .map((f) => ({ name: f.title, value: f.value }))
      .slice(0, 12),
    description: (p.about_the_product && p.about_the_product.description) || null,
    insights: insights.slice(0, 8),
    userReviews: (p.user_reviews || []).slice(0, 6).map((r) => ({
      title: r.title || '',
      text: r.text || '',
      rating: num(r.rating),
      user: r.user_name || null,
      source: r.source || null,
      date: r.date || null,
    })),
    criticRatings: (p.critic_ratings || []).map((c) => ({ name: c.name, rating: c.rating })),
    history: [],
  };
}

async function handleProduct(url, env, ctx) {
  const token = url.searchParams.get('token');
  if (!token) throw httpError(400, 'token is required');
  const detail = await productDetail(token, env);
  if (env.PRICES && detail.stores.length) {
    const key = 'p:' + (await hash(detail.title.toLowerCase()));
    const history = (await env.PRICES.get(key, 'json')) || [];
    const today = new Date().toISOString().slice(0, 10);
    const low = detail.stores[0].price;
    const last = history[history.length - 1];
    if (!last || last.d !== today) history.push({ d: today, p: low });
    else last.p = Math.min(last.p, low);
    const trimmed = history.slice(-180);
    ctx.waitUntil(env.PRICES.put(key, JSON.stringify(trimmed)));
    detail.history = trimmed;
  }
  return detail;
}

// ---------------------------------------------------------------- AI

async function claude(env, system, messages, maxTokens = 900) {
  if (!env.ANTHROPIC_API_KEY) throw httpError(503, 'AI is not configured (ANTHROPIC_API_KEY missing).');
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      model: env.CLAUDE_MODEL || 'claude-haiku-4-5',
      max_tokens: maxTokens,
      system,
      messages,
    }),
  });
  const data = await res.json();
  if (!res.ok) throw httpError(502, (data.error && data.error.message) || 'AI request failed');
  const text = (data.content || []).filter((c) => c.type === 'text').map((c) => c.text).join('');
  return parseJsonLoose(text);
}

export function parseJsonLoose(text) {
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start < 0 || end <= start) throw httpError(502, 'AI returned no JSON');
  return JSON.parse(text.slice(start, end + 1));
}

const INSIGHT_SYSTEM = `You are Cunning Cat, an honest shopping advisor for buyers in India.
Use ONLY the product data given. Never invent specs, prices or reviews. Prices are in Indian rupees.
Reply with JSON only:
{"verdict":"buy"|"wait"|"consider_alternatives","headline":"<= 12 words","summary":"2 short sentences",
 "pros":["<= 8 words", ...max 4],"cons":["<= 8 words", ...max 3],
 "bestFor":"<= 12 words","skipIf":"<= 12 words","priceAdvice":"1 sentence on the store prices"}`;

async function handleInsights(url, env) {
  const token = url.searchParams.get('token');
  if (!token) throw httpError(400, 'token is required');
  const d = await productDetail(token, env);
  const facts = {
    title: d.title,
    rating: d.rating,
    reviews: d.reviews,
    ratings: d.ratings,
    stores: d.stores.slice(0, 8).map((s) => ({ store: s.name, price: s.price, was: s.oldPrice, offers: s.offers.slice(0, 3) })),
    features: d.features,
    insights: d.insights,
    reviewsSample: d.userReviews.map((r) => ({ rating: r.rating, title: r.title, text: (r.text || '').slice(0, 400) })),
  };
  const out = await claude(env, INSIGHT_SYSTEM, [{ role: 'user', content: JSON.stringify(facts) }], 700);
  return { ...out, generatedAt: new Date().toISOString() };
}

const ASK_SYSTEM = `You are Cunning Cat, a friendly, sharp shopping assistant for buyers in India (prices in rupees).
Step 1 of 2. Understand what the person wants and turn it into ONE Google Shopping search query.
Reply with JSON only:
{"reply":"1-2 sentences, warm and specific; ask one short question only if the need is truly unclear",
 "query": "search words, or null if you must ask first",
 "maxPrice": number or null, "minPrice": number or null,
 "priorities": ["camera", "battery", ...max 4]}`;

const PICK_SYSTEM = `You are Cunning Cat. Step 2 of 2. From the numbered products, pick the best 3 for this person.
Use only the given data (price, rating, review count, store). Prefer well-reviewed items within budget.
Reply with JSON only:
{"summary":"1-2 sentences","picks":[{"index":n,"why":"<= 14 words"}]}`;

export async function handleAsk(body, env) {
  const message = String((body && body.message) || '').trim().slice(0, 600);
  if (!message) throw httpError(400, 'message is required');
  const history = Array.isArray(body.history) ? body.history.slice(-6) : [];
  const messages = [
    ...history
      .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && m.text)
      .map((m) => ({ role: m.role, content: String(m.text).slice(0, 600) })),
    { role: 'user', content: message },
  ];
  // Claude requires the first message to be from the user.
  while (messages.length && messages[0].role !== 'user') messages.shift();
  const intent = await claude(env, ASK_SYSTEM, messages, 400);
  if (!intent.query) return { reply: intent.reply, query: null, products: [], picks: [] };

  let products = await searchProducts(intent.query, env);
  const max = num(intent.maxPrice);
  const min = num(intent.minPrice);
  const inBudget = products.filter((p) => (max == null || p.price <= max * 1.03) && (min == null || p.price >= min));
  if (inBudget.length >= 3) products = inBudget;
  products = products.slice(0, 12);
  if (!products.length) return { reply: intent.reply, query: intent.query, products: [], picks: [] };

  const list = products.map((p, i) => ({ index: i, title: p.title, price: p.price, rating: p.rating, reviews: p.reviews, store: p.store }));
  let picks = [];
  let summary = intent.reply;
  try {
    const out = await claude(
      env,
      PICK_SYSTEM,
      [{ role: 'user', content: JSON.stringify({ need: message, priorities: intent.priorities || [], products: list }) }],
      500,
    );
    picks = (out.picks || [])
      .filter((p) => Number.isInteger(p.index) && p.index >= 0 && p.index < products.length)
      .slice(0, 3)
      .map((p) => ({ id: products[p.index].id, why: String(p.why || '') }));
    if (out.summary) summary = `${intent.reply} ${out.summary}`.trim();
  } catch (_) {
    // Picks are a bonus; the search results still answer the question.
  }
  return { reply: summary, query: intent.query, products, picks };
}

// ---------------------------------------------------------------- affiliate links

/** Turns a store link into our affiliate link. Google redirect links are unwrapped first. */
export function affiliateLink(link, env = {}) {
  let target = link;
  try {
    const u = new URL(link);
    if (/(^|\.)google\./.test(u.hostname)) {
      const inner = u.searchParams.get('url') || u.searchParams.get('q') || u.searchParams.get('adurl');
      if (inner && /^https?:\/\//.test(inner)) target = inner;
    }
    const t = new URL(target);
    if (/(^|\.)amazon\.in$/.test(t.hostname)) {
      if (env.AMAZON_TAG) {
        t.searchParams.set('tag', env.AMAZON_TAG);
        return t.toString();
      }
      return target;
    }
  } catch (_) {
    return link;
  }
  if (env.AFFILIATE_TEMPLATE && /^https?:\/\//.test(target) && !/google\./.test(new URL(target).hostname)) {
    return env.AFFILIATE_TEMPLATE.replace('{url}', encodeURIComponent(target));
  }
  return target;
}

// ---------------------------------------------------------------- helpers

function num(v) {
  if (v == null || v === '') return null;
  const n = typeof v === 'number' ? v : Number(String(v).replace(/[^0-9.]/g, ''));
  return Number.isFinite(n) ? n : null;
}

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

async function getJson(u) {
  const res = await fetch(u);
  const data = await res.json().catch(() => ({}));
  if (!res.ok && !data.error) throw httpError(502, `Upstream error ${res.status}`);
  return data;
}

async function hash(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].slice(0, 12).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function cors(res) {
  res.headers.set('access-control-allow-origin', '*');
  res.headers.set('access-control-allow-headers', 'content-type, x-cc-key');
  res.headers.set('access-control-allow-methods', 'GET, POST, OPTIONS');
  return res;
}

function json(body, status = 200, maxAge = 0) {
  const res = new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
  if (maxAge) res.headers.set('cache-control', `public, max-age=${maxAge}`);
  return cors(res);
}

/** Serves GET responses from Cloudflare's edge cache so repeat searches cost nothing. */
async function cached(request, ctx, ttl, produce) {
  const cache = typeof caches !== 'undefined' ? caches.default : null;
  const key = new Request(new URL(request.url).toString(), { method: 'GET' });
  if (cache) {
    const hit = await cache.match(key);
    if (hit) return hit;
  }
  const res = json(await produce(), 200, ttl);
  if (cache) ctx.waitUntil(cache.put(key, res.clone()));
  return res;
}
