import 'package:get/get.dart';

import '../controllers/game_menu_controller.dart';

class GameMenuBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GameMenuController>(() => GameMenuController());
  }
}
