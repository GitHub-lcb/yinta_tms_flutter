/// 离线模式数据库服务文件
/// 使用mysql_client包直接与MySQL数据库交互
/// 不依赖后端服务，支持本地数据库操作
/// 提供完整的数据库管理功能

import 'package:get/get.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/connection_config.dart';
import '../../utils/file_utils.dart';
import 'database_service.dart';

/// 离线模式数据库服务类
/// 继承自GetxService以支持依赖注入
/// 实现DatabaseService接口以确保实现所有必要的数据库操作方法
/// 主要功能：
/// 1. 直接数据库连接管理
/// 2. SQL查询执行
/// 3. 数据库和表的元数据获取
/// 4. 数据导出功能
/// 5. 支持Excel和CSV格式导出
class OfflineService extends GetxService implements DatabaseService {
  /// MySQL连接实例
  /// 使用mysql_client包提供的连接对象
  /// 用于直接与MySQL数据库通信
  MySQLConnection? _connection;

  /// 连接状态标志
  /// true表示已连接到数据库
  /// false表示未连接或连接已断开
  bool isConnected = false;

  /// 测试数据库连接方法
  /// 尝试建立临时连接以验证连接参数
  /// 连接成功后立即断开
  ///
  /// @param config 数据库连接配置信息
  /// @return Future<bool> 连接测试结果
  Future<bool> testConnection(ConnectionConfig config) async {
    try {
      // 创建临时连接
      final conn = await MySQLConnection.createConnection(
        host: config.host,
        port: config.port,
        userName: config.user,
        password: config.password,
        databaseName: config.database,
        secure: config.useSSL ?? false,
      );
      // 尝试连接
      await conn.connect();
      // 测试成功后立即断开
      await conn.close();
      return true;
    } catch (e) {
      print('测试连接失败: $e');
      return false;
    }
  }

  /// 连接数据库方法
  /// 建立与数据库的持久连接
  /// 连接成功后更新连接状态
  ///
  /// @param config 数据库连接配置信息
  /// @throws Exception 当连接失败时抛出异常
  Future<void> connect(ConnectionConfig config) async {
    try {
      // 创建数据库连接
      _connection = await MySQLConnection.createConnection(
        host: config.host,
        port: config.port,
        userName: config.user,
        password: config.password,
        databaseName: config.database,
        secure: config.useSSL ?? false,
      );
      // 建立连接
      await _connection!.connect();
      // 更新连接状态
      isConnected = true;
    } catch (e) {
      print('连接数据库失败: $e');
      rethrow;
    }
  }

  /// 断开数据库连接方法
  /// 关闭当前连接并清理连接状态
  /// 即使断开失败也会更新连接状态
  Future<void> disconnect() async {
    // 关闭连接
    await _connection?.close();
    // 清理连接对象
    _connection = null;
    // 更新连接状态
    isConnected = false;
  }

