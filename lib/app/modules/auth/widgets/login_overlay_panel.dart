import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/auth/controllers/login_form_controller.dart';
import 'package:igames/app/modules/auth/widgets/turnstile_widget.dart';
import 'package:igames/app/modules/widgets/app_close_button.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AuthLoginSubmit = Future<bool> Function(
  String account,
  String credential, {
  bool isPhone,
  String? turnstileToken,
});

class LoginOverlayPanel extends StatelessWidget {
  const LoginOverlayPanel({
    super.key,
    required this.onClose,
    required this.apiClient,
    required this.isLoading,
    required this.passwordLoginRetryAfterSeconds,
    required this.passwordLoginLockedAccount,
    required this.onSubmit,
    required this.onOpenCustomerService,
    required this.onOpenDownloadUrl,
  });

  final VoidCallback onClose;
  final ApiClient apiClient;
  final RxBool isLoading;
  final RxInt passwordLoginRetryAfterSeconds;
  final RxString passwordLoginLockedAccount;
  final AuthLoginSubmit onSubmit;
  final Future<void> Function() onOpenCustomerService;
  final Future<void> Function() onOpenDownloadUrl;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const closeSize = 36.0;
    const closeOverlap = closeSize / 2;
    final panelW = max(
      280.0,
      min(420.0, size.width - closeOverlap - 16.0),
    );
    final panelH = min(
      640.0,
      max(360.0, size.height - closeOverlap - 16.0),
    );

