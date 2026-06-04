import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_controller.dart';
import 'package:igames/app/modules/widgets/app_back_button.dart';
import 'package:igames/app/modules/widgets/compatible_image.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:url_launcher/url_launcher.dart';

class PromoDetailView extends StatefulWidget {
  const PromoDetailView({super.key, required this.activity});

  final PromoActivity activity;

  @override
  State<PromoDetailView> createState() => _PromoDetailViewState();
}

class _PromoDetailViewState extends State<PromoDetailView> {
  late final _PromoPrimaryAction? _primaryAction;

  @override
  void initState() {
    super.initState();
    _primaryAction = _resolvePrimaryAction(widget.activity);
  }

  @override
  Widget build(BuildContext context) {
    final pageTitle = widget.activity.title.trim().isEmpty
        ? 'promoCenter'.tr
        : widget.activity.title.trim();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: AppBackButton(
              onPressed: () => Get.back(),
            ),
            title: Text(
              pageTitle,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            centerTitle: true,
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildContent(),
                ),
                if (_primaryAction case final action?)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildPrimaryButton(action),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final activity = widget.activity;
    final resolvedPicture = _resolvePromoImageUrl(activity.picture);
    final bottomSpacing = _primaryAction == null ? 16.0 : 96.0;
    final endAtText = _formatEndAt(activity.endAt);
    final hasEnded = _hasEnded(activity.endAt);

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedPicture != null)
            AspectRatio(
              aspectRatio: 16 / 6.2,
              child: _PromoDetailImage(url: resolvedPicture),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title.trim().isEmpty
                      ? 'promoCenter'.tr
                      : activity.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PromoStatusChip(
                      label: hasEnded
                          ? 'activityEnded'.tr
                          : 'activityInProgress'.tr,
                      color: hasEnded
                          ? const Color(0xFFE35D5D)
                          : const Color(0xFF3ED598),
                    ),
                    if (endAtText.isNotEmpty)
                      Text(
                        endAtText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activity.content.trim().isNotEmpty)
                  Html(
                    data: _cleanHtml(activity.content),
                    style: {
                      'body': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: FontSize(14),
                        lineHeight: const LineHeight(1.6),
                      ),
                      'p': Style(
                        margin: Margins.only(bottom: 8),
                        padding: HtmlPaddings.zero,
                      ),
                      'br': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        lineHeight: const LineHeight(0),
                        fontSize: FontSize(0),
                      ),
                      'img': Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        display: Display.block,
                      ),
                    },
                  )
                else
                  Text(
                    'activityEmpty'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(_PromoPrimaryAction action) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _handlePrimaryAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          action.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction() async {
    final action = _primaryAction;
    if (action == null) return;

    switch (action.kind) {
      case _PromoActionKind.recharge:
        Get.back();
        Get.find<HomeController>().openRecharge(
          initialMethod: action.initialMethod,
        );
        return;
      case _PromoActionKind.route:
        try {
          await Get.toNamed(
            action.target,
            parameters: action.parameters,
          );
        } catch (e) {
          Get.snackbar('tip'.tr, '${'openPaymentPageFailed'.tr}: $e');
        }
        return;
      case _PromoActionKind.url:
        await _openUrl(
          action.target,
          openMode: action.openMode,
        );
        return;
    }
  }

  _PromoPrimaryAction? _resolvePrimaryAction(PromoActivity activity) {
    final params = _parseLinkParams(activity.linkParams);
    final linkType = activity.linkType.trim().toLowerCase();
    final linkValue = activity.linkValue.trim();
    final openMode = activity.openMode.trim().toLowerCase();
    final tab = params['tab']?.toString().trim().toLowerCase() ?? '';

    final opensRecharge = tab == 'usdt' ||
        linkType == 'deposit' ||
        linkType == 'recharge' ||
        linkValue == '/recharge' ||
        linkValue == 'recharge';
    if (opensRecharge) {
      return _PromoPrimaryAction.recharge(
        label: 'depositNow'.tr,
        initialMethod: tab == 'usdt' ? 'usdt' : '',
      );
    }

    if (linkValue.isEmpty) {
      return null;
    }

    if (linkType == 'url' || linkValue.startsWith('http')) {
      return _PromoPrimaryAction.url(
        label: 'viewDetails'.tr,
        target: linkValue,
        openMode: openMode,
      );
    }

    if (linkType == 'route' || linkValue.startsWith('/')) {
      return _PromoPrimaryAction.route(
        label: 'viewDetails'.tr,
        target: linkValue.startsWith('/') ? linkValue : '/$linkValue',
        parameters: params.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        ),
      );
    }

    return null;
  }

  Map<String, dynamic> _parseLinkParams(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return const <String, dynamic>{};
  }

  Future<void> _openUrl(
    String target, {
    required String openMode,
  }) async {
    try {
      final uri = Uri.parse(target);
      if (!await canLaunchUrl(uri)) {
        Get.snackbar('tip'.tr, 'cannotOpenPaymentPage'.tr);
        return;
      }

      final launched = openMode == 'in_app'
          ? await launchUrl(uri)
          : await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
      if (!launched) {
        Get.snackbar('tip'.tr, 'cannotOpenPaymentPage'.tr);
      }
    } catch (e) {
      Get.snackbar('tip'.tr, '${'openPaymentPageFailed'.tr}: $e');
    }
  }
}

