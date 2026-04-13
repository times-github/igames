import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as http;
import 'package:get/get.dart';
import 'package:igames/app/data/services/userServices.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/launch_params.dart';
import 'package:igames/config/app_config.dart';
import 'package:igames/app/utils/storage.dart';
import 'package:igames/app/data/services/sse_notify_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/utils/web_lang_param.dart';
import 'package:igames/app/modules/auth/widgets/turnstile_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';

class AuthController extends GetxController {
  final isLoggedIn = false.obs; // 是否登录
  final isLoading = false.obs;

  final ApiClient _apiClient = Get.find<ApiClient>();
  String? _customerServiceContact;
  String? _whatsAppSupportContact;
  String? _downloadAppUrl;

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
    _checkLoginState();
  }

  void _handleUnauthorized() {
    logout();
    final context = Get.context;
    if (context != null) {
      openLoginOverlay(context);
    }
  }

  /// 检查登录状态
  Future<void> _checkLoginState() async {
    final loginState = await UserServices.getUserLoginState();
    isLoggedIn.value = loginState;
    //如果登录了，则刷新余额
    if (isLoggedIn.value) {
      print('refresh balance');
      Get.find<HomeController>().refreshBalance();
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
    openLoginOverlay(context);
    return false;
  }

  /// 打开登录弹窗
  ///
  /// 显示一个全屏的毛玻璃登录弹窗，包含邮箱和密码输入框
  ///
  /// [context] 构建上下文
  void openLoginOverlay(BuildContext context) {
    if (isLoginOpen.value) return;
    isLoginOpen.value = true;
    Future.microtask(() {
      if (!(Get.isDialogOpen ?? false)) {
        Get.dialog(
          Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.22),
                  ),
                ),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: _LoginPanel(onClose: closeLoginOverlay),
                ),
              ),
            ],
          ),
          barrierColor: Colors.black.withValues(alpha: 0.35),
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
      Get.find<HomeController>().refreshBalance();
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
    _showAuthFailure(code: code);
    return false;
  }

  void _showAuthFailure({String? code}) {
    final messageKey = _authErrorMessageKey(code);
    final message = messageKey.tr;
    Get.snackbar(
      'loginFailed'.tr,
      message,
      snackPosition: SnackPosition.TOP,
    );
  }

  String _authErrorMessageKey(String? code) {
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
        return 'passwordError';
      case '3008':
        return 'authPasswordOrCodeRequired';
      case '3009':
        return 'turnstileRequired';
      case null:
        return 'networkError';
      default:
        return 'authUnknownError';
    }
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
    UserServices.loginOut();
    isLoggedIn.value = false;
    if (Get.isRegistered<SseNotifyService>()) {
      await Get.find<SseNotifyService>().disconnect();
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
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 600 ? size.width : 420.0;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: dialogWidth,
                minWidth: min(size.width - 40, 320.0).toDouble(),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF171A29),
                      Color(0xFF111C2E),
                      Color(0xFF101522),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.42),
                      blurRadius: 36,
                      offset: const Offset(0, 20),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
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
                                      color: const Color(0xFF4F8DFF)
                                          .withValues(alpha: 0.28),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'helpCenter'.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'supportCenterSubtitle'.tr,
                                      style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                        fontSize: 13,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: Get.back,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                  foregroundColor:
                                      Colors.white.withValues(alpha: 0.82),
                                ),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
                          const SizedBox(height: 14),
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
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            contactLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.90),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        enabled
                            ? 'supportOpenNow'.tr
                            : 'supportNotConfigured'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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

