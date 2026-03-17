import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/userServices.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RechargeTab extends StatefulWidget {
  const RechargeTab({super.key, required this.auth});

  final AuthController auth;

  @override
  State<RechargeTab> createState() => _RechargeTabState();
}

class _RechargeTabState extends State<RechargeTab> {
  final HomeController _home = Get.find<HomeController>();
  final AppInfoService _appInfo = Get.find<AppInfoService>();
  _DepositPayMethod _selectedPayMethod = _DepositPayMethod.idr;
  final TextEditingController _usdtAmountController = TextEditingController();
  double? _usdtRate;
  String? _usdtRateRaw;
  bool _isRateLoading = false;
  List<String> get _quickAmounts => _appInfo.depositAmountOptions.isNotEmpty
      ? _appInfo.depositAmountOptions
      : AppConfig.defaultDepositAmounts;
  List<String> get _formattedAmounts =>
      _quickAmounts.map((e) => _formatAmount(e)).toList();
  String? _selectedAmount;
  bool _hasUserSelected = false;
  bool _isSubmitting = false;
  late final Worker _depositAmountsWorker;

  @override
  void initState() {
    super.initState();
    _setDefaultSelectedAmount();
    _depositAmountsWorker = ever<List<String>>(
      _appInfo.depositAmountOptions,
      (_) => _setDefaultSelectedAmount(notify: true),
    );
    _usdtAmountController.addListener(_handleUsdtAmountChange);
  }

  @override
  void dispose() {
    _usdtAmountController.dispose();
    _depositAmountsWorker.dispose();
    super.dispose();
  }

  void _handleUsdtAmountChange() {
    if (!mounted) return;
    setState(() {});
  }

  void _setDefaultSelectedAmount({bool notify = false}) {
    if (_hasUserSelected) return;
    final options = _quickAmounts;
    if (options.isEmpty) return;
    final defaultAmount = options.length >= 2 ? options[1] : options.first;
    if (_selectedAmount == defaultAmount) return;
    if (notify) {
      setState(() {
        _selectedAmount = defaultAmount;
      });
    } else {
      _selectedAmount = defaultAmount;
    }
  }

  Future<void> _handleQuickAmount(String value) async {
    setState(() {
      _hasUserSelected = true;
      _selectedAmount = value;
    });
  }

  Future<void> _submit() async {
    if (_selectedPayMethod == _DepositPayMethod.usdtTrc20) {
      await _submitUsdt();
      return;
    }
    await _submitIdr();
  }

