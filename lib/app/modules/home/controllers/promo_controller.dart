import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';

class PromoCategory {
  PromoCategory({
    required this.id,
    required this.name,
    required this.shortName,
  });

  final int id;
  final String name;
  final String shortName;
}

class PromoActivity {
  PromoActivity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.picture,
    required this.categoryId,
    required this.endAt,
  });

  final int id;
  final String title;
  final String subtitle;
  final String picture;
  final int? categoryId;
  final String? endAt;
}

class PromoController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  final categories = <PromoCategory>[].obs;
  final selectedId = RxnInt();
  final isLoading = false.obs;
  final loadError = false.obs;
  final activities = <PromoActivity>[].obs;
  final isLoadingList = false.obs;
  final listError = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchActivities();
  }

  String _resolveLang() {
    var lang = Get.locale?.languageCode ?? 'id';
    if (lang == 'zh') {
      lang = 'zh-cn';
    }
    return lang;
  }

  Future<void> fetchCategories() async {
    if (isLoading.value) return;
    isLoading.value = true;
    loadError.value = false;
    try {
      final response = await _apiClient.get(
        '/user/activity/categories',
        queryParameters: {'lang': _resolveLang()},
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
        final data = responseData['data'];
        final listRaw =
            data is Map && data['list'] is List ? data['list'] as List : <dynamic>[];
        final items = listRaw
            .whereType<Map>()
            .map((item) => _mapToCategory(Map<String, dynamic>.from(item)))
            .toList();
        categories.assignAll(items);
      } else {
        loadError.value = true;
      }
    } catch (e) {
      debugPrint('加载优惠分类失败: $e');
      loadError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(PromoCategory category) {
    if (selectedId.value == category.id) return;
    selectedId.value = category.id;
    fetchActivities(categoryId: category.id);
  }

  void selectAll() {
    if (selectedId.value == null) return;
    selectedId.value = null;
    fetchActivities();
  }

  Future<void> fetchActivities({int? categoryId}) async {
    if (isLoadingList.value) return;
    isLoadingList.value = true;
    listError.value = false;
    try {
      final response = await _apiClient.get(
        '/user/activity/list',
        queryParameters: {
          'lang': _resolveLang(),
          if (categoryId != null) 'category_id': categoryId.toString(),
        },
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
        final data = responseData['data'];
        final listRaw =
            data is Map && data['list'] is List ? data['list'] as List : <dynamic>[];
        final items = listRaw
            .whereType<Map>()
            .map((item) => _mapToActivity(Map<String, dynamic>.from(item)))
            .toList();
        activities.assignAll(items);
      } else {
        listError.value = true;
        activities.clear();
      }
    } catch (e) {
      debugPrint('加载优惠列表失败: $e');
      listError.value = true;
      activities.clear();
    } finally {
      isLoadingList.value = false;
    }
  }

  PromoCategory _mapToCategory(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name']?.toString() ?? '';
    final shortName =
        (json['shortName'] ?? json['short_name'] ?? '').toString();
    return PromoCategory(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      name: name,
      shortName: shortName,
    );
  }

  PromoActivity _mapToActivity(Map<String, dynamic> json) {
    final id = json['id'];
    final endAtRaw = json['end_at'];
    String? endAt;
    if (endAtRaw != null) {
      final normalized = endAtRaw.toString();
      if (normalized != '0' && normalized.isNotEmpty) {
        endAt = normalized;
      }
    }
    return PromoActivity(
      id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      picture: (json['title_picture'] ??
              json['titlePicture'] ??
              json['picture'] ??
              '')
          .toString(),
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse(json['category_id']?.toString() ?? ''),
      endAt: endAt,
    );
  }
}