    return SafeArea(
      child: Center(
        child: SizedBox(
          width: panelW + closeOverlap,
          height: panelH + closeOverlap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: closeOverlap / 2,
                top: closeOverlap,
                child: _AuthPanelShell(
                  width: panelW,
                  height: panelH,
                  child: _LoginFormView(
                    apiClient: apiClient,
                    isLoading: isLoading,
                    passwordLoginRetryAfterSeconds:
                        passwordLoginRetryAfterSeconds,
                    passwordLoginLockedAccount: passwordLoginLockedAccount,
                    onSubmit: onSubmit,
                    onOpenCustomerService: onOpenCustomerService,
                    onOpenDownloadUrl: onOpenDownloadUrl,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: _CloseFab(
                  onTap: onClose,
                  size: closeSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginFormView extends StatefulWidget {
  const _LoginFormView({
    required this.apiClient,
    required this.isLoading,
    required this.passwordLoginRetryAfterSeconds,
    required this.passwordLoginLockedAccount,
    required this.onSubmit,
    required this.onOpenCustomerService,
    required this.onOpenDownloadUrl,
  });

  final ApiClient apiClient;
  final RxBool isLoading;
  final RxInt passwordLoginRetryAfterSeconds;
  final RxString passwordLoginLockedAccount;
  final AuthLoginSubmit onSubmit;
  final Future<void> Function() onOpenCustomerService;
  final Future<void> Function() onOpenDownloadUrl;

  @override
  State<_LoginFormView> createState() => _LoginFormViewState();
}

class _LoginFormViewState extends State<_LoginFormView> {
  late final LoginFormController controller;

  @override
  void initState() {
    super.initState();
    controller = LoginFormController(
      apiClient: widget.apiClient,
      parentIsLoading: widget.isLoading,
      passwordLoginRetryAfterSeconds: widget.passwordLoginRetryAfterSeconds,
      passwordLoginLockedAccount: widget.passwordLoginLockedAccount,
      onSubmit: widget.onSubmit,
      onOpenCustomerService: widget.onOpenCustomerService,
      onOpenDownloadUrl: widget.onOpenDownloadUrl,
    );
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    controller.handleLanguageChange();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final horizontalPadding = compact ? 14.0 : 20.0;
        final topPadding = compact ? 12.0 : 14.0;
        final bottomPadding = compact ? 20.0 : 24.0;
        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            overscroll: false,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoginBanner(),
                  Obx(() {
                    if (!controller.loadingBanners.value &&
                        controller.loginBanners.isNotEmpty) {
                      return const SizedBox(height: 12);
                    }
                    return const SizedBox.shrink();
                  }),
                  _buildTabs(),
                  const SizedBox(height: 10),
                  _buildAccountField(),
                  const SizedBox(height: 10),
                  _buildSecretField(),
                  const SizedBox(height: 6),
                  _buildRememberCheckbox(),
                  if (supportsTurnstileChallenge &&
                      AppConfig.turnstileSiteKey.isNotEmpty)
                    _buildTurnstile(),
                  const SizedBox(height: 10),
                  _buildSubmitButton(),
                  _buildFooterLinks(),
                  if (kIsWeb) _buildDownloadButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginBanner() {
    return Obx(() {
      if (controller.loadingBanners.value || controller.loginBanners.isEmpty) {
        return const SizedBox.shrink();
      }

      return SizedBox(
        height: 70,
        child: PageView.builder(
          controller: controller.bannerController,
          itemCount: controller.loginBanners.length,
          itemBuilder: (context, index) {
            final banner = controller.loginBanners[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: GestureDetector(
                  onTap: () async {
                    final link = banner.link;
                    if (link == null || link.isEmpty) return;
                    if (link.startsWith('http')) {
                      await launchUrl(
                        Uri.parse(link),
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      Get.toNamed(link);
                    }
                  },
                  child: CompatibleImage.network(
                    banner.imageUrl,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => _bannerFallback(),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _bannerFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppConfig.btnSelectedGradient,
      ),
    );
  }

  Widget _buildTabs() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabChip(
                  label: 'account'.tr,
                  active: !controller.usePhone.value,
                  onTap: () => controller.usePhone.value = false,
                ),
              ),
              Expanded(
                child: _TabChip(
                  label: 'phone'.tr,
                  active: controller.usePhone.value,
                  onTap: () => controller.usePhone.value = true,
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildAccountField() {
    return Obx(() => _AuthTextField(
          controller: controller.accountController,
          hint: controller.usePhone.value
              ? 'pleaseEnterPhone'.tr
              : 'pleaseEnterUsername'.tr,
          icon: controller.usePhone.value
              ? Icons.phone_android_outlined
              : Icons.person_outline,
          customPrefix: controller.usePhone.value
              ? const _PhonePrefix(
                  flagAsset: 'assets/images/phoneID.png',
                  code: '+62',
                )
              : null,
          keyboardType: controller.usePhone.value
              ? TextInputType.phone
              : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return controller.usePhone.value
                  ? 'pleaseEnterPhone'.tr
                  : 'pleaseEnterAccount'.tr;
            }
            if (controller.usePhone.value &&
                !RegExp(r'^\d{6,}$').hasMatch(value.trim())) {
              return 'pleaseEnterCorrectPhone'.tr;
            }
            return null;
          },
        ));
  }

  Widget _buildSecretField() {
    return Obx(() {
      if (controller.usePhone.value) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final codeButtonWidth =
                (constraints.maxWidth * 0.42).clamp(104.0, 136.0);
            return _AuthTextField(
              controller: controller.smsCodeController,
              hint: 'pleaseEnterSmsCode'.tr,
              icon: Icons.verified_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => controller.submit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'pleaseEnterCode'.tr;
                }
                if (value.length < 4) {
                  return 'codeLengthAtLeast4'.tr;
                }
                return null;
              },
              suffix: Obx(() => _SmsCodeButton(
                    width: codeButtonWidth,
                    text: controller.smsCountdown.value > 0
                        ? '${controller.smsCountdown.value}s'
                        : 'getCode'.tr,
                    loading: controller.sendingCode.value,
                    onTap: (controller.sendingCode.value ||
                            controller.smsCountdown.value > 0)
                        ? null
                        : controller.sendSmsCode,
                  )),
            );
          },
        );
      }

      return Obx(() => _AuthTextField(
            controller: controller.passwordController,
            hint: 'passwordHint'.tr,
            icon: Icons.lock_outline,
            obscure: controller.obscurePwd.value,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => controller.submit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'pleaseEnterPassword'.tr;
              }
              if (value.length < 6) {
                return 'passwordLengthMustBeAtLeast6'.tr;
              }
              return null;
            },
            suffix: IconButton(
              onPressed: controller.togglePasswordVisibility,
              icon: Icon(
                controller.obscurePwd.value
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ));
    });
  }

  Widget _buildRememberCheckbox() {
    return Obx(() => Row(
          children: [
            Theme(
              data: ThemeData(
                splashFactory: NoSplash.splashFactory,
              ),
              child: Checkbox(
                value: controller.remember.value,
                activeColor: AppConfig.btnSelectedBorderColor,
                checkColor: Colors.white,
                overlayColor: const WidgetStatePropertyAll<Color>(
                  Colors.transparent,
                ),
                splashRadius: 0,
                onChanged: controller.toggleRemember,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'rememberPassword'.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 13,
              ),
            ),
          ],
        ));
  }

  Widget _buildTurnstile() {
    return Obx(() => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Center(
            child: SizedBox(
              width: 300,
              child: TurnstileWidget(
                key: ValueKey(
                  'turnstile-${controller.turnstileLang.value}-${controller.turnstileEpoch.value}',
                ),
                siteKey: AppConfig.turnstileSiteKey,
                language: controller.turnstileLang.value,
                onToken: controller.handleTurnstileToken,
              ),
            ),
          ),
        ));
  }

  Widget _buildSubmitButton() {
    return Obx(() {
      final lockedSeconds = controller.passwordLoginLockedSeconds;
      final isPasswordLocked = lockedSeconds > 0;
      final buttonText = isPasswordLocked
          ? controller.passwordLockCountdownText(lockedSeconds)
          : 'loginRegister'.tr;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LoginSubmitButton(
            text: buttonText,
            busy: widget.isLoading.value,
            onTap: widget.isLoading.value || isPasswordLocked
                ? null
                : controller.submit,
          ),
          if (isPasswordLocked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'password_login_locked'.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    });
  }

  Widget _buildFooterLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _AuthFooterLink(
              text: 'forgotPassword'.tr,
              onTap: widget.onOpenCustomerService,
            ),
          ),
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: Colors.white.withValues(alpha: 0.22),
          ),
          Expanded(
            child: _AuthFooterLink(
              text: 'contactCustomerService'.tr,
              icon: Icons.headset_mic_outlined,
              onTap: widget.onOpenCustomerService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButtons() {
    return _DownloadButtons(
      onTap: widget.onOpenDownloadUrl,
    );
  }
}

class _AuthPanelShell extends StatelessWidget {
  const _AuthPanelShell({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final useWebCompatMode = kIsWeb;
    const outerRadius = 24.0;
    const innerRadius = 23.0;
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConfig.btnSelectedBorderColor.withValues(alpha: 0.85),
            AppConfig.buttonColor.withValues(alpha: 0.7),
            AppConfig.webDesktopOuterBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppConfig.webDesktopOuterBackground.withValues(
                    alpha: 0.26,
                  ),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/color_bg.png'),
                    fit: BoxFit.cover,
                    opacity: 0.82,
                  ),
                  borderRadius: BorderRadius.circular(innerRadius),
                  border: Border.all(
                    color:
                        AppConfig.webDesktopShellBorder.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(innerRadius),
                  gradient: LinearGradient(
                    colors: [
                      AppConfig.earnFloatingMenuBackground.withValues(
                        alpha: 0.42,
                      ),
                      AppConfig.webDesktopOuterBackground.withValues(
                        alpha: 0.36,
                      ),
                      AppConfig.earnCardBackground.withValues(alpha: 0.28),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            if (!useWebCompatMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.customPrefix,
    this.keyboardType,
    this.obscure = false,
    this.validator,
    this.suffix,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Widget? customPrefix;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    final enabledBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.16),
        width: 1.2,
      ),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: const BorderSide(
        color: AppConfig.btnSelectedBorderColor,
        width: 1.5,
      ),
    );
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: AppConfig.btnSelectedBorderColor,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.58),
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: AppConfig.buttonColor.withValues(alpha: 0.16),
        prefixIconConstraints: BoxConstraints(
          minWidth: customPrefix != null ? 104 : 48,
          minHeight: 48,
        ),
        prefixIcon: customPrefix ??
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.72),
                size: 22,
              ),
            ),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: enabledBorder,
        enabledBorder: enabledBorder,
        focusedBorder: focusedBorder,
        errorBorder: enabledBorder.copyWith(
          borderSide: const BorderSide(
            color: Color(0xC8FF6B6B),
            width: 1.2,
          ),
        ),
        focusedErrorBorder: focusedBorder.copyWith(
          borderSide: const BorderSide(
            color: Color(0xC8FF6B6B),
            width: 1.4,
          ),
        ),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B)),
      ),
    );
  }
}

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix({
    required this.flagAsset,
    required this.code,
  });

  final String flagAsset;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            flagAsset,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Text(
            code,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 1.4,
            height: 26,
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ],
      ),
    );
  }
}

