import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';

class AccountSecurityView extends StatefulWidget {
  const AccountSecurityView({super.key});

  @override
  State<AccountSecurityView> createState() => _AccountSecurityViewState();
}

class _AccountSecurityViewState extends State<AccountSecurityView> {
  final ApiClient _apiClient = ApiClient();
  bool _loading = true;
  _AccountSecurityStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final resp = await _apiClient.get('/user/security/status');
      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data;
        if (data is Map && data['code'] == 1 && data['data'] is Map) {
          setState(() {
            _status = _AccountSecurityStatus.fromJson(
                Map<String, dynamic>.from(data['data']));
          });
        }
      }
    } catch (_) {
      // keep silent for now
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status ?? _AccountSecurityStatus.empty();
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
              else ...[
                _buildScoreCard(status),
                const SizedBox(height: 12),
                _buildSecurityList(status),
                const SizedBox(height: 16),
                _buildExitButton(),
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
            'accountSecurity'.tr,
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

  Widget _buildScoreCard(_AccountSecurityStatus status) {
    final score = status.score.clamp(0, 100);
    final percent = score / 100;
    final level = _resolveLevel(status.level);
    final shieldCount = ((score / 20).round()).clamp(0, 5);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'securityScore'.tr}: $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final active = index < shieldCount;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            active
                                ? Icons.shield_rounded
                                : Icons.shield_outlined,
                            size: 18,
                            color: active
                                ? const Color(0xFF7B6CFF)
                                : Colors.white38,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              _buildScoreGauge(percent, score),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoPair(
                  label: 'lastLoginIp'.tr,
                  value: status.lastLoginIp.isEmpty ? '--' : status.lastLoginIp,
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              Expanded(
                child: _InfoPair(
                  label: 'lastLoginTime'.tr,
                  value: status.lastLoginAt.isEmpty ? '--' : status.lastLoginAt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGauge(double percent, int score) {
    final gaugeColor = _resolveGaugeColor(percent);
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
          ),
          Text(
            '${score.clamp(0, 100)}%',
            style: TextStyle(
              color: gaugeColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _resolveGaugeColor(double percent) {
    if (percent >= 0.8) {
      return const Color(0xFF37D17C);
    }
    if (percent >= 0.5) {
      return const Color(0xFFFFC107);
    }
    return const Color(0xFFFF8A3D);
  }

  Widget _buildSecurityList(_AccountSecurityStatus status) {
    final items = [
      _SecurityItem(
        icon: Icons.verified_user,
        label: 'verifyRealName'.tr,
        checked: status.verified,
        onTap: () async {
          final result = await Get.toNamed(
            Routes.REAL_NAME,
            arguments: {
              'verified': status.verified,
              'real_name': status.realName,
            },
          );
          if (result == true) {
            _loadStatus();
          }
        },
      ),
      _SecurityItem(
        icon: Icons.phone_android,
        label: 'bindPhone'.tr,
        checked: status.bindPhone,
      ),
      _SecurityItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'bindWithdrawAccount'.tr,
        checked: status.bindWithdrawAccount,
        hint: status.bindWithdrawAccount ? '' : 'completeBankReward'.tr,
        onTap: () => Get.toNamed(Routes.ACCOUNT_MANAGEMENT),
      ),
      _SecurityItem(
        icon: Icons.email_outlined,
        label: 'bindEmail'.tr,
        checked: status.bindEmail,
      ),
      _SecurityItem(
        icon: Icons.lock_outline,
        label: 'transactionPassword'.tr,
        checked: status.hasPayPwd,
        onTap: () async {
          final result = await Get.toNamed(
            Routes.PAY_PASSWORD,
            arguments: {'hasPayPwd': status.hasPayPwd},
          );
          if (result == true) {
            _loadStatus();
          }
        },
      ),
      _SecurityItem(
        icon: Icons.lock,
        label: 'loginPassword'.tr,
        checked: status.hasLoginPwd,
        onTap: () async {
          final result = await Get.toNamed(
            Routes.LOGIN_PASSWORD,
            arguments: {'hasLoginPwd': status.hasLoginPwd},
          );
          if (result == true) {
            _loadStatus();
          }
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: items
            .map((item) => Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F55FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF6F55FF)
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Icon(item.icon,
                            color: const Color(0xFF8A6CFF), size: 20),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.hint.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.hint,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.checked)
                            const Icon(Icons.check_circle,
                                color: Color(0xFF4CD964), size: 18),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right,
                              color: Colors.white70),
                        ],
                      ),
                      onTap: item.onTap,
                    ),
                    if (item != items.last)
                      Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                  ],
                ))
            .toList(),
      ),
    );
  }

  Widget _buildExitButton() {
    return Obx(() {
      final auth = Get.isRegistered<AuthController>()
          ? Get.find<AuthController>()
          : null;
      if (auth == null || !auth.isLoggedIn.value) {
        return const SizedBox.shrink();
      }
      return ElevatedButton(
        onPressed: () => auth.logout(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEB5757),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'exitAccount'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    });
  }

  String _resolveLevel(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'low':
        return 'securityLevelLow'.tr;
      case 'high':
        return 'securityLevelHigh'.tr;
      case 'medium':
      default:
        return 'securityLevelMedium'.tr;
    }
  }
}

