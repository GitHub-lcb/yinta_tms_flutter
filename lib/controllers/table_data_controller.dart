import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database/database_service.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../services/query/query_history_service.dart';
import '../models/query_history.dart';
import '../utils/dialog_utils.dart';

/// 表数据控制器
/// 负责管理表数据界面的状态和业务逻辑，包括数据加载、分页、排序、筛选等功能
class TableDataController extends GetxController {
  /// MySQL服务实例
  final _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  final _offlineService = Get.find<OfflineService>();

  /// 搜索框控制器
  final searchController = TextEditingController();

  /// 表格数据
  final data = <Map<String, dynamic>>[].obs;

  /// 演示大数据集（用于性能演示）
  final largeDataset = <Map<String, dynamic>>[].obs;

  /// 是否使用懒加载模式
  final useLazyLoading = true.obs;

  /// 是否正在展示性能演示
  final isPerformanceDemo = false.obs;

  /// 表格列名
  final columns = <String>[].obs;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  /// 当前页码（从0开始）
  final currentPage = 0.obs;

  /// 总页数
  final totalPages = 1.obs;

  /// 每页显示的记录数
  final pageSize = 20.obs;

  /// 排序列名
  final sortColumn = ''.obs;

  /// 排序方向（true为升序，false为降序）
  final sortAscending = true.obs;

  /// 筛选条件，键为列名，值为筛选值
  final filterConditions = <String, String>{}.obs;

  /// 当前数据库名称
  late final String databaseName;

  /// 当前表名
  late final String tableName;