  /// 获取数据库列表方法
  /// 执行SHOW DATABASES命令获取所有数据库
  ///
  /// @return Future<List<String>> 数据库名称列表
  /// @throws Exception 当未连接或执行失败时抛出异常
  Future<List<String>> getDatabases() async {
    // 检查连接状态
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 执行查询
      final results = await _connection!.execute('SHOW DATABASES');
      // 提取数据库名称
      return results.rows.map((row) => row.colAt(0)!).toList();
    } catch (e) {
      print('获取数据库列表失败: $e');
      rethrow;
    }
  }

  /// 获取表列表方法
  /// 支持分页查询表列表
  /// 返回表总数和分页后的表列表
  ///
  /// @param database 数据库名称
  /// @param offset 起始位置（可选）
  /// @param limit 每页数量（可选）
  /// @return Future<Map<String, dynamic>> 包含表总数和表列表的Map
  /// @throws Exception 当未连接或执行失败时抛出异常
  Future<Map<String, dynamic>> getTables(String database,
      {int? offset, int? limit}) async {
    // 检查连接状态
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 切换到指定数据库
      await _connection!.execute('USE `$database`');

      // 获取表总数
      final countResult = await _connection!.execute(
          'SELECT COUNT(*) as total FROM information_schema.tables WHERE table_schema = :db',
          {'db': database});
      final total = int.parse(countResult.rows.first.colAt(0) ?? '0');

      // 构建分页查询
      String query =
          'SELECT table_name FROM information_schema.tables WHERE table_schema = :db';

      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final results = await _connection!.execute(query, {'db': database});
      final tables = results.rows.map((row) => row.colAt(0)!).toList();

      return {
        'total': total,
        'tables': tables,
      };
    } catch (e, stackTrace) {
      print('获取表列表失败:');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      throw Exception('获取表列表失败: ${e.toString()}');
    }
  }

  /// 获取表结构
  Future<List<Map<String, dynamic>>> getTableStructure(
      String database, String table) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.execute('USE `$database`');
      final results =
          await _connection!.execute('SHOW FULL COLUMNS FROM `$table`');

      return results.rows.map((row) {
        return {
          'Field': row.colAt(0) ?? '',
          'Type': row.colAt(1) ?? '',
          'Collation': row.colAt(2),
          'Null': row.colAt(3) ?? '',
          'Key': row.colAt(4) ?? '',
          'Default': row.colAt(5),
          'Extra': row.colAt(6) ?? '',
          'Privileges': row.colAt(7) ?? '',
          'Comment': row.colAt(8) ?? '',
        };
      }).toList();
    } catch (e, stackTrace) {
      print('获取表结构失败:');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      throw Exception('获取表结构失败: ${e.toString()}');
    }
  }

  /// 执行SQL查询
  @override
  Future<Map<String, dynamic>> executeQuery(String database, String sql) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 检查SQL语句中是否已经包含数据库名称
      final hasDatabase = RegExp(r'`[^`]+`\.`[^`]+`').hasMatch(sql);
      if (!hasDatabase) {
        // 如果SQL语句中没有指定数据库，则切换到指定的数据库
        await _connection!.execute('USE `$database`');
      }
      return _executeQueryInternal(sql);
    } catch (e, stackTrace) {
      print('SQL执行失败:');
      print('SQL语句: $sql');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      throw Exception('执行SQL失败: ${e.toString()}');
    }
  }

  /// 内部查询执行方法
  Future<Map<String, dynamic>> _executeQueryInternal(String sql) async {
    final results = await _connection!.execute(sql);

    // 处理DDL语句 (CREATE, ALTER, DROP等)
    final ddlPattern = RegExp(r'^\s*(CREATE|ALTER|DROP|TRUNCATE|RENAME)\s+',
        caseSensitive: false);
    if (ddlPattern.hasMatch(sql)) {
      return {
        'columns': ['Result'],
        'rows': [
          ['Query executed successfully']
        ],
      };
    }

    // 检查是否是 SELECT 查询
    final isSelect =
        RegExp(r'^\s*SELECT\s+', caseSensitive: false).hasMatch(sql);

    // 如果是非SELECT语句，返回影响的行数
    if (!isSelect && results.affectedRows != null) {
      return {
        'columns': ['Affected Rows'],
        'rows': [
          [results.affectedRows]
        ],
      };
    }

    // SELECT语句结果处理
    if (results.rows.isEmpty) {
      return {
        'columns': [],
        'rows': [],
      };
    }

    // 获取所有字段名
    final firstRow = results.rows.first;
    final fields = firstRow.assoc().keys.toList();

    // 过滤掉内部字段（以下划线开头的字段）
    final validFields = fields.where((f) => !f.startsWith('_')).toList();

    // 获取所有行的数据
    final validRows = results.rows.map((row) {
      final rowData = row.assoc();
      return validFields.map((field) => rowData[field]).toList();
    }).toList();

    return {
      'columns': validFields,
      'rows': validRows,
    };
  }

  /// 获取表的索引信息
  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.execute('USE `$database`');
      final results = await _connection!.execute('SHOW INDEX FROM `$table`');

      return results.rows.map((row) {
        return {
          'Table': row.colAt(0) ?? '',
          'Non_unique': row.colAt(1) ?? '',
          'Key_name': row.colAt(2) ?? '',
          'Seq_in_index': row.colAt(3) ?? '',
          'Column_name': row.colAt(4) ?? '',
          'Collation': row.colAt(5) ?? '',
          'Cardinality': row.colAt(6) ?? '',
          'Sub_part': row.colAt(7),
          'Packed': row.colAt(8),
          'Null': row.colAt(9) ?? '',
          'Index_type': row.colAt(10) ?? '',
          'Comment': row.colAt(11) ?? '',
          'Index_comment': row.colAt(12) ?? '',
          'Visible': row.colAt(13) ?? '',
          'Expression': row.colAt(14),
        };
      }).toList();
    } catch (e) {
      throw Exception('获取表索引失败: ${e.toString()}');
    }
  }

  /// 修改表结构
  Future<void> alterTable(String database, String table, String sql) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.execute('USE `$database`');
      await _connection!.execute(sql);
    } catch (e) {
      throw Exception('修改表结构失败: ${e.toString()}');
    }
  }

  /// 导出查询结果为Excel文件
  Future<void> exportToExcel(
    String query,
    String filename, {
    String? mimeType,
  }) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 执行查询获取数据
      final results = await _connection!.execute(query);
      if (results.rows.isEmpty) {
        throw Exception('没有数据可导出');
      }

      // 创建Excel工作簿和工作表
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // 获取字段名并写入表头
      final fields = results.rows.first.assoc().keys.toList();
      for (var i = 0; i < fields.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          ..value = TextCellValue(fields[i])
          ..cellStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
          );
      }

      // 写入数据行
      var rowIndex = 1;
      for (final row in results.rows) {
        for (var i = 0; i < fields.length; i++) {
          sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex))
            ..value = TextCellValue(row.colAt(i)?.toString() ?? '')
            ..cellStyle = CellStyle(
              horizontalAlign: HorizontalAlign.Left,
            );
        }
        rowIndex++;
      }

      // 保存Excel文件
      final fileBytes = excel.encode();
      if (fileBytes == null) throw Exception('生成Excel文件失败');

      await FileUtils.saveOrShareFile(
        fileBytes,
        filename,
        allowedExtensions: ['xlsx'],
        dialogTitle: '选择保存位置',
        mimeType: mimeType,
      );
    } catch (e) {
      throw Exception('导出Excel失败: ${e.toString()}');
    }
  }

  /// 导出查询结果为CSV文件
  Future<void> exportToCsv(
    String query,
    String filename, {
    String? mimeType,
  }) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 执行查询获取数据
      final results = await _connection!.execute(query);
      if (results.rows.isEmpty) {
        throw Exception('没有数据可导出');
      }

      // 获取字段名列表
      final fields = results.rows.first.assoc().keys.toList();

      // 创建CSV字符串
      final csvData = const ListToCsvConverter().convert([
        // 写入表头
        fields,
        // 写入数据行
        ...results.rows.map((row) => fields.map((field) {
              final value = row.assoc()[field];
              return value?.toString() ?? '';
            }).toList()),
      ]);

      await FileUtils.saveOrShareFile(
        csvData.codeUnits,
        filename,
        allowedExtensions: ['csv'],
        dialogTitle: '选择保存位置',
        mimeType: mimeType,
      );
    } catch (e) {
      throw Exception('导出CSV失败: ${e.toString()}');
    }
  }

  /// 获取建表语句方法
  /// 获取指定表的建表语句
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @return Future<String> 建表语句
  /// @throws Exception 当获取失败时抛出异常
  @override
  Future<String> getCreateTableStatement(String database, String table) async {
    // 检查连接状态
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 切换到指定数据库
      await _connection!.execute('USE `$database`');

      // 获取建表语句
      final results = await _connection!.execute('SHOW CREATE TABLE `$table`');
      if (results.rows.isEmpty) {
        throw Exception('无法获取建表语句');
      }

      // 建表语句在第二列
      return results.rows.first.colAt(1) ?? '';
    } catch (e) {
      print('获取建表语句失败: $e');
      rethrow;
    }
  }
}
