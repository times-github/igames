import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/game_cover_image.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/app/modules/widgets/common_header.dart';
import 'package:igames/app/modules/widgets/jackpot_scroller.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igames/config/app_config_export.dart';

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
  static const int _priorityHomeImageCount = 6;
  bool _showBackToTop = false;
  bool _allowAnnouncementFetch = false;
  bool _allowDeferredHomeImages = false;
  bool _didKickOffHomeDeferredResources = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickOffHomeDeferredResources();
      _unlockDeferredHomeImagesLater();
    });
  }

  void _handleScroll() {
    final pos = _scrollController.position;
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
    final jackpotService = Get.find<JackpotService>();
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
    if (jackpotService.jackpotList.isEmpty) {
      unawaited(jackpotService.ensureLoaded());
    }
  }

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
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration:
              const BoxDecoration(gradient: AppColors.darkBackgroundGradient),
          child: SafeArea(
            bottom: false,
            child: _buildContent(context, widget.menuController),
          ),
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
              height: 41,
            ),
          ),
          SliverToBoxAdapter(
            //这个是公告栏
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeAnnouncementBar(
                    service: Get.find<AnnouncementService>(),
                    shouldFetch: _allowAnnouncementFetch,
                  ),
                  const SizedBox(height: 10),
                  HomeBannerCarousel(appInfo: appInfo),
                  const SizedBox(height: 10),
                  const JackpotScroller(),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            floating: false,
            delegate: CategoryHeaderDelegate(
              menuController: menuController,
              height: 40,
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
                height: 61,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 8,
            childAspectRatio: 1.05,
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
      color: AppColors.backgroundDark,
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
  });

  final AnnouncementService service;
  final bool shouldFetch;

  @override
  State<HomeAnnouncementBar> createState() => _HomeAnnouncementBarState();
}

