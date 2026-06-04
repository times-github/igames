import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/base/base_controller.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/app_close_button.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/game_card.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/app/modules/widgets/common_header.dart';
import 'package:igames/app/modules/widgets/jackpot_scroller.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igames/config/app_config_export.dart';

/// 简单的Timer管理器，用于StatefulWidget
class _TimerManager extends BaseController {
  _TimerManager() {
    onInit();
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    super.key,
    required this.controller,
    required this.auth,
    required this.menuController,
  });

  final HomeController controller;
  final AuthController auth;
  final GameMenuController menuController;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ScrollController _scrollController = ScrollController();
  late final _TimerManager _timerManager; // 使用TimerManager管理Timer
  static const int _priorityHomeImageCount = 6;
  static const double _homeShowcaseAutoPlayCutoff = 320;
  bool _showBackToTop = false;
  bool _allowAnnouncementFetch = false;
  bool _allowDeferredHomeImages = false;
  bool _didKickOffHomeDeferredResources = false;
  bool _pauseHomeAutoPlay = false;
  bool _homeShowcaseVisible = true;

  @override
  void initState() {
    super.initState();
    _timerManager = _TimerManager(); // 初始化TimerManager
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickOffHomeDeferredResources();
      _unlockDeferredHomeImagesLater();
    });
  }

  void _handleScroll() {
    final pos = _scrollController.position;
    _markHomeScrollActive();
    _updateHomeShowcaseVisibility(pos.pixels);
    final prefetchThreshold = pos.viewportDimension * 1.5;
    if (pos.pixels + prefetchThreshold >= pos.maxScrollExtent) {
      widget.menuController.loadMoreGames();
    }
    final shouldShow = pos.pixels > 420;
    if (shouldShow != _showBackToTop) {
      setState(() {
        _showBackToTop = shouldShow;
      });
    }
    if (!_allowDeferredHomeImages && pos.pixels > 120) {
      setState(() {
        _allowDeferredHomeImages = true;
      });
    }
  }

  void _kickOffHomeDeferredResources() {
    if (_didKickOffHomeDeferredResources || !mounted) return;
    _didKickOffHomeDeferredResources = true;

    final appInfo = Get.find<AppInfoService>();
    final locale = Get.locale;
    final resolvedLang = normalizeApiLang(
      locale?.toLanguageTag() ?? locale?.languageCode,
    );

    setState(() {
      _allowAnnouncementFetch = true;
    });

    unawaited(widget.menuController.ensureInitialGamesLoaded());
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

  void _markHomeScrollActive() {
    if (!AppConfig.homePauseAutoPlayWhileScrolling) {
      return;
    }

    if (!_pauseHomeAutoPlay && mounted) {
      setState(() {
        _pauseHomeAutoPlay = true;
      });
    }

    // 使用TimerManager注册Timer
    final timer = Timer(
      AppConfig.homeAutoPlayResumeDelay,
      () {
        if (!mounted || !_pauseHomeAutoPlay) return;
        setState(() {
          _pauseHomeAutoPlay = false;
        });
      },
    );
    _timerManager.addTimer(timer);
  }

  void _updateHomeShowcaseVisibility(double pixels) {
    final nextValue = pixels < _homeShowcaseAutoPlayCutoff;
    if (nextValue == _homeShowcaseVisible || !mounted) {
      return;
    }
    setState(() {
      _homeShowcaseVisible = nextValue;
    });
  }

  bool get _homeAutoPlayEnabled => !_pauseHomeAutoPlay && _homeShowcaseVisible;

  void _unlockDeferredHomeImagesLater() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted || _allowDeferredHomeImages) return;
      setState(() {
        _allowDeferredHomeImages = true;
      });
    });
  }

  bool _shouldLoadGameImage(int index) {
    return _allowDeferredHomeImages || index < _priorityHomeImageCount;
  }

  @override
  @override
  void dispose() {
    _timerManager.onClose(); // TimerManager会自动清理所有Timer
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: _buildContent(context, widget.menuController),
        ),
        if (_showBackToTop)
          Positioned(
            bottom: 90,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B66FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.keyboard_double_arrow_up,
                        color: Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      'backToTop'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, GameMenuController menuController) {
    final appInfo = Get.find<AppInfoService>();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final r = Responsive.fromContext(context);
    final topBarHeight = r.size(41);
    final categoryHeaderHeight = r.size(35);
    final slotProviderHeight = r.size(64);
    const bottomNavHeight = 2.0;
    final bottomSpacer = bottomNavHeight + bottomInset + 2;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: menuController.refreshGames,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: HomeTopBarDelegate(
              auth: widget.auth,
              height: topBarHeight,
            ),
          ),
          SliverToBoxAdapter(
            //这个是公告栏
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RepaintBoundary(
                    child: HomeBannerCarousel(
                      appInfo: appInfo,
                      autoPlayEnabled: _homeAutoPlayEnabled,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child: HomeAnnouncementBar(
                      service: Get.find<AnnouncementService>(),
                      shouldFetch: _allowAnnouncementFetch,
                      autoPlayEnabled: _homeAutoPlayEnabled,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RepaintBoundary(
                    child:
                        JackpotScroller(autoPlayEnabled: _homeAutoPlayEnabled),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: CategoryHeaderDelegate(
              menuController: menuController,
              height: categoryHeaderHeight,
            ),
          ),
          Obx(() {
            if (!menuController.showSlotProviderFilter) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverPersistentHeader(
              pinned: true,
              floating: false,
              delegate: SlotProviderHeaderDelegate(
                menuController: menuController,
                height: slotProviderHeight,
              ),
            );
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          _buildGameGridSliver(context, menuController),
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacer)),
        ],
      ),
    );
  }

  SliverPadding _buildGameGridSliver(
      BuildContext context, GameMenuController menuController) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: Obx(() {
        final games = menuController.gameList;
        final isLoading = menuController.isLoading.value;
        final waitingForInitialLoad =
            !menuController.initialLoadTriggered.value && games.isEmpty;

        if (waitingForInitialLoad || (games.isEmpty && isLoading)) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppConfig.btnSelectedBorderColor,
                ),
              ),
            ),
          );
        }

        if (games.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                menuController.loadError.value
                    ? 'checkNetwork'.tr
                    : 'noGame'.tr,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: AppConfig.homeGameGridCrossAxisCount,
            mainAxisSpacing: 4,
            crossAxisSpacing: 8,
            childAspectRatio: AppConfig.gameCardAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final game = games[index];
              return _mobileGameCard(
                context,
                game,
                menuController,
                shouldLoadImage: _shouldLoadGameImage(index),
              );
            },
            childCount: games.length,
          ),
        );
      }),
    );
  }
}

