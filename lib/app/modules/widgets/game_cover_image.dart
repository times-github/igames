import 'package:flutter/material.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';

class GameCoverImage extends StatelessWidget {
  const GameCoverImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return CompatibleImage.network(
      url,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
