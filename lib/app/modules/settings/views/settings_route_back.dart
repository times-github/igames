import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';

void handleSettingsRouteBack(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }

  if (Get.currentRoute != Routes.HOME) {
    Get.offAllNamed(Routes.HOME);
  }
}
