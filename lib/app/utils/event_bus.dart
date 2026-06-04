import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 应用事件基类
abstract class AppEvent {
  const AppEvent();
}

/// 登录成功事件
class LoginSuccessEvent extends AppEvent {
  const LoginSuccessEvent();
}

/// 登出事件
class LogoutEvent extends AppEvent {
  const LogoutEvent();
}

/// 请求打开登录弹窗事件
class RequestLoginEvent extends AppEvent {
  const RequestLoginEvent();
}

/// 余额变化事件
class BalanceChangedEvent extends AppEvent {
  final String newBalance;
  const BalanceChangedEvent(this.newBalance);
}

/// 语言切换事件
class LanguageChangedEvent extends AppEvent {
  final String languageCode;
  const LanguageChangedEvent(this.languageCode);
}

/// 用户信息更新事件
class UserInfoUpdatedEvent extends AppEvent {
  final Map<String, dynamic> userInfo;
  const UserInfoUpdatedEvent(this.userInfo);
}

/// 事件总线 - 用于模块间解耦通信
///
/// 使用示例：
/// ```dart
/// // 发送事件
/// EventBus.fire(LoginSuccessEvent());
///
/// // 监听事件
/// EventBus.on<LoginSuccessEvent>((event) {
///   print('User logged in');
/// });
/// ```
class EventBus extends GetxService {
  static EventBus get instance => Get.find<EventBus>();

  // 事件流控制器
  final _eventController = Rx<AppEvent?>(null);

  // 事件监听器映射 <事件类型, 监听器列表>
  final Map<Type, List<Function(AppEvent)>> _listeners = {};

  /// 发送事件
  static void fire(AppEvent event) {
    instance._fire(event);
  }

  void _fire(AppEvent event) {
    // 触发对应类型的所有监听器
    final listeners = _listeners[event.runtimeType];
    if (listeners != null) {
      for (var listener in listeners) {
        try {
          listener(event);
        } catch (e) {
          debugPrint('Error in event listener: $e');
        }
      }
    }

    // 更新事件流（用于 Obx 响应式监听）
    _eventController.value = event;
  }

  /// 监听特定类型的事件
  /// 返回取消监听的函数
  static VoidCallback on<T extends AppEvent>(void Function(T event) handler) {
    return instance._on<T>(handler);
  }

  VoidCallback _on<T extends AppEvent>(void Function(T event) handler) {
    final listeners = _listeners.putIfAbsent(T, () => []);

    void wrappedHandler(AppEvent event) {
      if (event is T) {
        handler(event);
      }
    }

    listeners.add(wrappedHandler);

    // 返回取消监听的函数
    return () {
      listeners.remove(wrappedHandler);
    };
  }

  /// 监听特定类型的事件（一次性）
  static VoidCallback once<T extends AppEvent>(void Function(T event) handler) {
    return instance._once<T>(handler);
  }

  VoidCallback _once<T extends AppEvent>(void Function(T event) handler) {
    late VoidCallback cancel;

    cancel = _on<T>((event) {
      handler(event);
      cancel(); // 执行一次后自动取消
    });

    return cancel;
  }

  /// 移除所有监听器
  void clear() {
    _listeners.clear();
  }

  /// 移除特定类型的所有监听器
  void clearType<T extends AppEvent>() {
    _listeners.remove(T);
  }

  @override
  void onClose() {
    clear();
    super.onClose();
  }

  /// 获取事件流（用于响应式监听）
  Stream<T> stream<T extends AppEvent>() {
    return _eventController.stream
        .where((event) => event is T)
        .map((event) => event as T);
  }
}
