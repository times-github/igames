import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../controllers/user_profile_controller.dart';

class WalletHistoryView extends GetView<UserProfileController> {
  const WalletHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部筛选
          Obx(() => Row(
                children: [
                  _buildFilterButton(
                      'all',
                      controller.walletFilter.value == 'all',
                      () => controller.setWalletFilter('all')),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                      'deposit',
                      controller.walletFilter.value == 'deposit',
                      () => controller.setWalletFilter('deposit')),
                  const SizedBox(width: 8),
                  _buildFilterButton(
                      'withdraw',
                      controller.walletFilter.value == 'withdraw',
                      () => controller.setWalletFilter('withdraw')),
                ],
              )),
          const SizedBox(height: 16),

          // 列表
          Expanded(
            child: Obx(() {
              return RefreshIndicator(
                onRefresh: controller.refreshWalletHistory,
                color: const Color(0xFF1E7BFF),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.walletHistory.length + 1,
                  itemBuilder: (context, index) {
                    // 触底加载更多
                    if (index == controller.walletHistory.length) {
                      if (controller.walletIsLoading.value &&
                          controller.walletHistory.isEmpty) {
                        return _buildLoading();
                      }
                      // 触发加载更多
                      if (controller.walletHasMore.value &&
                          !controller.walletIsLoading.value) {
                        controller.loadMoreWalletHistory();
                      }
                      return _buildListFooter();
                    }

                    final item = controller.walletHistory[index];
                    return _buildHistoryItem(
                      amount: item.amount ?? 0,
                      updatedAt: item.updatedAt ?? '-',
                      gameOrderNum: item.gameorderNum ?? '-',
                      orderStatus: controller.mapOrderStatus(item.orderStatus),
                      isDeposit: (item.actionType == 'deposit'),
                      currency: item.currency ?? '🪙',
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E7BFF) : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF1E7BFF) : const Color(0xFF2A3441),
            width: 1,
          ),
        ),
        child: Text(
          title.tr,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem({
    required int amount,
    required String updatedAt,
    required String gameOrderNum,
    required String orderStatus,
    required bool isDeposit,
    required String currency,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2332),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2A3441),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isDeposit ? const Color(0xFF0E8A00) : const Color(0xFFB00020),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    (isDeposit ? '+' : '-') + controller.formatAmount(amount),
                    style: TextStyle(
                      color: isDeposit
                          ? const Color.fromARGB(255, 72, 233, 54)
                          : const Color.fromARGB(255, 237, 71, 101),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  // 货币符号
                  Text(
                    currency,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                orderStatus,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 订单号置于右上角
                Align(
                  //Align 用于将子元素放置在父元素的右上角
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          "${"orderNumber".tr} : $gameOrderNum",
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          await Clipboard.setData(
                              ClipboardData(text: gameOrderNum));
                          Get.snackbar('tip'.tr, 'copied'.tr,
                              duration:
                                  const Duration(seconds: 1)); //seconds 1秒
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),
                // 下：时间
                Text(
                  updatedAt,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 金额
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E7BFF)),
        ),
      ),
    );
  }

  Widget _buildListFooter() {
    return Obx(() {
      if (Get.find<UserProfileController>().walletIsLoading.value) {
        return _buildLoading();
      }
      if (!Get.find<UserProfileController>().walletHasMore.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              'noMore'.tr,
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
        );
      }
      return const SizedBox(height: 24);
    });
  }
}
