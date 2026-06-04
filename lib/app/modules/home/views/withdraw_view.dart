import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/payment_services.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/modules/widgets/language_selector/controllers/language_selector_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/utils/storage.dart';
import 'package:igames/app/utils/user_status_error.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_config_export.dart';

class WithdrawView extends StatefulWidget {
  const WithdrawView({super.key});

  @override
  State<WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends State<WithdrawView> {
  final AuthController _auth = Get.find<AuthController>();
  final HomeController _home = Get.find<HomeController>();

  final TextEditingController _amountController = TextEditingController();
  late final FocusNode _amountFocusNode;

  bool _isLoading = false;
  bool _isStatusLoading = true;
  bool _hasBankCard = true;
  bool _hasCryptoAddress = true;
  List<Map<String, dynamic>> _bankCards = [];
  List<Map<String, dynamic>> _cryptoAddresses = [];
  Map<String, dynamic>? _selectedBankCard;
  Map<String, dynamic>? _selectedCryptoAddress;
  String _selectedBankCode = '';
  String _selectedCardNumber = '';
  String _selectedHolderName = '';
  String _selectedMobile = '';
  String _withdrawMinAmount = '';
  String _withdrawMaxAmount = '';
  String _amountRangeHint = '';
  bool _amountFocused = false;
  bool _isUsdtRateLoading = false;
  double? _usdtWithdrawRate;
  String? _usdtWithdrawRateRaw;
  _WithdrawMethod _selectedMethod = _WithdrawMethod.idr;

  @override
  void initState() {
    super.initState();
    _amountFocusNode = FocusNode()
      ..addListener(() {
        if (!mounted) return;
        setState(() => _amountFocused = _amountFocusNode.hasFocus);
      });
    _amountController.addListener(() {
      if (!mounted) return;
      if (_selectedMethod == _WithdrawMethod.usdtTrc20) {
        setState(() {});
      }
    });
    _loadSecurityStatus();
    _loadWithdrawConfig();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityStatus() async {
    await _refreshWithdrawAccounts(keepSelection: false);
    if (mounted) {
      setState(() => _isStatusLoading = false);
    }
  }

  Future<void> _refreshWithdrawAccounts({required bool keepSelection}) async {
    var bankCards = <Map<String, dynamic>>[];
    var cryptoList = <Map<String, dynamic>>[];
    var hasBankCard = false;
    var hasCryptoAddress = false;
    Map<String, dynamic>? selectedCard;
    Map<String, dynamic>? selectedCrypto;

    try {
      final data = await PaymentServices.getWithdrawAccounts();
      final rawCards = data['bank_cards'];
      if (rawCards is List) {
        for (final item in rawCards) {
          if (item is Map) {
            bankCards.add(Map<String, dynamic>.from(item));
          }
        }
      }
      final rawCrypto = data['crypto_addresses'];
      if (rawCrypto is List) {
        for (final item in rawCrypto) {
          if (item is Map) {
            cryptoList.add(Map<String, dynamic>.from(item));
          }
        }
      }
      hasBankCard = bankCards.isNotEmpty;
      hasCryptoAddress = cryptoList.isNotEmpty;
      if (bankCards.isNotEmpty) {
        if (keepSelection && _selectedBankCard != null) {
          final currentValue = _resolveCardValue(_selectedBankCard!);
          selectedCard = bankCards.firstWhere(
            (item) => _resolveCardValue(item) == currentValue,
            orElse: () => bankCards.first,
          );
        } else {
          selectedCard = bankCards.firstWhere(
            _isDefaultBankCard,
            orElse: () => bankCards.first,
          );
        }
      }
      if (cryptoList.isNotEmpty) {
        if (keepSelection && _selectedCryptoAddress != null) {
          final currentValue = _resolveCryptoId(_selectedCryptoAddress!);
          selectedCrypto = cryptoList.firstWhere(
            (item) => _resolveCryptoId(item) == currentValue,
            orElse: () => cryptoList.first,
          );
        } else {
          selectedCrypto = cryptoList.firstWhere(
            _isDefaultCryptoAddress,
            orElse: () => cryptoList.first,
          );
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() {
          _hasBankCard = hasBankCard;
          _hasCryptoAddress = hasCryptoAddress;
          _bankCards = bankCards;
          _cryptoAddresses = cryptoList;
          _selectedBankCard = selectedCard;
          _selectedCryptoAddress = selectedCrypto;
          _selectedBankCode = selectedCard == null
              ? ''
              : _resolveBankCodeFromCard(selectedCard);
          _selectedCardNumber =
              selectedCard == null ? '' : _resolveCardNumber(selectedCard);
          _selectedHolderName =
              selectedCard == null ? '' : _resolveCardHolderName(selectedCard);
          _selectedMobile = '';
        });
      }
    }
  }

  bool _isDefaultBankCard(Map<String, dynamic> card) {
    final flag = card['is_default'];
    return flag == true || flag == 1 || flag?.toString() == '1';
  }

  bool _isDefaultCryptoAddress(Map<String, dynamic> item) {
    final flag = item['is_default'];
    return flag == true || flag == 1 || flag?.toString() == '1';
  }

  String _resolveBankCodeFromCard(Map<String, dynamic>? card) {
    if (card == null) return '';
    return card['bank_code']?.toString() ??
        card['bankCode']?.toString() ??
        card['bankNum']?.toString() ??
        '';
  }

  String _resolveBankNameFromCard(Map<String, dynamic> card) {
    return card['bank_name']?.toString() ?? card['bankName']?.toString() ?? '';
  }

  String _resolveCardNumber(Map<String, dynamic>? card) {
    if (card == null) return '';
    return card['card_number']?.toString() ??
        card['cardNumber']?.toString() ??
        card['card_no']?.toString() ??
        card['cardNo']?.toString() ??
        card['bank_card']?.toString() ??
        card['bankCard']?.toString() ??
        card['number']?.toString() ??
        card['account']?.toString() ??
        '';
  }

  String _resolveCardHolderName(Map<String, dynamic>? card) {
    if (card == null) return '';
    return card['holder_name']?.toString() ??
        card['holderName']?.toString() ??
        '';
  }

  String _resolveCryptoAddress(Map<String, dynamic>? item) {
    if (item == null) return '';
    return item['address']?.toString() ?? item['addr']?.toString() ?? '';
  }

  String _resolveCryptoChain(Map<String, dynamic>? item) {
    if (item == null) return '';
    return item['chain']?.toString() ?? item['network']?.toString() ?? '';
  }

  String _resolveCryptoToken(Map<String, dynamic>? item) {
    if (item == null) return '';
    return item['token']?.toString() ?? item['coin']?.toString() ?? '';
  }

  String _resolveCryptoId(Map<String, dynamic>? item) {
    if (item == null) return '';
    final id = item['id'];
    return id == null ? '' : id.toString();
  }

  String _extractCardTail(String raw) {
    if (raw.isEmpty) return '';
    final digits =
        RegExp(r'\d').allMatches(raw).map((m) => m.group(0) ?? '').join();
    if (digits.isEmpty) return '';
    if (digits.length <= 4) return digits;
    return digits.substring(digits.length - 4);
  }

  String _extractAddressTail(String raw) {
    if (raw.isEmpty) return '';
    if (raw.length <= 4) return raw;
    return raw.substring(raw.length - 4);
  }

  String _resolveCardValue(Map<String, dynamic> card) {
    final id = card['id'];
    if (id != null) return id.toString();
    final code = _resolveBankCodeFromCard(card);
    final number = _resolveCardNumber(card);
    return '$code|$number';
  }

  void _fillAllAmount() {
    final raw = _home.balance.value;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return;
    _amountController.text = cleaned;
  }

  Future<void> _fetchUsdtWithdrawRate() async {
    if (_isUsdtRateLoading) return;
    setState(() => _isUsdtRateLoading = true);
    try {
      final lang = await _resolveLang();
      final resp = await ApiClient().get(
        '/user/config/rate_usdt_to_fiat_withdraw',
        queryParameters: {'lang': lang},
        withAuth: true,
      );
      String? value;
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1) {
          final inner = data['data'];
          if (inner is Map) {
            value =
                inner['value']?.toString() ?? inner['config_value']?.toString();
          } else {
            value = inner?.toString();
          }
        }
      }
      final parsed = double.tryParse(value ?? '');
      if (!mounted) return;
      setState(() {
        _usdtWithdrawRate = parsed;
        _usdtWithdrawRateRaw = value;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _usdtWithdrawRate = null;
          _usdtWithdrawRateRaw = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUsdtRateLoading = false);
      }
    }
  }

