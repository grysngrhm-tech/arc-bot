/**
 * ARC Bot Service Worker
 * Provides offline support and caching for the PWA
 */

const CACHE_NAME = 'arc-bot-v1.7';
const STATIC_CACHE = 'arc-bot-static-v1.7';
const DYNAMIC_CACHE = 'arc-bot-dynamic-v1.7';

// Assets to cache immediately on install
const PRECACHE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './assets/pinecone-logo.png',
  './assets/icons/icon-192.png',
  './assets/icons/icon-512.png',
  './assets/icons/apple-touch-icon.png',
  './assets/icons/favicon-32.png',
  './assets/icons/favicon-16.png'
];

// External resources to cache when fetched
const CACHEABLE_EXTERNAL = [
  'https://fonts.googleapis.com',
  'https://fonts.gstatic.com'
];

// Install event - precache static assets
self.addEventListener('install', (event) => {
  console.log('[SW] Installing service worker...');
  
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => {
        console.log('[SW] Precaching static assets');
        return cache.addAll(PRECACHE_ASSETS);
      })
      .then(() => {
        console.log('[SW] Installation complete');
        return self.skipWaiting();
      })
      .catch((error) => {
        console.error('[SW] Installation failed:', error);
      })
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating service worker...');
  
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames
            .filter((name) => {
              // Delete caches that don't match current version
              return name.startsWith('arc-bot-') && 
                     name !== STATIC_CACHE && 
                     name !== DYNAMIC_CACHE;
            })
            .map((name) => {
              console.log('[SW] Deleting old cache:', name);
              return caches.delete(name);
            })
        );
      })
      .then(() => {
        console.log('[SW] Activation complete');
        return self.clients.claim();
      })
  );
});

// Fetch event - serve from cache with network fallback
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // Skip non-GET requests
  if (request.method !== 'GET') {
    return;
  }
  
  // Skip API requests - always go to network
  if (url.hostname.includes('n8n.srv1208741.hstgr.cloud')) {
    event.respondWith(networkOnly(request));
    return;
  }
  
  // For same-origin requests - cache first, network fallback
  if (url.origin === self.location.origin) {
    event.respondWith(cacheFirst(request));
    return;
  }
  
  // For external fonts and resources - stale while revalidate
  if (CACHEABLE_EXTERNAL.some(domain => url.href.startsWith(domain))) {
    event.respondWith(staleWhileRevalidate(request));
    return;
  }
  
  // Default - network first with cache fallback
  event.respondWith(networkFirst(request));
});

// Cache-first strategy (for static assets)
async function cacheFirst(request) {
  const cachedResponse = await caches.match(request);
  if (cachedResponse) {
    return cachedResponse;
  }
  
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(STATIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    return offlineFallback(request);
  }
}

// Network-first strategy (for dynamic content)
async function networkFirst(request) {
  try {
    const networkResponse = await fetch(request);
    if (networkResponse.ok) {
      const cache = await caches.open(DYNAMIC_CACHE);
      cache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    const cachedResponse = await caches.match(request);
    if (cachedResponse) {
      return cachedResponse;
    }
    return offlineFallback(request);
  }
}

// Network-only strategy (for API calls)
async function networkOnly(request) {
  try {
    return await fetch(request);
  } catch (error) {
    // Return a JSON error response for API failures
    return new Response(
      JSON.stringify({
        error: 'offline',
        message: 'You appear to be offline. Please check your internet connection.'
      }),
      {
        status: 503,
        statusText: 'Service Unavailable',
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// Stale-while-revalidate strategy (for fonts)
async function staleWhileRevalidate(request) {
  const cache = await caches.open(DYNAMIC_CACHE);
  const cachedResponse = await cache.match(request);
  
  const fetchPromise = fetch(request)
    .then((networkResponse) => {
      if (networkResponse.ok) {
        cache.put(request, networkResponse.clone());
      }
      return networkResponse;
    })
    .catch(() => cachedResponse);
  
  return cachedResponse || fetchPromise;
}

// Offline fallback response
function offlineFallback(request) {
  // For navigation requests, return cached index.html
  if (request.mode === 'navigate') {
    return caches.match('./index.html');
  }
  
  // For other requests, return a generic offline response
  return new Response('Offline', {
    status: 503,
    statusText: 'Service Unavailable'
  });
}

// Handle messages from the main thread
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data && event.data.type === 'GET_VERSION') {
    event.ports[0].postMessage({ version: CACHE_NAME });
  }
});

