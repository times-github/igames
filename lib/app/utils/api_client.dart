import 'package:dio/dio.dart' as http;
import 'package:igames/app/data/services/userServices.dart';
import 'package:flutter/foundation.dart';
import 'package:igames/config/app_config_export.dart';

/// HTTP客户端基类
///
/// 提供统一的网络请求配置和错误处理
class ApiClient {
  static final ApiClient _instance = ApiClient._internal1(); // 单例模式
  factory ApiClient() => _instance; // 工厂模式

  late http.Dio _dio; // 私有Dio实例
  static VoidCallback? onUnauthorized;

  /// 基础URL
  static const String baseUrl = AppConfig.apiBaseUrl;

  /// 私有构造函数，自动初始化
  ApiClient._internal1() {
    _initDio();
  }

  /// 初始化Dio客户端
  void _initDio() {
    _dio = http.Dio(http.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
    ));

    // 请求拦截器
    _dio.interceptors.add(http.InterceptorsWrapper(
      //
      onRequest: (options, handler) async {
        // 是否附带 Authorization 头，默认 true
        final bool withAuth = (options.extra['withAuth'] as bool?) ?? true;

        // 动态注入 token 到请求头
        if (withAuth) {
          try {
            final token = await UserServices.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['AuthorizationU'] = 'Bearer ' + token;
            }
          } catch (_) {}
        }
        // 调试日志
        debugPrint(
            '🌐 request: ${options.method} ${options.path}${withAuth ? ' [auth]' : ''}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint(
            '✅ response: ${response.statusCode} ${response.requestOptions.path}');
        _handleUnauthorizedResponse(response.data);
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('❌ error: ${error.message ?? error.toString()}');
        _handleUnauthorizedResponse(error.response?.data);
        handler.next(error);
      },
    ));
  }

  /// 获取Dio实例
  http.Dio get dio => _dio;

  /// 发送POST请求
  Future<http.Response> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      bool withAuth = true}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: http.Options(extra: {"withAuth": withAuth}),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 发送GET请求
  Future<http.Response> get(String path,
      {Map<String, dynamic>? queryParameters, bool withAuth = true}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: http.Options(extra: {"withAuth": withAuth}),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// 发送DELETE请求
  Future<http.Response> delete(String path,
      {Map<String, dynamic>? queryParameters, bool withAuth = true}) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: http.Options(extra: {"withAuth": withAuth}),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static void _handleUnauthorizedResponse(dynamic data) {
    if (_isUnauthorized(data)) {
      onUnauthorized?.call();
    }
  }

  static bool _isUnauthorized(dynamic data) {
    if (data is Map) {
      return data['code'] == 0 && data['msg'] == 'unauthorized';
    }
    return false;
  }
}
