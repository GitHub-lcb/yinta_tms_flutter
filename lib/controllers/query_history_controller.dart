/// 查询历史控制器文件
/// 使用GetX状态管理框架
/// 负责管理SQL查询历史记录的状态和业务逻辑
/// 实现了查询历史的加载、搜索、执行和管理等功能
/// 支持在线和离线两种模式的查询执行

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/query_history.dart';
import '../services/query/query_history_service.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../services/database/database_service.dart';
import '../utils/dialog_utils.dart';

/// 查询历史控制器类
/// 继承自GetxController，用于管理查询历史相关的状态和业务逻辑
/// 主要功能：
/// 1. 加载和管理查询历史记录
/// 2. 搜索和过滤查询历史
/// 3. 重新执行历史查询
/// 4. 复制和查看查询详情
class QueryHistoryController extends GetxController {
  /// 查询历史服务实例
  /// 通过构造函数注入
  /// 用于处理查询历史的存储和检索
  final QueryHistoryService _historyService;

  /// MySQL服务实例
  /// 通过GetX依赖注入获取
  /// 用于在线模式下执行SQL查询
  final MySqlService _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  /// 通过GetX依赖注入获取
  /// 用于离线模式下执行SQL查询
  final OfflineService _offlineService = Get.find<OfflineService>();

  /// 搜索框控制器
  /// 用于管理搜索输入框的状态
  /// 在控制器销毁时需要释放资源
  final searchController = TextEditingController();

  /// 所有查询历史记录列表
  final allHistories = <QueryHistory>[].obs;

  /// 当前显示的查询历史记录列表（经过搜索过滤和分页）
  final histories = <QueryHistory>[].obs;

  /// 加载状态标志
  /// true表示正在加载数据
  /// false表示加载完成或未加载
  final isLoading = false.obs;

  /// 当前正在执行的查询ID
  /// 用于标识正在执行的查询
  /// 格式：query_timestamp
  final executingQueryId = RxnString();

  /// 错误信息
  /// 存储查询执行过程中的错误信息
  /// 空字符串表示没有错误
  final error = ''.obs;

  /// 每页显示的记录数
  final pageSize = 20.obs;

  /// 当前页码（从1开始）
  final currentPage = 1.obs;

  /// 总记录数
  final totalRecords = 0.obs;

  /// 获取总页数
  int get totalPages => (totalRecords.value / pageSize.value).ceil();

  /// 构造函数
  /// @param _historyService 查询历史服务实例
  QueryHistoryController(this._historyService);

  /// 获取当前数据库服务
  /// 根据连接模式返回对应的数据库服务实例
  /// @return DatabaseService 当前使用的数据库服务
  DatabaseService get _currentService => _offlineService.isConnected
      ? _offlineService as DatabaseService
      : _mysqlService as DatabaseService;

  /// 控制器初始化方法
  /// 在控制器被创建时自动调用
  /// 负责加载查询历史记录
  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  /// 控制器销毁方法
  /// 在控制器被销毁时自动调用
  /// 负责释放资源，避免内存泄漏
  @override
  void onClose() {
    // 释放搜索框控制器资源
    searchController.dispose();
    super.onClose();
  }

  /// 加载查询历史记录方法
  /// 从历史服务中获取所有查询记录
  /// 异步操作，更新加载状态
  Future<void> loadHistory() async {
    // 设置加载状态为true
    isLoading.value = true;
    try {
      // 从服务中获取查询记录
      final results = await _historyService.getQueries();
      // 更新历史记录列表
      allHistories.value = results;
      totalRecords.value = results.length;
      _updateCurrentPageData();
    } finally {
      // 无论成功失败，都将加载状态设为false
      isLoading.value = false;
    }
  }

  /// 处理搜索内容变化方法
  /// 根据搜索关键词实时过滤查询历史记录
  /// @param value 搜索关键词
  void onSearchChanged(String value) async {
    // 设置加载状态为true
    isLoading.value = true;
    try {
      // 使用服务搜索历史记录
      final results = await _historyService.searchHistory(value);
      // 更新过滤后的历史记录列表
      allHistories.value = results;
      totalRecords.value = results.length;
      currentPage.value = 1; // 重置到第一页
      _updateCurrentPageData();
    } finally {
      // 完成搜索，设置加载状态为false
      isLoading.value = false;
    }
  }

