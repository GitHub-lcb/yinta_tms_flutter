import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'table_controller.dart';

/// 数据表列表界面
/// 显示当前数据库中所有的数据表，并提供查看表数据、编辑表结构和执行SQL查询等功能
class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化表控制器
    final controller = Get.put(TableController());
    // 获取从路由传递的数据库名称
    final databaseName = Get.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('$databaseName / Tables'),
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
            onPressed: controller.loadTables,
          ),
        ],
      ),
      body: Obx(() {
        // 显示加载指示器
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 显示错误信息和重试按钮
        if (controller.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.error.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadTables,
                  child: const Text('重试 / Retry'),
                ),
              ],
            ),
          );
        }

        // 显示空数据提示
        if (controller.tables.isEmpty) {
          return const Center(
            child: Text('没有找到表格 / No tables found'),
          );
        }

        // 显示表格列表
        return ListView.builder(
          itemCount: controller.tables.length,
          itemBuilder: (context, index) {
            final table = controller.tables[index];
            return ListTile(
              leading: const Icon(Icons.table_chart),
              title: Text(table),
              onTap: () => controller.selectTable(table),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 查看表数据按钮
                  IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () => controller.viewTableData(table),
                  ),
                  // 编辑表结构按钮
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => controller.editTable(table),
                  ),
                ],
              ),
            );
          },
        );
      }),
      // SQL查询悬浮按钮
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showQueryDialog,
        child: const Icon(Icons.code),
        tooltip: '执行 SQL 查询 / Execute SQL Query',
      ),
    );
  }
}
