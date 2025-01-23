/// 数据库连接配置服务文件
/// 使用SharedPreferences持久化存储连接配置
/// 提供连接配置的CRUD操作
/// 支持多个命名连接配置的管理

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/connection_config.dart';

/// 数据库连接配置服务类
/// 负责管理数据库连接配置的持久化存储和操作
/// 主要功能：
/// 1. 保存和加载连接配置
/// 2. 管理多个命名连接配置
/// 3. 提供配置的增删改查操作
/// 4. 使用SharedPreferences实现持久化
class ConnectionService {
  /// SharedPreferences的键名
  /// 用于存储所有连接配置的JSON字符串列表
  /// 固定值，确保数据的一致性
  static const String _connectionsKey = 'saved_connections';

  /// 保存的连接配置列表
  /// 内存中的配置缓存
  /// 避免频繁读取SharedPreferences
  List<ConnectionConfig> _savedConnections = [];

  /// 获取已保存的连接配置列表
  /// 只读属性，返回内存中的配置列表
  /// 用于UI显示和配置选择
  List<ConnectionConfig> get savedConnections => _savedConnections;

  /// 初始化服务方法
  /// 在服务创建时调用
  /// 从SharedPreferences加载所有保存的连接配置
  ///
  /// @throws Exception 当读取或解析配置失败时抛出异常
  Future<void> init() async {
    // 获取SharedPreferences实例
    final prefs = await SharedPreferences.getInstance();
    // 读取保存的JSON字符串列表
    final savedJson = prefs.getStringList(_connectionsKey) ?? [];
    // 解析JSON并转换为ConnectionConfig对象
    _savedConnections = savedJson
        .map((json) => ConnectionConfig.fromJson(jsonDecode(json)))
        .toList();
  }

  /// 保存连接配置方法
  /// 支持新增和更新操作
  /// 使用配置名称作为唯一标识
  ///
  /// @param config 要保存的连接配置
  /// @throws Exception 当保存到SharedPreferences失败时抛出异常
  Future<void> saveConnection(ConnectionConfig config) async {
    // 检查是否存在同名配置
    final existingIndex =
        _savedConnections.indexWhere((c) => c.name == config.name);

    if (existingIndex != -1) {
      // 更新已存在的配置
      _savedConnections[existingIndex] = config;
    } else {
      // 添加新配置
      _savedConnections.add(config);
    }

    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // 将配置列表转换为JSON字符串列表
    final jsonList =
        _savedConnections.map((config) => jsonEncode(config.toJson())).toList();
    // 写入SharedPreferences
    await prefs.setStringList(_connectionsKey, jsonList);
  }

  /// 删除连接配置方法
  /// 根据配置名称删除指定配置
  /// 同时更新内存缓存和持久化存储
  ///
  /// @param name 要删除的配置名称
  /// @throws Exception 当保存到SharedPreferences失败时抛出异常
  Future<void> deleteConnection(String name) async {
    // 从内存中移除配置
    _savedConnections.removeWhere((config) => config.name == name);

    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    // 将更新后的配置列表转换为JSON字符串列表
    final jsonList =
        _savedConnections.map((config) => jsonEncode(config.toJson())).toList();
    // 写入SharedPreferences
    await prefs.setStringList(_connectionsKey, jsonList);
  }

  /// 获取连接配置方法
  /// 根据配置名称查找配置
  /// 如果不存在则抛出异常
  ///
  /// @param name 配置名称
  /// @return ConnectionConfig 找到的连接配置
  /// @throws Exception 当配置不存在时抛出异常
  ConnectionConfig? getConnection(String name) {
    return _savedConnections.firstWhere(
      (config) => config.name == name,
      orElse: () => throw Exception('Connection not found: $name'),
    );
  }
}
