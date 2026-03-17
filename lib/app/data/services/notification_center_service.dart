import 'package:get/get.dart';
import 'package:igames/app/data/models/notification_item.dart';

class NotificationCenterService extends GetxService {
  final RxList<NotificationItem> items = <NotificationItem>[].obs;
  final RxInt unreadCount = 0.obs;
  final Set<String> _seenKeys = <String>{};
  final int maxItems;

  NotificationCenterService({this.maxItems = 50});

  void add(NotificationItem item) {
    final key = '${item.type}:${item.id}';
    if (item.id > 0 && _seenKeys.contains(key)) return;
    if (item.id > 0) {
      _seenKeys.add(key);
    }
    items.insert(0, item);
    if (items.length > maxItems) {
      items.removeRange(maxItems, items.length);
    }
    unreadCount.value += 1;
  }

  void setUnreadCount(int value) {
    unreadCount.value = value;
  }

  void markAllRead() {
    unreadCount.value = 0;
  }
}
