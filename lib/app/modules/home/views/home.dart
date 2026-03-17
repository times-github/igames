import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/home/views/home_shell.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';

class Home extends GetView<HomeController> {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final menuController = Get.find<GameMenuController>();
    return HomeShell(
      controller: controller,
      auth: auth,
      menuController: menuController,
    );
  }
}
