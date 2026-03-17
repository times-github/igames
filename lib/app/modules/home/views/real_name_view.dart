import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config_export.dart';

class RealNameView extends StatefulWidget {
  const RealNameView({super.key});

  @override
  State<RealNameView> createState() => _RealNameViewState();
}

class _RealNameViewState extends State<RealNameView> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  bool _verified = false;
  String _realName = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      _verified = args['verified'] == true;
      _realName = (args['real_name'] ?? '').toString();
      _controller.text = _realName;
    } else {
      _loadStatus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final resp = await _apiClient.get('/user/security/status');
      if (resp.statusCode == 200 && resp.data is Map) {
        final data = resp.data as Map;
        if (data['code'] == 1 && data['data'] is Map) {
          final payload = data['data'] as Map;
          final verifiedValue = payload['verified'] ?? payload['is_verified'];
          final verified = verifiedValue == true || verifiedValue == 1 || verifiedValue == '1';
          final realName = (payload['real_name'] ?? '').toString();
          _verified = verified;
          _realName = realName;
          _controller.text = realName;
        }
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
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
              const SizedBox(height: 14),
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
                _verified ? _buildVerifiedCard() : _buildInputCard(),
                if (!_verified) ...[
                  const SizedBox(height: 14),
                  _buildSubmitButton(),
                ],
                const SizedBox(height: 14),
                _buildInfoText(),
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
            'realNameTitle'.tr,
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

  Widget _buildVerifiedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            'realNameTitle'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _realName.isEmpty ? '--' : _realName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Text(
            'realNameTitle'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _submit,
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

  Widget _buildInfoText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            height: 1.6,
          ),
          children: [
            TextSpan(text: 'realNameInfoPrefix'.tr),
            TextSpan(
              text: 'realNameInfoLink'.tr,
              style: const TextStyle(color: Color(0xFF8A6CFF)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      Get.snackbar('tip'.tr, 'errorRealNameEmpty'.tr,
          snackPosition: SnackPosition.TOP);
      return;
    }
    final resp = await _apiClient.post(
      '/user/security/real-name',
      data: {'real_name': name},
      withAuth: true,
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final data = resp.data as Map;
      if (data['code'] == 1) {
        Get.back(result: true);
        return;
      }
      _showError(data['code'], data['msg']);
      return;
    }
    _showError(null, null);
  }

  void _showError(dynamic code, dynamic msg) {
    final parsedCode = code is int ? code : int.tryParse(code?.toString() ?? '');
    String text;
    switch (parsedCode) {
      case 1301:
        text = 'errorRealNameNotLogin'.tr;
        break;
      case 1302:
        text = 'errorRealNameQueryFailed'.tr;
        break;
      case 1303:
        text = 'errorRealNameUserMissing'.tr;
        break;
      case 1304:
        text = 'errorRealNameEmpty'.tr;
        break;
      case 1305:
        text = 'errorRealNameAlreadyVerified'.tr;
        break;
      case 1306:
        text = 'errorRealNameBindFailed'.tr;
        break;
      default:
        final serverMsg = (msg ?? '').toString().trim();
        text = serverMsg.isEmpty ? 'networkError'.tr : serverMsg;
    }
    Get.snackbar('tip'.tr, text, snackPosition: SnackPosition.TOP);
  }
}
