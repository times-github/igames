import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/utils/api_client.dart';

class FavoritesController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final AuthController _auth = Get.find<AuthController>();

  final favorites = <GameList>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final currentPage = 1.obs;
  final int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    fetchFavorites(refresh: true);
  }

  String _resolveLang() {
    return normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
    );
  }

  Future<void> refreshFavorites() async {
    await fetchFavorites(refresh: true);
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;
    await fetchFavorites();
  }

  Future<void> fetchFavorites({bool refresh = false}) async {
    if (!_auth.isLoggedIn.value) return;

    if (refresh) {
      currentPage.value = 1;
      hasMore.value = true;
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final response = await _apiClient.get(
        '/user/favorite-games',
        queryParameters: {
          'page': currentPage.value.toString(),
          'size': pageSize.toString(),
          'lang': _resolveLang(),
        },
        withAuth: true,
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
        final listRaw = data is Map && data['list'] is List
            ? data['list'] as List
            : <dynamic>[];

        final newItems = listRaw
            .whereType<Map>()
            .map((item) => _mapToGame(Map<String, dynamic>.from(item)))
            .toList();

        if (refresh) {
          favorites.assignAll(newItems);
        } else {
          favorites.addAll(newItems);
        }

        if (newItems.length < pageSize) {
          hasMore.value = false;
        } else {
          currentPage.value = currentPage.value + 1;
        }
      } else {
        hasMore.value = false;
      }
    } catch (e) {
      debugPrint('加载收藏失败: $e');
      if (refresh) {
        favorites.clear();
      }
      hasMore.value = false;
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> removeFavorite(GameList game) async {
    if (!_auth.isLoggedIn.value) {
      final ctx = Get.context;
      if (ctx != null) {
        _auth.openLoginOverlay(ctx);
      }
      return;
    }
    final gamecode = game.gamecode ?? '';
    final gamehall = game.gamehall ?? '';
    if (gamecode.isEmpty || gamehall.isEmpty) return;

    try {
      final response = await _apiClient.delete(
        '/user/favorite-games',
        queryParameters: {
          'gamecode': gamecode,
          'gamehall': gamehall,
        },
        withAuth: true,
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
        favorites.remove(game);
        Get.snackbar(
          'transactionStatus_success'.tr,
          'favoriteRemoveSuccess'.tr,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        final msg = responseData['msg']?.toString();
        Get.snackbar(
          'transactionStatus_failed'.tr,
          (msg == null || msg.isEmpty) ? 'favoriteRemoveFailed'.tr : msg,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('取消收藏失败: $e');
      Get.snackbar(
        'transactionStatus_failed'.tr,
        'favoriteRemoveFailed'.tr,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  GameList _mapToGame(Map<String, dynamic> json) {
    return GameList(
      id: json['id'] as int?,
      gamecode: json['gamecode']?.toString(),
      gamehall: json['gamehall']?.toString(),
      gametype: (json['game_type'] ?? json['gametype'])?.toString(),
      gametech: json['gametech']?.toString(),
      name: (json['game_name'] ?? json['name'])?.toString(),
      iconUrl: json['icon_url']?.toString(),
      lang: json['lang']?.toString(),
      isFavorite: json['is_favorite'] ?? true,
    );
  }
}
