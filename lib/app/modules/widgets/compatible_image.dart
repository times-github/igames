import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum _CompatibleImageSource { asset, network }

class CompatibleImage extends StatelessWidget {
  const CompatibleImage.asset(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = false,
    this.errorBuilder,
    this.loadingBuilder,
  }) : _source = _CompatibleImageSource.asset;

  const CompatibleImage.network(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.medium,
    this.gaplessPlayback = true,
    this.errorBuilder,
    this.loadingBuilder,
  }) : _source = _CompatibleImageSource.network;

  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final _CompatibleImageSource _source;

  @override
  Widget build(BuildContext context) {
    switch (_source) {
      case _CompatibleImageSource.asset:
        return _buildAssetImage();
      case _CompatibleImageSource.network:
        return _buildNetworkImage(path);
    }
  }

  Widget _buildAssetImage() {
    if (kIsWeb && _shouldUseWebHtmlFallback(path)) {
      return _buildNetworkImage(_resolveWebAssetUrl(path));
    }

    return Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      errorBuilder: errorBuilder,
    );
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: gaplessPlayback,
      webHtmlElementStrategy: _shouldUseWebHtmlFallback(url)
          ? WebHtmlElementStrategy.fallback
          : WebHtmlElementStrategy.never,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}

String _resolveWebAssetUrl(String path) {
  if (path.startsWith('assets/')) {
    return 'assets/$path';
  }
  return path;
}

bool _shouldUseWebHtmlFallback(String path) {
  final normalized = path.toLowerCase();
  return normalized.endsWith('.avif') ||
      normalized.contains('.avif?') ||
      normalized.contains('.avif#');
}
