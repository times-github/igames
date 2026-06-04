import 'package:flutter/material.dart';
import 'package:igames/config/app_config.dart';

const double _kResponsiveMaxScale = 1.0;

/// 基于真实容器宽度的局部响应式工具。
///
/// 适合当前项目这种中间手机壳布局：
/// - 组件按自身可用宽度压缩
/// - 不做整站 Transform.scale
/// - 保证点击区域、弹窗、iframe 更稳定
class Responsive {
  const Responsive._({
    required this.width,
    required this.scale,
  });

  factory Responsive.fromContext(
    BuildContext context, {
    double designWidth = AppConfig.webDesktopShellWidth,
  }) {
    final mediaWidth = MediaQuery.sizeOf(context).width;
    return Responsive._fromWidth(
      mediaWidth,
      designWidth: designWidth,
    );
  }

  factory Responsive.fromConstraints(
    BoxConstraints constraints,
    BuildContext context, {
    double designWidth = AppConfig.webDesktopShellWidth,
  }) {
    final resolvedWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    return Responsive._fromWidth(
      resolvedWidth,
      designWidth: designWidth,
    );
  }

  factory Responsive._fromWidth(
    double resolvedWidth, {
    required double designWidth,
  }) {
    final safeWidth = resolvedWidth.isFinite && resolvedWidth > 0
        ? resolvedWidth
        : designWidth;
    final rawScale = safeWidth / designWidth;
    final safeScale =
        rawScale > _kResponsiveMaxScale ? _kResponsiveMaxScale : rawScale;
    return Responsive._(
      width: safeWidth,
      scale: safeScale,
    );
  }

  final double width;
  final double scale;

  double size(double base) => base * scale;

  double font(double base) => base * scale;
}
