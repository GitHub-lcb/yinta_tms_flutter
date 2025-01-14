import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/query_history.dart';
import '../../services/database/mysql_service.dart';
import '../../services/database/offline_service.dart';
import '../../services/query/query_history_service.dart';
import '../../widgets/sql_editor.dart';

/// 数据表列表控制器
/// 负责管理数据表列表界面的状态和业务逻辑，包括加载表列表、查看表数据、执行SQL查询等功能
class TableController extends GetxController {
  /// MySQL服务实例
  final _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  final _offlineService = Get.find<OfflineService>();

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

  /// 获取当前服务实例
  dynamic get _currentService =>
      _offlineService.isConnected ? _offlineService : _mysqlService as dynamic;

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
      final service = _offlineService.isConnected
          ? _offlineService
          : _mysqlService as dynamic;
      final result = await service.getTables(databaseName);
      tables.value = result;

      // 加载所有表的列信息
      columns.clear();
      for (final table in tables) {
        try {
          final structure =
              await service.getTableStructure(databaseName, table);
          columns.addAll(
            structure
                .map((col) => '$table.${col['Field']?.toString() ?? ''}')
                .where((col) => col.isNotEmpty && col.contains('.'))
                .cast<String>()
                .toList(),
          );
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
    Get.toNamed('/query', arguments: {
      'database': databaseName,
    });
  }
}
