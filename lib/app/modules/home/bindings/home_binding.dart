import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/modules/widgets/gameMenu/bindings/game_menu_binding.dart';

import '../controllers/home_controller.dart';
import '../controllers/promo_controller.dart';

/// HomeBinding - 仅负责页面级Controller
/// 注意：全局Services已在main.dart中注册，这里不再重复注册
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // 全局认证服务（如果未注册则注册）
    // AuthController 需要在多个地方使用，作为全局服务
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    // 页面级控制器（非permanent，跟随页面生命周期）
    Get.put(HomeController());
    Get.lazyPut<PromoController>(() => PromoController());
    Get.lazyPut<LanguageSelectorController>(() => LanguageSelectorController());

    // 游戏菜单控制器
    GameMenuBinding().dependencies();
  }
}
