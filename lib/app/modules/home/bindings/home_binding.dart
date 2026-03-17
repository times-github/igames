import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/modules/widgets/gameMenu/bindings/game_menu_binding.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/data/services/notification_center_service.dart';
import 'package:igames/app/data/services/sse_notify_service.dart';

import '../controllers/home_controller.dart';
import '../controllers/promo_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 全局服务 - 先注册依赖（顺序重要）
    if (!Get.isRegistered<ApiClient>()) {
      Get.put(ApiClient(), permanent: true); // ✅ 自动初始化
    }
    Get.put(AuthController(), permanent: true); // ✅ 全局认证服务
    if (!Get.isRegistered<AppInfoService>()) {
      Get.put(AppInfoService(), permanent: true);
    }
    if (!Get.isRegistered<AnnouncementService>()) {
      Get.put(AnnouncementService(), permanent: true);
    }
    if (!Get.isRegistered<NotificationCenterService>()) {
      Get.put(NotificationCenterService(), permanent: true);
    }
    if (!Get.isRegistered<SseNotifyService>()) {
      Get.put(SseNotifyService(), permanent: true);
    }

    // 页面控制器
    Get.put(HomeController());
    Get.lazyPut<PromoController>(() => PromoController());
    Get.lazyPut<LanguageSelectorController>(() => LanguageSelectorController());
    GameMenuBinding().dependencies(); // ✅ 游戏菜单控制器
  }
}
