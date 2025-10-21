'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "cd30af31f5e6374abe3eaa40796215da",
"assets/AssetManifest.bin.json": "3854819744143fcb5ca58c95bcaea870",
"assets/AssetManifest.json": "8f9947d399cb74824130f93ca2cf1d9e",
"assets/assets/fonts/PressStart2P.ttf": "74496d9086d97aaeeafb3085e9957668",
"assets/assets/images/1.png": "862a34cfb6de01ffdb1e82a78ffb35f3",
"assets/assets/images/10.png": "3ef3c62c534312c853ddfa4d7a5f1ae2",
"assets/assets/images/11.png": "f70ddb863fa8122d9690f5baaaab64f8",
"assets/assets/images/12.png": "f01472679c9d5686a8d4c54c8a165f7c",
"assets/assets/images/2.png": "1baa4c833e7753b70594e072eb05e519",
"assets/assets/images/3.png": "8f5952e50cdd6e4fdef5bad2758fc7cd",
"assets/assets/images/4.png": "7bf0fbd2c5946db907cb47c6a55d9c50",
"assets/assets/images/5.png": "1b2cb13c51d5ff601232c618d411edf3",
"assets/assets/images/6.png": "7da971fac4128c3c41e75c998fd7d1d3",
"assets/assets/images/7.png": "621a7721b6d910b9f122ae3fd59f0a58",
"assets/assets/images/8.png": "7f09a865a162cf32ffe773446493ccf3",
"assets/assets/images/9.png": "ae0b191b25809ec25462e5248a2b9cfb",
"assets/assets/images/apple.png": "d66c2d854b97e2807c354a6a1a564fa0",
"assets/assets/images/ball.png": "62ab71d9405cb78f63b2f45dae5be91f",
"assets/assets/images/books.png": "d1e6d5b05526298db111c434f7e92a4c",
"assets/assets/images/brazil.png": "0377348e91ed3b26065be1f3576df8f0",
"assets/assets/images/canada.png": "dee2f4dc836fb6f6e653e3c8f7090799",
"assets/assets/images/car.png": "674612af27bf6de771e92a1dabe3fe8f",
"assets/assets/images/cat.png": "39de586b0df5682a638f0255bbcc53f6",
"assets/assets/images/chair.png": "21e1d664328e5222f49852a6bf35c965",
"assets/assets/images/china.png": "dda70ca863e117487ca2d08cc61d3ed5",
"assets/assets/images/dog.png": "9dc2ad981ccc03bc89301d7da7f835a3",
"assets/assets/images/france.png": "fcf3e91be49f672a64fbd36477b44b46",
"assets/assets/images/germany.png": "1e4d260901d8022da097c16cf6b343dd",
"assets/assets/images/house.png": "7a1070084d1217f39f48a316a066490a",
"assets/assets/images/india.png": "c5ac69c6d8f57c1286107c46da82079f",
"assets/assets/images/italy.png": "62f3b6e2c1ec28a9572f4d6436757ca0",
"assets/assets/images/japan.png": "2b8944efd93673759b0555d7715938e7",
"assets/assets/images/philippines.png": "82f4407dccb388b55a1f41949b189e9c",
"assets/assets/images/shoes.png": "676789f0336aaa046abb1a6e1ec6cd6e",
"assets/assets/images/south_korea.png": "05ad069dffc68ff1f5cb20ac78dc1e93",
"assets/assets/images/sun.png": "5b50c5ffb921d49a63b76814fb658f37",
"assets/assets/images/tree.png": "c95b51771b4e92aed9d83cc7db3f34bb",
"assets/assets/images/united_kingdom.png": "e00490119fccb5a57b7aadf5e88ec408",
"assets/assets/images/usa.png": "439f8204958fc545dfcd8076a32c1e87",
"assets/assets/images/water.png": "5074ef61441066c5e40c269ea6e27670",
"assets/FontManifest.json": "bf1882d2cdb6bc3d886ff02e2a944591",
"assets/fonts/MaterialIcons-Regular.otf": "10a07d3b9331571b4442f628eda50897",
"assets/NOTICES": "7463cb3b9f93a73efc02db6709a6489f",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "2e5db1edd75da9c266665f01945df752",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "35468c3d637173a342c23f06e1cff660",
"/": "35468c3d637173a342c23f06e1cff660",
"main.dart.js": "d7dae1e77fa8627d9176aed5874ca7ee",
"manifest.json": "93c37eecd235ec821395472848c24759",
"version.json": "274cb08730044d4ae5394930d9c2372d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
