import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/home/views/tabs/earn_tab.dart';
import 'package:igames/app/modules/home/views/tabs/home_tab.dart';
import 'package:igames/app/modules/home/views/tabs/profile_tab.dart';
import 'package:igames/app/modules/home/views/tabs/promo_tab.dart';
import 'package:igames/app/modules/home/views/tabs/recharge_tab.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/app/modules/widgets/side_drawer.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.auth,
    required this.menuController,
  });

  final HomeController controller;
  final AuthController auth;
  final GameMenuController menuController;

  static const List<_BottomNavItem> _bottomNavItems = [
    _BottomNavItem('home', Icons.home_filled),
    _BottomNavItem('promo', Icons.local_activity_outlined),
    _BottomNavItem('recharge', Icons.account_balance_wallet, isCenter: true),
    _BottomNavItem('earn', Icons.monetization_on_outlined, showBadge: true),
    _BottomNavItem('mine', Icons.person_outline),
  ];

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final List<Widget?> _tabCache;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _tabCache = List<Widget?>.filled(5, null);
    _tabCache[0] = _buildTab(0);
    final initialTab = widget.controller.currentTab.value;
    if (initialTab >= 0 && initialTab < _tabCache.length) {
      _tabCache[initialTab] = _buildTab(initialTab);
    }
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return HomeTab(
          controller: widget.controller,
          auth: widget.auth,
          menuController: widget.menuController,
        );
      case 1:
        return PromoTab(auth: widget.auth);
      case 2:
        return RechargeTab(auth: widget.auth);
      case 3:
        return EarnTab(auth: widget.auth);
      case 4:
        return ProfileTab(auth: widget.auth, controller: widget.controller);
      default:
        return const SizedBox.shrink();
    }
  }

  void _ensureTabBuilt(int index) {
    if (index < 0 || index >= _tabCache.length) return;
    if (_tabCache[index] != null) return;
    _tabCache[index] = _buildTab(index);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = widget.controller.currentTab.value;
      _ensureTabBuilt(tab);
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        drawer: SideDrawer(isOpen: _isDrawerOpen),
        onDrawerChanged: (isOpen) {
          if (_isDrawerOpen == isOpen) return;
          setState(() {
            _isDrawerOpen = isOpen;
          });
        },
        body: IndexedStack(
          index: tab,
          children: _tabCache
              .map((tabView) => tabView ?? const SizedBox.shrink())
              .toList(),
        ),
        bottomNavigationBar: _buildBottomBar(context, tab),
      );
    });
  }

  Widget _buildBottomBar(BuildContext context, int tab) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = Responsive.fromConstraints(constraints, context);
        final m = _BottomNavMetrics.from(r, bottomInset);

        TextStyle navLabelStyle(
          bool isActive, {
          Color activeColor = AppConfig.btnSelectedColor,
        }) =>
            TextStyle(
              color: isActive ? activeColor : Colors.white70,
              fontSize: m.labelSize,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              height: 1,
            );

        return SafeArea(
          top: false,
          bottom: false,
          child: SizedBox(
            height: m.barHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  color: Colors.transparent,
                  padding: EdgeInsets.fromLTRB(
                    m.outerHorizontal,
                    m.outerTop,
                    m.outerHorizontal,
                    m.outerTop + m.extraSpace,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(m.barRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: m.innerHorizontal,
                          vertical: m.innerVertical,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(m.barRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: m.shadowBlur,
                              offset: Offset(0, -m.shadowOffset),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: HomeShell._bottomNavItems
                              .asMap()
                              .entries
                              .expand((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final bool isActive = tab == idx;
                            if (item.isCenter) {
                              return [
                                Expanded(
                                  child: InkWell(
                                    borderRadius:
                                        BorderRadius.circular(m.barRadius - 4),
                                    onTap: () async {
                                      final ok = await widget.auth
                                          .ensureAuthenticated(context);
                                      if (!ok) return;
                                      _ensureTabBuilt(2);
                                      widget.controller.currentTab.value = 2;
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                            height: m.centerPlaceholderHeight),
                                        SizedBox(height: m.labelGap),
                                        Text(
                                          item.label.tr,
                                          style: navLabelStyle(
                                            isActive,
                                            activeColor:
                                                AppConfig.btnSelectedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ];
                            }
                            return [
                              Expanded(
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(m.barRadius - 4),
                                  onTap: () async {
                                    if (idx == 3) {
                                      final ok = await widget.auth
                                          .ensureAuthenticated(context);
                                      if (!ok) return;
                                    }
                                    if (idx == 4 &&
                                        widget.auth.isLoggedIn.value) {
                                      widget.controller.refreshBalance();
                                    }
                                    _ensureTabBuilt(idx);
                                    widget.controller.currentTab.value = idx;
                                  },
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: m.sideIconBox,
                                        height: m.sideIconBox,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Align(
                                              alignment: Alignment.center,
                                              child: Icon(
                                                item.icon,
                                                size: m.sideIconSize,
                                                color: isActive
                                                    ? AppConfig.btnSelectedColor
                                                    : Colors.white70,
                                              ),
                                            ),
                                            if (item.showBadge)
                                              Positioned(
                                                top: -m.badgeTopOffset,
                                                right: -m.badgeRightOffset,
                                                child: _FlameBadge(
                                                  size: m.badgeSize,
                                                  iconSize: m.badgeIconSize,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: m.labelGap),
                                      Text(
                                        item.label.tr,
                                        style: navLabelStyle(isActive),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ];
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: m.centerIconBottom + m.extraSpace,
                  child: GestureDetector(
                    onTap: () async {
                      final ok = await widget.auth.ensureAuthenticated(context);
                      if (!ok) return;
                      _ensureTabBuilt(2);
                      widget.controller.currentTab.value = 2;
                    },
                    child: SizedBox(
                      width: m.centerIconSize,
                      height: m.centerIconSize,
                      child: Image.asset(
                        'assets/images/menu_desposit.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.low,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;
  final bool isCenter;
  final bool showBadge;

  const _BottomNavItem(
    this.label,
    this.icon, {
    this.isCenter = false,
    this.showBadge = false,
  });
}

class _BottomNavMetrics {
  const _BottomNavMetrics._({
    required this.barHeight,
    required this.outerHorizontal,
    required this.outerTop,
    required this.innerHorizontal,
    required this.innerVertical,
    required this.barRadius,
    required this.sideIconBox,
    required this.sideIconSize,
    required this.labelSize,
    required this.labelGap,
    required this.centerIconSize,
    required this.centerPlaceholderHeight,
    required this.centerIconBottom,
    required this.badgeSize,
    required this.badgeIconSize,
    required this.badgeTopOffset,
    required this.badgeRightOffset,
    required this.extraSpace,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  factory _BottomNavMetrics.from(Responsive r, double bottomInset) {
    final centerIconSize = r.size(48);
    return _BottomNavMetrics._(
      barHeight: r.size(82) + bottomInset,
      outerHorizontal: r.size(16),
      outerTop: r.size(6),
      innerHorizontal: r.size(14),
      innerVertical: r.size(8),
      barRadius: r.size(20),
      sideIconBox: r.size(24),
      sideIconSize: r.size(22),
      labelSize: r.font(11),
      labelGap: r.size(3),
      centerIconSize: centerIconSize,
      centerPlaceholderHeight: centerIconSize * 0.48,
      centerIconBottom: r.size(26),
      badgeSize: r.size(16),
      badgeIconSize: r.size(12),
      badgeTopOffset: r.size(6),
      badgeRightOffset: r.size(8),
      extraSpace: bottomInset > 0 ? bottomInset / 2 : 0.0,
      shadowBlur: r.size(12),
      shadowOffset: r.size(2),
    );
  }

  final double barHeight;
  final double outerHorizontal;
  final double outerTop;
  final double innerHorizontal;
  final double innerVertical;
  final double barRadius;
  final double sideIconBox;
  final double sideIconSize;
  final double labelSize;
  final double labelGap;
  final double centerIconSize;
  final double centerPlaceholderHeight;
  final double centerIconBottom;
  final double badgeSize;
  final double badgeIconSize;
  final double badgeTopOffset;
  final double badgeRightOffset;
  final double extraSpace;
  final double shadowBlur;
  final double shadowOffset;
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge({
    this.size = 16,
    this.iconSize = 12,
  });

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF6433), Color(0xFFFF3B6A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_fire_department,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}
