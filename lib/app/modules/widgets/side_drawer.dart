import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/jackpot.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/jackpot_scroller.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/modules/widgets/language_selector/views/language_selector_view.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final appInfo = Get.find<AppInfoService>();
    final homeController =
        Get.isRegistered<HomeController>() ? Get.find<HomeController>() : null;

    return Drawer(
      backgroundColor: const Color(0xFF0E1621),
      child: SafeArea(
        child: Column(
          children: [
            // 顶部区域：Logo + 金额 + 充值按钮 + 关闭按钮
            _DrawerHeader(
              auth: auth,
              appInfo: appInfo,
              homeController: homeController,
            ),
            const SizedBox(height: 12),
            // 菜单项
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.favorite_border,
                    label: 'myFavorites'.tr,
                    onTap: () async {
                      final ok = await auth.ensureAuthenticated(context);
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        Future.microtask(() {
                          Get.toNamed(Routes.FAVORITES);
                        });
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.history,
                    label: 'recentlyPlayed'.tr,
                    onTap: () async {
                      final ok = await auth.ensureAuthenticated(context);
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.pop(context);
                        Future.microtask(() {
                          Get.toNamed(Routes.RECENTLY_PLAYED);
                        });
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.local_activity_outlined,
                    label: 'promo'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      if (homeController != null) {
                        homeController.currentTab.value = 1;
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.support_agent_rounded,
                    label: 'helpCenter'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      auth.openCustomerService();
                    },
                  ),
                  _DrawerLanguageItem(),
                  const SizedBox(height: 20),
                  // 实时爆奖标题
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFD700),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'jackpotWinners'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 实时爆奖列表
                  const _JackpotList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.auth,
    required this.appInfo,
    required this.homeController,
  });

  final AuthController auth;
  final AppInfoService appInfo;
  final HomeController? homeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D2E), Color(0xFF2A2D3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Logo
              Obx(() {
                return SizedBox(
                  width: 50,
                  height: 50,
                  child: AppBrandLogo(
                    logo: appInfo.appLogo.value,
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
              const SizedBox(width: 8),
              // 网站名称
              Obx(() {
                final name = appInfo.appName.value;
                return Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1.1,
                  ),
                );
              }),
              const Spacer(),
              // 关闭按钮
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white70),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 金额和充值按钮
          Obx(() {
            final loggedIn = auth.isLoggedIn.value;
            if (!loggedIn) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  auth.openLoginOverlay(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A6CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('loginRegister'.tr),
              );
            }

            final balance = homeController?.balance.value ?? '0';
            final isRefreshing =
                homeController?.isRefreshingBalance.value ?? false;
            return Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222732),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppConfig.currencySymbol(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        balance,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => homeController?.refreshBalance(),
                        child: AnimatedRotation(
                          turns: isRefreshing ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Color(0xFFF1A64C),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    homeController?.currentTab.value = 2;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8A6CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('recharge'.tr),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF8A6CFF),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLanguageItem extends StatelessWidget {
  const _DrawerLanguageItem();

  void _openLanguageMenu(BuildContext context) {
    final languageController = Get.isRegistered<LanguageSelectorController>()
        ? Get.find<LanguageSelectorController>()
        : Get.put(LanguageSelectorController());
    Navigator.of(context).pop();
    languageController.openLanguageMenu(
      fallbackContext: Get.context,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openLanguageMenu(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.language,
              color: Color(0xFF8A6CFF),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'language'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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

class _JackpotList extends StatefulWidget {
  const _JackpotList();

  @override
  State<_JackpotList> createState() => _JackpotListState();
}

class _JackpotListState extends State<_JackpotList> {
  static const int _visibleCount = 4;
  static const double _itemHeight = 64;
  static const double _gap = 8;
  final Duration _stayDuration = const Duration(seconds: 4);
  final Duration _slideDuration = const Duration(milliseconds: 520);
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  Timer? _activeTimer;
  int _currentIndex = 0;
  int _activeSlotIndex = -1;
  int _lastLength = 0;
  bool _didInitActive = false;

  double get _itemExtent => _itemHeight + _gap;

  @override
  void dispose() {
    _timer?.cancel();
    _activeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _restartTicker(int length) {
    _timer?.cancel();
    _activeTimer?.cancel();
    _currentIndex = 0;
    _activeSlotIndex = -1;
    _didInitActive = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
    if (length > 1) {
      _timer = Timer.periodic(_stayDuration, (_) => _advance(length));
    }
    setState(() {});
  }

  void _advance(int length) {
    if (length <= 1 || !_scrollController.hasClients) return;
    final nextIndex = _currentIndex + 1;
    _currentIndex = nextIndex;

    _scrollController
        .animateTo(
      nextIndex * _itemExtent,
      duration: _slideDuration,
      curve: Curves.easeOutCubic,
    )
        .then((_) {
      if (!mounted) return;
      if (_currentIndex >= length) {
        _currentIndex = 0;
        _scrollController.jumpTo(0);
        _activeTimer?.cancel();
        _activeTimer = Timer(const Duration(milliseconds: 40), () {
          if (!mounted) return;
          setState(() {
            _activeSlotIndex = _visibleCount - 1;
          });
        });
      }
    });

    final newSlotIndex = nextIndex + _visibleCount - 1;
    _activeTimer?.cancel();
    _activeTimer = Timer(_slideDuration + const Duration(milliseconds: 60), () {
      if (!mounted) return;
      setState(() {
        _activeSlotIndex = newSlotIndex;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<JackpotService>()) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final service = Get.find<JackpotService>();
      final records = service.jackpotList;
      final length = records.length;

      if (length == 0) {
        return const SizedBox.shrink();
      }

      if (_lastLength != length) {
        _lastLength = length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _restartTicker(length);
        });
      }

      if (!_didInitActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _activeSlotIndex = _visibleCount - 1;
            _didInitActive = true;
          });
        });
      }

      final listCount = length + _visibleCount;
      final height = _itemExtent * _visibleCount - _gap;

      return SizedBox(
        height: height,
        child: ListView.builder(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listCount,
          itemBuilder: (context, index) {
            final sourceIndex = index % length;
            final record = records[sourceIndex];
            final isActive = index == _activeSlotIndex;
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == listCount - 1 ? 0 : _gap),
              child: SizedBox(
                height: _itemHeight,
                child: _SidebarJackpotCard(
                  key: ValueKey(
                    'side_${record.eventTime}_${record.account}_${record.gamecode}_$index',
                  ),
                  record: record,
                  isActive: isActive,
                  onTap: () => _handleJackpotTap(
                    context,
                    records,
                    record,
                    sourceIndex,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _handleJackpotTap(
    BuildContext context,
    List<JackpotRecord> records,
    JackpotRecord record,
    int index,
  ) {
    final hostContext = Get.context ?? context;
    showJackpotDetailSheet(
      context: hostContext,
      parentContext: hostContext,
      record: record,
      records: records,
      index: index,
    );
  }
}

class _SidebarJackpotCard extends StatefulWidget {
  const _SidebarJackpotCard({
    super.key,
    required this.record,
    required this.isActive,
    this.onTap,
  });

  final JackpotRecord record;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  State<_SidebarJackpotCard> createState() => _SidebarJackpotCardState();
}

class _SidebarJackpotCardState extends State<_SidebarJackpotCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _valueAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  bool _showRate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showRate = true;
        });
      }
    });
    _configureAnimations();
    if (widget.isActive) {
      _playAnimation();
    } else {
      _controller.value = 1;
      _showRate = true;
    }
  }

  @override
  void didUpdateWidget(covariant _SidebarJackpotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final amountChanged = oldWidget.record.winAmount != widget.record.winAmount;
    final multiplierChanged =
        oldWidget.record.multiplier != widget.record.multiplier;
    final betChanged = oldWidget.record.betAmount != widget.record.betAmount;
    final dataChanged = amountChanged || multiplierChanged || betChanged;

    if (dataChanged) {
      _configureAnimations();
    }

    if (widget.isActive && (!oldWidget.isActive || dataChanged)) {
      _showRate = false;
      _playAnimation();
      return;
    }

    if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 1;
      _showRate = true;
    }
  }

  void _configureAnimations() {
    final amount = (widget.record.winAmount ?? 0).toDouble();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _valueAnimation = Tween<double>(begin: 0, end: amount).animate(curve);
    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFF1B5),
      end: const Color(0xFFFFC24B),
    ).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _playAnimation() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _firstNonEmptyText(
      widget.record.gameName,
      widget.record.gamehall,
      widget.record.gamecode,
    );
    final account = _maskAccountText(widget.record.account);
    final rateText = _rateText();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: const Color(0xFFFFC24B).withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2F3B), Color(0xFF1B1F2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isActive
                  ? const Color(0xFFFFC862).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  _SidebarGameIcon(url: widget.record.iconUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title.isEmpty ? '--' : title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.isEmpty ? '--' : account,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SidebarAmountText(
                    controller: _controller,
                    valueAnimation: _valueAnimation,
                    colorAnimation: _colorAnimation,
                    scaleAnimation: _scaleAnimation,
                    isActive: widget.isActive,
                  ),
                ],
              ),
              if (rateText.isNotEmpty)
                Positioned(
                  top: -6,
                  right: -2,
                  child: _SidebarRateBadge(
                    text: rateText,
                    show: _showRate,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _rateText() {
    final raw = widget.record.multiplier?.toDouble();
    if (raw != null && raw > 0) return 'x${raw.toStringAsFixed(1)}';
    final bet = widget.record.betAmount?.toDouble() ?? 0;
    final win = widget.record.winAmount?.toDouble() ?? 0;
    if (bet <= 0 || win <= 0) return '';
    return 'x${(win / bet).toStringAsFixed(1)}';
  }
}

class _SidebarGameIcon extends StatelessWidget {
  const _SidebarGameIcon({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveGameIconUrl(url);
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD36E), Color(0xFFFF7A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA933).withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: resolved != null && resolved.isNotEmpty
            ? Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _iconFallback(),
              )
            : _iconFallback(),
      ),
    );
  }

  Widget _iconFallback() {
    if (!Get.isRegistered<AppInfoService>()) {
      return _iconPlaceholder();
    }
    final appInfo = Get.find<AppInfoService>();
    return Obx(() {
      final logo = appInfo.appLogo.value;
      return AppBrandLogo(
        logo: logo,
        showBackground: false,
        padding: const EdgeInsets.all(3),
        placeholder: _iconPlaceholder(),
      );
    });
  }

  Widget _iconPlaceholder() {
    return Container(
      color: const Color(0xFF2C3240),
      child: Icon(
        Icons.casino,
        color: Colors.white.withValues(alpha: 0.9),
        size: 24,
      ),
    );
  }
}

class _SidebarAmountText extends StatelessWidget {
  const _SidebarAmountText({
    required this.controller,
    required this.valueAnimation,
    required this.colorAnimation,
    required this.scaleAnimation,
    required this.isActive,
  });

  final AnimationController controller;
  final Animation<double> valueAnimation;
  final Animation<Color?> colorAnimation;
  final Animation<double> scaleAnimation;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final amountValue = valueAnimation.value;
        final amountColor = colorAnimation.value ?? const Color(0xFFFFC24B);
        final glowAlpha = isActive ? 0.75 : 0.45;
        final glowBlur = isActive ? 14.0 : 8.0;
        return Transform.scale(
          scale: scaleAnimation.value,
          alignment: Alignment.centerRight,
          child: Text(
            _formatAmount(amountValue),
            textAlign: TextAlign.right,
            style: TextStyle(
              color: amountColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: amountColor.withValues(alpha: glowAlpha),
                  blurRadius: glowBlur,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SidebarRateBadge extends StatelessWidget {
  const _SidebarRateBadge({required this.text, required this.show});

  final String text;
  final bool show;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7A1A), Color(0xFFFF1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF3B3B).withValues(alpha: 0.6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _maskAccountText(String? account) {
  if (account == null || account.isEmpty) return '';
  if (account.length <= 4) return account;
  final start = account.substring(0, 1);
  final end = account.substring(account.length - 2);
  return '$start****$end';
}

String _firstNonEmptyText(String? first, [String? second, String? third]) {
  if (first != null && first.trim().isNotEmpty) return first.trim();
  if (second != null && second.trim().isNotEmpty) return second.trim();
  if (third != null && third.trim().isNotEmpty) return third.trim();
  return '';
}

String _formatAmount(num? amount) {
  final value = (amount ?? 0).toDouble();
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

String? _resolveGameIconUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  final trimmed = url.startsWith('/') ? url.substring(1) : url;
  return '${AppConfig.gameIconBaseUrl}$trimmed';
}
