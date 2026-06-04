import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../utils/storage.dart';

/// 用户服务 - 管理用户信息和登录状态
///
/// 使用 GetxService 实现，支持依赖注入和响应式编程
class UserService extends GetxService {
  // 缓存的 token
  String? _cachedToken;

  // 响应式用户信息
  final userInfo = Rx<Map<String, dynamic>>({
    'account': '',
    'avatar': '',
    'nickname': '',
  });

  // 响应式登录状态
  final isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时加载用户信息
    _loadUserInfo();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    final info = await getUserInfo();
    userInfo.value = info;

    final token = await getToken();
    isLoggedIn.value = token != null && token.isNotEmpty;
  }

  /// 获取用户信息
  Future<Map<String, dynamic>> getUserInfo() async {
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

  /// 获取登录状态
  Future<bool> getUserLoginState() async {
    // 优先根据 token 判断
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// 保存后端返回的用户信息（token/avatar/nickname）
  Future<void> setUserInfo({
    required String token,
    String? avatar,
    String? nickname,
    required String account,
  }) async {
    _cachedToken = token;
    await Storage.setData("auth_token", token);

    final info = {
      "avatar": avatar ?? "",
      "account": account,
      "nickname": nickname ?? "",
    };

    await Storage.setData("user_profile", info);

    // 更新响应式状态
    userInfo.value = info;
    isLoggedIn.value = true;
  }

  /// 仅设置 token（可用于刷新）
  Future<void> setToken(String token) async {
    _cachedToken = token;
    await Storage.setData("auth_token", token);
    isLoggedIn.value = true;
  }

  /// 获取 token（带内存缓存）
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final token = await Storage.getData("auth_token");
    if (token is String) {
      _cachedToken = token;
      return token;
    }
    return null;
  }

  /// 登出
  Future<void> loginOut() async {
    _cachedToken = null;
    await Storage.removeData("auth_token");
    await Storage.removeData("user_profile");

    // 更新响应式状态
    userInfo.value = {
      'account': '',
      'avatar': '',
      'nickname': '',
    };
    isLoggedIn.value = false;
  }

  /// 刷新用户信息（从存储重新加载）
  Future<void> refreshUserInfo() async {
    await _loadUserInfo();
  }
}

// 保持向后兼容的静态类（将在后续版本中移除）
@Deprecated('Use Get.find<UserService>() instead')
class UserServices {
  static UserService get _service => Get.find<UserService>();

  static Future<Map<String, dynamic>> getUserInfo() async {
    return _service.getUserInfo();
  }

  static Future<bool> getUserLoginState() async {
    return _service.getUserLoginState();
  }

  static Future<void> setUserInfo({
    required String token,
    String? avatar,
    String? nickname,
    required String account,
  }) async {
    return _service.setUserInfo(
      token: token,
      avatar: avatar,
      nickname: nickname,
      account: account,
    );
  }

  static Future<void> setToken(String token) async {
    return _service.setToken(token);
  }

  static Future<String?> getToken() async {
    return _service.getToken();
  }

  static Future<void> loginOut() async {
    return _service.loginOut();
  }
}
