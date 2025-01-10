import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/query_history.dart';
import '../../services/database/mysql_service.dart';
import '../../services/query/query_history_service.dart';
import '../../widgets/sql_editor.dart';

/// 数据表列表控制器
/// 负责管理数据表列表界面的状态和业务逻辑，包括加载表列表、查看表数据、执行SQL查询等功能
class TableController extends GetxController {
  /// MySQL服务实例
  final _mysqlService = Get.find<MySqlService>();

  /// 数据表列表
  final tables = <String>[].obs;

  /// 所有表的列名列表（用于SQL编辑器自动完成）
  final columns = <String>[].obs;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  /// 当前选中的数据库名称
  late final String databaseName;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据库名称
    databaseName = Get.arguments as String;
    loadTables();
  }

  /// 加载数据表列表
  /// 获取当前数据库中的所有表，并加载每个表的列信息用于SQL编辑器的自动完成功能
  Future<void> loadTables() async {
    isLoading.value = true;
    error.value = '';

    try {
      // 获取表列表
      final result = await _mysqlService.getTables(databaseName);
      tables.value = result;

      // 加载所有表的列信息
      columns.clear();
      for (final table in tables) {
        try {
          final structure =
              await _mysqlService.getTableStructure(databaseName, table);
          columns.addAll(structure
              .map((col) => col['Field'] as String? ?? '')
              .where((col) => col.isNotEmpty));
        } catch (e) {
          print('Error loading columns for table $table: $e');
        }
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 选择数据表
  /// TODO: 实现表选择功能
  Future<void> selectTable(String table) async {
    // TODO: Implement table selection
  }

  /// 查看表数据
  /// 导航到表数据页面，显示选中表的数据内容
  ///
  /// 参数:
  /// - [table]: 要查看的表名
  Future<void> viewTableData(String table) async {
    Get.toNamed('/table-data', arguments: {
      'database': databaseName,
      'table': table,
    });
  }

  /// 编辑表结构
  /// 导航到表结构页面，用于查看和修改表结构
  ///
  /// 参数:
  /// - [table]: 要编辑的表名
  Future<void> editTable(String table) async {
    Get.toNamed('/table-structure', arguments: {
      'database': databaseName,
      'table': table,
    });
  }

  /// 显示SQL查询对话框
  /// 打开一个包含SQL编辑器的对话框，用于执行自定义SQL查询
  Future<void> showQueryDialog() async {
    final queryController = TextEditingController();
    String query = '';

    // 显示SQL编辑器对话框
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('执行 SQL 查询 / Execute SQL Query'),
        content: SizedBox(
          width: 800,
          height: 400,
          child: SqlEditor(
            onChanged: (value) => query = value,
            onExecute: () => Get.back(result: true),
            tables: tables,
            columns: columns,
          ),
        ),
      ),
    );

    // 如果用户点击了执行按钮
    if (result == true) {
      try {
        // 执行SQL查询
        final queryResult = await _mysqlService.executeQuery(query);
        final historyService = Get.find<QueryHistoryService>();
        // 添加成功的查询记录到历史
        await historyService.addQuery(
          QueryHistory(
            query: query,
            timestamp: DateTime.now(),
            database: databaseName,
            isSuccess: true,
            rowsAffected: queryResult.length,
          ),
        );
        // 导航到查询结果页面
        Get.toNamed('/query-result', arguments: {
          'query': query,
          'data': queryResult,
        });
      } catch (e) {
        final historyService = Get.find<QueryHistoryService>();
        // 添加失败的查询记录到历史
        await historyService.addQuery(
          QueryHistory(
            query: query,
            timestamp: DateTime.now(),
            database: databaseName,
            isSuccess: false,
            rowsAffected: 0,
          ),
        );
        error.value = e.toString();
      }
    }
  }
}
