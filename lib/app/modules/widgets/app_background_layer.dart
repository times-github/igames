import 'package:flutter/material.dart';

import 'package:igames/config/app_config_export.dart';

class AppBackgroundLayer extends StatelessWidget {
  const AppBackgroundLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Image.asset(
          AppConfig.appBackgroundAsset,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}
