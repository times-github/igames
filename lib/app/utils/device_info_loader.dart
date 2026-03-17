import 'package:flutter/foundation.dart';

import 'device_info_loader_stub.dart'
    if (dart.library.html) 'device_info_loader_web.dart'
    if (dart.library.io) 'device_info_loader_io.dart';
import 'device_info_models.dart';

/// 设备信息服务，负责聚合并格式化设备信息。
class DeviceInfoService {
  static Future<DeviceInfoData> load() async {
    final raw = await loadPlatformDeviceInfo();
    final now = DateTime.now();
    final formattedTime = _formatDateWithOffset(now);

    return DeviceInfoData(
      //英文
      model: _fallback(raw.model, 'unknown model'),
      osVersion: _fallback(raw.osVersion, 'unknown os version'),
      loginPort: kIsWeb ? 'h5' : 'app',
      browserVersion: _fallback(raw.browserVersion, 'unknown browser version'),
      browserEngine: _fallback(raw.browserEngine, 'unknown browser engine'),
      currentTime: formattedTime,
      userAgent: _fallback(raw.userAgent, ''),
    );
  }

  static String _fallback(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed;
  }

  static String _formatDateWithOffset(DateTime dateTime) {
    final offset = dateTime.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.inMinutes >= 0 ? '+' : '-';

    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final h = dateTime.hour.toString().padLeft(2, '0');
    final min = dateTime.minute.toString().padLeft(2, '0');
    final s = dateTime.second.toString().padLeft(2, '0');

    return '$y-$m-${d}T$h:$min:$s$sign$hours:$minutes';
  }
}