class _PromoDetailImage extends StatelessWidget {
  const _PromoDetailImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CompatibleImage.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.white.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: const Icon(Icons.campaign, color: Colors.white70, size: 28),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Container(
          color: Colors.white.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}

class _PromoStatusChip extends StatelessWidget {
  const _PromoStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _PromoActionKind {
  recharge,
  route,
  url,
}

class _PromoPrimaryAction {
  const _PromoPrimaryAction._({
    required this.kind,
    required this.label,
    required this.target,
    required this.parameters,
    required this.openMode,
    required this.initialMethod,
  });

  const _PromoPrimaryAction.recharge({
    required String label,
    required String initialMethod,
  }) : this._(
          kind: _PromoActionKind.recharge,
          label: label,
          target: '',
          parameters: const <String, String>{},
          openMode: '',
          initialMethod: initialMethod,
        );

  const _PromoPrimaryAction.route({
    required String label,
    required String target,
    required Map<String, String> parameters,
  }) : this._(
          kind: _PromoActionKind.route,
          label: label,
          target: target,
          parameters: parameters,
          openMode: '',
          initialMethod: '',
        );

  const _PromoPrimaryAction.url({
    required String label,
    required String target,
    required String openMode,
  }) : this._(
          kind: _PromoActionKind.url,
          label: label,
          target: target,
          parameters: const <String, String>{},
          openMode: openMode,
          initialMethod: '',
        );

  final _PromoActionKind kind;
  final String label;
  final String target;
  final Map<String, String> parameters;
  final String openMode;
  final String initialMethod;
}

/// 清理 HTML 末尾的空标签（<p><br></p> 等），避免底部多余空白
String _cleanHtml(String html) {
  return html
      .replaceAll(
          RegExp(r'(<br\s*/?>(\s*<br\s*/?>)*\s*</p>)', caseSensitive: false),
          '</p>')
      .replaceAll(
          RegExp(r'(<p[^>]*>\s*(<br\s*/?>)?\s*</p>\s*)+$',
              caseSensitive: false),
          '')
      .trimRight();
}

String? _resolvePromoImageUrl(String raw) {
  if (raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
  return '${AppConfig.apiBaseUrl}/$trimmed';
}

bool _hasEnded(int endAt) {
  if (endAt <= 0) {
    return false;
  }
  return DateTime.now().millisecondsSinceEpoch > endAt;
}

String _formatEndAt(int endAt) {
  if (endAt <= 0) {
    return '';
  }
  final endTime = DateTime.fromMillisecondsSinceEpoch(endAt);
  final year = endTime.year.toString().padLeft(4, '0');
  final month = endTime.month.toString().padLeft(2, '0');
  final day = endTime.day.toString().padLeft(2, '0');
  final hour = endTime.hour.toString().padLeft(2, '0');
  final minute = endTime.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
