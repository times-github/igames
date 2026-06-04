import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileView extends GetView<UserProfileController> {
  UserProfileView({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildEndDrawer(),
      body: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            // 顶部菜单栏
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2332),
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF2A3441),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 菜单按钮 - 打开右侧抽屉
                  GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E7BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  // 当前标签页标题
                  const Spacer(), // 占位符
                  Obx(() => Row(
                        children: [
                          Icon(
                            controller.drawerTabs[
                                    controller.selectedDrawerTab.value -
                                        1] //-1 因为列表从1开始
                                ['icon'],
                            color: const Color(0xFF1E7BFF),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${controller.drawerTabs[controller.selectedDrawerTab.value - 1]['title']}'
                                .tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )),
                  const Spacer(), // 占位符
                  //返回按钮 - 修改为图片样式
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.size(16),
                        vertical: r.size(8),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(r.size(20)),
                        border: Border.all(
                          color: const Color(0xFF2A3441),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: r.size(4),
                            offset: Offset(0, r.size(2)),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: r.size(6)),
                          const AppBackIcon(size: 24),
                          SizedBox(width: r.size(8)),
                          Text(
                            'back'.tr,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.font(14),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 主内容区域
            Expanded(
              child: _mainArea(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主内容区域
  Widget _mainArea() {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // 中心区域三页切换
          Expanded(
            child: Obx(() => IndexedStack(
                  index: controller.currentPage.value,
                  children: controller.pages,
                )),
          ),
        ],
      ),
    );
  }

  /// 构建右侧抽屉
  Widget _buildEndDrawer() {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF1A2332),
        border: Border(
          left: BorderSide(
            color: Color(0xFF2A3441),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 用户信息区域
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2A3441),
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF1A2332),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // 用户头像和基本信息
                Row(
                  children: [
                    // 用户头像
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E7BFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 用户信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 用户名
                          Obx(() => Text(
                                controller.username.value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              )),
                          // 用户昵称
                          Obx(() => Text(
                                controller.nickname.value,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 余额信息和操作按钮
                Row(
                  children: [
                    // 余额图标和金额

                    //TODO: 余额信息和操作按钮
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20242D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10),
                          //点击刷新余额
                          IconButton(
                            onPressed: () async {
                              await controller.home.refreshBalance();
                            },
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                          ),
                          Text(AppConfig.currencyCode(),
                              style: TextStyle(
                                  color: Color.fromARGB(255, 222, 247, 2))),
                          SizedBox(width: 4),

                          Obx(() => Text(
                                controller.home.balance.value,
                                style: TextStyle(color: Colors.white),
                              )),
                          SizedBox(width: 4),
                        ],
                      ),
                    ),

                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // 抽屉菜单
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 构建抽屉 菜单项 drawerTabs
                for (var tab in controller.drawerTabs)
                  Obx(
                    () => _buildDrawerMenuItem(
                        icon: tab['icon'],
                        title: tab['title'],
                        isSelected:
                            controller.selectedDrawerTab.value == tab['id'],
                        onTap: () {
                          controller.switchDrawerTab(tab['id']);
                          // 关闭抽屉
                          Get.back();
                          // 切换页面
                          controller.switchPageByIndex(tab['id'] - 1);
                        }),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建抽屉 菜单项
  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E7BFF).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: const Color(0xFF1E7BFF),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF1E7BFF)
                  : Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title.tr,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF1E7BFF)
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
