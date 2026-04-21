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
    _BottomNavItem('earn', Icons.monetization_on_outlined,
        badge: _FlameBadge()),
    _BottomNavItem('mine', Icons.person_outline),
  ];

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final List<Widget?> _tabCache;

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
        drawer: const SideDrawer(),
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
    final extraSpace = bottomInset > 0 ? bottomInset / 2 : 0.0;
    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        height: 82 + bottomInset,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              color: Colors.transparent,
              padding: EdgeInsets.fromLTRB(16, 6, 16, 6 + extraSpace),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
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
                          return [const SizedBox(width: 88)];
                        }
                        return [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                if (idx == 3) {
                                  final ok = await widget.auth
                                      .ensureAuthenticated(context);
                                  if (!ok) return;
                                }
                                if (idx == 4 && widget.auth.isLoggedIn.value) {
                                  widget.controller.refreshBalance();
                                }
                                _ensureTabBuilt(idx);
                                widget.controller.currentTab.value = idx;
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: isActive
                                            ? const Color(0xFF8A6CFF)
                                            : Colors.white70,
                                      ),
                                      if (item.badge != null)
                                        Positioned(
                                          top: -6,
                                          right: -8,
                                          child: item.badge!,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.label.tr,
                                    style: TextStyle(
                                      color: isActive
                                          ? const Color(0xFF8A6CFF)
                                          : Colors.white70,
                                      fontSize: 11,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
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
              bottom: 8 + extraSpace,
              child: _CenterRechargeButton(
                isActive: tab == 2,
                onTap: () async {
                  final ok = await widget.auth.ensureAuthenticated(context);
                  if (!ok) return;
                  _ensureTabBuilt(2);
                  widget.controller.currentTab.value = 2;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;
  final bool isCenter;
  final Widget? badge;

  const _BottomNavItem(
    this.label,
    this.icon, {
    this.isCenter = false,
    this.badge,
  });
}

class _FlameBadge extends StatelessWidget {
  const _FlameBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF6433), Color(0xFFFF3B6A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_fire_department,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CenterRechargeButton extends StatelessWidget {
  const _CenterRechargeButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.translate(
        offset: const Offset(0, -6),
        child: SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 18,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB489FF), Color(0xFF7E74FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(208, 177, 185, 234),
                        blurRadius: 10,
                        offset: Offset(2, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: isActive ? 0.26 : 0.16),
                      width: 1.0,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
                  child: Text(
                    'recharge'.tr,
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xFFB07CFF)
                          : const Color.fromARGB(179, 255, 255, 255),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
