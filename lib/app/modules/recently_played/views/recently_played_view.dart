import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/config/app_config_export.dart';
import '../controllers/recently_played_controller.dart';

class RecentlyPlayedView extends GetView<RecentlyPlayedController> {
  const RecentlyPlayedView({super.key});

  @override
  Widget build(BuildContext context) {
    final menuController = Get.find<GameMenuController>();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'recentlyPlayed'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.games.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.games.isEmpty) {
          return Center(
            child: Text(
              'recentlyPlayedEmpty'.tr,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 3;
            if (width >= 1000) {
              crossAxisCount = 6;
            } else if (width >= 820) {
              crossAxisCount = 5;
            } else if (width >= 620) {
              crossAxisCount = 4;
            }
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.05,
              ),
              itemCount: controller.games.length,
              itemBuilder: (context, index) {
                final game = controller.games[index];
                return _RecentGameCard(
                  game: game,
                  onTap: () => menuController.startGame(context, game),
                );
              },
            );
          },
        );
      }),
    );
  }
}

class _RecentGameCard extends StatelessWidget {
  const _RecentGameCard({
    required this.game,
    required this.onTap,
  });

  final GameList game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveGameIconUrl(game.iconUrl);
    return InkWell(
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AppColors.cardBackground, AppColors.backgroundLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.cardBackgroundDark,
                child: resolvedUrl != null && resolvedUrl.isNotEmpty
                    ? Image.network(
                        resolvedUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _gameCardLogoFallback(),
                      )
                    : _gameCardLogoFallback(),
              ),
              if ((game.gamehall ?? '').isNotEmpty)
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      game.gamehall ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(10)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        game.name ?? 'Game',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _gameCardLogoFallback() {
  return Image.asset(
    kDefaultAppLogoAsset,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.casino, color: Colors.white38, size: 40),
  );
}

String? _resolveGameIconUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  final trimmed = url.startsWith('/') ? url.substring(1) : url;
  return '${AppConfig.gameIconBaseUrl}$trimmed';
}
