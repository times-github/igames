import 'dart:io';

import 'device_info_models.dart';

Future<RawDeviceInfo> loadPlatformDeviceInfo() async {
  final os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  final model = Platform.localHostname.isNotEmpty
      ? Platform.localHostname
      : Platform.operatingSystem;

  return RawDeviceInfo(
    model: model,
    osVersion: os,
    browserVersion: 'App built-in',
    browserEngine: Platform.operatingSystem,
    flutterRuntime: 'Native App',
    host: Platform.localHostname,
    userAgent: '',
  );
}
