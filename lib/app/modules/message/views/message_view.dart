import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/announcement_service.dart';
import 'package:igames/app/routes/app_pages.dart';
import 'package:igames/config/app_colors.dart';
import '../controllers/message_controller.dart';

class MessageView extends GetView<MessageController> {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'messageCenter'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 分类Tab
          _buildTypeTab(),
          // 已读/未读切换
          _buildReadTab(),
          // 消息列表
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  /// 分类Tab
  Widget _buildTypeTab() {
    return Obx(() {
      if (controller.types.isEmpty) {
        return const SizedBox(height: 48);
      }
      return SizedBox(
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(controller.types.length, (index) {
              final type = controller.types[index];
              final isSelected = controller.currentTypeIndex.value == index;
              return GestureDetector(
                onTap: () => controller.switchType(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? const Border(
                            bottom: BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 2,
                            ),
                          )
                        : null,
                  ),
                  child: Text(
                    _getTypeLabel(type.type),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      );
    });
  }

  /// 已读/未读切换
  Widget _buildReadTab() {
    return Obx(() {
      final isUnread = controller.currentTab.value == 'unread';
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => controller.switchTab('unread'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${'unread'.tr}(${controller.unreadCount.value})',
                      style: TextStyle(
                        color: isUnread ? Colors.white : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => controller.switchTab('read'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !isUnread
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'read'.tr,
                      style: TextStyle(
                        color: !isUnread ? Colors.white : Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 消息列表
  Widget _buildMessageList() {
    return Obx(() {
      if (controller.isLoading.value && controller.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        );
      }
      if (controller.messages.isEmpty) {
        return Center(
          child: Text(
            'noMessages'.tr,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: controller.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final message = controller.messages[index];
            return _buildMessageItem(message);
          },
        ),
      );
    });
  }

  /// 消息项
  Widget _buildMessageItem(Announcement message) {
    return GestureDetector(
      onTap: () {
        // 标记已读并跳转详情
        controller.markAsRead(message.id);
        Get.toNamed(Routes.MESSAGE_DETAIL, arguments: message.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              message.summary ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(message.publishAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  '${'viewDetails'.tr} >',
                  style: const TextStyle(
                    color: AppColors.gameWin,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类标签
  String _getTypeLabel(String type) {
    switch (type) {
      case '':
        return 'message_all'.tr;
      case 'announcement':
        return 'announcement'.tr;
      case 'activity':
        return 'activity'.tr;
      case 'notice':
        return 'notice'.tr;
      default:
        return type;
    }
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
