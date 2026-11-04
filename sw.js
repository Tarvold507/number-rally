// Number Rally offline support.
// Bump VERSION whenever any file changes so tablets pick up the update.
const VERSION = 'nr-v12';
const FILES = [
  './',
  'index.html',
  'manifest.webmanifest',
  'icons/icon-192.png',
  'icons/icon-512.png',
  'icons/icon-maskable-512.png',
  'icons/apple-touch-icon.png',
  'fonts/atkinson-hyperlegible-mono-latin-400-normal.woff2',
  'fonts/atkinson-hyperlegible-mono-latin-600-normal.woff2',
  'fonts/atkinson-hyperlegible-mono-latin-700-normal.woff2',
  'fonts/atkinson-hyperlegible-mono-latin-800-normal.woff2'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => c.addAll(FILES)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== VERSION).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET' || new URL(req.url).origin !== location.origin) return;
  // The page itself: try the network first so updates arrive, fall back to the saved copy offline.
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(res => { const copy = res.clone(); caches.open(VERSION).then(c => c.put('index.html', copy)); return res; })
        .catch(() => caches.match('index.html'))
    );
    return;
  }
  // Fonts and icons: use the saved copy, fetch if missing.
  e.respondWith(caches.match(req).then(hit => hit || fetch(req)));
});