  Future<void> _loadWithdrawConfig() async {
    try {
      final lang = await _resolveLang();
      final resp = await ApiClient().get(
        '/user/config/withdraw_config',
        queryParameters: {'lang': lang},
        withAuth: true,
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1) {
          final value = _extractConfigMap(data);
          final minVal = value['min_amount'] ?? value['minAmount'];
          final maxVal = value['max_amount'] ?? value['maxAmount'];
          _withdrawMinAmount = minVal?.toString() ?? '';
          _withdrawMaxAmount = maxVal?.toString() ?? '';
          if (_withdrawMinAmount.isNotEmpty && _withdrawMaxAmount.isNotEmpty) {
            _amountRangeHint = '$_withdrawMinAmount-$_withdrawMaxAmount';
          } else if (_withdrawMinAmount.isNotEmpty) {
            _amountRangeHint = _withdrawMinAmount;
          } else if (_withdrawMaxAmount.isNotEmpty) {
            _amountRangeHint = _withdrawMaxAmount;
          }
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() {});
    }
  }

  Map<String, dynamic> _extractConfigMap(Map data) {
    final inner = data['data'];
    if (inner is Map) {
      final value = inner['value'] ?? inner['config_value'];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return Map<String, dynamic>.from(inner);
    }
    return {};
  }

