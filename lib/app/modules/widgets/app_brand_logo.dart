import 'package:flutter/material.dart';

const String kDefaultAppLogoAsset = 'assets/images/getwiner.png';

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    required this.logo,
    this.padding = const EdgeInsets.all(4),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.showBackground = true,
    this.backgroundColor = const Color(0x16000000),
    this.borderColor = const Color(0x24FFFFFF),
    this.placeholder,
  });

  final String logo;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final BoxFit fit;
  final Alignment alignment;
  final bool showBackground;
  final Color backgroundColor;
  final Color borderColor;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        decoration: showBackground
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: borderRadius,
                border: Border.all(color: borderColor),
              )
            : null,
        padding: padding,
        alignment: alignment,
        child: _buildImage(logo),
      ),
    );
    return child;
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => _buildDefaultAsset(),
      );
    }

    if (path.isEmpty || path == kDefaultAppLogoAsset) {
      return _buildDefaultAsset();
    }

    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => _buildDefaultAsset(),
    );
  }

  Widget _buildDefaultAsset() {
    return Image.asset(
      kDefaultAppLogoAsset,
      fit: fit,
      alignment: alignment,
      errorBuilder: (_, __, ___) => placeholder ?? _defaultPlaceholder(),
    );
  }

  Widget _defaultPlaceholder() {
    return Icon(
      Icons.casino,
      color: Colors.white.withValues(alpha: 0.9),
      size: 24,
    );
  }
}