class _HomeAnnouncementBarState extends State<HomeAnnouncementBar> {
  final Duration _stayDuration = const Duration(seconds: 4);
  final Duration _animDuration = const Duration(milliseconds: 380);
  List<Announcement> _announcements = [];
  int _currentIndex = 0;
  Timer? _timer;
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
        _startTicker();
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _startTicker() {
    _timer?.cancel();
    if (_announcements.length <= 1) return;
    _timer = Timer.periodic(_stayDuration, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _announcements.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasRequested) {
      return const SizedBox(height: 32);
    }
    if (_loading && _announcements.isEmpty) {
      return const SizedBox(height: 32);
    }
    if (_announcements.isEmpty) {
      return const SizedBox.shrink();
    }

    final current = _announcements[_currentIndex];
    return GestureDetector(
      onTap: () => _showAnnouncementDialog(context, current),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 41, 43, 47).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            const Icon(Icons.campaign, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: _animDuration,
                transitionBuilder: (child, animation) {
                  final offsetTween = Tween<Offset>(
                      begin: const Offset(0, 0.4), end: Offset.zero);
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
                child: Text(
                  current.title,
                  key: ValueKey<int>(_currentIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(
      BuildContext context, Announcement announcement) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2A2D3E), Color(0xFF1A1D2E)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 关闭按钮
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon:
                      const Icon(Icons.close, color: Colors.white54, size: 22),
                ),
              ),
              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  announcement.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      height: 1.6,
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
                            color: Color(0xFF6C63FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
                            color: Color(0xFF6C63FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, required this.appInfo});

  final AppInfoService appInfo;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const double _bannerAspectRatio = 2.22;
  final PageController _controller = PageController();
  int _current = 0;
  Timer? _autoTimer;

  List<AppBanner> get _banners =>
      widget.appInfo.banners.isNotEmpty ? widget.appInfo.banners : _fallback;

  final List<AppBanner> _fallback = const [
    AppBanner(
      img: 'assets/images/getwiner.png',
      link: null,
      title: null,
      weight: 0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handlePageChange);
    _startAutoScroll();
  }

  void _handlePageChange() {
    final page = _controller.page?.round() ?? 0;
    if (page != _current && page >= 0 && page < _banners.length) {
      setState(() {
        _current = page;
      });
    }
  }

  void _startAutoScroll() {
    _autoTimer?.cancel();
    if (_banners.length <= 1) return;
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = ((_controller.page ?? 0).round() + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
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
    final banners = _banners;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: _bannerAspectRatio,
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return BannerCard(
                imagePath: banner.img,
                title: banner.title,
                onTap: () => _onBannerTap(banner),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (index) {
            final isActive = index == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
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
      ],
    );
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard(
      {required this.imagePath, this.title, this.onTap, super.key});

  final String imagePath;
  final String? title;
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
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.darkBackgroundGradient,
              ),
            ),
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
            if (title != null && title!.isNotEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
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
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _fallback(),
          )
        : Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => _fallback(),
          );
    return image;
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.darkBackgroundGradient,
      ),
    );
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
    final bg = Colors.white.withValues(alpha: overlapsContent ? 0.07 : 0.05);
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _PrimaryCategoryFilterBar(menuController: menuController),
            ),
          ),
        ),
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
      return Stack(
        alignment: Alignment.centerLeft,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 30, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: categories.map((category) {
                  final type = category.type;
                  final label = category.nameKey;
                  final iconAssetPath = category.assetPath;
                  final bool isSelected = selected == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GestureDetector(
                      onTap: () => widget.menuController.selectCategory(type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF8A6CFF),
                                    Color(0xFF6D7BFF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected
                              ? null
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF8A6CFF)
                                : Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CompatibleImage.asset(
                              iconAssetPath,
                              width: 49,
                              height: 49,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              label.tr,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
                    width: 34,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
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
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        return SizedBox(
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: providers.map((provider) {
                    final isSelected = provider.id == selectedId;
                    final label = provider.translateLabel
                        ? provider.label.tr
                        : provider.label;
                    return Padding(
                      padding: const EdgeInsets.only(right: 1),
                      child: GestureDetector(
                        onTap: () => widget.menuController
                            .selectSlotProvider(provider.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 68,
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF8A6CFF),
                                      Color(0xFF5A6DFF),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected
                                ? null
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF9B86FF)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF7E66FF)
                                          .withValues(alpha: 0.24),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            spacing: 1,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 40,
                                width: 40,
                                child: Center(
                                  child: Image.asset(
                                    provider.assetPath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.casino_rounded,
                                      color: Colors.white54,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
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
                        width: 34,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                            bottomRight: Radius.circular(14),
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
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                          size: 44,
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
    final bg = Colors.white.withValues(alpha: overlapsContent ? 0.07 : 0.05);
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 0, 6, 0),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              child: _SlotProviderFilterBar(menuController: menuController),
            ),
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

  return InkWell(
    onTap: () => menuController.startGame(context, game),
    child: Ink(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [AppColors.cardBackground, AppColors.backgroundLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.cardBackgroundDark,
              child: () {
                final resolvedUrl = _resolveGameIconUrl(game.iconUrl);
                if (!shouldLoadImage ||
                    resolvedUrl == null ||
                    resolvedUrl.isEmpty) {
                  return _gameCardLogoFallback();
                }
                return GameCoverImage(
                  url: resolvedUrl,
                  fit: BoxFit.cover,
                  fallback: _gameCardLogoFallback(),
                );
              }(),
            ),
            if ((game.gamehall ?? '').isNotEmpty)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    game.gamehall ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                  ),
                ),
              ),
            // 收藏图标（只在登录时显示）
            Obx(() {
              if (!authController.isLoggedIn.value) {
                return const SizedBox.shrink();
              }

              return Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () {
                    menuController.toggleFavorite(game);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      game.isFavorite == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          game.isFavorite == true ? Colors.red : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              );
            }),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    game.name ?? 'Game',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
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

Widget _gameCardLogoFallback() {
  return Image.asset(
    kDefaultAppLogoAsset,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.casino, color: Colors.white38, size: 40),
  );
}

String? _resolveGameIconUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final trimmed = url.trim();
  if (trimmed.startsWith('http')) return trimmed;
  if (trimmed.startsWith('//')) return 'https:$trimmed';
  final path = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
  return '${AppConfig.gameIconBaseUrl}$path';
}
