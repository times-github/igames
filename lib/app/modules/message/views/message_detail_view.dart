import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:igames/app/data/services/announcement_service.dart';

class MessageDetailView extends StatefulWidget {
  const MessageDetailView({super.key});

  @override
  State<MessageDetailView> createState() => _MessageDetailViewState();
}

class _MessageDetailViewState extends State<MessageDetailView> {
  final AnnouncementService _service = Get.find<AnnouncementService>();
  Announcement? _detail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = Get.arguments as int?;
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }
    final detail = await _service.getAnnouncementDetail(id);
    setState(() {
      _detail = detail;
      _isLoading = false;
    });
    // 标记已读
    if (detail != null && !detail.read) {
      _service.markAsRead(id);
    }
  }

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
          _getTypeLabel(_detail?.type ?? ''),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : _detail == null
              ? Center(
                  child: Text(
                    'noMessages'.tr,
                    style: const TextStyle(color: Colors.white54),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _detail!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _formatDate(_detail!.publishAt),
                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _detail!.content ?? _detail!.summary ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'announcement':
        return 'announcement'.tr;
      case 'activity':
        return 'activity'.tr;
      case 'notice':
        return 'notice'.tr;
      default:
        return 'messageCenter'.tr;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }
}