// ============== 登录面板 ==============
class _LoginPanel extends StatefulWidget {
  const _LoginPanel({required this.onClose}); //
  final VoidCallback onClose; // 关闭回调

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelW = (size.width * 0.9).clamp(320.0, 420.0);
    final panelH = (size.height * 0.9).clamp(520.0, 640.0);
    const closeSize = 56.0;
    const closeOverlap = closeSize / 2;

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: panelW,
          height: panelH + closeSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _AuthPanelShell(
                width: panelW,
                height: panelH,
                child: _LoginForm(onClose: widget.onClose), // 登录表单
              ),
              Positioned(
                bottom: -closeOverlap,
                left: 0,
                right: 0,
                child: _CloseFab(onTap: widget.onClose),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== 登录表单 ==============
class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _account = TextEditingController(); // 账号/手机号
  final _password = TextEditingController(); // 密码
  final _smsCode = TextEditingController(); // 短信验证码
  final _formKey = GlobalKey<FormState>(); // 表单键
  String _turnstileToken = '';
  int _turnstileEpoch = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  List<_LoginBanner> _loginBanners = [];
  int _bannerIndex = 0;
  String _bannerLang = '';
  String _turnstileLang = 'auto';
  bool _loadingBanners = true;
  bool _usePhone = false;
  bool _remember = true;
  bool _obscurePwd = true;
  bool _sendingCode = false;
  int _smsCountdown = 0;
  Timer? _smsTimer;

  @override
  void initState() {
    super.initState();
    _bannerController.addListener(_handleBannerPageChange);
    _bannerLang = _resolveBannerLang();
    _turnstileLang = _resolveTurnstileLanguage();
    _loadLoginBanners();
  }

  @override
  void dispose() {
    _account.dispose();
    _password.dispose();
    _smsCode.dispose();
    _bannerTimer?.cancel();
    _bannerController
      ..removeListener(_handleBannerPageChange)
      ..dispose();
    _smsTimer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = Get.find<AuthController>();
    if (auth.isLoading.value) return;
    if (_formKey.currentState!.validate()) {
      final account = _account.text.trim();
      final credential = _usePhone ? _smsCode.text.trim() : _password.text;
      final token = _turnstileToken.trim();
      if (token.isNotEmpty) {
        setState(() {
          _turnstileToken = '';
          _turnstileEpoch += 1;
        });
      }
      await auth.loginOrRegister(account, credential,
          isPhone: _usePhone, turnstileToken: token);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lang = _resolveBannerLang();
    if (lang != _bannerLang) {
      _bannerLang = lang;
      _loadLoginBanners();
    }
    final turnstileLang = _resolveTurnstileLanguage();
    if (turnstileLang != _turnstileLang && mounted) {
      setState(() {
        _turnstileLang = turnstileLang;
        _turnstileToken = '';
        _turnstileEpoch += 1;
      });
    }
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

  Future<void> _loadLoginBanners() async {
    if (!mounted) return;
    setState(() => _loadingBanners = true);
    try {
      final resp = await ApiClient().get(
        '/user/banner/pic',
        withAuth: false,
        queryParameters: {
          'scene_code': 'login_banner',
          'lang': _bannerLang,
          'platform': kIsWeb ? 'h5' : 'app',
        },
      );
      final list = _parseBannerList(resp.data);
      if (!mounted) return;
      setState(() {
        _loginBanners = list;
        _bannerIndex = 0;
        _loadingBanners = false;
      });
      _startBannerAutoScroll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loginBanners = [];
        _bannerIndex = 0;
        _loadingBanners = false;
      });
      _bannerTimer?.cancel();
    }
  }

  List<_LoginBanner> _parseBannerList(dynamic data) {
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
        .map<_LoginBanner>((item) {
          if (item is Map) {
            final raw = item['image_url']?.toString() ?? '';
            final link = item['link_value']?.toString() ?? '';
            if (raw.isEmpty) {
              return const _LoginBanner(imageUrl: '');
            }
            return _LoginBanner(
              imageUrl: _normalizeBannerUrl(raw),
              link: link.isEmpty ? null : link,
            );
          }
          return const _LoginBanner(imageUrl: '');
        })
        .where((b) => b.imageUrl.isNotEmpty)
        .toList();
  }

  String _normalizeBannerUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return '${AppConfig.apiBaseUrl}/$trimmed';
  }

  void _handleBannerPageChange() {
    final page = _bannerController.page?.round() ?? 0;
    if (page != _bannerIndex && page >= 0 && page < _loginBanners.length) {
      setState(() => _bannerIndex = page);
    }
  }

