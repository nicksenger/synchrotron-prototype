const filesToCache = [
    'index.html',
    'bundle.css',
    'bundle.js'
];
const staticCacheName = `${process.env.TITLE}-v1`;

async function cacheAndReturn(event: FetchEvent) {
    const url = event.request.url;
    const response = await fetch(event.request);
    const cache = await caches.open(staticCacheName);
    if (!url.includes('test')) {
        cache.put(url, response.clone());
    }
    return response;
}

const initialize = (service: ServiceWorkerGlobalScope): void => {
    service.addEventListener('install', function () {
        caches
            .open(staticCacheName)
            .then((cache) => cache.addAll(filesToCache));
    });
    
    service.addEventListener('fetch', event => {
        const url = event.request.url;
        if (Boolean(filesToCache.filter(f => url.endsWith(f)).length)) {
            event.respondWith(cacheAndReturn(event));
        } else {
            caches.match(event.request).then(cached => {
                if (cached) {
                    event.respondWith(cached);
                } else {
                    event.respondWith(cacheAndReturn(event));
                }
            }).catch(function (error: Error) {
                // do something when offline
            });
        }
    });
}

initialize(self as any);
