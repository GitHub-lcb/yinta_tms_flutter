import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/query/query_history_service.dart';
import 'query_history_controller.dart';

/// 查询历史界面
/// 显示SQL查询的历史记录，支持查看详情、重新执行、复制和清空历史等功能
class QueryHistoryScreen extends StatelessWidget {
  const QueryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化查询历史控制器
    final controller =
        Get.put(QueryHistoryController(Get.find<QueryHistoryService>()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('查询历史 / Query History'),
        actions: [
          // 清空历史按钮
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '清空历史 / Clear History',
            onPressed: () => _showClearHistoryDialog(context, controller),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: controller.searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '搜索查询 / Search Queries',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.onSearchChanged,
            ),
          ),
          // 历史记录列表
          Expanded(
            child: Obx(() {
              // 显示加载指示器
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // 显示空数据提示
              if (controller.histories.isEmpty) {
                return const Center(
                  child: Text('没有查询历史 / No query history'),
                );
              }

              // 显示历史记录列表
              return ListView.builder(
                itemCount: controller.histories.length,
                itemBuilder: (context, index) {
                  final history = controller.histories[index];
                  return ListTile(
                    title: Text(
                      history.query,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(
                      '${history.database} - ${history.timestamp.toString()}',
                      style: TextStyle(
                        color: history.isSuccess ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 复制查询按钮
                        IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: '复制 / Copy',
                          onPressed: () => controller.copyQuery(history),
                        ),
                        // 重新执行按钮
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: '执行 / Execute',
                          onPressed: () => controller.executeQuery(history),
                        ),
                      ],
                    ),
                    onTap: () => controller.showQueryDetails(history),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  /// 显示清空历史确认对话框
  ///
  /// 参数:
  /// - [context]: 构建上下文
  /// - [controller]: 查询历史控制器
  void _showClearHistoryDialog(
      BuildContext context, QueryHistoryController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空 / Confirm Clear'),
        content: const Text(
          '确定要清空所有查询历史吗？此操作不可撤销。\nAre you sure you want to clear all query history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.clearHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('清空 / Clear'),
          ),
        ],
      ),
    );
  }
}
