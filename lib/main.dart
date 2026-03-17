import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart'; // GetX
import 'package:flutter/services.dart';
import 'package:igames/app/modules/home/bindings/home_binding.dart';
import 'package:igames/app/modules/home/views/home.dart';
import 'package:igames/app/data/services/app_info_service.dart';
import 'package:igames/app/data/services/jackpot_service.dart';
import 'package:igames/app/utils/api_client.dart';

import 'app/routes/app_pages.dart';
import 'generated/locales.g.dart'; // 是否需要国际化
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 屏幕适配
import 'config/app_config_export.dart'; // 全局配置
import 'utils/web_hash_handler.dart';
import 'utils/web_lang_param.dart';
import 'app/utils/launch_params.dart';
import 'app/utils/storage.dart';

Locale _resolveStoredLocale(dynamic raw) {
  if (raw is! String) return const Locale('id', 'ID');
  final normalized = raw.toLowerCase();
  if (normalized == 'zh' || normalized == 'zh-cn' || normalized == 'zh_cn') {
    return const Locale('zh', 'CN');
  }
  if (normalized == 'cn') {
    return const Locale('zh', 'CN');
  }
  if (normalized == 'en' || normalized == 'en-us' || normalized == 'en_us') {
    return const Locale('en', 'US');
  }
  if (normalized == 'id' || normalized == 'id-id' || normalized == 'id_id') {
    return const Locale('id', 'ID');
  }
  return const Locale('id', 'ID');
}

void main() async {
  //配置透明的状态栏
  SystemUiOverlayStyle systemUiOverlayStyle =
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent);
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  WidgetsFlutterBinding.ensureInitialized(); //
  LaunchParams.captureFromUri(Uri.base);
  final urlLang = LaunchParams.langCode;
  final urlInvite = LaunchParams.registerCode;
  if (urlLang != null) {
    await Storage.setData("language", urlLang);
  }
  if (urlInvite != null && urlInvite.isNotEmpty) {
    await Storage.setData("invite_code", urlInvite);
  } else {
    final storedInvite = await Storage.getData("invite_code");
    if (storedInvite is String && storedInvite.isNotEmpty) {
      LaunchParams.setRegisterCode(storedInvite);
    }
  }
  final storedLanguage = urlLang ?? await Storage.getData("language");
  final initialLocale = _resolveStoredLocale(storedLanguage);
  if (kIsWeb) {
    ensureHomeHash();
  }

  // 全局服务
  Get.put(ApiClient(), permanent: true); // 先注册 ApiClient
  final appInfo = Get.put(AppInfoService(), permanent: true);
  final jackpotService = Get.put(JackpotService(), permanent: true);
  // 异步拉取站点名称（不阻塞启动）
  appInfo.fetchAppName();
  appInfo.fetchAppLogo();
  appInfo.fetchDepositAmounts();
  appInfo.fetchAppBanners(lang: initialLocale.languageCode);

  // 注册 WebView 平台实现（Web 平台）

  runApp(ScreenUtilInit(
      designSize: const Size(1080, 2400), //设计稿的宽度和高度 px
      minTextAdapt: true, // 是否根据屏幕大小自动调整字体大小
      splitScreenMode: true, // 是否根据屏幕大小自动调整布局
      builder: (context, child) {
        final appInfo = Get.find<AppInfoService>();
        return Obx(
          () => GetMaterialApp(
            debugShowCheckedModeBanner: false, // 隐藏调试标志
            title: appInfo.appName.value,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // 系统主题

            defaultTransition: Transition.rightToLeftWithFade, //全局动画
            initialRoute: AppPages.INITIAL, // 初始路由
            getPages: AppPages.routes, // 路由列表
            // 遇到不认识的路由，强制回首页
            unknownRoute: GetPage(
              name: AppPages.INITIAL,
              page: () => Home(),
              binding: HomeBinding(),
            ),

            // // 全局路由拦截
            // onGenerateRoute: (settings) {
            //   final current = Get.currentRoute; // 当前路由
            //   // 白名单（允许直接访问的路由）
            //   const allowed = {
            //     AppPages.INITIAL, // '/home'
            //     '/', // 有些场景会是 '/'
            //     '', // 极端情况
            //   };

            //   // 已在首页或白名单内不处理
            //   if (allowed.contains(current)) return;

            //   // 避免重复跳转（如正在跳回）
            //   if (Get.routing.isBack == true) return;

            //   // 非白名单路径：强制回首页
            //   Future.microtask(() => Get.offAllNamed(AppPages.INITIAL));
            // },

            translationsKeys: AppTranslation.translations, // 国际化翻译
            // 默认与后备语言（使用标准构造：languageCode + countryCode）
            locale: initialLocale, // 默认语言来自本地缓存
            fallbackLocale: const Locale('id', 'ID'), // 翻译失败时使用中文

            // 与语言选择器一致的支持列表
            supportedLocales: const [
              Locale('zh', 'CN'),
              Locale('en', 'US'),
              Locale('id', 'ID'),
            ],

            routingCallback: (routing) {
              if (!kIsWeb) return;
              final lang =
                  Get.locale?.languageCode ?? initialLocale.languageCode;
              final params = <String, String?>{'lang': lang.toLowerCase()};
              final inviteCode = LaunchParams.registerCode;
              params['invite_code'] = inviteCode;
              setWebHashParams(params);
            },

            localizationsDelegates: const [
              //
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // 按系统语言匹配，匹配不到则用 fallback
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) return const Locale('id', 'ID');
              for (final l in supportedLocales) {
                if (l.languageCode == locale.languageCode) return l;
              }
              return const Locale('id', 'ID');
            },
          ),
        );
      }));
}