  void _startBannerAutoScroll() {
    _bannerTimer?.cancel();
    if (_loginBanners.length <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_bannerController.hasClients) return;
      final next =
          ((_bannerController.page ?? 0).round() + 1) % _loginBanners.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Widget _buildLoginBanner() {
    if (_loadingBanners || _loginBanners.isEmpty) {
      return const SizedBox.shrink();
    }
    final banners = _loginBanners;
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (_) {},
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: GestureDetector(
                    onTap: () {
                      final link = banner.link;
                      if (link == null || link.isEmpty) return;
                      if (link.startsWith('http')) {
                        launchUrl(Uri.parse(link),
                            mode: LaunchMode.externalApplication);
                      } else {
                        Get.toNamed(link);
                      }
                    },
                    child: Image.network(
                      banner.imageUrl,
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => _bannerFallback(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 指示点已移除
      ],
    );
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C3BFF), Color(0xFF8A5BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoginBanner(),
                  if (!_loadingBanners && _loginBanners.isNotEmpty)
                    const SizedBox(height: 16),
                  _buildTabs(),
                  const SizedBox(height: 14),
                  _AuthTextField(
                    controller: _account,
                    hint: _usePhone
                        ? 'pleaseEnterPhone'.tr
                        : 'pleaseEnterUsername'.tr,
                    icon: _usePhone
                        ? Icons.phone_android_outlined
                        : Icons.person_outline,
                    keyboardType:
                        _usePhone ? TextInputType.phone : TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return _usePhone
                            ? 'pleaseEnterPhone'.tr
                            : 'pleaseEnterAccount'.tr;
                      }
                      if (_usePhone &&
                          !RegExp(r'^\d{6,}$').hasMatch(value.trim())) {
                        return 'pleaseEnterCorrectPhone'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSecretField(),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        activeColor: const Color(0xFF7A4CFF),
                        checkColor: Colors.white,
                        onChanged: (value) =>
                            setState(() => _remember = value ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'rememberPassword'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (supportsTurnstileChallenge &&
                      AppConfig.turnstileSiteKey.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 300,
                        child: TurnstileWidget(
                          key: ValueKey(
                            'turnstile-$_turnstileLang-$_turnstileEpoch',
                          ),
                          siteKey: AppConfig.turnstileSiteKey,
                          language: _turnstileLang,
                          onToken: (token) {
                            if (!mounted) return;
                            setState(() => _turnstileToken = token);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Obx(
                    () => _GradientButton(
                      //
                      text: 'loginRegister'.tr,
                      height: 48,
                      colors: const [Color(0xFF7B66FF), Color(0xFF6F7BFF)],
                      busy: auth.isLoading.value, //busy 是否显示加载中
                      animate: false,
                      fontWeight: FontWeight.w800,
                      onTap: auth.isLoading.value ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 4,
                    children: [
                      TextButton(
                        onPressed: () {
                          auth.openCustomerService();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
                        ),
                        child: Text('forgotPassword'.tr),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          auth.openCustomerService();
                        },
                        icon: const Icon(Icons.headset_mic_outlined, size: 18),
                        label: Text('contactCustomerService'.tr),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 8),
                    const SizedBox(height: 16),
                    _DownloadButtons(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabChip(
              label: 'account'.tr,
              active: !_usePhone,
              onTap: () => setState(() => _usePhone = false),
            ),
          ),
          Expanded(
            child: _TabChip(
              label: 'phone'.tr,
              active: _usePhone,
              onTap: () => setState(() => _usePhone = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecretField() {
    if (_usePhone) {
      return _AuthTextField(
        controller: _smsCode,
        hint: 'pleaseEnterSmsCode'.tr,
        icon: Icons.verified_outlined,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'pleaseEnterCode'.tr;
          }
          if (value.length < 4) {
            return 'codeLengthAtLeast4'.tr;
          }
          return null;
        },
        suffix: TextButton(
          onPressed: (_sendingCode || _smsCountdown > 0) ? null : _sendSmsCode,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF8A6CFF),
            minimumSize: const Size(68, 38),
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          child: _sendingCode
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (_smsCountdown > 0
                  ? Text('${_smsCountdown}s')
                  : Text('getCode'.tr)),
        ),
      );
    }

    return _AuthTextField(
      controller: _password,
      hint: 'passwordHint'.tr,
      icon: Icons.lock_outline,
      obscure: _obscurePwd,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'pleaseEnterPassword'.tr;
        }
        if (value.length < 6) {
          return 'passwordLengthMustBeAtLeast6'.tr;
        }
        return null;
      },
      suffix: IconButton(
        onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
        icon: Icon(
          _obscurePwd
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }

  Future<void> _sendSmsCode() async {
    final phone = _account.text.trim();
    if (phone.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterPhone'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (_smsCountdown > 0) return;
    setState(() => _sendingCode = true);
    final auth = Get.find<AuthController>();
    final nonce =
        '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9000) + 1000}';
    final timestamp =
        (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sign = _buildOtpSign(phone, nonce, timestamp);

    try {
      final resp = await auth._apiClient.post(
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
        Get.snackbar('tip'.tr, 'codeSent'.tr, snackPosition: SnackPosition.TOP);
      } else {
        Get.snackbar('tip'.tr, msg.isEmpty ? 'networkError'.tr : msg,
            snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      String msg = 'networkError'.tr;
      if (e is http.DioException) {
        final data = e.response?.data;
        final serverMsg = data is Map ? data['msg']?.toString() : null;
        if (serverMsg != null && serverMsg.isNotEmpty) {
          msg = serverMsg;
        }
      }
      Get.snackbar('tip'.tr, msg, snackPosition: SnackPosition.TOP);
    } finally {
      if (mounted) {
        setState(() => _sendingCode = false);
      }
    }
  }

  String _buildOtpSign(String phone, String nonce, String timestamp) {
    final payload = '${phone.toLowerCase()}|$nonce|$timestamp';
    return md5
        .convert(utf8.encode(payload + AppConfig.otpSecret))
        .toString()
        .toUpperCase();
  }

  void _startCountdown() {
    setState(() => _smsCountdown = 60);
    _smsTimer?.cancel();
    _smsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _smsCountdown -= 1;
        if (_smsCountdown <= 0) {
          _smsCountdown = 0;
          timer.cancel();
        }
      });
    });
  }
}

class _AuthPanelShell extends StatelessWidget {
  const _AuthPanelShell({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF9C7BFF),
            Color(0xFF5A7BFF),
            Color(0xFF2B1C5A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1E2E), Color(0xFF0F1322)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ============== 复用小组件 ==============
class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        filled: true,
        fillColor: const Color(0xFF1F2433),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7A4CFF), width: 1.2),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.colors,
    required this.height,
    this.onTap,
    this.busy = false,
    this.animate = true,
    this.textColor = Colors.white,
    this.fontWeight = FontWeight.w700,
    this.fontSize = 16,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final List<Color> colors;
  final double height;
  final VoidCallback? onTap;
  final bool busy;
  final bool animate;
  final Color textColor;
  final FontWeight fontWeight;
  final double fontSize;
  final int maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final content = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            ],
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                  maxLines: maxLines,
                  overflow: overflow,
                  textAlign: textAlign,
                ),
        ),
      ),
    );

    if (!animate) return content;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.7,
      child: content,
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF2A3042) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBanner {
  final String imageUrl;
  final String? link;

  const _LoginBanner({required this.imageUrl, this.link});
}

class _DownloadButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        _GradientButton(
          text: 'downloadAppNow'.tr,
          height: 44,
          colors: const [Color(0xFF31C46C), Color(0xFF57E287)],
          fontSize: 13,
          onTap: auth.openDownloadUrl,
        ),
      ],
    );
  }
}

class _CloseFab extends StatelessWidget {
  const _CloseFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2F3240), Color(0xFF1F2230)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.85),
            width: 2,
          ),
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 22),
      ),
    );
  }
}
