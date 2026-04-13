import 'package:get/get.dart';
import 'package:igames/utils/web_update_bridge.dart';

class WebUpdateService extends GetxService {
  final isUpdateAvailable = false.obs;
  final isApplyingUpdate = false.obs;
  final pendingVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeWebUpdateBridge(onUpdateAvailable: _handleUpdateAvailable);
  }

  void _handleUpdateAvailable(String? version) {
    pendingVersion.value = version ?? '';
    isApplyingUpdate.value = false;
    isUpdateAvailable.value = true;
  }

  Future<void> applyUpdate() async {
    if (!isUpdateAvailable.value || isApplyingUpdate.value) {
      return;
    }

    isApplyingUpdate.value = true;
    await applyPendingWebUpdate();
  }

  void dismissUpdate() {
    isApplyingUpdate.value = false;
    isUpdateAvailable.value = false;
    pendingVersion.value = '';
    dismissPendingWebUpdate();
  }
}
