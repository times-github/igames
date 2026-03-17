import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_selector_controller.dart';

class LanguageSelectorView extends GetView<LanguageSelectorController> {
  const LanguageSelectorView({
    super.key,
    this.onTap,
    this.compact = true,
  });

  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: controller.link,
      child: GestureDetector(
        onTap: onTap ?? () => controller.toggleLanguageMenu(context),
        child: Obx(() {
          final padding = compact
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
          final margin =
              compact ? const EdgeInsets.symmetric(horizontal: 6) : EdgeInsets.zero;
          final fontSize = compact ? 11.0 : 13.0;
          final dotSize = compact ? 5.0 : 6.0;
          final iconSize = compact ? 14.0 : 16.0;
          final radius = compact ? 18.0 : 20.0;
          return Container(
            // 外边距
            margin: margin,
            // 内边距
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFF20242D),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.currentLanguage.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}
