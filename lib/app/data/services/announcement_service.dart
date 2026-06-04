import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/app/utils/api_lang.dart';
import 'package:igames/app/modules/auth/controllers/auth_controller.dart';
import 'package:igames/app/data/services/user_service.dart';

/// 公告消息模型
class Announcement {
  final int id;
  final String type;
  final String title;
  final String? summary;
  final String? content;
  final String publishAt;
  final bool read;

  Announcement({
    required this.id,
    required this.type,
    required this.title,
    this.summary,
    this.content,
    required this.publishAt,
    required this.read,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'],
      content: json['content'],
      publishAt: _parsePublishAt(json['publish_at']),
      read: json['read'] ?? false,
    );
  }

  static String _parsePublishAt(dynamic value) {
    if (value == null) return '';
    if (value is int || value is num) {
      final numValue = value is num ? value : (value as int);
      final ms = numValue > 100000000000 ? numValue : numValue * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms.toInt()).toIso8601String();
    }
    final text = value.toString().trim();
    if (text.isEmpty) return '';
    final asNum = num.tryParse(text);
    if (asNum != null) {
      final ms = asNum > 100000000000 ? asNum : asNum * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms.toInt()).toIso8601String();
    }
    return text;
  }
}

/// 消息分类模型
class AnnouncementType {
  final String name;
  final String type;

  AnnouncementType({required this.name, required this.type});

  factory AnnouncementType.fromJson(Map<String, dynamic> json) {
    return AnnouncementType(
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }
}

/// 公告服务
class AnnouncementService extends GetxService {
  final ApiClient _apiClient = ApiClient();

  /// 未读消息总数
  final totalUnreadCount = 0.obs;
  final _isFetchingUnread = false.obs;
  DateTime? _lastUnreadFetchAt;

  /// 处理未授权响应
  void _handleUnauthorized() {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      auth.logout();
      final context = Get.context;
      if (context != null) {
        auth.openLoginOverlay();
      }
    }
  }

  Future<bool> _isLoggedIn() async {
    if (Get.isRegistered<AuthController>()) {
      final auth = Get.find<AuthController>();
      if (auth.isLoggedIn.value) return true;
    }
    return await UserServices.getUserLoginState();
  }

  /// 获取消息分类
  Future<List<AnnouncementType>> getAnnouncementTypes() async {
    try {
      if (!await _isLoggedIn()) return [];
      final resp = await _apiClient.get('/user/config/announcement_type');
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data['msg'] == 'unauthorized') {
          _handleUnauthorized();
          return [];
        }
        final data = resp.data['data'];
        if (data is Map && data['value'] is List) {
          return (data['value'] as List)
              .map((e) => AnnouncementType.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('获取消息分类失败: $e');
    }
    return [];
  }

  /// 获取公告列表
  Future<Map<String, dynamic>> getAnnouncements({
    String? type,
    String? tab, // unread|read
    int page = 1,
    int size = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page.toString(),
        'size': size.toString(),
        'lang': _resolveLangParam(),
      };
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (tab != null && tab.isNotEmpty) params['tab'] = tab;

      final isLoggedIn = await _isLoggedIn();
      final resp = await _apiClient.get('/user/announcements',
          queryParameters: params, withAuth: isLoggedIn);
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data['msg'] == 'unauthorized') {
          _handleUnauthorized();
          return {'list': <Announcement>[], 'page': 1, 'size': 20, 'total': 0};
        }
        final data = resp.data['data'];
        if (data is Map) {
          final list = (data['list'] as List?)
                  ?.map((e) => Announcement.fromJson(e))
                  .toList() ??
              [];
          return {
            'list': list,
            'page': data['page'] ?? 1,
            'size': data['size'] ?? 20,
            'total': data['total'] ?? 0,
          };
        }
      }
    } catch (e) {
      debugPrint('获取公告列表失败: $e');
    }
    return {'list': <Announcement>[], 'page': 1, 'size': 20, 'total': 0};
  }

  String _resolveLangParam() {
    final locale = Get.locale;
    return normalizeApiLang(
      locale?.toLanguageTag() ?? locale?.languageCode,
      fallback: 'en',
    );
  }

  /// 获取未读数量
  Future<int> getUnreadCount({String? type}) async {
    try {
      if (!await _isLoggedIn()) return 0;
      final params = <String, dynamic>{
        'lang': _resolveLangParam(),
      };
      if (type != null && type.isNotEmpty) params['type'] = type;

      final resp = await _apiClient.get('/user/announcements/unread-count',
          queryParameters: params);
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data['msg'] == 'unauthorized') {
          _handleUnauthorized();
          return 0;
        }
        final data = resp.data['data'];
        if (data is Map) {
          return data['total'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('获取未读数量失败: $e');
    }
    return 0;
  }

  /// 获取公告详情
  Future<Announcement?> getAnnouncementDetail(int id) async {
    try {
      if (!await _isLoggedIn()) return null;
      final resp = await _apiClient.get('/user/announcements/$id');
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data['msg'] == 'unauthorized') {
          _handleUnauthorized();
          return null;
        }
        final data = resp.data['data'];
        if (data is Map<String, dynamic>) {
          return Announcement.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('获取公告详情失败: $e');
    }
    return null;
  }

  /// 标记为已读
  Future<bool> markAsRead(int id) async {
    try {
      if (!await _isLoggedIn()) return false;
      final resp = await _apiClient.post('/user/announcements/$id/read');
      if (resp.statusCode == 200 && resp.data != null) {
        if (resp.data['msg'] == 'unauthorized') {
          _handleUnauthorized();
          return false;
        }
        final data = resp.data['data'];
        if (data is Map && data['success'] == true) {
          // 刷新未读数量
          refreshTotalUnreadCount();
          return true;
        }
      }
    } catch (e) {
      debugPrint('标记已读失败: $e');
    }
    return false;
  }

  /// 刷新总未读数量
  Future<void> refreshTotalUnreadCount() async {
    if (_isFetchingUnread.value) return;
    final now = DateTime.now();
    if (_lastUnreadFetchAt != null &&
        now.difference(_lastUnreadFetchAt!).inSeconds < 3) {
      return;
    }
    _isFetchingUnread.value = true;
    _lastUnreadFetchAt = now;
    try {
      totalUnreadCount.value = await getUnreadCount();
    } finally {
      _isFetchingUnread.value = false;
    }
  }
}
