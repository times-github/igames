import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_controller.dart';
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PromoCategorySidebar(controller: promoController),
                    const SizedBox(width: 10),
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
            categoryLabel: _resolveCategoryLabel(
              controller.categories,
              activity.categoryId,
            ),
            onTap: () => Get.to(
              () => PromoDetailView(activity: activity),
            ),
            gradient: _promoGradients[index % _promoGradients.length],
          );
        },
      );
    });
  }
}

class _PromoActivityCard extends StatelessWidget {
  const _PromoActivityCard({
    required this.activity,
    required this.categoryLabel,
    required this.onTap,
    required this.gradient,
  });

  final PromoActivity activity;
  final String categoryLabel;
  final VoidCallback onTap;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    final statusLabel = (activity.endAt == null || activity.endAt!.isEmpty)
        ? 'activityInProgress'.tr
        : 'activityEnded'.tr;
    return Material(
      color: const Color.fromARGB(255, 47, 82, 176),
      //右上角圆角为0 其他圆角为18
      borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(18),
          topLeft: Radius.circular(18),
          bottomLeft: Radius.circular(0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          // height: 102,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 255, 255, 255)
                    .withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
                child: Row(
                  children: [
                    _PromoImage(url: activity.picture),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              activity.title.isEmpty ? '--' : activity.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _PromoTag(
                  text: categoryLabel.isEmpty ? 'hot'.tr : categoryLabel,
                  tone: const [
                    Color.fromARGB(156, 206, 158, 119),
                    Color(0xFF9B5F27)
                  ],
                ),
              ),
              Positioned(
                bottom: 1,
                right: 14,
                child: _PromoCountdownText(
                  endAt: activity.endAt,
                  fallback: statusLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCountdownText extends StatelessWidget {
  const _PromoCountdownText({
    required this.endAt,
    required this.fallback,
  });

  final String? endAt;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final endTime = _parseEndAt(endAt);
    if (endTime == null) {
      return Text(
        fallback,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final diff = endTime.difference(now);
        if (diff.isNegative) {
          return Text(
            'activityEnded'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return Text(
          _formatCountdown(diff),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        );
      },
    );
  }
}

class _PromoImage extends StatelessWidget {
  const _PromoImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvePromoImageUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: resolved == null || resolved.isEmpty
            ? const Icon(Icons.campaign, color: Colors.white70, size: 26)
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.campaign,
                  color: Colors.white70,
                  size: 26,
                ),
              ),
      ),
    );
  }
}

class _PromoTag extends StatelessWidget {
  const _PromoTag({
    required this.text,
    required this.tone,
  });

  final String text;
  final List<Color> tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: tone,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        //只有左下 右下角圆角
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10), bottomRight: Radius.circular(0)),
        boxShadow: [
          BoxShadow(
            color: tone.last.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _resolveCategoryLabel(List<PromoCategory> categories, int? id) {
  if (id == null) return '';
  final found = categories.firstWhereOrNull((item) => item.id == id);
  if (found == null) return '';
  return found.shortName.isNotEmpty ? found.shortName : found.name;
}

String? _resolvePromoImageUrl(String raw) {
  if (raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${AppConfig.apiBaseUrl}/$trimmed';
}

DateTime? _parseEndAt(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  var value = raw.trim();
  if (value.contains(' ') && !value.contains('T')) {
    value = value.replaceFirst(' ', 'T');
  }
  final parsed = DateTime.tryParse(value);
  return parsed?.toLocal();
}

String _formatCountdown(Duration diff) {
  final totalSeconds = diff.inSeconds;
  final days = totalSeconds ~/ 86400;
  final hours = (totalSeconds % 86400) ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (days > 0) {
    return '$days${'countdownDay'.tr} '
        '$hours${'countdownHour'.tr} '
        '$minutes${'countdownMinute'.tr} '
        '$seconds${'countdownSecond'.tr}';
  }
  return '$hours${'countdownHour'.tr} '
      '$minutes${'countdownMinute'.tr} '
      '$seconds${'countdownSecond'.tr}';
}

const List<List<Color>> _promoGradients = [
  [Color(0xFF7A7BFF), Color(0xFF5C7CFF)],
  [Color(0xFF3DB7FF), Color(0xFF2BB6C7)],
  [Color(0xFFFF8A5B), Color(0xFFFFB66D)],
  [Color(0xFF5CD06A), Color(0xFF2F8D5D)],
  [Color(0xFF8E6BFF), Color(0xFF5A3DCE)],
];
