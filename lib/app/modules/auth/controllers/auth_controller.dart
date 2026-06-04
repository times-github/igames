import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as http;
import 'package:get/get.dart';
import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/event_bus.dart';
import 'package:igames/app/modules/auth/widgets/login_overlay_panel.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/launch_params.dart';
import 'package:igames/app/utils/storage.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/app/data/services/sse_notify_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/utils/user_status_error.dart';
import 'package:igames/utils/web_lang_param.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs; // 是否登录
  final isLoading = false.obs;
  final passwordLoginRetryAfterSeconds = 0.obs;
  final passwordLoginLockedAccount = ''.obs;

  final ApiClient _apiClient = Get.find<ApiClient>();
  String? _customerServiceContact;
  String? _whatsAppSupportContact;
  String? _downloadAppUrl;
  Timer? _passwordLoginLockTimer;

  static String _resolveAuthChannel() {
    if (kIsWeb) return 'h5';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'app-ios';
      case TargetPlatform.android:
        return 'app-android';
      default:
        return 'app';
    }
  }

  @override
  void onInit() {
    super.onInit();
    ApiClient.onUnauthorized = _handleUnauthorized;

    // 监听请求登录事件
    EventBus.on<RequestLoginEvent>((_) {
      openLoginOverlay();
    });

    _checkLoginState();
  }

  void _handleUnauthorized() {
    logout();
    openLoginOverlay();
  }

  @override
  void onClose() {
    _passwordLoginLockTimer?.cancel();
    super.onClose();
  }

  /// 检查登录状态
  Future<void> _checkLoginState() async {
    final loginState = await UserServices.getUserLoginState();
    isLoggedIn.value = loginState;
    //如果登录了，则触发登录成功事件
    if (isLoggedIn.value) {
      debugPrint('User logged in, firing LoginSuccessEvent');
      // 通过事件总线通知其他模块，完全解耦
      EventBus.fire(const LoginSuccessEvent());

      if (Get.isRegistered<SseNotifyService>()) {
        Get.find<SseNotifyService>().connect();
      }
      if (Get.isRegistered<AnnouncementService>()) {
        Get.find<AnnouncementService>().refreshTotalUnreadCount();
      }
    }
  }

  // ============== 登录弹窗相关 ==============
  final isLoginOpen = false.obs;

  /// 确保用户已登录
  ///
  /// 如果用户未登录，会自动打开登录弹窗
  /// 返回 true 表示已登录，false 表示未登录且已打开登录弹窗
  ///
  /// [context] 构建上下文
  Future<bool> ensureAuthenticated(BuildContext context) async {
    if (isLoggedIn.value) return true;
    openLoginOverlay();
    return false;
  }

  /// 打开登录弹窗
  ///
  /// 显示一个全屏的毛玻璃登录弹窗，包含邮箱和密码输入框
  ///
  /// [context] 构建上下文
  void openLoginOverlay() {
    if (isLoginOpen.value) return;
    isLoginOpen.value = true;
    Future.microtask(() {
      if (!(Get.isDialogOpen ?? false)) {
        final overlayBackground = kIsWeb
            ? ColoredBox(
                color: Colors.black.withValues(alpha: 0.62),
              )
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.22),
                ),
              );
        Get.dialog(
          Stack(
            children: [
              Positioned.fill(
                child: overlayBackground,
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: RepaintBoundary(
                    child: LoginOverlayPanel(
                      onClose: closeLoginOverlay,
                      apiClient: _apiClient,
                      isLoading: isLoading,
                      passwordLoginRetryAfterSeconds:
                          passwordLoginRetryAfterSeconds,
                      passwordLoginLockedAccount: passwordLoginLockedAccount,
                      onSubmit: loginOrRegister,
                      onOpenCustomerService: openCustomerService,
                      onOpenDownloadUrl: openDownloadUrl,
                    ),
                  ),
                ),
              ),
            ],
          ),
          barrierColor: Colors.black.withValues(alpha: kIsWeb ? 0.58 : 0.35),
          barrierDismissible: true,
          useSafeArea: true,
        ).whenComplete(() => isLoginOpen.value = false);
      }
    });
  }

  /// 关闭登录弹窗
  ///
  /// 移除登录弹窗并清理相关资源
  void closeLoginOverlay() {
    if (isLoginOpen.value && (Get.isDialogOpen ?? false)) {
      Get.back();
    }
    isLoginOpen.value = false;
  }

  /// 登录/注册一键接口
  Future<bool> loginOrRegister(String account, String credential,
      {bool isPhone = false, String? turnstileToken}) {
    return _authRequest(
      account: isPhone ? '' : account,
      phone: isPhone ? account : '',
      password: isPhone ? '' : credential,
      otpCode: isPhone ? credential : '',
      turnstileToken: turnstileToken,
    );
  }

  /// 登录/注册统一接口
  Future<bool> login(String account, String password,
      {required String email,
      String otpCode = '',
      String phone = '',
      String? turnstileToken}) async {
    return _authRequest(
      account: account,
      password: password,
      phone: phone,
      otpCode: otpCode,
      turnstileToken: turnstileToken,
    );
  }

  Future<bool> _authRequest(
      {required String account,
      required String password,
      required String phone,
      required String otpCode,
      String? turnstileToken}) async {
    final loginAccount = account.isNotEmpty ? account : phone;
    final isPasswordLoginRequest = _isPasswordLoginRequest(
      account: account,
      password: password,
      phone: phone,
      otpCode: otpCode,
    );
    if (isPasswordLoginRequest && isPasswordLoginLockedFor(loginAccount)) {
      _showAuthFailure(
        code: '3111',
        retryAfterSeconds: passwordLoginRetryAfterSeconds.value,
      );
      return false;
    }

    try {
      isLoading.value = true;
      final inviteCode = LaunchParams.registerCode;
      final payload = {
        'account': account,
        'pwd': password,
        'phone': phone,
        'otp_code': otpCode,
        'turnstile_token': turnstileToken?.trim() ?? '',
        'channel': _resolveAuthChannel(),
        if (inviteCode != null && inviteCode.isNotEmpty)
          'invite_code': inviteCode,
      };
      final resp = await _apiClient.post(
        '/user/auth',
        data: payload,
        withAuth: false,
      );
      return _processAuthResponse(resp.data, loginAccount);
    } catch (e) {
      if (e is http.DioException) {
        final responseMap = _asStringKeyedMap(e.response?.data);
        if (responseMap.isNotEmpty) {
          return _processAuthResponse(responseMap, loginAccount);
        }
      }
      isLoggedIn.value = false;
      _showAuthFailure();
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  bool _processAuthResponse(dynamic raw, String account) {
    final response = _asStringKeyedMap(raw);
    if (response.isEmpty) {
      _showAuthFailure();
      return false;
    }

    final code = response['code']?.toString();
    final message = response['msg']?.toString();
    final retryAfterSeconds = _extractRetryAfterSeconds(response['data']);
    final statusError =
        parseUserStatusError(code: response['code'], message: message);
    if (statusError != null) {
      isLoggedIn.value = false;
      _showAuthFailure(code: code, message: message);
      return false;
    }

    if (_isPasswordLoginLockedResponse(code, message)) {
      isLoggedIn.value = false;
      _startPasswordLoginLock(
        account: account,
        retryAfterSeconds: retryAfterSeconds,
      );
      _showAuthFailure(
        code: code,
        message: message,
        retryAfterSeconds: retryAfterSeconds,
      );
      return false;
    }

    if (code == '1') {
      final data = _asStringKeyedMap(response['data']);
      final token = data['token']?.toString() ?? '';
      if (token.isEmpty) {
        isLoggedIn.value = false;
        _showAuthFailure(code: 'unknown');
        return false;
      }
      final avatar = data['avatar']?.toString() ?? '';
      final nickname = data['nickname']?.toString() ?? '';
      UserServices.setUserInfo(
        token: token,
        avatar: avatar,
        nickname: nickname,
        account: account,
      );
      LaunchParams.clearRegisterCode();
      Storage.removeData("invite_code");
      setWebHashParams({'invite_code': null});
      isLoggedIn.value = true;
      _closeAuthDialogs();

      // 通过事件总线通知登录成功，完全解耦
      EventBus.fire(const LoginSuccessEvent());

      if (Get.isRegistered<SseNotifyService>()) {
        Get.find<SseNotifyService>().connect();
      }
      if (Get.isRegistered<AnnouncementService>()) {
        Get.find<AnnouncementService>().refreshTotalUnreadCount();
      }
      Get.offAllNamed(AppPages.INITIAL);
      return true;
    }

    isLoggedIn.value = false;
    _showAuthFailure(code: code, message: message);
    return false;
  }

  void _showAuthFailure({
    String? code,
    String? message,
    int? retryAfterSeconds,
  }) {
    final localizedMessage = _resolveAuthErrorMessage(
      code,
      message: message,
      retryAfterSeconds: retryAfterSeconds,
    );
    Get.snackbar(
      'loginFailed'.tr,
      localizedMessage,
      snackPosition: SnackPosition.TOP,
    );
  }

  String _resolveAuthErrorMessage(
    String? code, {
    String? message,
    int? retryAfterSeconds,
  }) {
    final messageKey = _authErrorMessageKey(code, message: message);
    if (messageKey == 'password_login_locked') {
      return _buildPasswordLoginLockedMessage(
        retryAfterSeconds ??
            (passwordLoginRetryAfterSeconds.value > 0
                ? passwordLoginRetryAfterSeconds.value
                : null),
      );
    }
    return messageKey.tr;
  }

  String _authErrorMessageKey(String? code, {String? message}) {
    final statusError = parseUserStatusError(code: code, message: message);
    if (statusError != null) {
      return statusError.messageKey;
    }
    final normalizedMessage = message?.trim().toLowerCase();
    if (_isPasswordLoginLockedResponse(code, message)) {
      return 'password_login_locked';
    }

    switch (code) {
      case '3001':
        return 'authAccountOrPhoneRequired';
      case '3002':
        return 'authOtpLengthInvalid';
      case '3003':
        return 'authPhoneFormatInvalid';
      case '3004':
        return 'authAccountQueryFailed';
      case '3005':
        return 'authOtpVerifyFailed';
      case '3006':
        return 'authRegisterAutoFailed';
      case '3007':
        return 'password_invalid';
      case '3008':
        return 'authPasswordOrCodeRequired';
      case '3009':
        return 'turnstileRequired';
      case '3111':
        return 'password_login_locked';
      case null:
        if (normalizedMessage == 'password_invalid') {
          return 'password_invalid';
        }
        return 'networkError';
      default:
        if (normalizedMessage == 'password_invalid') {
          return 'password_invalid';
        }
        return 'authUnknownError';
    }
  }

  bool isPasswordLoginLockedFor(String account) {
    final normalizedAccount = _normalizeLoginAccount(account);
    return normalizedAccount.isNotEmpty &&
        normalizedAccount == passwordLoginLockedAccount.value &&
        passwordLoginRetryAfterSeconds.value > 0;
  }

  bool _isPasswordLoginRequest({
    required String account,
    required String password,
    required String phone,
    required String otpCode,
  }) {
    return account.trim().isNotEmpty &&
        phone.trim().isEmpty &&
        password.isNotEmpty &&
        otpCode.isEmpty;
  }

  bool _isPasswordLoginLockedResponse(String? code, String? message) {
    final normalizedMessage = message?.trim().toLowerCase();
    return code == '3111' || normalizedMessage == 'password_login_locked';
  }

  int? _extractRetryAfterSeconds(dynamic raw) {
    final data = _asStringKeyedMap(raw);
    final value = data['retry_after_seconds'];
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return null;
    }
    return parsed < 0 ? 0 : parsed;
  }

  void _startPasswordLoginLock({
    required String account,
    int? retryAfterSeconds,
  }) {
    final normalizedAccount = _normalizeLoginAccount(account);
    final seconds = retryAfterSeconds == null || retryAfterSeconds < 0
        ? 0
        : retryAfterSeconds;
    _passwordLoginLockTimer?.cancel();

    if (normalizedAccount.isEmpty || seconds <= 0) {
      passwordLoginLockedAccount.value = normalizedAccount;
      passwordLoginRetryAfterSeconds.value = seconds;
      return;
    }

    passwordLoginLockedAccount.value = normalizedAccount;
    passwordLoginRetryAfterSeconds.value = seconds;
    _passwordLoginLockTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      final next = passwordLoginRetryAfterSeconds.value - 1;
      if (next <= 0) {
        passwordLoginRetryAfterSeconds.value = 0;
        passwordLoginLockedAccount.value = '';
        timer.cancel();
        return;
      }
      passwordLoginRetryAfterSeconds.value = next;
    });
  }

  String _buildPasswordLoginLockedMessage(int? retryAfterSeconds) {
    final base = 'password_login_locked'.tr;
    if (retryAfterSeconds == null || retryAfterSeconds <= 0) {
      return base;
    }
    final retryText = 'retry_after_seconds'.trParams({
      'minutes': '${_roundUpRetryMinutes(retryAfterSeconds)}',
    });
    return '$base\n$retryText';
  }

  int _roundUpRetryMinutes(int seconds) {
    if (seconds <= 0) return 1;
    return (seconds / 60).ceil();
  }

  String _normalizeLoginAccount(String account) {
    return account.trim().toLowerCase();
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  void _closeAuthDialogs() {
    if (isLoginOpen.value) {
      closeLoginOverlay();
    }
  }

  /// 用户登出
  ///
  /// 清除用户信息并设置登录状态为 false
  Future<void> logout() async {
    await UserServices.loginOut();
    isLoggedIn.value = false;

    // 通过事件总线通知登出，完全解耦
    EventBus.fire(const LogoutEvent());

    if (Get.isRegistered<SseNotifyService>()) {
      await Get.find<SseNotifyService>().disconnect();
    }
  }

  Future<void> handleUserBanned({
    bool openLogin = true,
  }) async {
    await logout();
    if (!openLogin) return;
    if (!isLoginOpen.value) {
      openLoginOverlay();
    }
  }

  /// 打开下载链接
  Future<void> openDownloadUrl() async {
    final url = await _getDownloadUrl();
    if (url == null || url.isEmpty) {
      Get.snackbar('tip'.tr, 'networkError'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (kIsWeb) {
        await launchUrl(uri, webOnlyWindowName: '_blank');
        return;
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('tip'.tr, 'networkError'.tr,
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, 'networkError'.tr,
          snackPosition: SnackPosition.TOP);
    }
  }

  /// 打开客服
  Future<void> openCustomerService() async {
    final telegramContact = await _getCustomerServiceContact();
    final whatsAppContact = await _getWhatsAppSupportContact();
    if ((telegramContact == null || telegramContact.isEmpty) &&
        (whatsAppContact == null || whatsAppContact.isEmpty)) {
      Get.snackbar('tip'.tr, 'networkError'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }

    await Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: 'support_center',
      barrierColor: Colors.black.withValues(alpha: 0.58),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SupportCenterDialog(
          whatsAppContact: whatsAppContact,
          telegramContact: telegramContact,
          onOpenWhatsApp: whatsAppContact == null || whatsAppContact.isEmpty
              ? null
              : () {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  unawaited(_openWhatsAppContact(whatsAppContact));
                },
          onOpenTelegram: telegramContact == null || telegramContact.isEmpty
              ? null
              : () {
                  if (Get.isDialogOpen ?? false) {
                    Get.back();
                  }
                  unawaited(_openTelegramContact(telegramContact));
                },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<String?> _getCustomerServiceContact() async {
    if (_customerServiceContact?.isNotEmpty == true) {
      return _customerServiceContact;
    }

    _customerServiceContact = await _fetchCustomerServiceContact();
    return _customerServiceContact;
  }

  Future<String?> _fetchCustomerServiceContact() async {
    try {
      final response = await _apiClient.get(
        '/user/config/customer_service_tg',
        withAuth: false,
      );
      if (response.statusCode == 200) {
        final value = _extractConfigValue(response.data)?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (e) {
      debugPrint('获取客服联系方式失败: $e');
    }
    return null;
  }

  Future<String?> _getWhatsAppSupportContact() async {
    if (_whatsAppSupportContact?.isNotEmpty == true) {
      return _whatsAppSupportContact;
    }

    _whatsAppSupportContact = await _fetchWhatsAppSupportContact();
    return _whatsAppSupportContact;
  }

  Future<String?> _fetchWhatsAppSupportContact() async {
    try {
      final response = await _apiClient.get(
        '/user/config/customer_service_whatsapp',
        withAuth: false,
      );
      if (response.statusCode == 200) {
        final value = _extractConfigValue(response.data)?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (e) {
      debugPrint('获取 WhatsApp 客服联系方式失败: $e');
    }
    return null;
  }

  String _extractTelegramHandle(String contact) {
    if (contact.startsWith('http')) {
      final uri = Uri.tryParse(contact);
      if (uri != null) {
        final segments =
            uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          return segments.first.replaceAll('@', '');
        }
      }
    }
    return contact.replaceAll('@', '');
  }

  Uri _buildTelegramWebUri(String contact) {
    final trimmed = contact.trim();
    if (trimmed.startsWith('http')) {
      return Uri.parse(trimmed);
    }
    final handle = _extractTelegramHandle(trimmed);
    return Uri.parse('https://t.me/$handle');
  }

  Uri _buildTelegramAppUri(String contact) {
    final trimmed = contact.trim();
    if (trimmed.startsWith('tg://')) {
      return Uri.parse(trimmed);
    }
    final handle = _extractTelegramHandle(trimmed);
    return Uri.parse('tg://resolve?domain=$handle');
  }

  String _normalizeWhatsAppPhone(String contact) {
    final trimmed = contact.trim();
    if (trimmed.startsWith('http') || trimmed.startsWith('whatsapp://')) {
      final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
      return digits;
    }
    return trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Uri _buildWhatsAppWebUri(String contact) {
    final trimmed = contact.trim();
    if (trimmed.startsWith('http')) {
      return Uri.parse(trimmed);
    }
    final phone = _normalizeWhatsAppPhone(trimmed);
    return Uri.parse('https://wa.me/$phone');
  }

  Uri _buildWhatsAppAppUri(String contact) {
    final trimmed = contact.trim();
    if (trimmed.startsWith('whatsapp://')) {
      return Uri.parse(trimmed);
    }
    final phone = _normalizeWhatsAppPhone(trimmed);
    return Uri.parse('whatsapp://send?phone=$phone');
  }

  Future<void> _openTelegramContact(String contact) async {
    final webUri = _buildTelegramWebUri(contact);
    final appUri = _buildTelegramAppUri(contact);

    try {
      if (kIsWeb) {
        await launchUrl(webUri, webOnlyWindowName: '_blank');
        return;
      }

      if (await canLaunchUrl(appUri)) {
        final launched =
            await launchUrl(appUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      }

      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Get.snackbar('tip'.tr, 'networkError'.tr,
          snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> _openWhatsAppContact(String contact) async {
    final webUri = _buildWhatsAppWebUri(contact);
    final appUri = _buildWhatsAppAppUri(contact);

    try {
      if (kIsWeb) {
        await launchUrl(webUri, webOnlyWindowName: '_blank');
        return;
      }

      if (await canLaunchUrl(appUri)) {
        final launched =
            await launchUrl(appUri, mode: LaunchMode.externalApplication);
        if (launched) return;
      }

      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      Get.snackbar('tip'.tr, 'networkError'.tr,
          snackPosition: SnackPosition.TOP);
    }
  }

  Future<String?> _getDownloadUrl() async {
    if (_downloadAppUrl?.isNotEmpty == true) {
      return _downloadAppUrl;
    }
    _downloadAppUrl = await _fetchDownloadUrl();
    return _downloadAppUrl;
  }

  Future<String?> _fetchDownloadUrl() async {
    try {
      final response = await _apiClient.get(
        '/user/config/download_app_url',
        withAuth: false,
      );
      if (response.statusCode == 200) {
        final value = _extractConfigValue(response.data)?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    } catch (e) {
      debugPrint('获取下载链接失败: $e');
    }
    return null;
  }

  dynamic _extractConfigValue(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) {
        if (inner.containsKey('config_value')) return inner['config_value'];
        if (inner.containsKey('value')) return inner['value'];
      }
      if (inner != null && inner is! Map) return inner;
      if (data.containsKey('config_value')) return data['config_value'];
      if (data.containsKey('value')) return data['value'];
    }
    return data;
  }
}

class _SupportCenterDialog extends StatelessWidget {
  const _SupportCenterDialog({
    required this.whatsAppContact,
    required this.telegramContact,
    required this.onOpenWhatsApp,
    required this.onOpenTelegram,
  });

  final String? whatsAppContact;
  final String? telegramContact;
  final VoidCallback? onOpenWhatsApp;
  final VoidCallback? onOpenTelegram;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);
        final size = MediaQuery.sizeOf(context);

        return Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: r.size(20),
                  vertical: r.size(18),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: size.width < 600 ? size.width * 0.92 : 420.0,
                    minWidth:
                        min(size.width - (r.size(20) * 2), 300.0).toDouble(),
                    maxHeight: size.height * 0.84,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r.size(30)),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF171A29),
                          Color(0xFF111C2E),
                          Color(0xFF101522),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.42),
                          blurRadius: r.size(36),
                          offset: Offset(0, r.size(20)),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          top: -56,
                          right: -36,
                          child: _SupportGlow(
                            diameter: 180,
                            colors: [Color(0x3341E38D), Color(0x0041E38D)],
                          ),
                        ),
                        const Positioned(
                          bottom: -90,
                          left: -24,
                          child: _SupportGlow(
                            diameter: 220,
                            colors: [Color(0x333497FF), Color(0x003497FF)],
                          ),
                        ),
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            r.size(22),
                            r.size(20),
                            r.size(22),
                            r.size(22),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SupportCenterHeader(
                                onClose: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).maybePop();
                                },
                              ),
                              SizedBox(height: r.size(18)),
                              _SupportActionCard(
                                delay: 0.0,
                                title: 'WhatsApp',
                                description: 'supportWhatsAppDesc'.tr,
                                contactLabel: _formatWhatsAppContact(
                                  whatsAppContact,
                                ),
                                onTap: onOpenWhatsApp,
                                icon: Icons.chat_rounded,
                                colors: const [
                                  Color(0xFF27D367),
                                  Color(0xFF14934D),
                                ],
                              ),
                              SizedBox(height: r.size(12)),
                              _SupportActionCard(
                                delay: 0.14,
                                title: 'Telegram',
                                description: 'supportTelegramDesc'.tr,
                                contactLabel: _formatTelegramContact(
                                  telegramContact,
                                ),
                                onTap: onOpenTelegram,
                                icon: Icons.send_rounded,
                                colors: const [
                                  Color(0xFF33A4FF),
                                  Color(0xFF276BFF),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTelegramContact(String? contact) {
    if (contact == null || contact.trim().isEmpty) {
      return 'supportNotConfigured'.tr;
    }

    final trimmed = contact.trim();
    if (trimmed.startsWith('http')) {
      final uri = Uri.tryParse(trimmed);
      final segments =
          uri?.pathSegments.where((segment) => segment.isNotEmpty).toList() ??
              const [];
      if (segments.isNotEmpty) {
        final handle = segments.first.replaceAll('@', '');
        return '@$handle';
      }
    }

    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  String _formatWhatsAppContact(String? contact) {
    if (contact == null || contact.trim().isEmpty) {
      return 'supportNotConfigured'.tr;
    }

    final trimmed = contact.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return trimmed;
    }
    return '+$digits';
  }
}

class _SupportCenterHeader extends StatelessWidget {
  const _SupportCenterHeader({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final avatarSize = r.size(48);
    final titleSize = r.font(19);
    final subtitleSize = r.font(13);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7F5CFF),
                Color(0xFF4F8DFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F8DFF).withValues(alpha: 0.28),
                blurRadius: r.size(18),
                offset: Offset(0, r.size(8)),
              ),
            ],
          ),
          child: Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: r.size(24),
          ),
        ),
        SizedBox(width: r.size(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'helpCenter'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: r.size(4)),
              Text(
                'supportCenterSubtitle'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: subtitleSize,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: r.size(8)),
        IconButton(
          onPressed: onClose,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            foregroundColor: Colors.white.withValues(alpha: 0.82),
          ),
          icon: Icon(
            Icons.close_rounded,
            size: r.size(20),
          ),
        ),
      ],
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  const _SupportActionCard({
    required this.delay,
    required this.title,
    required this.description,
    required this.contactLabel,
    required this.onTap,
    required this.icon,
    required this.colors,
  });

  final double delay;
  final String title;
  final String description;
  final String contactLabel;
  final VoidCallback? onTap;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final r = Responsive.fromContext(context);
    final compact = r.width < 380;
    final cardRadius = r.size(compact ? 21 : 24);
    final cardPadding = r.size(compact ? 15 : 18);
    final gapSize = r.size(compact ? 10 : 14);
    final iconBoxSize = r.size(compact ? 48 : 54);
    final iconGlyphSize = r.size(compact ? 24 : 26);
    final titleFontSize = r.font(compact ? 17 : 18);
    final descFontSize = r.font(compact ? 11.5 : 12);
    final contactFontSize = r.font(compact ? 12.5 : 13);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final interval = Interval(delay, 1, curve: Curves.easeOutCubic);
        final eased = interval.transform(value);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 26),
            child: child,
          ),
        );
      },
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(cardRadius),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                gradient: LinearGradient(
                  colors: [
                    colors.first.withValues(alpha: 0.20),
                    colors.last.withValues(alpha: 0.10),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: colors.first.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconGlyphSize,
                      ),
                    ),
                    SizedBox(width: gapSize),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: r.size(4)),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: descFontSize,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: r.size(10)),
                          Text(
                            contactLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: contactFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportGlow extends StatelessWidget {
  const _SupportGlow({
    required this.diameter,
    required this.colors,
  });

  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}
