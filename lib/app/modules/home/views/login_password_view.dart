import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config_export.dart';

class LoginPasswordView extends StatefulWidget {
  const LoginPasswordView({super.key});

  @override
  State<LoginPasswordView> createState() => _LoginPasswordViewState();
}

class _LoginPasswordViewState extends State<LoginPasswordView> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _oldController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  bool _hasLoginPwd = true;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map && args.containsKey('hasLoginPwd')) {
      _hasLoginPwd = args['hasLoginPwd'] == true;
    }
  }

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
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
              _buildSmsRegisterHint(),
              const SizedBox(height: 12),
              _buildPasswordGroup(),
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
            'loginPasswordChangeTitle'.tr,
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

  Widget _buildPasswordGroup() {
    final rows = <Widget>[];
    if (_hasLoginPwd) {
      rows.add(_buildPasswordRow(
        controller: _oldController,
        hint: 'oldLoginPassword'.tr,
        obscure: _obscureOld,
        onToggle: () => setState(() => _obscureOld = !_obscureOld),
      ));
    }
    rows.add(_buildPasswordRow(
      controller: _newController,
      hint: 'newLoginPassword'.tr,
      obscure: _obscureNew,
      onToggle: () => setState(() => _obscureNew = !_obscureNew),
    ));
    rows.add(_buildPasswordRow(
      controller: _confirmController,
      hint: 'confirmLoginPassword'.tr,
      obscure: _obscureConfirm,
      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
    ));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          return Column(
            children: [
              rows[index],
              if (index != rows.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPasswordRow({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              minLines: 1,
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: Colors.white,
              textAlignVertical: TextAlignVertical.center,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                border: InputBorder.none,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6F55FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _submitting
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

  Widget _buildSmsRegisterHint() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'loginPasswordSmsDefaultHint'.tr,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 12,
          height: 1.4,
        ),
      ),
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
            TextSpan(text: 'loginPasswordHelpPrefix'.tr),
            const TextSpan(text: ' '),
            TextSpan(
              text: 'loginPasswordHelpLink'.tr,
              style: const TextStyle(color: Color(0xFFF5A646)),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasAtLeastSixDigits(String value) {
    return RegExp(r'\d').allMatches(value).length >= 6;
  }

  bool _hasSpecialChar(String value) {
    return RegExp(r'[!@#$%^&*()_+\-=\[\]{};:,.<>/?`~\\|]')
        .hasMatch(value);
  }

  bool _isLoginPasswordFormatValid(String value) {
    if (value.isEmpty || value.length > 18) {
      return false;
    }
    if (!_hasAtLeastSixDigits(value)) {
      return false;
    }
    if (!_hasSpecialChar(value)) {
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final oldPwd = _oldController.text.trim();
    final newPwd = _newController.text.trim();
    final confirmPwd = _confirmController.text.trim();

    if (_hasLoginPwd && oldPwd.isEmpty) {
      _showTip('errorLoginPasswordOldRequired'.tr);
      return;
    }
    if (newPwd.isEmpty) {
      _showTip('errorLoginPasswordFormat'.tr);
      return;
    }
    if (newPwd.length > 18) {
      _showTip('errorLoginPasswordLength'.tr);
      return;
    }
    if (!_isLoginPasswordFormatValid(newPwd)) {
      _showTip('errorLoginPasswordFormat'.tr);
      return;
    }
    if (newPwd != confirmPwd) {
      _showTip('errorLoginPasswordMismatch'.tr);
      return;
    }

    final data = {
      'new_pwd': newPwd,
      'confirm_pwd': confirmPwd,
    };
    if (_hasLoginPwd) {
      data['old_pwd'] = oldPwd;
    }

    setState(() => _submitting = true);
    try {
      final resp = await _apiClient.post(
        '/user/security/password',
        data: data,
        withAuth: true,
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        final payload = resp.data as Map;
        if (payload['code'] == 1) {
          Get.back(result: true);
          Future.microtask(() {
            Get.snackbar('tip'.tr, 'loginPasswordUpdated'.tr,
                snackPosition: SnackPosition.TOP);
          });
          return;
        }
        final msg = payload['msg'];
        if (msg is String && msg.trim().isNotEmpty) {
          _showTip(msg);
        } else {
          _showTip(_resolveError(payload['code']));
        }
        return;
      }
      _showTip('networkError'.tr);
    } catch (_) {
      _showTip('networkError'.tr);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _resolveError(dynamic code) {
    final parsedCode =
        code is int ? code : int.tryParse(code?.toString() ?? '');
    switch (parsedCode) {
      case 1311:
        return 'errorLoginPasswordNotLogin'.tr;
      case 1312:
        return 'errorLoginPasswordMismatch'.tr;
      case 1313:
        return 'errorLoginPasswordLength'.tr;
      case 1314:
        return 'errorLoginPasswordQueryFailed'.tr;
      case 1315:
        return 'errorLoginPasswordUserMissing'.tr;
      case 1316:
        return 'errorLoginPasswordOldRequired'.tr;
      case 1317:
        return 'errorLoginPasswordOldWrong'.tr;
      case 1318:
        return 'errorLoginPasswordUpdateFailed'.tr;
      default:
        return 'networkError'.tr;
    }
  }

  void _showTip(String text) {
    Get.snackbar('tip'.tr, text, snackPosition: SnackPosition.TOP);
  }
}
