/// 主题控制器文件
/// 使用GetX状态管理框架
/// 负责管理应用程序的主题状态
/// 实现了主题的持久化存储和动态切换功能

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题控制器类
/// 继承自GetxController，用于管理应用的主题状态
/// 主要功能：
/// 1. 管理深色/浅色主题模式
/// 2. 持久化存储主题设置
/// 3. 提供主题切换功能
/// 4. 在应用重启后恢复上次的主题设置
class ThemeController extends GetxController {
  /// SharedPreferences中存储主题模式的键名
  /// 使用静态常量确保键名一致性
  static const String _themeKey = 'isDarkMode';

  /// SharedPreferences实例
  /// 用于持久化存储主题设置
  /// 通过依赖注入在构造函数中传入
  final SharedPreferences _prefs;

  /// 深色模式状态
  /// 使用obs使其成为可观察对象
  /// true表示深色模式，false表示浅色模式
  final isDarkMode = false.obs;

  /// 构造函数
  /// @param _prefs SharedPreferences实例，用于读写主题设置
  /// 在创建控制器实例时自动加载保存的主题设置
  ThemeController(this._prefs) {
    _loadThemeMode();
  }

  /// 加载主题模式
  /// 从SharedPreferences中读取保存的主题设置
  /// 如果没有保存的设置，默认使用浅色模式
  void _loadThemeMode() {
    // 读取保存的主题设置，如果不存在则默认为false（浅色模式）
    isDarkMode.value = _prefs.getBool(_themeKey) ?? false;
  }

  /// 切换主题模式
  /// 在深色和浅色主题之间切换
  /// 切换后自动保存设置到SharedPreferences
  void toggleTheme() {
    // 反转当前的主题模式
    isDarkMode.value = !isDarkMode.value;
    // 保存新的主题设置
    _prefs.setBool(_themeKey, isDarkMode.value);
  }

  /// 获取当前主题模式
  /// 返回Flutter的ThemeMode枚举值
  /// 用于在MaterialApp中设置主题
  /// @return ThemeMode 当前的主题模式
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
