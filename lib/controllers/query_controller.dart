import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../services/database/database_service.dart';
import '../services/query/query_history_service.dart';
import '../models/query_history.dart';

class QueryResult {
  final String sql;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isSuccess;
  final String? error;

  QueryResult({
    required this.sql,
    required this.data,
    required this.timestamp,
    required this.isSuccess,
    this.error,
  });
}

class QueryController extends GetxController {
  final MySqlService _mysqlService = Get.find<MySqlService>();
  final OfflineService _offlineService = Get.find<OfflineService>();
  final _historyService = Get.find<QueryHistoryService>();

  final queryResults = <QueryResult>[].obs;
  final currentQuery = ''.obs;
  final tables = <String>[].obs;
  final columns = <String>[].obs;
  final selectedTabIndex = 0.obs;

  /// 水平滚动控制器
  final horizontalScrollController = ScrollController();

  /// 拖动起始位置
  double? _dragStartX;

  /// 拖动起始滚动位置
  double? _dragStartScroll;

  /// 获取当前数据库名称
  late final String databaseName;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据库名称
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      databaseName = args['database'] ?? '';
    } else {
      databaseName = '';
    }
    loadTables();
  }

  @override
  void onClose() {
    horizontalScrollController.dispose();
    super.onClose();
  }

  /// 开始水平拖动
  void startHorizontalDrag(double x) {
    _dragStartX = x;
    _dragStartScroll = horizontalScrollController.offset;
  }

  /// 更新水平拖动
  void updateHorizontalDrag(double x) {
    if (_dragStartX != null && _dragStartScroll != null) {
      final delta = _dragStartX! - x;
      horizontalScrollController.jumpTo(
        (_dragStartScroll! + delta).clamp(
          0.0,
          horizontalScrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  /// 结束水平拖动
  void endHorizontalDrag() {
    _dragStartX = null;
    _dragStartScroll = null;
  }

  /// 加载当前数据库的表列表
  Future<void> loadTables() async {
    try {
      final DatabaseService service =
          _offlineService.isConnected ? _offlineService : _mysqlService;
      final tableList = await service.getTables(databaseName);
      tables.value = tableList;

      // 加载所有表的列信息用于自动完成
      columns.clear();
      for (final table in tables) {
        try {
          final structure =
              await service.getTableStructure(databaseName, table);

          // 过滤掉内部字段
          final validColumns = structure.where((col) {
            final fieldName = col['Field']?.toString() ?? '';
            return !fieldName.startsWith('_');
          }).toList();

          columns.addAll(
            validColumns
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
      Get.snackbar(
        '加载失败 / Load Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// SQL查询变化时的回调
  void onQueryChanged(String query) {
    currentQuery.value = query;
  }

  /// 过滤查询结果中的内部字段
  Map<String, dynamic> _filterInternalFields(Map<String, dynamic> result) {
    if (!result.containsKey('columns') || !result.containsKey('rows')) {
      return result;
    }

    final columns = result['columns'] as List;
    final rows = result['rows'] as List;

    // 如果是DDL语句的结果，直接返回
    if (columns.length == 1 && columns[0] == 'Affected Rows') {
      return result;
    }

    // 找出需要保留的列的索引
    final validColumnIndices = <int>[];
    final validColumns = <String>[];

    for (var i = 0; i < columns.length; i++) {
      final column = columns[i].toString();
      if (!column.startsWith('_')) {
        validColumnIndices.add(i);
        validColumns.add(column);
      }
    }

    // 只保留有效的列的数据
    final validRows = rows.map((row) {
      final List originalRow = row as List;
      return validColumnIndices.map((index) => originalRow[index]).toList();
    }).toList();

    return {
      'columns': validColumns,
      'rows': validRows,
    };
  }

  /// 执行SQL查询
  Future<void> executeQuery() async {
    if (currentQuery.value.isEmpty) {
      Get.snackbar(
        '错误 / Error',
        'SQL查询不能为空 / SQL query cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    // 分割多条SQL语句
    final queries = currentQuery.value
        .split(';')
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    // 清空之前的结果
    queryResults.clear();
    selectedTabIndex.value = 0;

    // 执行每条SQL语句
    for (final sql in queries) {
      try {
        final DatabaseService service =
            _offlineService.isConnected ? _offlineService : _mysqlService;
        final result = await service.executeQuery(databaseName, sql);

        // 过滤内部字段
        final filteredResult = _filterInternalFields(result);

        // 添加到结果列表
        queryResults.add(QueryResult(
          sql: sql,
          data: filteredResult,
          timestamp: DateTime.now(),
          isSuccess: true,
        ));

        // 添加到查询历史
        await _historyService.addQuery(
          QueryHistory(
            query: sql,
            timestamp: DateTime.now(),
            database: databaseName,
            isSuccess: true,
            rowsAffected: filteredResult['rows']?.length ?? 0,
          ),
        );
      } catch (e) {
        // 添加错误结果
        queryResults.add(QueryResult(
          sql: sql,
          data: {},
          timestamp: DateTime.now(),
          isSuccess: false,
          error: e.toString(),
        ));

        // 添加到查询历史
        await _historyService.addQuery(
          QueryHistory(
            query: sql,
            timestamp: DateTime.now(),
            database: databaseName,
            isSuccess: false,
            rowsAffected: 0,
          ),
        );

        // 显示错误提示
        Get.snackbar(
          '查询失败 / Query Failed',
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
        );
      }
    }
  }

  /// 执行历史查询
  Future<void> executeHistoryQuery(String query) async {
    currentQuery.value = query;
    await executeQuery();
  }

  /// 导出当前选中的查询结果为Excel文件
  Future<void> exportToExcel() async {
    if (queryResults.isEmpty || selectedTabIndex.value >= queryResults.length) {
      Get.snackbar(
        '错误 / Error',
        '没有可导出的查询结果 / No query results to export',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    final result = queryResults[selectedTabIndex.value];
    if (!result.isSuccess) {
      Get.snackbar(
        '错误 / Error',
        '无法导出失败的查询结果 / Cannot export failed query result',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    try {
      final DatabaseService service =
          _offlineService.isConnected ? _offlineService : _mysqlService;

      // 生成文件名（使用时间戳避免重复）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'query_result_$timestamp.xlsx';

      await service.exportToExcel(result.sql, filename);
    } catch (e) {
      Get.snackbar(
        '导出失败 / Export Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// 导出当前选中的查询结果为CSV文件
  Future<void> exportToCsv() async {
    if (queryResults.isEmpty || selectedTabIndex.value >= queryResults.length) {
      Get.snackbar(
        '错误 / Error',
        '没有可导出的查询结果 / No query results to export',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    final result = queryResults[selectedTabIndex.value];
    if (!result.isSuccess) {
      Get.snackbar(
        '错误 / Error',
        '无法导出失败的查询结果 / Cannot export failed query result',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }

    try {
      final DatabaseService service =
          _offlineService.isConnected ? _offlineService : _mysqlService;

      // 生成文件名（使用时间戳避免重复）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'query_result_$timestamp.csv';

      await service.exportToCsv(result.sql, filename);
    } catch (e) {
      Get.snackbar(
        '导出失败 / Export Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// 关闭指定的结果标签页
  void closeTab(int index) {
    if (index < 0 || index >= queryResults.length) return;

    queryResults.removeAt(index);

    // 如果关闭的是当前选中的标签页，则选中前一个标签页
    if (selectedTabIndex.value >= queryResults.length) {
      selectedTabIndex.value =
          queryResults.isEmpty ? 0 : queryResults.length - 1;
    }
  }

  /// 选择标签页
  void selectTab(int index) {
    if (index >= 0 && index < queryResults.length) {
      selectedTabIndex.value = index;
    }
  }
}
