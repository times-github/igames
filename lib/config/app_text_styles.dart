import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用文字样式配置类
class AppTextStyles {
  // 私有构造函数，防止实例化
  AppTextStyles._();

  // ==================== 字体族 ====================

  /// 中文字体族
  static const String chineseFontFamily = 'PingFang SC';

  /// 英文字体族
  static const String englishFontFamily = 'Roboto';

  /// 数字字体族
  static const String numberFontFamily = 'SF Mono';

  /// 获取当前语言的字体族
  static String getFontFamily(String? languageCode) {
    switch (languageCode) {
      case 'zh':
      case 'zh-CN':
      case 'zh-TW':
        return chineseFontFamily;
      case 'en':
      case 'en-US':
      case 'en-GB':
        return englishFontFamily;
      default:
        return englishFontFamily;
    }
  }

  // ==================== 标题样式 ====================

  /// 超大标题
  static TextStyle get h1 => const TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: AppColors.textPrimary,
      );

  /// 大标题
  static TextStyle get h2 => const TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        height: 1.3,
        color: AppColors.textPrimary,
      );

  /// 中标题
  static TextStyle get h3 => const TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// 小标题
  static TextStyle get h4 => const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// 副标题
  static TextStyle get h5 => const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  /// 小副标题
  static TextStyle get h6 => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textPrimary,
      );

  // ==================== 正文样式 ====================

  /// 大正文
  static TextStyle get bodyLarge => const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  /// 正文
  static TextStyle get bodyMedium => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  /// 小正文
  static TextStyle get bodySmall => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  /// 超小正文
  static TextStyle get bodyTiny => const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textPrimary,
      );

  // ==================== 标签样式 ====================

  /// 标签
  static TextStyle get label => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// 小标签
  static TextStyle get labelSmall => const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  /// 大标签
  static TextStyle get labelLarge => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.textSecondary,
      );

  // ==================== 按钮样式 ====================

  /// 按钮文字
  static TextStyle get button => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textOnPrimary,
      );

  /// 小按钮文字
  static TextStyle get buttonSmall => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textOnPrimary,
      );

  /// 大按钮文字
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.textOnPrimary,
      );

  // ==================== 链接样式 ====================

  /// 链接文字
  static TextStyle get link => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );

  /// 小链接文字
  static TextStyle get linkSmall => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );

  // ==================== 特殊样式 ====================

  /// 强调文字
  static TextStyle get emphasis => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        height: 1.6,
        color: AppColors.primary,
      );

  /// 引用文字
  static TextStyle get quote => const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      );

  /// 代码文字
  static TextStyle get code => const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        height: 1.4,
        color: AppColors.textPrimary,
        fontFamily: 'SF Mono',
        backgroundColor: AppColors.grey100,
      );

  /// 时间文字
  static TextStyle get timestamp => const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        height: 1.4,
        color: AppColors.textTertiary,
      );

  // ==================== 响应式文字样式 ====================

  /// 根据屏幕尺寸获取响应式标题样式
  static TextStyle getResponsiveTitle(BuildContext context, {int level = 1}) {
    final width = MediaQuery.of(context).size.width;

    if (width < 768) {
      // 手机端
      switch (level) {
        case 1:
          return h1.copyWith(fontSize: 24.0);
        case 2:
          return h2.copyWith(fontSize: 20.0);
        case 3:
          return h3.copyWith(fontSize: 18.0);
        case 4:
          return h4.copyWith(fontSize: 16.0);
        case 5:
          return h5.copyWith(fontSize: 15.0);
        case 6:
          return h6.copyWith(fontSize: 14.0);
        default:
          return h1.copyWith(fontSize: 24.0);
      }
    } else if (width < 1024) {
      // 平板端
      switch (level) {
        case 1:
          return h1.copyWith(fontSize: 28.0);
        case 2:
          return h2.copyWith(fontSize: 24.0);
        case 3:
          return h3.copyWith(fontSize: 20.0);
        case 4:
          return h4.copyWith(fontSize: 18.0);
        case 5:
          return h5.copyWith(fontSize: 16.0);
        case 6:
          return h6.copyWith(fontSize: 15.0);
        default:
          return h1.copyWith(fontSize: 28.0);
      }
    } else {
      // 桌面端
      switch (level) {
        case 1:
          return h1;
        case 2:
          return h2;
        case 3:
          return h3;
        case 4:
          return h4;
        case 5:
          return h5;
        case 6:
          return h6;
        default:
          return h1;
      }
    }
  }

  /// 根据屏幕尺寸获取响应式正文样式
  static TextStyle getResponsiveBody(BuildContext context,
      {String size = 'medium'}) {
    final width = MediaQuery.of(context).size.width;

    if (width < 768) {
      // 手机端
      switch (size) {
        case 'large':
          return bodyLarge.copyWith(fontSize: 16.0);
        case 'medium':
          return bodyMedium.copyWith(fontSize: 14.0);
        case 'small':
          return bodySmall.copyWith(fontSize: 12.0);
        case 'tiny':
          return bodyTiny.copyWith(fontSize: 11.0);
        default:
          return bodyMedium.copyWith(fontSize: 14.0);
      }
    } else if (width < 1024) {
      // 平板端
      switch (size) {
        case 'large':
          return bodyLarge.copyWith(fontSize: 17.0);
        case 'medium':
          return bodyMedium.copyWith(fontSize: 15.0);
        case 'small':
          return bodySmall.copyWith(fontSize: 13.0);
        case 'tiny':
          return bodyTiny.copyWith(fontSize: 12.0);
        default:
          return bodyMedium.copyWith(fontSize: 15.0);
      }
    } else {
      // 桌面端
      switch (size) {
        case 'large':
          return bodyLarge;
        case 'medium':
          return bodyMedium;
        case 'small':
          return bodySmall;
        case 'tiny':
          return bodyTiny;
        default:
          return bodyMedium;
      }
    }
  }

  // ==================== 主题相关样式 ====================

  /// 根据主题获取文字样式
  static TextStyle getTextStyleByTheme(
      TextStyle baseStyle, ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return baseStyle;
      case ThemeMode.dark:
        return baseStyle.copyWith(
          color: AppColors.getTextColor(themeMode),
        );
      case ThemeMode.system:
        return baseStyle;
    }
  }

  /// 获取带颜色的文字样式
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  /// 获取带字重的文字样式
  static TextStyle withWeight(TextStyle baseStyle, FontWeight weight) {
    return baseStyle.copyWith(fontWeight: weight);
  }

  /// 获取带字号的文字样式
  static TextStyle withSize(TextStyle baseStyle, double size) {
    return baseStyle.copyWith(fontSize: size);
  }
}
