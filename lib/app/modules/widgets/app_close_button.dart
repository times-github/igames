import 'package:flutter/material.dart';
import 'package:igames/app/utils/responsive.dart';

class AppCloseIcon extends StatelessWidget {
  const AppCloseIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final resolvedSize = r.size(size);
    return Icon(
      Icons.close_rounded,
      size: resolvedSize,
      color: color ?? Colors.white.withValues(alpha: 0.82),
    );
  }
}

class AppCloseButton extends StatelessWidget {
  const AppCloseButton({
    super.key,
    this.onPressed,
    this.size = 24,
    this.minTapSize = 40,
    this.padding = EdgeInsets.zero,
  });

  final VoidCallback? onPressed;
  final double size;
  final double minTapSize;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final resolvedTapSize = r.size(minTapSize);
    return IconButton(
      padding: padding,
      constraints: BoxConstraints(
        minWidth: resolvedTapSize,
        minHeight: resolvedTapSize,
      ),
      onPressed: onPressed,
      icon: AppCloseIcon(size: size),
    );
  }
}