class _InfoPair extends StatelessWidget {
  const _InfoPair({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SecurityItem {
  const _SecurityItem({
    required this.icon,
    required this.label,
    required this.checked,
    this.hint = '',
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool checked;
  final String hint;
  final VoidCallback? onTap;
}


class _AccountSecurityStatus {
  const _AccountSecurityStatus({
    required this.score,
    required this.level,
    required this.lastLoginIp,
    required this.lastLoginAt,
    required this.realName,
    required this.verified,
    required this.bindPhone,
    required this.bindEmail,
    required this.bindWithdrawAccount,
    required this.hasPayPwd,
    required this.hasLoginPwd,
    required this.hasBankCard,
    required this.hasCryptoAddress,
  });

  final int score;
  final String level;
  final String lastLoginIp;
  final String lastLoginAt;
  final String realName;
  final bool verified;
  final bool bindPhone;
  final bool bindEmail;
  final bool bindWithdrawAccount;
  final bool hasPayPwd;
  final bool hasLoginPwd;
  final bool hasBankCard;
  final bool hasCryptoAddress;

  factory _AccountSecurityStatus.empty() {
    return const _AccountSecurityStatus(
      score: 0,
      level: 'medium',
      lastLoginIp: '',
      lastLoginAt: '',
      realName: '',
      verified: false,
      bindPhone: false,
      bindEmail: false,
      bindWithdrawAccount: false,
      hasPayPwd: false,
      hasLoginPwd: false,
      hasBankCard: false,
      hasCryptoAddress: false,
    );
  }

  factory _AccountSecurityStatus.fromJson(Map<String, dynamic> json) {
    final phone = json['phone']?.toString() ?? '';
    final email = json['email']?.toString() ?? '';
    final bankCards = json['bank_cards'];
    final cryptoAddresses = json['crypto_addresses'];
    final verifiedValue = json['verified'] ?? json['is_verified'];
    final realName = json['real_name']?.toString() ?? '';
    final verifiedFlag = verifiedValue == true ||
        verifiedValue == 1 ||
        verifiedValue == '1';
    final verified = verifiedFlag && realName.isNotEmpty;
    return _AccountSecurityStatus(
      score: _toInt(json['score']),
      level: json['level']?.toString() ?? 'medium',
      lastLoginIp: json['last_login_ip']?.toString() ?? '',
      lastLoginAt: _formatTimeValue(json['last_login_at']),
      realName: realName,
      verified: verified,
      bindPhone: phone.isNotEmpty,
      bindEmail: email.isNotEmpty,
      bindWithdrawAccount: json['bind_withdraw_account'] == true,
      hasPayPwd: json['has_pay_pwd'] == true,
      hasLoginPwd: json['has_login_pwd'] == true,
      hasBankCard: bankCards is List && bankCards.isNotEmpty,
      hasCryptoAddress: cryptoAddresses is List && cryptoAddresses.isNotEmpty,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatTimeValue(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return _formatMillis(value);
    }
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    final asNum = num.tryParse(text);
    if (asNum != null) {
      return _formatMillis(asNum);
    }
    final normalized = text.contains('T') ? text : text.replaceFirst(' ', 'T');
    final dt = DateTime.tryParse(normalized);
    if (dt == null) return text;
    return _formatDateTime(dt);
  }

  static String _formatMillis(num value) {
    final ms = value > 100000000000 ? value : value * 1000;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
    return _formatDateTime(dt);
  }

  static String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}
