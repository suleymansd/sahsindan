const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const ts = require('typescript');

function loadApi(fetch, env = { NEXT_PUBLIC_API_URL: '/api' }) {
  const exports = {};
  const events = [];
  const context = {
    exports, fetch, Headers, FormData, AbortSignal, CustomEvent, Error, TypeError,
    process: { env },
    window: { location: { origin: 'https://market.example', pathname: '/ilanlar', search: '', href: '' }, dispatchEvent: (event) => events.push(event.type) },
  };
  const code = ts.transpileModule(fs.readFileSync('lib/api.ts', 'utf8'), { compilerOptions: { module: ts.ModuleKind.CommonJS } }).outputText;
  vm.runInNewContext(code, context);
  return { ...exports, context, events };
}
const response = (status, data) => new Response(JSON.stringify(data), {status, headers: {'Content-Type': 'application/json'}});

test('same-origin configuration resolves HTTPS API', () => {
  assert.equal(loadApi(() => {}).API_URL, 'https://market.example/api');
});

test('production without a backend never sends credentials or refresh requests', async () => {
  let calls = 0;
  const api = loadApi(() => { calls++; }, { NODE_ENV: 'production' });
  assert.equal(api.API_CONFIGURED, false);
  assert.equal(api.API_URL, '');
  await assert.rejects(() => api.apiFetch('/auth/login', {method: 'POST', body: 'private'}), /henüz açık değil/);
  await assert.rejects(() => api.refreshSession(), /henüz açık değil/);
  assert.equal(calls, 0);
});

test('explicit backend enables production and normalizes trailing slash', () => {
  const api = loadApi(() => {}, {NODE_ENV: 'production', NEXT_PUBLIC_API_URL: 'https://api.market.example/api/'});
  assert.equal(api.API_CONFIGURED, true);
  assert.equal(api.API_URL, 'https://api.market.example/api');
});

test('development keeps local backend fallback', () => {
  assert.equal(loadApi(() => {}, {NODE_ENV: 'development'}).API_URL, 'http://127.0.0.1:8080/api');
});

test('concurrent refresh callers share one network request', async () => {
  let requests = 0;
  const api = loadApi(async () => { requests++; return response(200, {data: {access_token: 'new'}}); });
  await Promise.all([api.refreshSession(), api.refreshSession(), api.refreshSession()]);
  assert.equal(requests, 1);
});

test('temporary refresh outage preserves the session and does not retry endlessly', async () => {
  const api = loadApi(async (url) => response(url.endsWith('/auth/refresh') ? 503 : 401, {error: {message: 'Temporary outage'}}));
  await assert.rejects(() => api.apiFetch('/listings', {headers: {Authorization: 'Bearer old'}}), /Temporary outage/);
  assert.deepEqual(api.events, []);
  assert.equal(api.context.window.location.href, '');
});

test('authenticated request refreshes and retries once using the new token', async () => {
  const requests = [];
  const api = loadApi(async (url, init) => {
    requests.push([url, init.headers.get('Authorization')]);
    if (url.endsWith('/auth/refresh')) return response(200, {data: {access_token: 'new'}});
    return init.headers.get('Authorization') === 'Bearer new' ? response(200, {data: []}) : response(401, {});
  });
  await api.apiFetch('/listings', {headers: {Authorization: 'Bearer old'}});
  assert.equal(requests.length, 3);
  assert.equal(requests.at(-1)[1], 'Bearer new');
  assert.deepEqual(api.events, ['auth:token']);
});

test('rate limit errors produce no automatic network retry', async () => {
  let requests = 0;
  const api = loadApi(async () => { requests++; return response(429, {error: {message: 'Too many requests'}}); });
  await assert.rejects(() => api.apiFetch('/listings'), /Too many requests/);
  assert.equal(requests, 1);
});
