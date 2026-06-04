import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/base/base_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/config/app_config_export.dart';

typedef AuthLoginSubmit = Future<bool> Function(
  String account,
  String credential, {
  bool isPhone,
  String? turnstileToken,
});

class LoginFormController extends BaseController {
  // ============ 依赖注入 ============
  final ApiClient apiClient;
  final RxBool parentIsLoading;
  final RxInt passwordLoginRetryAfterSeconds;
  final RxString passwordLoginLockedAccount;
  final AuthLoginSubmit onSubmit;
  final Future<void> Function() onOpenCustomerService;
  final Future<void> Function() onOpenDownloadUrl;

  LoginFormController({
    required this.apiClient,
    required this.parentIsLoading,
    required this.passwordLoginRetryAfterSeconds,
    required this.passwordLoginLockedAccount,
    required this.onSubmit,
    required this.onOpenCustomerService,
    required this.onOpenDownloadUrl,
  });

  // ============ Form Controllers (不是响应式，直接管理) ============
  late final TextEditingController accountController;
  late final TextEditingController passwordController;
  late final TextEditingController smsCodeController;
  late final GlobalKey<FormState> formKey;
  late final PageController bannerController;

  // ============ 响应式状态变量 ============
  // Turnstile相关
  final turnstileToken = ''.obs;
  final turnstileLang = 'auto'.obs;
  final turnstileEpoch = 0.obs;

  // Banner相关
  final loginBanners = <LoginBanner>[].obs;
  final bannerIndex = 0.obs;
  final bannerLang = ''.obs;
  final loadingBanners = true.obs;

  // 短信验证码相关
  final smsCountdown = 0.obs;
  final sendingCode = false.obs;

  // 登录表单状态
  final usePhone = false.obs;
  final remember = true.obs;
  final obscurePwd = true.obs;

  // 账号输入框变化（用于触发UI更新）
  final accountText = ''.obs;

  // ============ 计算属性 ============
  bool get isPasswordLoginLocked => passwordLoginLockedSeconds > 0;

  int get passwordLoginLockedSeconds {
    if (usePhone.value) return 0;
    final currentAccount = _normalizeAccount(accountController.text);
    if (currentAccount.isEmpty) return 0;
    if (currentAccount != passwordLoginLockedAccount.value) return 0;
    return passwordLoginRetryAfterSeconds.value;
  }

  String passwordLockCountdownText(int seconds) {
    return 'retry_after_seconds'.trParams({
      'minutes': '${_roundUpRetryMinutes(seconds)}',
    });
  }

  // ============ 生命周期 ============
  @override
  void onInit() {
    super.onInit();

    // 初始化Controllers
    accountController = TextEditingController();
    passwordController = TextEditingController();
    smsCodeController = TextEditingController();
    formKey = GlobalKey<FormState>();
    bannerController = PageController();

    // 监听账号输入变化
    accountController.addListener(_handleAccountChanged);

    // 监听Banner页面变化
    bannerController.addListener(_handleBannerPageChange);

    // 初始化语言设置
    bannerLang.value = _resolveBannerLang();
    turnstileLang.value = _resolveTurnstileLanguage();

    // 加载Banner
    loadLoginBanners();
  }

  @override
  void onClose() {
    // 移除监听
    accountController.removeListener(_handleAccountChanged);
    bannerController.removeListener(_handleBannerPageChange);

    // 释放Controllers
    accountController.dispose();
    passwordController.dispose();
    smsCodeController.dispose();
    bannerController.dispose();

    // Timer会由BaseController自动清理
    super.onClose();
  }

  // ============ 业务逻辑方法 ============

  /// 处理账号输入框变化
  void _handleAccountChanged() {
    accountText.value = accountController.text;
  }

  /// 提交登录表单
  Future<void> submit() async {
    if (parentIsLoading.value) return;

    if (isPasswordLoginLocked) {
      _showPasswordLockHint();
      return;
    }

    if (formKey.currentState?.validate() != true) return;

    final account = accountController.text.trim();
    final credential =
        usePhone.value ? smsCodeController.text.trim() : passwordController.text;
    final token = turnstileToken.value.trim();

    if (token.isNotEmpty) {
      turnstileToken.value = '';
      turnstileEpoch.value += 1;
    }

    await onSubmit(
      account,
      credential,
      isPhone: usePhone.value,
      turnstileToken: token,
    );
  }

