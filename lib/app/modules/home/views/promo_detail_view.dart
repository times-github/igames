import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:igames/config/app_config_export.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_detail_controller.dart';
import 'package:igames/app/modules/home/controllers/promo_controller.dart';

class PromoDetailView extends StatefulWidget {
  const PromoDetailView({super.key, required this.activity});

  final PromoActivity activity;

  @override
  State<PromoDetailView> createState() => _PromoDetailViewState();
}

class _PromoDetailViewState extends State<PromoDetailView> {
  late final String _tag;
  late final PromoDetailController _controller;

  @override
  void initState() {
    super.initState();
    _tag = 'promo_detail_${widget.activity.id}';
    _controller = Get.put(
      PromoDetailController(activity: widget.activity),
      tag: _tag,
    );
  }

  @override
  void dispose() {
    if (Get.isRegistered<PromoDetailController>(tag: _tag)) {
      Get.delete<PromoDetailController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        final pageTitle = _controller.title.value.trim().isEmpty
            ? 'promoCenter'.tr
            : _controller.title.value.trim();
        return Container(
          decoration: const BoxDecoration(
            gradient: AppColors.darkBackgroundGradient,
          ),
          child: Column(
            children: [
              AppBar(
                backgroundColor: AppColors.backgroundDark,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
                title: Text(
                  pageTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                centerTitle: true,
              ),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      return Stack(
        children: [
          Positioned.fill(
            child: _buildContent(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildDepositButton(),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildContent() {
    if (_controller.isLoading.value && _controller.content.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_controller.errorMessage.isNotEmpty && _controller.content.isEmpty) {
      return Center(
        child: Text(
          _controller.errorMessage.value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.content.value.isNotEmpty)
            Html(
              data: _cleanHtml(_controller.content.value),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDepositButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          Get.back();
          Get.find<HomeController>().currentTab.value = 2;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(
          'depositNow'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
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
