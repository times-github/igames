import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_selector_controller.dart';

class LanguageSelectorView extends GetView<LanguageSelectorController> {
  const LanguageSelectorView({
    super.key,
    this.onTap,
    this.dense = true,
    this.scale = 1,
    this.showDot = true,
    this.labelOverride,
  });

  final VoidCallback? onTap;
  final bool dense;
  final double scale;
  final bool showDot;
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: controller.link,
      child: GestureDetector(
        onTap: onTap ?? () => controller.toggleLanguageMenu(context),
        child: Obx(() {
          final label = labelOverride ?? controller.currentLanguage.value;
          final padding = dense
              ? EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 10 * scale,
                )
              : EdgeInsets.symmetric(
                  horizontal: 12 * scale,
                  vertical: 8 * scale,
                );
          final margin = dense
              ? EdgeInsets.symmetric(horizontal: 6 * scale)
              : EdgeInsets.zero;
          final fontSize = (dense ? 11.0 : 13.0) * scale;
          final dotSize = (dense ? 5.0 : 6.0) * scale;
          final radius = (dense ? 18.0 : 20.0) * scale;
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (showDot) ...[
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
              ],
            ),
          );
        }),
      ),
    );
  }
}
