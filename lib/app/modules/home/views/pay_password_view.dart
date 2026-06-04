import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/utils/api_client.dart';

class PayPasswordView extends StatefulWidget {
  const PayPasswordView({super.key});

  @override
  State<PayPasswordView> createState() => _PayPasswordViewState();
}

class _PayPasswordViewState extends State<PayPasswordView> {
  final ApiClient _apiClient = ApiClient();
  bool _submitting = false;
  bool _hasPayPwd = false;
  int _stepIndex = 0;
  String _input = '';
  String _oldPwd = '';
  String _newPwd = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _hasPayPwd = args['hasPayPwd'] == true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_stepIndex];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              Text(
                step.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 22),
              _buildDots(),
              const Spacer(),
              _buildKeypad(),
              const Spacer(),
              _buildFooterTip(),
              const SizedBox(height: 24),
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
            _hasPayPwd ? 'payPasswordChangeTitle'.tr : 'payPasswordSetTitle'.tr,
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

  Future<void> _submit() async {
    if (_submitting) return;

    final data = {
      'new_pwd': _newPwd,
      'confirm_pwd': _input,
    };
    if (_hasPayPwd) {
      data['old_pwd'] = _oldPwd;
    }

    setState(() => _submitting = true);
    try {
      final resp = await _apiClient.post(
        '/user/pay/password',
        data: data,
        withAuth: true,
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final payload = resp.data as Map;
        if (payload['code'] == 1) {
          Get.back(result: true);
          Future.microtask(() {
            Get.snackbar('tip'.tr, 'payPasswordUpdated'.tr,
                snackPosition: SnackPosition.TOP);
          });
          return;
        }
        _showTip(_resolveError(payload['code']));
        _resetToFirstStep();
        return;
      }
      _showTip('networkError'.tr);
      _resetToFirstStep();
    } catch (_) {
      _showTip('networkError'.tr);
      _resetToFirstStep();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _resolveError(dynamic code) {
    final parsedCode =
        code is int ? code : int.tryParse(code?.toString() ?? '');
    switch (parsedCode) {
      case 1201:
        return 'errorPayPasswordNotLogin'.tr;
      case 1202:
        return 'errorPayPasswordMismatch'.tr;
      case 1203:
        return 'errorPayPasswordLength'.tr;
      case 1204:
        return 'errorPayPasswordQueryFailed'.tr;
      case 1205:
        return 'errorPayPasswordUserMissing'.tr;
      case 1206:
        return 'errorPayPasswordOldRequired'.tr;
      case 1207:
        return 'errorPayPasswordOldWrong'.tr;
      case 1208:
        return 'errorPayPasswordEncryptFailed'.tr;
      case 1209:
        return 'errorPayPasswordUpdateFailed'.tr;
      default:
        return 'networkError'.tr;
    }
  }

  void _showTip(String text) {
    Get.snackbar('tip'.tr, text, snackPosition: SnackPosition.TOP);
  }

  List<_PayStep> get _steps {
    final steps = <_PayStep>[];
    if (_hasPayPwd) {
      steps.add(_PayStep(type: _PayStepType.old, label: 'oldPayPassword'.tr));
    }
    steps.add(_PayStep(type: _PayStepType.newPwd, label: 'newPayPassword'.tr));
    steps.add(
        _PayStep(type: _PayStepType.confirm, label: 'confirmPayPassword'.tr));
    return steps;
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final filled = index < _input.length;
        return Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.only(right: index == 5 ? 0 : 10),
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    final width = MediaQuery.of(context).size.width;
    const gap = 25.0;
    final size = ((width - 32 - gap * 2) / 3).clamp(64.0, 78.0);
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], size, gap),
        const SizedBox(height: gap),
        _buildKeypadRow(['4', '5', '6'], size, gap),
        const SizedBox(height: gap),
        _buildKeypadRow(['7', '8', '9'], size, gap),
        const SizedBox(height: gap),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: size),
            SizedBox(width: gap),
            _KeyButton(
              label: '0',
              size: size,
              onTap: () => _handleDigit('0'),
            ),
            SizedBox(width: gap),
            _KeyButton(
              size: size,
              icon: Icons.backspace_outlined,
              onTap: _handleBackspace,
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFooterTip() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
          children: [
            TextSpan(text: 'forgotPayPasswordPrefix'.tr),
            TextSpan(
              text: 'forgotPayPasswordLink'.tr,
              style: const TextStyle(color: Color(0xFF8A6CFF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, double size, double gap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          _KeyButton(
            label: digits[i],
            size: size,
            onTap: () => _handleDigit(digits[i]),
          ),
          if (i != digits.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }

  void _handleDigit(String digit) {
    if (_submitting) return;
    if (_input.length >= 6) return;
    setState(() {
      _input += digit;
    });
    if (_input.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _handleComplete();
      });
    }
  }

  void _handleBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _handleComplete() {
    final step = _steps[_stepIndex].type;
    if (step == _PayStepType.old) {
      _oldPwd = _input;
      _input = '';
      _stepIndex += 1;
      setState(() {});
      return;
    }
    if (step == _PayStepType.newPwd) {
      _newPwd = _input;
      _input = '';
      _stepIndex += 1;
      setState(() {});
      return;
    }
    if (step == _PayStepType.confirm) {
      if (_newPwd != _input) {
        _showTip('errorPayPasswordMismatch'.tr);
        _resetToFirstStep();
        return;
      }
      _submit();
    }
  }

  void _resetToFirstStep() {
    _input = '';
    _newPwd = '';
    if (_hasPayPwd) {
      _oldPwd = '';
      _stepIndex = 0;
    } else {
      _stepIndex = 0;
    }
    if (mounted) setState(() {});
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({
    this.label,
    this.icon,
    required this.size,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: icon != null
              ? Icon(icon, color: Colors.white70)
              : Text(
                  label ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

enum _PayStepType { old, newPwd, confirm }

class _PayStep {
  const _PayStep({required this.type, required this.label});

  final _PayStepType type;
  final String label;
}
