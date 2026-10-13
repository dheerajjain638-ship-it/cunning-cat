// Run: node --test server/   (Node 18+). Uses a fake fetch; no keys or network needed.
import test from 'node:test';
import assert from 'node:assert/strict';
import worker, { affiliateLink, normaliseResult, normaliseDetail, parseJsonLoose, handleAsk } from './worker.js';

const shopping = {
  shopping_results: [
    {
      title: 'Samsung Galaxy S25 5G (Navy, 256 GB)',
      product_id: '123',
      immersive_product_page_token: 'tok123',
      thumbnail: 'https://img.example/s25.jpg',
      extracted_price: 74999,
      extracted_old_price: 80999,
      source: 'Croma',
      rating: 4.5,
      reviews: 2310,
      multiple_sources: true,
    },
    { title: 'No price item' },
    { title: 'Samsung Galaxy S25 5G (Navy, 256 GB)', product_id: '123', extracted_price: 75999 },
    { title: 'Galaxy S25 case', product_id: '9', extracted_price: '₹499', source: 'Amazon.in' },
  ],
};

const immersive = {
  product_results: {
    title: 'Samsung Galaxy S25',
    thumbnails: ['a.jpg', 'b.jpg'],
    rating: 4.5,
    reviews: 2310,
    ratings: [{ stars: 5, amount: 1500 }],
    stores: [
      { name: 'Flipkart', link: 'https://www.flipkart.com/p/1', extracted_price: 73999, details_and_offers: ['Bank offer'] },
      { name: 'Amazon.in', link: 'https://www.amazon.in/dp/B0X', extracted_price: 74499 },
      { name: 'No price store' },
    ],
    about_the_product: { features: [{ title: 'Display', value: '6.2 in' }] },
    top_insights: [{ items: [{ key_point: 'Great camera', pros: ['sharp'], cons: [] }] }],
    user_reviews: [{ title: 'Nice', text: 'Love it', rating: 5 }],
  },
};

function fakeFetch(claudeReplies = []) {
  const calls = [];
  globalThis.fetch = async (url, init) => {
    calls.push(String(url));
    const u = String(url);
    let body;
    if (u.includes('engine=google_shopping')) body = shopping;
    else if (u.includes('engine=google_immersive_product')) body = immersive;
    else if (u.includes('api.anthropic.com')) body = { content: [{ type: 'text', text: claudeReplies.shift() }] };
    else body = { error: 'unknown' };
    return new Response(JSON.stringify(body), { status: 200, headers: { 'content-type': 'application/json' } });
  };
  return calls;
}

const env = { SERPAPI_KEY: 's', ANTHROPIC_API_KEY: 'a', APP_KEY: 'k', AMAZON_TAG: 'cat-21',
  AFFILIATE_TEMPLATE: 'https://linksredirect.com/?cid=1&url={url}' };
const ctx = { waitUntil() {} };
const req = (path, init = {}) => new Request(`https://w.example${path}`, { ...init, headers: { 'x-cc-key': 'k', ...(init.headers || {}) } });

test('affiliate links: amazon gets tag, others wrapped, google redirects unwrapped', () => {
  assert.equal(affiliateLink('https://www.amazon.in/dp/B0X?th=1', env), 'https://www.amazon.in/dp/B0X?th=1&tag=cat-21');
  assert.equal(
    affiliateLink('https://www.google.com/url?url=https%3A%2F%2Fwww.croma.com%2Fp%2F1', env),
    'https://linksredirect.com/?cid=1&url=' + encodeURIComponent('https://www.croma.com/p/1'),
  );
  assert.equal(affiliateLink('https://www.croma.com/p/1', {}), 'https://www.croma.com/p/1');
});

test('normaliseResult keeps image, price and store; drops items without price', () => {
  const p = normaliseResult(shopping.shopping_results[0], env);
  assert.equal(p.price, 74999);
  assert.equal(p.image, 'https://img.example/s25.jpg');
  assert.equal(p.token, 'tok123');
  assert.equal(normaliseResult(shopping.shopping_results[1]), null);
  assert.equal(normaliseResult(shopping.shopping_results[3]).price, 499);
});

test('normaliseDetail sorts stores cheapest first and drops priceless ones', () => {
  const d = normaliseDetail(immersive.product_results, env);
  assert.deepEqual(d.stores.map((s) => s.name), ['Flipkart', 'Amazon.in']);
  assert.ok(d.stores[1].link.endsWith('tag=cat-21'));
  assert.equal(d.insights[0].point, 'Great camera');
  assert.equal(d.features[0].name, 'Display');
});

test('search endpoint requires the app key and de-duplicates results', async () => {
  fakeFetch();
  const denied = await worker.fetch(new Request('https://w.example/search?q=s25'), env, ctx);
  assert.equal(denied.status, 401);
  const res = await worker.fetch(req('/search?q=s25'), env, ctx);
  const body = await res.json();
  assert.equal(res.status, 200);
  assert.equal(body.products.length, 2);
});

test('product endpoint returns stores', async () => {
  fakeFetch();
  const res = await worker.fetch(req('/product?token=tok123'), env, ctx);
  const body = await res.json();
  assert.equal(body.stores[0].price, 73999);
});

test('ask: AI query -> search -> picks', async () => {
  fakeFetch([
    '{"reply":"Here are strong picks.","query":"samsung galaxy s25","maxPrice":80000,"minPrice":null,"priorities":["camera"]}',
    'Sure! {"summary":"The S25 is the pick.","picks":[{"index":0,"why":"Top rated, under budget"},{"index":7,"why":"bad index"}]}',
  ]);
  const out = await handleAsk({ message: 'best samsung phone under 80k', history: [{ role: 'assistant', text: 'hi' }] }, env);
  assert.equal(out.query, 'samsung galaxy s25');
  assert.equal(out.picks.length, 1);
  assert.equal(out.picks[0].id, '123');
  assert.ok(out.reply.includes('S25'));
});

test('ask: clarifying question returns no products', async () => {
  fakeFetch(['{"reply":"What is your budget?","query":null}']);
  const out = await handleAsk({ message: 'need a laptop' }, env);
  assert.equal(out.products.length, 0);
  assert.equal(out.reply, 'What is your budget?');
});

test('parseJsonLoose tolerates text around JSON', () => {
  assert.deepEqual(parseJsonLoose('ok {"a":1} done'), { a: 1 });
});

test('missing keys give a clear 503', async () => {
  fakeFetch();
  const res = await worker.fetch(new Request('https://w.example/search?q=x'), {}, ctx);
  assert.equal(res.status, 503);
});
