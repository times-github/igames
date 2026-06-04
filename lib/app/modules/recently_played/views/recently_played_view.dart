import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/modules/widgets/game_card.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/config/app_config_export.dart';
import '../controllers/recently_played_controller.dart';

class RecentlyPlayedView extends GetView<RecentlyPlayedController> {
  const RecentlyPlayedView({super.key});

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

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppConfig.homeGameGridCrossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: AppConfig.gameCardAspectRatio,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GameCard(
          game: game,
          showNameBlur: true,
          topLeftBadgeOffset: const EdgeInsets.only(left: 8, top: 8),
          onTap: onTap,
        );
      },
    );
  }
}
