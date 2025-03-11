import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/table_controller.dart';

/// 数据表列表界面
/// 显示当前数据库中所有的数据表，并提供查看表数据、编辑表结构和执行SQL查询等功能
class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化表控制器
    final controller = Get.put(TableController());

    // 更健壮的参数处理方式
    String databaseName;
    if (Get.arguments is String) {
      databaseName = Get.arguments as String;
    } else if (Get.arguments is Map) {
      // 尝试从Map中获取数据库名称
      final argsMap = Get.arguments as Map;
      if (argsMap.containsKey('database')) {
        databaseName = argsMap['database'].toString();
      } else if (argsMap.values.isNotEmpty && argsMap.values.first is String) {
        databaseName = argsMap.values.first.toString();
      } else {
        databaseName = '未知数据库';
      }
    } else {
      databaseName = '未知数据库';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$databaseName / Tables'),
        elevation: 0,
        actions: [
          // 查询历史按钮
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '查询历史 / Query History',
            onPressed: () => Get.toNamed('/query-history'),
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新 / Refresh',
            onPressed: controller.loadTables,
          ),
        ],
      ),
      body: Obx(() {
        // 显示加载指示器
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 显示错误信息
        if (controller.error.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.error.value,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试 / Retry'),
                  onPressed: controller.loadTables,
                ),
              ],
            ),
          );
        }

        // 显示空数据提示
        if (controller.tables.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到表格 / No tables found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 显示表格列表
        return Column(
          children: [
            // 搜索框
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'table_search'.tr,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: controller.searchTables,
                ),
              ),
            ),
            // 表格列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.tables.length,
                itemBuilder: (context, index) {
                  final table = controller.tables[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => controller.selectTable(table),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 表格图标
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.tag_faces,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 表格名称
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    table,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '点击查看详情 / Click to view details',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // 操作按钮
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 查看表数据按钮
                                IconButton(
                                  icon: Icon(
                                    Icons.visibility,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  tooltip: '查看数据 / View Data',
                                  onPressed: () =>
                                      controller.viewTableData(table),
                                ),
                                // 编辑表结构按钮
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  tooltip: '编辑结构 / Edit Structure',
                                  onPressed: () => controller.editTable(table),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // 分页控件
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    tooltip: '第一页 / First Page',
                    onPressed: controller.currentPage.value > 1
                        ? () => controller.changePage(1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '上一页 / Previous Page',
                    onPressed: controller.currentPage.value > 1
                        ? controller.previousPage
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${controller.currentPage.value} / ${(controller.totalTables.value / controller.pageSize.value).ceil()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '下一页 / Next Page',
                    onPressed: controller.currentPage.value <
                            (controller.totalTables.value /
                                    controller.pageSize.value)
                                .ceil()
                        ? controller.nextPage
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    tooltip: '最后一页 / Last Page',
                    onPressed: controller.currentPage.value <
                            (controller.totalTables.value /
                                    controller.pageSize.value)
                                .ceil()
                        ? () => controller.changePage(
                            (controller.totalTables.value /
                                    controller.pageSize.value)
                                .ceil())
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
      // SQL查询悬浮按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.showQueryDialog,
        icon: const Icon(Icons.coffee),
        // label: const Text('SQL 查询 / Query'),
        label: Text('sql_query'.tr),
        tooltip: '执行 SQL 查询 / Execute SQL Query',
      ),
    );
  }
}
