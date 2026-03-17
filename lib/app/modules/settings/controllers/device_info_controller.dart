import 'package:get/get.dart';

import '../../../utils/device_info_loader.dart';
import '../../../utils/device_info_models.dart';

class DeviceInfoController extends GetxController {
  final info = Rxn<DeviceInfoData>();
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadInfo();
  }

  Future<void> loadInfo() async {
    loading.value = true;
    info.value = await DeviceInfoService.load();
    loading.value = false;
  }
}
