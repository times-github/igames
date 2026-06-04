import 'dart:async';

import 'package:get/get.dart';

/// 基础Controller类，提供统一的资源管理
///
/// 所有Controller应继承此类以确保资源正确释放
///
/// 使用方法：
/// ```dart
/// class MyController extends BaseController {
///   @override
///   void onInit() {
///     super.onInit();
///
///     // 注册Timer
///     final timer = Timer.periodic(Duration(seconds: 1), (_) {
///       // ...
///     });
///     addTimer(timer);
///
///     // 注册Stream订阅
///     final sub = someStream.listen((data) {
///       // ...
///     });
///     addSubscription(sub);
///
///     // 注册Worker
///     final worker = ever(someObservable, (_) {
///       // ...
///     });
///     addWorker(worker);
///   }
/// }
/// ```
abstract class BaseController extends GetxController {
  // 资源追踪列表
  final List<Timer> _timers = [];
  final List<StreamSubscription> _subscriptions = [];
  final List<Worker> _workers = [];

  /// 注册Timer，确保在Controller销毁时自动取消
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  /// 注册Stream订阅，确保在Controller销毁时自动取消
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// 注册Worker，确保在Controller销毁时自动销毁
  void addWorker(Worker worker) {
    _workers.add(worker);
  }

  /// 手动移除Timer（如果需要提前取消）
  void removeTimer(Timer timer) {
    timer.cancel();
    _timers.remove(timer);
  }

  /// 手动移除Stream订阅（如果需要提前取消）
  void removeSubscription(StreamSubscription subscription) {
    subscription.cancel();
    _subscriptions.remove(subscription);
  }

  /// 手动移除Worker（如果需要提前销毁）
  void removeWorker(Worker worker) {
    worker.dispose();
    _workers.remove(worker);
  }

  @override
  void onClose() {
    // 取消所有Timer
    for (var timer in _timers) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    _timers.clear();

    // 取消所有Stream订阅
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 销毁所有Worker
    for (var worker in _workers) {
      worker.dispose();
    }
    _workers.clear();

    super.onClose();
  }

  /// 获取当前注册的资源统计（用于调试）
  Map<String, int> getResourceStats() {
    return {
      'timers': _timers.length,
      'subscriptions': _subscriptions.length,
      'workers': _workers.length,
    };
  }
}
