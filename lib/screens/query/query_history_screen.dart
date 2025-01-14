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
        elevation: 0,
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '搜索查询 / Search Queries',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '没有查询历史 / No query history',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // 显示历史记录列表
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.histories.length,
                itemBuilder: (context, index) {
                  final history = controller.histories[index];
                  final isSuccess = history.isSuccess;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => controller.showQueryDetails(history),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 查询语句和状态指示器
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              border: Border(
                                left: BorderSide(
                                  color: isSuccess ? Colors.green : Colors.red,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        history.query,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSuccess
                                            ? Colors.green[100]
                                            : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSuccess
                                                ? Icons.check_circle
                                                : Icons.error,
                                            color: isSuccess
                                                ? Colors.green[900]
                                                : Colors.red[900],
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isSuccess ? '成功' : '失败',
                                            style: TextStyle(
                                              color: isSuccess
                                                  ? Colors.green[900]
                                                  : Colors.red[900],
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.storage,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      history.database,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      history.timestamp.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (isSuccess) ...[
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.table_rows,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${history.rowsAffected} 行',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // 操作按钮
                          ButtonBar(
                            buttonPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy, size: 18),
                                label: const Text('复制 / Copy'),
                                onPressed: () => controller.copyQuery(history),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('执行 / Execute'),
                                onPressed: () =>
                                    controller.executeQuery(history),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
              foregroundColor: Colors.white,
            ),
            child: const Text('清空 / Clear'),
          ),
        ],
      ),
    );
  }
}
