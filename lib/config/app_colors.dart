import 'package:flutter/material.dart';

/// 应用颜色配置类
class AppColors {
  // 私有构造函数，防止实例化
  AppColors._();

  // ==================== 主色调 ====================

  /// 主色调 - 深蓝色系（根据图片中的主背景色）
  static const Color primary = Color(0xFF4EA3FF); // 图片中的主蓝色
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1565C0);

  /// 次要色调 - 橙色系（根据图片中的赢取金额颜色）
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);

  /// 强调色 - 绿色系（根据图片中的发光绿色箭头）
  static const Color accent = Color(0xFF4CAF50);
  static const Color accentLight = Color(0xFF81C784);
  static const Color accentDark = Color(0xFF388E3C);

  // ==================== 中性色 ====================

  /// 白色
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSmoke = Color(0xFFF5F5F5);
  static const Color ghostWhite = Color(0xFFF8F9FA);

  /// 黑色
  static const Color black = Color(0xFF000000);
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black38 = Color(0x61000000);
  static const Color black12 = Color(0x1F000000);

  /// 灰色系
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ==================== 功能色 ====================

  /// 成功色
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  /// 警告色
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  /// 错误色
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  /// 信息色
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ==================== 背景色 ====================

  /// 主背景色（根据图片中的深蓝色背景）
  static const Color background = Color(0xFF0E1621); // 图片中的主背景色
  static const Color backgroundLight = Color(0xFF1A202C); // 稍浅的背景色
  static const Color backgroundDark = Color(0xFF0A0F16); // 更深的背景色

  /// 卡片背景色（根据图片中的卡片背景）
  static const Color cardBackground = Color(0xFF20242D); // 图片中的卡片背景色
  static const Color cardBackgroundLight = Color(0xFF2A2F3A);
  static const Color cardBackgroundDark = Color(0xFF1A1F28);

  /// 表面背景色
  static const Color surface = Color(0xFF20242D); // 与卡片背景色一致
  static const Color surfaceLight = Color(0xFF2A2F3A);
  static const Color surfaceDark = Color(0xFF1A1F28);

  /// 侧边栏背景色（根据图片中的左侧导航栏）
  static const Color sidebarBackground = Color(0xFF1A202C);

  // ==================== 文字色 ====================

  /// 主要文字色（根据图片中的白色文字）
  static const Color textPrimary = Color(0xFFFFFFFF); // 图片中的主要文字色
  static const Color textSecondary = Color(0xFFB0BEC5); // 图片中的次要文字色
  static const Color textTertiary = Color(0xFF78909C); // 图片中的辅助文字色
  static const Color textDisabled = Color(0xFF546E7A);

  /// 反色文字
  static const Color textOnPrimary = Color(0xFF000000);
  static const Color textOnSecondary = Color(0xFF000000);
  static const Color textOnBackground = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFFFFFFFF);

  // ==================== 边框色 ====================

  /// 边框色
  static const Color border = Color(0xFF37474F);
  static const Color borderLight = Color(0xFF455A64);
  static const Color borderDark = Color(0xFF263238);

  /// 分割线色
  static const Color divider = Color(0xFF37474F);
  static const Color dividerLight = Color(0xFF455A64);

  // ==================== 阴影色 ====================

  /// 阴影色
  static const Color shadow = Color(0x33000000);
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x4D000000);

  // ==================== 游戏主题色 ====================

  /// 游戏相关颜色（根据图片中的游戏元素）
  static const Color gameAction = Color(0xFFE91E63);
  static const Color gameAdventure = Color(0xFF9C27B0);
  static const Color gameRacing = Color(0xFF00BCD4);
  static const Color gameStrategy = Color(0xFF795548);
  static const Color gameRPG = Color(0xFF607D8B);
  static const Color gameSports = Color(0xFF8BC34A);

  /// 游戏特殊颜色（根据图片中的特殊元素）
  static const Color gameWin = Color(0xFFFFD700); // 赢取金额的金色
  static const Color gameWinMega = Color(0xFFFF6B35); // 大型赢取金额的橙色
  static const Color gameLive = Color(0xFF00BCD4); // Live标签的蓝色
  static const Color gameNew = Color(0xFF4CAF50); // NEW标签的绿色

  // ==================== 渐变色 ====================

  /// 主色调渐变（根据图片中的渐变效果）
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0E1621), Color(0xFF1A202C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 次要色调渐变
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 强调色渐变
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 深色背景渐变（根据图片中的主视觉区域）
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 24, 26, 29),
      Color.fromARGB(255, 41, 43, 49)
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==================== 透明度工具方法 ====================

  /// 获取带透明度的颜色
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// 获取浅色版本
  static Color getLight(Color color) {
    return color.withValues(alpha: 0.1);
  }

  /// 获取中等透明度版本
  static Color getMedium(Color color) {
    return color.withValues(alpha: 0.3);
  }

  /// 获取深色版本
  static Color getDark(Color color) {
    return color.withValues(alpha: 0.7);
  }

  // ==================== 主题色获取方法 ====================

  /// 根据主题获取背景色
  static Color getBackgroundColor(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return backgroundLight;
      case ThemeMode.dark:
        return backgroundDark;
      case ThemeMode.system:
        return backgroundDark;
    }
  }

  /// 根据主题获取文字色
  static Color getTextColor(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return textPrimary;
      case ThemeMode.dark:
        return textPrimary;
      case ThemeMode.system:
        return textPrimary;
    }
  }
}
