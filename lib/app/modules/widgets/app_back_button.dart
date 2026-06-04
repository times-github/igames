import 'package:flutter/material.dart';
import 'package:igames/app/utils/responsive.dart';

const String kNavBackAsset = 'assets/images/navv_back.png';

class AppBackIcon extends StatelessWidget {
  const AppBackIcon({
    super.key,
    this.size = 28,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final resolvedSize = r.size(size);
    return Image.asset(
      kNavBackAsset,
      width: resolvedSize,
      height: resolvedSize,
      fit: BoxFit.contain,
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 28,
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
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      icon: AppBackIcon(size: size),
    );
  }
}
