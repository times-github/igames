import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/storage.dart';
import 'package:igames/utils/web_lang_param.dart';
import 'package:igames/utils/web_page_reload.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import '../../gameMenu/controllers/game_menu_controller.dart';

class LanguageSelectorController extends GetxController {
  final LayerLink link = LayerLink(); // 仍保留，视图可继续作为触发点
  OverlayEntry? _entry; // 全屏 Overlay

  // 响应式变量
  final currentLanguage = 'Indonesia'.obs; // 展示名称（供视图显示）
  final currentCode = 'id'.obs; // 语言代码（用于逻辑与选中判断）
  final isOpen = false.obs;

  final List<LanguageOption> languages = [
    LanguageOption('中文', 'assets/images/country/zh-cn.svg', 'zh', 'CN'),
    LanguageOption('Indonesia', 'assets/images/country/id.svg', 'id', 'ID'),
    LanguageOption('English', 'assets/images/country/en.svg', 'en', 'US'),
    // LanguageOption('Русский', '🇷🇺', 'ru', 'RU'),
    // LanguageOption('日本語', '🇯🇵', 'ja', 'JP'),
    // LanguageOption('한국어', '🇰🇷', 'ko', 'KR'),
    // LanguageOption('Français', '🇫🇷', 'fr', 'FR'),
    // LanguageOption('Deutsch', '🇩🇪', 'de', 'DE'),
    // LanguageOption('Español', '🇪🇸', 'es', 'ES'),
    // LanguageOption('Português', '🇵🇹', 'pt', 'PT'),
    // LanguageOption('Italiano', '🇮🇹', 'it', 'IT'),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void toggleLanguageMenu(BuildContext context) {
    // 打开或关闭语言选择器
    if (_entry != null) {
      close();
    } else {
      openLanguageMenu(fallbackContext: context);
    }
  }

