import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'device_info_models.dart';

Future<RawDeviceInfo> loadPlatformDeviceInfo() async {
  final navigator = web.window.navigator;
  final userAgent = navigator.userAgent;
  final platform = navigator.platform;
  final host = web.window.location.host;

  final browserVersion = _parseBrowser(userAgent);
  final engine = _parseEngine(userAgent, browserVersion);
  final model = _parseModel(userAgent, platform);
  final osVersion = _parseOs(userAgent, platform);
  final flutterRuntime = _parseFlutterRuntime();

  return RawDeviceInfo(
    model: model,
    osVersion: osVersion,
    browserVersion: browserVersion,
    browserEngine: engine,
    flutterRuntime: flutterRuntime,
    host: host,
    userAgent: userAgent,
  );
}

String _parseFlutterRuntime() {
  final runtime = _readFlutterRuntime();
  final summary = _readJsString(runtime, 'summary');
  if (summary.isNotEmpty) {
    return summary;
  }

  final compileTarget = _readJsString(runtime, 'compileTarget');
  final renderer = _normalizeRendererName(_readJsString(runtime, 'renderer'));
  final usesWasm = _readJsBool(runtime, 'usesWasm');

  if (compileTarget.isNotEmpty || renderer.isNotEmpty) {
    final label = renderer.isNotEmpty ? renderer : compileTarget;
    return usesWasm ? 'Wasm ($label)' : 'JS fallback ($label)';
  }

  if (_hasWindowProperty('_flutter_skwasmInstance')) {
    return 'Wasm (skwasm)';
  }

  if (_hasWindowProperty('flutterCanvasKit')) {
    return 'JS fallback (CanvasKit)';
  }

  return '未知';
}

JSAny? _readFlutterRuntime() {
  final global = web.window as JSObject;
  final runtime = global['__igamesFlutterRuntime'];
  if (runtime == null || runtime.isUndefinedOrNull) {
    return null;
  }
  return runtime;
}

String _readJsString(JSAny? target, String key) {
  if (target == null || target.isUndefinedOrNull) {
    return '';
  }

  final value = (target as JSObject)[key];
  if (value == null || value.isUndefinedOrNull) {
    return '';
  }

  if (value case JSString jsString) {
    return jsString.toDart.trim();
  }

  return value.dartify()?.toString().trim() ?? '';
}

bool _readJsBool(JSAny? target, String key) {
  if (target == null || target.isUndefinedOrNull) {
    return false;
  }

  final value = (target as JSObject)[key];
  if (value == null || value.isUndefinedOrNull) {
    return false;
  }

  return value == true.toJS;
}

bool _hasWindowProperty(String key) {
  final global = web.window as JSObject;
  final value = global[key];
  return value != null && !value.isUndefinedOrNull;
}

String _normalizeRendererName(String renderer) {
  switch (renderer.toLowerCase()) {
    case 'canvaskit':
      return 'CanvasKit';
    case 'skwasm':
      return 'skwasm';
    default:
      return renderer;
  }
}

String _parseBrowser(String ua) {
  final edge = RegExp(r'Edg[e]?/([0-9\\.]+)').firstMatch(ua);
  if (edge != null) return 'Edge(${edge.group(1)})';

  final chrome = RegExp(r'Chrome/([0-9\\.]+)').firstMatch(ua);
  if (chrome != null) return 'Chrome(${chrome.group(1)})';

  final firefox = RegExp(r'Firefox/([0-9\\.]+)').firstMatch(ua);
  if (firefox != null) return 'Firefox(${firefox.group(1)})';

  final safari = RegExp(r'Version/([0-9\\.]+)').firstMatch(ua);
  if (safari != null && ua.contains('Safari') && !ua.contains('Chrome')) {
    return 'Safari(${safari.group(1)})';
  }

  return '未知';
}

String _parseEngine(String ua, String browserVersion) {
  if (ua.contains('Chrome') || ua.contains('Edg') || ua.contains('Chromium')) {
    final version = RegExp(r'([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)')
        .firstMatch(browserVersion)
        ?.group(1);
    return 'chrome内核(${version ?? browserVersion.replaceAll(RegExp(r'[^0-9.]'), '')})';
  }

  if (ua.contains('Firefox')) {
    final version = RegExp(r'Firefox/([0-9\\.]+)').firstMatch(ua)?.group(1);
    return 'Gecko(${version ?? ''})';
  }

  if (ua.contains('Safari') && !ua.contains('Chrome')) {
    final webkit = RegExp(r'AppleWebKit/([0-9\\.]+)').firstMatch(ua);
    return 'WebKit(${webkit?.group(1) ?? ''})';
  }

  return browserVersion;
}

String _parseModel(String ua, String platform) {
  final androidSection =
      RegExp(r'\(([^)]*Android[^)]*)\)').firstMatch(ua)?.group(1);
  if (androidSection != null) {
    final parts = androidSection
        .split(';')
        .map((part) => part.trim())
        .map((part) => part.split('Build/').first.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    for (final part in parts) {
      final normalized = part.toLowerCase();
      if (normalized.startsWith('linux')) continue;
      if (normalized.startsWith('android')) continue;
      if (normalized == 'u' || normalized == 'wv') continue;
      if (part.length <= 1) continue;
      return part;
    }

    return 'Android Device';
  }

  if (ua.contains('iPhone')) return 'iPhone';
  if (ua.contains('iPad')) return 'iPad';
  if (ua.contains('Macintosh')) return 'Macintosh';
  if (ua.contains('Windows')) return 'Windows PC';

  return platform.isNotEmpty ? platform : '未知';
}

String _parseOs(String ua, String platform) {
  final android = RegExp(r'Android ([^;\s\)]+)').firstMatch(ua)?.group(1);
  if (android != null) return 'Android $android';

  final ios = RegExp(r'CPU (?:iPhone )?OS ([0-9_]+)').firstMatch(ua)?.group(1);
  if (ios != null) return 'iOS ${ios.replaceAll('_', '.')}';

  final mac = RegExp(r'Mac OS X ([0-9_\\.]+)').firstMatch(ua)?.group(1);
  if (mac != null) return 'macOS ${mac.replaceAll('_', '.')}';

  final windows = RegExp(r'Windows NT ([0-9\\.]+)').firstMatch(ua)?.group(1);
  if (windows != null) return 'Windows $windows';

  if (ua.contains('Linux')) return 'Linux';

  return platform.isNotEmpty ? platform : '未知';
}
