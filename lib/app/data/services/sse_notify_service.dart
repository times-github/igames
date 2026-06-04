import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/data/models/notification_item.dart';
import 'package:igames/app/data/services/notification_center_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/sse_client.dart';

typedef SseEventHandler = void Function(Map<String, dynamic> payload);

class SseNotifyService extends GetxService with WidgetsBindingObserver {
  static const Duration _defaultReconnectDelay = Duration(seconds: 3);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);

  final http.Dio _sseDio = http.Dio(
    http.BaseOptions(
      baseUrl: ApiClient.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: null,
      headers: const {'Accept': 'text/event-stream'},
    ),
  );
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  bool _wantConnection = false;
  bool _isConnecting = false;
  bool _connected = false;
  bool _appInForeground = true;
  int _connectionGeneration = 0;
  int _reconnectAttempt = 0;
  int? _serverRetryMs;
  Timer? _reconnectTimer;
  StreamSubscription<String>? _nativeSub;
  http.CancelToken? _nativeCancelToken;
  SseClient? _webClient;
  final Map<String, SseEventHandler> _handlers = {};
  final List<String> _pendingDataLines = <String>[];
  String _pendingEvent = '';
  String _lastEventId = '';

  void registerHandler(String event, SseEventHandler handler) {
    if (event.isEmpty) return;
    _handlers[event] = handler;
  }

  Future<void> connect() async {
    _wantConnection = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _startConnection();
  }

  Future<void> _startConnection() async {
    if (_isConnecting || _connected || !_canMaintainConnection()) {
      return;
    }

    final token = await UserServices.getToken();
    if (!_canMaintainConnection()) {
      return;
    }
    if (token == null || token.isEmpty) {
      _wantConnection = false;
      return;
    }

    _isConnecting = true;
    final generation = ++_connectionGeneration;
    final headers = _buildSseHeaders(token);
    _resetPendingEvent();

    if (kIsWeb) {
      _webClient ??= createSseClient();
      _webClient!.connect(
        url: '${ApiClient.baseUrl}/user/sse/notify',
        headers: headers,
        onData: _handleLine,
        onOpen: () => _handleConnectionOpen(generation),
        onDone: () => _handleConnectionEnded(generation),
        onError: (err) => debugPrint('SSE error: $err'),
      );
      return;
    }

    try {
      final cancelToken = http.CancelToken();
      _nativeCancelToken = cancelToken;
      final response = await _sseDio.get<http.ResponseBody>(
        '/user/sse/notify',
        cancelToken: cancelToken,
        options: http.Options(
          responseType: http.ResponseType.stream,
          headers: headers,
        ),
      );
      if (generation != _connectionGeneration || !_canMaintainConnection()) {
        cancelToken.cancel('Discard stale SSE connection');
        return;
      }

      final stream = response.data?.stream;
      if (response.statusCode != 200 || stream == null) {
        _handleConnectionEnded(
          generation,
          error: 'SSE request failed with status ${response.statusCode ?? 0}',
        );
        return;
      }

      _handleConnectionOpen(generation);
      var terminated = false;

      void finish({Object? error}) {
        if (terminated) return;
        terminated = true;
        _handleConnectionEnded(generation, error: error);
      }

      _nativeSub = stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _handleLine,
            onDone: () => finish(),
            onError: (error) {
              if (!_isExpectedCancel(error)) {
                debugPrint('SSE error: $error');
              }
              finish(error: error);
            },
            cancelOnError: true,
          );
    } catch (e) {
      if (_isExpectedCancel(e)) {
        _resetConnectionFlags();
        return;
      }
      debugPrint('SSE connect failed: $e');
      _handleConnectionEnded(generation, error: e);
    }
  }

  void _handleLine(String line) {
    final normalized =
        line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

    if (normalized.isEmpty) {
      _dispatchPendingEvent();
      return;
    }
    if (normalized.startsWith(':')) {
      return;
    }

    final separatorIndex = normalized.indexOf(':');
    final field = separatorIndex >= 0
        ? normalized.substring(0, separatorIndex)
        : normalized;
    var value =
        separatorIndex >= 0 ? normalized.substring(separatorIndex + 1) : '';
    if (value.startsWith(' ')) {
      value = value.substring(1);
    }

    switch (field) {
      case 'event':
        _pendingEvent = value;
        return;
      case 'data':
        _pendingDataLines.add(value);
        return;
      case 'id':
        if (!value.contains('\u0000')) {
          _lastEventId = value;
        }
        return;
      case 'retry':
        final retryMs = int.tryParse(value);
        if (retryMs != null && retryMs >= 0) {
          _serverRetryMs = retryMs;
        }
        return;
      default:
        return;
    }
  }

  void _dispatchPendingEvent() {
    if (_pendingDataLines.isEmpty) {
      _pendingEvent = '';
      return;
    }
    final payload = _pendingDataLines.join('\n');
    final eventName = _pendingEvent;
    _resetPendingEvent();
    _handleMessage(payload, eventName);
  }

  void _resetPendingEvent() {
    _pendingEvent = '';
    _pendingDataLines.clear();
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

  Map<String, String> _buildSseHeaders(String token) {
    return {
      'AuthorizationU': 'Bearer $token',
      if (_lastEventId.isNotEmpty) 'Last-Event-ID': _lastEventId,
    };
  }

  bool _canMaintainConnection() {
    return _wantConnection && (kIsWeb || _appInForeground);
  }

  bool _isExpectedCancel(Object error) {
    return error is http.DioException &&
        error.type == http.DioExceptionType.cancel;
  }

  void _handleConnectionOpen(int generation) {
    if (generation != _connectionGeneration) {
      return;
    }
    _connected = true;
    _isConnecting = false;
    _reconnectAttempt = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    debugPrint('SSE connected');
  }

  void _handleConnectionEnded(int generation, {Object? error}) {
    if (generation != _connectionGeneration) {
      return;
    }
    final wasActive = _connected || _isConnecting;
    _nativeSub = null;
    _nativeCancelToken = null;
    _resetConnectionFlags();
    _resetPendingEvent();

    if (error != null && !_isExpectedCancel(error)) {
      debugPrint('SSE disconnected with error: $error');
    } else if (wasActive) {
      debugPrint('SSE disconnected');
    }

    if (_canMaintainConnection()) {
      _scheduleReconnect();
    }
  }

  void _resetConnectionFlags() {
    _connected = false;
    _isConnecting = false;
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null || !_canMaintainConnection()) {
      return;
    }

    final delay = _nextReconnectDelay();
    debugPrint(
      'SSE reconnect scheduled in ${delay.inMilliseconds}ms',
    );
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      unawaited(_startConnection());
    });
  }

  Duration _nextReconnectDelay() {
    const factors = <int>[1, 2, 4, 8, 10];
    final index = _reconnectAttempt < factors.length
        ? _reconnectAttempt
        : factors.length - 1;
    final baseMs = _serverRetryMs ?? _defaultReconnectDelay.inMilliseconds;
    final delayMs = (baseMs * factors[index]).clamp(
      _defaultReconnectDelay.inMilliseconds,
      _maxReconnectDelay.inMilliseconds,
    );
    _reconnectAttempt += 1;
    return Duration(milliseconds: delayMs);
  }

  Future<void> _stopConnection({
    bool clearIntent = true,
    bool preserveCursor = false,
  }) async {
    if (clearIntent) {
      _wantConnection = false;
    }
    _connectionGeneration += 1;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _resetConnectionFlags();
    _resetPendingEvent();

    _nativeCancelToken?.cancel('SSE disconnected');
    _nativeCancelToken = null;
    final nativeSub = _nativeSub;
    _nativeSub = null;
    await nativeSub?.cancel();

    _webClient?.disconnect();

    if (!preserveCursor) {
      _lastEventId = '';
      _serverRetryMs = null;
      _reconnectAttempt = 0;
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

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _registerDefaultHandlers();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _appInForeground = true;
        if (_wantConnection) {
          unawaited(connect());
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _appInForeground = false;
        unawaited(
          _stopConnection(clearIntent: false, preserveCursor: true),
        );
        break;
    }
  }

  Future<void> disconnect() async {
    await _stopConnection(clearIntent: true, preserveCursor: false);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    // 确保所有资源都被清理
    try {
      _stopConnection(clearIntent: true, preserveCursor: false);
    } catch (e) {
      debugPrint('Error during SSE cleanup: $e');
    }

    // 确保StreamController被关闭
    try {
      if (!_controller.isClosed) {
        _controller.close();
      }
    } catch (e) {
      debugPrint('Error closing SSE StreamController: $e');
    }

    // 确保Dio被关闭
    try {
      _sseDio.close(force: true);
    } catch (e) {
      debugPrint('Error closing SSE Dio: $e');
    }

    super.onClose();
  }
}
