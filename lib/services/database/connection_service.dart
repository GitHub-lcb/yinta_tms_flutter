import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/connection_config.dart';

/// 数据库连接配置服务类
/// 负责管理数据库连接配置的保存、加载和测试
class ConnectionService {
  /// SharedPreferences的键名
  static const String _connectionsKey = 'saved_connections';

  /// 保存的连接配置列表
  List<ConnectionConfig> _savedConnections = [];

  /// 获取已保存的连接配置列表
  List<ConnectionConfig> get savedConnections => _savedConnections;

  /// 初始化服务
  /// 从SharedPreferences加载保存的连接配置
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getStringList(_connectionsKey) ?? [];
    _savedConnections = savedJson
        .map((json) => ConnectionConfig.fromJson(jsonDecode(json)))
        .toList();
  }

  /// 保存连接配置
  ///
  /// 参数:
  /// - [config]: 要保存的连接配置
  Future<void> saveConnection(ConnectionConfig config) async {
    // 检查是否已存在同名配置
    final existingIndex =
        _savedConnections.indexWhere((c) => c.name == config.name);

    if (existingIndex != -1) {
      // 更新现有配置
      _savedConnections[existingIndex] = config;
    } else {
      // 添加新配置
      _savedConnections.add(config);
    }

    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _savedConnections.map((config) => jsonEncode(config.toJson())).toList();
    await prefs.setStringList(_connectionsKey, jsonList);
  }

  /// 删除连接配置
  ///
  /// 参数:
  /// - [name]: 要删除的配置名称
  Future<void> deleteConnection(String name) async {
    _savedConnections.removeWhere((config) => config.name == name);

    // 保存到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _savedConnections.map((config) => jsonEncode(config.toJson())).toList();
    await prefs.setStringList(_connectionsKey, jsonList);
  }

  /// 获取连接配置
  ///
  /// 参数:
  /// - [name]: 配置名称
  ///
  /// 返回:
  /// 找到的连接配置，如果不存在则返回null
  ConnectionConfig? getConnection(String name) {
    return _savedConnections.firstWhere(
      (config) => config.name == name,
      orElse: () => throw Exception('Connection not found: $name'),
    );
  }
}
