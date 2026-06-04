import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/utils/user_status_error.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/utils/device_utils.dart';
import 'dart:convert';
import '../../../data/models/gametype.dart';
import '../../../utils/api_client.dart';

class GameStartController extends GetxController {
  // 游戏数据（允许在再次进入时更新）
  GameList? game = _readGameFromArgs(Get.arguments);
  String? _activeGameKey;
  String? _loadingGameKey;
  String? _loadedGameKey;

  // 状态管理
  final isLoading = true.obs;
  final gameUrl = ''.obs;
  final errorMessage = ''.obs;
  final loadingProgress = 0.0.obs;
  // final Rx<Offset> floatingOffset = const Offset(16, 16).obs;

  bool get hasGameContext => game != null;

  // InAppWebView 控制器
  InAppWebViewController? webViewController;

  // API 客户端
  final ApiClient _apiClient = Get.find<ApiClient>();

  @override
  void onInit() {
    super.onInit();
    _syncArgsAndMaybeLoad();
  }

  @override
  void onReady() {
    super.onReady();
    // 再次打开页面时，若参数变化，则重新加载
    _syncArgsAndMaybeLoad();
  }

  @override
  void onClose() {
    // 清理并重置状态，避免下次进入复用旧数据
    try {
      webViewController?.stopLoading();
    } catch (_) {}
    webViewController = null;
    gameUrl.value = '';
    errorMessage.value = '';
    isLoading.value = false;
    _activeGameKey = null;
    _loadingGameKey = null;
    _loadedGameKey = null;
    super.onClose();
  }

  void _syncArgsAndMaybeLoad() {
    //同步参数并加载游戏
    final arg = _readGameFromArgs(Get.arguments);
    final nextGameKey = _buildGameKey(arg);

    final bool isDifferent =
        (arg?.id != game?.id) || (arg?.gamecode != game?.gamecode);

    if (isDifferent) {
      game = arg;
      _activeGameKey = nextGameKey;
      _loadedGameKey = null;
      gameUrl.value = '';
      errorMessage.value = '';
      if (game != null) {
        _loadGameUrl();
      }
    } else if (game != null) {
      _activeGameKey ??= nextGameKey;
      _loadGameUrl();
    }
  }

