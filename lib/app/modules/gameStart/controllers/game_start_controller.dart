import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:igames/app/data/services/userServices.dart';
import 'package:igames/app/utils/device_utils.dart';
import 'dart:convert';
import '../../../data/models/gametype.dart';
import '../../../data/models/gamelink.dart';
import '../../../utils/api_client.dart';

class GameStartController extends GetxController {
  // 游戏数据（允许在再次进入时更新）
  GameList? game = Get.arguments as GameList?;

  // 状态管理
  final isLoading = true.obs;
  final gameUrl = ''.obs;
  final errorMessage = ''.obs;
  final loadingProgress = 0.0.obs;
  // final Rx<Offset> floatingOffset = const Offset(16, 16).obs;

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
    super.onClose();
  }

  void _syncArgsAndMaybeLoad() {
    //同步参数并加载游戏
    final arg = Get.arguments as GameList?;

    final bool isDifferent =
        (arg?.id != game?.id) || (arg?.gamecode != game?.gamecode);

    if (isDifferent) {
      game = arg;
      gameUrl.value = '';
      errorMessage.value = '';
      if (game != null) {
        _loadGameUrl();
      }
    } else if (game != null && gameUrl.value.isEmpty) {
      _loadGameUrl();
    }
  }

  /// 加载游戏URL
  Future<void> _loadGameUrl() async {
    debugPrint('_loadGameUrl - game: $game');
    debugPrint('_loadGameUrl - game?.gamehall: ${game?.gamehall}');
    debugPrint('_loadGameUrl - game?.gamecode: ${game?.gamecode}');

    isLoading.value = true;
    errorMessage.value = '';
    loadingProgress.value = 0.0;

    // 获取用户信息
    final userInfo = await UserServices.getUserInfo();
    debugPrint(' userInfo: $userInfo');
    final account = userInfo['account'];

    // 获取语言如果是zh 转成zh-cn
    String lang = Get.locale?.languageCode ?? 'zh-cn';
    if (lang == 'zh') {
      lang = 'zh-cn';
    }
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

        // 使用 gamelink 模型解析响应
        final gameLinkResponse = gamelink.fromJson(responseData);

        if (gameLinkResponse.status?.code == '0' &&
            gameLinkResponse.data?.url != null) {
          final newUrl = gameLinkResponse.data!.url!;
          gameUrl.value = newUrl;
          // 若 WebView 已创建，则直接跳转到新地址
          try {
            await webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(newUrl)));
          } catch (_) {}
        } else {
          errorMessage.value =
              gameLinkResponse.status?.message ?? 'loadingGameFailed'.tr;
        }
      } else {
        errorMessage.value = 'networkError'.tr;
      }
    } catch (e) {
      debugPrint('${'loadingGameFailed'.tr}: $e');
      errorMessage.value = '${'loadingGameFailed'.tr}: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// 重新加载游戏
  void reloadGame() {
    if (game != null) {
      _loadGameUrl();
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

  /// 处理加载错误
  void onLoadError(InAppWebViewController controller, WebUri? url, int code,
      String message) {
    debugPrint('加载错误: $message');
    errorMessage.value = '加载失败: $message';
    isLoading.value = false;
  }
}
