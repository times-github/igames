import 'dart:ui';
import 'package:get/get.dart';

/// 全局应用配置类
class AppConfig {
  // 私有构造函数，防止实例化
  AppConfig._();

  // ==================== 网站基本信息 ====================

  /// 网站默认名称
  static const String appName = 'igames';

  /// 分页大小
  static const int pageSize = 40;
  // / API基础URL
  // static const String apiBaseUrl = 'https://api.getwiner.win';
  static const String apiBaseUrl = 'http://127.0.0.1:8199';

  /// 游戏图标基础URL
  // static const String gameIconBaseUrl = 'https://api.getwiner.win/';
  static const String gameIconBaseUrl = 'http://127.0.0.1:8199/';

  /// Web 应用地址（用于生成邀请链接等）
  static const String appWebUrl = 'https://www.getwiner.win';
  // static const String appWebUrl = 'http://localhost:PORT'; // 本地开发时替换

  /// OTP 签名密钥
  static const String otpSecret = '7hygjitdsghyr475f6';

  /// Turnstile 站点公钥（Web 登录/注册）
  static const String turnstileSiteKey = '1x00000000000000000000AA'; //测试环境
  // static const String turnstileSiteKey = '0x4AAAAAACnWJ5yLmBg0s6bL'; //正式环境
  /// 默认充值金额选项（后端未返回时兜底）
  static const List<String> defaultDepositAmounts = [
    '50',
    '10',
    '20',
    '30',
    '100',
    '200'
  ];

  /// 货币配置：根据语言切换货币缩写与符号
  // static const Map<String, Map<String, String>> _currencyByLanguage = {
  //   'id': {'code': 'IDR', 'symbol': 'Rp'},
  //   'zh': {'code': 'CNY', 'symbol': '¥'},
  //   'en': {'code': 'USD', 'symbol': r'$'},
  // };

  // /// 货币配置：固定为印尼币种
  static const Map<String, Map<String, String>> _currencyByLanguage = {
    'id': {'code': 'IDR', 'symbol': 'Rp'},
    'zh': {'code': 'IDR', 'symbol': 'Rp'},
    'en': {'code': 'IDR', 'symbol': 'Rp'},
  };

  static const String _defaultCurrencyCode = 'IDR';
  static const String _defaultCurrencySymbol = 'Rp';

  /// 获取当前语言对应的货币缩写
  static String currencyCode({Locale? locale}) {
    final lang = _resolveLanguage(locale);
    return _currencyByLanguage[lang]?['code'] ?? _defaultCurrencyCode;
  }

  /// 获取当前语言对应的货币符号
  static String currencySymbol({Locale? locale}) {
    final lang = _resolveLanguage(locale);
    return _currencyByLanguage[lang]?['symbol'] ?? _defaultCurrencySymbol;
  }

  static String _resolveLanguage(Locale? locale) {
    final lang = (locale ?? Get.locale)?.languageCode.toLowerCase();
    return lang ?? 'id';
  }
}
