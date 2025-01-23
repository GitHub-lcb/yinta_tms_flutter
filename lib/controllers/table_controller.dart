/// 数据表控制器文件
/// 使用GetX状态管理框架
/// 负责管理数据表列表界面的状态和业务逻辑
/// 支持在线和离线两种模式的数据表操作

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../models/query_history.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../services/query/query_history_service.dart';
import '../widgets/sql_editor.dart';

/// 数据表列表控制器类
/// 继承自GetxController，用于管理数据表相关的状态和业务逻辑
/// 主要功能：
/// 1. 加载和管理数据表列表
/// 2. 提供表数据的查看和编辑功能
/// 3. 支持表结构的修改
/// 4. 提供SQL查询执行功能
/// 5. 实现表列表的搜索和分页
class TableController extends GetxController {
  /// MySQL服务实例
  /// 通过GetX依赖注入获取
  /// 用于处理在线模式下的数据表操作
  final _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  /// 通过GetX依赖注入获取
  /// 用于处理离线模式下的数据表操作
  final _offlineService = Get.find<OfflineService>();

  /// 所有表的列表
  /// 存储未经过滤的完整表列表
  /// 用于前端搜索和过滤操作
  final allTables = <String>[].obs;

  /// 当前显示的表列表
  /// 存储经过搜索过滤和分页后的表列表
  /// 用于UI显示
  final tables = <String>[].obs;

  /// 表的总数
  /// 记录当前数据库中的表总数
  /// 用于分页计算
  final totalTables = 0.obs;

  /// 当前页码
  /// 从1开始计数
  /// 用于分页显示
  final currentPage = 1.obs;

  /// 每页显示的表数量
  /// 默认为20条
  /// 用于分页显示
  final pageSize = 20.obs;

  /// 搜索关键词
  /// 用户输入的搜索条件
  /// 用于过滤表列表
  final searchKeyword = ''.obs;

  /// 搜索防抖定时器
  /// 用于优化搜索性能
  /// 避免频繁触发搜索操作
  Timer? _searchDebounce;

  /// 所有表的列名列表
  /// 用于SQL编辑器的自动完成功能
  /// 提供列名建议
  final columns = <String>[].obs;

  /// 加载状态标志
  /// true表示正在加载数据
  /// false表示加载完成或未加载
  final isLoading = false.obs;

  /// 错误信息
  /// 存储加载过程中的错误信息
  /// 空字符串表示没有错误
  final error = ''.obs;

  /// 当前选中的数据库名称
  /// 从路由参数中获取
  /// 用于标识当前操作的数据库
  late final String databaseName;

  /// 获取当前服务实例
  /// 根据连接状态返回对应的服务实例
  /// 用于统一处理在线和离线模式的操作
  dynamic get _currentService =>
      _offlineService.isConnected ? _offlineService : _mysqlService as dynamic;

