import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'promo_controller.dart';

class PromoDetailController extends GetxController {
  PromoDetailController({required this.activity});

  final PromoActivity activity;
  final ApiClient _apiClient = Get.find<ApiClient>();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final content = ''.obs;
  final title = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _apiClient.get(
        '/user/activity/${activity.id}',
        withAuth: false,
      );

      Map<String, dynamic> responseData;
      if (response.data == null) {
        responseData = {};
      } else if (response.data is Map) {
        responseData = Map<String, dynamic>.from(response.data as Map);
      } else {
        responseData = Map<String, dynamic>.from(
          jsonDecode(response.data.toString()) as Map,
        );
      }

      if (response.statusCode == 200 && responseData['code'] == 1) {
        final data = responseData['data'] is Map
            ? Map<String, dynamic>.from(responseData['data'] as Map)
            : <String, dynamic>{};
        final newTitle = data['title']?.toString() ?? '';
        final newContent = data['content']?.toString();
        title.value = newTitle;
        content.value = newContent ?? '';
      } else {
        errorMessage.value =
            responseData['msg']?.toString() ?? 'networkError'.tr;
      }
    } catch (e) {
      debugPrint('加载活动详情失败: $e');
      errorMessage.value = 'networkError'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}
