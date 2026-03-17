// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

import 'device_info_models.dart';

Future<RawDeviceInfo> loadPlatformDeviceInfo() async {
  final navigator = html.window.navigator;
  final userAgent = navigator.userAgent;
  final platform = navigator.platform ?? '';
  final host = html.window.location.host;

  final browserVersion = _parseBrowser(userAgent);
  final engine = _parseEngine(userAgent, browserVersion);
  final model = _parseModel(userAgent, platform);
  final osVersion = _parseOs(userAgent, platform);

  return RawDeviceInfo(
    model: model,
    osVersion: osVersion,
    browserVersion: browserVersion,
    browserEngine: engine,
    host: host,
    userAgent: userAgent,
  );
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
  final androidModel =
      RegExp(r'Android [^;\)]+;\s*([^)]+)\)').firstMatch(ua)?.group(1);
  if (androidModel != null) return androidModel.trim();

  if (ua.contains('iPhone')) return 'iPhone';
  if (ua.contains('iPad')) return 'iPad';
  if (ua.contains('Macintosh')) return 'Macintosh';
  if (ua.contains('Windows')) return 'Windows PC';

  return platform.isNotEmpty ? platform : '未知';
}

String _parseOs(String ua, String platform) {
  final android = RegExp(r'Android ([^;\s\)]+)').firstMatch(ua)?.group(1);
  if (android != null) return 'Android $android';

  final ios =
      RegExp(r'CPU (?:iPhone )?OS ([0-9_]+)').firstMatch(ua)?.group(1);
  if (ios != null) return 'iOS ${ios.replaceAll('_', '.')}';

  final mac = RegExp(r'Mac OS X ([0-9_\\.]+)').firstMatch(ua)?.group(1);
  if (mac != null) return 'macOS ${mac.replaceAll('_', '.')}';

  final windows = RegExp(r'Windows NT ([0-9\\.]+)').firstMatch(ua)?.group(1);
  if (windows != null) return 'Windows $windows';

  if (ua.contains('Linux')) return 'Linux';

  return platform.isNotEmpty ? platform : '未知';
}