  /// 控制器初始化方法
  /// 在控制器被创建时自动调用
  /// 负责初始化数据和状态
  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据库名称
    databaseName = Get.arguments as String;
    // 加载表列表
    loadTables();
  }

  /// 加载所有表方法
  /// 从服务获取表列表并更新状态
  /// 支持在线和离线两种模式
  /// 异步操作，返回Future
  Future<void> loadTables() async {
    // 设置加载状态为true
    isLoading.value = true;
    // 清空错误信息
    error.value = '';

    try {
      // 获取当前服务实例
      final service = _offlineService.isConnected
          ? _offlineService
          : _mysqlService as dynamic;

      // 获取表列表
      final result = await service.getTables(databaseName);
      allTables.value = List<String>.from(result['tables'] as List);

      // 更新总数并应用过滤
      _applyFilterAndPagination();

      // 只在第一次加载时获取列信息
      if (columns.isEmpty) {
        // await _loadColumnsInfo();
      }
    } catch (e) {
      // 捕获并存储错误信息
      error.value = e.toString();
    } finally {
      // 无论成功失败，都将加载状态设为false
      isLoading.value = false;
    }
  }

  /// 应用过滤和分页方法
  /// 根据搜索关键词过滤表列表
  /// 并应用分页逻辑
  void _applyFilterAndPagination() {
    // 1. 根据关键词过滤表列表
    List<String> filteredTables = allTables.toList();
    if (searchKeyword.value.isNotEmpty) {
      filteredTables = filteredTables
          .where((table) =>
              table.toLowerCase().contains(searchKeyword.value.toLowerCase()))
          .toList();
    }

    // 2. 更新表总数
    totalTables.value = filteredTables.length;

    // 3. 应用分页逻辑
    final startIndex = (currentPage.value - 1) * pageSize.value;
    final endIndex = startIndex + pageSize.value;

    // 确保索引不越界
    if (startIndex < filteredTables.length) {
      tables.value = filteredTables.sublist(
          startIndex, endIndex.clamp(0, filteredTables.length));
    } else {
      tables.value = [];
    }
  }

  /// 搜索表方法
  /// 处理用户输入的搜索关键词
  /// 包含300ms的防抖处理
  /// @param keyword 搜索关键词
  void searchTables(String keyword) {
    // 取消之前的防抖定时器
    _searchDebounce?.cancel();

    // 更新搜索关键词
    searchKeyword.value = keyword;

    // 重置到第一页
    currentPage.value = 1;

    // 添加300ms防抖
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilterAndPagination();
    });
  }

  /// 切换页码方法
  /// 验证页码有效性并更新列表
  /// @param page 目标页码
  void changePage(int page) {
    // 验证页码下限
    if (page < 1) return;
    // 计算最大页码
    final maxPage = (totalTables.value / pageSize.value).ceil();
    // 验证页码上限
    if (page > maxPage) return;

    // 更新页码并重新加载数据
    currentPage.value = page;
    _applyFilterAndPagination();
  }

  /// 下一页方法
  /// 将当前页码加1
  void nextPage() {
    changePage(currentPage.value + 1);
  }

  /// 上一页方法
  /// 将当前页码减1
  void previousPage() {
    changePage(currentPage.value - 1);
  }

  /// 选择数据表方法
  /// 显示表的操作菜单对话框
  /// 提供查看数据、编辑结构、执行查询等选项
  /// @param table 选中的表名
  Future<void> selectTable(String table) async {
    final result = await Get.dialog<String>(
      AlertDialog(
        title: Text('$table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('查看数据 / View Data'),
              onTap: () {
                Get.back(result: 'view');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑结构 / Edit Structure'),
              onTap: () {
                Get.back(result: 'edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('执行查询 / Execute Query'),
              onTap: () {
                Get.back(result: 'query');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
        ],
      ),
    );

    // 根据用户选择执行相应操作
    if (result != null) {
      switch (result) {
        case 'view':
          await viewTableData(table);
          break;
        case 'edit':
          await editTable(table);
          break;
        case 'query':
          await Get.toNamed('/query', arguments: {
            'database': databaseName,
            'defaultQuery': 'SELECT * FROM `$table` LIMIT 100',
          });
          break;
      }
    }
  }

  /// 查看表数据方法
  /// 导航到表数据页面
  /// @param table 要查看的表名
  Future<void> viewTableData(String table) async {
    Get.toNamed('/table-data', arguments: {
      'database': databaseName,
      'table': table,
    });
  }

  /// 编辑表结构方法
  /// 导航到表结构页面
  /// @param table 要编辑的表名
  Future<void> editTable(String table) async {
    Get.toNamed('/table-structure', arguments: {
      'database': databaseName,
      'table': table,
    });
  }

  /// 显示SQL查询对话框方法
  /// 导航到查询页面
  /// 用于执行自定义SQL查询
  Future<void> showQueryDialog() async {
    Get.toNamed('/query', arguments: {
      'database': databaseName,
    });
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
