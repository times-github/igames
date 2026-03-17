import 'device_info_models.dart';

/// 非 web/io 平台的兜底实现（理论不会命中）。
Future<RawDeviceInfo> loadPlatformDeviceInfo() async {
  return const RawDeviceInfo(
    model: '',
    osVersion: '',
    browserVersion: '',
    browserEngine: '',
    host: '',
    userAgent: '',
  );
}
