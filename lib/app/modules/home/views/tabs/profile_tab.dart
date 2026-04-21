import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:igames/app/data/services/userServices.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/views/language_selector_view.dart';
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
    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.darkBackgroundGradient),
      child: SafeArea(
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
            ),
            const SizedBox(height: 12),
            _ProfileActions(auth: auth, controller: controller),
            const SizedBox(height: 12),
            _PromoTile(
              title: 'promoCenter'.tr,
              actionText: 'getBenefits'.tr,
              onTap: () => controller.currentTab.value = 1,
            ),
            const SizedBox(height: 8),
            _SettingsGroup(
              items: [
                _SettingsItem(
                  label: 'betRecord'.tr,
                  icon: Icons.history,
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
                _SettingsItem(
                  label: 'accountSecurity'.tr,
                  icon: Icons.shield_moon_outlined,
                  onTap: () async {
                    final ok = await auth.ensureAuthenticated(context);
                    if (ok) {
                      Get.toNamed(Routes.ACCOUNT_SECURITY);
                    }
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'accountSecurityReward'.tr,
                        style: const TextStyle(
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white70),
                    ],
                  ),
                ),
                _SettingsItem(
                  label: 'helpCenter'.tr,
                  icon: Icons.help_outline,
                  onTap: () => auth.openCustomerService(),
                ),
                _SettingsItem(
                  label: 'language'.tr,
                  icon: Icons.language,
                  onTap: () {
                    final languageController =
                        Get.isRegistered<LanguageSelectorController>()
                            ? Get.find<LanguageSelectorController>()
                            : Get.put(LanguageSelectorController());
                    languageController.openLanguageMenu(
                      fallbackContext: context,
                    );
                  },
                  trailing: IgnorePointer(
                    child: LanguageSelectorView(compact: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LogoutButton(auth: auth),
          ],
        ),
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
      required this.hasFetchedBalance});

  final AuthController auth;
  final RxString balance;
  final Future<void> Function() onRefreshBalance;
  final RxBool isRefreshingBalance;
  final RxBool hasFetchedBalance;

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

          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1A2E),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfileAvatar(avatarUrl: avatarUrl),
                    const SizedBox(width: 12),
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
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _CopyNameButton(text: displayName),
                                  ],
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: _ProfileLoginButton(
                                onTap: () => auth.openLoginOverlay(context),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    _CircleIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => Get.toNamed(Routes.SETTINGS),
                    ),
                    const SizedBox(width: 8),
                    const _NotificationCircleButton(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _WalletBalancePill(
                        loggedIn: loggedIn,
                        balanceText: balanceText,
                        isRefreshing: refreshing,
                        onRefresh: loggedIn ? () => onRefreshBalance() : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RecordButton(
                      onTap: () async {
                        final ok = await auth.ensureAuthenticated(context);
                        if (!ok) return;
                        Get.toNamed(Routes.TRANSACTION_HISTORY);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl});

  final String avatarUrl;

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
          width: 48,
          height: 48,
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
  const _ProfileLoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A5CFF), Color(0xFF5E63FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A5CFF).withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          'loginRegister'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }
}

class _NotificationCircleButton extends StatefulWidget {
  const _NotificationCircleButton();

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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_outlined,
              color: Colors.white70,
              size: 18,
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
      this.onRefresh});

  final bool loggedIn;
  final String balanceText;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 72, 41, 159),
            Color.fromARGB(193, 24, 20, 50)
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              AppConfig.currencySymbol(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              loggedIn ? balanceText : '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 6),
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
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: disabled ? 0.55 : 1,
      child: _RefreshIconButton(
        isRefreshing: isRefreshing,
        disabled: disabled,
        onTap: onTap,
      ),
    );
  }
}

class _RefreshIconButton extends StatefulWidget {
  const _RefreshIconButton(
      {required this.isRefreshing,
      required this.disabled,
      required this.onTap});

  final bool isRefreshing;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  State<_RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<_RefreshIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.isRefreshing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _RefreshIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isRefreshing && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.disabled ? null : widget.onTap,
      child: Center(
        child: RotationTransition(
          turns: _controller,
          child: const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white70,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'transactionHistory'.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
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
        label: 'deposit'.tr,
        icon: Icons.download_rounded,
        onTap: () async {
          final ok = await auth.ensureAuthenticated(context);
          if (ok) controller.currentTab.value = 2;
        },
      ),
      _WalletAction(
        label: 'withdraw'.tr,
        icon: Icons.upload_rounded,
        onTap: () async {
          final ok = await auth.ensureAuthenticated(context);
          if (ok) {
            Get.toNamed(Routes.WITHDRAW);
          }
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: actions.asMap().entries.expand((entry) {
          final idx = entry.key;
          final action = entry.value;
          return [
            Expanded(
              child: _ActionButton(
                label: action.label,
                icon: action.icon,
                onTap: action.onTap,
                highlight: action.highlight,
                badgeText: action.badge,
              ),
            ),
            if (idx != actions.length - 1) const SizedBox(width: 8),
          ];
        }).toList(),
      ),
    );
  }
}

class _WalletAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;
  final String? badge;

  const _WalletAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlight = false,
    this.badge,
  });
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.highlight = false,
      this.badgeText});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final gradient = highlight
        ? const LinearGradient(
            colors: [Color(0xFF3B1F9D), Color(0xFF7A4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFF5B4ADA), Color(0xFF7A55FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (badgeText != null && badgeText!.isNotEmpty)
              Positioned(
                right: -2,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1524C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile(
      {required this.title, required this.actionText, required this.onTap});

  final String title;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8A6CFF),
                ),
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});

  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: items
            .map((item) => Column(
                  children: [
                    ListTile(
                      leading: Icon(item.icon,
                          color: Colors.white.withValues(alpha: 0.9)),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: item.trailing ??
                          const Icon(Icons.chevron_right,
                              color: Colors.white70),
                      onTap: item.onTap,
                    ),
                    if (item != items.last)
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _SettingsItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  const _SettingsItem(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.trailing});
}

class _LanguageSelectorTile extends StatelessWidget {
  const _LanguageSelectorTile();

  void _openLanguageMenu(BuildContext context) {
    final languageController = Get.isRegistered<LanguageSelectorController>()
        ? Get.find<LanguageSelectorController>()
        : Get.put(LanguageSelectorController());
    languageController.openLanguageMenu(
      fallbackContext: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openLanguageMenu(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(Icons.language, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'language'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IgnorePointer(
              child: LanguageSelectorView(compact: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    // 使用 Obx 监听登录状态，只有登录时才显示注销按钮
    return Obx(() {
      if (!auth.isLoggedIn.value) {
        return const SizedBox.shrink(); // 未登录时返回空组件
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB5757),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0),
            onPressed: () => auth.logout(),
            child: Text(
              'logout'.tr,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    });
  }
}
