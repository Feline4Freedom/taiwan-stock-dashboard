/* Service Worker — 台股全景儀表板
   - cache-first 策略，初次載入後即可離線使用
   - 版本變更時自動清掉舊快取
*/
const CACHE = 'tw-stock-v3-1975';
const ASSETS = [
  './',
  './index.html',
  './data.js',
  './manifest.json',
  './icon.svg',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png',
  'https://cdnjs.cloudflare.com/ajax/libs/vis-network/9.1.6/standalone/umd/vis-network.min.js',
];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(ASSETS).catch(()=>{}))
  );
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(
      keys.filter(k => k !== CACHE).map(k => caches.delete(k))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // 對於 GoodInfo / Yahoo 等外部連結，不快取
  if(url.host.includes('goodinfo') || url.host.includes('yahoo') ||
     url.host.includes('twse') || url.host.includes('cnyes') ||
     url.host.includes('histock') || url.host.includes('wantgoo')){
    return; // 走網路
  }
  e.respondWith(
    caches.match(e.request).then(cached => {
      if(cached) return cached;
      return fetch(e.request).then(resp => {
        // 動態快取同源資源
        if(resp.ok && (url.origin === location.origin || url.host.includes('cdnjs'))){
          const clone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone));
        }
        return resp;
      }).catch(() => caches.match('./index.html'));
    })
  );
});
