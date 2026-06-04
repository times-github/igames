import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:igames/config/app_config.dart';

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
  static const Duration _loadTimeout = Duration(seconds: 20);
  static const int _maxRetryableErrors = 2;

  _TurnstileViewState _state = _TurnstileViewState.loading;
  Timer? _loadTimer;
  int _reloadNonce = 0;
  int _retryableErrorCount = 0;

  WebUri get _baseUri => WebUri('${AppConfig.appWebUrl}/');

  String get _htmlData {
    final siteKey = jsonEncode(widget.siteKey);
    final theme = jsonEncode(widget.theme);
    final language = jsonEncode(widget.language);
    return '''
<!DOCTYPE html>
<html lang="${widget.language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      background: transparent;
      overflow: hidden;
      height: 100%;
    }
    body {
      display: flex;
      align-items: center;
      justify-content: center;
    }
    #turnstile-root {
      width: 300px;
      min-height: 74px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
  </style>
  <script>
    function notifyFlutter(handler, value) {
      if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler(handler, value);
      }
    }

    function notifyVisibleWhenReady(attempt) {
      var root = document.getElementById('turnstile-root');
      if (!root) {
        return;
      }
      var hasContent = root.childElementCount > 0 || root.querySelector('iframe') !== null;
      if (hasContent) {
        notifyFlutter('turnstileVisible', '');
        return;
      }
      if (attempt >= 20) {
        return;
      }
      setTimeout(function() {
        notifyVisibleWhenReady(attempt + 1);
      }, 150);
    }

    function renderTurnstile() {
      if (!window.turnstile || window.__turnstileRendered) {
        return;
      }
      try {
        window.__turnstileRendered = true;
        window.turnstile.render('#turnstile-root', {
          sitekey: $siteKey,
          theme: $theme,
          language: $language,
          callback: function(token) {
            notifyFlutter('turnstileToken', token || '');
          },
          'expired-callback': function() {
            notifyFlutter('turnstileExpired', '');
          },
          'timeout-callback': function() {
            notifyFlutter('turnstileTimeout', '');
          },
          'error-callback': function(errorCode) {
            notifyFlutter('turnstileError', errorCode == null ? '' : String(errorCode));
            return false;
          }
        });
        notifyVisibleWhenReady(0);
      } catch (e) {
        notifyFlutter('turnstileError', '');
      }
    }

    window.__turnstileOnLoad = function() {
      renderTurnstile();
    };
  </script>
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit&onload=__turnstileOnLoad" async defer></script>
</head>
<body>
  <div id="turnstile-root"></div>
</body>
</html>
''';
  }

  void _startLoadingState() {
    _loadTimer?.cancel();
    _state = _TurnstileViewState.loading;
    _loadTimer = Timer(_loadTimeout, () {
      if (!mounted || _state != _TurnstileViewState.loading) return;
      widget.onToken('');
      setState(() => _state = _TurnstileViewState.error);
    });
  }

  void _markReady() {
    _loadTimer?.cancel();
    _retryableErrorCount = 0;
    if (!mounted || _state == _TurnstileViewState.ready) return;
    setState(() => _state = _TurnstileViewState.ready);
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

  void _handleTurnstileError([String? code]) {
    final errorCode = code?.trim() ?? '';
    widget.onToken('');
    debugPrint(
      'Turnstile mobile error: ${errorCode.isEmpty ? 'unknown' : errorCode}',
    );
    if (!mounted) return;

    if (_isFatalTurnstileError(errorCode)) {
      _loadTimer?.cancel();
      if (_state != _TurnstileViewState.error) {
        setState(() => _state = _TurnstileViewState.error);
      }
      return;
    }

    _retryableErrorCount += 1;
    if (_retryableErrorCount > _maxRetryableErrors) {
      _loadTimer?.cancel();
      if (_state != _TurnstileViewState.error) {
        setState(() => _state = _TurnstileViewState.error);
      }
      return;
    }

    if (_state != _TurnstileViewState.loading) {
      setState(() => _state = _TurnstileViewState.loading);
    }
    _startLoadingState();
  }

  void _retry() {
    widget.onToken('');
    setState(() {
      _reloadNonce += 1;
      _state = _TurnstileViewState.loading;
    });
    _retryableErrorCount = 0;
    _startLoadingState();
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

  Widget _buildStateOverlay({required bool compact}) {
    switch (_state) {
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
      case _TurnstileViewState.ready:
        return const SizedBox.shrink();
    }
  }

  @override
  void initState() {
    super.initState();
    _startLoadingState();
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteKey != widget.siteKey ||
        oldWidget.theme != widget.theme ||
        oldWidget.language != widget.language) {
      _retry();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.siteKey.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: InAppWebView(
              key: ValueKey('turnstile-mobile-$_reloadNonce'),
              initialData: InAppWebViewInitialData(
                data: _htmlData,
                baseUrl: _baseUri,
                historyUrl: _baseUri,
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                transparentBackground: true,
                supportZoom: false,
                disableHorizontalScroll: true,
                disableVerticalScroll: true,
                disableContextMenu: true,
                overScrollMode: OverScrollMode.NEVER,
              ),
              onWebViewCreated: (controller) {
                controller.addJavaScriptHandler(
                  handlerName: 'turnstileVisible',
                  callback: (_) {
                    _markReady();
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'turnstileToken',
                  callback: (args) {
                    _markReady();
                    final token =
                        args.isNotEmpty ? args.first?.toString() ?? '' : '';
                    widget.onToken(token);
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'turnstileExpired',
                  callback: (_) {
                    _markReady();
                    widget.onToken('');
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'turnstileError',
                  callback: (args) {
                    final code =
                        args.isNotEmpty ? args.first?.toString() ?? '' : '';
                    _handleTurnstileError(code);
                  },
                );
                controller.addJavaScriptHandler(
                  handlerName: 'turnstileTimeout',
                  callback: (_) {
                    widget.onToken('');
                    if (!mounted) return;
                    if (_state != _TurnstileViewState.loading) {
                      setState(() => _state = _TurnstileViewState.loading);
                    }
                    _startLoadingState();
                  },
                );
              },
              onReceivedError: (controller, request, error) {
                if (!(request.isForMainFrame ?? true)) {
                  return;
                }
                _handleTurnstileError();
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _state == _TurnstileViewState.ready,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight <= 110;
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _buildStateOverlay(compact: compact),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }
}
