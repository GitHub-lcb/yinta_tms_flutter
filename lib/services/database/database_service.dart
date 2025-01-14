import 'package:flutter/foundation.dart';
import '../../models/connection_config.dart';

/// 数据库服务接口
/// 定义了数据库服务的基本操作方法
@immutable
abstract class DatabaseService {
  /// 执行SQL查询
  ///
  /// 参数:
  /// - [database]: 数据库名称
  /// - [query]: SQL查询语句
  ///
  /// 返回:
  /// 包含查询结果的Map对象
  Future<Map<String, dynamic>> executeQuery(String database, String query);

  /// 测试数据库连接
  Future<bool> testConnection(ConnectionConfig config);

  /// 连接到数据库
  Future<void> connect(ConnectionConfig config);

  /// 断开数据库连接
  Future<void> disconnect();

  /// 获取数据库列表
  Future<List<String>> getDatabases();

  /// 获取指定数据库中的表列表
  Future<List<String>> getTables(String database);

  /// 获取指定表的结构信息
  Future<List<Map<String, dynamic>>> getTableStructure(
      String database, String table);

  /// 获取指定表的索引信息
  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table);

  /// 修改表结构
  Future<void> alterTable(String database, String table, String sql);

  /// 导出查询结果为Excel文件
  Future<void> exportToExcel(String query, String filename);

  /// 导出查询结果为CSV文件
  Future<void> exportToCsv(String query, String filename);
}
