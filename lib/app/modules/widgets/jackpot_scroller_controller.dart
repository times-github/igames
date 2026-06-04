import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/base/base_controller.dart';
import 'package:igames/app/data/models/jackpot.dart';
import 'package:igames/app/data/services/jackpot_service.dart';

/// Jackpot滚动控制器 - 管理所有状态和业务逻辑
class JackpotScrollerController extends BaseController {
  final bool autoPlayEnabled;

  JackpotScrollerController({required this.autoPlayEnabled});

  // 配置
  static const Duration stayDuration = Duration(seconds: 5);
  static const Duration slideDuration = Duration(milliseconds: 650);

  // ScrollController
  late final ScrollController scrollController;

  // 响应式状态
  final currentIndex = 0.obs;
  final activeIndex = (-1).obs;
  final itemExtent = 0.0.obs;

  // Web平台特有状态
  final webDisplayIndex = 0.obs;
  final webSlideDuration = Duration.zero.obs;

  // Jackpot数据（从Service获取）
  List<JackpotRecord> get records {
    if (!Get.isRegistered<JackpotService>()) return [];
    return Get.find<JackpotService>().jackpotList;
  }

  @override
  void onInit() {
    super.onInit();
    scrollController = ScrollController();

    // 如果启用自动播放，启动定时器
    if (autoPlayEnabled) {
      _startAutoPlay();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose(); // BaseController会自动清理所有Timer
  }

  /// 启动自动播放
  void _startAutoPlay() {
    final timer = Timer.periodic(stayDuration, (_) {
      if (records.length <= 1) return;
      advance();
    });
    addTimer(timer);
  }

  /// 前进到下一个
  void advance() {
    final length = records.length;
    if (length <= 1) return;

    final nextIndex = (currentIndex.value + 1) % length;

    if (kIsWeb) {
      _advanceWeb(nextIndex, length);
    } else {
      _advanceMobile(nextIndex);
    }
  }

  /// Web平台滚动
  void _advanceWeb(int nextIndex, int length) {
    final nextDisplayIndex = webDisplayIndex.value + 1;

    currentIndex.value = nextIndex;
    webSlideDuration.value = slideDuration;
    webDisplayIndex.value = nextDisplayIndex;

    // 延迟更新activeIndex
    final activeTimer = Timer(
      slideDuration + const Duration(milliseconds: 80),
      () => activeIndex.value = nextIndex,
    );
    addTimer(activeTimer);

    // 重置显示索引（无限循环效果）
    if (nextDisplayIndex >= length) {
      Future.delayed(slideDuration, () {
        webSlideDuration.value = Duration.zero;
        webDisplayIndex.value = 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          webSlideDuration.value = slideDuration;
        });
      });
    }
  }

  /// 移动平台滚动
  void _advanceMobile(int nextIndex) {
    currentIndex.value = nextIndex;

    if (!scrollController.hasClients || itemExtent.value <= 0) return;

    if (nextIndex == 0) {
      scrollController.jumpTo(0);
    } else {
      scrollController.animateTo(
        nextIndex * itemExtent.value,
        duration: slideDuration,
        curve: Curves.easeOutCubic,
      );
    }

    // 延迟更新activeIndex
    final targetActive = nextIndex;
    final activeTimer = Timer(
      slideDuration + const Duration(milliseconds: 80),
      () => activeIndex.value = targetActive,
    );
    addTimer(activeTimer);
  }

  /// 更新itemExtent
  void updateItemExtent(double extent) {
    itemExtent.value = extent;
  }

  /// 重置索引（当数据变化时）
  void resetIndices() {
    final length = records.length;
    if (currentIndex.value >= length) {
      currentIndex.value = 0;
    }
    if (activeIndex.value < 0 || activeIndex.value >= length) {
      activeIndex.value = length > 0 ? 0 : -1;
    }
    if (webDisplayIndex.value > length) {
      webDisplayIndex.value = 0;
      webSlideDuration.value = Duration.zero;
    }
  }
}
