import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/models/jackpot.dart';
import 'package:igames/app/data/models/gametype.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/modules/widgets/app_brand_logo.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/app/modules/widgets/game_cover_image.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/modules/widgets/gameMenu/controllers/game_menu_controller.dart';
import 'package:igames/config/app_config_export.dart';

class JackpotScroller extends StatefulWidget {
  const JackpotScroller({super.key});

  @override
  State<JackpotScroller> createState() => _JackpotScrollerState();
}

void showJackpotDetailSheet({
  required BuildContext context,
  required BuildContext parentContext,
  required JackpotRecord record,
  required List<JackpotRecord> records,
  int? index,
}) {
  final recommend = <JackpotRecord>[];
  for (var i = 0; i < records.length; i++) {
    if (index != null) {
      if (i == index) continue;
    } else if (_isSameJackpotRecord(records[i], record)) {
      continue;
    }
    recommend.add(records[i]);
  }

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) {
      return _JackpotDetailSheet(
        parentContext: parentContext,
        record: record,
        recommend: recommend,
      );
    },
  );
}

class _JackpotScrollerState extends State<JackpotScroller> {
  final Duration _stayDuration = const Duration(seconds: 5);
  final Duration _slideDuration = const Duration(milliseconds: 650);
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  int _activeIndex = -1;
  double _itemExtent = 0;
  Timer? _timer;
  Timer? _activeTimer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(_stayDuration, (_) {
      if (!mounted) return;
      if (!Get.isRegistered<JackpotService>()) return;

      final service = Get.find<JackpotService>();
      final records = service.jackpotList;
      if (records.length <= 1) return;

      _advance(records.length);
    });
  }

  void _advance(int length) {
    if (length <= 1) return;
    final nextIndex = (_currentIndex + 1) % length;

    setState(() {
      _currentIndex = nextIndex;
    });

    if (!_scrollController.hasClients || _itemExtent <= 0) return;

    if (nextIndex == 0) {
      _scrollController.jumpTo(0);
    } else {
      _scrollController.animateTo(
        nextIndex * _itemExtent,
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );
    }

    final targetActive = nextIndex;
    _activeTimer?.cancel();
    _activeTimer = Timer(_slideDuration + const Duration(milliseconds: 80), () {
      if (!mounted) return;
      setState(() {
        _activeIndex = targetActive;
      });
    });
  }

  void _showJackpotDetail(
    BuildContext context,
    JackpotRecord record,
    List<JackpotRecord> records,
    int index,
  ) {
    showJackpotDetailSheet(
      context: context,
      parentContext: context,
      record: record,
      records: records,
      index: index,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _activeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<JackpotService>()) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final service = Get.find<JackpotService>();
      final records = service.jackpotList;

      if (records.isEmpty) {
        return const SizedBox.shrink();
      }

      final fallbackActive =
          records.isNotEmpty ? _currentIndex % records.length : 0;
      if (_activeIndex < 0 || _activeIndex >= records.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _activeIndex = fallbackActive;
          });
        });
      }
      final activeIndex = (_activeIndex >= 0 && _activeIndex < records.length)
          ? _activeIndex
          : fallbackActive;

      return LayoutBuilder(
        builder: (context, constraints) {
          final containerHeight = DeviceUtils.responsiveValue(
            context: context,
            mobile: 66.0,
            tablet: 72.0,
            desktop: 78.0,
            largeDesktop: 82.0,
          );
          final verticalPadding = DeviceUtils.responsiveValue(
            context: context,
            mobile: 3.0,
            tablet: 4.0,
            desktop: 5.0,
            largeDesktop: 5.0,
          );
          final cardHeight = containerHeight - verticalPadding * 2;
          final labelWidth = DeviceUtils.responsiveValue(
            context: context,
            mobile: 26.0,
            tablet: 28.0,
            desktop: 30.0,
            largeDesktop: 32.0,
          );
          const gap = 10.0;

          final available = math.max(
            0.0,
            constraints.maxWidth - labelWidth - 24,
          );
          final desiredCardWidth = DeviceUtils.responsiveValue(
            context: context,
            mobile: 220.0,
            tablet: 240.0,
            desktop: 260.0,
            largeDesktop: 280.0,
          );
          final minCardWidth = DeviceUtils.responsiveValue(
            context: context,
            mobile: 190.0,
            tablet: 210.0,
            desktop: 230.0,
            largeDesktop: 250.0,
          );
          final twoCardWidth = (available - gap) / 2;
          final targetWidth = math.min(desiredCardWidth, twoCardWidth);
          final cardWidth = targetWidth >= minCardWidth
              ? targetWidth
              : math.min(desiredCardWidth, available);
          _itemExtent = cardWidth > 0 ? cardWidth + gap : 0;

          if (_scrollController.hasClients && records.length > 1) {
            final maxOffset = math.max(0.0, (records.length - 1) * _itemExtent);
            if (_scrollController.offset > maxOffset) {
              _scrollController.jumpTo(maxOffset);
            }
          }

          return Container(
            height: containerHeight,
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141723), Color(0xFF1F2432)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _LiveLabel(
                  width: labelWidth,
                  height: cardHeight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ScrollConfiguration(
                    behavior: const _NoScrollbarBehavior(),
                    child: ListView.separated(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      primary: false,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const SizedBox(width: gap),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showJackpotDetail(
                                context,
                                record,
                                records,
                                index,
                              ),
                              child: _JackpotRecordCard(
                                key: ValueKey(
                                  '${record.eventTime}_${record.account}_${record.gamecode}_$index',
                                ),
                                record: record,
                                isActive: index == activeIndex,
                                compact: cardWidth < 240,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _LiveLabel extends StatelessWidget {
  const _LiveLabel({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final lang = (Get.locale?.languageCode ?? 'en').toLowerCase();
    final displayLabel = lang.startsWith('zh') ? '实时爆奖' : 'LIVE';
    return LayoutBuilder(
      builder: (context, constraints) {
        final baseFont = DeviceUtils.responsiveValue(
          context: context,
          mobile: 10.0,
          tablet: 11.0,
          desktop: 12.0,
        );
        final availableHeight = (constraints.maxHeight - 12).clamp(0.0, 999.0);
        final charCount = math.max(1, displayLabel.runes.length);
        final fittedFont = math
            .min(baseFont, availableHeight / charCount)
            .clamp(7.0, baseFont);
        final textStyle = TextStyle(
          color: const Color(0xFF1A1C28),
          fontSize: fittedFont,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
          height: 1,
          shadows: const [
            Shadow(
              color: Color(0xFF1A1C28),
              offset: Offset(0.3, 0),
            ),
            Shadow(
              color: Color(0xFF1A1C28),
              offset: Offset(-0.3, 0),
            ),
          ],
        );
        final isCompactLabel = displayLabel.runes.length <= 4;
        final isLiveLabel = displayLabel == 'LIVE';
        final letterWidgets = <Widget>[];
        if (isCompactLabel) {
          final letters = displayLabel.split('');
          for (var i = 0; i < letters.length; i++) {
            letterWidgets.add(Text(letters[i], style: textStyle));
            if (isLiveLabel && i != letters.length - 1) {
              letterWidgets.add(const SizedBox(height: 2));
            }
          }
        }
        final content = isCompactLabel
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: letterWidgets,
              )
            : RotatedBox(
                quarterTurns: -1,
                child: Text(
                  displayLabel,
                  style: textStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );

        return Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(vertical: 6),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD36E), Color(0xFFFF7A1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA933).withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _JackpotRecordCard extends StatefulWidget {
  const _JackpotRecordCard({
    super.key,
    required this.record,
    required this.isActive,
    required this.compact,
  });

  final JackpotRecord record;
  final bool isActive;
  final bool compact;

  @override
  State<_JackpotRecordCard> createState() => _JackpotRecordCardState();
}

class _JackpotRecordCardState extends State<_JackpotRecordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _valueAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  bool _showRate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _showRate = true;
        });
      }
    });
    _configureAnimations();
    if (widget.isActive) {
      _playAnimation();
    } else {
      _controller.value = 1;
      _showRate = true;
    }
  }

  @override
  void didUpdateWidget(covariant _JackpotRecordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final amountChanged = oldWidget.record.winAmount != widget.record.winAmount;
    final multiplierChanged =
        oldWidget.record.multiplier != widget.record.multiplier;
    final betChanged = oldWidget.record.betAmount != widget.record.betAmount;
    final dataChanged = amountChanged || multiplierChanged || betChanged;

    if (dataChanged) {
      _configureAnimations();
    }

    if (widget.isActive && (!oldWidget.isActive || dataChanged)) {
      if (_showRate) {
        setState(() {
          _showRate = false;
        });
      } else {
        _showRate = false;
      }
      _playAnimation();
      return;
    }

    if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.value = 1;
      _showRate = true;
    }
  }

  void _configureAnimations() {
    final amount = (widget.record.winAmount ?? 0).toDouble();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _valueAnimation = Tween<double>(begin: 0, end: amount).animate(curve);
    _colorAnimation = ColorTween(
      begin: const Color(0xFFFFF1B5),
      end: const Color(0xFFFFC24B),
    ).animate(curve);
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );
  }

  void _playAnimation() {
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;
    final cardPadding = widget.compact ? 8.0 : 10.0;
    final titleSize = widget.compact ? 12.0 : 13.5;
    final subtitleSize = widget.compact ? 10.5 : 11.5;
    final amountSize = widget.compact ? 13.5 : 15.5;
    final iconSize = widget.compact ? 38.0 : 44.0;

    final title = _firstNonEmptyText(
      widget.record.gameName,
      widget.record.gamehall,
      widget.record.gamecode,
    );
    final account = _maskAccountText(widget.record.account);
    final subTitle = account.isNotEmpty
        ? account
        : _firstNonEmptyText(widget.record.gamecode, widget.record.gamehall);

    final rateText = _rateText();

    final verticalPadding = widget.compact ? 3.0 : 7.0;
    final subtitleSpacing = widget.compact ? 0.0 : 2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      padding: EdgeInsets.symmetric(
        horizontal: cardPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2F3B), Color(0xFF1B1F2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFFFFC862).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
          width: isActive ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFFFF7A1A).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: isActive ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x33FFD86A),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -24,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x3326D9FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GameIcon(
                iconUrl: widget.record.iconUrl,
                size: iconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _AmountBox(
                      amountSize: amountSize,
                      isActive: isActive,
                      valueAnimation: _valueAnimation,
                      colorAnimation: _colorAnimation,
                      scaleAnimation: _scaleAnimation,
                      controller: _controller,
                    ),
                    Text(
                      title.isNotEmpty ? title : '--',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: subtitleSpacing),
                    Text(
                      subTitle.isNotEmpty ? subTitle : '--',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: subtitleSize,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rateText.isNotEmpty)
            Positioned(
              top: -4,
              right: -2,
              child: _RateBadge(
                text: rateText,
                show: _showRate,
              ),
            ),
        ],
      ),
    );
  }

  String _rateText() {
    final multiplier = _resolveMultiplier(widget.record);
    if (multiplier == null) return '';
    return 'x${multiplier.toStringAsFixed(1)}';
  }

  static double? _resolveMultiplier(JackpotRecord record) {
    final raw = record.multiplier?.toDouble();
    if (raw != null && raw > 0) return raw;
    final bet = record.betAmount?.toDouble() ?? 0;
    final win = record.winAmount?.toDouble() ?? 0;
    if (bet <= 0 || win <= 0) return null;
    return win / bet;
  }
}

