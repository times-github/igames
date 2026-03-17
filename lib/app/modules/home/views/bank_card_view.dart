import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';

class BankCardView extends StatefulWidget {
  const BankCardView({super.key});

  @override
  State<BankCardView> createState() => _BankCardViewState();
}

class _BankCardViewState extends State<BankCardView> {
  bool _loading = true;
  final List<Map<String, dynamic>> _cards = [];
  static const int _maxCount = 6;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final banks = args is Map ? args['bank_cards'] : null;
    if (banks is List) {
      _cards
        ..clear()
        ..addAll(
            banks.whereType<Map>().map((e) => Map<String, dynamic>.from(e)));
      _loading = false;
    } else {
      _loadCards();
    }
  }

  Future<void> _loadCards() async {
    try {
      final result = await PaymentServices.getWithdrawAccounts();
      final banks = result['bank_cards'];
      _cards
        ..clear()
        ..addAll(banks is List ? List<Map<String, dynamic>>.from(banks) : []);
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
      backgroundColor: AppColors.background,
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
              else if (_cards.isEmpty) ...[
                _buildEmptyState(),
                const SizedBox(height: 16),
                _buildAddButton(),
              ] else ...[
                _buildCountRow(),
                const SizedBox(height: 12),
                ..._cards.map(_buildCard).toList(),
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
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
            ),
          ),
          Text(
            'bankCardManagement'.tr,
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
        Icon(Icons.credit_card,
            size: 72, color: Colors.white.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        Text(
          'noBankCard'.tr,
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
      'bankCardCount'.trParams({
        'count': _cards.length.toString(),
        'max': _maxCount.toString(),
      }),
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final bankName = (item['bank_name'] ?? '').toString();
    final cardNumber = _resolveCardNumber(item);
    final holder = (item['holder_name'] ?? '').toString();
    final isDefault = item['is_default'] == true;
    final id = item['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3B55), Color(0xFF1A2232)],
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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.credit_card,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bankName.isEmpty ? 'bankCard'.tr : bankName,
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
            _maskCardNumber(cardNumber),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          if (holder.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              holder,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => _confirmDelete(id),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text('deleteBankCard'.tr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _cards.length >= _maxCount
          ? null
          : () async {
              final result = await Get.toNamed(Routes.BANK_CARD_ADD);
              if (result == true) {
                _loading = true;
                if (mounted) setState(() {});
                await _loadCards();
              }
            },
      icon: const Icon(Icons.add, size: 18),
      label: Text('addBankCard'.tr),
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

  String _maskCardNumber(String raw) {
    if (raw.isEmpty) return '--';
    if (raw.contains('*')) return raw;
    if (raw.length <= 6) return raw;
    final tail = raw.substring(raw.length - 4);
    return '**** **** **** $tail';
  }

  String _resolveCardNumber(Map<String, dynamic> item) {
    return item['card_number']?.toString() ??
        item['cardNumber']?.toString() ??
        item['card_no']?.toString() ??
        item['cardNo']?.toString() ??
        item['bank_card']?.toString() ??
        item['bankCard']?.toString() ??
        item['number']?.toString() ??
        item['account']?.toString() ??
        '';
  }

  Future<void> _confirmDelete(dynamic id) async {
    if (id == null) return;
    final result = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1C1E2B),
        title: Text('deleteBankCard'.tr,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          'confirmDeleteBankCard'.tr,
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

    final resultMap = await PaymentServices.deleteBankCard(id);
    if (resultMap['ok'] == true) {
      _cards.removeWhere((item) => item['id'] == id);
      if (mounted) setState(() {});
      return;
    }
    final msg = _resolveBankCardError(resultMap['code'], resultMap['msg']);
    Get.snackbar('tip'.tr, msg, snackPosition: SnackPosition.TOP);
  }

  Future<void> _setDefault(dynamic id) async {
    if (id == null) return;
    final result = await PaymentServices.setDefaultBankCard(id);
    if (result['ok'] == true) {
      for (final item in _cards) {
        item['is_default'] = item['id'] == id;
      }
      if (mounted) setState(() {});
      return;
    }
    final msg = _resolveBankCardError(result['code'], result['msg']);
    Get.snackbar('tip'.tr, msg, snackPosition: SnackPosition.TOP);
  }

  String _resolveBankCardError(dynamic code, dynamic msg) {
    final parsedCode = code is int ? code : int.tryParse(code?.toString() ?? '');
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