  /// 更新当前页显示的数据
  void _updateCurrentPageData() {
    final start = (currentPage.value - 1) * pageSize.value;
    final end = start + pageSize.value;
    histories.value = allHistories.sublist(
      start,
      end > allHistories.length ? allHistories.length : end,
    );
  }

  /// 切换页码
  void changePage(int page) {
    if (page < 1 || page > totalPages) return;
    currentPage.value = page;
    _updateCurrentPageData();
  }

  /// 切换每页显示记录数
  void changePageSize(int size) {
    pageSize.value = size;
    currentPage.value = 1; // 重置到第一页
    _updateCurrentPageData();
  }

  /// 清空查询历史方法
  /// 删除所有查询历史记录
  /// 同时清空内存中的历史记录列表
  Future<void> clearHistory() async {
    // 清空存储的历史记录
    await _historyService.clearHistory();
    // 清空内存中的历史记录列表
    allHistories.clear();
    histories.clear();
    totalRecords.value = 0;
    currentPage.value = 1;
  }

  /// 复制查询语句方法
  /// 将查询语句复制到系统剪贴板
  /// @param history 要复制的查询历史记录
  void copyQuery(QueryHistory history) {
    // 复制查询语句到剪贴板
    Clipboard.setData(ClipboardData(text: history.query));
    // 显示复制成功提示
    DialogUtils.showSuccess(
      '复制成功 / Copied',
      '查询已复制到剪贴板 / Query copied to clipboard',
    );
  }

  /// 执行查询方法
  /// 重新执行历史查询记录中的SQL语句
  /// @param history 要执行的查询历史记录
  Future<void> executeQuery(QueryHistory history) async {
    // 设置当前执行的查询ID
    executingQueryId.value =
        '${history.query}_${history.timestamp.millisecondsSinceEpoch}';
    try {
      print('Executing query: ${history.query}');

      // 执行查询操作
      final result = await _currentService.executeQuery(
        history.database,
        history.query,
      );

      print('Raw query result type: ${result.runtimeType}');

      // 将成功的查询添加到历史记录
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
      // 将失败的查询添加到历史记录
      await _historyService.addQuery(
        QueryHistory(
          query: history.query,
          timestamp: DateTime.now(),
          database: history.database,
          isSuccess: false,
          rowsAffected: 0,
        ),
      );
      // 设置错误信息
      error.value = e.toString();
      // 显示错误提示对话框
      DialogUtils.showError(
        '执行失败 / Execution Failed',
        e.toString(),
      );
    } finally {
      // 清除当前执行的查询ID
      executingQueryId.value = null;
    }
  }

  /// 检查查询执行状态方法
  /// 判断指定的查询是否正在执行
  /// @param history 要检查的查询历史记录
  /// @return bool 是否正在执行
  bool isQueryExecuting(QueryHistory history) {
    // 生成查询ID
    final queryId =
        '${history.query}_${history.timestamp.millisecondsSinceEpoch}';
    // 比较当前执行的查询ID
    return executingQueryId.value == queryId;
  }

  /// 显示查询详情对话框方法
  /// 以对话框形式显示查询的详细信息
  /// @param history 要显示详情的查询历史记录
  void showQueryDetails(QueryHistory history) {
    Get.dialog(
      AlertDialog(
        title: const Text('查询详情 / Query Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // SQL查询语句显示
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
              // 数据库信息显示
              Text(
                '数据库 / Database: ${history.database}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 执行时间显示
              Text(
                '执行时间 / Execution Time: ${history.timestamp.toString()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 影响行数显示
              Text(
                '影响行数 / Rows Affected: ${history.rowsAffected}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // 执行状态显示
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
        // 对话框按钮
        actions: [
          // 关闭按钮
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭 / Close'),
          ),
          // 重新执行按钮
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
