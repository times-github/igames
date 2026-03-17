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

class HomeShell extends StatelessWidget {
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
    _BottomNavItem('earn', Icons.monetization_on_outlined, badge: _FlameBadge()),
    _BottomNavItem('mine', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = controller.currentTab.value;
      return Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        drawer: const SideDrawer(),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: IndexedStack(
            index: tab,
            children: [
              HomeTab(
                controller: controller,
                auth: auth,
                menuController: menuController,
              ),
              PromoTab(auth: auth),
              RechargeTab(auth: auth),
              EarnTab(auth: auth),
              ProfileTab(auth: auth, controller: controller),
            ],
          ),
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
                      children: _bottomNavItems.asMap().entries.expand((entry) {
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
                                  final ok = await auth.ensureAuthenticated(context);
                                  if (!ok) return;
                                }
                                if (idx == 4 && auth.isLoggedIn.value) {
                                  controller.refreshBalance();
                                }
                                controller.currentTab.value = idx;
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
                  final ok = await auth.ensureAuthenticated(context);
                  if (!ok) return;
                  controller.currentTab.value = 2;
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
