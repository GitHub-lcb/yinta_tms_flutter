import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 应用配置
/// 集中管理应用的配置信息
class AppConfig {
  /// 应用标题
  static const appTitle = 'yinta-tms-connect';

  /// 支持的语言列表
  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'CN'),
  ];

  /// 本地化代理
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// 默认语言
  static const defaultLocale = Locale('en', 'US');

  /// 是否显示调试标签
  static const showDebugBanner = false;
}
