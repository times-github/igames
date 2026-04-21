/// 原始设备信息，聚合自不同平台。
class RawDeviceInfo {
  final String model;
  final String osVersion;
  final String browserVersion;
  final String browserEngine;
  final String flutterRuntime;
  final String host;
  final String userAgent;

  const RawDeviceInfo({
    required this.model,
    required this.osVersion,
    required this.browserVersion,
    required this.browserEngine,
    required this.flutterRuntime,
    required this.host,
    required this.userAgent,
  });
}

/// 展示层设备信息。
class DeviceInfoData {
  final String model;
  final String osVersion;
  final String loginPort;
  final String browserVersion;
  final String browserEngine;
  final String flutterRuntime;
  final String currentTime;
  final String userAgent;

  const DeviceInfoData({
    required this.model,
    required this.osVersion,
    required this.loginPort,
    required this.browserVersion,
    required this.browserEngine,
    required this.flutterRuntime,
    required this.currentTime,
    required this.userAgent,
  });
}