class HomeTopBarDelegate extends SliverPersistentHeaderDelegate {
  HomeTopBarDelegate({required this.auth, required this.height});

  final AuthController auth;
  final double height;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      alignment: Alignment.center,
      child: buildCommonHeader(
        context,
        auth,
        showNotification: true,
        showMenu: true,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant HomeTopBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.auth != auth;
  }
}

class HomeAnnouncementBar extends StatefulWidget {
  const HomeAnnouncementBar({
    super.key,
    required this.service,
    required this.shouldFetch,
    required this.autoPlayEnabled,
  });

  final AnnouncementService service;
  final bool shouldFetch;
  final bool autoPlayEnabled;

  @override
  State<HomeAnnouncementBar> createState() => _HomeAnnouncementBarState();
}

class _HomeAnnouncementBarState extends State<HomeAnnouncementBar> {
  final Duration _stayDuration = const Duration(seconds: 4);
  final Duration _animDuration = const Duration(milliseconds: 380);
  List<Announcement> _announcements = [];
  int _currentIndex = 0;
  bool _hasRequested = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tryFetchAnnouncements();
  }

  @override
  void didUpdateWidget(covariant HomeAnnouncementBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.shouldFetch && widget.shouldFetch) {
      _tryFetchAnnouncements();
    }
    if (oldWidget.autoPlayEnabled != widget.autoPlayEnabled) {
      _syncTickerState();
    }
  }

  void _tryFetchAnnouncements() {
    if (!widget.shouldFetch || _hasRequested) return;
    _hasRequested = true;
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final result = await widget.service.getAnnouncements(
        type: 'announcement',
        page: 1,
        size: 20,
      );
      final list = (result['list'] as List<Announcement>?)
              ?.where((item) => item.type == 'announcement')
              .toList() ??
          [];
      if (mounted) {
        //判断是否挂载
        setState(() {
          _announcements = list;
          _currentIndex = 0;
          _loading = false;
        });
        _syncTickerState();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _syncTickerState() {
    if (!mounted) return;
    setState(() {});
  }

  void _showNextAnnouncement() {
    if (!mounted || !widget.autoPlayEnabled || _announcements.length <= 1) {
      return;
    }
    setState(() {
      _currentIndex = (_currentIndex + 1) % _announcements.length;
    });
  }

  void _handleMarqueeCycleComplete(int index) {
    if (index != _currentIndex) return;
    _showNextAnnouncement();
  }

  String _normalizeAnnouncementText(String? value) {
    if (value == null) return '';
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRequested) {
      return const SizedBox(height: 44);
    }
    if (_loading && _announcements.isEmpty) {
      return const SizedBox(height: 44);
    }
    if (_announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _announcements[_currentIndex];
    final currentIndex = _currentIndex;
    final titleText = _normalizeAnnouncementText(current.title);
    final contentText = _normalizeAnnouncementText(
      current.content ?? current.summary,
    );
    return GestureDetector(
      onTap: () => _showAnnouncementDialog(context, current),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final r = Responsive.fromConstraints(constraints, context);
          final barHeight = r.size(44);
          final horizontalPadding = r.size(14);
          final iconSize = r.size(26);
          final iconGap = r.size(10);
          final titleSize = r.font(15);

          return Container(
            height: barHeight,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/top_roll_bg.2bca030a.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/tongzhi.png',
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.low,
                ),
                SizedBox(width: iconGap),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: _animDuration,
                    transitionBuilder: (child, animation) {
                      final offsetTween = Tween<Offset>(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      );
                      return ClipRect(
                        child: SlideTransition(
                          position: offsetTween.animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: _AnnouncementTickerText(
                      key: ValueKey<String>(
                        '$currentIndex-${widget.autoPlayEnabled}-$titleText-$contentText',
                      ),
                      title: titleText.isNotEmpty ? titleText : contentText,
                      content: contentText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                      ),
                      titleDuration: const Duration(seconds: 3),
                      contentStaticDuration: _stayDuration,
                      autoPlayEnabled: widget.autoPlayEnabled,
                      onCycleComplete:
                          widget.autoPlayEnabled && _announcements.length > 1
                              ? () => _handleMarqueeCycleComplete(currentIndex)
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAnnouncementDialog(
      BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.66),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppConfig.buttonColor.withValues(alpha: 0.26),
                const Color(0xFF103C3E).withValues(alpha: 0.96),
                const Color(0xFF0A2428).withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppConfig.btnSelectedBorderColor.withValues(alpha: 0.72),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppConfig.btnSelectedBorderColor.withValues(alpha: 0.18),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关闭按钮
              Align(
                alignment: Alignment.topRight,
                child: AppCloseButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // 内容
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    announcement.content ?? announcement.summary ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // 操作按钮
              SizedBox(
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Get.toNamed(Routes.MESSAGE);
                        },
                        child: Text(
                          'viewAll'.tr,
                          style: const TextStyle(
                            color: AppConfig.btnSelectedBorderColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Get.toNamed(Routes.MESSAGE_DETAIL,
                              arguments: announcement.id);
                        },
                        child: Text(
                          'detail'.tr,
                          style: const TextStyle(
                            color: AppConfig.btnSelectedBorderColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTickerText extends StatefulWidget {
  const _AnnouncementTickerText({
    super.key,
    required this.title,
    required this.content,
    required this.style,
    required this.titleDuration,
    required this.contentStaticDuration,
    required this.autoPlayEnabled,
    this.onCycleComplete,
  });

  final String title;
  final String content;
  final TextStyle style;
  final Duration titleDuration;
  final Duration contentStaticDuration;
  final bool autoPlayEnabled;
  final VoidCallback? onCycleComplete;

  @override
  State<_AnnouncementTickerText> createState() =>
      _AnnouncementTickerTextState();
}

class _AnnouncementTickerTextState extends State<_AnnouncementTickerText>
    with SingleTickerProviderStateMixin {
  static const double _pixelsPerSecond = 42;
  static const double _contentEndPadding = 24;
  static const Duration _contentEndPauseDuration = Duration(milliseconds: 1500);

  late final AnimationController _controller;
  Timer? _phaseTimer;
  bool _showContent = false;
  bool _isScrolling = false;
  double _scrollStartOffset = 0;
  double _scrollDistance = 0;
  Duration? _scrollDuration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_handleAnimationStatus);
    _startTitlePhase();
  }

  @override
  void didUpdateWidget(covariant _AnnouncementTickerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.content != widget.content ||
        oldWidget.autoPlayEnabled != widget.autoPlayEnabled) {
      _startTitlePhase();
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _phaseTimer?.cancel();
    _phaseTimer = Timer(_contentEndPauseDuration, () {
      if (!mounted) return;
      _completeCycle();
    });
  }

  void _startTitlePhase() {
    _phaseTimer?.cancel();
    _controller.stop();
    _controller.reset();
    _isScrolling = false;
    _scrollStartOffset = 0;
    _scrollDistance = 0;
    _scrollDuration = null;

    if (_showContent && mounted) {
      setState(() {
        _showContent = false;
      });
    } else {
      _showContent = false;
    }

    if (!widget.autoPlayEnabled) return;
    _phaseTimer = Timer(widget.titleDuration, _startContentPhase);
  }

  void _startContentPhase() {
    if (!mounted || !widget.autoPlayEnabled) return;
    if (widget.content.trim().isEmpty) {
      _completeCycle();
      return;
    }
    setState(() {
      _showContent = true;
    });
  }

  void _completeCycle() {
    if (!mounted || !widget.autoPlayEnabled) return;
    if (widget.onCycleComplete != null) {
      widget.onCycleComplete?.call();
      return;
    }
    _startTitlePhase();
  }

  void _updateScrollState({
    required bool shouldScroll,
    required double startOffset,
    required double distance,
    required Duration duration,
  }) {
    if (_isScrolling == shouldScroll &&
        _scrollStartOffset == startOffset &&
        _scrollDistance == distance &&
        _scrollDuration == duration) {
      return;
    }

    _controller.stop();
    _controller.reset();
    _phaseTimer?.cancel();

    _isScrolling = shouldScroll;
    _scrollStartOffset = startOffset;
    _scrollDistance = distance;
    _scrollDuration = duration;

    if (_isScrolling) {
      _controller.duration = duration;
      _controller.forward();
    } else if (widget.onCycleComplete != null) {
      _phaseTimer = Timer(widget.contentStaticDuration, () {
        if (!mounted) return;
        _completeCycle();
      });
    } else if (widget.autoPlayEnabled) {
      _phaseTimer = Timer(widget.contentStaticDuration, () {
        if (!mounted) return;
        _completeCycle();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showContent) {
      return Text(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: widget.style,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final painter = TextPainter(
          text: TextSpan(text: widget.content, style: widget.style),
          maxLines: 1,
          textDirection: textDirection,
        )..layout(maxWidth: double.infinity);

        final textWidth = painter.width;
        final maxWidth = constraints.maxWidth;
        final shouldScroll = textWidth > maxWidth;
        final contentWidth = textWidth + _contentEndPadding;
        final startOffset = 0.0;
        final distance = shouldScroll ? (contentWidth - maxWidth) : 0.0;
        final duration = shouldScroll
            ? Duration(
                milliseconds:
                    ((distance / _pixelsPerSecond) * 1000).round().clamp(
                          2000,
                          45000,
                        ),
              )
            : const Duration(milliseconds: 1);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _updateScrollState(
            shouldScroll: shouldScroll,
            startOffset: startOffset,
            distance: distance,
            duration: duration,
          );
        });

        if (!shouldScroll) {
          return Text(
            widget.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            child: SizedBox(
              width: contentWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.content,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: widget.style,
                  ),
                  const SizedBox(width: _contentEndPadding),
                ],
              ),
            ),
            builder: (context, child) {
              final offset =
                  _scrollStartOffset - (_scrollDistance * _controller.value);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
          ),
        );
      },
    );
  }
}

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({
    super.key,
    required this.appInfo,
    required this.autoPlayEnabled,
  });

  final AppInfoService appInfo;
  final bool autoPlayEnabled;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _autoTimer;
  int _lastKnownBannerCount = -1;

  List<AppBanner> get _banners =>
      widget.appInfo.banners.isNotEmpty ? widget.appInfo.banners : _fallback;

  final List<AppBanner> _fallback = const [
    AppBanner(
      img: 'assets/images/getwiner.png',
      link: null,
      weight: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handlePageChange);
    _syncAutoScrollState();
  }

  @override
  void didUpdateWidget(covariant HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.autoPlayEnabled != widget.autoPlayEnabled) {
      _syncAutoScrollState();
    }
  }

  void _handlePageChange() {
    final page = _controller.page?.round() ?? 0;
    if (page != _current && page >= 0 && page < _banners.length) {
      setState(() {
        _current = page;
      });
    }
  }

  void _syncAutoScrollState() {
    _autoTimer?.cancel();
    if (!widget.autoPlayEnabled || _banners.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = ((_controller.page ?? 0).round() + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePageChange);
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onBannerTap(AppBanner banner) {
    final link = banner.link;
    if (link == null || link.isEmpty) return;
    if (link.startsWith('http')) {
      launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else {
      Get.toNamed(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final banners = widget.appInfo.banners.isNotEmpty
          ? widget.appInfo.banners.toList(growable: false)
          : _fallback;
      if (_lastKnownBannerCount != banners.length) {
        _lastKnownBannerCount = banners.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncAutoScrollState();
        });
      }
      return AspectRatio(
        aspectRatio: AppConfig.homeBannerAspectRatio,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return BannerCard(
                    imagePath: banner.img,
                    onTap: () => _onBannerTap(banner),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  final isActive = index == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: isActive ? 18 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard({required this.imagePath, this.onTap, super.key});

  final String imagePath;
  final VoidCallback? onTap;

  bool get _isBrandBanner => imagePath == kDefaultAppLogoAsset;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.transparent),
            _BannerImage(imagePath: imagePath),
            if (!_isBrandBanner)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath == kDefaultAppLogoAsset) {
      return const _BrandBannerArtwork();
    }

    final isNetwork = imagePath.startsWith('http');
    final image = isNetwork
        ? CompatibleImage.network(
            imagePath,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stack) => _fallback(),
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.fill,
            errorBuilder: (context, error, stack) => _fallback(),
          );
    return image;
  }

  Widget _fallback() {
    return const ColoredBox(color: Colors.transparent);
  }
}

class _BrandBannerArtwork extends StatelessWidget {
  const _BrandBannerArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF210B02), Color(0xFF4A1405), Color(0xFF7C2C06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: -20,
            top: -28,
            child: _BrandBannerGlow(
              size: 120,
              color: const Color(0x55FFDA65),
            ),
          ),
          Positioned(
            right: -12,
            bottom: -34,
            child: _BrandBannerGlow(
              size: 110,
              color: const Color(0x33FFF0B2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                const Expanded(
                  flex: 4,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: AppBrandLogo(
                      logo: kDefaultAppLogoAsset,
                      showBackground: false,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GETWINER.WIN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'CASINO · SPORTS · SLOTS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFFFFD987),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBannerGlow extends StatelessWidget {
  const _BrandBannerGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  CategoryHeaderDelegate({required this.menuController, required this.height});

  final GameMenuController menuController;
  final double height;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = overlapsContent
        ? AppConfig.webDesktopOuterBackground
        : Colors.transparent;
    return Container(
      color: bg,
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        decoration: BoxDecoration(
          color: bg,
        ),
        child: _PrimaryCategoryFilterBar(menuController: menuController),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.menuController != menuController;
  }
}

class _PrimaryCategoryFilterBar extends StatefulWidget {
  const _PrimaryCategoryFilterBar({required this.menuController});

  final GameMenuController menuController;

  @override
  State<_PrimaryCategoryFilterBar> createState() =>
      _PrimaryCategoryFilterBarState();
}

class _PrimaryCategoryFilterBarState extends State<_PrimaryCategoryFilterBar> {
  final ScrollController _scrollController = ScrollController();
  bool _showRightHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void didUpdateWidget(covariant _PrimaryCategoryFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) {
      if (_showRightHint) {
        setState(() => _showRightHint = false);
      }
      return;
    }

    final position = _scrollController.position;
    final nextValue = position.maxScrollExtent > 6 &&
        position.pixels < position.maxScrollExtent - 6;
    if (nextValue != _showRightHint && mounted) {
      setState(() => _showRightHint = nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = widget.menuController.gameCategories;
      final selected = widget.menuController.selectedCategory.value;
      return LayoutBuilder(
        builder: (context, constraints) {
          final r = Responsive.fromConstraints(constraints, context);
          final itemRadius = r.size(14);
          final itemHPadding = r.size(5);
          final itemVPadding = r.size(1);
          final itemGap = r.size(4);
          final iconSize = r.size(44);
          final labelSize = r.font(14.5);
          final hintWidth = r.size(34);
          final hintRadius = r.size(14);
          final hintIconSize = r.size(44);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(0, 0, hintWidth - 4, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: categories.map((category) {
                      final type = category.type;
                      final label = category.nameKey;
                      final iconAssetPath = category.assetPath;
                      final bool isSelected = selected == type;
                      return Padding(
                        padding: EdgeInsets.only(right: itemGap),
                        child: GestureDetector(
                          onTap: () =>
                              widget.menuController.selectCategory(type),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: itemHPadding,
                              vertical: itemVPadding,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppConfig.btnSelectedGradient
                                  : null,
                              color: isSelected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(itemRadius),
                              border: Border.all(
                                color: isSelected
                                    ? AppConfig.btnSelectedBorderColor
                                    : Colors.white.withValues(alpha: 0.14),
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: isSelected
                                  ? AppConfig.btnSelectedShadow
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CompatibleImage.asset(
                                  iconAssetPath,
                                  width: iconSize,
                                  height: iconSize,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: r.size(1)),
                                Text(
                                  label.tr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: labelSize,
                                    height: 1,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: AnimatedOpacity(
                      opacity: _showRightHint ? 1 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        width: hintWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(hintRadius),
                            bottomRight: Radius.circular(hintRadius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.42),
                            ],
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: AppConfig.btnSelectedBorderColor,
                          size: hintIconSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }
}

class _SlotProviderFilterBar extends StatefulWidget {
  const _SlotProviderFilterBar({required this.menuController});

  final GameMenuController menuController;

  @override
  State<_SlotProviderFilterBar> createState() => _SlotProviderFilterBarState();
}

class _SlotProviderFilterBarState extends State<_SlotProviderFilterBar> {
  static const AssetImage _providerCardBackground =
      AssetImage('assets/images/gamecategory/cardbg.png');
  final ScrollController _scrollController = ScrollController();
  bool _showRightHint = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void didUpdateWidget(covariant _SlotProviderFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) {
      if (_showRightHint) {
        setState(() => _showRightHint = false);
      }
      return;
    }

    final position = _scrollController.position;
    final nextValue = position.maxScrollExtent > 6 &&
        position.pixels < position.maxScrollExtent - 6;
    if (nextValue != _showRightHint && mounted) {
      setState(() => _showRightHint = nextValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providers = widget.menuController.slotProviders;
    return Obx(
      () {
        final selectedId = widget.menuController.selectedSlotProvider.value;
        return LayoutBuilder(
          builder: (context, constraints) {
            final r = Responsive.fromConstraints(constraints, context);
            final itemWidth = r.size(72);
            final itemHeight = r.size(54);
            final itemRadius = r.size(16);
            final cardInnerRadius = r.size(15);
            final itemGap = r.size(4);
            final logoBoxWidth = r.size(42);
            final logoBoxHeight = r.size(22);
            final textSize = r.font(9.5);
            final innerHPadding = r.size(5);
            final innerVPadding = r.size(4);
            final hintWidth = r.size(34);
            final hintRadius = r.size(14);
            final hintIconSize = r.size(44);
            final fallbackIconSize = r.size(28);

            return SizedBox(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(right: hintWidth - 4),
                    child: Row(
                      children: providers.map((provider) {
                        final isSelected = provider.id == selectedId;
                        final label = provider.translateLabel
                            ? provider.label.tr
                            : provider.label;
                        return Padding(
                          padding: EdgeInsets.only(right: itemGap),
                          child: GestureDetector(
                            onTap: () => widget.menuController
                                .selectSlotProvider(provider.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: itemWidth,
                              height: itemHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(itemRadius),
                                border: Border.all(
                                  color: isSelected
                                      ? AppConfig.btnSelectedBorderColor
                                      : Colors.white.withValues(alpha: 0.08),
                                  width: isSelected ? 1.8 : 0.9,
                                ),
                                boxShadow: isSelected
                                    ? AppConfig.btnSelectedShadow
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: r.size(8),
                                          offset: Offset(
                                            0,
                                            r.size(3),
                                          ),
                                        ),
                                      ],
                              ),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(cardInnerRadius),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    const DecoratedBox(
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: _providerCardBackground,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isSelected
                                              ? [
                                                  AppConfig.btnSelectedColor
                                                      .withValues(alpha: 0.85),
                                                  AppConfig.btnSelectedColor
                                                      .withValues(alpha: 0.28),
                                                ]
                                              : [
                                                  Colors.black.withValues(
                                                    alpha: 0.12,
                                                  ),
                                                  Colors.black.withValues(
                                                    alpha: 0.22,
                                                  ),
                                                ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        innerHPadding,
                                        innerVPadding,
                                        innerHPadding,
                                        innerVPadding,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: logoBoxWidth,
                                            height: logoBoxHeight,
                                            child: Center(
                                              child: Image.asset(
                                                provider.assetPath,
                                                fit: BoxFit.contain,
                                                filterQuality:
                                                    FilterQuality.low,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                  Icons.casino_rounded,
                                                  color: Colors.white54,
                                                  size: fallbackIconSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: r.size(3),
                                          ),
                                          Text(
                                            label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: textSize,
                                              height: 1,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                              shadows: [
                                                Shadow(
                                                  color:
                                                      Colors.black.withValues(
                                                    alpha: 0.28,
                                                  ),
                                                  blurRadius: r.size(4),
                                                  offset: Offset(
                                                    0,
                                                    r.size(1),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          opacity: _showRightHint ? 1 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            width: hintWidth,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(hintRadius),
                                bottomRight: Radius.circular(hintRadius),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.42),
                                ],
                              ),
                            ),
                            alignment: Alignment.centerRight,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: AppConfig.btnSelectedBorderColor,
                              size: hintIconSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class SlotProviderHeaderDelegate extends SliverPersistentHeaderDelegate {
  SlotProviderHeaderDelegate({
    required this.menuController,
    required this.height,
  });

  final GameMenuController menuController;
  final double height;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bg = overlapsContent
        ? AppConfig.webDesktopOuterBackground
        : Colors.transparent;
    return Container(
      color: bg,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerLeft,
            child: _SlotProviderFilterBar(menuController: menuController),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SlotProviderHeaderDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.menuController != menuController;
  }
}

Widget _mobileGameCard(
    BuildContext context, GameList game, GameMenuController menuController,
    {required bool shouldLoadImage}) {
  final authController = Get.find<AuthController>();
  return LayoutBuilder(
    builder: (context, constraints) {
      final r = Responsive.fromConstraints(
        constraints,
        context,
        designWidth: 104,
      );

      return GameCard(
        game: game,
        shouldLoadImage: shouldLoadImage,
        topLeftBadgeOffset: EdgeInsets.zero,
        nameOverlayColor: Colors.black.withValues(alpha: 0.42),
        namePadding: EdgeInsets.symmetric(
          horizontal: r.size(4),
          vertical: r.size(2),
        ),
        onTap: () => menuController.startGame(context, game),
        topRightAction: Obx(() {
          if (!authController.isLoggedIn.value) {
            return const SizedBox.shrink();
          }

          return GameCardFavoriteAction(
            isFavorite: game.isFavorite == true,
            size: r.size(18),
            padding: EdgeInsets.all(r.size(5)),
            onTap: () => menuController.toggleFavorite(game),
          );
        }),
      );
    },
  );
}
