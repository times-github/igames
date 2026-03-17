import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/utils/api_client.dart';

class RecentlyPlayedController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final AuthController _auth = Get.find<AuthController>();

  final games = <GameList>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchRecentlyPlayed();
  }

  String _resolveLang() {
    var lang = Get.locale?.languageCode ?? 'id';
    if (lang == 'zh') {
      lang = 'zh-cn';
    }
    return lang;
  }

  Future<void> fetchRecentlyPlayed() async {
    if (!_auth.isLoggedIn.value) return;
    isLoading.value = true;
    try {
      final response = await _apiClient.get(
        '/user/recently-played-games',
        queryParameters: {
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
        final listRaw =
            data is Map && data['list'] is List ? data['list'] as List : <dynamic>[];
        final items = listRaw
            .whereType<Map>()
            .map((item) => _mapToGame(Map<String, dynamic>.from(item)))
            .toList();
        games.assignAll(items);
      } else {
        games.clear();
      }
    } catch (e) {
      debugPrint('加载最近游戏失败: $e');
      games.clear();
    } finally {
      isLoading.value = false;
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
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}
