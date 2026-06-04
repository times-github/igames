import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/base/base_controller.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/config/app_config_export.dart';

/// HomeTabController - 管理首页标签页的所有业务逻辑
class HomeTabController extends BaseController {
  // 依赖注入
  final HomeController homeController;
  final AuthController authController;
  final GameMenuController menuController;

  HomeTabController({
    required this.homeController,
    required this.authController,
    required this.menuController,
  });

  // ScrollController
  late final ScrollController scrollController;

  // 状态变量
  static const int priorityHomeImageCount = 6;
  static const double homeShowcaseAutoPlayCutoff = 320;

  final showBackToTop = false.obs;
  final allowAnnouncementFetch = false.obs;
  final allowDeferredHomeImages = false.obs;
  final pauseHomeAutoPlay = false.obs;
  final homeShowcaseVisible = true.obs;

  bool _didKickOffHomeDeferredResources = false;

  // 计算属性
  bool get homeAutoPlayEnabled =>
      !pauseHomeAutoPlay.value && homeShowcaseVisible.value;

  @override
  void onInit() {
    super.onInit();

    scrollController = ScrollController();
    scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickOffHomeDeferredResources();
      _unlockDeferredHomeImagesLater();
    });
  }

  @override
  void onClose() {
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    super.onClose(); // BaseController会自动清理Timer
  }

  /// 处理滚动事件
  void _handleScroll() {
    final pos = scrollController.position;
    _markHomeScrollActive();
    _updateHomeShowcaseVisibility(pos.pixels);

    // 预加载游戏
    final prefetchThreshold = pos.viewportDimension * 1.5;
    if (pos.pixels + prefetchThreshold >= pos.maxScrollExtent) {
      menuController.loadMoreGames();
    }

    // 更新回到顶部按钮
    final shouldShow = pos.pixels > 420;
    if (shouldShow != showBackToTop.value) {
      showBackToTop.value = shouldShow;
    }

    // 解锁延迟加载的图片
    if (!allowDeferredHomeImages.value && pos.pixels > 120) {
      allowDeferredHomeImages.value = true;
    }
  }

  /// 启动延迟加载的资源
  void _kickOffHomeDeferredResources() {
    if (_didKickOffHomeDeferredResources) return;
    _didKickOffHomeDeferredResources = true;

    final appInfo = Get.find<AppInfoService>();
    final locale = Get.locale;
    final resolvedLang = normalizeApiLang(
      locale?.toLanguageTag() ?? locale?.languageCode,
    );

    allowAnnouncementFetch.value = true;

    unawaited(menuController.ensureInitialGamesLoaded());
    if (appInfo.banners.isEmpty) {
      unawaited(appInfo.fetchAppBanners(lang: resolvedLang));
    }
    if (Get.isRegistered<JackpotService>()) {
      final jackpotService = Get.find<JackpotService>();
      if (jackpotService.jackpotList.isEmpty) {
        unawaited(jackpotService.ensureLoaded());
      }
    }
  }

  /// 标记首页滚动活跃（用于暂停自动播放）
  void _markHomeScrollActive() {
    if (!AppConfig.homePauseAutoPlayWhileScrolling) {
      return;
    }

    if (!pauseHomeAutoPlay.value) {
      pauseHomeAutoPlay.value = true;
    }

    // 使用BaseController的addTimer注册Timer
    final timer = Timer(
      AppConfig.homeAutoPlayResumeDelay,
      () {
        if (pauseHomeAutoPlay.value) {
          pauseHomeAutoPlay.value = false;
        }
      },
    );
    addTimer(timer);
  }

  /// 更新首页展示区可见性
  void _updateHomeShowcaseVisibility(double scrollOffset) {
    final visible = scrollOffset < homeShowcaseAutoPlayCutoff;
    if (visible != homeShowcaseVisible.value) {
      homeShowcaseVisible.value = visible;
    }
  }

  /// 延迟解锁图片加载
  void _unlockDeferredHomeImagesLater() {
    final timer = Timer(const Duration(milliseconds: 1200), () {
      if (!allowDeferredHomeImages.value) {
        allowDeferredHomeImages.value = true;
      }
    });
    addTimer(timer);
  }

  /// 滚动到顶部
  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
}
