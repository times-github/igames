import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_controller.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/common_header.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/config/app_config_export.dart';
// import 'package:igames/config/app_config.dart';
import 'package:igames/app/modules/home/views/promo_detail_view.dart';

class PromoTab extends StatelessWidget {
  const PromoTab({super.key, required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final promoController = Get.find<PromoController>();
    final headerHeight = Responsive.fromContext(context).size(41);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // 顶部栏（和首页一样）
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            height: headerHeight,
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final r = Responsive.fromConstraints(constraints, context);
                final sidebarWidth = r.width < 360 ? r.size(82) : r.size(92);
                final contentGap = r.size(4);
                final contentPadding = r.size(10);

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    contentPadding,
                    0,
                    contentPadding,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: sidebarWidth,
                        child: _PromoCategorySidebar(
                          controller: promoController,
                          scale: r.scale,
                        ),
                      ),
                      SizedBox(width: contentGap),
                      Expanded(
                        child: _PromoActivityList(controller: promoController),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCategorySidebar extends StatelessWidget {
  const _PromoCategorySidebar({
    required this.controller,
    required this.scale,
  });

  final PromoController controller;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final itemGap = 8 * scale;
      final loadingSize = 18 * scale;
      final textSize = 14 * scale;

      if (controller.isLoading.value && controller.categories.isEmpty) {
        return SizedBox(
          height: 42 * scale,
          child: Center(
            child: SizedBox(
              width: loadingSize,
              height: loadingSize,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
        );
      }

      if (controller.categories.isEmpty) {
        if (controller.loadError.value) {
          return Text(
            'checkNetwork'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: textSize,
            ),
          );
        }
        return const SizedBox.shrink();
      }

      return ListView(
        padding: EdgeInsets.only(top: 2 * scale),
        children: [
          _PromoCategoryChip(
            label: 'promoAll'.tr,
            selected: controller.selectedId.value == null,
            onTap: controller.selectAll,
            scale: scale,
          ),
          SizedBox(height: itemGap),
          ...controller.categories.map((item) {
            final isSelected = controller.selectedId.value == item.id;
            final name = item.name.trim();
            final label = name;
            return Padding(
              padding: EdgeInsets.only(bottom: itemGap),
              child: _PromoCategoryChip(
                label: label.isEmpty ? '--' : label,
                selected: isSelected,
                onTap: () => controller.selectCategory(item),
                scale: scale,
              ),
            );
          }),
        ],
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
    required this.scale,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final radius = 12 * scale;
    final height = 34 * scale;
    final fontSize = 12.5 * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400), //动画时间
          padding:
              EdgeInsets.symmetric(horizontal: 1 * scale, vertical: 1 * scale),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                selected
                    ? AppConfig.btnSelectedBackgroundAsset
                    : AppConfig.btnDefaultBackgroundAsset,
              ),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(radius), //圆角
          ),
          child: SizedBox(
            //盒子
            height: height,
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? AppConfig.btnSelectedTextColor
                      : AppConfig.btnDefaultTextColor,
                  fontSize: fontSize,
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: AspectRatio(
            aspectRatio: 16 / 4.2,
            child: _PromoImage(url: activity.picture),
          ),
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
