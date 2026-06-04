import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/modules/widgets/game_card.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';
import '../controllers/favorites_controller.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final menuController = Get.find<GameMenuController>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          onPressed: () => Get.back(),
        ),
        title: Text(
          'myFavorites'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.favorites.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (controller.favorites.isEmpty) {
          return Center(
            child: Text(
              'favoritesEmpty'.tr,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshFavorites,
          color: AppColors.primary,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppConfig.homeGameGridCrossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: AppConfig.gameCardAspectRatio,
            ),
            itemCount: controller.favorites.length +
                (controller.hasMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.favorites.length) {
                controller.loadMore();
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  ),
                );
              }
              final game = controller.favorites[index];
              return _FavoriteGameCard(
                game: game,
                onTap: () => menuController.startGame(context, game),
                onFavoriteTap: () => controller.removeFavorite(game),
              );
            },
          ),
        );
      }),
    );
  }
}

class _FavoriteGameCard extends StatelessWidget {
  const _FavoriteGameCard({
    required this.game,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final GameList game;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(
          constraints,
          context,
          designWidth: 104,
        );

        return GameCard(
          game: game,
          showNameBlur: true,
          topLeftBadgeOffset: const EdgeInsets.only(left: 8, top: 8),
          topRightActionOffset: const EdgeInsets.only(right: 8, top: 8),
          topRightAction: GameCardFavoriteAction(
            isFavorite: true,
            size: r.size(18),
            padding: EdgeInsets.all(r.size(6)),
            onTap: onFavoriteTap,
          ),
          onTap: onTap,
        );
      },
    );
  }
}
