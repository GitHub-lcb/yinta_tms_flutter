/// MySQL客户端应用程序的主入口文件
/// 该文件负责初始化应用程序，配置依赖注入，设置路由系统
/// 使用GetX作为状态管理和依赖注入框架
/// 支持多语言国际化和深色/浅色主题切换
/// 文件主要功能：
/// 1. 初始化必要的Flutter绑定
/// 2. 注册全局服务和控制器
/// 3. 配置应用主题和国际化
/// 4. 设置路由系统

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/theme_controller.dart';
import 'config/app_config.dart';
import 'i18n/locale_controller.dart';
import 'i18n/translations.dart';
import 'initializer/service_initializer.dart';
import 'routes/app_pages.dart';
import 'themes/app_theme.dart';

/// 应用程序的入口函数
void main() async {
  // 确保初始化Flutter的widgets和binding，以便在使用任何Flutter功能之前做好准备
  WidgetsFlutterBinding.ensureInitialized();

  // 异步初始化服务。这可能包括加载配置文件、初始化网络服务或其他需要在应用运行前完成的任务
  await ServiceInitializer.init();

  // 启动应用，MyApp是应用的入口点
  runApp(const MyApp());
}

/// 应用程序的根Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取主题控制器，用于全局控制应用的主题
    final themeController = Get.find<ThemeController>();
    // 获取语言控制器，用于全局控制应用的语言设置
    final localeController = Get.find<LocaleController>();

    // 使用Obx监听控制器的状态变化，以动态更新应用的主题和语言
    return Obx(() => GetMaterialApp(
          // 是否在调试模式下显示标志
          debugShowCheckedModeBanner: AppConfig.showDebugBanner,
          // 应用的标题
          title: AppConfig.appTitle,
          // 应用的亮色主题
          theme: AppTheme.lightTheme,
          // 应用的暗色主题
          darkTheme: AppTheme.darkTheme,
          // 根据主题控制器的状态决定使用哪种主题模式
          themeMode: themeController.isDarkMode.value
              ? ThemeMode.dark
              : ThemeMode.light,
          // 应用的多语言消息
          translations: Messages(),
          // 当前应用的语言设置
          locale: localeController.currentLocale.value,
          // 默认语言设置，当语言设置失败时使用
          fallbackLocale: AppConfig.defaultLocale,
          // 应用支持的所有语言设置
          supportedLocales: AppConfig.supportedLocales,
          // 应用的本地化代理
          localizationsDelegates: AppConfig.localizationsDelegates,
          // 应用的初始路由页面
          initialRoute: AppPages.initial,
          // 应用的所有路由配置
          getPages: AppPages.routes,
        ));
  }
}