  /// 发送短信验证码
  Future<void> sendSmsCode() async {
    final phone = accountController.text.trim();
    if (phone.isEmpty) {
      Get.snackbar(
        'tip'.tr,
        'pleaseEnterPhone'.tr,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    if (smsCountdown.value > 0) return;

    sendingCode.value = true;
    final nonce =
        '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9000) + 1000}';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = _buildOtpSign(phone, nonce, timestamp);

    try {
      final resp = await apiClient.post(
        '/user/otp/send',
        data: {
          'phone': phone,
          'nonce': nonce,
          'timestamp': timestamp,
          'sign': sign,
        },
        withAuth: false,
      );
      final data = resp.data;
      final code = data is Map ? data['code'] : null;
      final msg = data is Map ? data['msg']?.toString() ?? '' : '';

      if (code == 1) {
        _startCountdown();
        Get.snackbar(
          'tip'.tr,
          'codeSent'.tr,
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          'tip'.tr,
          msg.isEmpty ? 'networkError'.tr : msg,
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      var msg = 'networkError'.tr;
      if (e is http.DioException) {
        final data = e.response?.data;
        final serverMsg = data is Map ? data['msg']?.toString() : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          msg = serverMsg;
        }
      }
      Get.snackbar('tip'.tr, msg, snackPosition: SnackPosition.TOP);
    } finally {
      sendingCode.value = false;
    }
  }

  /// 加载登录Banner
  Future<void> loadLoginBanners() async {
    loadingBanners.value = true;
    try {
      final resp = await apiClient.get(
        '/user/banner/pic',
        withAuth: false,
        queryParameters: {
          'scene_code': 'login_banner',
          'lang': bannerLang.value,
          'platform': kIsWeb ? 'h5' : 'app',
        },
      );
      final list = _parseBannerList(resp.data);
      loginBanners.value = list;
      bannerIndex.value = 0;
      loadingBanners.value = false;
      _startBannerAutoScroll();
    } catch (_) {
      loginBanners.value = [];
      bannerIndex.value = 0;
      loadingBanners.value = false;
    }
  }

  /// 切换登录方式（账号/手机）
  void toggleLoginMethod() {
    usePhone.value = !usePhone.value;
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    obscurePwd.value = !obscurePwd.value;
  }

  /// 切换记住密码
  void toggleRemember(bool? value) {
    remember.value = value ?? false;
  }

  /// 处理Turnstile token回调
  void handleTurnstileToken(String token) {
    turnstileToken.value = token;
  }

  /// 处理语言变化
  void handleLanguageChange() {
    final newBannerLang = _resolveBannerLang();
    if (newBannerLang != bannerLang.value) {
      bannerLang.value = newBannerLang;
      loadLoginBanners();
    }
    final newTurnstileLang = _resolveTurnstileLanguage();
    if (newTurnstileLang != turnstileLang.value) {
      turnstileLang.value = newTurnstileLang;
      turnstileToken.value = '';
      turnstileEpoch.value += 1;
    }
  }

  // ============ 私有辅助方法 ============

  void _showPasswordLockHint() {
    final seconds = passwordLoginLockedSeconds;
    final message = seconds > 0
        ? '${'password_login_locked'.tr}\n${passwordLockCountdownText(seconds)}'
        : 'password_login_locked'.tr;
    Get.snackbar(
      'loginFailed'.tr,
      message,
      snackPosition: SnackPosition.TOP,
    );
  }

  String _normalizeAccount(String value) {
    return value.trim().toLowerCase();
  }

  int _roundUpRetryMinutes(int seconds) {
    if (seconds <= 0) return 1;
    return (seconds / 60).ceil();
  }

  String _resolveBannerLang() {
    return normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
    );
  }

  String _resolveTurnstileLanguage() {
    final raw = (Get.locale?.languageCode ?? 'id').toLowerCase();
    if (raw == 'zh') return 'zh-cn';
    if (raw == 'en') return 'en';
    if (raw == 'id') return 'id';
    return 'auto';
  }

  List<LoginBanner> _parseBannerList(dynamic data) {
    final items = <dynamic>[];
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map && inner['list'] is List) {
        items.addAll(inner['list'] as List);
      } else if (data['list'] is List) {
        items.addAll(data['list'] as List);
      }
    } else if (data is List) {
      items.addAll(data);
    }

    return items
        .map<LoginBanner>((item) {
          if (item is Map) {
            final raw = item['image_url']?.toString() ?? '';
            final link = item['link_value']?.toString() ?? '';
            if (raw.isEmpty) {
              return const LoginBanner(imageUrl: '');
            }
            return LoginBanner(
              imageUrl: _normalizeBannerUrl(raw),
              link: link.isEmpty ? null : link,
            );
          }
          return const LoginBanner(imageUrl: '');
        })
        .where((banner) => banner.imageUrl.isNotEmpty)
        .toList();
  }

  String _normalizeBannerUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return '${AppConfig.apiBaseUrl}/$trimmed';
  }

  void _handleBannerPageChange() {
    final page = bannerController.page?.round() ?? 0;
    if (page != bannerIndex.value &&
        page >= 0 &&
        page < loginBanners.length) {
      bannerIndex.value = page;
    }
  }

  void _startBannerAutoScroll() {
    if (loginBanners.length <= 1) return;

    final timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!bannerController.hasClients) return;
      final next =
          ((bannerController.page ?? 0).round() + 1) % loginBanners.length;
      bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
    addTimer(timer); // 使用BaseController的方法注册
  }

  String _buildOtpSign(String phone, String nonce, String timestamp) {
    final payload = '${phone.toLowerCase()}|$nonce|$timestamp';
    return md5
        .convert(utf8.encode(payload + AppConfig.otpSecret))
        .toString()
        .toUpperCase();
  }

  void _startCountdown() {
    smsCountdown.value = 60;
    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      smsCountdown.value -= 1;
      if (smsCountdown.value <= 0) {
        smsCountdown.value = 0;
        timer.cancel();
      }
    });
    addTimer(timer); // 使用BaseController的方法注册
  }
}

// ============ 数据模型 ============
class LoginBanner {
  const LoginBanner({
    required this.imageUrl,
    this.link,
  });

  final String imageUrl;
  final String? link;
}
