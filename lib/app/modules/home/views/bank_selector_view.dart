import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/config/app_config_export.dart';

class BankSelectorView extends StatefulWidget {
  const BankSelectorView({super.key});

  @override
  State<BankSelectorView> createState() => _BankSelectorViewState();
}

class _BankSelectorViewState extends State<BankSelectorView> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    final args = Get.arguments;
    final banks = args is Map ? args['banks'] : null;
    if (banks is List && banks.isNotEmpty) {
      _banks = banks.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _filtered = List<Map<String, dynamic>>.from(_banks);
      _loading = false;
    } else {
      _loadBanks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks() async {
    try {
      final result = await PaymentServices.getBankList();
      _banks = result;
      _filtered = List<Map<String, dynamic>>.from(_banks);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _applyFilter() {
    final keyword = _searchController.text.trim().toLowerCase();
    if (keyword.isEmpty) {
      setState(() => _filtered = List<Map<String, dynamic>>.from(_banks));
      return;
    }
    final filtered = _banks.where((bank) {
      final name = _resolveBankName(bank).toLowerCase();
      final short = (bank['bankShort'] ?? '').toString().toLowerCase();
      final code = _resolveBankCode(bank).toLowerCase();
      return name.contains(keyword) ||
          short.contains(keyword) ||
          code.contains(keyword);
    }).toList();
    setState(() => _filtered = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildSearchBar(),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF7C3AED),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final bank = _filtered[index];
                        return _buildBankItem(bank);
                      },
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      itemCount: _filtered.length,
                    ),
            ),
          ],
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
            'bankSelectTitle'.tr,
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

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'bankSearchPlaceholder'.tr,
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                border: InputBorder.none,
                isDense: true,//
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _applyFilter,
          child: Text(
            'searchAction'.tr,
            style: const TextStyle(
              color: Color(0xFF8A6CFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankItem(Map<String, dynamic> bank) {
    final short = (bank['bankShort'] ?? '').toString();
    final name = _resolveBankName(bank);
    final code = _resolveBankCode(bank);
    return InkWell(
      onTap: () => Get.back(result: {
        'bank_code': code,
        'bank_name': name,
        'bank_short': short,
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? '--' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              short.isEmpty ? '--' : short,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 56,
              child: Text(
                code.isEmpty ? '--' : code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveBankCode(Map<String, dynamic> bank) {
    return bank['bankNum']?.toString() ??
        bank['code']?.toString() ??
        bank['bank_code']?.toString() ??
        '';
  }

  String _resolveBankName(Map<String, dynamic> bank) {
    return bank['bankName']?.toString() ??
        bank['bank_name']?.toString() ??
        bank['bankShort']?.toString() ??
        '';
  }
}
