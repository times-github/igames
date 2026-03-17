import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config_export.dart';

class CryptoAddressAddView extends StatefulWidget {
  const CryptoAddressAddView({super.key});

  @override
  State<CryptoAddressAddView> createState() => _CryptoAddressAddViewState();
}

class _CryptoAddressAddViewState extends State<CryptoAddressAddView> {
  final TextEditingController _addressController = TextEditingController();
  bool _isDefault = true;
  String _chain = 'TRC20';
  bool _hasPayPwd = true;
  bool _statusLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityStatus() async {
    try {
      final resp = await ApiClient().get('/user/security/status');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1 && data['data'] is Map) {
          final payload = data['data'] as Map;
          _hasPayPwd = payload['has_pay_pwd'] == true;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _statusLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 12),
              _buildPrivacyTip(),
              const SizedBox(height: 12),
              _buildProtocolCard(),
              const SizedBox(height: 12),
              _buildAddressInput(),
              const SizedBox(height: 12),
              _buildDefaultSwitch(),
              if (!_statusLoading && !_hasPayPwd) ...[
                const SizedBox(height: 12),
                _buildPayPasswordCard(),
              ],
              const SizedBox(height: 20),
              _buildSubmitButton(),
              const SizedBox(height: 12),
              _buildHelpText(),
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
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
            ),
          ),
          Text(
            'addCryptoAddressTitle'.tr,
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

  Widget _buildPrivacyTip() {
    return Text(
      'cryptoAddressPrivacyTip'.tr,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 12,
      ),
    );
  }

  Widget _buildProtocolCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'cryptoAddressProtocol'.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildChainChip(),
        ],
      ),
    );
  }

  Widget _buildChainChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B4CFF)),
        color: const Color(0xFF2C2548),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _chain,
            style: const TextStyle(
              color: Color(0xFFBFA6FF),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.check, size: 14, color: Color(0xFFBFA6FF)),
        ],
      ),
    );
  }

  Widget _buildAddressInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _addressController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'cryptoAddressPlaceholder'.tr,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDefaultSwitch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
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
            activeColor: const Color(0xFF34C759),
            activeTrackColor: const Color(0xFF23362C),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
            onChanged: (val) => setState(() => _isDefault = val),
          ),
        ],
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
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF6F55FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF6F55FF).withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(Icons.lock_outline,
                  color: Color(0xFF8A6CFF), size: 18),
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

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F55FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text('button_submit'.tr),
    );
  }

  Widget _buildHelpText() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          children: [
            TextSpan(text: 'needHelp'.tr),
            const TextSpan(text: ' '),
            TextSpan(
              text: 'contactCustomerService'.tr,
              style: const TextStyle(color: Color(0xFF8A6CFF)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterCryptoAddress'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    if (address.length < 10 || address.length > 128) {
      Get.snackbar('tip'.tr, 'cryptoAddressLength'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    _submit(address);
  }

  Future<void> _submit(String address) async {
    final result = await PaymentServices.createCryptoWithdrawAddress(
      address: address,
      isDefault: _isDefault,
    );
    final ok = result['ok'] == true;
    if (ok) {
      Get.back(result: true);
      return;
    }
    Get.snackbar(
      'tip'.tr,
      _resolveCreateAddressError(result['code'], result['msg']),
      snackPosition: SnackPosition.TOP,
    );
  }

  String _resolveCreateAddressError(dynamic code, dynamic msg) {
    final parsedCode = code is int ? code : int.tryParse(code?.toString() ?? '');
    switch (parsedCode) {
      case 2001:
        return 'errorNotLogin'.tr;
      case 2002:
        return 'errorAddressFormat'.tr;
      case 2003:
        return 'errorQueryAddressFailed'.tr;
      case 2004:
        return 'errorAddressExists'.tr;
      case 2005:
        return 'errorAddAddressFailed'.tr;
      case 2006:
        return 'errorAddressLimit'.tr;
      case 2007:
        return 'errorPayPwdRequired'.tr;
      default:
        final serverMsg = (msg ?? '').toString().trim();
        return serverMsg.isEmpty ? 'networkError'.tr : serverMsg;
    }
  }
}