  void openLanguageMenu({BuildContext? fallbackContext}) {
    if (_entry != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_entry != null) return;
      final overlayState = _resolveOverlayState(fallbackContext);
      final overlayContext = overlayState?.context;
      if (overlayState == null || overlayContext == null) {
        debugPrint(
            'LanguageSelectorController: unable to find a root overlay context.');
        return;
      }
      open(overlayContext, overlayState: overlayState);
    });
  }

  OverlayState? _resolveOverlayState([BuildContext? fallbackContext]) {
    final rootOverlay = Get.key.currentState?.overlay;
    if (rootOverlay != null) {
      return rootOverlay;
    }

    final overlayContext = Get.overlayContext ?? Get.context ?? fallbackContext;
    if (overlayContext == null) {
      return null;
    }

    return Overlay.maybeOf(overlayContext, rootOverlay: true);
  }

  void open(BuildContext context, {OverlayState? overlayState}) {
    if (_entry != null) return;

    final targetOverlay =
        overlayState ?? Overlay.maybeOf(context, rootOverlay: true);
    if (targetOverlay == null) {
      debugPrint(
          'LanguageSelectorController: unable to open language menu without overlay.');
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final bottomInset = mediaQuery.padding.bottom;
    final scale = (screenWidth / 390).clamp(0.88, 1.18);
    final blur = 8.0 * scale;
    final panelRadius = 28.0 * scale;
    final horizontalPadding = 24.0 * scale;
    final titleTop = 26.0 * scale;
    final titleBottom = 10.0 * scale;
    final titleSize = 24.0 * scale;
    final subtitleGap = 12.0 * scale;
    final subtitleSize = 14.0 * scale;

    _entry = OverlayEntry(
      builder: (context) => Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                color: Colors.black.withValues(alpha: 0.48),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(bottom: bottomInset),
              decoration: BoxDecoration(
                color: const Color(0xFF0D6A72),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(panelRadius),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      titleTop,
                      horizontalPadding,
                      titleBottom,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'switchLanguageTitle'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: subtitleGap),
                        Text(
                          'switchLanguageSubtitle'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.52),
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...languages.map(
                    (lang) => _buildLanguageOption(lang, scale: scale),
                  ),
                  _buildCancelButton(scale: scale),
                ],
              ),
            ),
          ),
        ),
      ]),
    );

    targetOverlay.insert(_entry!);
    isOpen.value = true;
  }

  void close() {
    _entry?.remove();
    _entry = null;
    isOpen.value = false;
  }

  Future<void> selectLanguage(LanguageOption lang) async {
    // 更新当前语言：代码（用于逻辑）+ 名称（用于显示）
    currentCode.value = lang.languageCode;
    currentLanguage.value = lang.name;
    debugPrint('selectLanguage: ${lang.languageCode}, ${lang.countryCode}');
    //存储到本地
    await Storage.setData("language", lang.languageCode);

    close();

    // 更新语言
    Get.updateLocale(Locale(lang.languageCode, lang.countryCode));

    // 刷新游戏数据（如果 GameMenuController 已注册）
    try {
      if (Get.isRegistered<GameMenuController>()) {
        Get.find<GameMenuController>().refreshGames();
      }
      if (Get.isRegistered<JackpotService>()) {
        Get.find<JackpotService>().refresh();
      }
    } catch (e) {
      debugPrint('刷新游戏数据失败: $e');
    }

    // 切换语言后刷新页面（Web 上生效）
    setWebLangParam(lang.languageCode);
    reloadWebPage();
  }

  Future<void> _loadSavedLanguage() async {
    final stored = await Storage.getData("language");
    final storedCode = stored is String ? stored.toLowerCase() : null;
    final fallbackCode = (Get.locale?.languageCode ?? 'en').toLowerCase();
    final resolved = _resolveLanguageOption(storedCode ?? fallbackCode);
    currentCode.value = resolved.languageCode;
    currentLanguage.value = resolved.name;
    if (Get.locale?.languageCode != resolved.languageCode) {
      Get.updateLocale(Locale(resolved.languageCode, resolved.countryCode));
    }
  }

  LanguageOption _resolveLanguageOption(String code) {
    return languages.firstWhere(
      (lang) => lang.languageCode.toLowerCase() == code,
      orElse: () => languages.first,
    );
  }

  Widget _buildLanguageOption(LanguageOption lang, {required double scale}) {
    final bool isSelected = currentCode.value == lang.languageCode;
    final horizontalPadding = 24.0 * scale;
    final verticalPadding = 18.0 * scale;
    final flagSize = 28.0 * scale;
    final gap = 18.0 * scale;
    final textSize = 18.0 * scale;
    final checkBoxSize = 38.0 * scale;
    final checkIconSize = 28.0 * scale;

    return GestureDetector(
      onTap: () => selectLanguage(lang),
      child: Container(
        width: double.infinity,
        color: isSelected ? const Color(0xFF13959D) : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              lang.flagAsset,
              width: flagSize,
              height: flagSize,
              fit: BoxFit.contain,
            ),
            SizedBox(width: gap),
            Expanded(
              child: Text(
                _displayNameForSheet(lang),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: textSize,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: checkBoxSize,
                height: checkBoxSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF1CE5E6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: const Color(0xFF005B61),
                  size: checkIconSize,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton({required double scale}) {
    final horizontalPadding = 24.0 * scale;
    final verticalPadding = 20.0 * scale;
    final fontSize = 17.0 * scale;
    return GestureDetector(
      onTap: close,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Text(
          'button_cancel'.tr,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _displayNameForSheet(LanguageOption lang) {
    switch (lang.languageCode.toLowerCase()) {
      case 'id':
        return 'Indonesian';
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return lang.name;
    }
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}

class LanguageOption {
  final String name;
  final String flagAsset;
  final String languageCode;
  final String countryCode;

  LanguageOption(
    this.name,
    this.flagAsset,
    this.languageCode,
    this.countryCode,
  );
}
