import 'dart:math' as math;
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

/// 脉动登录按钮（带动画效果）
class PulsingLoginButton extends StatefulWidget {
  const PulsingLoginButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<PulsingLoginButton> createState() => _PulsingLoginButtonState();
}

class _PulsingLoginButtonState extends State<PulsingLoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = _controller.drive(Tween<double>(begin: 0.94, end: 1.04));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
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
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 6),
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
                  child: _PulsingDot(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// 波动的红点组件
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
          final dotScale = 0.9 + pulse * 0.25;
          final dotOpacity = 0.6 + pulse * 0.4;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 第一层波纹
              _buildRipple(0.0, 1.0),
              // 第二层波纹
              _buildRipple(0.3, 1.0),
              // 第三层波纹
              _buildRipple(0.6, 1.0),
              // 中心实心圆点
              Transform.scale(
                scale: dotScale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFFF3B6A).withValues(alpha: dotOpacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B6A).withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRipple(double delay, double maxScale) {
    final value = (_controller.value + delay) % 1.0;
    final scale = 1.0 + (value * maxScale);
    final opacity = 1.0 - value;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF3B6A).withValues(alpha: opacity * 0.75),
            width: 1.6,
          ),
        ),
      ),
    );
  }
}
