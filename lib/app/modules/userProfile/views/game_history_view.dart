import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_profile_controller.dart';

class GameHistoryView extends GetView<UserProfileController> {
  const GameHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _buildFilters(),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            return RefreshIndicator(
              onRefresh: controller.refreshGameHistory,
              color: const Color(0xFF1E7BFF),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: controller.gameHistory.isEmpty &&
                        !controller.gameIsLoading.value
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: controller.gameHistory.length + 1,
                        itemBuilder: (context, index) {
                          if (index == controller.gameHistory.length) {
                            if (controller.gameIsLoading.value &&
                                controller.gameHistory.isEmpty) {
                              return _buildLoading();
                            }
                            if (controller.gameHasMore.value &&
                                !controller.gameIsLoading.value) {
                              controller.loadMoreGameHistory();
                            }
                            return _buildListFooter();
                          }

                          final item = controller.gameHistory[index];
                          final change = item.changeAmount ?? 0;
                          // 投注类型强制显示为负数（红色）
                          final isPositive = (item.eventType == 'bet' ||
                                  item.eventType == 'rollout')
                              ? false
                              : (change > 0 || (item.changeType == 'add'));

                          return _buildGameItem(
                            eventType: item.eventType?.tr ?? '-',
                            time: item.updatedAt ?? '-',
                            changeAmount: change,
                            balanceBefore: item.balanceBefore ?? 0,
                            balanceAfter: item.balanceAfter ?? 0,
                            isPositive: isPositive,
                          );
                        },
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    const keys = [
      'all',
      'bet',
      'endround',
      'rollout',
      'takeall',
      'rollin',
      'debit',
      'credit',
      'payoff',
      'refund',
    ];
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < keys.length; i++) ...[
              _buildFilterButton(keys[i]),
              if (i != keys.length - 1) const SizedBox(width: 10),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String key) {
    final selected = controller.gameFilter.value == key;
    return GestureDetector(
      onTap: () => controller.setGameFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF5FA7FF)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          key.tr,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGameItem({
    required String eventType,
    required String time,
    required num changeAmount,
    required num balanceBefore,
    required num balanceAfter,
    required bool isPositive,
  }) {
    final Color deltaColor = isPositive
        ? const Color.fromARGB(255, 72, 233, 54)
        : const Color.fromARGB(255, 237, 71, 101);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141B26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部：事件类型 + 时间
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventType, // 保留原 EventType 文本
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDelta(changeAmount, isPositive),
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 下：余额前/后
          Row(
            children: [
              Expanded(
                child: _buildAmountInfo(
                    'balanceBefore', _fmt(balanceBefore), Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAmountInfo(
                    'balanceAfter', _fmt(balanceAfter), Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInfo(String label, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.tr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _fmt(num value) {
    final isNegative = value < 0;
    final absValue = value.abs();
    final fixed = absValue.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : '00';
    final intPartWithComma = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    final result = '$intPartWithComma.${decPart.padRight(2, '0')}';
    return isNegative ? '-$result' : result;
  }

  String _formatDelta(num value, bool isPositive) {
    final absText = _fmt(value.abs());
    final sign = isPositive ? '+' : '-';
    return '$sign$absText';
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
      if (Get.find<UserProfileController>().gameIsLoading.value) {
        return _buildLoading();
      }
      if (!Get.find<UserProfileController>().gameHasMore.value) {
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

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.inbox_outlined,
            size: 56, color: Colors.white.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'noMore'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
