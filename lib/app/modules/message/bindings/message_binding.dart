import 'package:get/get.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import '../controllers/message_controller.dart';

class MessageBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AnnouncementService>()) {
      Get.put(AnnouncementService(), permanent: true);
    }
    Get.lazyPut<MessageController>(() => MessageController());
  }
}
