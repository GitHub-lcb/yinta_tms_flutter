import 'package:get/get.dart';
import 'package:mysql1/mysql1.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../models/connection_config.dart';
import 'database_service.dart';

/// 离线模式数据库服务类
/// 负责在离线模式下直接与MySQL数据库交互，不通过后端服务
class OfflineService extends GetxService implements DatabaseService {
  MySqlConnection? _connection;
  bool isConnected = false;

  /// 测试连接
  Future<bool> testConnection(ConnectionConfig config) async {
    try {
      final settings = ConnectionSettings(
        host: config.host,
        port: config.port,
        user: config.user,
        password: config.password,
        db: config.database,
      );
      final testConn = await MySqlConnection.connect(settings);
      await testConn.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 连接数据库
  Future<void> connect(ConnectionConfig config) async {
    final settings = ConnectionSettings(
      host: config.host,
      port: config.port,
      user: config.user,
      password: config.password,
      db: config.database,
    );
    _connection = await MySqlConnection.connect(settings);
    isConnected = true;
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    isConnected = false;
  }

  /// 获取数据库列表
  Future<List<String>> getDatabases() async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    final results = await _connection!.query('SHOW DATABASES');
    return results.map((row) => row[0] as String).toList();
  }

  /// 获取表列表
  Future<List<String>> getTables(String database) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    await _connection!.query('USE `$database`');
    final results = await _connection!.query('SHOW TABLES');
    return results.map((row) => row[0] as String).toList();
  }

  /// 获取表结构
  Future<List<Map<String, dynamic>>> getTableStructure(
      String database, String table) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.query('USE `$database`');
      final results =
          await _connection!.query('SHOW FULL COLUMNS FROM `$table`');

