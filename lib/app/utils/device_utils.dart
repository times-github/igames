import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 应用断点常量
class AppBreakpoints {
  /// 手机断点
  static const double mobile = 768.0;

  /// 平板断点
  static const double tablet = 1024.0;

  /// 桌面断点
  static const double desktop = 1200.0;

  /// 大桌面断点
  static const double largeDesktop = 1440.0;
}

/// 应用尺寸常量
class AppSizes {
  /// 基础间距单位
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  /// 容器最大宽度
  static const double maxWidth = 1200.0;

  /// 侧边栏宽度
  static const double sidebarWidth = 280.0;

  /// 卡片圆角
  static const double cardRadius = 12.0;

  /// 按钮圆角
  static const double buttonRadius = 8.0;
}

/// 响应式工具类
class DeviceUtils {
  /// 判断是否为Web平台
  static bool get isWeb => kIsWeb;

  /// 判断是否为移动平台
  static bool get isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 判断是否为移动设备（基于平台/UA，不随窗口大小变化）
  static bool get isMobileDevice {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 判断是否为桌面平台
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// 获取当前平台名称
  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  /// 判断是否为手机（基于屏幕宽度）
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.mobile;
  }

  /// 判断是否使用手机布局（考虑横竖屏情况下的最短边）
  static bool isCompactLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    return shortestSide < AppBreakpoints.mobile;
  }

  /// 判断是否为平板（基于屏幕宽度）
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppBreakpoints.mobile && width < AppBreakpoints.tablet;
  }

  /// 判断是否为桌面（基于屏幕宽度）
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.tablet;
  }

  /// 判断是否为小屏幕
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < AppBreakpoints.tablet;
  }

  /// 判断是否为大屏幕
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
  }

  /// 获取当前设备类型（基于屏幕宽度）
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) return DeviceType.mobile;
    if (width < AppBreakpoints.tablet) return DeviceType.tablet;
    if (width < AppBreakpoints.desktop) return DeviceType.desktop;
    return DeviceType.largeDesktop;
  }

  /// 获取屏幕信息
  static ScreenInfo getScreenInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return ScreenInfo(
      width: mediaQuery.size.width,
      height: mediaQuery.size.height,
      pixelRatio: mediaQuery.devicePixelRatio,
      textScaleFactor: mediaQuery.textScaleFactor,
      platformBrightness: mediaQuery.platformBrightness,
    );
  }

  /// 根据屏幕宽度返回不同的值
  static T responsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);

    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// 获取响应式边距
  static EdgeInsets responsivePadding(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: const EdgeInsets.all(AppSizes.md),
      tablet: const EdgeInsets.all(AppSizes.lg),
      desktop: const EdgeInsets.all(AppSizes.xl),
    );
  }

  /// 获取响应式列数
  static int responsiveColumns(BuildContext context) {
    return responsiveValue(
      context: context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
  }

  /// 获取响应式字体大小
  static double responsiveFontSize(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsiveValue(
      context: context,
      mobile: mobile ?? 14.0,
      tablet: tablet ?? 16.0,
      desktop: desktop ?? 18.0,
      largeDesktop: largeDesktop ?? 20.0,
    );
  }

  /// 获取响应式间距
  static double responsiveSpacing(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    double? largeDesktop,
  }) {
    return responsiveValue(
      context: context,
      mobile: mobile ?? AppSizes.md,
      tablet: tablet ?? AppSizes.lg,
      desktop: desktop ?? AppSizes.xl,
      largeDesktop: largeDesktop ?? AppSizes.xxl,
    );
  }

  /// 判断是否为横屏
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// 判断是否为竖屏
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// 获取安全区域信息
  static EdgeInsets getSafeAreaInsets(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// 判断是否为深色模式
  static bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  /// 判断是否为浅色模式
  static bool isLightMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.light;
  }

  /// 获取设备详细信息
  static DeviceInfo getDeviceInfo(BuildContext context) {
    return DeviceInfo(
      isWeb: isWeb,
      platform: platformName,
      deviceType: getDeviceType(context),
      screenInfo: getScreenInfo(context),
      isLandscape: isLandscape(context),
      isDarkMode: isDarkMode(context),
    );
  }
}

/// 设备类型枚举
enum DeviceType {
  mobile, // 手机
  tablet, // 平板
  desktop, // 桌面
  largeDesktop, // 大桌面
}

/// 屏幕信息类
class ScreenInfo {
  final double width;
  final double height;
  final double pixelRatio;
  final double textScaleFactor;
  final Brightness platformBrightness;

  const ScreenInfo({
    required this.width,
    required this.height,
    required this.pixelRatio,
    required this.textScaleFactor,
    required this.platformBrightness,
  });

  @override
  String toString() {
    return 'ScreenInfo(width: $width, height: $height, pixelRatio: $pixelRatio, textScaleFactor: $textScaleFactor)';
  }
}

/// 设备信息类
class DeviceInfo {
  final bool isWeb;
  final String platform;
  final DeviceType deviceType;
  final ScreenInfo screenInfo;
  final bool isLandscape;
  final bool isDarkMode;

  const DeviceInfo({
    required this.isWeb,
    required this.platform,
    required this.deviceType,
    required this.screenInfo,
    required this.isLandscape,
    required this.isDarkMode,
  });

  @override
  String toString() {
    return 'DeviceInfo(isWeb: $isWeb, platform: $platform, deviceType: $deviceType, isLandscape: $isLandscape, isDarkMode: $isDarkMode)';
  }
}
