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
  const APPLY_RELOAD_TIMEOUT_MS = 1500;
  const UPDATE_POLL_INTERVAL_MS = 60000;
  const UPDATE_POLL_START_DELAY_MS = 15000;
  const APPLYING_VERSION_KEY = 'igames_sw_applying_version';
  const DISMISSED_VERSION_KEY = 'igames_sw_dismissed_version';
  const KNOWN_VERSION_KEY = 'igames_sw_known_version';
  let refreshing = false;
  let applyRequested = false;
  let registration = null;
  let pendingWorker = null;
  let applyReloadTimer = null;
  let updatePollTimer = null;
  const observedRegistrations = new WeakSet();
  const observedWorkers = new WeakSet();

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

  function readApplyingVersion() {
    try {
      return window.sessionStorage.getItem(APPLYING_VERSION_KEY);
    } catch (_) {
      return null;
    }
  }

  function writeApplyingVersion(version) {
    try {
      if (!version) {
        window.sessionStorage.removeItem(APPLYING_VERSION_KEY);
        return;
      }
      window.sessionStorage.setItem(APPLYING_VERSION_KEY, version);
    } catch (_) {}
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
      applyingVersion: readApplyingVersion(),
      dismissedVersion: readDismissedVersion(),
      knownVersion: readKnownVersion(),
    });

  function setApplyingVersion(version) {
    const normalized = normalizeVersion(version);
    state.applyingVersion = normalized || null;
    writeApplyingVersion(normalized || null);
  }

  function clearApplyingVersion() {
    state.applyingVersion = null;
    writeApplyingVersion(null);
  }

  function markUpdateAvailable(version) {
    const normalizedVersion = normalizeVersion(version);
    if (
      !normalizedVersion ||
      state.dismissedVersion === normalizedVersion ||
      state.applyingVersion === normalizedVersion
    ) {
      return;
    }

    state.available = true;
    state.version = normalizedVersion;

    window.dispatchEvent(
      new CustomEvent('igames-sw-update-available', {
        detail: {version: normalizedVersion},
      }),
    );
  }

  function clearApplyReloadTimer() {
    if (applyReloadTimer !== null) {
      window.clearTimeout(applyReloadTimer);
      applyReloadTimer = null;
    }
  }

  function forceReloadPage() {
    if (refreshing) {
      return;
    }
    refreshing = true;
    window.location.reload();
  }

  function requestWorkerActivation(worker, fallbackVersion) {
    if (!worker) {
      return false;
    }

    const targetVersion =
      normalizeVersion(fallbackVersion) || resolvePendingVersion(worker, '');

    clearApplyReloadTimer();
    applyRequested = true;
    state.available = false;
    state.version = null;
    writeDismissedVersion(null);
    if (targetVersion) {
      setApplyingVersion(targetVersion);
    }
    pendingWorker = worker;

    applyReloadTimer = window.setTimeout(() => {
      forceReloadPage();
    }, APPLY_RELOAD_TIMEOUT_MS);

    worker.postMessage({type: 'SKIP_WAITING'});
    return true;
  }

  window.__igamesDismissWebUpdate = function () {
    clearApplyReloadTimer();
    if (state.version) {
      state.dismissedVersion = state.version;
      writeDismissedVersion(state.version);
    }
    state.available = false;
    state.version = null;
    applyRequested = false;
    pendingWorker = null;
  };

  window.__igamesApplyWebUpdate = function () {
    const waitingWorker = pendingWorker || registration?.waiting;
    if (!requestWorkerActivation(waitingWorker, state.version)) {
      forceReloadPage();
    }
  };

  function normalizeVersion(value) {
    return typeof value === 'string' ? value.trim() : '';
  }

  function getCurrentEngineRevision() {
    return normalizeVersion(_flutter?.buildConfig?.engineRevision || '');
  }

  function parseEngineRevisionFromBootstrapText(text) {
    const normalizedText = normalizeText(text);
    if (!normalizedText) {
      return '';
    }

    const match = normalizedText.match(/"engineRevision"\s*:\s*"([^"]+)"/);
    return normalizeVersion(match?.[1] || '');
  }

  function buildSwUrl(version, engineRevision) {
    const params = new URLSearchParams();
    const normalizedVersion = normalizeVersion(version);
    const normalizedEngineRevision = normalizeVersion(engineRevision);

    if (normalizedVersion) {
      params.set('v', normalizedVersion);
    }
    if (normalizedEngineRevision) {
      params.set('engine', normalizedEngineRevision);
    }

    const queryString = params.toString();
    return queryString ? `/sw.js?${queryString}` : '/sw.js';
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
    if (normalized && state.applyingVersion === normalized) {
      clearApplyingVersion();
    }
    if (!normalized || state.knownVersion === normalized) {
      return;
    }

    state.knownVersion = normalized;
    writeKnownVersion(normalized);
  }

  function getActiveBaselineVersion() {
    return normalizeVersion(getControllerVersion() || state.knownVersion || '');
  }

  function shouldAutoApplyLoadedBuild(version) {
    const pendingVersion = normalizeVersion(version);
    const loadedVersion = normalizeVersion(state.loadedVersion);
    const baselineVersion = getActiveBaselineVersion();

    return !!(
      pendingVersion &&
      loadedVersion &&
      baselineVersion &&
      pendingVersion === loadedVersion &&
      pendingVersion !== baselineVersion
    );
  }

  function resolvePendingVersion(worker, fallbackVersion) {
    return (
      parseVersionFromWorkerUrl(worker?.scriptURL || '') ||
      normalizeVersion(fallbackVersion)
    );
  }

  function handlePendingWorker(worker, hadController, fallbackVersion) {
    if (!worker) {
      return;
    }

    pendingWorker = worker;
    const pendingVersion = resolvePendingVersion(worker, fallbackVersion);

    if (shouldAutoApplyLoadedBuild(pendingVersion)) {
      requestWorkerActivation(worker, pendingVersion);
      return;
    }

    if (
      state.applyingVersion &&
      normalizeVersion(pendingVersion) === state.applyingVersion
    ) {
      requestWorkerActivation(worker, pendingVersion);
      return;
    }

    if (shouldPromptForUpdate(pendingVersion, hadController)) {
      markUpdateAvailable(pendingVersion);
    }
  }

  function observeWorker(worker, hadController, fallbackVersion) {
    if (!worker || observedWorkers.has(worker)) {
      return;
    }

    observedWorkers.add(worker);
    worker.addEventListener('statechange', () => {
      const pendingVersion = resolvePendingVersion(worker, fallbackVersion);
      if (
        worker.state === 'installed' &&
        navigator.serviceWorker.controller
      ) {
        handlePendingWorker(
          worker,
          !!navigator.serviceWorker.controller,
          fallbackVersion,
        );
        return;
      }

      if (worker.state === 'activated' && pendingVersion) {
        syncKnownVersion(pendingVersion);
      }
    });
  }

  function observeRegistration(targetRegistration, hadController, fallbackVersion) {
    if (!targetRegistration) {
      return;
    }

    if (targetRegistration.waiting) {
      handlePendingWorker(
        targetRegistration.waiting,
        hadController,
        fallbackVersion,
      );
    }

    if (targetRegistration.installing) {
      observeWorker(
        targetRegistration.installing,
        hadController,
        fallbackVersion,
      );
    }

    if (observedRegistrations.has(targetRegistration)) {
      return;
    }

    observedRegistrations.add(targetRegistration);
    targetRegistration.addEventListener('updatefound', () => {
      observeWorker(
        targetRegistration.installing,
        hadController,
        fallbackVersion,
      );
    });
  }

  function shouldPromptForUpdate(version, hadController) {
    const pendingVersion = normalizeVersion(version);
    const baselineVersion = getActiveBaselineVersion();
    if (!hadController || !pendingVersion || !baselineVersion) {
      return false;
    }

    if (shouldAutoApplyLoadedBuild(pendingVersion)) {
      return false;
    }

    return pendingVersion !== baselineVersion;
  }

  function buildResponseVersionSignature(response) {
    if (!response || !response.ok) {
      return '';
    }

    return [
      response.headers.get('etag'),
      response.headers.get('last-modified'),
      response.headers.get('content-length'),
    ]
      .filter(Boolean)
      .join(':');
  }

  function hashText(text) {
    let hash = 5381;
    for (let index = 0; index < text.length; index += 1) {
      hash = ((hash << 5) + hash + text.charCodeAt(index)) >>> 0;
    }

    return hash.toString(16);
  }

  async function resolveVersionFromPath(path, allowTextFallback) {
    try {
      const headResponse = await fetch(path, {
        method: 'HEAD',
        cache: 'no-store',
      });
      const signature = buildResponseVersionSignature(headResponse);
      if (signature) {
        return signature;
      }
    } catch (_) {}

    if (!allowTextFallback) {
      return '';
    }

    try {
      const response = await fetch(path, {cache: 'no-store'});
      if (!response.ok) {
        return '';
      }

      const text = await response.text();
      if (!text) {
        return '';
      }

      return `text:${hashText(text)}:${text.length}`;
    } catch (_) {
      return '';
    }
  }

  async function resolveVersionFromBuildMarker() {
    try {
      const response = await fetch('.last_build_id', {cache: 'no-store'});
      if (!response.ok) {
        return '';
      }

      return normalizeVersion(await response.text());
    } catch (_) {
      return '';
    }
  }

  function getActiveBuildAssetPath() {
    const builds = Array.isArray(_flutter?.buildConfig?.builds)
      ? _flutter.buildConfig.builds
      : [];
    const runtime = window[FLUTTER_RUNTIME_KEY];
    const usesWasm = runtime?.usesWasm === true;
    const renderer = normalizeText(runtime?.renderer);

    const selectedBuild =
      builds.find((build) => {
        if (!build || typeof build !== 'object') {
          return false;
        }
        const buildRenderer = normalizeText(build.renderer);
        const compileTarget = normalizeText(build.compileTarget);
        const buildUsesWasm = compileTarget === 'dart2wasm';
        return buildUsesWasm === usesWasm && buildRenderer === renderer;
      }) || null;

    if (usesWasm) {
      return (
        selectedBuild?.mainWasmPath ||
        selectedBuild?.jsSupportRuntimePath ||
        'main.dart.wasm'
      );
    }

    return selectedBuild?.mainJsPath || 'main.dart.js';
  }

  async function resolveVersionFromActiveAsset() {
    const assetPath = getActiveBuildAssetPath();
    if (!assetPath) {
      return '';
    }

    return resolveVersionFromPath(assetPath, false);
  }

  async function resolveVersionFromBootstrapAsset() {
    return resolveVersionFromPath('flutter_bootstrap.js', true);
  }

  async function resolveBootstrapBuildInfoFromNetwork() {
    try {
      const response = await fetch('flutter_bootstrap.js', {cache: 'no-store'});
      if (!response.ok) {
        return {version: '', engineRevision: ''};
      }

      const text = await response.text();
      if (!text) {
        return {version: '', engineRevision: ''};
      }

      return {
        version: `text:${hashText(text)}:${text.length}`,
        engineRevision: parseEngineRevisionFromBootstrapText(text),
      };
    } catch (_) {
      return {version: '', engineRevision: ''};
    }
  }

  async function resolveBuildVersion() {
    const buildMarkerVersion = await resolveVersionFromBuildMarker();
    if (buildMarkerVersion) {
      return buildMarkerVersion;
    }

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

    const assetVersion = await resolveVersionFromActiveAsset();
    if (assetVersion) {
      return assetVersion;
    }

    const bootstrapVersion = await resolveVersionFromBootstrapAsset();
    if (bootstrapVersion) {
      return bootstrapVersion;
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

  async function resolveLatestBuildInfoFromNetwork() {
    const buildMarkerVersion = await resolveVersionFromBuildMarker();
    if (buildMarkerVersion) {
      return {
        version: buildMarkerVersion,
        engineRevision: '',
      };
    }

    const assetVersion = await resolveVersionFromActiveAsset();
    if (assetVersion) {
      return {
        version: assetVersion,
        engineRevision: '',
      };
    }

    return resolveBootstrapBuildInfoFromNetwork();
  }

  async function resolveRemoteEngineRevisionFromNetwork() {
    const buildInfo = await resolveBootstrapBuildInfoFromNetwork();
    return normalizeVersion(buildInfo.engineRevision);
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
    state.loadedVersion = normalizeVersion(buildVersion);
    const swUrl = buildSwUrl(buildVersion, getCurrentEngineRevision());
    const hadController = !!navigator.serviceWorker.controller;
    const controllerVersion = getControllerVersion();

    if (controllerVersion) {
      syncKnownVersion(controllerVersion);
    }

    navigator.serviceWorker.addEventListener('controllerchange', () => {
      clearApplyReloadTimer();
      const nextControllerVersion = getControllerVersion();
      if (nextControllerVersion) {
        syncKnownVersion(nextControllerVersion);
      }

      if (!applyRequested || refreshing) {
        return;
      }
      forceReloadPage();
    });

    registration = await navigator.serviceWorker.register(swUrl);
    observeRegistration(registration, hadController, '');

    const activeVersion = parseVersionFromWorkerUrl(
      registration.active?.scriptURL || '',
    );
    if (activeVersion) {
      syncKnownVersion(activeVersion);
    } else if (!hadController && buildVersion) {
      syncKnownVersion(buildVersion);
    }

    if (updatePollTimer === null) {
      updatePollTimer = window.setTimeout(() => {
        const poll = async () => {
          try {
            const remoteBuildInfo = await resolveLatestBuildInfoFromNetwork();
            const normalizedRemoteVersion = normalizeVersion(
              remoteBuildInfo?.version,
            );
            const activeVersion = getActiveBaselineVersion();

            if (
              !normalizedRemoteVersion ||
              !activeVersion ||
              normalizedRemoteVersion === activeVersion ||
              normalizedRemoteVersion === state.dismissedVersion ||
              normalizedRemoteVersion === state.applyingVersion
            ) {
              return;
            }

            let remoteEngineRevision = normalizeVersion(
              remoteBuildInfo?.engineRevision,
            );
            if (!remoteEngineRevision) {
              remoteEngineRevision =
                (await resolveRemoteEngineRevisionFromNetwork()) ||
                getCurrentEngineRevision();
            }

            const remoteSwUrl = buildSwUrl(
              normalizedRemoteVersion,
              remoteEngineRevision,
            );
            registration = await navigator.serviceWorker.register(remoteSwUrl);
            observeRegistration(registration, true, '');
          } catch (_) {}
        };

        poll();
        window.setInterval(poll, UPDATE_POLL_INTERVAL_MS);
      }, UPDATE_POLL_START_DELAY_MS);
    }
  }

  function startWebUpdaterLater() {
    const run = async () => {
      try {
        await setupWebUpdater();
      } catch (_) {}
    };

    window.addEventListener(
      'flutter-first-frame',
      () => {
        if ('requestIdleCallback' in window) {
          window.requestIdleCallback(run, {timeout: 2500});
        } else {
          window.setTimeout(run, 800);
        }
      },
      {once: true},
    );
  }

  startWebUpdaterLater();
  _flutter.loader.load();
})();
