import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/game_cover_image.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    this.shouldLoadImage = true,
    this.topLeftBadgeOffset = EdgeInsets.zero,
    this.topRightAction,
    this.topRightActionOffset = EdgeInsets.zero,
    this.showNameBlur = false,
    this.nameOverlayColor,
    this.namePadding,
  });

  final GameList game;
  final VoidCallback onTap;
  final bool shouldLoadImage;
  final EdgeInsets topLeftBadgeOffset;
  final Widget? topRightAction;
  final EdgeInsets topRightActionOffset;
  final bool showNameBlur;
  final Color? nameOverlayColor;
  final EdgeInsetsGeometry? namePadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(
          constraints,
          context,
          designWidth: 104,
        );
        final resolvedUrl = resolveGameIconUrl(game.iconUrl);
        final hasDisplayableImage =
            shouldLoadImage && resolvedUrl != null && resolvedUrl.isNotEmpty;
        final shouldShowGameName = AppConfig.shouldShowGameCardName(
          hasDisplayableImage: hasDisplayableImage,
        );

        return InkWell(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.cardBackgroundDark,
                  child: _buildCover(resolvedUrl),
                ),
                GameCardProviderBadge(
                  providerName: game.gamehall,
                  offset: topLeftBadgeOffset,
                  padding: EdgeInsets.symmetric(
                    horizontal: r.size(6),
                    vertical: r.size(3),
                  ),
                  fontSize: r.font(10),
                ),
                if (topRightAction != null)
                  Positioned(
                    right: topRightActionOffset.right,
                    top: topRightActionOffset.top,
                    child: topRightAction!,
                  ),
                if (shouldShowGameName)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _GameCardNameOverlay(
                      name: game.name ?? 'Game',
                      fontSize: r.font(10.5),
                      showBlur: showNameBlur,
                      color: nameOverlayColor,
                      padding: namePadding ??
                          EdgeInsets.symmetric(
                            horizontal: r.size(6),
                            vertical: r.size(4),
                          ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCover(String? resolvedUrl) {
    if (!shouldLoadImage || resolvedUrl == null || resolvedUrl.isEmpty) {
      return buildGameCardLogoFallback();
    }
    return GameCoverImage(
      url: resolvedUrl,
      fit: BoxFit.cover,
      fallback: buildGameCardLogoFallback(),
    );
  }
}

class GameCardProviderBadge extends StatelessWidget {
  const GameCardProviderBadge({
    super.key,
    required this.providerName,
    required this.offset,
    required this.padding,
    required this.fontSize,
  });

  final String? providerName;
  final EdgeInsets offset;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = (providerName ?? '').trim();
    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: offset.left,
      top: offset.top,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: const Color.fromARGB(83, 0, 0, 0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
          // border: Border.all(
          //   color: Colors.white.withValues(alpha: 0.1),
          // ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
        ),
      ),
    );
  }
}

class _GameCardNameOverlay extends StatelessWidget {
  const _GameCardNameOverlay({
    required this.name,
    required this.fontSize,
    required this.showBlur,
    required this.padding,
    this.color,
  });

  final String name;
  final double fontSize;
  final bool showBlur;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: showBlur ? 0.25 : 0.42),
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
      ),
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(10),
      ),
      child: showBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: content,
            )
          : content,
    );
  }
}

class GameCardFavoriteAction extends StatelessWidget {
  const GameCardFavoriteAction({
    super.key,
    required this.isFavorite,
    required this.onTap,
    required this.size,
    required this.padding,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.red : Colors.white,
          size: size,
        ),
      ),
    );
  }
}

Widget buildGameCardLogoFallback() {
  return Image.asset(
    kDefaultAppLogoAsset,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.casino, color: Colors.white38, size: 40),
  );
}

String? resolveGameIconUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final trimmed = url.trim();
  if (trimmed.startsWith('http')) return trimmed;
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${AppConfig.gameIconBaseUrl}$path';
}
