import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:igames/app/utils/api_client.dart';
import 'package:igames/config/app_config.dart';
import 'dart:convert';

/// 拉取站点基础信息（如名称）的服务
class AppInfoService extends GetxService {
  final ApiClient _apiClient = ApiClient();

  /// 站点名称，默认使用本地配置，拉取后更新
  final RxString appName = AppConfig.appName.obs;
  final RxString appLogo = 'assets/images/binguo168.png'.obs;
  final RxList<String> depositAmountOptions = <String>[].obs;
  final RxList<AppBanner> banners = <AppBanner>[].obs;

  /// 拉取最新站点名称
  Future<void> fetchAppName() async {
    try {
      final resp =
          await _apiClient.get('/user/config/app_name', withAuth: false);
      if (resp.statusCode == 200) {
        final value = _extractConfigValue(resp.data)?.toString();
        if (value != null && value.isNotEmpty) {
          appName.value = value;
          Get.forceAppUpdate();
        }
      }
    } catch (e) {
      debugPrint('获取站点名称失败: $e');
    }
  }

  /// 拉取站点 Logo
  Future<void> fetchAppLogo() async {
    try {
      final resp =
          await _apiClient.get('/user/config/app_logo', withAuth: false);
      if (resp.statusCode == 200) {
        final value = _extractConfigValue(resp.data)?.toString();
        if (value != null && value.isNotEmpty) {
          appLogo.value = _normalizeUrl(value);
          Get.forceAppUpdate();
        }
      }
    } catch (e) {
      debugPrint('获取站点 Logo 失败: $e');
    }
  }

  /// 拉取充值金额选项
  Future<void> fetchDepositAmounts() async {
    try {
      final resp = await _apiClient.get(
        '/user/config/deposit_amount_options',
        withAuth: false,
      );
      if (resp.statusCode == 200) {
        final configValue = _extractConfigValue(resp.data);
        // 直接返回列表的情况
        if (configValue is List) {
          depositAmountOptions
              .assignAll(configValue.map((e) => e.toString()).toList());
          Get.forceAppUpdate();
          return;
        }
        final raw = configValue?.toString();
        if (raw != null && raw.isNotEmpty) {
          final parsed = _parseAmountList(raw);
          if (parsed.isNotEmpty) {
            depositAmountOptions.assignAll(parsed);
            Get.forceAppUpdate();
          }
        }
      }
    } catch (e) {
      debugPrint('获取充值金额选项失败: $e');
    }
  }

  List<String> _parseAmountList(String raw) {
    try {
      final trimmed = raw.trim();
      // JSON 数组
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
      // 普通逗号分隔
      final cleaned = trimmed.replaceAll('[', '').replaceAll(']', '');
      return cleaned
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 拉取首页轮播配置
  Future<void> fetchAppBanners({
    String sceneCode = 'home_banner',
    String lang = 'id',
    String? platform,
  }) async {
    try {
      final resp = await _apiClient.get(
        '/user/banner/pic',
        withAuth: false,
        queryParameters: {
          'scene_code': sceneCode,
          'lang': lang,
          'platform': platform ?? (kIsWeb ? 'h5' : 'app'),
        },
      );
      if (resp.statusCode == 200) {
        final parsed = _parseBannerData(resp.data);
        if (parsed.isNotEmpty) {
          banners.assignAll(parsed);
          Get.forceAppUpdate();
        }
      }
    } catch (e) {
      debugPrint('获取首页轮播失败: $e');
    }
  }

  dynamic _extractConfigValue(dynamic data) {
    if (data is Map) {
      final inner = data['data'];
      if (inner is Map) {
        if (inner.containsKey('config_value')) return inner['config_value'];
        if (inner.containsKey('value')) return inner['value'];
      }
      if (inner != null && inner is! Map) return inner;
      if (data.containsKey('config_value')) return data['config_value'];
      if (data.containsKey('value')) return data['value'];
    }
    return data;
  }

  List<AppBanner> _parseBannerData(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return _mapBannerList(raw);
    }
    if (raw is Map) {
      if (raw['data'] is Map && (raw['data'] as Map)['list'] is List) {
        return _mapBannerList((raw['data'] as Map)['list'] as List);
      }
      if (raw['list'] is List) return _mapBannerList(raw['list']);
      if (raw['value'] is List) return _mapBannerList(raw['value']);
      if (raw['config_value'] is List) {
        return _mapBannerList(raw['config_value']);
      }
    }
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is List) {
        return _mapBannerList(decoded);
      }
      if (decoded is Map) {
        if (decoded['data'] is Map &&
            (decoded['data'] as Map)['list'] is List) {
          return _mapBannerList((decoded['data'] as Map)['list'] as List);
        }
        if (decoded['list'] is List) return _mapBannerList(decoded['list']);
        if (decoded['value'] is List) return _mapBannerList(decoded['value']);
        if (decoded['config_value'] is List) {
          return _mapBannerList(decoded['config_value']);
        }
      }
    } catch (_) {}
    return [];
  }

  List<AppBanner> _mapBannerList(List<dynamic> source) {
    return source.map<AppBanner>((item) {
      if (item is Map) {
        final img = item['image_url']?.toString() ??
            item['img']?.toString() ??
            item['image']?.toString() ??
            '';
        final link =
            item['link_value']?.toString() ?? item['link']?.toString();
        final title = item['title']?.toString();
        final weight = int.tryParse(item['weight']?.toString() ?? '') ?? 0;
        return AppBanner(
          img: _normalizeUrl(img),
          link: link,
          title: title,
          weight: weight,
        );
      }
      return AppBanner(img: '', link: null, title: null, weight: 0);
    }).where((e) => e.img.isNotEmpty).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
  }

  String _normalizeUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    final trimmed = raw.startsWith('/') ? raw.substring(1) : raw;
    return '${AppConfig.apiBaseUrl}/$trimmed';
  }
}

class AppBanner {
  final String img;
  final String? link;
  final String? title;
  final int weight;

  const AppBanner(
      {required this.img, this.link, this.title, this.weight = 0});
}
