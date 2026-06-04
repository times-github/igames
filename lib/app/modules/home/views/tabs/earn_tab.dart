import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/utils/responsive.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
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
  final int lastWeekClaimStatus;

  const WeeklyData({
    required this.totalCommission,
    required this.currentWeekClaimWindow,
    required this.lastWeekClaimStatus,
  });

  static const empty = WeeklyData(
    totalCommission: 0,
    currentWeekClaimWindow: '下周一到周日',
    lastWeekClaimStatus: -1,
  );
}

const _kEarnBannerAspectRatio = 2.0;
const _kBalanceHighlightColor = Color(0xFFFFF133);

BoxDecoration _earnThemeCardDecoration({double radius = 14}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppConfig.buttonColor.withValues(alpha: 0.11),
        const Color(0xFF145B5E).withValues(alpha: 0.54),
        const Color(0xFF0E4145).withValues(alpha: 0.72),
        const Color(0xFF0A3034).withValues(alpha: 0.88),
        const Color(0xFF071F23).withValues(alpha: 0.97),
      ],
      stops: const [0.0, 0.22, 0.48, 0.74, 1.0],
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(
      color: AppConfig.btnSelectedBorderColor.withValues(alpha: 0.24),
      width: 1,
    ),
  );
}

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
  String _inviteLink = '';
  String _inviteLang = 'id';
  String _inviteCode = '';
  InviteStats _stats = InviteStats.empty;
  InviteRebatePreview _rebatePreview = InviteRebatePreview.empty;
  List<AppBanner> _earnBanners = const [];
  bool _loadingBanners = true;
  bool _loadingLink = true;
  bool _loadingRebatePreview = true;
  bool _loadingCommissionData = true;
  bool _claimingCommission = false;
  Worker? _authWorker;
  Worker? _tabWorker;
  bool _statsLoadScheduled = false;
  bool _rebatePreviewLoadScheduled = false;
  double _claimableCommission = 0;
  WeeklyData _currentWeekData = WeeklyData.empty;
  WeeklyData _lastWeekData = WeeklyData.empty;
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
    _authWorker = ever<bool>(widget.auth.isLoggedIn, _handleLoginStateChanged);
    if (Get.isRegistered<HomeController>()) {
      _tabWorker =
          ever<int>(Get.find<HomeController>().currentTab, _handleTabChanged);
    }
    _loadInviteCode();
    _loadInviteStats();
    _loadInviteRebatePreview();
    _loadEarnBanners();
    _loadWeeklySummary();
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _tabWorker?.dispose();
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
        _loadingCommissionData = false;
        _claimableCommission = 0;
        _currentWeekData = WeeklyData.empty;
        _lastWeekData = WeeklyData.empty;
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
    _loadWeeklySummary(forceRefresh: true);
  }

  void _handleTabChanged(int tab) {
    if (tab != 3 || !widget.auth.isLoggedIn.value) return;
    _loadInviteStats(forceRefresh: true);
    _loadWeeklySummary(forceRefresh: true);
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

  Future<void> _loadInviteStats({bool forceRefresh = false}) async {
    if (!widget.auth.isLoggedIn.value) {
      if (!mounted) return;
      setState(() => _stats = InviteStats.empty);
      return;
    }

    final cachedStats = _cachedStats;
    if (!forceRefresh && _hasLoadedStats && cachedStats != null) {
      if (!mounted) return;
      setState(() => _stats = cachedStats);
      return;
    }

    final pendingRequest = forceRefresh ? null : _statsRequest;
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

  Future<void> _loadWeeklySummary({bool forceRefresh = false}) async {
    if (!widget.auth.isLoggedIn.value) {
      if (!mounted) return;
      setState(() {
        _loadingCommissionData = false;
        _claimableCommission = 0;
        _currentWeekData = WeeklyData.empty;
        _lastWeekData = WeeklyData.empty;
      });
      return;
    }

    if (mounted && !_loadingCommissionData) {
      setState(() => _loadingCommissionData = true);
    }

    try {
      final response =
          await ApiClient().get('/user/invite/rebate/weekly-summary');
      final raw = response.data;
      if (response.statusCode == 200 &&
          raw is Map &&
          raw['code']?.toString() == '1' &&
          raw['data'] is Map) {
        final data = Map<String, dynamic>.from(raw['data'] as Map);
        final currentWeekTotal = _readDoubleFromMap(
          data,
          const ['current_week_total'],
        );
        final lastWeekTotal = _readDoubleFromMap(
          data,
          const ['last_week_total'],
        );
        final lastWeekClaimStatus = _readIntFromMap(
          data,
          const ['last_week_claim_status'],
          defaultValue: -1,
        );
        if (!mounted) return;
        setState(() {
          _claimableCommission = _resolveClaimableCommission(
            lastWeekTotal: lastWeekTotal,
            lastWeekClaimStatus: lastWeekClaimStatus,
          );
          _currentWeekData = WeeklyData(
            totalCommission: currentWeekTotal,
            currentWeekClaimWindow: '下周一到周日',
            lastWeekClaimStatus: -1,
          );
          _lastWeekData = WeeklyData(
            totalCommission: lastWeekTotal,
            currentWeekClaimWindow: '下周一到周日',
            lastWeekClaimStatus: lastWeekClaimStatus,
          );
          _loadingCommissionData = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('invite/rebate/weekly-summary error: $e');
    }

    if (!mounted) return;
    setState(() {
      _loadingCommissionData = false;
      if (forceRefresh) {
        _claimableCommission = 0;
        _currentWeekData = WeeklyData.empty;
        _lastWeekData = WeeklyData.empty;
      }
    });
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

  Future<void> _handleClaimCommission() async {
    final ok = await widget.auth.ensureAuthenticated(context);
    if (!ok || _claimingCommission) return;

    final amount = _claimableCommission;
    if (amount <= 0) {
      Get.snackbar(
        '提示',
        '没有金额可以领取',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => _claimingCommission = true);
    try {
      final response = await ApiClient().post('/user/invite/rebate/claim-all');
      final raw = response.data;
      final success = response.statusCode == 200 &&
          raw is Map &&
          raw['code']?.toString() == '1';
      if (success) {
        final msg = raw['msg']?.toString();
        Get.snackbar(
          '提示',
          (msg != null && msg.isNotEmpty) ? msg : '领取成功',
          snackPosition: SnackPosition.TOP,
        );
        await Future.wait([
          _loadInviteStats(forceRefresh: true),
          _loadWeeklySummary(forceRefresh: true),
        ]);
      } else {
        final msg = raw is Map ? raw['msg']?.toString() : null;
        Get.snackbar(
          '提示',
          (msg != null && msg.isNotEmpty) ? msg : '领取失败',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      Get.snackbar(
        '提示',
        '领取失败，请稍后再试',
        snackPosition: SnackPosition.TOP,
      );
      debugPrint('invite/rebate/claim-all error: $e');
    } finally {
      if (mounted) {
        setState(() => _claimingCommission = false);
      }
    }
  }

  String _buildInviteLink(String code, {String? lang}) {
    String base;
    if (kIsWeb) {
      final uri = Uri.base;
      base = '${uri.scheme}://${uri.host}';
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
              ),
              const SizedBox(height: 12),
              _WeeklyCommissionSection(
                currentWeekData: _currentWeekData,
                lastWeekData: _lastWeekData,
                onClaim: _handleClaimCommission,
                claiming: _claimingCommission,
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

    return SafeArea(
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
        color: AppConfig.webDesktopOuterBackground,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
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
      body: _buildBody(),
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
        duration: const Duration(milliseconds: 750),
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
            color: Colors.transparent,
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
                    duration: const Duration(milliseconds: 350),
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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.transparent),
          _EarnBannerImage(imagePath: banner.img),
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
    return const ColoredBox(color: Colors.transparent);
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
        value: _formatCommissionAsK(stats.totalCommission),
        highlight: true,
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
          decoration: _earnThemeCardDecoration(),
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
  const _StatMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;
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
                color:
                    metric.highlight ? _kBalanceHighlightColor : Colors.white,
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
    this.loading = false,
  });
  final String link;
  final bool loading;

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
        iconAsset: 'assets/images/shareapp/whatsapp.png',
      ),
      _SocialChannel(
          Icons.facebook,
          'Facebook',
          (_) =>
              _openUrl('https://www.facebook.com/sharer/sharer.php?u=$encoded'),
          iconAsset: 'assets/images/shareapp/facebook.png'),
      _SocialChannel(
        Icons.send,
        'Telegram',
        (_) => _openUrl('https://t.me/share/url?url=$encoded'),
        iconAsset: 'assets/images/shareapp/tg.png',
      ),
      _SocialChannel(Icons.link, '复制链接', (_) => _copyLink(),
          backgroundColor: AppConfig.buttonColor.withValues(alpha: 0.18),
          iconColor: AppConfig.btnSelectedBorderColor),
      _SocialChannel(Icons.qr_code, '二维码', (_) => _showQr(context, link)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final channels = _buildChannels(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _earnThemeCardDecoration(),
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
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        image: const DecorationImage(
                          image: AssetImage(
                            AppConfig.btnDefaultBackgroundAsset,
                          ),
                          fit: BoxFit.fill,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppConfig.btnSelectedBorderColor,
                          width: 1.5,
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 14,
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                color: AppConfig.btnSelectedBorderColor,
                              ),
                            )
                          : Text(
                              link.isEmpty ? '暂无邀请链接' : link,
                              style: TextStyle(
                                color: link.isEmpty
                                    ? AppConfig.btnDefaultTextColor
                                        .withValues(alpha: 0.52)
                                    : AppConfig.btnDefaultTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
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
  final String? iconAsset;
  final void Function(String link) onTap;
  const _SocialChannel(
    this.icon,
    this.label,
    this.onTap, {
    this.iconColor,
    this.backgroundColor,
    this.iconAsset,
  });
}

class _SocialChannelItem extends StatelessWidget {
  const _SocialChannelItem({required this.channel, required this.link});
  final _SocialChannel channel;
  final String link;

  @override
  Widget build(BuildContext context) {
    final r = Responsive.fromContext(context);
    final isAssetChannel = channel.iconAsset != null;
    final buttonSize = r.size(48);
    final assetIconSize = r.size(42);
    final glyphIconSize = r.size(22);
    final labelGap = r.size(6);
    final labelSize = r.font(10.5);

    return GestureDetector(
      onTap: () => channel.onTap(link),
      child: Column(
        children: [
          SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(
              child: isAssetChannel
                  ? CompatibleImage.asset(
                      channel.iconAsset!,
                      width: assetIconSize,
                      height: assetIconSize,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: buttonSize,
                      height: buttonSize,
                      decoration: BoxDecoration(
                        color: channel.backgroundColor ??
                            AppConfig.buttonColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppConfig.btnSelectedBorderColor
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        channel.icon,
                        color: channel.iconColor ??
                            AppConfig.btnSelectedBorderColor,
                        size: glyphIconSize,
                      ),
                    ),
            ),
          ),
          SizedBox(height: labelGap),
          Text(
            channel.label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: labelSize,
            ),
          ),
        ],
      ),
    );
  }
}

double _readDoubleFromMap(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (!data.containsKey(key)) continue;
    return InviteStats._toDouble(data[key]);
  }
  return 0;
}

int _readIntFromMap(
  Map<String, dynamic> data,
  List<String> keys, {
  int defaultValue = 0,
}) {
  for (final key in keys) {
    if (!data.containsKey(key)) continue;
    final value = data[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return defaultValue;
}

double _resolveClaimableCommission({
  required double lastWeekTotal,
  required int lastWeekClaimStatus,
}) {
  switch (lastWeekClaimStatus) {
    case 0:
    case 2:
      return lastWeekTotal > 0 ? lastWeekTotal : 0;
    case -1:
    case 1:
    default:
      return 0;
  }
}

// ─── _WeeklyCommissionSection ────────────────────────────────────────────────

class _WeeklyCommissionSection extends StatelessWidget {
  const _WeeklyCommissionSection({
    required this.currentWeekData,
    required this.lastWeekData,
    required this.onClaim,
    this.claiming = false,
  });
  final WeeklyData currentWeekData;
  final WeeklyData lastWeekData;
  final VoidCallback onClaim;
  final bool claiming;

  @override
  Widget build(BuildContext context) {
    final claimButtonEnabled =
        _isClaimButtonEnabled(lastWeekData.lastWeekClaimStatus);
    final claimButtonText = _claimButtonText(lastWeekData.lastWeekClaimStatus);

    return Container(
      decoration: _earnThemeCardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _WeeklyCommissionRow(
                  title: '本周',
                  amount: currentWeekData.totalCommission,
                  rightLabel: '领取时间',
                  rightChild: Text(
                    currentWeekData.currentWeekClaimWindow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                _WeeklyCommissionRow(
                  title: '上周',
                  amount: lastWeekData.totalCommission,
                  rightLabel: '',
                  rightChild: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: claimButtonEnabled && !claiming ? onClaim : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 112,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: claimButtonEnabled
                              ? const LinearGradient(
                                  colors: [
                                    AppConfig.btnSelectedBorderColor,
                                    AppConfig.buttonColor,
                                  ],
                                )
                              : null,
                          color: claimButtonEnabled
                              ? null
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: claiming
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  claimButtonText,
                                  style: TextStyle(
                                    color: claimButtonEnabled
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
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

class _WeeklyCommissionRow extends StatelessWidget {
  const _WeeklyCommissionRow({
    required this.title,
    required this.amount,
    required this.rightLabel,
    required this.rightChild,
  });

  final String title;
  final double amount;
  final String rightLabel;
  final Widget rightChild;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '累计佣金',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCommissionAsK(amount),
                    style: const TextStyle(
                      color: _kBalanceHighlightColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rightLabel,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  rightChild,
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

bool _isClaimButtonEnabled(int status) {
  switch (status) {
    case 0:
    case 2:
      return true;
    case -1:
    case 1:
    default:
      return false;
  }
}

String _formatCommissionAsK(num amount) {
  final scaled = amount / 1000;
  return '${scaled.toStringAsFixed(2)} K';
}

String _claimButtonText(int status) {
  switch (status) {
    case 0:
      return '立即领取';
    case 2:
      return '继续领取';
    case 1:
      return '已领取';
    case -1:
    default:
      return '无佣金';
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
      decoration: _earnThemeCardDecoration(),
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
                    color: AppConfig.btnSelectedBorderColor,
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
                            ? AppConfig.buttonColor.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive
                              ? AppConfig.btnSelectedBorderColor
                                  .withValues(alpha: 0.72)
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
                                  ? AppConfig.btnSelectedBorderColor
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
