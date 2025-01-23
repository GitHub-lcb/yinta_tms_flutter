/// 数据库服务接口文件
/// 定义了应用程序中数据库操作的标准接口
/// 所有具体的数据库服务实现都必须遵循此接口
/// 支持在线和离线两种模式的数据库操作

import 'package:flutter/foundation.dart';
import '../../models/connection_config.dart';

/// 数据库服务接口类
/// 定义了数据库服务的所有必要操作方法
/// 使用@immutable注解标记为不可变类
/// 主要功能：
/// 1. 数据库连接管理
/// 2. SQL查询执行
/// 3. 数据库结构操作
/// 4. 数据导出功能
@immutable
abstract class DatabaseService {
  /// 执行SQL查询方法
  /// 支持所有类型的SQL语句
  /// 包括SELECT、INSERT、UPDATE、DELETE等
  ///
  /// @param database 要操作的数据库名称
  /// @param query 要执行的SQL查询语句
  /// @return Future<Map<String, dynamic>> 包含查询结果的Map对象
  /// @throws Exception 当SQL执行失败时抛出异常
  Future<Map<String, dynamic>> executeQuery(String database, String query);

  /// 测试数据库连接方法
  /// 用于验证连接参数的正确性
  /// 不建立持久连接
  ///
  /// @param config 数据库连接配置信息
  /// @return Future<bool> 连接测试结果
  Future<bool> testConnection(ConnectionConfig config);

  /// 连接数据库方法
  /// 建立与数据库的持久连接
  ///
  /// @param config 数据库连接配置信息
  /// @throws Exception 当连接失败时抛出异常
  Future<void> connect(ConnectionConfig config);

  /// 断开数据库连接方法
  /// 关闭当前的数据库连接
  ///
  /// @throws Exception 当断开连接失败时抛出异常
  Future<void> disconnect();

  /// 获取数据库列表方法
  /// 获取当前用户有权限访问的所有数据库
  ///
  /// @return Future<List<String>> 数据库名称列表
  /// @throws Exception 当获取失败时抛出异常
  Future<List<String>> getDatabases();

  /// 获取表列表方法
  /// 获取指定数据库中的所有表
  /// 支持分页查询
  ///
  /// @param database 数据库名称
  /// @param offset 起始位置（可选）
  /// @param limit 每页数量（可选）
  /// @return Future<Map<String, dynamic>> 包含表列表和总数的Map对象
  /// @throws Exception 当获取失败时抛出异常
  Future<Map<String, dynamic>> getTables(String database,
      {int? offset, int? limit});

  /// 获取表结构信息方法
  /// 获取指定表的列信息
  /// 包括列名、数据类型、约束等
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @return Future<List<Map<String, dynamic>>> 表结构信息列表
  /// @throws Exception 当获取失败时抛出异常
  Future<List<Map<String, dynamic>>> getTableStructure(
      String database, String table);

  /// 获取表索引信息方法
  /// 获取指定表的所有索引
  /// 包括主键、唯一索引、普通索引等
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @return Future<List<Map<String, dynamic>>> 索引信息列表
  /// @throws Exception 当获取失败时抛出异常
  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table);

  /// 修改表结构方法
  /// 执行ALTER TABLE语句修改表结构
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @param sql ALTER TABLE语句
  /// @throws Exception 当修改失败时抛出异常
  Future<void> alterTable(String database, String table, String sql);

  /// 导出Excel方法
  /// 将查询结果导出为Excel文件
  ///
  /// @param query 要导出的查询语句
  /// @param filename 导出文件名
  /// @param mimeType 文件MIME类型（可选）
  /// @throws Exception 当导出失败时抛出异常
  Future<void> exportToExcel(
    String query,
    String filename, {
    String? mimeType,
  });

  /// 导出CSV方法
  /// 将查询结果导出为CSV文件
  ///
  /// @param query 要导出的查询语句
  /// @param filename 导出文件名
  /// @param mimeType 文件MIME类型（可选）
  /// @throws Exception 当导出失败时抛出异常
  Future<void> exportToCsv(
    String query,
    String filename, {
    String? mimeType,
  });

  /// 获取建表语句方法
  /// 获取指定表的建表语句
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @return Future<String> 建表语句
  /// @throws Exception 当获取失败时抛出异常
  Future<String> getCreateTableStatement(String database, String table);
}
