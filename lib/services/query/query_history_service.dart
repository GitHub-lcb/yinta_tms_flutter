import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/query_history.dart';

/// SQL查询历史记录服务类
/// 负责管理和持久化存储SQL查询历史记录
class QueryHistoryService {
  /// 存储查询历史的SharedPreferences键名
  static const String _storageKey = 'query_history';

  /// 最大保存的历史记录数量
  static const int _maxHistoryItems = 100;

  /// SharedPreferences实例，用于本地数据持久化
  final SharedPreferences _prefs;

  /// 构造函数
  ///
  /// 参数:
  /// - [_prefs]: SharedPreferences实例，用于数据持久化
  QueryHistoryService(this._prefs);

  /// 添加新的查询历史记录
  /// 将新记录插入到列表开头，并确保列表不超过最大限制
  ///
  /// 参数:
  /// - [query]: 要添加的查询历史记录
  Future<void> addQuery(QueryHistory query) async {
    final histories = await getQueries();
    histories.insert(0, query);

    // 只保留最近的_maxHistoryItems条记录
    if (histories.length > _maxHistoryItems) {
      histories.removeRange(_maxHistoryItems, histories.length);
    }

    final jsonList = histories.map((h) => h.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  /// 获取所有查询历史记录
  /// 从本地存储中读取并反序列化查询历史数据
  ///
  /// 返回:
  /// 查询历史记录列表，如果没有记录则返回空列表
  Future<List<QueryHistory>> getQueries() async {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => QueryHistory.fromJson(json)).toList();
  }

  /// 清空所有查询历史记录
  /// 从本地存储中删除所有查询历史数据
  Future<void> clearHistory() async {
    await _prefs.remove(_storageKey);
  }

  /// 搜索查询历史记录
  /// 根据关键字在查询语句和数据库名称中进行模糊搜索
  ///
  /// 参数:
  /// - [keyword]: 搜索关键字
  ///
  /// 返回:
  /// 匹配关键字的查询历史记录列表
  Future<List<QueryHistory>> searchHistory(String keyword) async {
    final histories = await getQueries();
    if (keyword.isEmpty) return histories;

    return histories
        .where((h) =>
            h.query.toLowerCase().contains(keyword.toLowerCase()) ||
            h.database.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}
