import 'package:flutter/painting.dart';
import 'package:get/get.dart';

/// 全局应用配置类
class AppConfig {
  // 私有构造函数，防止实例化
  AppConfig._();

  // ==================== 网站基本信息 ====================

  /// 网站默认名称
  static const String appName = 'igames';

  /// 全局背景图
  static const String appBackgroundAsset = 'assets/images/appbg.png';

  /// Web 大屏启用中间手机壳的最小宽度
  static const double webDesktopShellBreakpoint = 560;

  /// Web 大屏手机壳宽度
  static const double webDesktopShellWidth = 430;

  /// Web 大屏手机壳圆角
  static const double webDesktopShellRadius = 10;

  /// Web 大屏外层纯色背景
  static const Color webDesktopOuterBackground = Color(0xFF17363A);

  /// Web 大屏手机壳描边色
  static const Color webDesktopShellBorder = Color(0x4D8DF6FF);

  /// Web 大屏手机壳阴影色
  static const Color webDesktopShellShadow = Color(0x66000000);

  /// 分页大小
  static const int pageSize = 30;
  // / API基础URL2
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
  // static const String turnstileSiteKey = '1x00000000000000000000AA'; //测试环境
  static const String turnstileSiteKey = '0x4AAAAAACnWJ5yLmBg0s6bL'; //正式环境
  /// 默认充值金额选项（后端未返回时兜底）
  static const List<String> defaultDepositAmounts = [
    '50',
    '10',
    '20',
    '30',
    '100',
    '200'
  ];

  // ==================== 赚钱页样式配置 ====================

  /// 赚钱页卡片背景色
  static const Color earnCardBackground = Color(0xFF252535);

  /// 赚钱页顶部悬浮菜单背景色
  static const Color earnFloatingMenuBackground = Color(0xFF19191E);

  /// 赚钱页强调橙色
  static const Color earnAccentOrange = Color(0xFFFF9800);

  /// 赚钱页主紫色
  static const Color earnPrimaryPurple = Color(0xFF7B5CFF);

  /// 赚钱页次级紫色
  static const Color earnSecondaryPurple = Color(0xFF5A3DCE);

  /// 赚钱页顶部悬浮菜单图标底色
  static const Color earnFloatingMenuIconBackground = Color(0xFF303044);

  /// 赚钱页顶部悬浮菜单图标边框色
  static const Color earnFloatingMenuIconBorder = Color(0x22FFFFFF);

  // ==================== 首页性能配置 ====================

  /// 首页 banner 宽高比
  static const double homeBannerAspectRatio = 2.98;

  /// 游戏卡片宽高比
  static const double gameCardAspectRatio = 0.75;

  /// 首页游戏列表列数
  static const int homeGameGridCrossAxisCount = 4;

  /// 全局按钮颜色
  static const Color buttonColor = Color.fromRGBO(103, 236, 223, 1);

  /// 按钮选中态主色
  static const Color btnSelectedColor = buttonColor;

  /// 按钮默认态背景图
  static const String btnDefaultBackgroundAsset = 'assets/images/me/btn_bg.png';

  /// 按钮选中态背景图
  static const String btnSelectedBackgroundAsset =
      'assets/images/me/btn_bg2.png';

  /// 按钮默认态文字色
  static const Color btnDefaultTextColor = Color(0xFF0B4B55);

  /// 按钮选中态文字色
  static const Color btnSelectedTextColor = Color(0xFFFFFFFF);

  /// 按钮选中态渐变
  static const LinearGradient btnSelectedGradient = LinearGradient(
    colors: [
      Color(0xFF16AFC0),
      Color(0xFF27D7E8),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 按钮选中态描边色
  static const Color btnSelectedBorderColor = Color(0xFF2BE8F2);

  /// 第二类按钮描边色
  static const Color btn2SelectedBorderColor = Color(0xFFFFD36E);

  /// 按钮选中态阴影
  static const List<BoxShadow> btnSelectedShadow = [
    BoxShadow(
      color: Color(0x661ADBE8),
      blurRadius: 12,
      spreadRadius: 0.5,
    ),
  ];

  /// 所有游戏卡片在可展示封面图时隐藏底部游戏名
  static const bool hideGameCardNameWhenImagePresent = true;

  /// 统一控制所有游戏卡片是否展示游戏名
  static bool shouldShowGameCardName({
    required bool hasDisplayableImage,
  }) {
    return !hideGameCardNameWhenImagePresent || !hasDisplayableImage;
  }

  /// 首页滚动时暂停公告 / Banner / Jackpot 自动轮播
  static const bool homePauseAutoPlayWhileScrolling = true;

  /// 首页停止滚动后，多久恢复自动轮播
  static const Duration homeAutoPlayResumeDelay = Duration(milliseconds: 260);

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
