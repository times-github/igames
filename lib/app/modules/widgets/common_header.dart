import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/views/language_selector_view.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);
        final menuImageSize = r.size(44);
        final menuPadding = r.size(2);
        final iconBoxSize = menuImageSize + menuPadding;
        final sideGap = r.size(6);
        final unauthHeaderScale =
            !loggedIn ? ((r.width / 520) > 1 ? 1.0 : (r.width / 520)) : 1.0;
        final compactActionScale = r.width < 360 ? r.scale : 1.0;
        final actionScale = compactActionScale < unauthHeaderScale
            ? compactActionScale
            : unauthHeaderScale;
        final logoHeight = r.size(loggedIn ? 48 : 36) * unauthHeaderScale;
        final logoWidth = r.size(loggedIn ? 140 : 148) * unauthHeaderScale;

        return Container(
          color: AppConfig.webDesktopOuterBackground,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (loggedIn && showMenu) ...[
                      SizedBox(
                        width: iconBoxSize,
                        height: iconBoxSize,
                        child: InkWell(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Padding(
                            padding: EdgeInsets.all(menuPadding),
                            child: Image.asset(
                              'assets/images/menu.png',
                              width: menuImageSize,
                              height: menuImageSize,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.low,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.size(2)),
                    ],
                    SizedBox(
                      height: logoHeight,
                      width: logoWidth,
                      child: Obx(() {
                        return AppBrandLogo(
                          logo: appInfo.appLogo.value,
                          borderRadius: BorderRadius.zero,
                          width: logoWidth,
                          height: logoHeight,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(
                            horizontal: r.size(2),
                            vertical: r.size(1),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(width: r.size(6)),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!loggedIn) ...[
                          LanguageSelectorView(
                            scale: actionScale,
                          ),
                          SizedBox(width: r.size(4)),
                          PulsingLoginButton(
                            onTap: auth.openLoginOverlay,
                            scale: actionScale,
                            dense: r.width < 330,
                          ),
                        ] else if (showNotification) ...[
                          NotificationButton(
                            size: iconBoxSize,
                            iconSize: r.size(35),
                          ),
                        ],
                        SizedBox(width: sideGap),
                        CustomerServiceButton(
                          onTap: auth.openCustomerService,
                          size: iconBoxSize * actionScale,
                          iconSize: r.size(35) * actionScale,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  });
}

/// 登录按钮
class PulsingLoginButton extends StatelessWidget {
  const PulsingLoginButton({
    required this.onTap,
    super.key,
    this.scale = 1,
    this.dense = false,
  });

  final VoidCallback onTap;
  final double scale;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final widthScale = scale;
    final horizontalPadding = (dense ? 7 : 8) * widthScale;
    final verticalPadding = (dense ? 6 : 7) * widthScale;
    final fontSize = (dense ? 12.5 : 13) * widthScale;
    final radius = 18 * widthScale;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 16, 82, 77),
              Color.fromARGB(255, 45, 218, 206)
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6 * widthScale,
              offset: Offset(0, 3 * widthScale),
            ),
          ],
        ),
        child: Text(
          'loginRegister'.tr,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: dense ? 0.15 : 0.5,
          ),
        ),
      ),
    );
  }
}

/// 客服按钮
class CustomerServiceButton extends StatelessWidget {
  const CustomerServiceButton({
    required this.onTap,
    super.key,
    this.size = 36,
    this.iconSize = 24,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: InkWell(
        onTap: onTap,
        // borderRadius: BorderRadius.circular(size * 0.35),
        child: Ink(
          child: Center(
            child: Image.asset(
              'assets/images/customer.png',
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
            ),
          ),
        ),
      ),
    );
  }
}

/// 通知按钮
class NotificationButton extends StatefulWidget {
  const NotificationButton({
    super.key,
    this.size = 36,
    this.iconSize = 24,
  });

  final double size;
  final double iconSize;

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: InkWell(
        onTap: () => Get.toNamed(Routes.MESSAGE),
        borderRadius: BorderRadius.circular(widget.size * 0.3),
        child: Center(
          child: Stack(
            clipBehavior: Clip.none, //不裁剪
            children: [
              Image.asset(
                'assets/images/inbox.png',
                width: widget.iconSize,
                height: widget.iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
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
