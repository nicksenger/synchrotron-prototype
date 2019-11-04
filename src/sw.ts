const filesToCache = [
    "/",
    '/index.html',
    '/bundle.css',
    '/bundle.js',
    process.env.DATA_PATH as string
];

const staticCacheName = `${process.env.TITLE}-v1`;

async function fetchWithFallback(event: FetchEvent) {
    const url = event.request.url;
    try {
        const response = await fetch(event.request);
        const cache = await caches.open(staticCacheName);
        cache.put(url, response.clone());
        return response;
    } catch (_e) {
        const cached = await caches.match(event.request);
        if (cached) {
            return cached;
        }
        return fetch(event.request);
    }
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
            event.respondWith(fetchWithFallback(event));
        } else {
            event.respondWith(
                caches.match(event.request).then(cached => {
                    if (cached) {
                        return cached;
                    } else {
                        return fetchWithFallback(event);
                    }
                })
            )
        }
    });
}

initialize(self as any);
