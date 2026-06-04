import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/user_service.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/modules/home/controllers/home_controller.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/data/models/transactions.dart' as tx_model;
import 'package:igames/app/data/models/scorerecord.dart' as gr_model;
import '../views/wallet_view.dart';
import '../views/wallet_history_view.dart';
import '../views/game_history_view.dart';

class UserProfileController extends GetxController {
  final HomeController home = Get.find<HomeController>();
  final AuthController auth = Get.find<AuthController>();

  // 用户信息
  final RxString username = 'empty_shark297'.obs;
  final RxString nickname = 'EmptyShark'.obs;

  // 当前选中的标签页 一级标题
  final RxInt selectedDrawerTab = 1.obs;
  final RxString selectedPage = 'wallet'.obs;

  // 中心区域三页切换
  final RxInt currentPage = 0.obs;
  final List<Widget> pages = const [
    WalletView(),
    WalletHistoryView(),
    GameHistoryView(),
  ];

  // 侧边抽屉菜单
  final List<Map<String, dynamic>> drawerTabs = const [
    {'id': 1, 'title': 'wallet', 'icon': Icons.wallet_outlined},
    {'id': 2, 'title': 'walletHistory', 'icon': Icons.history_outlined},
    {'id': 3, 'title': 'gameHistory', 'icon': Icons.gamepad_outlined},
  ];

  void switchDrawerTab(int id) => selectedDrawerTab.value = id;
  void switchPage(String viewName) => selectedPage.value = viewName;
  void switchPageByIndex(int index) => currentPage.value = index;

  // ---------------- 钱包历史：分页/筛选/刷新 ----------------
  final RxList<tx_model.TransactionsRecord> walletHistory =
      <tx_model.TransactionsRecord>[].obs;
  final RxBool walletIsLoading = false.obs;
  final RxBool walletIsRefreshing = false.obs;
  final RxBool walletHasMore = true.obs;
  final RxString walletFilter = 'all'.obs; // all/deposit/withdraw
  int _walletPage = 1;
  final int _walletSize = 20;

  Future<void> refreshWalletHistory() async {
    walletIsRefreshing.value = true;
    _walletPage = 1;
    walletHasMore.value = true;
    await _fetchWalletHistoryInternal(reset: true);
    walletIsRefreshing.value = false;
  }

  Future<void> loadMoreWalletHistory() async {
    if (walletIsLoading.value || !walletHasMore.value) return;
    _walletPage += 1;
    await _fetchWalletHistoryInternal();
  }

  Future<void> setWalletFilter(String actionType) async {
    if (walletFilter.value == actionType) return;
    walletFilter.value = actionType; // all/deposit/withdraw
    await refreshWalletHistory();
  }

  Future<void> _fetchWalletHistoryInternal({bool reset = false}) async {
    walletIsLoading.value = true;
    try {
      final params = <String, dynamic>{
        'page': _walletPage.toString(),
        'size': _walletSize.toString(),
      };
      if (walletFilter.value != 'all') {
        params['action_type'] = walletFilter.value;
      }
      final resp =
          await ApiClient().get('/user/transactions', queryParameters: params);
      final data = tx_model.transactions.fromJson(resp.data);
      final list = data.data?.transactionsRecord ?? [];

      if (reset) {
        walletHistory.assignAll(list);
      } else {
        walletHistory.addAll(list);
      }
      final total = data.data?.total ?? 0;
      final currentCount = walletHistory.length;
      walletHasMore.value = currentCount < total;
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      walletIsLoading.value = false;
    }
  }

  // ---------------- 游戏历史：分页/筛选/刷新 ----------------
  final RxList<gr_model.GameScoreRecord> gameHistory =
      <gr_model.GameScoreRecord>[].obs;
  final RxBool gameIsLoading = false.obs;
  final RxBool gameHasMore = true.obs;
  final RxString gameFilter =
      'all'.obs; // all/bet/endround/rollout/rollin/refund
  int _gamePage = 1;
  final int _gameSize = 20;

  Future<void> refreshGameHistory() async {
    _gamePage = 1;
    gameHasMore.value = true;
    await _fetchGameHistoryInternal(reset: true);
  }

