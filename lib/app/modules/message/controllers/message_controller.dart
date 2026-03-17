import 'package:get/get.dart';
import 'package:igames/app/data/services/announcement_service.dart';

class MessageController extends GetxController {
  final AnnouncementService _service = Get.find<AnnouncementService>();

  // 消息分类列表
  final types = <AnnouncementType>[].obs;
  // 当前选中的分类索引
  final currentTypeIndex = 0.obs;
  // 当前选中的tab: unread/read
  final currentTab = 'unread'.obs;
  // 消息列表
  final messages = <Announcement>[].obs;
  // 加载状态
  final isLoading = false.obs;
  // 当前页
  final currentPage = 1.obs;
  // 总数
  final total = 0.obs;
  // 每页数量
  final pageSize = 20;
  // 未读数量
  final unreadCount = 0.obs;

  // 当前分类的type
  String get currentType => types.isNotEmpty ? types[currentTypeIndex.value].type : '';

  @override
  void onInit() {
    super.onInit();
    loadTypes();
  }

  /// 加载消息分类
  Future<void> loadTypes() async {
    final result = await _service.getAnnouncementTypes();
    final merged = <AnnouncementType>[
      AnnouncementType(name: 'message_all', type: ''),
      ...result,
    ];
    types.assignAll(merged);
    await refreshUnreadCount();
    await _service.refreshTotalUnreadCount();
    loadMessages();
  }

  /// 刷新未读数量
  Future<void> refreshUnreadCount() async {
    unreadCount.value = await _service.getUnreadCount(type: currentType);
  }

  /// 切换分类
  void switchType(int index) {
    if (currentTypeIndex.value != index) {
      currentTypeIndex.value = index;
      currentPage.value = 1;
      refreshUnreadCount();
      loadMessages();
    }
  }

  /// 切换已读/未读
  void switchTab(String tab) {
    if (currentTab.value != tab) {
      currentTab.value = tab;
      currentPage.value = 1;
      loadMessages();
    }
  }

  /// 加载消息列表
  Future<void> loadMessages() async {
    isLoading.value = true;
    try {
      final result = await _service.getAnnouncements(
        type: currentType,
        tab: currentTab.value,
        page: currentPage.value,
        size: pageSize,
      );
      messages.assignAll(result['list'] as List<Announcement>);
      total.value = result['total'] as int;
    } finally {
      isLoading.value = false;
    }
  }

  /// 刷新
  Future<void> refresh() async {
    currentPage.value = 1;
    await loadMessages();
  }

  /// 加载更多
  Future<void> loadMore() async {
    if (messages.length >= total.value) return;
    currentPage.value++;
    final result = await _service.getAnnouncements(
      type: currentType,
      tab: currentTab.value,
      page: currentPage.value,
      size: pageSize,
    );
    messages.addAll(result['list'] as List<Announcement>);
  }

  /// 标记已读
  Future<void> markAsRead(int id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      // 从未读列表移除
      if (currentTab.value == 'unread') {
        messages.removeWhere((m) => m.id == id);
      }
      // 更新未读数量
      refreshUnreadCount();
    }
  }
}
