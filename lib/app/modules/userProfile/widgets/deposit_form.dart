import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/user_profile_controller.dart';

class DepositForm extends StatefulWidget {
  const DepositForm({super.key});

  @override
  State<DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends State<DepositForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    final amount = _amountController.text.trim();
    final remark = _remarkController.text.trim();

    if (amount.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterDepositAmount'.tr);
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      Get.snackbar('tip'.tr, 'pleaseEnterValidDepositAmount'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PaymentServices.deposit(
        amount: amount,
        remark: remark,
      );

      if (result.code == 200) {
        Get.snackbar('tip'.tr, 'depositSubmitted'.tr);

        // 如果有支付URL，打开支付页面
        if (result.data?.url != null && result.data!.url!.isNotEmpty) {
          _launchPaymentUrl(result.data!.url!);
        }
      } else {
        Get.snackbar('tip'.tr, result.msg ?? 'depositFailed'.tr);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('tip'.tr, 'cannotOpenPaymentPage'.tr);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, 'openPaymentPageFailed'.tr + ': $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF1E7BFF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'deposit'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),

              // 金额输入
              Text(
                'depositAmount'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'pleaseEnterDepositAmount'.tr,
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  prefixText: '${AppConfig.currencyCode()} ',
                  prefixStyle: const TextStyle(
                    color: Color(0xFF1E7BFF),
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2A3441),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 备注输入
              Text(
                'remark'.tr,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _remarkController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'pleaseEnterRemark'.tr,
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: const Color(0xFF2A3441),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 按钮组
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleDeposit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('confirmDeposit'.tr),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E7BFF))),
                  SizedBox(height: 12),
                  Text('processing'.tr,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