  /// 获取当前服务实例
  dynamic get _currentService =>
      _offlineService.isConnected ? _offlineService : _mysqlService as dynamic;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据库名和表名
    final args = Get.arguments as Map<String, dynamic>;
    databaseName = args['database'] as String;
    tableName = args['table'] as String;
    loadData();
  }

  @override
  void onClose() {
    // 释放搜索框控制器资源
    searchController.dispose();
    super.onClose();
  }

  /// 加载表数据
  /// 根据当前的分页、排序和筛选条件加载数据
  Future<void> loadData() async {
    isLoading.value = true;
    error.value = '';

    try {
      print('开始加载数据，数据库: $databaseName, 表: $tableName');
      print('当前服务类型: ${_currentService.runtimeType}');

      // 先获取总记录数
      String countQuery = 'SELECT COUNT(*) as total FROM `$tableName`';
      if (filterConditions.isNotEmpty) {
        final conditions = filterConditions.entries
            .map((e) => "`${e.key}` LIKE '%${e.value}%'")
            .join(' AND ');
        countQuery += ' WHERE $conditions';
      }

      print('执行计数查询: $countQuery');
      final countResult =
          await _currentService.executeQuery(databaseName, countQuery);
      print('计数查询结果详情:');
      print('- 结果类型: ${countResult.runtimeType}');
      // print('- 结果内容: $countResult');
      print('- rows类型: ${countResult['rows']?.runtimeType}');
      print('- rows内容: ${countResult['rows']}');
      print('- 第一行内容: ${countResult['rows']?[0]}');

      // 从结果中提取总数
      final countValue = countResult['rows']?[0][0];
      print('提取的计数值: $countValue (${countValue.runtimeType})');
      final total = countValue != null ? int.parse(countValue.toString()) : 0;
      print('转换后的总数: $total');
      totalPages.value = (total / pageSize.value).ceil();
      print('计算的总页数: ${totalPages.value}');

      // 构建分页查询
      String query = 'SELECT * FROM `$tableName`';
      if (filterConditions.isNotEmpty) {
        final conditions = filterConditions.entries
            .map((e) => "`${e.key}` LIKE '%${e.value}%'")
            .join(' AND ');
        query += ' WHERE $conditions';
      }

      if (sortColumn.isNotEmpty) {
        query +=
            ' ORDER BY `${sortColumn.value}` ${sortAscending.value ? 'ASC' : 'DESC'}';
      }

      // 添加分页
      final offset = currentPage.value * pageSize.value;
      query += ' LIMIT ${pageSize.value} OFFSET $offset';

      print('执行数据查询: $query');
      final result = await _currentService.executeQuery(databaseName, query);
      print('数据查询结果详情:');
      print('- 结果类型: ${result.runtimeType}');
      // print('- 结果内容: $result');
      print('- columns: ${result['columns']}');
      // print('- rows: ${result['rows']}');

      // 更新列和数据
      if (result['columns']?.isNotEmpty ?? false) {
        columns.value = List<String>.from(result['columns']);
        if (result['rows']?.isNotEmpty ?? false) {
          // 将行数据转换为 Map 格式
          data.value = List<Map<String, dynamic>>.from(
            result['rows'].map((row) {
              final map = <String, dynamic>{};
              for (var i = 0; i < columns.length; i++) {
                map[columns[i]] = row[i];
              }
              return map;
            }),
          );
        } else {
          data.value = [];
        }
      } else {
        columns.value = [];
        data.value = [];
      }
    } catch (e, stackTrace) {
      print('加载数据失败:');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 处理搜索框内容变化
  /// 当搜索框内容变化时，更新筛选条件并重新加载数据
  ///
  /// 参数:
  /// - [value]: 搜索框的新值
  void onSearchChanged(String value) {
    if (value.isEmpty) {
      filterConditions.clear();
    } else {
      filterConditions.clear();
      // 在所有列中搜索
      for (final column in columns) {
        filterConditions[column] = value;
      }
    }
    currentPage.value = 0; // 重置到第一页
    loadData();
  }

  /// 处理每页显示记录数变化
  ///
  /// 参数:
  /// - [value]: 新的每页记录数
  void onPageSizeChanged(int? value) {
    if (value != null) {
      pageSize.value = value;
      currentPage.value = 0;
      loadData();
    }
  }

  /// 处理排序变化
  ///
  /// 参数:
  /// - [column]: 排序列名
  /// - [ascending]: 是否升序
  void onSort(String column, bool ascending) {
    sortColumn.value = column;
    sortAscending.value = ascending;
    loadData();
  }

  /// 跳转到第一页
  void firstPage() {
    currentPage.value = 0;
    loadData();
  }

  /// 跳转到上一页
  void previousPage() {
    if (currentPage.value > 0) {
      currentPage.value--;
      loadData();
    }
  }

  /// 跳转到下一页
  void nextPage() {
    if (currentPage.value < totalPages.value - 1) {
      currentPage.value++;
      loadData();
    }
  }

  /// 跳转到最后一页
  void lastPage() {
    currentPage.value = totalPages.value - 1;
    loadData();
  }

  /// 显示筛选对话框
  /// 允许用户选择要筛选的列并输入筛选条件
  Future<void> showFilterDialog() async {
    // 已选择的列
    final selectedColumns = <String>[].obs;
    // 筛选值输入控制器
    final filterValues = <String, TextEditingController>{};

    // 为每一列创建输入控制器
    for (final column in columns) {
      filterValues[column] = TextEditingController(
        text: filterConditions[column] ?? '',
      );
    }

    await Get.dialog(
      AlertDialog(
        title: const Text('筛选 / Filter'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: columns.map((column) {
                      return Obx(() => CheckboxListTile(
                            title: Text(column),
                            value: selectedColumns.contains(column),
                            onChanged: (checked) {
                              if (checked == true) {
                                selectedColumns.add(column);
                              } else {
                                selectedColumns.remove(column);
                              }
                            },
                            subtitle: selectedColumns.contains(column)
                                ? TextField(
                                    controller: filterValues[column],
                                    decoration: InputDecoration(
                                      hintText: '输入筛选条件 / Enter filter',
                                      labelText: column,
                                    ),
                                  )
                                : null,
                          ));
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 清除筛选按钮
          TextButton(
            onPressed: () {
              filterConditions.clear();
              Get.back();
              loadData();
            },
            child: const Text('清除 / Clear'),
          ),
          // 取消按钮
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          // 应用筛选按钮
          ElevatedButton(
            onPressed: () {
              filterConditions.clear();
              for (final column in selectedColumns) {
                final value = filterValues[column]?.text.trim() ?? '';
                if (value.isNotEmpty) {
                  filterConditions[column] = value;
                }
              }
              Get.back();
              loadData();
            },
            child: const Text('应用 / Apply'),
          ),
        ],
      ),
    );

    // 清理输入控制器资源
    for (final controller in filterValues.values) {
      controller.dispose();
    }
  }

  Future<void> showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};

    // Create controllers for each column
    for (final column in columns) {
      controllers[column] = TextEditingController();
    }

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('添加记录 / Add Record'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: columns.map((column) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: controllers[column],
                    decoration: InputDecoration(
                      labelText: column,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // TODO: Add validation based on column type
                      return null;
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back(result: true);
              }
            },
            child: const Text('添加 / Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Build column names and values for INSERT query
        final columnNames = columns.join('`, `');
        final values = columns.map((column) {
          final value = controllers[column]?.text.trim() ?? '';
          return value.isEmpty ? 'NULL' : "'$value'";
        }).join(', ');

        // Execute INSERT query
        final query = '''
          INSERT INTO `$databaseName`.`$tableName` 
          (`$columnNames`) 
          VALUES ($values)
        ''';

        await _currentService.executeQuery(databaseName, query);
        loadData(); // Reload data after insert
      } catch (e) {
        error.value = e.toString();
      }
    }

    // Clean up controllers
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> showEditDialog(Map<String, dynamic> row, String column) async {
    final controller =
        TextEditingController(text: row[column]?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text('编辑 / Edit: $column'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前值 / Current value:',
                  style: TextStyle(color: Colors.grey[600])),
              Text(
                row[column]?.toString() ?? 'NULL',
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: row[column] == null ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 16),
              Text('新值 / New value:',
                  style: TextStyle(color: Colors.grey[600])),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter new value',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  // TODO: Add validation based on column type
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back(result: controller.text);
              }
            },
            child: const Text('保存 / Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        // Find primary key columns (assuming first column is primary key)
        final primaryKey = columns.first;
        final primaryKeyValue = row[primaryKey];

        // Build and execute update query
        final query = '''
          UPDATE `$databaseName`.`$tableName` 
          SET `$column` = ${result.isEmpty ? 'NULL' : "'$result'"} 
          WHERE `$primaryKey` = ${primaryKeyValue is String ? "'$primaryKeyValue'" : primaryKeyValue}
        ''';

        await _currentService.executeQuery(databaseName, query);
        loadData(); // Reload data after update
      } catch (e) {
        error.value = e.toString();
      }
    }
  }

  Future<void> showRowActions(Map<String, dynamic> row) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('操作 / Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑 / Edit'),
              onTap: () async {
                Get.back();
                // Show edit dialog for each column
                for (final column in columns) {
                  await showEditDialog(row, column);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除 / Delete',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Get.back();
                final confirm = await Get.dialog<bool>(
                  AlertDialog(
                    title: const Text('确认删除 / Confirm Delete'),
                    content: const Text(
                        '确定要删除这条记录吗？\nAre you sure you want to delete this record?'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: const Text('取消 / Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('删除 / Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    // Find primary key columns (assuming first column is primary key)
                    final primaryKey = columns.first;
                    final primaryKeyValue = row[primaryKey];

                    // Execute DELETE query
                    final query = '''
                      DELETE FROM `$databaseName`.`$tableName`
                      WHERE `$primaryKey` = ${primaryKeyValue is String ? "'$primaryKeyValue'" : primaryKeyValue}
                    ''';

                    await _currentService.executeQuery(query);
                    loadData(); // Reload data after delete
                  } catch (e) {
                    error.value = e.toString();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> exportToExcel() async {
    try {
      // Build query for all data (without pagination)
      String query = 'SELECT * FROM `$databaseName`.`$tableName`';

      // Add WHERE clause if there are filter conditions
      if (filterConditions.isNotEmpty) {
        final conditions = filterConditions.entries
            .map((e) => "`${e.key}` LIKE '%${e.value}%'")
            .join(' AND ');
        query += ' WHERE $conditions';
      }

      // Add ORDER BY clause if sorting is active
      if (sortColumn.isNotEmpty) {
        query +=
            ' ORDER BY `${sortColumn.value}` ${sortAscending.value ? 'ASC' : 'DESC'}';
      }

      await _currentService.exportToExcel(
        query,
        '${tableName}_${DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_')}.xlsx',
      );
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> exportToCsv() async {
    try {
      // Build query for all data (without pagination)
      String query = 'SELECT * FROM `$databaseName`.`$tableName`';

      // Add WHERE clause if there are filter conditions
      if (filterConditions.isNotEmpty) {
        final conditions = filterConditions.entries
            .map((e) => "`${e.key}` LIKE '%${e.value}%'")
            .join(' AND ');
        query += ' WHERE $conditions';
      }

      // Add ORDER BY clause if sorting is active
      if (sortColumn.isNotEmpty) {
        query +=
            ' ORDER BY `${sortColumn.value}` ${sortAscending.value ? 'ASC' : 'DESC'}';
      }

      await _currentService.exportToCsv(
        query,
        '${tableName}_${DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_')}.csv',
      );
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<void> executeQuery(String query) async {
    try {
      final result = await _currentService.executeQuery(databaseName, query);
      final historyService = Get.find<QueryHistoryService>();
      await historyService.addQuery(
        QueryHistory(
          query: query,
          timestamp: DateTime.now(),
          database: databaseName,
          isSuccess: true,
          rowsAffected: result.length,
        ),
      );
      Get.toNamed('/query-result', arguments: {
        'query': query,
        'data': result,
      });
    } catch (e) {
      final historyService = Get.find<QueryHistoryService>();
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

  /// 执行自定义SQL查询
  Future<void> executeCustomQuery(String sql) async {
    if (sql.trim().isEmpty) return;

    isLoading.value = true;
    error.value = '';

    try {
      // 检查是否是 SELECT 查询
      final isSelect =
          RegExp(r'^\s*SELECT\s+', caseSensitive: false).hasMatch(sql);

      // 如果是 SELECT 查询且没有 LIMIT 子句，自动添加限制
      if (isSelect &&
          !RegExp(r'\bLIMIT\s+\d+', caseSensitive: false).hasMatch(sql)) {
        sql = '$sql LIMIT 1000'; // 默认限制1000行
      }

      print('执行自定义查询: $sql');
      final startTime = DateTime.now();
      final result = await _currentService.executeQuery(databaseName, sql);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      print('查询结果: $result');

      // 更新列和数据
      if (result['columns']?.isNotEmpty ?? false) {
        columns.value = List<String>.from(result['columns']);
        if (result['rows']?.isNotEmpty ?? false) {
          // 将行数据转换为 Map 格式
          data.value = List<Map<String, dynamic>>.from(
            result['rows'].map((row) {
              final map = <String, dynamic>{};
              for (var i = 0; i < columns.length; i++) {
                map[columns[i]] = row[i];
              }
              return map;
            }),
          );
          // 显示查询结果信息
          DialogUtils.showSuccess(
            '查询成功',
            '返回 ${data.length} 行数据\n耗时: ${duration.inMilliseconds}ms',
          );
        } else {
          data.value = [];
          DialogUtils.showSuccess(
            '查询成功',
            '没有返回数据\n耗时: ${duration.inMilliseconds}ms',
          );
        }
      } else {
        columns.value = [];
        data.value = [];
      }

      // 如果是非SELECT语句，显示执行结果
      if (result['columns']?.length == 1 &&
          result['columns']?[0] == 'Affected Rows') {
        DialogUtils.showSuccess(
          '执行成功',
          '影响行数: ${result['rows']?[0][0]}\n耗时: ${duration.inMilliseconds}ms',
        );
      }

      // 添加到查询历史
      final historyService = Get.find<QueryHistoryService>();
      await historyService.addQuery(
        QueryHistory(
          query: sql,
          timestamp: DateTime.now(),
          database: databaseName,
          isSuccess: true,
          rowsAffected: data.length,
        ),
      );
    } catch (e, stackTrace) {
      print('执行查询失败:');
      print('错误信息: $e');
      print('堆栈跟踪: $stackTrace');
      error.value = e.toString();
      DialogUtils.showError(
        '查询失败',
        e.toString(),
      );

      // 添加到查询历史
      final historyService = Get.find<QueryHistoryService>();
      await historyService.addQuery(
        QueryHistory(
          query: sql,
          timestamp: DateTime.now(),
          database: databaseName,
          isSuccess: false,
          rowsAffected: 0,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 切换是否使用懒加载
  void toggleLazyLoading() {
    useLazyLoading.value = !useLazyLoading.value;
  }

  /// 生成大数据集用于性能演示
  void generateLargeDataset() {
    isPerformanceDemo.value = true;
    isLoading.value = true;

    // 清空现有数据
    largeDataset.clear();

    // 生成10万行测试数据
    for (int i = 0; i < 100000; i++) {
      final Map<String, dynamic> row = {};
      for (String column in columns) {
        row[column] = '数据 $i - $column';
      }
      largeDataset.add(row);
    }

    isLoading.value = false;
  }

  /// 退出性能演示模式
  void exitPerformanceDemo() {
    isPerformanceDemo.value = false;
    // 确保退出时切回懒加载模式（防止下次进入时卡死）
    useLazyLoading.value = true;
    largeDataset.clear();
  }
}
