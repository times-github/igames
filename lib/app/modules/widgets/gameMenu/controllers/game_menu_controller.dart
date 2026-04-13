import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'dart:ui';
import 'package:igames/app/routes/app_pages.dart';
import '../../../../data/models/gametype.dart';
import '../../../../utils/api_client.dart';
import 'dart:convert'; // Added for jsonDecode

class SlotProviderOption {
  const SlotProviderOption({
    required this.id,
    required this.label,
    required this.assetPath,
    this.requestValue,
    this.translateLabel = false,
  });

  final String id;
  final String label;
  final String assetPath;
  final String? requestValue;
  final bool translateLabel;
}

class GameMenuController extends GetxController {
  static const String _allProviderId = 'all';
  static const List<SlotProviderOption> _slotProviderOptions = [
    SlotProviderOption(
      id: _allProviderId,
      label: 'all',
      assetPath: 'assets/images/provider/all.png',
      translateLabel: true,
    ),
    SlotProviderOption(
      id: 'pg',
      label: 'PG',
      assetPath: 'assets/images/provider/pg.webp',
      requestValue: 'pg',
    ),
    SlotProviderOption(
      id: 'jdb',
      label: 'JDB',
      assetPath: 'assets/images/provider/JDB.webp',
      requestValue: 'jdb',
    ),
    SlotProviderOption(
      id: 'jili',
      label: 'JILI',
      assetPath: 'assets/images/provider/jili.webp',
      requestValue: 'jili',
    ),
    SlotProviderOption(
      id: 'pp',
      label: 'PP',
      assetPath: 'assets/images/provider/pragmatic.webp',
      requestValue: 'pp',
    ),
    SlotProviderOption(
      id: 'bg',
      label: 'BG',
      assetPath: 'assets/images/provider/bg.png',
      requestValue: 'bg',
    ),
    SlotProviderOption(
      id: 'fc',
      label: 'FC',
      assetPath: 'assets/images/provider/fachai.webp',
      requestValue: 'fc',
    ),
    SlotProviderOption(
      id: 'hsd',
      label: 'HSD',
      assetPath: 'assets/images/provider/hsd.png',
      requestValue: 'hsd',
    ),
    SlotProviderOption(
      id: 'tada',
      label: 'TADA',
      assetPath: 'assets/images/provider/tada.webp',
      requestValue: 'tada',
    ),
    SlotProviderOption(
      id: 'wg',
      label: 'WG',
      assetPath: 'assets/images/provider/wg_games.png',
      requestValue: 'wg',
    ),
    SlotProviderOption(
      id: 'cq9',
      label: 'CQ9',
      assetPath: 'assets/images/provider/CQ9.webp',
      requestValue: 'cq9',
    ),
  ];

  // 游戏分类数据
  final gameCategories = <Map<String, dynamic>>[].obs;

  // 当前选中的分类
  final selectedCategory = 'HOME_TOP'.obs;
  final selectedSlotProvider = _allProviderId.obs;

  // 游戏列表数据
  final gameList = <GameList>[].obs;

  // 分页相关
  final currentPage = 1.obs;
  final pageSize = 40.obs;
  final hasMoreData = true.obs;
  final isLoading = false.obs;
  final loadError = false.obs;

  // 游戏状态管理
  final expandedGames = <int>{}.obs; // 记录哪些游戏卡片是展开状态
  final likedGames = <int>{}.obs; // 记录喜欢的游戏

  // 详情弹层（Overlay 实现）
  final selectedGame = Rxn<GameList>();
  OverlayEntry? _detailEntry;

  // API客户端
  final ApiClient _apiClient = Get.find<ApiClient>();
  Worker? _authWorker;

  List<SlotProviderOption> get slotProviders => _slotProviderOptions;

  bool get showSlotProviderFilter => _isSlotCategory(selectedCategory.value);

  SlotProviderOption get currentSlotProvider =>
      _slotProviderOptions.firstWhereOrNull(
        (provider) => provider.id == selectedSlotProvider.value,
      ) ??
      _slotProviderOptions.first;

