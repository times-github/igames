import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/config/app_config.dart';
import 'package:web/web.dart' as web;

const bool supportsTurnstileChallenge = true;

enum _TurnstileViewState { loading, ready, error }

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    required this.onToken,
    this.theme = 'dark',
    this.language = 'auto',
  });

  final String siteKey;
  final ValueChanged<String> onToken;
  final String theme;
  final String language;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  static const Duration _loadTimeout = Duration(seconds: 18);
  static const int _maxRetryableErrors = 2;

  late String _viewType;
  late String _instanceId;
  _TurnstileViewState _state = _TurnstileViewState.loading;
  web.HTMLDivElement? _frameContainer;
  web.HTMLIFrameElement? _frameElement;
  int _retryableErrorCount = 0;

  Timer? _loadTimer;
  StreamSubscription<web.Event>? _loadSubscription;
  StreamSubscription<web.Event>? _errorSubscription;
  StreamSubscription<web.MessageEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _bindMessageListener();
    _mountFrame();
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteKey != widget.siteKey ||
        oldWidget.theme != widget.theme ||
        oldWidget.language != widget.language) {
      widget.onToken('');
      _mountFrame();
    }
  }

  @override
  void dispose() {
    _disposeFrameResources();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _bindMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = web.window.onMessage.listen(_handleMessage);
  }

  void _mountFrame() {
    _disposeFrameResources();
    _instanceId = 'turnstile-${DateTime.now().microsecondsSinceEpoch}';
    _viewType = 'turnstile-frame-$_instanceId';
    _retryableErrorCount = 0;
    _setViewState(_TurnstileViewState.loading);

    if (widget.siteKey.isEmpty) {
      _setViewState(_TurnstileViewState.error);
      return;
    }

    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src = _buildFrameUrl()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent'
        ..style.overflow = 'hidden'
        ..allow = 'clipboard-read; clipboard-write'
        ..referrerPolicy = 'strict-origin-when-cross-origin';

      final container = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.position = 'relative'
        ..style.overflow = 'hidden'
        ..style.borderRadius = '10px'
        ..style.contain = 'layout paint size style'
        ..append(iframe);

      _frameElement = iframe;
      _frameContainer = container;
      _syncFrameInteraction();

      _loadSubscription = iframe.onLoad.listen((_) {});
      _errorSubscription = iframe.onError.listen((_) {
        widget.onToken('');
        _loadTimer?.cancel();
        _setViewState(_TurnstileViewState.error);
      });

      return container;
    });

    _startLoadTimer();

    if (mounted) {
      setState(() {});
    }
  }

  void _startLoadTimer() {
    _loadTimer?.cancel();
    _loadTimer = Timer(_loadTimeout, () {
      if (!mounted || _state != _TurnstileViewState.loading) {
        return;
      }
      widget.onToken('');
      _setViewState(_TurnstileViewState.error);
    });
  }

  String _buildFrameUrl() {
    return Uri(
      path: 'turnstile_frame.html',
      queryParameters: <String, String>{
        'instance': _instanceId,
        'siteKey': widget.siteKey,
        'theme': widget.theme,
        'language': widget.language.toLowerCase(),
      },
    ).toString();
  }

  void _handleMessage(web.MessageEvent event) {
    if (!mounted) {
      return;
    }

    final rawData = event.data;
    if (rawData == null || rawData.isUndefinedOrNull) {
      return;
    }

    String? rawText;
    if (rawData case JSString jsString) {
      rawText = jsString.toDart;
    }
    if (rawText == null || rawText.isEmpty) {
      return;
    }

    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(rawText);
      if (decoded is! Map) {
        return;
      }
      message = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    if (message['channel'] != 'igames-turnstile' ||
        message['instance'] != _instanceId) {
      return;
    }

    final type = message['type']?.toString();
    switch (type) {
      case 'rendered':
        _loadTimer?.cancel();
        _retryableErrorCount = 0;
        _setViewState(_TurnstileViewState.ready);
        break;
      case 'token':
        _loadTimer?.cancel();
        _retryableErrorCount = 0;
        widget.onToken(message['token']?.toString() ?? '');
        _setViewState(_TurnstileViewState.ready);
        break;
      case 'expired':
        widget.onToken('');
        break;
      case 'timeout':
        widget.onToken('');
        _setViewState(_TurnstileViewState.loading);
        _startLoadTimer();
        break;
      case 'error':
        _handleTurnstileError(message['code']?.toString());
        break;
    }
  }

  bool _isFatalTurnstileError(String? code) {
    switch (code) {
      case '100000':
      case '110100':
      case '110110':
      case '110200':
      case '200100':
      case '400020':
      case '400070':
        return true;
      default:
        return false;
    }
  }

  void _handleTurnstileError(String? code) {
    final errorCode = code?.trim() ?? '';
    widget.onToken('');
    debugPrint(
      'Turnstile web error: ${errorCode.isEmpty ? 'unknown' : errorCode}',
    );

    if (_isFatalTurnstileError(errorCode)) {
      _loadTimer?.cancel();
      _setViewState(_TurnstileViewState.error);
      return;
    }

    _retryableErrorCount += 1;
    if (_retryableErrorCount > _maxRetryableErrors) {
      _loadTimer?.cancel();
      _setViewState(_TurnstileViewState.error);
      return;
    }

    _setViewState(_TurnstileViewState.loading);
    _startLoadTimer();
  }

  void _disposeFrameResources() {
    _loadTimer?.cancel();
    _loadTimer = null;
    _loadSubscription?.cancel();
    _errorSubscription?.cancel();
    _loadSubscription = null;
    _errorSubscription = null;
    _frameElement = null;
    _frameContainer = null;
  }

  void _syncFrameInteraction() {
    final interactive = _state == _TurnstileViewState.ready;
    final pointerEvents = interactive ? 'auto' : 'none';
    final visibility = interactive ? 'visible' : 'hidden';

    _frameContainer?.style.pointerEvents = pointerEvents;
    _frameContainer?.style.visibility = visibility;
    _frameElement?.style.pointerEvents = pointerEvents;
    _frameElement?.style.visibility = visibility;
  }

  void _setViewState(_TurnstileViewState state) {
    if (!mounted) {
      return;
    }
    if (_state == state) {
      _syncFrameInteraction();
      return;
    }
    setState(() => _state = state);
    _syncFrameInteraction();
  }

  void _retry() {
    widget.onToken('');
    _mountFrame();
  }

  Widget _buildRefreshButton({double height = 32}) {
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: _retry,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppConfig.btnSelectedColor,
          foregroundColor: AppConfig.btnDefaultTextColor,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: Size(0, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: AppConfig.btnSelectedBorderColor,
              width: 1.2,
            ),
          ),
        ),
        child: Text(
          'refresh'.tr,
          style: const TextStyle(
            color: AppConfig.btnDefaultTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay({required bool compact}) {
    switch (_state) {
      case _TurnstileViewState.ready:
        return const SizedBox.shrink();
      case _TurnstileViewState.loading:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF20242D),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 0,
          ),
          child: compact
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppConfig.btnSelectedColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'turnstileLoading'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppConfig.btnSelectedColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'turnstileLoading'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        );
      case _TurnstileViewState.error:
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF20242D),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.35),
            ),
          ),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: compact
              ? Row(
                  children: [
                    Expanded(
                      child: Text(
                        'turnstileLoadFailed'.tr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildRefreshButton(height: 28),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'turnstileLoadFailed'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRefreshButton(),
                  ],
                ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteKey.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF20242D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              alignment: Alignment.center,
              child: HtmlElementView(
                key: ValueKey(_viewType),
                viewType: _viewType,
              ),
            ),
          ),
          if (_state != _TurnstileViewState.ready)
            Positioned.fill(
              child: AbsorbPointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight <= 84;
                    return _buildOverlay(compact: compact);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