  Future<void> loadMoreGameHistory() async {
    if (gameIsLoading.value || !gameHasMore.value) return;
    _gamePage += 1;
    await _fetchGameHistoryInternal();
  }

  Future<void> setGameFilter(String type) async {
    if (gameFilter.value == type) return;
    gameFilter.value = type; // all/bet/endround/rollout/rollin/refund
    await refreshGameHistory();
  }

  Future<void> _fetchGameHistoryInternal({bool reset = false}) async {
    gameIsLoading.value = true;
    try {
      final params = <String, dynamic>{
        'page': _gamePage.toString(),
        'size': _gameSize.toString(),
      };
      if (gameFilter.value != 'all') {
        params['event_type'] = gameFilter.value;
      }
      final resp = await ApiClient()
          .get('/user/game/score/record', queryParameters: params);
      final data = gr_model.scorerecord.fromJson(resp.data);
      final list = data.data?.gameScoreRecord ?? [];
      if (reset) {
        gameHistory.assignAll(list);
      } else {
        gameHistory.addAll(list);
      }
      final total = data.data?.total ?? 0;
      final currentCount = gameHistory.length;
      gameHasMore.value = currentCount < total;
    } catch (e) {
      Get.snackbar('tip'.tr, e.toString());
    } finally {
      gameIsLoading.value = false;
    }
  }

  // 金额格式化（千分位，保留原小数部分）
  String formatAmount(num value) {
    final parts = value.toString().split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    final intPartWithComma = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return intPartWithComma + decPart;
  }

  // 状态展示映射（后续可调整）

//存款状态映射
// created = "已创建"
  // 	if in.Status == "SUCCESS" {
  // 	StstusDetail = "支付成功"
  // }
  // if in.Status == "INIT_ORDER" {
  // 	StstusDetail = "订单初始化"
  // }
  // if in.Status == "NO_PAY" {
  // 	StstusDetail = "未支付"
  // }
  // if in.Status == "PAY_CANCEL" {
  // 	StstusDetail = "撤销"
  // }
  // if in.Status == "PAY_ERROR" {
  // 	StstusDetail = "支付失败"
  // }
  //提现状态映射
  // 	if in.Status == 0 {
  // 	StatusDetail = "待处理"
  // }
  // if in.Status == 1 {
  // 	StatusDetail = "处理中"
  // }
  // if in.Status == 2 {
  // 	StatusDetail = "代付成功"
  // }
  // if in.Status == 4 {
  // 	StatusDetail = "代付失败"
  // }
  // if in.Status == 5 {
  // 	StatusDetail = "银行代付中"
  // }

  String mapOrderStatus(String? status) {
    switch (status) {
      case 'created':
        return 'transactionStatus_created'.tr; //已创建
      case 'SUCCESS':
        return 'transactionStatus_success'.tr; //成功
      case 'INIT_ORDER':
        return 'transactionStatus_init_order'.tr; //订单初始化
      case 'NO_PAY':
        return 'transactionStatus_no_pay'.tr; //未支付
      case 'PAY_CANCEL':
        return 'transactionStatus_pay_cancel'.tr; //撤销
      case 'PAY_ERROR':
        return 'transactionStatus_pay_error'.tr; //支付失败
      case '0':
        return 'transactionStatus_pending'.tr; //待处理
      case '1':
        return 'transactionStatus_processing'.tr; //处理中
      case '2':
        return 'transactionStatus_success'.tr; //代付成功
      case '4':
        return 'transactionStatus_failed'.tr; //代付失败
      case '5':
        return 'transactionStatus_bank_processing'.tr; //银行代付中
      default:
        return (status ?? '-');
    }
  }

  @override
  void onInit() {
    super.onInit();
    getUserInfo();
    // 预加载钱包历史
    refreshWalletHistory();
    // 预加载游戏历史
    refreshGameHistory();
  }

  // 获取用户信息
  Future<void> getUserInfo() async {
    final userInfo = await UserServices.getUserInfo();
    final account = userInfo['account'];
    nickname.value = userInfo['nickname'];
    username.value = account;
  }
}
