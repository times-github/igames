import 'package:get/get.dart';
import '../controllers/game_start_controller.dart';
import '../../../utils/api_client.dart';

class GameStartBinding extends Bindings {
  @override
  void dependencies() {
    // 注册 ApiClient
    Get.lazyPut<ApiClient>(() => ApiClient());

    // 注册控制器
    Get.lazyPut<GameStartController>(() => GameStartController());
  }
}
