import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../config/app_config_export.dart';
import '../controllers/device_info_controller.dart';
import 'settings_route_back.dart';

class DeviceInfoView extends GetView<DeviceInfoController> {
  const DeviceInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleSettingsRouteBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => handleSettingsRouteBack(context),
          ),
          centerTitle: true,
          title: Text(
            'deviceInfo'.tr,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
        body: Obx(() {
          if (controller.loading.value || controller.info.value == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final info = controller.info.value!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'phoneModel'.tr, value: info.model),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(label: 'osVersion'.tr, value: info.osVersion),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(label: 'loginPort'.tr, value: info.loginPort),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(
                      label: 'browserVersion'.tr, value: info.browserVersion),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(
                      label: 'browserEngine'.tr, value: info.browserEngine),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(
                      label: 'flutterRuntime'.tr, value: info.flutterRuntime),
                  const Divider(height: 1, color: Colors.white24),
                  _InfoRow(label: 'currentTime'.tr, value: info.currentTime),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
