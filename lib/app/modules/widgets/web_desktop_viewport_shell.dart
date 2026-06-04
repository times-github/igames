import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/modules/widgets/app_background_layer.dart';
import 'package:igames/config/app_config_export.dart';

class WebDesktopViewportShell extends StatelessWidget {
  const WebDesktopViewportShell({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  final Widget child;
  final String currentRoute;

  bool _isFullscreenRoute(String route) {
    return route == Routes.GAME_START;
  }

  String _normalizeRoute(String route) {
    final trimmed = route.trim();
    if (trimmed.isEmpty || trimmed == '/') {
      return AppPages.INITIAL;
    }

    final queryIndex = trimmed.indexOf('?');
    if (queryIndex >= 0) {
      return trimmed.substring(0, queryIndex);
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final route = _normalizeRoute(currentRoute);
        final shouldUseShell = kIsWeb &&
            constraints.maxWidth >= AppConfig.webDesktopShellBreakpoint &&
            !_isFullscreenRoute(route);

        if (!shouldUseShell) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: AppBackgroundLayer()),
              Positioned.fill(child: child),
            ],
          );
        }

        final maxShellWidth = math.max(320, constraints.maxWidth).toDouble();
        final shellWidth = math
            .min(
              AppConfig.webDesktopShellWidth,
              maxShellWidth,
            )
            .toDouble();
        final shellHeight = math.max(0, constraints.maxHeight).toDouble();

        return ColoredBox(
          color: AppConfig.webDesktopOuterBackground,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: shellWidth,
              height: shellHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(AppConfig.webDesktopShellRadius),
                  border: Border.all(color: AppConfig.webDesktopShellBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: AppConfig.webDesktopShellShadow,
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppConfig.webDesktopShellRadius),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Positioned.fill(child: AppBackgroundLayer()),
                      Positioned.fill(child: child),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
