import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
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
    LanguageOption('中文', '🇨🇳', 'zh', 'CN'), // 显示名称，国旗，语言代码，国家代码
    LanguageOption('Indonesia', '🇮🇩', 'id', 'ID'),
    LanguageOption('English', '🇺🇸', 'en', 'US'),
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

    final Size screen = MediaQuery.of(context).size;
    final double panelWidth = math.min(screen.width - 48, 980);
    final double panelHeight = math.min(screen.height - 160, 600);

    _entry = OverlayEntry(
      builder: (context) => Stack(children: [
        // 背景模糊 + 暗色蒙层（点击关闭）
        Positioned.fill(
          child: GestureDetector(
            onTap: close,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        // 居中弹窗面板
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              height: panelHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0E1621),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题 + 关闭按钮
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(
                          'language'.tr,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: close,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF20242D),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // // 可选的顶部装饰横幅
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 20),
                  //   child: Container(
                  //     height: 64,
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(16),
                  //       gradient: const LinearGradient(
                  //         colors: [Color(0xFF0E3A8C), Color(0xFF2563EB)],
                  //       ),
                  //     ),
                  //     // 可放入装饰内容
                  //   ),
                  // ),

                  expandedGrid(), // 中部网格区域（可滚动）
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

  // 中部网格区域（可滚动）
  Widget expandedGrid() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children:
                languages.map((lang) => _buildLanguageOption(lang)).toList(),
          ),
        ),
      ),
    );
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

  Widget _buildLanguageOption(LanguageOption lang) {
    final bool isSelected = currentCode.value ==
        lang.languageCode; // 判断是否选中，根据语言代码，而不是语言名称 ，因为语言名称可能相同，但是语言代码不会相同

    return GestureDetector(
      // 网格选项（点击选中的语言）
      onTap: () => selectLanguage(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: isSelected ? 86 : 74,
        height: isSelected ? 86 : 74,
        decoration: BoxDecoration(
          color: isSelected ? null : const Color(0xFF20242D),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)])
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              lang.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    close();
    super.onClose();
  }
}

class LanguageOption {
  final String name;
  final String flag;
  final String languageCode;
  final String countryCode;

  LanguageOption(this.name, this.flag, this.languageCode, this.countryCode);
}