      return results.map((row) {
        final values = row.values?.toList() ?? [];
        if (values.length < 9) {
          // 如果返回的列数不足，使用默认值填充
          return {
            'Field': values.isNotEmpty ? values[0]?.toString() ?? '' : '',
            'Type': values.length > 1 ? values[1]?.toString() ?? '' : '',
            'Collation': values.length > 2 ? values[2]?.toString() ?? '' : null,
            'Null': values.length > 3 ? values[3]?.toString() ?? '' : '',
            'Key': values.length > 4 ? values[4]?.toString() ?? '' : '',
            'Default': values.length > 5 ? values[5]?.toString() : null,
            'Extra': values.length > 6 ? values[6]?.toString() ?? '' : '',
            'Privileges': values.length > 7 ? values[7]?.toString() ?? '' : '',
            'Comment': values.length > 8 ? values[8]?.toString() ?? '' : '',
          };
        }

        return {
          'Field': values[0]?.toString() ?? '',
          'Type': values[1]?.toString() ?? '',
          'Collation': values[2]?.toString(),
          'Null': values[3]?.toString() ?? '',
          'Key': values[4]?.toString() ?? '',
          'Default': values[5]?.toString(),
          'Extra': values[6]?.toString() ?? '',
          'Privileges': values[7]?.toString() ?? '',
          'Comment': values[8]?.toString() ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('获取表结构失败: ${e.toString()}');
    }
  }

  /// 执行SQL查询
  Future<Map<String, dynamic>> executeQuery(String database, String sql) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.query('USE `$database`');

      // 处理DDL语句 (CREATE, ALTER, DROP等)
      final ddlPattern = RegExp(r'^\s*(CREATE|ALTER|DROP|TRUNCATE|RENAME)\s+',
          caseSensitive: false);
      if (ddlPattern.hasMatch(sql)) {
        await _connection!.query(sql);
        return {
          'columns': ['Result'],
          'rows': [
            ['Query executed successfully']
          ],
        };
      }

      // 处理DML语句 (SELECT, INSERT, UPDATE, DELETE等)
      final results = await _connection!.query(sql);

      // 如果是非SELECT语句，返回影响的行数
      if (results.affectedRows != null) {
        return {
          'columns': ['Affected Rows'],
          'rows': [
            [results.affectedRows]
          ],
        };
      }

      // SELECT语句结果处理
      if (results.isEmpty) {
        return {
          'columns': [],
          'rows': [],
        };
      }

      // 获取所有字段名
      final allFields = results.fields.map((f) => f.name).toList();

      // 过滤掉内部字段（以下划线开头的字段）
      final validFieldIndices = <int>[];
      final validFields = <String>[];

      for (var i = 0; i < allFields.length; i++) {
        final fieldName = allFields[i];
        if (fieldName != null && !fieldName.startsWith('_')) {
          validFieldIndices.add(i);
          validFields.add(fieldName);
        }
      }

      // 只保留有效字段的数据
      final validRows = results.map((row) {
        final List? values = row.values?.toList();
        return validFieldIndices.map((index) => values?[index]).toList();
      }).toList();

      return {
        'columns': validFields,
        'rows': validRows,
      };
    } catch (e) {
      throw Exception('执行SQL失败: ${e.toString()}');
    }
  }

  /// 获取表的索引信息
  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      await _connection!.query('USE `$database`');
      final results = await _connection!.query('SHOW INDEX FROM `$table`');

      return results.map((row) {
        final values = row.values?.toList() ?? [];
        return {
          'Table': values.isNotEmpty ? values[0]?.toString() ?? '' : '',
          'Non_unique': values.length > 1 ? values[1]?.toString() ?? '' : '',
          'Key_name': values.length > 2 ? values[2]?.toString() ?? '' : '',
          'Seq_in_index': values.length > 3 ? values[3]?.toString() ?? '' : '',
          'Column_name': values.length > 4 ? values[4]?.toString() ?? '' : '',
          'Collation': values.length > 5 ? values[5]?.toString() ?? '' : '',
          'Cardinality': values.length > 6 ? values[6]?.toString() ?? '' : '',
          'Sub_part': values.length > 7 ? values[7]?.toString() : null,
          'Packed': values.length > 8 ? values[8]?.toString() : null,
          'Null': values.length > 9 ? values[9]?.toString() ?? '' : '',
          'Index_type': values.length > 10 ? values[10]?.toString() ?? '' : '',
          'Comment': values.length > 11 ? values[11]?.toString() ?? '' : '',
          'Index_comment':
              values.length > 12 ? values[12]?.toString() ?? '' : '',
          'Visible': values.length > 13 ? values[13]?.toString() ?? '' : '',
          'Expression': values.length > 14 ? values[14]?.toString() : null,
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
      await _connection!.query('USE `$database`');
      await _connection!.query(sql);
    } catch (e) {
      throw Exception('修改表结构失败: ${e.toString()}');
    }
  }

  /// 导出查询结果为Excel文件
  Future<void> exportToExcel(String query, String filename) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 执行查询获取数据
      final results = await _connection!.query(query);
      if (results.isEmpty) {
        throw Exception('没有数据可导出');
      }

      // 创建Excel工作簿和工作表
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // 写入表头
      final fields = results.fields.map((f) => f.name).toList();
      for (var i = 0; i < fields.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(fields[i] ?? '');
        cell.cellStyle = CellStyle(bold: true);
      }

      // 写入数据行
      for (var i = 0; i < results.length; i++) {
        final row = results.elementAt(i);
        for (var j = 0; j < fields.length; j++) {
          final value = row[j];
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = TextCellValue(value?.toString() ?? '');
        }
      }

      // 自动调整列宽
      for (var i = 0; i < fields.length; i++) {
        sheet.setColumnAutoFit(i);
      }

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsBytes(excel.encode()!);

      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        // 在移动设备上使用分享功能
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: '导出数据',
        );
      } else {
        // 在桌面平台上使用文件选择器
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['xlsx'],
        );

        if (outputFile == null) {
          // 用户取消了选择
          return;
        }

        // 保存文件
        final file = File(outputFile);
        await file.writeAsBytes(excel.encode()!);

        // 显示成功提示
        Get.snackbar(
          '导出成功',
          '文件已保存到: $outputFile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      throw Exception('导出Excel失败: ${e.toString()}');
    }
  }

  /// 导出查询结果为CSV文件
  Future<void> exportToCsv(String query, String filename) async {
    if (!isConnected || _connection == null) throw Exception('未连接到数据库');

    try {
      // 执行查询获取数据
      final results = await _connection!.query(query);
      if (results.isEmpty) {
        throw Exception('没有数据可导出');
      }

      // 获取字段名列表
      final fields = results.fields.map((f) => f.name).toList();

      // 创建CSV字符串
      final csvData = const ListToCsvConverter().convert([
        // 写入表头
        fields,
        // 写入数据行
        ...results.map((row) => fields.map((field) {
              final value = row[fields.indexOf(field)];
              return value?.toString() ?? '';
            }).toList()),
      ]);

      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$filename');
      await tempFile.writeAsString(csvData);

      if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
        // 在移动设备上使用分享功能
        await Share.shareXFiles(
          [XFile(tempFile.path)],
          subject: '导出数据',
        );
      } else {
        // 在桌面平台上使用文件选择器
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '选择保存位置',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['csv'],
        );

        if (outputFile == null) {
          // 用户取消了选择
          return;
        }

        // 保存文件
        final file = File(outputFile);
        await file.writeAsString(csvData);

        // 显示成功提示
        Get.snackbar(
          '导出成功',
          '文件已保存到: $outputFile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      throw Exception('导出CSV失败: ${e.toString()}');
    }
  }
}