class _AuthFooterLink extends StatelessWidget {
  const _AuthFooterLink({
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final Future<void> Function() onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.85),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsCodeButton extends StatelessWidget {
  const _SmsCodeButton({
    required this.width,
    required this.text,
    required this.loading,
    required this.onTap,
  });

  final double width;
  final String text;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        width: width,
        height: 40,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppConfig.btnSelectedBorderColor,
            disabledForegroundColor:
                AppConfig.btnSelectedBorderColor.withValues(alpha: 0.52),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppConfig.btnSelectedBorderColor,
                    ),
                  ),
                )
              : Opacity(
                  opacity: enabled ? 1 : 0.7,
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _LoginSubmitButton extends StatelessWidget {
  const _LoginSubmitButton({
    required this.text,
    this.onTap,
    this.busy = false,
  });

  final String text;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final visualEnabled = enabled || busy;
    const borderRadius = 14.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: visualEnabled ? 1 : 0.58,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage(AppConfig.btnDefaultBackgroundAsset),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppConfig.btnSelectedBorderColor,
                width: 1.8,
              ),
            ),
            alignment: Alignment.center,
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppConfig.btnDefaultTextColor,
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: AppConfig.btnDefaultTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: active ? null : Colors.transparent,
        gradient: active
            ? LinearGradient(
                colors: [
                  AppConfig.btnSelectedBorderColor.withValues(alpha: 0.58),
                  AppConfig.buttonColor.withValues(alpha: 0.36),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: active
            ? Border.all(
                color: AppConfig.btnSelectedBorderColor.withValues(alpha: 0.72),
                width: 1,
              )
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    active ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadButtons extends StatelessWidget {
  const _DownloadButtons({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DownloadAppButton(
          text: 'downloadAppNow'.tr,
          onTap: onTap,
        ),
      ],
    );
  }
}

class _DownloadAppButton extends StatelessWidget {
  const _DownloadAppButton({
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    const borderRadius = 14.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.58,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage(AppConfig.btnSelectedBackgroundAsset),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppConfig.btn2SelectedBorderColor,
                width: 2.2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: const TextStyle(
                color: AppConfig.btnSelectedTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseFab extends StatelessWidget {
  const _CloseFab({
    required this.onTap,
    this.size = 56,
  });

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              AppConfig.earnCardBackground,
              AppConfig.earnFloatingMenuBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppConfig.webDesktopShellShadow.withValues(alpha: 0.75),
              blurRadius: size <= 40 ? 8 : 14,
              offset: Offset(0, size <= 40 ? 3 : 6),
            ),
          ],
          border: Border.all(
            color: AppConfig.webDesktopShellBorder.withValues(alpha: 0.9),
            width: size <= 40 ? 1.6 : 2,
          ),
        ),
        child: AppCloseIcon(
          size: size <= 40 ? 18 : 22,
        ),
      ),
    );
  }
}
