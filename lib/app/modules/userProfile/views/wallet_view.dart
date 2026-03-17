import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/config/app_config_export.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/deposit_form.dart';

class WalletView extends GetView<UserProfileController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 余额卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2332),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF2A3441),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'currentPoints'.tr,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // 余额信息和操作按钮
                Row(
                  children: [
                    // 余额图标和金额
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20242D),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 10),

                          Text(AppConfig.currencyCode(),
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 222, 247, 2))),
                          SizedBox(width: 4),

                          Obx(() => Text(
                                controller.home.balance.value,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24),
                              )),
                          SizedBox(width: 4),
                          //点击刷新余额
                          IconButton(
                            onPressed: () async {
                              await controller.home.refreshBalance();
                            },
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                ],
              ),

                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 20),

          //  动态内容显示
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1621),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 52, 112, 232),
                  width: 2,
                ),
              ),
              child: const DepositForm(),
            ),
          ),
        ],
      ),
    );
  }
}
