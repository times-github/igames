import 'dart:math' as math;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/app/modules/userProfile/controllers/user_profile_controller.dart';
import 'package:igames/app/modules/userProfile/views/game_history_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.auth,
    required this.controller,
  });

  final AuthController auth;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = 20.0;
    final showAppUpdateItem =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final languageController = Get.isRegistered<LanguageSelectorController>()
        ? Get.find<LanguageSelectorController>()
        : Get.put(LanguageSelectorController());
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          3,
          12,
          3,
          1 + bottomNavHeight + bottomInset,
        ),
        children: [
          _ProfileCard(
            auth: auth,
            balance: controller.balance,
            onRefreshBalance: controller.refreshBalance,
            isRefreshingBalance: controller.isRefreshingBalance,
            hasFetchedBalance: controller.hasFetchedBalance,
            onBalanceActionTap: () {
              auth.ensureAuthenticated(context).then((ok) {
                if (ok) {
                  controller.currentTab.value = 2;
                }
              });
            },
          ),
          const SizedBox(height: 12),
          _ProfileActions(auth: auth, controller: controller),
          const SizedBox(height: 12),
          _PromoTile(
            title: 'promoCenter'.tr,
            actionText: 'getBenefits'.tr,
            onTap: () => controller.currentTab.value = 1,
          ),
          const SizedBox(height: 12),
          _ProfileMenuPanel(
            auth: auth,
            languageController: languageController,
            items: [
              _ProfileMenuItem(
                label: 'betRecord'.tr,
                iconAsset: 'assets/images/me/games.png',
                onTap: () async {
                  final ok = await auth.ensureAuthenticated(context);
                  if (ok) {
                    final userProfile =
                        Get.isRegistered<UserProfileController>()
                            ? Get.find<UserProfileController>()
                            : Get.put(UserProfileController());
                    userProfile.switchPageByIndex(2);
                    userProfile.selectedDrawerTab.value = 3;
                    Get.to(() => const GameHistoryPage());
                  }
                },
              ),
              _ProfileMenuItem(
                label: 'accountSecurity'.tr,
                iconAsset: 'assets/images/me/edit.png',
                onTap: () async {
                  final ok = await auth.ensureAuthenticated(context);
                  if (ok) {
                    Get.toNamed(Routes.ACCOUNT_SECURITY);
                  }
                },
                subtitle: 'accountSecurityReward'.tr,
              ),
              _ProfileMenuItem(
                label: 'helpCenter'.tr,
                iconAsset: 'assets/images/me/customer.png',
                onTap: () => auth.openCustomerService(),
              ),
              _ProfileMenuItem(
                label: 'language'.tr,
                iconAsset: 'assets/images/me/language.png',
                onTap: () {
                  languageController.openLanguageMenu(
                    fallbackContext: context,
                  );
                },
                trailing: Obx(
                  () => Text(
                    languageController.currentLanguage.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (showAppUpdateItem)
                _ProfileMenuItem(
                  label: 'appUpdate'.tr,
                  iconData: Icons.system_update_alt_rounded,
                  onTap: auth.openDownloadUrl,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(
      {required this.auth,
      required this.balance,
      required this.onRefreshBalance,
      required this.isRefreshingBalance,
      required this.hasFetchedBalance,
      required this.onBalanceActionTap});

  final AuthController auth;
  final RxString balance;
  final Future<void> Function() onRefreshBalance;
  final RxBool isRefreshingBalance;
  final RxBool hasFetchedBalance;
  final VoidCallback onBalanceActionTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loggedIn = auth.isLoggedIn.value;
      final balanceText = balance.value;
      final refreshing = isRefreshingBalance.value;
      final fetchedOnce = hasFetchedBalance.value;
      if (loggedIn && !refreshing && !fetchedOnce) {
        Future.microtask(onRefreshBalance);
      }
      return FutureBuilder<Map<String, dynamic>>(
        future: UserServices.getUserInfo(),
        builder: (context, snapshot) {
          final userInfo = snapshot.data ?? {};
          final nickname = (userInfo['nickname'] ?? '').toString().trim();
          final account = (userInfo['account'] ?? '').toString().trim();
          final displayName = loggedIn
              ? (nickname.isNotEmpty
                  ? nickname
                  : (account.isNotEmpty ? account : 'loggedInUser'.tr))
              : '-';
          final avatarUrl = (userInfo['avatar'] ?? '').toString();

          return LayoutBuilder(
            builder: (context, constraints) {
              final r = Responsive.fromConstraints(constraints, context);

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: r.size(8),
                  vertical: r.size(8),
                ),
                decoration: BoxDecoration(
                  color: AppConfig.webDesktopOuterBackground,
                  borderRadius: BorderRadius.circular(r.size(18)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: r.size(16),
                      offset: Offset(0, r.size(10)),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _ProfileAvatar(
                          avatarUrl: avatarUrl,
                          size: r.size(48),
                        ),
                        SizedBox(width: r.size(12)),
                        Expanded(
                          child: loggedIn
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: AppColors.textPrimary,
                                                  fontSize: r.font(16),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                        SizedBox(width: r.size(6)),
                                        _CopyNameButton(text: displayName),
                                      ],
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: _ProfileLoginButton(
                                    onTap: auth.openLoginOverlay,
                                    scale: r.scale,
                                  ),
                                ),
                        ),
                        SizedBox(width: r.size(8)),
                        _CircleIconButton(
                          assetPath: 'assets/images/me/edit.png',
                          onTap: () => Get.toNamed(Routes.ABOUT),
                          padding: r.size(10),
                          iconSize: r.size(21),
                        ),
                        SizedBox(width: r.size(8)),
                        _NotificationCircleButton(
                          padding: r.size(10),
                          iconSize: r.size(38),
                        ),
                      ],
                    ),
                    SizedBox(height: r.size(14)),
                    _WalletBalancePill(
                      loggedIn: loggedIn,
                      balanceText: balanceText,
                      isRefreshing: refreshing,
                      onRefresh: loggedIn ? onBalanceActionTap : null,
                      scale: r.scale,
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    this.size = 48,
  });

  final String avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveAvatarUrl(avatarUrl);
    final hasAvatar = resolvedUrl != null;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
        ),
      ),
      child: ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: hasAvatar
              ? CompatibleImage.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Image.asset('assets/images/avator.png'),
                )
              : Image.asset(
                  'assets/images/avator.png',
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  String? _resolveAvatarUrl(String raw) {
    if (raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return '${AppConfig.apiBaseUrl}/$trimmed';
  }
}

class _ProfileLoginButton extends StatelessWidget {
  const _ProfileLoginButton({
    required this.onTap,
    this.scale = 1,
  });

  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final widthScale = scale;
    final horizontalPadding = 14 * widthScale;
    final verticalPadding = 8 * widthScale;
    final fontSize = 14 * widthScale;
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
              Color.fromARGB(255, 45, 218, 206),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    this.assetPath,
    required this.onTap,
    this.padding = 10,
    this.iconSize = 21,
  });

  final String? assetPath;
  final VoidCallback onTap;
  final double padding;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Image.asset(
          assetPath!,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _NotificationCircleButton extends StatefulWidget {
  const _NotificationCircleButton({
    this.padding = 10,
    this.iconSize = 21,
  });

  final double padding;
  final double iconSize;

  @override
  State<_NotificationCircleButton> createState() =>
      _NotificationCircleButtonState();
}

class _NotificationCircleButtonState extends State<_NotificationCircleButton> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(Routes.MESSAGE),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: EdgeInsets.all(widget.padding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              'assets/images/inbox.png',
              width: widget.iconSize,
              height: widget.iconSize,
              fit: BoxFit.contain,
            ),
            Obx(() {
              final auth = Get.find<AuthController>();
              if (!auth.isLoggedIn.value) return const SizedBox.shrink();
              final count = Get.isRegistered<AnnouncementService>()
                  ? Get.find<AnnouncementService>().totalUnreadCount.value
                  : 0;
              if (count <= 0) return const SizedBox.shrink();
              return const Positioned(
                top: -6,
                right: -6,
                child: _MiniPulsingDot(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MiniPulsingDot extends StatefulWidget {
  const _MiniPulsingDot();

  @override
  State<_MiniPulsingDot> createState() => _MiniPulsingDotState();
}

class _MiniPulsingDotState extends State<_MiniPulsingDot>
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
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
          final dotScale = 0.9 + pulse * 0.25;
          final dotOpacity = 0.6 + pulse * 0.4;
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRipple(0.0, 0.6),
              _buildRipple(0.3, 0.6),
              _buildRipple(0.6, 0.6),
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
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF3B6A).withValues(alpha: opacity * 0.6),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CopyNameButton extends StatelessWidget {
  const _CopyNameButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final canCopy = text.isNotEmpty;
    return GestureDetector(
      onTap: canCopy
          ? () async {
              await Clipboard.setData(ClipboardData(text: text));
              Get.snackbar('tip'.tr, 'copied'.tr);
            }
          : null,
      child: Icon(
        Icons.copy_rounded,
        color: canCopy ? Colors.white70 : Colors.white38,
        size: 16,
      ),
    );
  }
}

class _WalletBalancePill extends StatelessWidget {
  const _WalletBalancePill(
      {required this.loggedIn,
      required this.balanceText,
      required this.isRefreshing,
      this.onRefresh,
      this.scale = 1});

  final bool loggedIn;
  final String balanceText;
  final bool isRefreshing;
  final VoidCallback? onRefresh;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final widthScale = scale;
    final displayedBalance = loggedIn ? _formatBalanceAsK(balanceText) : '-';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (7 * widthScale).clamp(5, 7).toDouble(),
        vertical: (3 * widthScale).clamp(2.5, 3).toDouble(),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF14383C),
        border: Border.all(
          color: const Color(0xFF22D8DF),
          width: 1.4,
        ),
        borderRadius:
            BorderRadius.circular((24 * widthScale).clamp(18, 24).toDouble()),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/me/idr.png',
            width: (26 * widthScale).clamp(20, 26).toDouble(),
            height: (26 * widthScale).clamp(20, 26).toDouble(),
            fit: BoxFit.contain,
          ),
          SizedBox(width: (6 * widthScale).clamp(4, 6).toDouble()),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              displayedBalance,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFFF133),
                    fontSize: (15 * widthScale).clamp(11.5, 15).toDouble(),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(width: (3 * widthScale).clamp(1.5, 3).toDouble()),
          _RefreshBalanceButton(
            isRefreshing: isRefreshing,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _RefreshBalanceButton extends StatelessWidget {
  const _RefreshBalanceButton(
      {required this.isRefreshing, required this.onTap});

  final bool isRefreshing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.55 : (isRefreshing ? 0.88 : 1),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Image.asset(
          'assets/images/me/add.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({required this.auth, required this.controller});

  final AuthController auth;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _WalletAction(
        label: 'withdraw'.tr,
        iconAsset: 'assets/images/me/withdraw.png',
        backgroundAsset: AppConfig.btnDefaultBackgroundAsset,
        textColor: AppConfig.btnDefaultTextColor,
        borderColor: AppConfig.btnSelectedBorderColor,
        borderWidth: 2,
        borderRadius: 14,
        onTap: () async {
          final ok = await auth.ensureAuthenticated(context);
          if (ok) {
            Get.toNamed(Routes.WITHDRAW);
          }
        },
      ),
      _WalletAction(
        label: 'deposit'.tr,
        iconAsset: 'assets/images/me/desposit.png',
        backgroundAsset: AppConfig.btnSelectedBackgroundAsset,
        textColor: AppConfig.btnSelectedTextColor,
        borderColor: AppConfig.btn2SelectedBorderColor,
        borderWidth: 2.2,
        borderRadius: 14,
        onTap: () async {
          final ok = await auth.ensureAuthenticated(context);
          if (ok) controller.currentTab.value = 2;
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);

        return Row(
          children: actions.asMap().entries.expand((entry) {
            final idx = entry.key;
            final action = entry.value;
            return [
              Expanded(
                child: _ActionButton(
                  label: action.label,
                  iconAsset: action.iconAsset,
                  backgroundAsset: action.backgroundAsset,
                  textColor: action.textColor,
                  borderColor: action.borderColor,
                  borderWidth: action.borderWidth,
                  borderRadius: action.borderRadius,
                  scale: r.scale,
                  onTap: action.onTap,
                ),
              ),
              if (idx != actions.length - 1) SizedBox(width: r.size(12)),
            ];
          }).toList(),
        );
      },
    );
  }
}

class _WalletAction {
  final String label;
  final String iconAsset;
  final String backgroundAsset;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback onTap;

  const _WalletAction({
    required this.label,
    required this.iconAsset,
    required this.backgroundAsset,
    required this.textColor,
    required this.onTap,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 18,
  });
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.iconAsset,
    required this.backgroundAsset,
    required this.textColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 18,
    required this.onTap,
    this.scale = 1,
  });

  final String label;
  final String iconAsset;
  final String backgroundAsset;
  final Color textColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final widthScale = scale;
    final height = (54 * widthScale).clamp(42, 54).toDouble();
    final iconSize = (30 * widthScale).clamp(22, 30).toDouble();
    final fontSize = (16 * widthScale).clamp(12, 16).toDouble();
    final resolvedRadius = (borderRadius * widthScale).clamp(12, 18).toDouble();
    final resolvedBorderWidth = borderColor == null
        ? 0.0
        : (borderWidth * widthScale).clamp(1.0, 2.8).toDouble();

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(backgroundAsset),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(resolvedRadius),
            border: borderColor == null
                ? null
                : Border.all(
                    color: borderColor!,
                    width: resolvedBorderWidth,
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: (20 * widthScale).clamp(14, 20).toDouble(),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  iconAsset,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: (10 * widthScale).clamp(7, 10).toDouble()),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatBalanceAsK(String raw) {
  final normalized = raw.replaceAll(',', '').replaceAll(' ', '');
  final value = double.tryParse(normalized);
  if (value == null) return raw;
  final scaled = value / 1000;
  return '${scaled.toStringAsFixed(2)} K';
}

class _PromoTile extends StatelessWidget {
  const _PromoTile(
      {required this.title, required this.actionText, required this.onTap});

  final String title;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);
        final stackAction = r.width < 300;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(r.size(16)),
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.size(14),
                vertical: r.size(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(r.size(16)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: stackAction
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              color: Colors.white70,
                              size: r.size(24),
                            ),
                            SizedBox(width: r.size(10)),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: r.font(15),
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: r.size(8)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: onTap,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8A6CFF),
                              padding: EdgeInsets.symmetric(
                                horizontal: r.size(8),
                                vertical: r.size(4),
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              actionText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: r.font(13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.white70,
                          size: r.size(24),
                        ),
                        SizedBox(width: r.size(10)),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: r.font(15),
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF8A6CFF),
                            padding: EdgeInsets.symmetric(
                              horizontal: r.size(8),
                              vertical: r.size(4),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            actionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: r.font(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileMenuPanel extends StatelessWidget {
  const _ProfileMenuPanel({
    required this.auth,
    required this.languageController,
    required this.items,
  });

  final AuthController auth;
  final LanguageSelectorController languageController;
  final List<_ProfileMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);
        return Obx(() {
          final showLogout = auth.isLoggedIn.value;
          final borderRadius = BorderRadius.circular(14);
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: Color.fromARGB(168, 17, 157, 159),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(168, 17, 157, 159)
                      .withValues(alpha: 0.10),
                  const Color.fromARGB(0, 255, 255, 255)
                      .withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                    left: r.size(-200),
                    top: r.size(-208),
                    child: IgnorePointer(
                      child: Container(
                        width: r.size(400),
                        height: r.size(400),
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Color.fromARGB(191, 41, 253, 239),
                              Color.fromARGB(0, 69, 255, 240),
                            ],
                          ),
                        ),
                      ),
                    )),
                Positioned(
                  left: r.size(110),
                  right: r.size(110),
                  bottom: r.size(-35),
                  child: IgnorePointer(
                    child: Container(
                      height: r.size(44),
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(191, 41, 253, 239),
                            blurRadius: r.size(50),
                            spreadRadius: r.size(0.1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Column(
                      children: items.asMap().entries.map((entry) {
                        final item = entry.value;
                        final isLast = entry.key == items.length - 1;
                        return Column(
                          children: [
                            _ProfileMenuRow(
                              item: item,
                              scale: r.scale,
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: r.size(18),
                                endIndent: r.size(18),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                    if (showLogout)
                      Divider(
                        height: 1,
                        indent: r.size(18),
                        endIndent: r.size(18),
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    if (showLogout)
                      _ProfileMenuRow(
                        item: _ProfileMenuItem(
                          label: 'logout'.tr,
                          iconAsset: 'assets/images/me/logout.png',
                          onTap: auth.logout,
                        ),
                        scale: r.scale,
                      ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.item,
    required this.scale,
  });

  final _ProfileMenuItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final horizontal = (16 * scale).clamp(14, 18).toDouble();
    final vertical = (14 * scale).clamp(13, 17).toDouble();
    final iconBox = (26 * scale).clamp(22, 26).toDouble();
    final iconSize = (24 * scale).clamp(20, 24).toDouble();
    final arrowSize = (28 * scale).clamp(13, 16).toDouble();
    final titleSize = (19 * scale).clamp(12.5, 15).toDouble();
    final subtitleSize = (15 * scale).clamp(10, 12).toDouble();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: Row(
            children: [
              SizedBox(
                width: iconBox,
                height: iconBox,
                child: item.iconAsset != null
                    ? Image.asset(
                        item.iconAsset!,
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        item.iconData,
                        // color: const Color(0xFF79FFF0),
                        size: iconSize,
                      ),
              ),
              SizedBox(width: (16 * scale).clamp(12, 16).toDouble()),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: titleSize,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            SizedBox(
                              height: (4 * scale).clamp(2, 4).toDouble(),
                            ),
                            Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 239, 53, 47),
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (item.trailing != null) ...[
                      SizedBox(width: (10 * scale).clamp(8, 10).toDouble()),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: (132 * scale).clamp(82, 132).toDouble(),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: item.trailing!,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: (14 * scale).clamp(10, 14).toDouble()),
              Image.asset(
                'assets/images/me/into.png',
                width: arrowSize,
                height: arrowSize,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.label,
    required this.onTap,
    this.iconAsset,
    this.iconData,
    this.trailing,
    this.subtitle,
  });

  final String label;
  final VoidCallback onTap;
  final String? iconAsset;
  final IconData? iconData;
  final Widget? trailing;
  final String? subtitle;
}
