/// 查询历史服务文件
/// 提供SQL查询历史记录的管理和持久化功能
/// 使用SharedPreferences进行本地存储
/// 主要功能：
/// 1. 查询历史的添加和获取
/// 2. 历史记录的持久化存储
/// 3. 历史记录的搜索功能
/// 4. 历史记录数量限制管理

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/query_history.dart';

/// SQL查询历史记录服务类
/// 负责管理和持久化存储SQL查询历史记录
/// 提供查询历史的CRUD操作
/// 实现了历史记录的自动清理和搜索功能
class QueryHistoryService {
  /// 存储查询历史的SharedPreferences键名
  /// 用于在本地存储中唯一标识查询历史数据
  /// 格式：'query_history'
  static const String _storageKey = 'query_history';

  /// 最大保存的历史记录数量
  /// 超过此数量的旧记录会被自动删除
  /// 用于防止历史记录占用过多存储空间
  static const int _maxHistoryItems = 100;

  /// SharedPreferences实例
  /// 用于实现查询历史的本地持久化存储
  /// 通过依赖注入在构造函数中传入
  final SharedPreferences _prefs;

  /// 构造函数
  /// 创建查询历史服务实例
  ///
  /// @param _prefs SharedPreferences实例，用于本地数据持久化
  /// 通过依赖注入方式提供SharedPreferences实例
  QueryHistoryService(this._prefs);

  /// 添加查询历史记录方法
  /// 将新的查询记录添加到历史列表的开头
  /// 同时确保历史记录数量不超过限制
  /// 实现了自动清理过期记录的功能
  ///
  /// @param query 要添加的查询历史记录对象
  /// @throws Exception 当存储操作失败时抛出异常
  Future<void> addQuery(QueryHistory query) async {
    // 获取现有的查询历史记录
    final histories = await getQueries();
    // 将新记录插入到列表开头
    histories.insert(0, query);

    // 限制历史记录数量
    // 只保留最近的_maxHistoryItems条记录
    if (histories.length > _maxHistoryItems) {
      histories.removeRange(_maxHistoryItems, histories.length);
    }

    // 序列化并保存到本地存储
    final jsonList = histories.map((h) => h.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// 获取查询历史记录方法
  /// 从本地存储中读取所有查询历史
  /// 将JSON数据反序列化为QueryHistory对象
  /// 如果没有历史记录，返回空列表
  ///
  /// @return Future<List<QueryHistory>> 查询历史记录列表
  /// @throws Exception 当读取或解析数据失败时抛出异常
  Future<List<QueryHistory>> getQueries() async {
    // 从本地存储读取JSON字符串
    final jsonString = _prefs.getString(_storageKey);
    // 如果没有数据，返回空列表
    if (jsonString == null) return [];

    // 解析JSON数据并转换为QueryHistory对象列表
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => QueryHistory.fromJson(json)).toList();
  }

  /// 清空查询历史方法
  /// 删除本地存储中的所有查询历史记录
  /// 操作不可撤销，请谨慎使用
  ///
  /// @throws Exception 当删除操作失败时抛出异常
  Future<void> clearHistory() async {
    // 从本地存储中移除查询历史数据
    await _prefs.remove(_storageKey);
  }

  /// 搜索查询历史方法
  /// 支持在查询语句和数据库名称中进行模糊搜索
  /// 搜索不区分大小写
  /// 空关键字将返回所有历史记录
  ///
  /// @param keyword 搜索关键字
  /// @return Future<List<QueryHistory>> 匹配的查询历史记录列表
  /// @throws Exception 当搜索操作失败时抛出异常
  Future<List<QueryHistory>> searchHistory(String keyword) async {
    // 获取所有查询历史记录
    final histories = await getQueries();
    // 如果关键字为空，返回所有记录
    if (keyword.isEmpty) return histories;

    // 执行模糊搜索
    // 在查询语句和数据库名称中查找匹配项
    return histories
        .where((h) =>
            h.query.toLowerCase().contains(keyword.toLowerCase()) ||
            h.database.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}
