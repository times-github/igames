import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/routes/app_pages.dart';

class BankCardAddView extends StatefulWidget {
  const BankCardAddView({super.key});

  @override
  State<BankCardAddView> createState() => _BankCardAddViewState();
}

class _BankCardAddViewState extends State<BankCardAddView> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _holderController = TextEditingController();
  bool _isDefault = true;
  bool _isLoading = false;
  bool _isBankLoading = false;
  bool _isVerified = false;
  bool _hasPayPwd = true;
  String _realName = '';
  List<Map<String, dynamic>> _bankList = [];
  String _selectedBankCode = '';
  String _selectedBankName = '';
  String _selectedBankShort = '';

  @override
  void initState() {
    super.initState();
    _loadBankList();
    _loadSecurityStatus();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _holderController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityStatus() async {
    try {
      final resp = await ApiClient().get('/user/security/status');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1 && data['data'] is Map) {
          final payload = data['data'] as Map;
          final verifiedValue = payload['verified'] ?? payload['is_verified'];
          final verified = verifiedValue == true ||
              verifiedValue == 1 ||
              verifiedValue == '1';
          final realName = payload['real_name']?.toString() ?? '';
          _isVerified = verified;
          _realName = realName;
          _hasPayPwd = payload['has_pay_pwd'] == true;
          if (_isVerified && _realName.isNotEmpty) {
            _holderController.text = _realName;
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadBankList() async {
    if (_isBankLoading) return;
    setState(() => _isBankLoading = true);
    try {
      final banks = await PaymentServices.getBankList();
      if (!mounted) return;
      setState(() {
        _bankList = banks;
        if (_selectedBankCode.isNotEmpty &&
            !_bankList
                .any((bank) => _resolveBankCode(bank) == _selectedBankCode)) {
          _selectedBankCode = '';
        }
      });
    } catch (_) {
      Get.snackbar('tip'.tr, 'getBankListFailed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isBankLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              _buildBankSelector(),
              const SizedBox(height: 12),
              _buildCardNumberInput(),
              const SizedBox(height: 12),
              _buildHolderInput(),
              if (!_hasPayPwd) ...[
                const SizedBox(height: 12),
                _buildPayPasswordCard(),
              ],
              const SizedBox(height: 12),
              _buildDefaultSwitch(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppBackButton(
              onPressed: () => Get.back(),
            ),
          ),
          Text(
            'addBankCardTitle'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankSelector() {
    return InkWell(
      onTap: _openBankSelector,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedBankName.isEmpty ? 'bankName'.tr : _selectedBankName,
                style: TextStyle(
                  color: _selectedBankName.isEmpty
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white,
                ),
              ),
            ),
            if (_isBankLoading)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Future<void> _openBankSelector() async {
    final result = await Get.toNamed(Routes.BANK_SELECTOR);
    if (result is Map) {
      final code = result['bank_code']?.toString() ?? '';
      final name = result['bank_name']?.toString() ?? '';
      final short = result['bank_short']?.toString() ?? '';
      setState(() {
        _selectedBankCode = code;
        _selectedBankName = name;
        _selectedBankShort = short;
      });
    }
  }

  Widget _buildCardNumberInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _cardNumberController,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'bankCardNumber'.tr,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildHolderInput() {
    final holderLocked = _isVerified && _realName.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _holderController,
        enabled: !holderLocked,
        style: TextStyle(
          color: Colors.white.withValues(alpha: holderLocked ? 0.7 : 1),
        ),
        decoration: InputDecoration(
          hintText: 'cardholderName'.tr,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPayPasswordCard() {
    return InkWell(
      onTap: () async {
        final result = await Get.toNamed(
          Routes.PAY_PASSWORD,
          arguments: {'hasPayPwd': _hasPayPwd},
        );
        if (result == true) {
          _loadSecurityStatus();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF6F55FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6F55FF).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFF8A6CFF), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'payPasswordSetTitle'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'setDefaultAddress'.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _isDefault,
            activeThumbColor: const Color(0xFF34C759),
            activeTrackColor: const Color(0xFF23362C),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            onChanged: (val) => setState(() => _isDefault = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F55FF),
        foregroundColor: Colors.white,
        // 14 是按钮的高度 6是按钮的宽度
        // 14 + 6 = 20 是按钮的总宽度
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text('button_submit'.tr),
    );
  }

  void _handleSubmit() {
    final bankName = _selectedBankName.trim();
    final cardNumber = _cardNumberController.text.trim();
    final holder = _holderController.text.trim();
    if (_selectedBankCode.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseSelectBankCode'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (bankName.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterBankName'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (cardNumber.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterBankCardNumber'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (holder.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterCardholderName'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    _submit(bankName, cardNumber, holder);
  }

  Future<void> _submit(
      String bankName, String cardNumber, String holder) async {
    setState(() => _isLoading = true);
    final result = await PaymentServices.createBankCard(
      bankCode: _selectedBankCode,
      bankName: bankName,
      bankShortName: _selectedBankShort.trim(),
      cardNumber: cardNumber,
      holderName: holder,
      isDefault: _isDefault,
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
    final code = result['code'];
    final success =
        result['ok'] == true || code == 1 || code?.toString() == '1';
    if (success) {
      Get.back(result: true);
      return;
    }
    final msg = _resolveBankCardError(result['code'], result['msg']);
    Get.snackbar('tip'.tr, msg, snackPosition: SnackPosition.TOP);
  }

  String _resolveBankCode(Map<String, dynamic> bank) {
    return bank['bankNum']?.toString() ??
        bank['code']?.toString() ??
        bank['bank_code']?.toString() ??
        '';
  }

  String _resolveBankCardError(dynamic code, dynamic msg) {
    final parsedCode =
        code is int ? code : int.tryParse(code?.toString() ?? '');
    switch (parsedCode) {
      case 2101:
        return 'errorBankNotLogin'.tr;
      case 2102:
        return 'errorBankQueryUserFailed'.tr;
      case 2103:
        return 'errorBankPayPwdRequired'.tr;
      case 2104:
        return 'errorBankInfoIncomplete'.tr;
      case 2105:
        return 'errorBankQueryFailed'.tr;
      case 2106:
        return 'errorBankLimit'.tr;
      case 2107:
        return 'errorBankExists'.tr;
      case 2108:
        return 'errorBankAddFailed'.tr;
      case 2109:
        return 'errorBankNotFound'.tr;
      case 2110:
        return 'errorBankDeleteFailed'.tr;
      case 2111:
        return 'errorBankSetDefaultFailed'.tr;
      default:
        final serverMsg = (msg ?? '').toString().trim();
        return serverMsg.isEmpty ? 'networkError'.tr : serverMsg;
    }
  }
}
