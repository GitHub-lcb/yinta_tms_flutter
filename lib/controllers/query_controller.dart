import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../services/database/database_service.dart';
import '../services/query/query_history_service.dart';
import '../models/query_history.dart';
import '../utils/file_utils.dart';
import '../utils/dialog_utils.dart';

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
  final isLoading = false.obs;

  /// 每页显示的记录数
  final pageSize = 50.obs;

  /// 当前页码（从1开始）
  final currentPage = 1.obs;

  /// 总记录数
  final totalRecords = 0.obs;

  /// 水平滚动控制器
  final horizontalScrollController = ScrollController();

  /// 拖动起始位置
  double? _dragStartX;

  /// 拖动起始滚动位置
  double? _dragStartScroll;

  /// 获取当前数据库名称
  late final String databaseName;

  /// 获取总页数
  int get totalPages => (totalRecords.value / pageSize.value).ceil();

  /// 获取当前查询结果
  QueryResult? get currentResult =>
      queryResults.isEmpty ? null : queryResults[selectedTabIndex.value];

  /// 获取当前页的数据
  List<dynamic> get currentPageData {
    if (currentResult == null || !currentResult!.isSuccess) return [];
    final rows = currentResult!.data['rows'] as List;
    final start = (currentPage.value - 1) * pageSize.value;
    final end = start + pageSize.value;
    if (start >= rows.length) return [];
    return rows.sublist(start, end > rows.length ? rows.length : end);
  }

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
      final result = await service.getTables(databaseName);
      final tableList = List<String>.from(result['tables'] as List);
      tables.value = tableList;

      // 加载所有表的列信息用于自动完成
      columns.clear();
      for (final table in tableList) {
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
      DialogUtils.showError(
        '加载失败 / Load Failed',
        e.toString(),
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

  /// 切换页码
  void changePage(int page) {
    if (page < 1 || page > totalPages) return;
    currentPage.value = page;
  }

  /// 切换每页显示记录数
  void changePageSize(int size) {
    pageSize.value = size;
    // 重新计算当前页码，确保数据正确显示
    currentPage.value = 1;
  }

  /// 执行SQL查询
  Future<void> executeQuery() async {
    if (currentQuery.value.isEmpty) {
      DialogUtils.showError(
        '错误 / Error',
        'SQL查询不能为空 / SQL query cannot be empty',
      );
      return;
    }

    // 设置loading状态
    isLoading.value = true;

    try {
      // 分割多条SQL语句
      final queries = currentQuery.value
          .split(';')
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty)
          .toList();

      // 清空之前的结果
      queryResults.clear();
      selectedTabIndex.value = 0;
      currentPage.value = 1; // 重置页码

      // 执行每条SQL语句
      for (final sql in queries) {
        try {
          final DatabaseService service =
              _offlineService.isConnected ? _offlineService : _mysqlService;

          // 处理SELECT语句的分页
          String processedSql = sql;
          final isSelect =
              RegExp(r'^\s*SELECT\b', caseSensitive: false).hasMatch(sql);
          final hasLimit =
              RegExp(r'\bLIMIT\b', caseSensitive: false).hasMatch(sql);

          // 如果是SELECT语句且没有LIMIT子句，添加默认的LIMIT
          if (isSelect && !hasLimit) {
            processedSql = '$sql LIMIT 1000'; // 增加默认限制到10000条
          }

          final result = await service.executeQuery(databaseName, processedSql);

          // 过滤内部字段
          final filteredResult = _filterInternalFields(result);

          // 更新总记录数
          if (isSelect) {
            totalRecords.value = (filteredResult['rows'] as List).length;
          }

          // 添加到结果列表
          queryResults.add(QueryResult(
            sql: processedSql,
            data: filteredResult,
            timestamp: DateTime.now(),
            isSuccess: true,
          ));

          // 添加到查询历史
          await _historyService.addQuery(
            QueryHistory(
              query: processedSql,
              timestamp: DateTime.now(),
              database: databaseName,
              isSuccess: true,
              rowsAffected: filteredResult['rows']?.length ?? 0,
            ),
          );

          // 如果是SELECT语句且使用了默认LIMIT，添加提示信息
          if (isSelect && !hasLimit && totalRecords.value >= 1000) {
            DialogUtils.showInfo(
              '提示 / Notice',
              '为了提高性能，查询结果已限制为前1000条记录\nFor better performance, query results are limited to first 1000 records',
            );
          }
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
          DialogUtils.showError(
            '查询失败 / Query Failed',
            e.toString(),
          );
        }
      }
    } finally {
      // 无论成功失败都关闭loading
      isLoading.value = false;
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
      DialogUtils.showError(
        '错误 / Error',
        '没有可导出的查询结果 / No query results to export',
      );
      return;
    }

    final result = queryResults[selectedTabIndex.value];
    if (!result.isSuccess) {
      DialogUtils.showError(
        '错误 / Error',
        '无法导出失败的查询结果 / Cannot export failed query result',
      );
      return;
    }

    try {
      final DatabaseService service =
          _offlineService.isConnected ? _offlineService : _mysqlService;

      // 生成文件名（使用时间戳避免重复）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'query_result_$timestamp.xlsx';

      await service.exportToExcel(
        result.sql,
        filename,
        mimeType: FileUtils.getMimeType(filename),
      );
    } catch (e) {
      DialogUtils.showError(
        '导出失败 / Export Failed',
        e.toString(),
      );
    }
  }

  /// 导出当前选中的查询结果为CSV文件
  Future<void> exportToCsv() async {
    if (queryResults.isEmpty || selectedTabIndex.value >= queryResults.length) {
      DialogUtils.showError(
        '错误 / Error',
        '没有可导出的查询结果 / No query results to export',
      );
      return;
    }

    final result = queryResults[selectedTabIndex.value];
    if (!result.isSuccess) {
      DialogUtils.showError(
        '错误 / Error',
        '无法导出失败的查询结果 / Cannot export failed query result',
      );
      return;
    }

    try {
      final DatabaseService service =
          _offlineService.isConnected ? _offlineService : _mysqlService;

      // 生成文件名（使用时间戳避免重复）
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'query_result_$timestamp.csv';

      await service.exportToCsv(
        result.sql,
        filename,
        mimeType: FileUtils.getMimeType(filename),
      );
    } catch (e) {
      DialogUtils.showError(
        '导出失败 / Export Failed',
        e.toString(),
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
