import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/web_update_service.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class WebUpdateBanner extends GetView<WebUpdateService> {
  const WebUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isUpdateAvailable.value) {
        return const SizedBox.shrink();
      }

      final applying = controller.isApplyingUpdate.value;

      return Positioned.fill(
        child: PointerInterceptor(
          child: IgnorePointer(
            ignoring: false,
            child: Container(
              color: Colors.black.withValues(alpha: 0.48),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF343E55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.30),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'webUpdateAvailableTitle'.tr,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          applying
                              ? 'webUpdateApplying'.tr
                              : 'webUpdateAvailableMessage'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 15,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: _DialogButton(
                                label: 'webUpdateLater'.tr,
                                filled: false,
                                enabled: !applying,
                                onTap: controller.dismissUpdate,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _DialogButton(
                                label: applying
                                    ? 'webUpdateApplying'.tr
                                    : 'webUpdateNow'.tr,
                                filled: true,
                                enabled: !applying,
                                onTap: controller.applyUpdate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.filled,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFFD7B24A);
    final fillColor = const Color(0xFFF0C95C);
    final foregroundColor = filled ? const Color(0xFF443100) : borderColor;

    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: filled
                  ? (enabled ? fillColor : fillColor.withValues(alpha: 0.5))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    enabled ? borderColor : borderColor.withValues(alpha: 0.5),
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: enabled
                      ? foregroundColor
                      : foregroundColor.withValues(alpha: 0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
