{{flutter_js}}
{{flutter_build_config}}

(function () {
  const FLUTTER_RUNTIME_KEY = '__igamesFlutterRuntime';
  const DEFAULT_WASM_ALLOW_LIST = {
    blink: true,
    gecko: false,
    webkit: false,
    unknown: false,
  };
  const DISMISSED_VERSION_KEY = 'igames_sw_dismissed_version';
  const KNOWN_VERSION_KEY = 'igames_sw_known_version';
  let refreshing = false;
  let applyRequested = false;
  let registration = null;
  let pendingWorker = null;

  function normalizeText(value) {
    return typeof value === 'string' ? value.trim() : '';
  }

  function detectBrowserEngine() {
    const vendor = normalizeText(window.navigator.vendor);
    const userAgent = normalizeText(window.navigator.userAgent);

    if (vendor === 'Google Inc.' || userAgent.includes('Edg/')) {
      return 'blink';
    }

    if (vendor === 'Apple Computer, Inc.') {
      return 'webkit';
    }

    if (!vendor && userAgent.includes('Firefox')) {
      return 'gecko';
    }

    return 'unknown';
  }

  function supportsWasmGc() {
    try {
      return WebAssembly.validate(
        new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0]),
      );
    } catch (_) {
      return false;
    }
  }

  function detectWebGlVersion() {
    try {
      const canvas = document.createElement('canvas');
      canvas.width = 1;
      canvas.height = 1;

      if (canvas.getContext('webgl2')) {
        return 2;
      }

      if (canvas.getContext('webgl')) {
        return 1;
      }
    } catch (_) {}

    return -1;
  }

  function formatRendererName(renderer) {
    switch (renderer) {
      case 'canvaskit':
        return 'CanvasKit';
      case 'skwasm':
        return 'skwasm';
      default:
        return renderer || 'unknown';
    }
  }

  function resolveFlutterRuntime(config) {
    const runtimeConfig = config || {};
    const buildConfig = _flutter?.buildConfig;
    const builds = Array.isArray(buildConfig?.builds) ? buildConfig.builds : [];
    const browserEngine = detectBrowserEngine();
    const wasmAllowList = {
      ...DEFAULT_WASM_ALLOW_LIST,
      ...(runtimeConfig.wasmAllowList || {}),
    };
    const wasmGcSupported = supportsWasmGc();
    const webGlVersion = detectWebGlVersion();
    const browserAllowlisted = wasmAllowList[browserEngine] === true;

    const selectedBuild =
      builds.find((build) => {
        if (!build || typeof build !== 'object') {
          return false;
        }

        const compileTarget = normalizeText(build.compileTarget);
        const renderer = normalizeText(build.renderer);

        if (runtimeConfig.renderer && runtimeConfig.renderer !== renderer) {
          return false;
        }

        if (compileTarget === 'dart2wasm' && !wasmGcSupported) {
          return false;
        }

        if (
          renderer === 'skwasm' &&
          !(wasmGcSupported && webGlVersion > 0 && browserAllowlisted)
        ) {
          return false;
        }

        return true;
      }) || null;

    const compileTarget =
      normalizeText(selectedBuild?.compileTarget) || 'unknown';
    const renderer = normalizeText(selectedBuild?.renderer) || 'unknown';
    const usesWasm = compileTarget === 'dart2wasm';

    let reason = '';
    if (!selectedBuild) {
      reason = 'no-compatible-build';
    } else if (!usesWasm) {
      if (!wasmGcSupported) {
        reason = 'browser-missing-wasm-gc';
      } else if (webGlVersion <= 0) {
        reason = 'browser-missing-webgl';
      } else if (!browserAllowlisted) {
        reason = `browser-engine-${browserEngine}-not-allowlisted`;
      } else {
        reason = 'js-build-selected';
      }
    }

    return {
      summary: usesWasm
        ? `Wasm (${formatRendererName(renderer)})`
        : `JS fallback (${formatRendererName(renderer)})`,
      compileTarget,
      renderer,
      usesWasm,
      browserEngine,
      browserAllowlisted,
      supportsWasmGc: wasmGcSupported,
      webGlVersion,
      crossOriginIsolated: window.crossOriginIsolated === true,
      reason,
    };
  }

  function writeFlutterRuntime(config) {
    window[FLUTTER_RUNTIME_KEY] = resolveFlutterRuntime(config);
  }

  if (_flutter?.loader?.load) {
    const originalFlutterLoad = _flutter.loader.load.bind(_flutter.loader);
    _flutter.loader.load = function (options) {
      writeFlutterRuntime(options?.config);
      return originalFlutterLoad(options);
    };
  }

  function readDismissedVersion() {
    try {
      return window.sessionStorage.getItem(DISMISSED_VERSION_KEY);
    } catch (_) {
      return null;
    }
  }

  function writeDismissedVersion(version) {
    try {
      if (!version) {
        window.sessionStorage.removeItem(DISMISSED_VERSION_KEY);
        return;
      }
      window.sessionStorage.setItem(DISMISSED_VERSION_KEY, version);
    } catch (_) {}
  }

  function readKnownVersion() {
    try {
      return window.localStorage.getItem(KNOWN_VERSION_KEY) || '';
    } catch (_) {
      return '';
    }
  }

  function writeKnownVersion(version) {
    try {
      if (!version) {
        window.localStorage.removeItem(KNOWN_VERSION_KEY);
        return;
      }
      window.localStorage.setItem(KNOWN_VERSION_KEY, version);
    } catch (_) {}
  }

  const state = (window.__igamesSwUpdateState =
    window.__igamesSwUpdateState || {
      available: false,
      version: null,
      dismissedVersion: readDismissedVersion(),
      knownVersion: readKnownVersion(),
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
      writeDismissedVersion(state.version);
    }
    state.available = false;
    applyRequested = false;
  };

  window.__igamesApplyWebUpdate = function () {
    const waitingWorker = pendingWorker || registration?.waiting;
    if (!waitingWorker) {
      return;
    }
    applyRequested = true;
    writeDismissedVersion(null);
    waitingWorker.postMessage({type: 'SKIP_WAITING'});
  };

  function normalizeVersion(value) {
    return typeof value === 'string' ? value.trim() : '';
  }

  function parseVersionFromWorkerUrl(scriptUrl) {
    const normalizedUrl = normalizeVersion(scriptUrl);
    if (!normalizedUrl) {
      return '';
    }

    try {
      const parsedUrl = new URL(normalizedUrl, window.location.origin);
      return normalizeVersion(parsedUrl.searchParams.get('v'));
    } catch (_) {
      return '';
    }
  }

  function getControllerVersion() {
    return parseVersionFromWorkerUrl(
      navigator.serviceWorker.controller?.scriptURL || '',
    );
  }

  function syncKnownVersion(version) {
    const normalized = normalizeVersion(version);
    if (!normalized || state.knownVersion === normalized) {
      return;
    }

    state.knownVersion = normalized;
    writeKnownVersion(normalized);
  }

  function resolvePendingVersion(worker, fallbackVersion) {
    return (
      parseVersionFromWorkerUrl(worker?.scriptURL || '') ||
      normalizeVersion(fallbackVersion)
    );
  }

  function shouldPromptForUpdate(version, hadController) {
    const pendingVersion = normalizeVersion(version);
    const baselineVersion = getControllerVersion() || state.knownVersion || '';
    if (!hadController || !pendingVersion || !baselineVersion) {
      return false;
    }

    return pendingVersion !== baselineVersion;
  }

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
    const hadController = !!navigator.serviceWorker.controller;
    const controllerVersion = getControllerVersion();

    if (controllerVersion) {
      syncKnownVersion(controllerVersion);
    }

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      const nextControllerVersion = getControllerVersion();
      if (nextControllerVersion) {
        syncKnownVersion(nextControllerVersion);
      }

      if (!hadController || !applyRequested || refreshing) {
        return;
      }
      refreshing = true;
      window.location.reload();
    });

    registration = await navigator.serviceWorker.register(swUrl);

    const activeVersion = parseVersionFromWorkerUrl(
      registration.active?.scriptURL || '',
    );
    if (activeVersion) {
      syncKnownVersion(activeVersion);
    } else if (!hadController && buildVersion) {
      syncKnownVersion(buildVersion);
    }

    if (registration.waiting) {
      pendingWorker = registration.waiting;
      const waitingVersion =
        resolvePendingVersion(registration.waiting, buildVersion) || 'latest';
      if (shouldPromptForUpdate(waitingVersion, hadController)) {
        markUpdateAvailable(waitingVersion);
      }
    }

    registration.addEventListener('updatefound', () => {
      const newWorker = registration.installing;
      if (!newWorker) {
        return;
      }

      newWorker.addEventListener('statechange', () => {
        const pendingVersion = resolvePendingVersion(newWorker, buildVersion);
        if (
          newWorker.state === 'installed' &&
          navigator.serviceWorker.controller &&
          shouldPromptForUpdate(pendingVersion, hadController)
        ) {
          pendingWorker = newWorker;
          markUpdateAvailable(pendingVersion || 'latest');
          return;
        }

        if (newWorker.state === 'activated' && pendingVersion) {
          syncKnownVersion(pendingVersion);
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
      window.setTimeout(() => {
        if ('requestIdleCallback' in window) {
          window.requestIdleCallback(run, {timeout: 4000});
        } else {
          run();
        }
      }, 15000);
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
