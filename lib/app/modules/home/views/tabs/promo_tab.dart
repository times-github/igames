import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_controller.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/common_header.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/modules/home/views/promo_detail_view.dart';

class PromoTab extends StatelessWidget {
  const PromoTab({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final promoController = Get.find<PromoController>();

    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.darkBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 顶部栏（和首页一样）
            Container(
              color: AppColors.backgroundDark,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              height: 41,
              alignment: Alignment.center,
              child: buildCommonHeader(
                context,
                auth,
                showNotification: true,
                showMenu: true,
              ),
            ),
            // 内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PromoCategorySidebar(controller: promoController),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _PromoActivityList(controller: promoController),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCategorySidebar extends StatelessWidget {
  const _PromoCategorySidebar({required this.controller});

  final PromoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.categories.isEmpty) {
        return const SizedBox(
          height: 42,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        );
      }

      if (controller.categories.isEmpty) {
        if (controller.loadError.value) {
          return SizedBox(
            width: 88,
            child: Text(
              'checkNetwork'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
              ),
            ),
          );
        }
        return const SizedBox(width: 88);
      }

      return SizedBox(
        width: 92,
        child: ListView(
          padding: const EdgeInsets.only(top: 2),
          children: [
            _PromoCategoryChip(
              label: 'promoAll'.tr,
              selected: controller.selectedId.value == null,
              onTap: controller.selectAll,
            ),
            const SizedBox(height: 8),
            ...controller.categories.map((item) {
              final isSelected = controller.selectedId.value == item.id;
              final name = item.name.trim();
              final label = name;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PromoCategoryChip(
                  label: label.isEmpty ? '--' : label,
                  selected: isSelected,
                  onTap: () => controller.selectCategory(item),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// 促销分类标签
class _PromoCategoryChip extends StatelessWidget {
  const _PromoCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedGradient = const LinearGradient(
      colors: [Color(0xFFB07CFF), Color(0xFF6B6CFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400), //动画时间
          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1), //内边距
          decoration: BoxDecoration(
            color:
                selected ? null : const Color.fromARGB(255, 45, 49, 64), //选中背景色
            gradient: selected ? selectedGradient : null, //选中渐变背景
            borderRadius: BorderRadius.circular(12), //圆角
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: SizedBox(
            //盒子
            height: 34,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoActivityList extends StatelessWidget {
  const _PromoActivityList({required this.controller});

  final PromoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingList.value && controller.activities.isEmpty) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      }

      if (controller.activities.isEmpty) {
        final text =
            controller.listError.value ? 'checkNetwork'.tr : 'activityEmpty'.tr;
        return Center(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        );
      }

      return ListView.separated(
        itemCount: controller.activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final activity = controller.activities[index];
          return _PromoActivityCard(
            activity: activity,
            onTap: () => Get.to(
              () => PromoDetailView(activity: activity),
            ),
          );
        },
      );
    });
  }
}

class _PromoActivityCard extends StatelessWidget {
  const _PromoActivityCard({
    required this.activity,
    required this.onTap,
  });

  final PromoActivity activity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 16 / 4.2,
          child: _PromoImage(url: activity.picture),
        ),
      ),
    );
  }
}

class _PromoImage extends StatelessWidget {
  const _PromoImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvePromoImageUrl(url);
    if (resolved == null || resolved.isEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: const Icon(Icons.campaign, color: Colors.white70, size: 28),
      );
    }

    return CompatibleImage.network(
      resolved,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: const Icon(Icons.campaign, color: Colors.white70, size: 28),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.white.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}

String? _resolvePromoImageUrl(String raw) {
  if (raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${AppConfig.apiBaseUrl}/$trimmed';
}
