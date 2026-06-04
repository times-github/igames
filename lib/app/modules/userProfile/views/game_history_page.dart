import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import '../controllers/user_profile_controller.dart';
import 'game_history_view.dart';

/// 独立的投注记录页面（无侧边栏）
class GameHistoryPage extends StatelessWidget {
  const GameHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保控制器已就绪
    final controller = Get.find<UserProfileController>();
    // 每次进入默认展示全部
    controller.setGameFilter('all');
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: AppBackButton(
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'gameHistory'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        body: const GameHistoryView(),
      ),
    );
  }
}
