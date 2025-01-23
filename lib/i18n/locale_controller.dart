/// 语言控制器文件
/// 使用GetX状态管理框架
/// 负责管理应用程序的语言设置
/// 实现了语言的持久化存储和动态切换功能
/// 支持中英文切换，并在应用重启后保持语言设置

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言控制器类
/// 继承自GetxController，用于管理应用的语言状态
/// 主要功能：
/// 1. 管理应用程序的语言设置
/// 2. 持久化存储语言偏好
/// 3. 提供语言切换功能
/// 4. 在应用重启后恢复语言设置
class LocaleController extends GetxController {
  /// SharedPreferences中存储语言设置的键名
  /// 使用静态常量确保键名一致性
  /// 格式：languageCode_countryCode (例如：zh_CN)
  static const String _localeKey = 'app_locale';

  /// SharedPreferences实例的Future
  /// 用于异步获取SharedPreferences实例
  /// 用于持久化存储语言设置
  final _prefs = SharedPreferences.getInstance();

  /// 当前语言设置
  /// 使用Rx使其成为可观察对象
  /// 默认使用中文简体（zh_CN）
  /// 当语言改变时，UI会自动更新
  final Rx<Locale> currentLocale = Rx<Locale>(const Locale('zh', 'CN'));

  /// 控制器初始化方法
  /// 在控制器被创建时自动调用
  /// 负责加载保存的语言设置
  @override
  void onInit() {
    super.onInit();
    // 初始化时加载保存的语言设置
    loadSavedLocale();
  }

  /// 加载保存的语言设置
  /// 从SharedPreferences中读取并应用保存的语言设置
  /// 如果没有保存的设置，则使用默认语言（zh_CN）
  Future<void> loadSavedLocale() async {
    // 获取SharedPreferences实例
    final prefs = await _prefs;
    // 读取保存的语言设置字符串
    final savedLocale = prefs.getString(_localeKey);

    if (savedLocale != null) {
      // 将保存的字符串解析为语言代码和国家代码
      final parts = savedLocale.split('_');
      if (parts.length == 2) {
        // 设置当前语言
        currentLocale.value = Locale(parts[0], parts[1]);
        // 更新GetX的语言设置
        Get.updateLocale(currentLocale.value);
      }
    }
  }

  /// 更改应用语言设置
  /// @param locale 要切换的目标语言
  /// 更新当前语言并保存到SharedPreferences
  Future<void> changeLocale(Locale locale) async {
    // 更新当前语言设置
    currentLocale.value = locale;
    // 更新GetX的语言设置，触发UI更新
    Get.updateLocale(locale);

    // 保存语言设置到SharedPreferences
    final prefs = await _prefs;
    // 将语言设置转换为字符串格式保存
    await prefs.setString(
        _localeKey, '${locale.languageCode}_${locale.countryCode}');
  }

  /// 切换语言方法
  /// 在中文和英文之间切换
  /// 如果当前是英文则切换到中文
  /// 如果当前是中文则切换到英文
  void toggleLocale() {
    if (currentLocale.value.languageCode == 'en') {
      // 当前为英文，切换到中文
      changeLocale(const Locale('zh', 'CN'));
    } else {
      // 当前为中文，切换到英文
      changeLocale(const Locale('en', 'US'));
    }
  }

  /// 判断当前是否为英文
  /// @return bool 当前是否为英文
  /// true表示当前为英文，false表示当前为中文
  bool get isEnglish => currentLocale.value.languageCode == 'en';
}