  Future<String> _resolveLang() async {
    String lang = '';
    if (Get.isRegistered<LanguageSelectorController>()) {
      lang = Get.find<LanguageSelectorController>().currentCode.value;
    }
    if (lang.isEmpty) {
      final stored = await Storage.getData('language');
      if (stored is String) {
        lang = stored;
      }
    }
    if (lang.isEmpty) {
      lang = Get.locale?.languageCode ?? 'id';
    }
    return normalizeApiLang(lang);
  }

  String _composeBankCardTitle(Map<String, dynamic> card) {
    final name = _resolveBankNameFromCard(card);
    final tail = _extractCardTail(_resolveCardNumber(card));
    final tailLabel =
        tail.isEmpty ? '' : ' ${'bankCardTail'.trParams({'tail': tail})}';
    final label = name.isEmpty ? 'bankCard'.tr : name;
    return '$label$tailLabel';
  }

  String _composeCryptoAddressTitle(Map<String, dynamic> item) {
    final token = _resolveCryptoToken(item).toUpperCase();
    final chain = _resolveCryptoChain(item).toUpperCase();
    final address = _resolveCryptoAddress(item);
    final tail = _extractAddressTail(address);
    final tailLabel =
        tail.isEmpty ? '' : ' ${'bankCardTail'.trParams({'tail': tail})}';
    final tokenLabel = token.isEmpty ? 'USDT' : token;
    final chainLabel = chain.isEmpty ? 'TRC20' : chain;
    return '$tokenLabel/$chainLabel$tailLabel';
  }

  Future<void> _showBankCardSelector() async {
    await _refreshWithdrawAccounts(keepSelection: true);
    if (!mounted) return;
    Get.bottomSheet(_buildBankCardSelectorSheet());
  }

  Future<void> _showCryptoAddressSelector() async {
    await _refreshWithdrawAccounts(keepSelection: true);
    if (!mounted) return;
    Get.bottomSheet(_buildCryptoAddressSelectorSheet());
  }