  static GameList? _readGameFromArgs(dynamic args) {
    if (args is GameList) {
      return args;
    }

    if (args is Map) {
      try {
        return GameList.fromJson(Map<String, dynamic>.from(args));
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  /// 加载游戏URL
  Future<void> _loadGameUrl({bool force = false}) async {
    final currentGame = game;
    final requestGameKey = _buildGameKey(currentGame);
    if (currentGame == null || requestGameKey == null) {
      return;
    }
    _activeGameKey = requestGameKey;

    final alreadyLoaded =
        !force && _loadedGameKey == requestGameKey && gameUrl.value.isNotEmpty;
    final isLoadingSameGame =
        !force && _loadingGameKey == requestGameKey && isLoading.value;

    if (alreadyLoaded || isLoadingSameGame) {
      return;
    }

    debugPrint('_loadGameUrl - game: $game');
    debugPrint('_loadGameUrl - game?.gamehall: ${game?.gamehall}');
    debugPrint('_loadGameUrl - game?.gamecode: ${game?.gamecode}');

    _loadingGameKey = requestGameKey;
    isLoading.value = true;
    gameUrl.value = '';
    errorMessage.value = '';
    loadingProgress.value = 0.0;

    // 获取用户信息
    final userInfo = await UserServices.getUserInfo();
    debugPrint(' userInfo: $userInfo');
    final account = userInfo['account'];

    final lang = normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
      fallback: 'zh-cn',
    );
    // 获取设备 如果是手机 gameplat = mobile ，请填入 web 或 mobile ，如果是电脑 gameplat = web
    // 基于平台/UA 判断，不随窗口大小变化
    final String gameplat = DeviceUtils.isMobileDevice ? 'mobile' : 'web';

    debugPrint('gameplat: $gameplat');

    try {
      final response = await _apiClient.post(
        '/user/getgamelink',
        data: {
          'account': account, // 用户账号
          'gamehall': game?.gamehall,
          'gamecode': game?.gamecode,
          'gameplat': gameplat, // 游戏平台
          // 'gameplat': "web", // 游戏平台
          'lang': lang,
          // 'session': '',
          // 'app': '',
          // 'detect': '',
          // 'gamesite': '滑稽得玩',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint(response.data.toString());

        // 安全转换 response.data
        Map<String, dynamic> responseData;
        try {
          if (response.data is Map) {
            responseData = Map<String, dynamic>.from(response.data as Map);
          } else {
            // 如果是字符串，尝试解析JSON
            responseData = Map<String, dynamic>.from(
              jsonDecode(response.data.toString()) as Map,
            );
          }
        } catch (e) {
          debugPrint('响应数据转换失败: $e');
          responseData = {};
        }

        final newUrl = _extractGameUrl(responseData);
        if (_activeGameKey != requestGameKey) {
          return;
        }

        if (newUrl != null && newUrl.isNotEmpty) {
          _loadedGameKey = requestGameKey;
          gameUrl.value = newUrl;
          // 若 WebView 已创建，则直接跳转到新地址
          try {
            await webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(newUrl)));
          } catch (_) {}
        } else {
          final handled = await handleUserStatusError(
            code: responseData['code'],
            message: responseData['msg']?.toString(),
          );
          if (handled) {
            _showError(
              parseUserStatusError(
                    code: responseData['code'],
                    message: responseData['msg']?.toString(),
                  )?.localizedMessage ??
                  'networkError'.tr,
            );
            return;
          }
          _showError(_extractGameLinkErrorMessage(responseData));
        }
      } else {
        if (_activeGameKey != requestGameKey) {
          return;
        }
        _showError('networkError'.tr);
      }
    } catch (e) {
      if (_activeGameKey != requestGameKey) {
        return;
      }
      debugPrint('${'loadingGameFailed'.tr}: $e');
      _showError('${'loadingGameFailed'.tr}: $e');
    } finally {
      if (_loadingGameKey == requestGameKey) {
        _loadingGameKey = null;
      }
      if (_activeGameKey == requestGameKey) {
        isLoading.value = false;
      }
    }
  }

  /// 重新加载游戏
  void reloadGame() {
    if (game != null) {
      _loadedGameKey = null;
      _loadGameUrl(force: true);
    }
  }

  /// 返回上一页
  void goBack() {
    Get.back();
  }

  /// 获取游戏标题
  String get gameTitle => game?.name ?? '游戏';

  /// 处理加载进度
  void onProgressChanged(InAppWebViewController controller, int progress) {
    loadingProgress.value = progress / 100.0;
    debugPrint('加载进度: $progress%');
  }

  /// 处理页面开始加载
  void onLoadStart(InAppWebViewController controller, WebUri? url) {
    debugPrint('开始加载: $url');
  }

  /// 处理页面加载完成
  void onLoadStop(InAppWebViewController controller, WebUri? url) {
    debugPrint('加载完成: $url');
    isLoading.value = false;
  }

  void onWebFrameLoaded() {
    debugPrint('Web iframe 加载完成');
    loadingProgress.value = 1.0;
    isLoading.value = false;
  }

  void onWebFrameError(String message) {
    debugPrint('Web iframe 加载错误: $message');
    _showError(message);
  }

  /// 处理加载错误
  void onLoadError(InAppWebViewController controller, WebUri? url, int code,
      String message) {
    debugPrint('加载错误: $message');
    _showError('加载失败: $message');
  }

  void handleWebResourceError(String message, {bool isMainFrame = true}) {
    if (!isMainFrame) {
      debugPrint('忽略子资源加载错误: $message');
      return;
    }
    debugPrint('资源加载错误: $message');
    _showError('加载失败: $message');
  }

  String? _extractGameUrl(Map<String, dynamic> responseData) {
    final data = _asMap(responseData['data']);
    final url = data['url']?.toString().trim();
    if (url == null || url.isEmpty) {
      return null;
    }

    final topCode = responseData['code']?.toString();
    if (topCode == '1') {
      return url;
    }

    final status = _asMap(responseData['status']);
    final legacyCode = status['code']?.toString();
    if (legacyCode == '0') {
      return url;
    }

    // Some environments may only return data.url without explicit status.
    if (responseData.containsKey('data') &&
        !responseData.containsKey('status')) {
      return url;
    }

    return null;
  }

  String _extractGameLinkErrorMessage(Map<String, dynamic> responseData) {
    final statusError = parseUserStatusError(
      code: responseData['code'],
      message: responseData['msg']?.toString(),
    );
    if (statusError != null) {
      return statusError.localizedMessage;
    }

    final data = _asMap(responseData['data']);
    final vendorMessage = data['vendor_msg']?.toString().trim();
    if (vendorMessage != null && vendorMessage.isNotEmpty) {
      return vendorMessage;
    }

    final topMessage = responseData['msg']?.toString().trim();
    if (topMessage != null && topMessage.isNotEmpty) {
      return topMessage;
    }

    final status = _asMap(responseData['status']);
    final legacyMessage = status['message']?.toString().trim();
    if (legacyMessage != null && legacyMessage.isNotEmpty) {
      return legacyMessage;
    }

    return 'loadingGameFailed'.tr;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  void _showError(String message) {
    _loadedGameKey = null;
    gameUrl.value = '';
    errorMessage.value = message;
    loadingProgress.value = 0.0;
    isLoading.value = false;
  }

  String? _buildGameKey(GameList? target) {
    if (target == null) {
      return null;
    }
    return '${target.gamehall ?? ''}:${target.gamecode ?? ''}:${target.id ?? ''}';
  }
}
