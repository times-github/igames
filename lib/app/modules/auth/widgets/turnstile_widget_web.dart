import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    required this.onToken,
    this.theme = 'dark',
  });

  final String siteKey;
  final ValueChanged<String> onToken;
  final String theme;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  static Future<void>? _scriptFuture;
  late final String _viewType;
  web.HTMLDivElement? _container;
  JSObject? _turnstile;
  JSAny? _widgetId;

  @override
  void initState() {
    super.initState();
    _viewType = 'turnstile-${DateTime.now().microsecondsSinceEpoch}';
    _registerView();
    _ensureScriptLoaded().then((_) => _render());
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteKey != widget.siteKey ||
        oldWidget.theme != widget.theme) {
      _reset();
      _render();
    }
  }

  @override
  void dispose() {
    _remove();
    super.dispose();
  }

  void _registerView() {
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _container = web.HTMLDivElement()
        ..id = _viewType
        ..style.width = '100%'
        ..style.height = '74px'
        ..style.minHeight = '70px';
      return _container!;
    });
  }

  Future<void> _ensureScriptLoaded() {
    if (_scriptFuture != null) return _scriptFuture!;
    final completer = Completer<void>();
    final existing = web.document.querySelector(
      'script[data-cf-turnstile="true"]',
    );
    if (existing != null) {
      completer.complete();
    } else {
      final script = web.HTMLScriptElement()
        ..src =
            'https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit'
        ..async = true
        ..defer = true
        ..setAttribute('data-cf-turnstile', 'true');
      script.addEventListener('error', ((web.Event _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }).toJS);
      script.addEventListener('load', ((web.Event _) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }).toJS);
      web.document.head?.appendChild(script);
    }
    _scriptFuture = completer.future;
    return _scriptFuture!;
  }

  void _render() {
    if (_container == null || widget.siteKey.isEmpty) return;
    final turnstile = (web.window as JSObject)['turnstile'];
    if (turnstile == null) return;
    _turnstile = turnstile as JSObject;
    final options = JSObject()
      ..['sitekey'] = widget.siteKey.toJS
      ..['theme'] = widget.theme.toJS
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
      }).toJS;
    _widgetId = _turnstile!.callMethodVarArgs<JSAny?>('render'.toJS, [
      _container!,
      options,
    ]);
  }

  void _reset() {
    if (_turnstile == null || _widgetId == null) return;
    try {
      _turnstile!.callMethodVarArgs<JSAny?>('reset'.toJS, [_widgetId]);
    } catch (_) {}
  }

  void _remove() {
    if (_turnstile == null || _widgetId == null) return;
    try {
      _turnstile!.callMethodVarArgs<JSAny?>('remove'.toJS, [_widgetId]);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteKey.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 74,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
