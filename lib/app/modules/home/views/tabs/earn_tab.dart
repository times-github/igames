import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/config/app_config_export.dart';

// ─── 数据模型 ────────────────────────────────────────────────────────────────

class InviteStats {
  final double totalCommission;
  final int directFriends;
  final int totalFriends;
  final int activeFriends;
  const InviteStats({
    required this.totalCommission,
    required this.directFriends,
    required this.totalFriends,
    required this.activeFriends,
  });

  static const empty = InviteStats(
    totalCommission: 0,
    directFriends: 0,
    totalFriends: 0,
    activeFriends: 0,
  );

  factory InviteStats.fromMap(Map<String, dynamic> data) {
    return InviteStats(
      totalCommission: _toDouble(data['total_commission']),
      directFriends: _toInt(data['friend_count']),
      totalFriends: _toInt(data['total_friend_count']),
      activeFriends: _toInt(data['active_friend_count']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class InviteRebateLevel {
  final int level;
  final double levelRate;
  final double effectiveRate;
  final double rebateAmount;
  final bool eligible;

  const InviteRebateLevel({
    required this.level,
    required this.levelRate,
    required this.effectiveRate,
    required this.rebateAmount,
    required this.eligible,
  });

  factory InviteRebateLevel.fromMap(Map<String, dynamic> data) {
    return InviteRebateLevel(
      level: _toInt(data['level']),
      levelRate: _toDouble(data['level_rate']),
      effectiveRate: _toDouble(data['effective_rate']),
      rebateAmount: _toDouble(data['rebate_amount']),
      eligible: data['eligible'] == true,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class InviteRebatePreview {
  final List<InviteRebateLevel> levels;

  const InviteRebatePreview({
    required this.levels,
  });

  static const empty = InviteRebatePreview(levels: []);

  factory InviteRebatePreview.fromMap(Map<String, dynamic> data) {
    final rawLevels = data['levels'];
    final levels = rawLevels is List
        ? rawLevels
            .whereType<Map>()
            .map((item) => InviteRebateLevel.fromMap(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <InviteRebateLevel>[];
    return InviteRebatePreview(levels: levels);
  }
}

class WeeklyData {
  final double totalCommission;
  final String currentWeekClaimWindow;
  final bool lastWeekClaimed;

  const WeeklyData({
    required this.totalCommission,
    required this.currentWeekClaimWindow,
    required this.lastWeekClaimed,
  });
}

// ─── Mock 数据 ───────────────────────────────────────────────────────────────

const _kMockWeekly = WeeklyData(
  totalCommission: 0,
  currentWeekClaimWindow: '下周一到周日',
  lastWeekClaimed: false,
);

const _kMockPendingCommission = 0.0;

const _kEarnBannerAspectRatio = 2.22;

// ─── 导航项数据 ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const _kNavItems = [
  _NavItem(Icons.rule_folder_outlined, '佣金规则'),
  // _NavItem(Icons.people_alt_outlined, '邀请好友'),
  // _NavItem(Icons.assignment_outlined, '好友任务'),
  // _NavItem(Icons.bar_chart_outlined, '数据报表'),
  _NavItem(Icons.account_balance_wallet_outlined, '佣金记录'),
  // _NavItem(Icons.info_outline, '规则说明'),
];

// ─── EarnTab ─────────────────────────────────────────────────────────────────

class EarnTab extends StatefulWidget {
  const EarnTab({super.key, required this.auth});
  final AuthController auth;

  @override
  State<EarnTab> createState() => _EarnTabState();
}

class _EarnTabState extends State<EarnTab>
    with AutomaticKeepAliveClientMixin<EarnTab> {
  static const double _inviteNavBarHeight = 68;
  int _selectedWeek = 0;
  String _inviteLink = '';
  String _inviteLang = 'id';
  String _inviteCode = '';
  InviteStats _stats = InviteStats.empty;
  InviteRebatePreview _rebatePreview = InviteRebatePreview.empty;
  List<AppBanner> _earnBanners = const [];
  bool _useAppLang = true;
  bool _loadingBanners = true;
  bool _loadingLink = true;
  bool _loadingRebatePreview = true;
  Worker? _authWorker;
  bool _statsLoadScheduled = false;
  bool _rebatePreviewLoadScheduled = false;
  String _bannerLang = 'id';

  // static 缓存：跨 widget 实例，只请求一次
  static String? _cachedCode;
  static InviteStats? _cachedStats;
  static InviteRebatePreview? _cachedRebatePreview;
  static Future<InviteStats>? _statsRequest;
  static Future<InviteRebatePreview>? _rebatePreviewRequest;
  static final Map<String, List<AppBanner>> _cachedBannersByLang = {};
  static final Map<String, Future<List<AppBanner>>> _bannerRequestsByLang = {};
  static bool _hasLoadedStats = false;
  static bool _hasLoadedRebatePreview = false;
  static const List<String> _inviteLangs = ['id', 'en', 'zh'];

  @override
  void initState() {
    super.initState();
    _inviteLang = _resolveInviteLang();
    _bannerLang = _resolveBannerLang();
    _useAppLang = true;
    _authWorker = ever<bool>(widget.auth.isLoggedIn, _handleLoginStateChanged);
    _loadInviteCode();
    _loadInviteStats();
    _loadInviteRebatePreview();
    _loadEarnBanners();
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bannerLang = _resolveBannerLang();
    if (bannerLang != _bannerLang) {
      _bannerLang = bannerLang;
      _loadEarnBanners();
    }
    if (!_useAppLang) return;
    final appLang = _resolveInviteLang();
    if (appLang == _inviteLang) return;
    if (!mounted) return;
    setState(() {
      _inviteLang = appLang;
      _inviteLink = _buildInviteLink(_inviteCode, lang: _inviteLang);
    });
  }

  String _resolveInviteLang() {
    final raw = (Get.locale?.languageCode ?? 'id').toLowerCase();
    return _inviteLangs.contains(raw) ? raw : 'id';
  }

  String _resolveBannerLang() {
    return normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
    );
  }

  void _setInviteLang(String lang) {
    if (!_inviteLangs.contains(lang)) return;
    if (!mounted) return;
    setState(() {
      _useAppLang = false;
      _inviteLang = lang;
      _inviteLink = _buildInviteLink(_inviteCode, lang: _inviteLang);
    });
  }

  void _handleLoginStateChanged(bool isLoggedIn) {
    if (!isLoggedIn) {
      _cachedCode = null;
      _cachedStats = null;
      _cachedRebatePreview = null;
      _statsRequest = null;
      _rebatePreviewRequest = null;
      _hasLoadedStats = false;
      _hasLoadedRebatePreview = false;
      if (!mounted) return;
      setState(() {
        _inviteCode = '';
        _inviteLink = _buildInviteLink('', lang: _inviteLang);
        _loadingLink = false;
        _stats = InviteStats.empty;
        _rebatePreview = InviteRebatePreview.empty;
        _loadingRebatePreview = false;
      });
      return;
    }

    if (_cachedCode == null) {
      _loadInviteCode();
    }
    if (!_hasLoadedStats) {
      _loadInviteStats();
    }
    if (!_hasLoadedRebatePreview) {
      _loadInviteRebatePreview();
    }
  }

  Future<void> _loadInviteCode() async {
    // 未登录不请求
    if (!widget.auth.isLoggedIn.value) {
      if (mounted) setState(() => _loadingLink = false);
      return;
    }
    // 已有缓存，直接用
    if (_cachedCode != null) {
      if (mounted) {
        setState(() {
          _inviteCode = _cachedCode ?? '';
          _inviteLink = _buildInviteLink(_inviteCode, lang: _inviteLang);
          _loadingLink = false;
        });
      }
      return;
    }
    // 首次请求
    try {
      final resp = await ApiClient().post('/user/invite/code');
      final code = resp.data?['data']?['code'] as String?;
      _cachedCode = code ?? '';
      if (mounted) {
        setState(() {
          _inviteCode = _cachedCode ?? '';
          _inviteLink = _buildInviteLink(_inviteCode, lang: _inviteLang);
          _loadingLink = false;
        });
      }
    } catch (e) {
      debugPrint('invite/code error: $e');
      _cachedCode = '';
      if (mounted) {
        setState(() {
          _inviteCode = '';
          _inviteLink = _buildInviteLink('', lang: _inviteLang);
          _loadingLink = false;
        });
      }
    }
  }

  Future<void> _loadInviteStats() async {
    if (!widget.auth.isLoggedIn.value) {
      if (!mounted) return;
      setState(() => _stats = InviteStats.empty);
      return;
    }

    final cachedStats = _cachedStats;
    if (_hasLoadedStats && cachedStats != null) {
      if (!mounted) return;
      setState(() => _stats = cachedStats);
      return;
    }

    final pendingRequest = _statsRequest;
    if (pendingRequest != null) {
      final stats = await pendingRequest;
      if (!mounted) return;
      setState(() => _stats = stats);
      return;
    }

    final request = _fetchInviteStats();
    _statsRequest = request;
    final stats = await request;
    if (identical(_statsRequest, request)) {
      _statsRequest = null;
    }
    if (stats != InviteStats.empty) {
      _cachedStats = stats;
      _hasLoadedStats = true;
    }
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  Future<InviteStats> _fetchInviteStats() async {
    try {
      final response = await ApiClient().get('/user/invite/rebate/stats');
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['code']?.toString() == '1' &&
          data['data'] is Map) {
        return InviteStats.fromMap(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (e) {
      debugPrint('invite/rebate/stats error: $e');
    }
    return InviteStats.empty;
  }

  Future<void> _loadInviteRebatePreview() async {
    if (!widget.auth.isLoggedIn.value) {
      if (!mounted) return;
      setState(() {
        _rebatePreview = InviteRebatePreview.empty;
        _loadingRebatePreview = false;
      });
      return;
    }

    final cachedPreview = _cachedRebatePreview;
    if (_hasLoadedRebatePreview && cachedPreview != null) {
      if (!mounted) return;
      setState(() {
        _rebatePreview = cachedPreview;
        _loadingRebatePreview = false;
      });
      return;
    }

    final pendingRequest = _rebatePreviewRequest;
    if (pendingRequest != null) {
      final preview = await pendingRequest;
      if (!mounted) return;
      setState(() {
        _rebatePreview = preview;
        _loadingRebatePreview = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loadingRebatePreview = true);
    }

    final request = _fetchInviteRebatePreview();
    _rebatePreviewRequest = request;
    final preview = await request;
    if (identical(_rebatePreviewRequest, request)) {
      _rebatePreviewRequest = null;
    }
    if (preview.levels.isNotEmpty) {
      _cachedRebatePreview = preview;
      _hasLoadedRebatePreview = true;
    }
    if (!mounted) return;
    setState(() {
      _rebatePreview = preview;
      _loadingRebatePreview = false;
    });
  }

  Future<InviteRebatePreview> _fetchInviteRebatePreview() async {
    try {
      final response = await ApiClient().get('/user/invite/rebate/preview');
      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map &&
          data['code']?.toString() == '1' &&
          data['data'] is Map) {
        return InviteRebatePreview.fromMap(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
    } catch (e) {
      debugPrint('invite/rebate/preview error: $e');
    }
    return InviteRebatePreview.empty;
  }

  Future<void> _loadEarnBanners() async {
    final lang = _bannerLang;
    final cached = _cachedBannersByLang[lang];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _earnBanners = cached;
        _loadingBanners = false;
      });
      return;
    }

    final pending = _bannerRequestsByLang[lang];
    if (pending != null) {
      final banners = await pending;
      if (!mounted || lang != _bannerLang) return;
      setState(() {
        _earnBanners = banners;
        _loadingBanners = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _loadingBanners = true);
    }

    final request = Get.find<AppInfoService>().fetchBanners(
      sceneCode: 'earn',
      lang: lang,
    );
    _bannerRequestsByLang[lang] = request;
    final banners = await request;
    if (identical(_bannerRequestsByLang[lang], request)) {
      _bannerRequestsByLang.remove(lang);
    }
    _cachedBannersByLang[lang] = banners;
    if (!mounted || lang != _bannerLang) return;
    setState(() {
      _earnBanners = banners;
      _loadingBanners = false;
    });
  }

  void _openCommissionRules() {
    Get.to(() => const _CommissionRulesView());
  }

  String _buildInviteLink(String code, {String? lang}) {
    String base;
    if (kIsWeb) {
      final uri = Uri.base;
      final port = uri.port != 0 ? ':${uri.port}' : '';
      base = '${uri.scheme}://${uri.host}$port';
    } else {
      base = AppConfig.appWebUrl;
    }
    final resolvedLang = (lang ?? _inviteLang).toLowerCase();
    if (code.isEmpty) {
      return '$base/#/?lang=$resolvedLang';
    }
    return '$base/#/?lang=$resolvedLang&invite_code=$code';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.auth.isLoggedIn.value &&
        !_hasLoadedStats &&
        _statsRequest == null &&
        !_statsLoadScheduled) {
      _statsLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _statsLoadScheduled = false;
        if (!mounted || !widget.auth.isLoggedIn.value || _hasLoadedStats) {
          return;
        }
        _loadInviteStats();
      });
    }
    if (widget.auth.isLoggedIn.value &&
        !_hasLoadedRebatePreview &&
        _rebatePreviewRequest == null &&
        !_rebatePreviewLoadScheduled) {
      _rebatePreviewLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebatePreviewLoadScheduled = false;
        if (!mounted ||
            !widget.auth.isLoggedIn.value ||
            _hasLoadedRebatePreview) {
          return;
        }
        _loadInviteRebatePreview();
      });
    }
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = 82.0;
    final bottomPadding = bottomNavHeight + bottomInset + 16;
    final showEarnBanner = _loadingBanners || _earnBanners.isNotEmpty;

    final content = ListView(
      padding: EdgeInsets.only(
        top: _inviteNavBarHeight + 6,
        bottom: bottomPadding,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              if (showEarnBanner) ...[
                _InviteBannerCarousel(
                  banners: _earnBanners,
                  loading: _loadingBanners,
                ),
                const SizedBox(height: 12),
              ],
              _InviteStatsRow(stats: _stats),
              const SizedBox(height: 12),
              _PromoLinkCard(
                link: _inviteLink,
                loading: _loadingLink,
                currentLang: _inviteLang,
                langOptions: _inviteLangs,
                onSelectLang: _setInviteLang,
              ),
              const SizedBox(height: 12),
              _PendingCommissionCard(
                amount: _kMockPendingCommission,
                onClaim: () => widget.auth.ensureAuthenticated(context),
              ),
              const SizedBox(height: 12),
              _WeeklyCommissionSection(
                selectedWeek: _selectedWeek,
                onWeekChanged: (v) => setState(() => _selectedWeek = v),
                data: _kMockWeekly,
              ),
              const SizedBox(height: 12),
              _CommissionTierCard(
                levels: _rebatePreview.levels,
                loading: _loadingRebatePreview,
                onTapRuleDetails: _openCommissionRules,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.darkBackgroundGradient),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            content,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _InviteNavBar(
                onTapCommissionRules: _openCommissionRules,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _InviteNavBar ───────────────────────────────────────────────────────────

class _InviteNavBar extends StatelessWidget {
  const _InviteNavBar({
    required this.onTapCommissionRules,
  });

  final VoidCallback onTapCommissionRules;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _EarnTabState._inviteNavBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: const BoxDecoration(
        color: AppConfig.earnFloatingMenuBackground,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _kNavItems
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: item.label == '佣金规则' ? onTapCommissionRules : null,
                  child: SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppConfig.earnFloatingMenuIconBackground,
                                border: Border.all(
                                  color: AppConfig.earnFloatingMenuIconBorder,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white70,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 8.5),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CommissionRulesView extends StatefulWidget {
  const _CommissionRulesView();

  @override
  State<_CommissionRulesView> createState() => _CommissionRulesViewState();
}

class _CommissionRulesViewState extends State<_CommissionRulesView> {
  static final Map<String, List<AppBanner>> _cachedRulesByLang = {};
  static final Map<String, Future<List<AppBanner>>> _pendingRulesByLang = {};

  List<AppBanner> _banners = const [];
  bool _loading = true;
  late final String _lang;

  @override
  void initState() {
    super.initState();
    _lang = normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
    );
    _loadRules();
  }

  Future<void> _loadRules() async {
    final cached = _cachedRulesByLang[_lang];
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _banners = cached;
        _loading = false;
      });
      return;
    }

    final pending = _pendingRulesByLang[_lang];
    if (pending != null) {
      final banners = await pending;
      if (!mounted) return;
      setState(() {
        _banners = banners;
        _loading = false;
      });
      return;
    }

    final request = Get.find<AppInfoService>().fetchBanners(
      sceneCode: 'commission_rules',
      lang: _lang,
    );
    _pendingRulesByLang[_lang] = request;
    final banners = await request;
    if (identical(_pendingRulesByLang[_lang], request)) {
      _pendingRulesByLang.remove(_lang);
    }
    _cachedRulesByLang[_lang] = banners;
    if (!mounted) return;
    setState(() {
      _banners = banners;
      _loading = false;
    });
  }

  void _handleBack(BuildContext context) {
    final rootNavigator = Navigator.maybeOf(context, rootNavigator: true);
    if (rootNavigator != null && rootNavigator.canPop()) {
      rootNavigator.pop();
      return;
    }

    final navigator = Navigator.maybeOf(context);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => _handleBack(context),
        ),
        title: const Text(
          '佣金规则',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.darkBackgroundGradient,
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _banners.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      );
    }

    if (_banners.isEmpty) {
      return Center(
        child: Text(
          '暂无规则内容',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _banners.length,
      itemBuilder: (context, index) {
        return _CommissionRuleImageItem(
          imageUrl: _banners[index].img,
        );
      },
    );
  }
}

class _CommissionRuleImageItem extends StatelessWidget {
  const _CommissionRuleImageItem({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: IgnorePointer(
        child: Image.network(
          imageUrl,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          webHtmlElementStrategy: WebHtmlElementStrategy.never,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ─── _InviteBannerCarousel ───────────────────────────────────────────────────

class _InviteBannerCarousel extends StatefulWidget {
  const _InviteBannerCarousel({
    required this.banners,
    required this.loading,
  });

  final List<AppBanner> banners;
  final bool loading;

  @override
  State<_InviteBannerCarousel> createState() => _InviteBannerCarouselState();
}

class _InviteBannerCarouselState extends State<_InviteBannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant _InviteBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      final lastIndex = widget.banners.length - 1;
      if (_current > lastIndex) {
        _current = 0;
      }
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) {
      if (!widget.loading) {
        return const SizedBox.shrink();
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: _kEarnBannerAspectRatio,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkBackgroundGradient,
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: _kEarnBannerAspectRatio,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _EarnBannerPage(
                banner: banners[i],
                onTap: () => _onBannerTap(banners[i]),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (i) {
                  final active = i == _current;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _EarnBannerPage extends StatelessWidget {
  const _EarnBannerPage({
    required this.banner,
    required this.onTap,
  });

  final AppBanner banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasTitle = banner.title != null && banner.title!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.darkBackgroundGradient,
            ),
          ),
          _EarnBannerImage(imagePath: banner.img),
          if (hasTitle)
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
          if (hasTitle)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Text(
                banner.title!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _EarnBannerImage extends StatelessWidget {
  const _EarnBannerImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _fallback();
    }

    final isNetwork = imagePath.startsWith('http');
    if (isNetwork) {
      return CompatibleImage.network(
        imagePath,
        fit: BoxFit.fill,
        errorBuilder: (context, error, stack) => _fallback(),
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.fill,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.darkBackgroundGradient,
      ),
    );
  }
}

// ─── _InviteStatsRow ─────────────────────────────────────────────────────────

class _InviteStatsRow extends StatelessWidget {
  const _InviteStatsRow({required this.stats});
  final InviteStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatMetric(
        label: '已领取佣金',
        value: stats.totalCommission.toStringAsFixed(2),
      ),
      _StatMetric(
        label: '一级直属好友',
        value: stats.directFriends.toString(),
      ),
      _StatMetric(
        label: '总注册人数',
        value: stats.totalFriends.toString(),
      ),
      _StatMetric(
        label: '7日活跃好友',
        value: stats.activeFriends.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppConfig.earnCardBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: compact ? _buildCompactGrid(items) : _buildWideRow(items),
        );
      },
    );
  }

  Widget _buildWideRow(List<_StatMetric> items) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _StatItem(metric: items[i]),
          if (i != items.length - 1) _divider(height: 36),
        ],
      ],
    );
  }

  Widget _buildCompactGrid(List<_StatMetric> items) {
    return Column(
      children: [
        Row(
          children: [
            _StatItem(metric: items[0], compact: true),
            _divider(height: 44),
            _StatItem(metric: items[1], compact: true),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Container(height: 1, color: Colors.white12),
        ),
        Row(
          children: [
            _StatItem(metric: items[2], compact: true),
            _divider(height: 44),
            _StatItem(metric: items[3], compact: true),
          ],
        ),
      ],
    );
  }

  Widget _divider({required double height}) => Container(
        width: 1,
        height: height,
        color: Colors.white12,
      );
}

class _StatMetric {
  const _StatMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.metric, this.compact = false});

  final _StatMetric metric;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 6 : 4),
        child: Column(
          children: [
            Text(
              metric.value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: compact ? 11 : 12,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _PromoLinkCard ──────────────────────────────────────────────────────────

class _PromoLinkCard extends StatelessWidget {
  const _PromoLinkCard({
    required this.link,
    required this.currentLang,
    required this.langOptions,
    required this.onSelectLang,
    this.loading = false,
  });
  final String link;
  final bool loading;
  final String currentLang;
  final List<String> langOptions;
  final ValueChanged<String> onSelectLang;

  static void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static void _showQr(BuildContext context, String link) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF252535),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('扫码分享',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              QrImageView(data: link, size: 200, backgroundColor: Colors.white),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  '关闭',
                  style: TextStyle(color: AppConfig.earnPrimaryPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyLink() {
    if (loading || link.isEmpty) return;
    Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      '已复制',
      '推广链接已复制到剪贴板',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  List<_SocialChannel> _buildChannels(BuildContext context) {
    final encoded = Uri.encodeComponent(link);
    return [
      _SocialChannel(
        Icons.chat,
        'WhatsApp',
        (_) => _openUrl('https://wa.me/?text=$encoded'),
        iconWidget: const _WhatsAppIcon(),
      ),
      _SocialChannel(
          Icons.facebook,
          'Facebook',
          (_) =>
              _openUrl('https://www.facebook.com/sharer/sharer.php?u=$encoded'),
          iconColor: const Color(0xFF1877F2)),
      _SocialChannel(Icons.send, 'Telegram',
          (_) => _openUrl('https://t.me/share/url?url=$encoded'),
          iconColor: const Color(0xFF2AABEE)),
      _SocialChannel(Icons.link, '复制链接', (_) => _copyLink(),
          backgroundColor: AppConfig.earnPrimaryPurple,
          iconColor: Colors.white),
      _SocialChannel(Icons.qr_code, '二维码', (_) => _showQr(context, link)),
      _SocialChannel(Icons.more_horiz, '更多', (_) {
        _copyLink();
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final channels = _buildChannels(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.earnCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的推广链接',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: loading || link.isEmpty ? null : _copyLink,
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 14,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                color: AppConfig.earnPrimaryPurple,
                              ),
                            )
                          : Text(
                              link.isEmpty ? '暂无邀请链接' : link,
                              style: TextStyle(
                                color: link.isEmpty
                                    ? Colors.white38
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: '',
                padding: EdgeInsets.zero,
                color: const Color(0xFF1E1E2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: onSelectLang,
                itemBuilder: (_) {
                  return langOptions.map((code) {
                    final isActive = code == currentLang;
                    return PopupMenuItem<String>(
                      value: code,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _inviteLangLabel(code),
                            style: const TextStyle(color: Colors.white),
                          ),
                          if (isActive) const SizedBox(width: 8),
                          if (isActive)
                            const Icon(Icons.check,
                                size: 16, color: Color(0xFF22C55E)),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: _ActionBtn(
                  label: _shareLanguageLabel(currentLang),
                  icon: Icons.language,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: channels
                .map((c) => _SocialChannelItem(channel: c, link: link))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SocialChannel {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final Color? backgroundColor;
  final Widget? iconWidget;
  final void Function(String link) onTap;
  const _SocialChannel(
    this.icon,
    this.label,
    this.onTap, {
    this.iconColor,
    this.backgroundColor,
    this.iconWidget,
  });
}

class _SocialChannelItem extends StatelessWidget {
  const _SocialChannelItem({required this.channel, required this.link});
  final _SocialChannel channel;
  final String link;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => channel.onTap(link),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: channel.backgroundColor ??
                  Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: channel.iconWidget ??
                  Icon(
                    channel.icon,
                    color: channel.iconColor ?? Colors.white70,
                    size: 20,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            channel.label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppIcon extends StatelessWidget {
  const _WhatsAppIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: const [
        Icon(
          Icons.chat_bubble_rounded,
          color: Color(0xFF25D366),
          size: 21,
        ),
        Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.call_rounded,
            color: Colors.white,
            size: 10,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppConfig.earnPrimaryPurple,
            AppConfig.earnSecondaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

String _shareLanguageLabel(String currentLang) {
  final current = _inviteLangLabel(currentLang);
  switch ((Get.locale?.languageCode ?? 'zh').toLowerCase()) {
    case 'id':
      return 'Bahasa bagikan: $current';
    case 'en':
      return 'Current share language: $current';
    default:
      return '当前分享语言: $current';
  }
}

String _inviteLangLabel(String code) {
  switch (code.toLowerCase()) {
    case 'id':
      return 'Indonesia';
    case 'en':
      return 'English';
    case 'zh-cn':
    case 'zh':
      return '中文';
    default:
      return code.toUpperCase();
  }
}

// ─── _PendingCommissionCard ──────────────────────────────────────────────────

class _PendingCommissionCard extends StatelessWidget {
  const _PendingCommissionCard({required this.amount, required this.onClaim});
  final double amount;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.earnCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '待领取佣金',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  amount.toStringAsFixed(2),
                  style: const TextStyle(
                    color: AppConfig.earnAccentOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClaim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppConfig.earnPrimaryPurple,
                    AppConfig.earnSecondaryPurple,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '立即领取',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _WeeklyCommissionSection ────────────────────────────────────────────────

class _WeeklyCommissionSection extends StatelessWidget {
  const _WeeklyCommissionSection({
    required this.selectedWeek,
    required this.onWeekChanged,
    required this.data,
  });
  final int selectedWeek;
  final ValueChanged<int> onWeekChanged;
  final WeeklyData data;

  @override
  Widget build(BuildContext context) {
    final isCurrentWeek = selectedWeek == 0;
    final showRightPanel = isCurrentWeek || data.totalCommission > 0;
    final rightLabel = isCurrentWeek ? '领取时间' : '领取状态';
    final rightValue = isCurrentWeek
        ? data.currentWeekClaimWindow
        : (data.lastWeekClaimed ? '已领取' : '未领取');
    final rightValueColor = isCurrentWeek
        ? Colors.white
        : (data.lastWeekClaimed ? Colors.white : AppConfig.earnAccentOrange);

    return Container(
      decoration: BoxDecoration(
        color: AppConfig.earnCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _WeekTab(
                  label: '本周',
                  active: selectedWeek == 0,
                  onTap: () => onWeekChanged(0)),
              _WeekTab(
                  label: '上周',
                  active: selectedWeek == 1,
                  onTap: () => onWeekChanged(1)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('累计佣金',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        data.totalCommission.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showRightPanel) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rightLabel,
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          rightValue,
                          style: TextStyle(
                            color: rightValueColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekTab extends StatelessWidget {
  const _WeekTab(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppConfig.earnAccentOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppConfig.earnAccentOrange : Colors.white54,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── _CommissionTierCard ─────────────────────────────────────────────────────

class _CommissionTierCard extends StatelessWidget {
  const _CommissionTierCard({
    required this.levels,
    required this.loading,
    required this.onTapRuleDetails,
  });
  final List<InviteRebateLevel> levels;
  final bool loading;
  final VoidCallback onTapRuleDetails;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty && !loading) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConfig.earnCardBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '佣金等级',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: onTapRuleDetails,
                child: const Text(
                  '规则详情 >',
                  style: TextStyle(
                    color: AppConfig.earnPrimaryPurple,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (loading && levels.isEmpty)
            const SizedBox(
              height: 74,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: levels.map((level) {
                    final isActive = level.eligible;
                    return Container(
                      width: itemWidth,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppConfig.earnAccentOrange.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? AppConfig.earnAccentOrange
                                  .withValues(alpha: 0.9)
                              : Colors.white.withValues(alpha: 0.04),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatLevelRate(level.levelRate),
                            style: TextStyle(
                              color: isActive
                                  ? AppConfig.earnAccentOrange
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${level.level}级',
                            style: TextStyle(
                              color: isActive ? Colors.white70 : Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

String _formatLevelRate(double value) {
  final percent = value * 100;
  if ((percent - percent.roundToDouble()).abs() < 0.0001) {
    return '${percent.toStringAsFixed(0)}%';
  }
  if (((percent * 10) - (percent * 10).roundToDouble()).abs() < 0.0001) {
    return '${percent.toStringAsFixed(1)}%';
  }
  return '${percent.toStringAsFixed(2)}%';
}
