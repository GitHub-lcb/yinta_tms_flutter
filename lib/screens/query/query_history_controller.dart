import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../models/query_history.dart';
import '../../services/query/query_history_service.dart';
import '../../services/database/mysql_service.dart';
import '../../services/database/offline_service.dart';
import '../../services/database/database_service.dart';

/// 查询历史控制器
/// 负责管理查询历史界面的状态和业务逻辑，包括查询历史的加载、搜索、执行和管理等功能
class QueryHistoryController extends GetxController {
  /// 查询历史服务实例
  final QueryHistoryService _historyService;

  /// MySQL服务实例
  final MySqlService _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  final OfflineService _offlineService = Get.find<OfflineService>();

  /// 搜索框控制器
  final searchController = TextEditingController();

  /// 查询历史记录列表
  final histories = <QueryHistory>[].obs;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  QueryHistoryController(this._historyService);

  /// 获取当前数据库服务
  DatabaseService get _currentService => _offlineService.isConnected
      ? _offlineService as DatabaseService
      : _mysqlService as DatabaseService;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// 加载查询历史记录
  /// 从历史服务中获取所有查询记录
  Future<void> loadHistory() async {
    isLoading.value = true;
    try {
      final results = await _historyService.getQueries();
      histories.value = results;
    } finally {
      isLoading.value = false;
    }
  }

  /// 处理搜索内容变化
  /// 根据搜索关键词过滤查询历史记录
  ///
  /// 参数:
  /// - [value]: 搜索关键词
  void onSearchChanged(String value) async {
    isLoading.value = true;
    try {
      final results = await _historyService.searchHistory(value);
      histories.value = results;
    } finally {
      isLoading.value = false;
    }
  }

  /// 清空查询历史
  /// 删除所有查询历史记录
  Future<void> clearHistory() async {
    await _historyService.clearHistory();
    histories.clear();
  }

  /// 复制查询语句
  /// 将查询语句复制到剪贴板
  ///
  /// 参数:
  /// - [history]: 要复制的查询历史记录
  void copyQuery(QueryHistory history) {
    Clipboard.setData(ClipboardData(text: history.query));
    Get.snackbar(
      '复制成功 / Copied',
      '查询已复制到剪贴板 / Query copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 执行查询
  /// 重新执行历史查询记录中的SQL语句
  ///
  /// 参数:
  /// - [history]: 要执行的查询历史记录
  Future<void> executeQuery(QueryHistory history) async {
    try {
      print('Executing query: ${history.query}');

      // 执行查询
      final result = await _currentService.executeQuery(
        history.database,
        history.query,
      );

      print('Raw query result type: ${result.runtimeType}');
      print('Raw query result: $result');

      // 添加新的查询记录到历史
      await _historyService.addQuery(
        QueryHistory(
          query: history.query,
          timestamp: DateTime.now(),
          database: history.database,
          isSuccess: true,
          rowsAffected: result['rows']?.length ?? 0,
        ),
      );

      // 导航到查询结果页面
      Get.toNamed('/query-result', arguments: {
        'query': history.query,
        'data': result,
      });
    } catch (e) {
      print('Error executing query: $e');
      // 添加失败的查询记录到历史
      await _historyService.addQuery(
        QueryHistory(
          query: history.query,
          timestamp: DateTime.now(),
          database: history.database,
          isSuccess: false,
          rowsAffected: 0,
        ),
      );
      error.value = e.toString();
      Get.snackbar(
        '执行失败 / Execution Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  /// 显示查询详情对话框
  /// 显示查询历史记录的详细信息，包括SQL语句、执行时间、影响行数等
  ///
  /// 参数:
  /// - [history]: 要显示详情的查询历史记录
  void showQueryDetails(QueryHistory history) {
    Get.dialog(
      AlertDialog(
        title: const Text('查询详情 / Query Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SQL Query:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  history.query,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              Text(
                '数据库 / Database: ${history.database}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '执行时间 / Execution Time: ${history.timestamp.toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '影响行数 / Rows Affected: ${history.rowsAffected}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '执行状态 / Status: ${history.isSuccess ? "成功 / Success" : "失败 / Failed"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: history.isSuccess ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭 / Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              executeQuery(history);
            },
            child: const Text('重新执行 / Execute'),
          ),
        ],
      ),
    );
  }
}
