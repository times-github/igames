import 'package:flutter/material.dart';

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
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      webHtmlElementStrategy: _shouldUseWebHtmlFallback(url)
          ? WebHtmlElementStrategy.fallback
          : WebHtmlElementStrategy.never,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

bool _shouldUseWebHtmlFallback(String url) {
  final normalized = url.toLowerCase();
  return normalized.endsWith('.avif') ||
      normalized.contains('.avif?') ||
      normalized.contains('.avif#');
}
