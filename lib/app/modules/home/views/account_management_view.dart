import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/routes/app_pages.dart';

class AccountManagementView extends StatefulWidget {
  const AccountManagementView({super.key});

  @override
  State<AccountManagementView> createState() => _AccountManagementViewState();
}

class _AccountManagementViewState extends State<AccountManagementView> {
  bool _loading = true;
  List<dynamic> _bankCards = [];
  List<dynamic> _cryptoAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final resp = await ApiClient().get('/user/pay/withdraw/accounts');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1 && data['data'] is Map) {
          final payload = data['data'] as Map;
          final banks = payload['bank_cards'];
          final cryptos = payload['crypto_addresses'];
          _bankCards = banks is List ? banks : [];
          _cryptoAddresses = cryptos is List ? cryptos : [];
        }
      }
    } catch (_) {
      // ignore
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
              else
                Column(
                  children: [
                    _AccountTile(
                      iconPath: 'assets/images/rpicon.png',
                      label: 'bankCard'.tr,
                      subtitle: 'boundAccountCount'.trParams({
                        'count': _bankCards.length.toString(),
                      }),
                      onTap: () => Get.toNamed(
                        Routes.BANK_CARD,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AccountTile(
                      iconPath: 'assets/images/usdttrc20icon.png',
                      label: 'cryptoAddress'.tr,
                      subtitle: 'boundAddressCount'.trParams({
                        'count': _cryptoAddresses.length.toString(),
                      }),
                      onTap: () => Get.toNamed(
                        Routes.CRYPTO_ADDRESS,
                      ),
                    ),
                  ],
                ),
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
            'accountManagement'.tr,
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
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.iconPath,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final String iconPath;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  iconPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