  Widget _buildBankCardSelectorSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1E2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'selectBankCard'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              if (_bankCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'noBankCard'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                for (final card in _bankCards) _buildBankCardOption(card),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final result = await Get.toNamed(Routes.BANK_CARD_ADD);
                    if (result == true) {
                      await _refreshWithdrawAccounts(keepSelection: false);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('addBankCard'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCryptoAddressSelectorSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1E2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'selectWithdrawAddress'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),
              if (_cryptoAddresses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'noCryptoAddress'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                for (final item in _cryptoAddresses)
                  _buildCryptoAddressOption(item),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Get.back();
                    final result = await Get.toNamed(Routes.CRYPTO_ADDRESS_ADD);
                    if (result == true) {
                      await _refreshWithdrawAccounts(keepSelection: false);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text('addCryptoAddress'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankCardOption(Map<String, dynamic> card) {
    final value = _resolveCardValue(card);
    final selectedValue =
        _selectedBankCard == null ? '' : _resolveCardValue(_selectedBankCard!);
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBankCard = card;
          _selectedBankCode = _resolveBankCodeFromCard(card);
          _selectedCardNumber = _resolveCardNumber(card);
          _selectedHolderName = _resolveCardHolderName(card);
        });
        Get.back();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8A6CFF)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _composeBankCardTitle(card),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF8A6CFF), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoAddressOption(Map<String, dynamic> item) {
    final value = _resolveCryptoId(item);
    final selectedValue = _selectedCryptoAddress == null
        ? ''
        : _resolveCryptoId(_selectedCryptoAddress);
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCryptoAddress = item;
        });
        Get.back();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8A6CFF)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _composeCryptoAddressTitle(item),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF8A6CFF), size: 18),
          ],
        ),
      ),
    );
  }

  String _buildUsdtWithdrawRateText() {
    if (_isUsdtRateLoading) return 'processing'.tr;
    final rateValue =
        _usdtWithdrawRate ?? double.tryParse(_usdtWithdrawRateRaw ?? '');
    if (rateValue == null || rateValue <= 0) return '--';
    final formatted = _formatAmount(rateValue.toString());
    return '1USDT≈$formatted ${AppConfig.currencyCode()}';
  }

  String _buildUsdtEstimatedText() {
    final rawAmount = _amountController.text.trim();
    if (rawAmount.isEmpty) {
      return '0 USDT';
    }
    final amountValue = double.tryParse(rawAmount);
    final rateValue =
        _usdtWithdrawRate ?? double.tryParse(_usdtWithdrawRateRaw ?? '');
    if (amountValue == null || rateValue == null || rateValue <= 0) {
      return '--';
    }
    final estimated = amountValue / rateValue;
    return '${_formatUsdt(estimated)} USDT';
  }

  String _formatUsdt(double value) {
    if (value == 0) return '0';
    final text = value.toStringAsFixed(4);
    return text.replaceAll(RegExp(r'([.]*0+)$'), '');
  }

  String _formatAmount(String value) {
    final numValue = num.tryParse(value);
    if (numValue == null) return value;
    final parts = numValue.toStringAsFixed(0).split('.');
    final intPart = parts[0];
    final intPartWithComma = intPart.replaceAllMapped(
      RegExp(r'(\\d)(?=(\\d{3})+(?!\\d))'),
      (m) => '${m[1]},',
    );
    return intPartWithComma;
  }

  Future<void> _submitWithdraw() async {
    if (_selectedMethod == _WithdrawMethod.usdtTrc20) {
      await _submitUsdtWithdraw();
      return;
    }
    await _submitFiatWithdraw();
  }

  String _resolveWithdrawError(dynamic code, {String? message}) {
    final statusError = parseUserStatusError(code: code, message: message);
    if (statusError != null) {
      return statusError.localizedMessage;
    }
    final parsedCode =
        code is int ? code : int.tryParse(code?.toString() ?? '');
    switch (parsedCode) {
      case 1001:
        return 'errorWithdrawAmountInvalid'.tr;
      case 1002:
        return 'errorWithdrawConfigFailed'.tr;
      case 1003:
        return 'errorWithdrawUserQueryFailed'.tr;
      case 1004:
        return 'errorWithdrawUserNotFound'.tr;
      case 1005:
        return 'errorWithdrawNotVerified'.tr;
      case 1006:
        return 'errorWithdrawAmountTooLow'.tr;
      case 1007:
        return 'errorWithdrawAmountTooHigh'.tr;
      case 1008:
        return 'errorWithdrawStatsFailed'.tr;
      case 1009:
        return 'errorWithdrawDailyCountLimit'.tr;
      case 1010:
        return 'errorWithdrawDailyAmountLimit'.tr;
      case 1011:
        return 'errorWithdrawWalletFailed'.tr;
      case 1012:
        return 'errorWithdrawInsufficientFunds'.tr;
      case 1013:
        return 'errorWithdrawOutOfServiceTime'.tr;
      case 1014:
        return 'errorWithdrawCreateOrderFailed'.tr;
      case 1015:
        return 'errorWithdrawDeductBalanceFailed'.tr;
      default:
        return 'withdrawFailed'.tr;
    }
  }

  Future<void> _submitFiatWithdraw() async {
    if (_isLoading) return;
    final ok = await _auth.ensureAuthenticated(context);
    if (!ok) return;

    final amount = _amountController.text.trim();
    final cardNumber = _selectedCardNumber.trim();
    final name = _selectedHolderName.trim();
    final mobile = _selectedMobile.trim();

    if (amount.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterWithdrawAmount'.tr);
      return;
    }
    if (_selectedBankCard == null || cardNumber.isEmpty) {
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

    setState(() => _isLoading = true);
    try {
      final result = await PaymentServices.withdraw(
        money: amount,
        number: cardNumber,
        name: name,
        bankCode: _selectedBankCode,
        mobile: mobile,
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
        Future.microtask(() => _home.refreshBalance());
      } else {
        Get.snackbar(
          'tip'.tr,
          _resolveWithdrawError(result.code, message: result.msg),
        );
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitUsdtWithdraw() async {
    if (_isLoading) return;
    final ok = await _auth.ensureAuthenticated(context);
    if (!ok) return;

    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      Get.snackbar('tip'.tr, 'pleaseEnterWithdrawAmount'.tr);
      return;
    }
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      Get.snackbar('tip'.tr, 'pleaseEnterValidWithdrawAmount'.tr);
      return;
    }
    if (_selectedCryptoAddress == null) {
      Get.snackbar('tip'.tr, 'bindCryptoAddressPrompt'.tr);
      return;
    }

    final addressId = _resolveCryptoId(_selectedCryptoAddress);
    final address = _resolveCryptoAddress(_selectedCryptoAddress);
    final chain = _resolveCryptoChain(_selectedCryptoAddress);
    final token = _resolveCryptoToken(_selectedCryptoAddress);

    setState(() => _isLoading = true);
    try {
      final result = await PaymentServices.cryptoWithdraw(
        amount: amount,
        chain: chain.isEmpty ? 'TRC20' : chain,
        token: token,
        addressId: addressId,
        address: address,
      );
      final handled = await handleUserStatusError(
        code: result['code'],
        message: result['msg']?.toString(),
      );
      if (handled) {
        return;
      }
      final code = result['code'];
      if (code == 1 || code?.toString() == '1') {
        Get.snackbar('tip'.tr, 'withdraw_submitted'.tr);
        Future.microtask(() => _home.refreshBalance());
      } else {
        Get.snackbar(
          'tip'.tr,
          _resolveWithdrawError(code, message: result['msg']?.toString()),
        );
      }
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
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
                    _buildHeader(),
                    const SizedBox(height: 12),
                    _buildWithdrawMethod(),
                    const SizedBox(height: 12),
                    if (_isStatusLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      )
                    else if (_selectedMethod == _WithdrawMethod.idr) ...[
                      if (!_hasBankCard) ...[
                        _buildBindBankCardPrompt(),
                      ] else ...[
                        _buildWithdrawForm(),
                        const SizedBox(height: 16),
                        _buildSubmitButton(),
                      ],
                    ] else ...[
                      if (!_hasCryptoAddress) ...[
                        _buildBindCryptoAddressPrompt(),
                      ] else ...[
                        _buildUsdtWithdrawForm(),
                        const SizedBox(height: 16),
                        _buildSubmitButton(),
                      ],
                    ],
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

  Widget _buildBindBankCardPrompt() {
    return InkWell(
      onTap: () => Get.toNamed(Routes.BANK_CARD_ADD),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5A646).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF5A646).withValues(alpha: 0.8),
                ),
              ),
              child: const Icon(Icons.add, color: Color(0xFFF5A646), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'bindBankCardPrompt'.tr,
                style: const TextStyle(
                  color: Color(0xFFF5A646),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildBindCryptoAddressPrompt() {
    return InkWell(
      onTap: () => Get.toNamed(Routes.CRYPTO_ADDRESS_ADD),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5A646).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF5A646).withValues(alpha: 0.8),
                ),
              ),
              child: const Icon(Icons.add, color: Color(0xFFF5A646), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'bindCryptoAddressPrompt'.tr,
                style: const TextStyle(
                  color: Color(0xFFF5A646),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildBackButton(),
              ),
              Text(
                'withdraw'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BalanceBadge(
              onRefresh: _home.refreshBalance,
              balance: _home.balance,
              refreshing: _home.isRefreshingBalance,
            ),
            _OutlineRecordButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: AppBackButton(
        onPressed: () => Get.back(),
      ),
    );
  }

  Widget _buildWithdrawMethod() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: LayoutBuilder(
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
                selected: _selectedMethod == _WithdrawMethod.idr,
                onTap: () {
                  if (_selectedMethod == _WithdrawMethod.idr) return;
                  setState(() => _selectedMethod = _WithdrawMethod.idr);
                },
              ),
              _PaymentMethodCard(
                width: itemWidth,
                iconPath: 'assets/images/usdttrc20icon.png',
                label: 'payMethodUsdtTrc20'.tr,
                selected: _selectedMethod == _WithdrawMethod.usdtTrc20,
                onTap: () {
                  if (_selectedMethod == _WithdrawMethod.usdtTrc20) return;
                  setState(() => _selectedMethod = _WithdrawMethod.usdtTrc20);
                  if (_usdtWithdrawRate == null) {
                    _fetchUsdtWithdrawRate();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWithdrawForm() {
    final bankCard = _selectedBankCard;
    final bankLabel =
        bankCard == null ? 'bankCard'.tr : _composeBankCardTitle(bankCard);

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
          _buildStatusTip(),
          const SizedBox(height: 10),
          _buildPromoRow(),
          const SizedBox(height: 12),
          _buildBankCardRow(bankLabel),
          const SizedBox(height: 12),
          Text(
            'withdrawAmount'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildAmountInputRow(),
        ],
      ),
    );
  }

  Widget _buildUsdtWithdrawForm() {
    final addressItem = _selectedCryptoAddress;
    final addressLabel = addressItem == null
        ? 'withdrawAddress'.tr
        : _composeCryptoAddressTitle(addressItem);
    final rateText = _buildUsdtWithdrawRateText();
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
            'withdrawAddress'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildCryptoAddressRow(addressLabel),
          const SizedBox(height: 12),
          Text(
            'withdrawAmount'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          _buildAmountInputRow(),
          const SizedBox(height: 10),
          _buildInfoRow(label: 'exchangeRate'.tr, value: rateText),
          const SizedBox(height: 6),
          _buildInfoRow(label: 'estimatedArrival'.tr, value: estimatedText),
        ],
      ),
    );
  }

  Widget _buildCryptoAddressRow(String label) {
    return InkWell(
      onTap: _showCryptoAddressSelector,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInputRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _amountFocused
              ? AppConfig.btnSelectedBorderColor
              : Colors.white.withValues(alpha: 0.08),
          width: _amountFocused ? 1.8 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            AppConfig.currencySymbol(),
            style: const TextStyle(
              color: AppConfig.btnSelectedColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              focusNode: _amountFocusNode,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: _amountRangeHint.isNotEmpty
                    ? _amountRangeHint
                    : 'withdrawAmountHint'.tr,
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _fillAllAmount,
            child: Text(
              'withdrawAll'.tr,
              style: const TextStyle(
                color: Color(0xFFF5A646),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF5A646),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'withdrawStatusTip'.tr,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPromoRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'withdrawPromoTitle'.tr,
              style: const TextStyle(
                color: Color(0xFFF5A646),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'detail'.tr,
            style: const TextStyle(
              color: Color(0xFFF5A646),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFFF5A646), size: 18),
        ],
      ),
    );
  }

  Widget _buildBankCardRow(String label) {
    return InkWell(
      onTap: _showBankCardSelector,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
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
                gradient: AppConfig.btnSelectedGradient,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppConfig.btnSelectedBorderColor,
                  width: 1.6,
                ),
                boxShadow: AppConfig.btnSelectedShadow,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
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
                        'confirmWithdraw'.tr,
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
              'withdrawIssueTip'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 12,
              ),
            ),
            GestureDetector(
              onTap: _auth.openCustomerService,
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
        ? AppConfig.btnSelectedBorderColor
        : Colors.white.withValues(alpha: 0.1);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: width,
          height: width,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            gradient: selected ? AppConfig.btnSelectedGradient : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected ? AppConfig.btnSelectedShadow : null,
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
      ),
    );
  }
}

enum _WithdrawMethod {
  idr,
  usdtTrc20,
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
      final displayBalance = _formatBalanceAsK(balance.value);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF14383C),
          border: Border.all(
            color: const Color(0xFF22D8DF),
            width: 1.4,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/me/idr.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Text(
              displayBalance,
              style: const TextStyle(
                color: Color(0xFFFFF133),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onRefresh,
              child: Opacity(
                opacity: isLoading ? 0.88 : 1,
                child: Image.asset(
                  'assets/images/me/add.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
        'withdrawRecord'.tr,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatBalanceAsK(String raw) {
  final normalized = raw.replaceAll(',', '').replaceAll(' ', '');
  final value = double.tryParse(normalized);
  if (value == null) return raw;
  final scaled = value / 1000;
  return '${scaled.toStringAsFixed(2)} K';
}
