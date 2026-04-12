import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/userServices.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/data/models/notification_item.dart';
import 'package:igames/app/data/services/notification_center_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/sse_client.dart';

typedef SseEventHandler = void Function(Map<String, dynamic> payload);

class SseNotifyService extends GetxService {
  final ApiClient _apiClient = ApiClient();
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  bool _connected = false;
  StreamSubscription<String>? _nativeSub;
  SseClient? _webClient;
  final Map<String, SseEventHandler> _handlers = {};
  String _currentEvent = '';

  void registerHandler(String event, SseEventHandler handler) {
    if (event.isEmpty) return;
    _handlers[event] = handler;
  }

  Future<void> connect() async {
    if (_connected) return;
    _connected = true; // 先占位，防止并发调用
    final token = await UserServices.getToken();
    if (token == null || token.isEmpty) {
      _connected = false;
      return;
    }

    if (kIsWeb) {
      _webClient ??= createSseClient();
      _webClient!.connect(
        url: '${ApiClient.baseUrl}/user/sse/notify',
        headers: {'AuthorizationU': 'Bearer $token'},
        onData: _handleLine,
        onError: (err) => debugPrint('SSE error: $err'),
      );
      return;
    }

    try {
      final response = await _apiClient.dio.get<http.ResponseBody>(
        '/user/sse/notify',
        options: http.Options(
          responseType: http.ResponseType.stream,
          headers: {'AuthorizationU': 'Bearer $token'},
        ),
      );
      final stream = response.data?.stream;
      if (response.statusCode == 200 && stream != null) {
        debugPrint('SSE connected');
      }
      if (stream == null) return;
      _nativeSub = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine, onError: (e) {
        debugPrint('SSE error: $e');
      });
    } catch (e) {
      debugPrint('SSE connect failed: $e');
    }
  }

  void _handleLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      _currentEvent = '';
      return;
    }
    if (trimmed.startsWith(':')) {
      return;
    }
    if (trimmed.startsWith('retry:')) {
      return;
    }
    if (trimmed.startsWith('event:')) {
      _currentEvent = trimmed.substring(6).trim();
      return;
    }
    if (trimmed.startsWith('data:')) {
      final data = trimmed.substring(5).trim();
      if (data.isNotEmpty) {
        _handleMessage(data, _currentEvent);
      }
    }
  }

  void _handleMessage(String raw, String eventName) {
    _controller.add(raw);
    final parsed = _tryDecode(raw);
    if (parsed is! Map) return;
    final type = parsed['type']?.toString();
    final handlerKey = (type == null || type.isEmpty) ? eventName : type;
    if (handlerKey.isEmpty) return;
    final handler = _handlers[handlerKey];
    handler?.call(Map<String, dynamic>.from(parsed));
  }

  dynamic _tryDecode(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatAmountLabel(dynamic rawAmount, String? currency) {
    final amountText = _formatAmount(rawAmount);
    final code = currency?.toUpperCase() ?? '';
    if (code == 'IDR') {
      return '${AppConfig.currencySymbol()} $amountText';
    }
    if (code.isNotEmpty) {
      return '$amountText $code';
    }
    return amountText;
  }

  void _registerDefaultHandlers() {
    _handlers['deposit_success'] = (payload) {
      final amountLabel = _formatAmountLabel(
        payload['amount'],
        payload['currency']?.toString(),
      );
      Get.snackbar(
        'tip'.tr,
        'depositSuccessNotification'.trParams({'amount': amountLabel}),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
    };
    _handlers['announcement'] =
        (payload) => _handleAnnouncementLike(payload, 'announcement');
    _handlers['activity'] =
        (payload) => _handleAnnouncementLike(payload, 'activity');
    _handlers['notice'] =
        (payload) => _handleAnnouncementLike(payload, 'notice');
  }

  void _handleAnnouncementLike(
    Map<String, dynamic> payload,
    String eventType,
  ) {
    final item = NotificationItem.fromSse(payload);
    if (!_isLangMatch(item.lang)) return;

    if (Get.isRegistered<NotificationCenterService>()) {
      Get.find<NotificationCenterService>().add(item);
    }

    if (Get.isRegistered<AnnouncementService>()) {
      final service = Get.find<AnnouncementService>();
      service.totalUnreadCount.value += 1;
    }

    _showAnnouncementDialog(item, eventType);
  }

  bool _isLangMatch(String lang) {
    if (lang.isEmpty) return true;
    return lang.toLowerCase() == _currentLang();
  }

  String _currentLang() {
    final locale = Get.locale;
    return normalizeApiLang(
      locale?.toLanguageTag() ?? locale?.languageCode,
      fallback: 'en',
    );
  }

  String _fallbackTitle(String type) {
    switch (type) {
      case 'announcement':
        return 'announcement'.tr;
      case 'activity':
        return 'activity'.tr;
      case 'notice':
        return 'notice'.tr;
      default:
        return type;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _registerDefaultHandlers();
  }

  void _showAnnouncementDialog(NotificationItem item, String eventType) {
    if (Get.isDialogOpen ?? false) return;
    final title =
        item.title.isNotEmpty ? item.title : _fallbackTitle(eventType);
    final content = item.content.isNotEmpty ? item.content : title;
    final hasDetail = item.id > 0;

    final IconData headerIcon = switch (eventType) {
      'activity' => Icons.local_activity_rounded,
      'notice' => Icons.info_rounded,
      _ => Icons.campaign_rounded,
    };

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2035),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── 渐变头部 ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7B5CFF), Color(0xFF4EA3FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(headerIcon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // ── 内容区 ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                  child: Text(
                    content,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // ── 按钮区 ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'close'.tr,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Get.back();
                          if (hasDetail) {
                            if (Get.isRegistered<AnnouncementService>()) {
                              Get.find<AnnouncementService>()
                                  .markAsRead(item.id);
                            }
                            Get.toNamed(Routes.MESSAGE_DETAIL,
                                arguments: item.id);
                          } else {
                            Get.toNamed(Routes.MESSAGE);
                          }
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7B5CFF), Color(0xFF4EA3FF)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hasDetail ? 'detail'.tr : 'viewAll'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.65),
      barrierDismissible: true,
    );
  }

  String _formatAmount(dynamic rawAmount) {
    if (rawAmount == null) return '0';
    final numValue = num.tryParse(rawAmount.toString());
    if (numValue == null) return rawAmount.toString();
    final parts = numValue.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    return intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  void disconnect() {
    _connected = false;
    _nativeSub?.cancel();
    _nativeSub = null;
    _webClient?.disconnect();
    _currentEvent = '';
  }

  @override
  void onClose() {
    disconnect();
    _controller.close();
    super.onClose();
  }
}
