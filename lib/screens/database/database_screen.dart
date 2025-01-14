import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'database_controller.dart';

/// 数据库列表界面
/// 显示当前MySQL服务器中所有可用的数据库列表，并提供数据库选择功能
class DatabaseScreen extends StatelessWidget {
  const DatabaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化数据库控制器
    final controller = Get.put(DatabaseController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据库列表 / Databases'),
        elevation: 0,
        actions: [
          // 刷新按钮，用于重新加载数据库列表
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新 / Refresh',
            onPressed: controller.loadDatabases,
          ),
          // 断开连接按钮
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '断开连接 / Disconnect',
            onPressed: () {
              controller.disconnect();
              Get.back();
            },
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
                  onPressed: controller.loadDatabases,
                ),
              ],
            ),
          );
        }

        // 显示空数据提示
        if (controller.databases.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.storage_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '没有找到数据库 / No databases found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 显示数据库列表
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.databases.length,
          itemBuilder: (context, index) {
            final database = controller.databases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => controller.selectDatabase(database),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // 数据库图标
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.storage,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 数据库名称
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              database,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击查看表格 / Click to view tables',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 箭头图标
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
