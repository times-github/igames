import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  static const Duration _retryInterval = Duration(milliseconds: 180);
  static const int _maxRenderAttempts = 80;

  late final String _viewType;
  web.HTMLDivElement? _container;
  JSObject? _turnstile;
  JSAny? _widgetId;
  _TurnstileViewState _state = _TurnstileViewState.loading;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _viewType = 'turnstile-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteKey != widget.siteKey ||
        oldWidget.theme != widget.theme ||
        oldWidget.language != widget.language) {
      widget.onToken('');
      _remove();
      _setViewState(_TurnstileViewState.loading);
      _bootstrap();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _remove();
    super.dispose();
  }

  void _registerView() {
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _container = web.HTMLDivElement()
        ..id = _viewType
        ..style.width = '100%'
        ..style.height = '74px'
        ..style.minHeight = '70px'
        ..style.background = '#20242D'
        ..style.borderRadius = '10px'
        ..style.overflow = 'hidden'
        ..style.display = 'flex'
        ..style.alignItems = 'center'
        ..style.justifyContent = 'center'
        ..style.setProperty('transform', 'translateZ(0)')
        ..style.setProperty('will-change', 'transform');
      return _container!;
    });
  }

  void _bootstrap() {
    _retryTimer?.cancel();
    if (widget.siteKey.isEmpty) {
      _setViewState(_TurnstileViewState.error);
      return;
    }
    _ensureScriptInjected();
    _tryRender();
  }

  void _ensureScriptInjected() {
    final existing = web.document.querySelector(
      'script[data-cf-turnstile="true"]',
    );
    if (existing != null) {
      return;
    }

    final script = web.HTMLScriptElement()
      ..src =
          'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
      ..async = true
      ..defer = true
      ..setAttribute('data-cf-turnstile', 'true');
    web.document.head?.appendChild(script);
  }

  void _resetScriptTagIfNeeded() {
    final turnstile = (web.window as JSObject)['turnstile'];
    if (turnstile != null) {
      return;
    }
    final existing = web.document.querySelector(
      'script[data-cf-turnstile="true"]',
    );
    existing?.remove();
  }

  void _tryRender([int attempt = 0]) {
    _retryTimer?.cancel();
    if (!mounted) return;
    if (widget.siteKey.isEmpty) {
      _setViewState(_TurnstileViewState.error);
      return;
    }
    if (_container == null) {
      _scheduleRetry(attempt);
      return;
    }

    final turnstile = (web.window as JSObject)['turnstile'];
    if (turnstile == null) {
      _scheduleRetry(attempt);
      return;
    }

    _turnstile = turnstile as JSObject;

    try {
      final options = JSObject()
        ..['sitekey'] = widget.siteKey.toJS
        ..['theme'] = widget.theme.toJS
        ..['language'] = widget.language.toJS
        ..['callback'] = ((JSString token) {
          final tokenStr = token.toDart;
          if (tokenStr.isNotEmpty) {
            widget.onToken(tokenStr);
          }
        }).toJS
        ..['expired-callback'] = (() {
          widget.onToken('');
        }).toJS
        ..['error-callback'] = (() {
          widget.onToken('');
          _setViewState(_TurnstileViewState.error);
        }).toJS;
      _widgetId = _turnstile!.callMethodVarArgs<JSAny?>('render'.toJS, [
        _container!,
        options,
      ]);
      _setViewState(_TurnstileViewState.ready);
    } catch (_) {
      _scheduleRetry(attempt);
    }
  }

  void _scheduleRetry(int attempt) {
    if (attempt >= _maxRenderAttempts) {
      _setViewState(_TurnstileViewState.error);
      return;
    }
    _retryTimer = Timer(_retryInterval, () => _tryRender(attempt + 1));
  }

  void _setViewState(_TurnstileViewState state) {
    if (!mounted || _state == state) return;
    setState(() => _state = state);
  }

  void _retry() {
    widget.onToken('');
    _remove();
    _setViewState(_TurnstileViewState.loading);
    _resetScriptTagIfNeeded();
    _bootstrap();
  }

  void _remove() {
    if (_turnstile == null || _widgetId == null) {
      _widgetId = null;
      return;
    }
    try {
      _turnstile!.callMethodVarArgs<JSAny?>('remove'.toJS, [_widgetId]);
    } catch (_) {}
    _widgetId = null;
  }

  Widget _buildOverlay() {
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF8A6CFF),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
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
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF8A6CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'refresh'.tr,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteKey.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF20242D),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.center,
            child: HtmlElementView(viewType: _viewType),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _state == _TurnstileViewState.ready,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _buildOverlay(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
