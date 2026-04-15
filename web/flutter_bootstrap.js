{{flutter_js}}
{{flutter_build_config}}

(function () {
  let refreshing = false;
  let registration = null;
  let pendingWorker = null;

  const state = (window.__igamesSwUpdateState =
    window.__igamesSwUpdateState || {
      available: false,
      version: null,
      dismissedVersion: null,
    });

  function markUpdateAvailable(version) {
    if (!version || state.dismissedVersion === version) {
      return;
    }

    state.available = true;
    state.version = version;

    window.dispatchEvent(
      new CustomEvent('igames-sw-update-available', {
        detail: {version},
      }),
    );
  }

  window.__igamesDismissWebUpdate = function () {
    if (state.version) {
      state.dismissedVersion = state.version;
    }
    state.available = false;
  };

  window.__igamesApplyWebUpdate = function () {
    const waitingWorker = pendingWorker || registration?.waiting;
    if (!waitingWorker) {
      return;
    }
    waitingWorker.postMessage({type: 'SKIP_WAITING'});
  };

  function getBuildVersionCandidates() {
    const candidates = [];
    const seen = new Set();
    const builds = Array.isArray(_flutter?.buildConfig?.builds)
      ? _flutter.buildConfig.builds
      : [];

    function pushIfPresent(value) {
      if (typeof value !== 'string') {
        return;
      }

      const normalized = value.trim();
      if (!normalized || seen.has(normalized)) {
        return;
      }

      seen.add(normalized);
      candidates.push(normalized);
    }

    for (const build of builds) {
      if (!build || typeof build !== 'object') {
        continue;
      }
      pushIfPresent(build.jsSupportRuntimePath);
      pushIfPresent(build.mainWasmPath);
      pushIfPresent(build.mainJsPath);
    }

    pushIfPresent('main.dart.mjs');
    pushIfPresent('main.dart.wasm');
    pushIfPresent('main.dart.js');

    return candidates;
  }

  async function resolveVersionFromAssets() {
    const candidates = getBuildVersionCandidates();
    if (candidates.length === 0) {
      return '';
    }

    const parts = [];

    for (const assetPath of candidates) {
      try {
        const response = await fetch(assetPath, {
          method: 'HEAD',
          cache: 'no-store',
        });
        if (!response.ok) {
          continue;
        }

        const eTag = response.headers.get('etag');
        const lastModified = response.headers.get('last-modified');
        const contentLength = response.headers.get('content-length');
        const assetVersion = [eTag, lastModified, contentLength]
          .filter(Boolean)
          .join(':');

        if (assetVersion) {
          parts.push(`${assetPath}:${assetVersion}`);
        }
      } catch (_) {}
    }

    return parts.join('|');
  }

  async function resolveBuildVersion() {
    const tokenVersion = {{flutter_service_worker_version}};
    const normalizedTokenVersion = String(tokenVersion ?? '')
      .trim()
      .toLowerCase();
    if (
      typeof tokenVersion === 'string' &&
      tokenVersion &&
      !tokenVersion.includes('{{') &&
      !normalizedTokenVersion.startsWith('null')
      ) {
        return tokenVersion;
      }

    const assetVersion = await resolveVersionFromAssets();
    if (assetVersion) {
      return assetVersion;
    }

    try {
      const response = await fetch('version.json', {cache: 'no-store'});
      if (!response.ok) {
        return '';
      }
      const data = await response.json();
      return (
        data?.version?.toString() ||
        data?.app_version?.toString() ||
        data?.build_number?.toString() ||
        ''
      );
    } catch (_) {
      return '';
    }
  }

  async function unregisterLegacyFlutterWorkers() {
    if (!('serviceWorker' in navigator)) {
      return;
    }

    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map(async (item) => {
        const scriptUrl =
          item.active?.scriptURL ||
          item.waiting?.scriptURL ||
          item.installing?.scriptURL ||
          '';

        if (scriptUrl.includes('flutter_service_worker.js')) {
          await item.unregister();
        }
      }),
    );
  }

  async function setupWebUpdater() {
    if (!('serviceWorker' in navigator)) {
      return;
    }

    const isLocalhost =
    window.location.hostname === 'localhost' ||
    window.location.hostname === '127.0.0.1' ||
    window.location.hostname === '::1';

  if (isLocalhost) {
    return;
  }

    await unregisterLegacyFlutterWorkers();

    const buildVersion = await resolveBuildVersion();
    const swVersionParam = buildVersion ? encodeURIComponent(buildVersion) : '';
    const swUrl = swVersionParam ? `/sw.js?v=${swVersionParam}` : '/sw.js';

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      if (refreshing) {
        return;
      }
      refreshing = true;
      window.location.reload();
    });

    registration = await navigator.serviceWorker.register(swUrl);

    if (registration.waiting) {
      pendingWorker = registration.waiting;
      markUpdateAvailable(buildVersion || 'latest');
    }

    registration.addEventListener('updatefound', () => {
      const newWorker = registration.installing;
      if (!newWorker) {
        return;
      }

      newWorker.addEventListener('statechange', () => {
        if (
          newWorker.state === 'installed' &&
          navigator.serviceWorker.controller
        ) {
          pendingWorker = newWorker;
          markUpdateAvailable(buildVersion || 'latest');
        }
      });
    });

    window.setInterval(() => {
      registration?.update();
    }, 60000);
  }

  function startWebUpdaterLater() {
    const run = async () => {
      try {
        await setupWebUpdater();
      } catch (_) {}
    };

    const schedule = () => {
      if ('requestIdleCallback' in window) {
        window.requestIdleCallback(run, {timeout: 4000});
      } else {
        window.setTimeout(run, 1200);
      }
    };

    window.addEventListener(
      'flutter-first-frame',
      () => {
        schedule();
      },
      {once: true},
    );
  }

  startWebUpdaterLater();
  _flutter.loader.load();
})();
