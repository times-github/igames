import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/utils/storage.dart';
import '../models/jackpot.dart';
import '../../utils/api_client.dart';

class JackpotService extends GetxService {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final jackpotList = <JackpotRecord>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJackpotList();
  }

  /// 获取奖池中奖记录
  Future<void> fetchJackpotList() async {
    try {
      isLoading.value = true;

      // 获取当前语言
      final lang = await _resolveLang();

      final response = await _apiClient.get(
        '/user/jackpot/list',
        queryParameters: {
          'lang': lang,
        },
        withAuth: false,
      );

      if (response.statusCode == 200 && response.data != null) {
        final jackpotResponse = JackpotResponse.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );

        if (jackpotResponse.code == 1 &&
            jackpotResponse.data?.list != null) {
          jackpotList.value = jackpotResponse.data!.list!;
        }
      }
    } catch (e) {
      debugPrint('获取奖池记录失败: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新奖池记录
  Future<void> refresh() async {
    await fetchJackpotList();
  }

  Future<String> _resolveLang() async {
    String lang = '';
    if (Get.isRegistered<LanguageSelectorController>()) {
      lang = Get.find<LanguageSelectorController>().currentCode.value;
    }
    if (lang.isEmpty) {
      final stored = await Storage.getData("language");
      if (stored is String) {
        lang = stored;
      }
    }
    if (lang.isEmpty) {
      lang = Get.locale?.languageCode ?? 'id';
    }
    final normalized = lang.toLowerCase();
    if (normalized == 'zh' ||
        normalized == 'zh-cn' ||
        normalized == 'zh_cn') {
      return 'zh-cn';
    }
    if (normalized == 'id' ||
        normalized == 'id-id' ||
        normalized == 'id_id') {
      return 'id';
    }
    if (normalized == 'en' ||
        normalized == 'en-us' ||
        normalized == 'en_us') {
      return 'en';
    }
    return normalized;
  }
}
