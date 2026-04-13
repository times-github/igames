{{flutter_js}}
{{flutter_build_config}}

(async function () {
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

    try {
      const mainJsResponse = await fetch('main.dart.js', {
        method: 'HEAD',
        cache: 'no-store',
      });
      if (mainJsResponse.ok) {
        const eTag = mainJsResponse.headers.get('etag');
        const lastModified = mainJsResponse.headers.get('last-modified');
        const contentLength = mainJsResponse.headers.get('content-length');
        const headerVersion = [eTag, lastModified, contentLength]
          .filter(Boolean)
          .join(':');

        if (headerVersion) {
          return headerVersion;
        }
      }
    } catch (_) {}

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
    const swUrl = buildVersion ? `/sw.js?v=${buildVersion}` : '/sw.js';

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

  try {
    await setupWebUpdater();
  } catch (_) {}

  _flutter.loader.load();
})();
