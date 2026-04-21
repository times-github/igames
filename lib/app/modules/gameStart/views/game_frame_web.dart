import 'dart:async';
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class GameFrame extends StatefulWidget {
  const GameFrame({
    super.key,
    required this.url,
    this.onLoaded,
    this.onError,
  });

  final String url;
  final VoidCallback? onLoaded;
  final ValueChanged<String>? onError;

  @override
  State<GameFrame> createState() => _GameFrameState();
}

class _GameFrameState extends State<GameFrame> {
  static const Duration _loadTimeout = Duration(seconds: 18);

  late String _viewType;
  StreamSubscription<web.Event>? _loadSubscription;
  StreamSubscription<web.Event>? _errorSubscription;
  Timer? _loadTimer;
  bool _didResolve = false;

  @override
  void initState() {
    super.initState();
    _viewType = _createViewType();
    _registerViewFactory();
  }

  @override
  void didUpdateWidget(covariant GameFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _disposeIframeListeners();
      _viewType = _createViewType();
      _registerViewFactory();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _disposeIframeListeners();
    super.dispose();
  }

  String _createViewType() {
    return 'game-frame-${DateTime.now().microsecondsSinceEpoch}';
  }

  void _registerViewFactory() {
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      _didResolve = false;
      final iframe = web.HTMLIFrameElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.backgroundColor = 'transparent'
        ..allowFullscreen = true
        ..allow = 'autoplay; fullscreen; clipboard-read; clipboard-write'
        ..referrerPolicy = 'strict-origin-when-cross-origin';

      _loadSubscription = iframe.onLoad.listen((_) {
        if (_didResolve) {
          return;
        }
        _didResolve = true;
        _loadTimer?.cancel();
        widget.onLoaded?.call();
      });
      _errorSubscription = iframe.onError.listen((_) {
        if (_didResolve) {
          return;
        }
        _didResolve = true;
        _loadTimer?.cancel();
        widget.onError?.call('加载游戏页面失败');
      });
      _loadTimer = Timer(_loadTimeout, () {
        if (_didResolve) {
          return;
        }
        _didResolve = true;
        widget.onError?.call('游戏页面加载超时');
      });

      final container = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.overflow = 'hidden'
        ..append(iframe);

      return container;
    });
  }

  void _disposeIframeListeners() {
    _loadTimer?.cancel();
    _loadTimer = null;
    _loadSubscription?.cancel();
    _errorSubscription?.cancel();
    _loadSubscription = null;
    _errorSubscription = null;
    _didResolve = false;
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