  @override
  void onInit() {
    super.onInit();
    final authController = Get.find<AuthController>();
    _authWorker = ever<bool>(authController.isLoggedIn, (_) {
      refreshGames();
    });
    _loadGameCategories();
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  /// 通过 Overlay 打开一个带毛玻璃背景的居中弹层
  void openOverlay(BuildContext context, Widget child) {
    if (_detailEntry != null) return;

    _detailEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // 背景虚化 + 半透明
          Positioned.fill(
            child: GestureDetector(
              onTap: closeGameOverlay,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
          ),
          // 内容
          Center(
            child: Material(color: Colors.transparent, child: child),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_detailEntry!);
  }

  /// 打开游戏详情弹层

  /// 关闭弹层
  void closeGameOverlay() {
    _detailEntry?.remove();
    _detailEntry = null;
    selectedGame.value = null;
  }

  /// 从API加载游戏分类
  Future<void> _loadGameCategories() async {
    try {
      final response = await _apiClient.get(
        '/user/config/game_categories',
        withAuth: false,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['code'] == 1 && data['data']?['value'] != null) {
          final List<dynamic> categories = data['data']['value'];
          gameCategories.value = categories
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          // 设置默认选中第一个分类
          if (gameCategories.isNotEmpty) {
            selectedCategory.value = gameCategories.first['type'] ?? 'HOME_TOP';
          }
        }
      }
    } catch (e) {
      debugPrint('加载游戏分类失败: $e');
      // 失败时使用默认分类
      _setDefaultCategories();
    }

    // 加载游戏列表
    _loadGames();
  }

  /// 设置默认分类（API失败时的备用）
  void _setDefaultCategories() {
    gameCategories.value = [
      {'name': 'gamestype_recommend', 'type': 'HOME_TOP', 'icon': '⭐'},
      {'name': 'gamestype_slot', 'type': 'slot', 'icon': '🎲'},
      {'name': 'gamestype_table', 'type': 'table', 'icon': '🎰'},
      {'name': 'gamestype_animal', 'type': 'animal', 'icon': '🐒'},
      {'name': 'gamestype_live', 'type': 'live', 'icon': '🎰'},
      {'name': 'gamestype_fish', 'type': 'fish', 'icon': '🐟'},
      {'name': 'gamestype_arcade', 'type': 'arcade', 'icon': '🎮'},
    ];
  }

  /// 切换游戏分类
  void selectCategory(String categoryType) {
    if (categoryType.isEmpty) return;

    selectedCategory.value = categoryType;
    selectedSlotProvider.value = _allProviderId;
    currentPage.value = 1;
    gameList.clear();
    expandedGames.clear();
    hasMoreData.value = true;
    loadError.value = false;
    _loadGames();
  }

  void selectSlotProvider(String providerId) {
    if (!showSlotProviderFilter || providerId.isEmpty) {
      return;
    }
    if (selectedSlotProvider.value == providerId &&
        currentPage.value == 1 &&
        gameList.isNotEmpty) {
      return;
    }

    selectedSlotProvider.value = providerId;
    currentPage.value = 1;
    gameList.clear();
    expandedGames.clear();
    hasMoreData.value = true;
    loadError.value = false;
    _loadGames();
  }

  /// 加载游戏数据
  Future<void> _loadGames() async {
    if (isLoading.value || !hasMoreData.value) return;

    isLoading.value = true;
    final isFirstPage = currentPage.value == 1;
    if (isFirstPage) {
      loadError.value = false;
    }

    final lang = normalizeApiLang(
      Get.locale?.toLanguageTag() ?? Get.locale?.languageCode,
    );

    // 检查是否登录，决定是否传 Authorization
    final authController = Get.find<AuthController>();
    final bool isLoggedIn = authController.isLoggedIn.value;

    try {
      final requestData = <String, String>{
        'lang': lang,
        'game_type': selectedCategory.value.isNotEmpty
            ? selectedCategory.value
            : 'HOME_TOP',
        'platform_type': 'h5',
        'page': currentPage.value.toString(),
        'size': pageSize.value.toString(),
      };
      final selectedProviderValue = currentSlotProvider.requestValue;
      if (showSlotProviderFilter &&
          selectedProviderValue != null &&
          selectedProviderValue.isNotEmpty) {
        requestData['gamehall'] = selectedProviderValue;
      }

      final response = await _apiClient.post(
        '/user/games/type',
        data: requestData,
        withAuth: isLoggedIn, // 根据登录状态决定是否传 Authorization
      );

      if (response.statusCode == 200 && response.data != null) {
        // 安全转换 response.data
        Map<String, dynamic> responseData;
        try {
          if (response.data is Map) {
            responseData = Map<String, dynamic>.from(response.data as Map);
          } else {
            // 如果是字符串，尝试解析JSON
            responseData = Map<String, dynamic>.from(
              jsonDecode(response.data.toString()) as Map,
            );
          }
        } catch (e) {
          debugPrint('响应数据转换失败: $e');
          responseData = {};
        }

        if (responseData['code'] == 1) {
          final gameTypeResponse = gametype.fromJson(responseData);

          if (gameTypeResponse.data != null &&
              gameTypeResponse.data!.list != null) {
            final newGames = gameTypeResponse.data!.list!;

            if (currentPage.value == 1) {
              gameList.value = newGames;
            } else {
              gameList.addAll(newGames);
            }

            // 检查是否还有更多数据
            if (newGames.length < pageSize.value) {
              hasMoreData.value = false;
            } else {
              currentPage.value++;
            }
            loadError.value = false;
          } else {
            // data 为 null 或 list 为 null，无论第几页都停止加载
            hasMoreData.value = false;
            if (isFirstPage) {
              gameList.clear();
              loadError.value = false;
            }
          }
        } else {
          if (isFirstPage) {
            hasMoreData.value = false;
            loadError.value = true;
          }
        }
      } else {
        if (isFirstPage) {
          hasMoreData.value = false;
          loadError.value = true;
        }
      }
    } catch (e) {
      debugPrint('加载游戏数据失败: $e');
      if (gameList.isEmpty) {
        hasMoreData.value = false;
        if (isFirstPage) {
          loadError.value = true;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新数据（语言切换或下拉刷新时调用）
  Future<void> refreshGames() async {
    currentPage.value = 1;
    gameList.clear(); // 清空游戏列表，显示加载状态
    hasMoreData.value = true;
    expandedGames.clear();
    loadError.value = false;
    await _loadGames();
  }

  /// 加载更多数据（无限滚动）
  Future<void> loadMoreGames() async {
    if (hasMoreData.value && !isLoading.value) {
      await _loadGames();
    }
  }

  /// 切换游戏卡片展开状态

  /// 切换游戏喜欢状态
  void toggleGameLiked(int gameId) {
    if (likedGames.contains(gameId)) {
      likedGames.remove(gameId);
    } else {
      likedGames.add(gameId);
    }
  }

  /// 开始游戏
  void startGame(BuildContext context, GameList game) {
    // 判断是否登录
    if (!Get.find<AuthController>().isLoggedIn.value) {
      Get.find<AuthController>().openLoginOverlay(context);
      return;
    }

    debugPrint('开始游戏: ${game.name}');
    //关闭弹窗
    closeGameOverlay();
    // 跳转到游戏启动页面
    Get.toNamed(Routes.GAME_START, arguments: game);
  }

  /// 获取分类显示名称
  String getCategoryDisplayName(String type) {
    final category =
        gameCategories.firstWhereOrNull((cat) => cat['type'] == type);
    return category?['name'] ?? type;
  }

  /// 获取分类图标
  String getCategoryIcon(String type) {
    final category =
        gameCategories.firstWhereOrNull((cat) => cat['type'] == type);
    return category?['icon'] ?? '🎮';
  }

  bool _isSlotCategory(String type) => type.trim().toLowerCase() == 'slot';

  /// 切换游戏收藏状态
  Future<void> toggleFavorite(GameList game) async {
    // 检查是否登录
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn.value) {
      Get.snackbar('提示', '请先登录', snackPosition: SnackPosition.TOP);
      return;
    }

    if (game.gamecode == null || game.gamehall == null) {
      Get.snackbar('错误', '游戏信息不完整', snackPosition: SnackPosition.TOP);
      return;
    }

    final bool currentFavoriteStatus = game.isFavorite ?? false;
    final bool isRemoving = currentFavoriteStatus;
    try {
      if (currentFavoriteStatus) {
        // 取消收藏 - DELETE 请求
        final response = await _apiClient.delete(
          '/user/favorite-games',
          queryParameters: {
            'gamecode': game.gamecode,
            'gamehall': game.gamehall,
          },
          withAuth: true,
        );

        if (response.statusCode == 200 && response.data['code'] == 1) {
          // 更新本地状态
          game.isFavorite = false;
          gameList.refresh(); // 刷新列表
          Get.snackbar(
            'transactionStatus_success'.tr,
            'favoriteRemoveSuccess'.tr,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          final msg = response.data['msg']?.toString();
          Get.snackbar(
            'transactionStatus_failed'.tr,
            (msg == null || msg.isEmpty) ? 'favoriteRemoveFailed'.tr : msg,
            snackPosition: SnackPosition.TOP,
          );
        }
      } else {
        // 添加收藏 - POST 请求
        final response = await _apiClient.post(
          '/user/favorite-games',
          data: {
            'gamecode': game.gamecode,
            'gamehall': game.gamehall,
          },
          withAuth: true,
        );

        if (response.statusCode == 200 && response.data['code'] == 1) {
          // 更新本地状态
          game.isFavorite = true;
          gameList.refresh(); // 刷新列表
          Get.snackbar(
            'transactionStatus_success'.tr,
            'favoriteAddSuccess'.tr,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          final msg = response.data['msg']?.toString();
          Get.snackbar(
            'transactionStatus_failed'.tr,
            (msg == null || msg.isEmpty) ? 'favoriteAddFailed'.tr : msg,
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      debugPrint('收藏操作失败: $e');
      final fallbackKey =
          isRemoving ? 'favoriteRemoveFailed' : 'favoriteAddFailed';
      Get.snackbar(
        'transactionStatus_failed'.tr,
        fallbackKey.tr,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
