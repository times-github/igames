import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/utils/event_bus.dart';
import 'package:igames/app/utils/launch_params.dart';
import '../../../utils/api_client.dart';

class HomeController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  //余额
  final balance = '0'.obs;
  final isRefreshingBalance = false.obs;
  final hasFetchedBalance = false.obs;
  // 当前显示的页面类型
  final currentView = 'index'.obs; // 'index' 或 'gameAll'
  // 移动端底部导航索引：0 首页 1 优惠 2 充值 3 赚钱 4 我的
  final currentTab = 0.obs;
  final rechargeInitialMethod = ''.obs;

  // 页面切换方法
  void switchToGameAll() {
    currentView.value = 'gameAll';
  }

  void switchToIndex() {
    currentView.value = 'index';
  }

  // 返回上一页
  void goBack() {
    if (currentView.value == 'gameAll') {
      switchToIndex();
    }
  }

  void openRecharge({String initialMethod = ''}) {
    rechargeInitialMethod.value = initialMethod;
    currentTab.value = 2;
  }

  @override
  void onInit() {
    super.onInit();
    // 检查路由参数设置初始 tab
    final args = Get.arguments;
    if (args is Map && args['initialTab'] != null) {
      currentTab.value = args['initialTab'] as int;
    }

    // 监听登录成功事件，自动刷新余额（完全解耦）
    EventBus.on<LoginSuccessEvent>((_) {
      debugPrint('Received LoginSuccessEvent, refreshing balance');
      refreshBalance();
    });

    // 监听登出事件，清空余额
    EventBus.on<LogoutEvent>((_) {
      debugPrint('Received LogoutEvent, clearing balance');
      balance.value = '0';
      hasFetchedBalance.value = false;
    });

    _autoOpenAuthFromLink();
  }

  @override
  void onReady() {
    super.onReady();
    _autoOpenAuthFromLink();
  }

  void _autoOpenAuthFromLink() {
    if (!LaunchParams.consumeAutoOpenAuth()) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = Get.context;
      if (context == null) return;
      // 通过事件总线请求打开登录弹窗，完全解耦
      EventBus.fire(const RequestLoginEvent());
    });
  }

  //刷新余额 请求api

  Future<void> refreshBalance() async {
    if (isRefreshingBalance.value) return;
    isRefreshingBalance.value = true;
    try {
      // /transaction/balance/{account}
      final userInfo = await UserServices.getUserInfo();
      final account = userInfo['account'];
      if (account == null || account.toString().isEmpty) {
        balance.value = '0';
        return;
      }
      final response = await _apiClient.get(
        '/cq9/transaction/balance/$account',
      );
      if (response.statusCode == 200 && response.data != null) {
        // 格式化 balance，加千分位
        final rawBalance = response.data['data']?['balance'];
        if (rawBalance == null) {
          balance.value = '0';
          return;
        }
        String formattedBalance;
        if (rawBalance is num) {
          // 保留小数点后所有位数
          final parts = rawBalance.toString().split('.');
          final intPart = parts[0];
          final decPart = parts.length > 1 ? '.${parts[1]}' : '';
          final intPartWithComma = intPart.replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
          formattedBalance = intPartWithComma + decPart;
        } else {
          // 兜底：直接转字符串
          formattedBalance = rawBalance.toString();
        }
        balance.value = formattedBalance;
      }
    } finally {
      isRefreshingBalance.value = false;
      hasFetchedBalance.value = true;
    }
  }
}
