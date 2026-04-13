import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/web_update_service.dart';
import 'package:igames/config/app_colors.dart';

class WebUpdateBanner extends GetView<WebUpdateService> {
  const WebUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final visible = controller.isUpdateAvailable.value;
      if (!visible) {
        return const SizedBox.shrink();
      }

      final applying = controller.isApplyingUpdate.value;

      return SafeArea(
        child: IgnorePointer(
          ignoring: !visible,
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              offset: visible ? Offset.zero : const Offset(0, -1),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;

                  return Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B2A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: compact
                        ? _buildCompactLayout(applying)
                        : _buildWideLayout(applying),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildWideLayout(bool applying) {
    return Row(
      children: [
        _buildLeadingIcon(),
        const SizedBox(width: 12),
        Expanded(child: _buildTextContent(applying, maxLines: 1)),
        const SizedBox(width: 12),
        _buildLaterButton(applying),
        const SizedBox(width: 8),
        _buildUpdateButton(applying),
      ],
    );
  }

  Widget _buildCompactLayout(bool applying) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildLeadingIcon(),
            const SizedBox(width: 12),
            Expanded(child: _buildTextContent(applying, maxLines: 2)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildLaterButton(applying)),
            const SizedBox(width: 8),
            Expanded(child: _buildUpdateButton(applying)),
          ],
        ),
      ],
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.system_update_alt_rounded,
        color: Color(0xFFA855F7),
        size: 18,
      ),
    );
  }

  Widget _buildTextContent(bool applying, {required int maxLines}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'webUpdateAvailableTitle'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          applying ? 'webUpdateApplying'.tr : 'webUpdateAvailableMessage'.tr,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.68),
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildLaterButton(bool applying) {
    return TextButton(
      onPressed: applying ? null : controller.dismissUpdate,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.78),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text('webUpdateLater'.tr),
    );
  }

  Widget _buildUpdateButton(bool applying) {
    return ElevatedButton(
      onPressed: applying ? null : controller.applyUpdate,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.42),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        applying ? 'webUpdateApplying'.tr : 'webUpdateNow'.tr,
      ),
    );
  }
}
