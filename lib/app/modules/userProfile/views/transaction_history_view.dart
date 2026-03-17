import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../controllers/user_profile_controller.dart';

class TransactionHistoryView extends StatefulWidget {
  const TransactionHistoryView({super.key});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  final UserProfileController controller = Get.find<UserProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161E2A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'transactionHistory'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildFilters(),
            const SizedBox(height: 12),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterChip(
                'all', 'all'.tr, controller.walletFilter.value == 'all'),
            const SizedBox(width: 8),
            _filterChip('deposit', 'deposit'.tr,
                controller.walletFilter.value == 'deposit'),
            const SizedBox(width: 8),
            _filterChip('withdraw', 'withdraw'.tr,
                controller.walletFilter.value == 'withdraw'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label, bool selected) {
    return GestureDetector(
      onTap: () => controller.setWalletFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6C63FF) : const Color(0xFF1A2332),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF8A7CFF) : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      return RefreshIndicator(
        color: const Color(0xFF7A4CFF),
        onRefresh: controller.refreshWalletHistory,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.walletHistory.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.walletHistory.length) {
              if (controller.walletIsLoading.value &&
                  controller.walletHistory.isEmpty) {
                return _buildLoading();
              }
              if (controller.walletHasMore.value &&
                  !controller.walletIsLoading.value) {
                controller.loadMoreWalletHistory();
              }
              return _buildFooter();
            }
            final item = controller.walletHistory[index];
            final isDeposit = item.actionType == 'deposit';
            return _HistoryCard(
              amount: item.amount ?? 0,
              currency: item.currency ?? '',
              status: controller.mapOrderStatus(item.orderStatus),
              orderNo: item.gameorderNum ?? '-',
              updatedAt: item.updatedAt ?? '-',
              isDeposit: isDeposit,
            );
          },
        ),
      );
    });
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFF7A4CFF)),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    if (controller.walletIsLoading.value) return _buildLoading();
    if (!controller.walletHasMore.value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'noMore'.tr,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
      );
    }
    return const SizedBox(height: 24);
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.amount,
    required this.currency,
    required this.status,
    required this.orderNo,
    required this.updatedAt,
    required this.isDeposit,
  });

  final num amount;
  final String currency;
  final String status;
  final String orderNo;
  final String updatedAt;
  final bool isDeposit;

  @override
  Widget build(BuildContext context) {
    final color = isDeposit ? const Color(0xFF30D158) : const Color(0xFFFF6B6B);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141C27),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.south : Icons.north,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${isDeposit ? '+' : '-'}${_formatAmount(amount)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currency,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${'orderNumber'.tr}: $orderNo',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: orderNo));
                        Get.snackbar('tip'.tr, 'copied'.tr,
                            duration: const Duration(seconds: 1));
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        updatedAt,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(num value) {
    final parts = value.toString().split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final intPartWithComma = intPart.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return intPartWithComma + decPart;
  }
}
