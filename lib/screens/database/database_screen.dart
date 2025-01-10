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
        actions: [
          // 刷新按钮，用于重新加载数据库列表
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadDatabases,
          ),
          // 断开连接按钮
          IconButton(
            icon: const Icon(Icons.logout),
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
                Text(
                  controller.error.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadDatabases,
                  child: const Text('重试 / Retry'),
                ),
              ],
            ),
          );
        }

        // 显示空数据提示
        if (controller.databases.isEmpty) {
          return const Center(
            child: Text('没有找到数据库 / No databases found'),
          );
        }

        // 显示数据库列表
        return ListView.builder(
          itemCount: controller.databases.length,
          itemBuilder: (context, index) {
            final database = controller.databases[index];
            return ListTile(
              leading: const Icon(Icons.storage),
              title: Text(database),
              onTap: () => controller.selectDatabase(database),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        );
      }),
    );
  }
}
