const currentUrl = new URL(self.location.href);
const swVersion = currentUrl.searchParams.get('v') || 'base';
const engineRevision = currentUrl.searchParams.get('engine') || 'base';

const ENTRY_CACHE = `igames-entry-${swVersion}`;
const RUNTIME_CACHE = `igames-runtime-${swVersion}`;
const STATIC_CACHE = `igames-static-${swVersion}`;
const CANVASKIT_CACHE = `igames-canvaskit-${engineRevision}`;
const OWNED_CACHE_PREFIXES = [
  'igames-entry-',
  'igames-runtime-',
  'igames-static-',
  'igames-canvaskit-',
];
const LEGACY_CACHE_NAMES = [
  'flutter-app-cache',
  'flutter-temp-cache',
  'flutter-app-manifest',
];

const NETWORK_FIRST_PATHS = new Set([
  '/index.html',
  '/flutter_bootstrap.js',
  '/version.json',
  '/manifest.json',
]);

self.addEventListener('install', () => {});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      await cleanupOldCaches();
      await self.clients.claim();
    })(),
  );
});

self.addEventListener('message', (event) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const {request} = event;
  if (request.method !== 'GET') {
    return;
  }

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) {
    return;
  }

  if (request.mode === 'navigate') {
    event.respondWith(handleNavigationRequest(request));
    return;
  }

  if (NETWORK_FIRST_PATHS.has(url.pathname)) {
    event.respondWith(networkFirst(request, ENTRY_CACHE));
    return;
  }

  if (shouldUseCanvaskitCacheFirst(url.pathname)) {
    event.respondWith(cacheFirst(request, CANVASKIT_CACHE));
    return;
  }

  if (shouldUseRuntimeNetworkFirst(url.pathname)) {
    event.respondWith(networkFirst(request, RUNTIME_CACHE));
    return;
  }

  if (shouldUseFrameworkCacheFirst(url.pathname)) {
    event.respondWith(cacheFirst(request, STATIC_CACHE));
    return;
  }

  if (shouldUseAssetStaleWhileRevalidate(url.pathname)) {
    event.respondWith(staleWhileRevalidate(request, STATIC_CACHE));
  }
});

async function handleNavigationRequest(request) {
  const cache = await caches.open(ENTRY_CACHE);
  const networkRequest = buildFreshRequest(request);

  try {
    const response = await fetch(networkRequest);
    if (isCacheable(response)) {
      await cache.put('/index.html', response.clone());
    }
    return response;
  } catch (error) {
    const cached = await cache.match('/index.html');
    if (cached) {
      return cached;
    }
    throw error;
  }
}

async function networkFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const networkRequest = buildFreshRequest(request);

  try {
    const response = await fetch(networkRequest);
    if (isCacheable(response)) {
      await cache.put(request, response.clone());
    }
    return response;
  } catch (error) {
    const cached = await cache.match(request);
    if (cached) {
      return cached;
    }
    throw error;
  }
}

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) {
    return cached;
  }

  const response = await fetch(request);
  if (isCacheable(response)) {
    await cache.put(request, response.clone());
  }
  return response;
}

async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);

  const networkPromise = fetch(request)
    .then(async (response) => {
      if (isCacheable(response)) {
        await cache.put(request, response.clone());
      }
      return response;
    })
    .catch(() => null);

  if (cached) {
    return cached;
  }

  const networkResponse = await networkPromise;
  if (networkResponse) {
    return networkResponse;
  }

  throw new Error(`Failed to load resource: ${request.url}`);
}

function shouldUseFrameworkCacheFirst(pathname) {
  return pathname === '/favicon.png' || pathname.startsWith('/icons/');
}

function shouldUseCanvaskitCacheFirst(pathname) {
  return pathname.startsWith('/canvaskit/');
}

function shouldUseAssetStaleWhileRevalidate(pathname) {
  return pathname.startsWith('/assets/');
}

function buildFreshRequest(request) {
  try {
    return new Request(request, {cache: 'no-cache'});
  } catch (_) {
    return request;
  }
}

function shouldUseRuntimeNetworkFirst(pathname) {
  const lowerPathname = pathname.toLowerCase();
  return (
    pathname === '/main.dart.js' ||
    pathname === '/main.dart.mjs' ||
    pathname === '/main.dart.wasm' ||
    pathname === '/flutter.js' ||
    lowerPathname.endsWith('.mjs') ||
    lowerPathname.endsWith('.wasm')
  );
}

function isCacheable(response) {
  return response && response.ok;
}

async function cleanupOldCaches() {
  const cacheKeys = await caches.keys();
  const currentCaches = new Set([
    ENTRY_CACHE,
    RUNTIME_CACHE,
    STATIC_CACHE,
    CANVASKIT_CACHE,
  ]);

  await Promise.all(
    cacheKeys.map((cacheName) => {
      const isOwnedCache = OWNED_CACHE_PREFIXES.some((prefix) =>
        cacheName.startsWith(prefix),
      );
      const isLegacyCache = LEGACY_CACHE_NAMES.some(
        (legacyName) => cacheName === legacyName,
      );

      if ((isOwnedCache || isLegacyCache) && !currentCaches.has(cacheName)) {
        return caches.delete(cacheName);
      }

      return Promise.resolve(false);
    }),
  );
}