class _AmountBox extends StatelessWidget {
  const _AmountBox({
    required this.amountSize,
    required this.isActive,
    required this.valueAnimation,
    required this.colorAnimation,
    required this.scaleAnimation,
    required this.controller,
  });

  final double amountSize;
  final bool isActive;
  final Animation<double> valueAnimation;
  final Animation<Color?> colorAnimation;
  final Animation<double> scaleAnimation;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final amountValue = valueAnimation.value;
          final amountColor = colorAnimation.value ?? const Color(0xFFFFC24B);
          final glowAlpha = isActive ? 0.8 : 0.5;
          final glowBlur = isActive ? 18.0 : 12.0;
          return Transform.scale(
            scale: scaleAnimation.value,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatAmount(amountValue),
              style: TextStyle(
                color: amountColor,
                fontSize: amountSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                height: 1,
                shadows: [
                  Shadow(
                    color: amountColor.withValues(alpha: glowAlpha),
                    blurRadius: glowBlur,
                  ),
                  Shadow(
                    color: const Color(0xFFFF2A1A).withValues(alpha: glowAlpha),
                    blurRadius: glowBlur * 1.4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _JackpotDetailSheet extends StatelessWidget {
  const _JackpotDetailSheet({
    required this.parentContext,
    required this.record,
    required this.recommend,
  });

  final BuildContext parentContext;
  final JackpotRecord record;
  final List<JackpotRecord> recommend;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.72;
    final isNarrow = media.size.width <= 420;
    final sheetWidth = isNarrow ? media.size.width : 420.0;
    final horizontalMargin = isNarrow ? 0.0 : 16.0;
    final amountText = _formatAmount(record.winAmount);
    final betAmount = record.betAmount?.toDouble() ?? 0;
    final betText = betAmount > 0 ? _formatAmount(betAmount) : '--';
    final multiplier = _resolveMultiplierValue(record);
    final multiplierText =
        multiplier != null ? 'x${multiplier.toStringAsFixed(1)}' : '--';
    final accountText = _maskAccountText(record.account);
    final timeText = record.eventTime ?? '';
    final gameName = _firstNonEmptyText(
      record.gameName,
      record.gamehall,
      record.gamecode,
    );
    final gameProvider = _firstNonEmptyText(
      record.gamehall,
      record.gamecode,
    );

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: sheetWidth,
          constraints: BoxConstraints(maxHeight: maxHeight),
          margin:
              EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 12),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C2F45), Color(0xFF1C1E2B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      'jackpotDetailTitle'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _AvatarBlock(
                            accountText: accountText,
                            timeText: timeText,
                          ),
                          const SizedBox(height: 18),
                          _DetailAmountBlock(
                            amountText: amountText,
                            betText: betText,
                            multiplierText: multiplierText,
                          ),
                          const SizedBox(height: 16),
                          _DetailGameBlock(
                            title: 'jackpotDetailGame'.tr,
                            gameName: gameName,
                            gameProvider: gameProvider,
                            iconUrl: record.iconUrl,
                          ),
                          if (recommend.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _RecommendBlock(
                              title: 'jackpotDetailRecommend'.tr,
                              records: recommend,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FollowButton(
                    label: 'jackpotDetailFollow'.tr,
                    onTap: () => _handleFollow(context),
                  ),
                ],
              ),
              Positioned(
                top: 6,
                right: 8,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
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

  void _handleFollow(BuildContext context) {
    Navigator.of(context).pop();

    final gamehall = record.gamehall;
    final gamecode = record.gamecode;
    if (gamehall == null ||
        gamehall.isEmpty ||
        gamecode == null ||
        gamecode.isEmpty) {
      Get.snackbar('错误', '游戏信息不完整', snackPosition: SnackPosition.TOP);
      return;
    }

    if (!Get.isRegistered<GameMenuController>()) {
      Get.snackbar('提示', '请返回首页再试', snackPosition: SnackPosition.TOP);
      return;
    }

    final menuController = Get.find<GameMenuController>();
    final hallKey = gamehall.toLowerCase();
    final codeKey = gamecode.toLowerCase();
    GameList? target = menuController.gameList.firstWhereOrNull((game) {
      final gameCode = (game.gamecode ?? '').toLowerCase();
      final gameHall = (game.gamehall ?? '').toLowerCase();
      if (gameCode.isEmpty) return false;
      if (gameCode != codeKey) return false;
      if (hallKey.isEmpty) return true;
      return gameHall == hallKey;
    });

    target ??= GameList(
      gamehall: gamehall,
      gamecode: gamecode,
      name: record.gameName,
      iconUrl: record.iconUrl,
    );

    Future.microtask(() {
      if (!Get.isRegistered<GameMenuController>()) return;
      menuController.startGame(parentContext, target!);
    });
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({
    required this.accountText,
    required this.timeText,
  });

  final String accountText;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF8A6CFF), Color(0xFF5B35F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4CFF).withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF272A3B),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          accountText.isEmpty ? '--' : accountText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (timeText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            timeText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailAmountBlock extends StatelessWidget {
  const _DetailAmountBlock({
    required this.amountText,
    required this.betText,
    required this.multiplierText,
  });

  final String amountText;
  final String betText;
  final String multiplierText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F2448), Color(0xFF231C36)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            'jackpotDetailAmount'.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            amountText,
            style: const TextStyle(
              color: Color(0xFFFFD36E),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DetailStatItem(
                  label: 'jackpotDetailBet'.tr,
                  value: betText == '--' ? '--' : betText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatItem(
                  label: 'jackpotDetailMultiplier'.tr,
                  value: multiplierText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailStatItem extends StatelessWidget {
  const _DetailStatItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final showPlaceholder = value.isEmpty || value == '--';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showPlaceholder ? '--' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: showPlaceholder
                  ? Colors.white.withValues(alpha: 0.45)
                  : const Color(0xFFFFD36E),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGameBlock extends StatelessWidget {
  const _DetailGameBlock({
    required this.title,
    required this.gameName,
    required this.gameProvider,
    required this.iconUrl,
  });

  final String title;
  final String gameName;
  final String gameProvider;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveGameIconUrl(iconUrl);
    final media = MediaQuery.of(context);
    final availableWidth = media.size.width - 140;
    final textWidth = math.max(140.0, math.min(availableWidth, 240.0));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailGameIcon(url: resolvedUrl),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: textWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameName.isEmpty ? '--' : gameName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      gameProvider.isEmpty ? '--' : gameProvider,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailGameIcon extends StatelessWidget {
  const _DetailGameIcon({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD36E), Color(0xFFFF7A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9F1A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: url != null && url!.isNotEmpty
            ? GameCoverImage(
                url: url!,
                fit: BoxFit.cover,
                fallback: _iconFallback(),
              )
            : _iconFallback(),
      ),
    );
  }

  Widget _iconFallback() {
    return _appLogoFallback(iconSize: 24);
  }
}

class _RecommendBlock extends StatelessWidget {
  const _RecommendBlock({
    required this.title,
    required this.records,
  });

  final String title;
  final List<JackpotRecord> records;

  @override
  Widget build(BuildContext context) {
    final items = records.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final name = _firstNonEmptyText(
                item.gameName,
                item.gamehall,
                item.gamecode,
              );
              final url = _resolveGameIconUrl(item.iconUrl);
              return Container(
                width: 86,
                margin: const EdgeInsets.only(right: 10),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: const Color(0xFF2C3240),
                        child: url != null && url.isNotEmpty
                            ? GameCoverImage(
                                url: url,
                                fit: BoxFit.cover,
                                fallback: _iconFallback(),
                              )
                            : _iconFallback(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name.isEmpty ? '--' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _iconFallback() {
    return _appLogoFallback(
      iconSize: 28,
      withBackground: false,
      iconOpacity: 0.8,
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 46,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7A4DFF), Color(0xFF4B2CDA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5A3BFF).withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _RateBadge extends StatelessWidget {
  const _RateBadge({required this.text, required this.show});

  final String text;
  final bool show;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: show ? 1 : 0,
      duration: const Duration(milliseconds: 260),
      child: AnimatedScale(
        scale: show ? 1 : 0.92,
        duration: const Duration(milliseconds: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A1A), Color(0xFFFF1C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B3B).withValues(alpha: 0.75),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameIcon extends StatelessWidget {
  const _GameIcon({
    required this.iconUrl,
    required this.size,
  });

  final String? iconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveGameIconUrl(iconUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: SizedBox(
        width: size,
        height: size,
        child: resolvedUrl != null && resolvedUrl.isNotEmpty
            ? CompatibleImage.network(
                resolvedUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return _appLogoFallback(iconSize: size * 0.55);
  }
}

Widget _appLogoFallback({
  double? iconSize,
  bool withBackground = true,
  double iconOpacity = 0.9,
}) {
  if (!Get.isRegistered<AppInfoService>()) {
    return _logoPlaceholder(
      iconSize: iconSize,
      withBackground: withBackground,
      iconOpacity: iconOpacity,
    );
  }
  final appInfo = Get.find<AppInfoService>();
  return Obx(() {
    final logo = appInfo.appLogo.value;
    if (logo.isEmpty) {
      return _logoPlaceholder(
        iconSize: iconSize,
        withBackground: withBackground,
        iconOpacity: iconOpacity,
      );
    }
    return AppBrandLogo(
      logo: logo,
      showBackground: withBackground,
      placeholder: _logoPlaceholder(
        iconSize: iconSize,
        withBackground: withBackground,
        iconOpacity: iconOpacity,
      ),
    );
  });
}

Widget _logoPlaceholder({
  double? iconSize,
  bool withBackground = true,
  double iconOpacity = 0.9,
}) {
  final icon = Icon(
    Icons.casino,
    color: Colors.white.withValues(alpha: iconOpacity),
    size: iconSize,
  );
  if (!withBackground) {
    return icon;
  }
  return Container(
    color: const Color(0xFF2C3240),
    child: icon,
  );
}

String _formatAmount(num? amount) {
  final value = (amount ?? 0).toDouble();
  final fixed = value.toStringAsFixed(2);
  final formatted = fixed.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  final symbol = AppConfig.currencySymbol();
  return '$symbol$formatted';
}

String _maskAccountText(String? account) {
  if (account == null || account.isEmpty) return '';
  if (account.length <= 4) return account;
  final start = account.substring(0, 1);
  final end = account.substring(account.length - 2);
  return '$start****$end';
}

String _firstNonEmptyText(String? first, [String? second, String? third]) {
  if (first != null && first.trim().isNotEmpty) return first.trim();
  if (second != null && second.trim().isNotEmpty) return second.trim();
  if (third != null && third.trim().isNotEmpty) return third.trim();
  return '';
}

String? _resolveGameIconUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  final trimmed = url.startsWith('/') ? url.substring(1) : url;
  return '${AppConfig.gameIconBaseUrl}$trimmed';
}

double? _resolveMultiplierValue(JackpotRecord record) {
  final raw = record.multiplier?.toDouble();
  if (raw != null && raw > 0) return raw;
  final bet = record.betAmount?.toDouble() ?? 0;
  final win = record.winAmount?.toDouble() ?? 0;
  if (bet <= 0 || win <= 0) return null;
  return win / bet;
}

bool _isSameJackpotRecord(JackpotRecord a, JackpotRecord b) {
  final account = a.account ?? '';
  final otherAccount = b.account ?? '';
  final gameCode = a.gamecode ?? '';
  final otherGameCode = b.gamecode ?? '';
  final time = a.eventTime ?? '';
  final otherTime = b.eventTime ?? '';
  if (account.isNotEmpty &&
      otherAccount.isNotEmpty &&
      account != otherAccount) {
    return false;
  }
  if (gameCode.isNotEmpty &&
      otherGameCode.isNotEmpty &&
      gameCode != otherGameCode) {
    return false;
  }
  if (time.isNotEmpty && otherTime.isNotEmpty && time != otherTime) {
    return false;
  }
  return account.isNotEmpty || gameCode.isNotEmpty || time.isNotEmpty;
}
