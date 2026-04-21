import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/views/language_selector_view.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';

const double _kHeaderIconSize = 40.0;

/// 通用顶部栏组件
/// 用于首页、优惠页面等
/// [showNotification] 是否显示通知按钮（登录时）
/// [showMenu] 是否显示左侧菜单按钮（登录时）
Widget buildCommonHeader(
  BuildContext context,
  AuthController auth, {
  bool showNotification = false,
  bool showMenu = false,
}) {
  final appInfo = Get.find<AppInfoService>();

  return Obx(() {
    final loggedIn = auth.isLoggedIn.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final showTitle = screenWidth >= 350;
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧：菜单 + logo + 标题
          Expanded(
            child: Row(
              children: [
                if (loggedIn && showMenu) ...[
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: InkWell(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Icon(Icons.menu_open_outlined,
                            color: Colors.white70, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Obx(() {
                    return AppBrandLogo(
                      logo: appInfo.appLogo.value,
                      borderRadius: BorderRadius.circular(10),
                    );
                  }),
                ),
                if (showTitle) ...[
                  const SizedBox(width: 4),
                  Flexible(
                    child: Obx(() {
                      final name = appInfo.appName.value;
                      return Text(
                        name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          // 右侧：固定宽度，客服按钮始终可见
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!loggedIn) ...[
                const LanguageSelectorView(),
                const SizedBox(width: 4),
                PulsingLoginButton(
                  onTap: () => auth.openLoginOverlay(context),
                ),
              ] else if (showNotification) ...[
                const NotificationButton(),
              ],
              const SizedBox(width: 6),
              CustomerServiceButton(onTap: auth.openCustomerService),
            ],
          ),
        ],
      ),
    );
  });
}

/// 登录按钮
class PulsingLoginButton extends StatelessWidget {
  const PulsingLoginButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A5CFF), Color(0xFF5E63FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          'loginRegister'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// 客服按钮
class CustomerServiceButton extends StatelessWidget {
  const CustomerServiceButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kHeaderIconSize,
      height: _kHeaderIconSize,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          // padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 242, 241, 247)
                    .withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.headset_mic_outlined,
            color: Colors.white70,
            size: 30,
          ),
        ),
      ),
    );
  }
}

/// 通知按钮
class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kHeaderIconSize,
      height: _kHeaderIconSize,
      child: InkWell(
        onTap: () => Get.toNamed(Routes.MESSAGE),
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none, //不裁剪
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                color: Colors.white70,
                size: 30,
              ),
              Obx(() {
                final auth = Get.find<AuthController>();
                if (!auth.isLoggedIn.value) return const SizedBox.shrink();
                final count = Get.isRegistered<AnnouncementService>()
                    ? Get.find<AnnouncementService>().totalUnreadCount.value
                    : 0;
                if (count <= 0) return const SizedBox.shrink();
                return const Positioned(
                  top: -4,
                  right: -4,
                  child: _UnreadDot(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 简单未读红点
class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B6A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B6A).withValues(alpha: 0.28),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
