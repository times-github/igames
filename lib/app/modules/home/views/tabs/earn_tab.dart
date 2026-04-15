import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config_export.dart';

// ─── 数据模型 ────────────────────────────────────────────────────────────────

class InviteStats {
  final double totalCommission;
  final int totalFriends;
  final int activeFriends;
  const InviteStats({
    required this.totalCommission,
    required this.totalFriends,
    required this.activeFriends,
  });
}

class CommissionTier {
  final int requiredActive;
  final double rate; // e.g. 0.001 = 0.1%
  const CommissionTier(this.requiredActive, this.rate);
}

class WeeklyData {
  final double estimatedCommission;
  final int friendsNeededForNext;
  final double nextTierBonus;
  const WeeklyData({
    required this.estimatedCommission,
    required this.friendsNeededForNext,
    required this.nextTierBonus,
  });
}

// ─── Mock 数据 ───────────────────────────────────────────────────────────────

const _kMockStats = InviteStats(
  totalCommission: 0,
  totalFriends: 0,
  activeFriends: 0,
);

const _kMockTiers = [
  CommissionTier(1, 0.001),
  CommissionTier(3, 0.0015),
  CommissionTier(10, 0.002),
  CommissionTier(30, 0.003),
  CommissionTier(100, 0.0035),
];

const _kMockWeekly = WeeklyData(
  estimatedCommission: 0,
  friendsNeededForNext: 1,
  nextTierBonus: 1.82,
);

const _kMockPendingCommission = 0.0;
const _kCurrentTierIndex = 0; // 当前所在档位（0-based）

// ─── 颜色常量 ────────────────────────────────────────────────────────────────

const _kCardBg = Color(0xFF252535);
const _kOrange = Color(0xFFFF9800);
const _kPurple1 = Color(0xFF7B5CFF);
const _kPurple2 = Color(0xFF5A3DCE);
const _kBlue = Color(0xFF4EA3FF);

// ─── 导航项数据 ──────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final bool hasBadge;
  const _NavItem(this.icon, this.label, {this.hasBadge = false});
}

const _kNavItems = [
  _NavItem(Icons.people_alt_outlined, '邀请好友'),
  _NavItem(Icons.assignment_outlined, '好友任务', hasBadge: true),
  _NavItem(Icons.bar_chart_outlined, '数据报表'),
  _NavItem(Icons.account_balance_wallet_outlined, '佣金记录'),
  _NavItem(Icons.info_outline, '规则说明'),
];

// ─── EarnTab ─────────────────────────────────────────────────────────────────

class EarnTab extends StatefulWidget {
  const EarnTab({super.key, required this.auth});
  final AuthController auth;

  @override
  State<EarnTab> createState() => _EarnTabState();
}

class _EarnTabState extends State<EarnTab> {
  int _selectedWeek = 0;
  String _inviteLink = '';
  String _inviteLang = 'id';
  String _inviteCode = '';
  bool _useAppLang = true;
  bool _loadingLink = true;

  // static 缓存：跨 widget 实例，只请求一次
  static String? _cachedCode;
  static const List<String> _inviteLangs = ['id', 'en', 'zh'];

  @override
  void initState() {
    super.initState();
    _inviteLang = _resolveInviteLang();
    _useAppLang = true;
    _loadInviteCode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  void _setInviteLang(String lang) {
    if (!_inviteLangs.contains(lang)) return;
    if (!mounted) return;
    setState(() {
      _useAppLang = false;
      _inviteLang = lang;
      _inviteLink = _buildInviteLink(_inviteCode, lang: _inviteLang);
    });
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
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = 82.0;
    final bottomPadding = bottomNavHeight + bottomInset + 16;

    final content = ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _InviteNavBar(),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              _InviteBannerCarousel(),
              const SizedBox(height: 12),
              _InviteStatsRow(stats: _kMockStats),
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
                tiers: _kMockTiers,
                currentTierIndex: _kCurrentTierIndex,
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      decoration:
          const BoxDecoration(gradient: AppColors.darkBackgroundGradient),
      child: SafeArea(bottom: false, child: content),
    );
  }
}

// ─── _InviteNavBar ───────────────────────────────────────────────────────────

class _InviteNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _kNavItems.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final item = _kNavItems[i];
          return SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: Colors.white70, size: 22),
                    ),
                    if (item.hasBadge)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── _InviteBannerCarousel ───────────────────────────────────────────────────

class _InviteBannerCarousel extends StatefulWidget {
  @override
  State<_InviteBannerCarousel> createState() => _InviteBannerCarouselState();
}

class _InviteBannerCarouselState extends State<_InviteBannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  final _banners = const [
    _BannerData('邀请好友，赚取佣金', '每邀请一位活跃好友，即可获得持续佣金收益'),
    _BannerData('最高 0.35% 佣金比例', '邀请越多活跃好友，佣金比例越高'),
    _BannerData('实时结算，随时提现', '佣金每小时更新，随时可申请提现'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => _BannerPage(data: _banners[i]),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (i) {
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
}

class _BannerData {
  final String title;
  final String subtitle;
  const _BannerData(this.title, this.subtitle);
}

class _BannerPage extends StatelessWidget {
  const _BannerPage({required this.data});
  final _BannerData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPurple1, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _StatItem(
            label: '累计佣金',
            value: stats.totalCommission.toStringAsFixed(2),
          ),
          _divider(),
          _StatItem(
            label: '好友人数',
            value: stats.totalFriends.toString(),
          ),
          _divider(),
          _StatItem(
            label: '活跃人数',
            value: stats.activeFriends.toString(),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white12,
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
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
                child: const Text('关闭', style: TextStyle(color: _kPurple1)),
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
          backgroundColor: _kPurple1, iconColor: Colors.white),
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
        color: _kCardBg,
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
                                color: _kPurple1,
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
        gradient: const LinearGradient(colors: [_kPurple1, _kPurple2]),
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
  switch (code) {
    case 'id':
      return 'lang_id'.tr;
    case 'en':
      return 'lang_en'.tr;
    case 'zh':
      return 'lang_zh'.tr;
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
        color: _kCardBg,
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
                    color: _kOrange,
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
                gradient: const LinearGradient(colors: [_kPurple1, _kPurple2]),
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
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
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
                      const Text('预计佣金',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        data.estimatedCommission.toStringAsFixed(2),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('下一档奖励',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '再邀 ${data.friendsNeededForNext} 人 ',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            TextSpan(
                              text:
                                  '+${data.nextTierBonus.toStringAsFixed(2)}%',
                              style: const TextStyle(
                                color: _kOrange,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
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
              color: active ? _kOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? _kOrange : Colors.white54,
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
    required this.tiers,
    required this.currentTierIndex,
  });
  final List<CommissionTier> tiers;
  final int currentTierIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '佣金等级',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(tiers.length, (i) {
              final tier = tiers[i];
              final isActive = i == currentTierIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < tiers.length - 1 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _kOrange.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? _kOrange : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${(tier.rate * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isActive ? _kOrange : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tier.requiredActive}人',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {},
                child: const Text(
                  '规则详情 >',
                  style: TextStyle(color: _kPurple1, fontSize: 12),
                ),
              ),
              const Text(
                '数据每小时更新一次',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
