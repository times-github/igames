import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/utils/user_status_error.dart';
import 'package:igames/app/modules/widgets/app_close_button.dart';
import 'package:igames/config/app_config_export.dart';

class WithdrawForm extends StatefulWidget {
  const WithdrawForm({super.key});

  @override
  State<WithdrawForm> createState() => _WithdrawFormState();
}

class _WithdrawFormState extends State<WithdrawForm> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  bool _isLoading = false;
  String _selectedBankCode = '';
  List<Map<String, dynamic>> _bankList = [];

  @override
  void initState() {
    super.initState();
    _loadBankList();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadBankList() async {
    try {
      final banks = await PaymentServices.getBankList();
      setState(() {
        _bankList = banks;
        if (banks.isNotEmpty) {
          _selectedBankCode = banks.first['code'] ?? '';
        }
      });
    } catch (e) {
      Get.snackbar('tip'.tr, 'getBankListFailed'.tr);
    }
  }

  Future<void> _handleWithdraw() async {
    final amount = _amountController.text.trim();
    final cardNumber = _cardNumberController.text.trim();
    final name = _nameController.text.trim();
    // final mobile = _mobileController.text.trim();

    if (amount.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterWithdrawAmount'.tr);
      return;
    }

    if (cardNumber.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterBankCardNumber'.tr);
      return;
    }

    if (name.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterCardholderName'.tr);
      return;
    }

    if (_selectedBankCode.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseSelectBank'.tr);
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      Get.snackbar('tip'.tr, 'pleaseEnterValidWithdrawAmount'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await PaymentServices.withdraw(
        money: amount,
        number: cardNumber,
        name: name,
        bankCode: _selectedBankCode,
      );
      final handled = await handleUserStatusError(
        code: result.code,
        message: result.msg,
      );
      if (handled) {
        return;
      }

      if (result.code == 1) {
        Get.snackbar('tip'.tr, 'withdraw_submitted'.tr);
      } else {
        Get.snackbar(
          'tip'.tr,
          _resolveWithdrawMessage(result.code, result.msg),
        );
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _resolveWithdrawMessage(int? code, String? message) {
    final statusError = parseUserStatusError(code: code, message: message);
    if (statusError != null) {
      return statusError.localizedMessage;
    }
    return 'withdrawFailed'.tr;
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
              // 标题（可根据需要保留或移除）
              Row(
                children: [
                  const Icon(
                    Icons.credit_card,
                    color: Color(0xFF1E7BFF),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'withdraw'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const AppCloseIcon(size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 提现金额输入
              Text(
                'withdrawAmount'.tr,
                style: const TextStyle(
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
                  hintText: 'pleaseEnterWithdrawAmount'.tr,
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

              // 银行卡号输入
              Text(
                'bankCardNumber'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'pleaseEnterBankCardNumber'.tr,
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
              const SizedBox(height: 16),

              // 持卡人姓名输入
              Text(
                'cardholderName'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'pleaseEnterCardholderName'.tr,
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
              const SizedBox(height: 16),

              // 手机号输入
              Text(
                'mobile'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'pleaseEnterMobile'.tr,
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
              const SizedBox(height: 16),

              // 银行选择
              Text(
                'selectBank'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A3441),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBankCode.isEmpty ? null : _selectedBankCode,
                    hint: Text(
                      'pleaseSelectBank'.tr,
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF2A3441),
                    isExpanded: true,
                    items: _bankList.map((bank) {
                      return DropdownMenuItem<String>(
                        value: bank['bankNum'] ?? '',
                        //全称+ 短称r
                        child:
                            Text('${bank['bankName']} (${bank['bankShort']})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBankCode = value ?? '';
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 仅保留提交按钮，与充值一致
              Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E7BFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('confirmWithdraw'.tr),
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
                  const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF1E7BFF))),
                  const SizedBox(height: 12),
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