  Future<void> _submitIdr() async {
    if (_isSubmitting) return;
    final ok = await widget.auth.ensureAuthenticated(context);
    if (!ok) return;

    final amount = _selectedAmount ?? '';
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      Get.snackbar('tip'.tr, 'pleaseSelectAmount'.tr);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userInfo = await UserServices.getUserInfo();
      final account = userInfo['account']?.toString() ?? '';
      final nickname = userInfo['nickname']?.toString() ?? '';
      final remark =
          '${_appInfo.appName.value}-${nickname.isNotEmpty ? nickname : account}';
      final result = await PaymentServices.deposit(
        amount: amount,
        remark: remark,
      );
      if (result.code == 200) {
        Get.snackbar('tip'.tr, 'depositSubmitted'.tr);
        final payUrl = result.data?.url ?? '';
        if (payUrl.isNotEmpty) {
          await _openPaymentUrl(payUrl);
        }
      } else {
        Get.snackbar('tip'.tr, result.msg ?? 'depositFailed'.tr);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitUsdt() async {
    if (_isSubmitting) return;
    final ok = await widget.auth.ensureAuthenticated(context);
    if (!ok) return;

    final rawAmount = _usdtAmountController.text.trim();
    final amountValue = int.tryParse(rawAmount);
    if (amountValue == null) {
      Get.snackbar('tip'.tr, 'pleaseEnterUsdtAmount'.tr);
      return;
    }
    if (amountValue < 10 || amountValue > 9999999) {
      Get.snackbar('tip'.tr, 'usdtAmountRange'.tr);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await PaymentServices.cryptoDeposit(
        chain: 'trc20',
        amount: rawAmount,
      );
      final code = result['code'];
      if (code == 200 || code == 1) {
        final data = result['data'];
        if (data is Map && data['url'] != null) {
          final payUrl = data['url']?.toString() ?? '';
          if (payUrl.isNotEmpty) {
            await _openPaymentUrl(payUrl);
          }
        }
        if (data is Map) {
          _showUsdtDepositSheet(
            orderNo: data['order_no']?.toString() ?? '',
            address: data['address']?.toString() ?? '',
            amount: data['amount']?.toString() ?? rawAmount,
            createdAt: data['created_at'],
            expireMinutes: data['expire_minutes'],
          );
        }
      } else {
        Get.snackbar('tip'.tr, result['msg']?.toString() ?? 'depositFailed'.tr);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _fetchUsdtRate() async {
    if (_isRateLoading) return;
    setState(() => _isRateLoading = true);
    try {
      final value = await PaymentServices.getConfigValue(
        'rate_usdt_to_fiat_deposit',
      );
      final parsed = double.tryParse(value ?? '');
      if (!mounted) return;
      setState(() {
        _usdtRate = parsed;
        _usdtRateRaw = value;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _usdtRate = null;
          _usdtRateRaw = null;
        });
      }
      Get.snackbar('tip'.tr, 'getConfigFailed'.tr);
    } finally {
      if (mounted) {
        setState(() => _isRateLoading = false);
      }
    }
  }

  void _selectPayMethod(_DepositPayMethod method) {
    if (_selectedPayMethod == method) return;
    setState(() => _selectedPayMethod = method);
    if (method == _DepositPayMethod.usdtTrc20 && _usdtRate == null) {
      _fetchUsdtRate();
    }
  }

  Future<void> _openPaymentUrl(String url) async {
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


  void _showUsdtDepositSheet({
    required String orderNo,
    required String address,
    required String amount,
    required dynamic createdAt,
    required dynamic expireMinutes,
  }) {
    if (address.isEmpty && amount.isEmpty) return;
    Get.bottomSheet(
      _UsdtDepositSheet(
        orderNo: orderNo,
        address: address,
        amount: amount,
        createdAt: createdAt,
        expireMinutes: expireMinutes,
      ),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 12),
                    _buildPaymentMethods(context),
                    const SizedBox(height: 12),
                    if (_selectedPayMethod == _DepositPayMethod.idr)
                      _buildQuickAmounts(context)
                    else
                      _buildUsdtForm(context),
                    const SizedBox(height: 16),
                    _buildSubmitButton(context),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _BalanceBadge(
          onRefresh: _home.refreshBalance,
          balance: _home.balance,
          refreshing: _home.isRefreshingBalance,
        ),
        Text(
          'deposit'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        _OutlineRecordButton(),
      ],
    );
  }

  Widget _buildQuickAmounts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'depositAmount'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _quickAmounts.asMap().entries.map((entry) {
              final amount = entry.value;
              final display = _formattedAmounts[entry.key];
              final selected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () => _handleQuickAmount(amount),
                child: IntrinsicWidth(
                  //自适应宽度
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF8A6CFF)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF8A6CFF)
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        display,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '${'selectedDepositAmount'.tr}${_selectedAmount != null ? '${AppConfig.currencySymbol()} ${_formatAmount(_selectedAmount!)}' : '--'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsdtForm(BuildContext context) {
    final rateText = _buildUsdtRateText();
    final estimatedText = _buildUsdtEstimatedText();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'usdtAmount'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _usdtAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(7),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'usdtAmountHint'.tr,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              prefixText: 'USDT ',
              prefixStyle: const TextStyle(
                color: Color(0xFF8A6CFF),
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'usdtAmountRange'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'exchangeRate'.tr, value: rateText),
          const SizedBox(height: 6),
          _InfoRow(label: 'estimatedArrival'.tr, value: estimatedText),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final available = constraints.maxWidth - 10;
              final itemWidth = (available / 2).clamp(70.0, 80.0);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _PaymentMethodCard(
                    width: itemWidth,
                    iconPath: 'assets/images/rpicon.png',
                    label: 'payMethodIdr'.tr,
                    selected: _selectedPayMethod == _DepositPayMethod.idr,
                    onTap: () => _selectPayMethod(_DepositPayMethod.idr),
                  ),
                  _PaymentMethodCard(
                    width: itemWidth,
                    iconPath: 'assets/images/usdttrc20icon.png',
                    label: 'payMethodUsdtTrc20'.tr,
                    selected: _selectedPayMethod == _DepositPayMethod.usdtTrc20,
                    onTap: () => _selectPayMethod(_DepositPayMethod.usdtTrc20),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 260,
              minWidth: 180,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B4CFF), Color(0xFF2F245D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'confirmDeposit'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'depositIssueTip'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: widget.auth.openCustomerService,
              child: Text(
                'manualCustomerService'.tr,
                style: const TextStyle(
                  color: Color(0xFF8A6CFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'resolve'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buildUsdtRateText() {
    if (_isRateLoading) return 'processing'.tr;
    final rateValue = _usdtRate ?? double.tryParse(_usdtRateRaw ?? '');
    if (rateValue == null) return '--';
    final formatted = _formatAmount(rateValue.toString());
    return '1 USDT = ${AppConfig.currencySymbol()} $formatted';
  }

  String _buildUsdtEstimatedText() {
    final rawAmount = _usdtAmountController.text.trim();
    if (rawAmount.isEmpty) {
      return '${AppConfig.currencySymbol()} 0';
    }
    final amountValue = int.tryParse(rawAmount);
    final rateValue = _usdtRate ?? double.tryParse(_usdtRateRaw ?? '');
    if (amountValue == null || rateValue == null) return '--';
    final estimated = amountValue * rateValue;
    return '${AppConfig.currencySymbol()} ${_formatAmount(estimated.toString())}';
  }

  String _formatAmount(String value) {
    final numValue = num.tryParse(value);
    if (numValue == null) return value;
    final parts = numValue.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    final intPartWithComma = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return intPartWithComma;
  }
}

enum _DepositPayMethod {
  idr,
  usdtTrc20,
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.width,
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String iconPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF8A6CFF)
        : Colors.white.withValues(alpha: 0.1);
    final bgColor = selected
        ? const Color(0xFF8A6CFF).withValues(alpha: 0.2)
        : Colors.white.withValues(alpha: 0.04);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: width,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                iconPath,
                width: (width * 0.5).clamp(34.0, 52.0).toDouble(),
                height: (width * 0.5).clamp(34.0, 52.0).toDouble(),
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  const _BalanceBadge({
    required this.onRefresh,
    required this.balance,
    this.refreshing,
  });

  final VoidCallback onRefresh;
  final RxString balance;
  final RxBool? refreshing;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = refreshing?.value ?? false;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF222732),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppConfig.currencySymbol(),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              balance.value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRefresh,
              child: AnimatedRotation(
                turns: isLoading ? 1 : 0,
                duration: const Duration(milliseconds: 700),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Color(0xFFF1A64C),
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _UsdtDepositSheet extends StatefulWidget {
  const _UsdtDepositSheet({
    required this.orderNo,
    required this.address,
    required this.amount,
    required this.createdAt,
    required this.expireMinutes,
  });

  final String orderNo;
  final String address;
  final String amount;
  final dynamic createdAt;
  final dynamic expireMinutes;

  @override
  State<_UsdtDepositSheet> createState() => _UsdtDepositSheetState();
}

class _UsdtDepositSheetState extends State<_UsdtDepositSheet> {
  Timer? _timer;
  DateTime? _expireAt;
  DateTime? _createdAt;
  Duration _remaining = Duration.zero;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _createdAt = _parseCreatedAt(widget.createdAt);
    _expireAt = _computeExpireAt(_createdAt, widget.expireMinutes);
    _tick();
    if (_expireAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _parseCreatedAt(dynamic createdAt) {
    final ts = _toInt(createdAt);
    if (ts == null) return null;
    return _fromEpoch(ts);
  }

  DateTime? _computeExpireAt(DateTime? createdAt, dynamic expireMinutes) {
    final minutes = _toInt(expireMinutes);
    if (minutes == null || createdAt == null) return null;
    return createdAt.add(Duration(minutes: minutes));
  }

  DateTime _fromEpoch(int ts) {
    final isMs = ts > 1000000000000;
    final ms = isMs ? ts : ts * 1000;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  void _tick() {
    if (_expireAt == null) return;
    final now = DateTime.now();
    final diff = _expireAt!.difference(now);
    if (!mounted) return;
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
    if (_remaining == Duration.zero) {
      _timer?.cancel();
    }
  }

  String _formatRemaining(Duration duration) {
    final totalSeconds = duration.inSeconds;
    if (totalSeconds <= 0) return '00:00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _formatCreatedAtFull() {
    if (_createdAt == null) return '--';
    final value = _createdAt!;
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final amountText =
        widget.amount.isNotEmpty ? widget.amount : '--';
    final canCopy = widget.address.isNotEmpty;
    final canCancel = widget.orderNo.isNotEmpty && !_isCanceling;
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'usdtDepositTitle'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 12),
              if (widget.orderNo.isNotEmpty)
                _InfoRow(label: 'orderNumber'.tr, value: widget.orderNo),
              const SizedBox(height: 8),
              _InfoRow(label: 'usdtAmount'.tr, value: amountText),
              const SizedBox(height: 8),
              _InfoRow(
                label: 'createdAt'.tr,
                value: _formatCreatedAtFull(),
              ),
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: widget.address.isNotEmpty ? widget.address : ' ',
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${'chainType'.tr}: TRC20',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  _expireAt == null
                      ? 'payWithinTime'.tr
                      : '${'payWithinTime'.tr} (${_formatRemaining(_remaining)})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFF5B5B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'depositAddress'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.address.isNotEmpty ? widget.address : '--',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: canCopy
                          ? () async {
                              await Clipboard.setData(
                                ClipboardData(text: widget.address),
                              );
                              Get.snackbar('tip'.tr, 'copied'.tr);
                            }
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8A6CFF),
                      ),
                      child: Text('copyAddress'.tr),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: canCancel
                            ? () async {
                                setState(() => _isCanceling = true);
                                try {
                                  await PaymentServices.cancelCryptoDeposit(
                                    orderNo: widget.orderNo,
                                  );
                                } catch (_) {}
                                if (mounted) {
                                  setState(() => _isCanceling = false);
                                  Get.back();
                                }
                              }
                            : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isCanceling
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text('cancelPayment'.tr),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A6CFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('confirmPayment'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineRecordButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => Get.toNamed(Routes.TRANSACTION_HISTORY),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFDF9C4D), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        foregroundColor: const Color(0xFFDF9C4D),
      ),
      child: Text(
        'transactionHistory'.tr,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
