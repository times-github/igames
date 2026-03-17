import "../../utils/storage.dart";
import 'package:flutter/foundation.dart'; // Added for debugPrint

class UserServices {
  static String? _cachedToken;

  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final userProfileRaw = await Storage.getData("user_profile");
      // 如果是 Map，兜底转换为 <String, dynamic>
      if (userProfileRaw is Map) {
        return Map<String, dynamic>.from(userProfileRaw);
      }
    } catch (e) {
      debugPrint('解析用户信息失败: $e');
    }

    // 返回默认值
    return {
      'account': '',
      'avatar': '',
      'nickname': '',
    };
  }

  static Future<bool> getUserLoginState() async {
    // 优先根据 token 判断
    final token = await getToken();
    if (token != null && token.isNotEmpty) return true;
    return false;
  }

  // 保存后端返回的用户信息（token/avatar/nickname）
  static Future<void> setUserInfo({
    required String token,
    String? avatar,
    String? nickname,
    required String account,
  }) async {
    _cachedToken = token;
    await Storage.setData("auth_token", token);
    await Storage.setData("user_profile", {
      "avatar": avatar ?? "",
      "account": account,
      "nickname": nickname ?? "",
    });
  }

  // 仅设置 token（可用于刷新）
  static Future<void> setToken(String token) async {
    _cachedToken = token;
    await Storage.setData("auth_token", token);
  }

  // 获取 token（带内存缓存）
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final token = await Storage.getData("auth_token");
    if (token is String) {
      _cachedToken = token;
      return token;
    }
    return null;
  }

  static loginOut() async {
    _cachedToken = null;
    Storage.removeData("auth_token");
    Storage.removeData("user_profile");
  }
}
