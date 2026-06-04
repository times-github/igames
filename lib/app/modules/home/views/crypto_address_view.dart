import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/routes/app_pages.dart';

class CryptoAddressView extends StatefulWidget {
  const CryptoAddressView({super.key});

  @override
  State<CryptoAddressView> createState() => _CryptoAddressViewState();
}

class _CryptoAddressViewState extends State<CryptoAddressView> {
  bool _loading = true;
  final List<Map<String, dynamic>> _addresses = [];
  static const int _maxCount = 3;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final crypto = args is Map ? args['crypto_addresses'] : null;
    if (crypto is List) {
      _addresses
        ..clear()
        ..addAll(crypto
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)));
      _loading = false;
    } else {
      _loadAddresses();
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final result = await PaymentServices.getWithdrawAccounts();
      final crypto = result['crypto_addresses'];
      _addresses
        ..clear()
        ..addAll(crypto is List ? List<Map<String, dynamic>>.from(crypto) : []);
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) {
        setState(() => _loading = false);
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
              const SizedBox(height: 16),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                )
              else if (_addresses.isEmpty) ...[
                _buildEmptyState(),
                const SizedBox(height: 16),
                _buildAddButton(),
                const SizedBox(height: 10),
                _buildHintText(),
              ] else ...[
                _buildCountRow(),
                const SizedBox(height: 12),
                ..._addresses.map(_buildAddressCard).toList(),
                const SizedBox(height: 16),
                _buildAddButton(),
              ],
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
            'cryptoManagement'.tr,
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

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Icon(Icons.account_balance_wallet_outlined,
            size: 72, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text(
          'noCryptoAddress'.tr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCountRow() {
    return Text(
      'cryptoAddressCount'.trParams({
        'count': _addresses.length.toString(),
        'max': _maxCount.toString(),
      }),
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> item) {
    final token = (item['token'] ?? '').toString().toUpperCase();
    final chain = (item['chain'] ?? '').toString().toUpperCase();
    final address = (item['address'] ?? '').toString();
    final isDefault = item['is_default'] == true;
    final id = item['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4478FF), Color(0xFF2E4FAF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset('assets/images/usdttrc20icon.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  token.isEmpty
                      ? 'cryptoAddress'.tr
                      : '$token (${chain.isEmpty ? 'TRC20' : chain})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'defaultLabel'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: () => _setDefault(id),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'setDefault'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            address.isEmpty ? '--' : address,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _confirmUnbind(id),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('unbind'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _addresses.length >= _maxCount
          ? null
          : () async {
              final result = await Get.toNamed(Routes.CRYPTO_ADDRESS_ADD);
              if (result == true) {
                _loading = true;
                if (mounted) setState(() {});
                await _loadAddresses();
              }
            },
      icon: const Icon(Icons.add, size: 18),
      label: Text('addCryptoAddress'.tr),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F55FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildHintText() {
    return Text(
      'cryptoAddressHint'.tr,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 11,
      ),
    );
  }

  String _maskAddress(String raw) {
    if (raw.isEmpty) return '--';
    if (raw.length <= 6) return raw;
    final tail = raw.substring(raw.length - 4);
    return '**** **** **** $tail';
  }

  Future<void> _confirmUnbind(dynamic id) async {
    if (id == null) return;
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1C1E2B),
        title: Text('unbind'.tr, style: const TextStyle(color: Colors.white)),
        content: Text(
          'confirmUnbind'.tr,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('button_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('button_submit'.tr),
          ),
        ],
      ),
    );
    if (result != true) return;

    final ok = await PaymentServices.deleteCryptoWithdrawAddress(id);
    if (ok) {
      _addresses.removeWhere((item) => item['id'] == id);
      if (mounted) setState(() {});
    }
  }

  Future<void> _setDefault(dynamic id) async {
    if (id == null) return;
    final result = await PaymentServices.setCryptoWithdrawAddressDefault(id);
    if (result['ok'] == true) {
      for (final item in _addresses) {
        item['is_default'] = item['id'] == id;
      }
      if (mounted) setState(() {});
      return;
    }
    final msg = (result['msg'] ?? '').toString().trim();
    Get.snackbar('tip'.tr, msg.isEmpty ? 'networkError'.tr : msg,
        snackPosition: SnackPosition.TOP);
  }
}
