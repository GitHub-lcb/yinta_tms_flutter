import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../services/database/mysql_service.dart';
import '../../../services/database/offline_service.dart';
import '../../../services/database/database_service.dart';
import '../../../utils/dialog_utils.dart';
import '../../../controllers/query_result_controller.dart';

/// 长文本单元格组件
class LongTextCell extends StatelessWidget {
  final String text;
  final int maxLength;

  const LongTextCell({
    super.key,
    required this.text,
    this.maxLength = 50,
  });

  @override
  Widget build(BuildContext context) {
    if (text.length <= maxLength) {
      return Text(text);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${text.substring(0, maxLength)}...',
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'view_full_content'.tr,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('field_content'.tr),
                content: SingleChildScrollView(
                  child: SelectableText(text),
                ),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text('copy'.tr),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      DialogUtils.showSuccess(
                        'copied'.tr,
                        'content_copied'.tr,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('close'.tr),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class QueryResultScreen extends GetView<QueryResultController> {
  const QueryResultScreen({super.key});

  void _showExportDialog(BuildContext context, String query) {
    final mysqlService = Get.find<MySqlService>();
    final offlineService = Get.find<OfflineService>();
    final DatabaseService currentService =
        offlineService.isConnected ? offlineService : mysqlService;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出 / Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 导出为Excel选项
            ListTile(
              leading: Icon(
                Icons.table_chart,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Excel'),
              subtitle: const Text('导出为Excel表格文件 / Export as Excel file'),
              onTap: () async {
                Get.back();
                try {
                  await currentService.exportToExcel(
                    query,
                    'query_result_${DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_')}.xlsx',
                  );
                } catch (e) {
                  DialogUtils.showError(
                    '导出失败 / Export Failed',
                    e.toString(),
                  );
                }
              },
            ),
            const Divider(),
            // 导出为CSV选项
            ListTile(
              leading: Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.secondary,
              ),
              title: const Text('CSV'),
              subtitle: const Text('导出为CSV文本文件 / Export as CSV file'),
              onTap: () async {
                Get.back();
                try {
                  await currentService.exportToCsv(
                    query,
                    'query_result_${DateTime.now().toString().replaceAll(RegExp(r'[^\w]'), '_')}.csv',
                  );
                } catch (e) {
                  DialogUtils.showError(
                    '导出失败 / Export Failed',
                    e.toString(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final query = args['query'] as String;
    final result = args['data'] as Map<String, dynamic>?;
    final scrollController = ScrollController();

    if (result == null ||
        !result.containsKey('columns') ||
        !result.containsKey('rows')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('查询结果 / Query Result'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '没有数据 / No data available',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final columnsList = result['columns'] as List;
    final columns = columnsList.map((col) => (col ?? '').toString()).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('查询结果 / Query Result'),
        elevation: 0,
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: '导出 / Export',
            onPressed: () => _showExportDialog(context, query),
          ),
          // 复制按钮
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制SQL / Copy SQL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: query));
              DialogUtils.showSuccess(
                '复制成功 / Copied',
                'SQL已复制到剪贴板 / SQL copied to clipboard',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // SQL查询语句显示区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SQL Query',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    query,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '共 ${controller.totalRecords} 条记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // 分页大小选择器
                    DropdownButton<int>(
                      value: controller.pageSize.value,
                      items: [10, 20, 50, 100].map((size) {
                        return DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size 条/页'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.changePageSize(value);
                        }
                      },
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 数据表格区域
          Expanded(
            child: Obx(() {
              final rows = controller.currentPageRows;
              return rows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_rows_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '没有数据 / No data available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            scrollController.position.moveTo(
                              scrollController.position.pixels -
                                  details.delta.dx,
                            );
                          },
                          child: SingleChildScrollView(
                            controller: scrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SingleChildScrollView(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dataTableTheme: DataTableThemeData(
                                    headingRowColor: MaterialStateProperty.all(
                                      Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withOpacity(0.1),
                                    ),
                                    dataRowColor:
                                        MaterialStateProperty.resolveWith(
                                      (states) {
                                        if (states
                                            .contains(MaterialState.hovered)) {
                                          return Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.05);
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                child: DataTable(
                                  columns: columns.map((column) {
                                    return DataColumn(
                                      label: Text(
                                        column,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  rows: rows.map((row) {
                                    return DataRow(
                                      cells: List.generate(
                                        columns.length,
                                        (index) {
                                          final value =
                                              row[index]?.toString() ?? '';
                                          return DataCell(
                                            LongTextCell(text: value),
                                          );
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
            }),
          ),

          // 分页控件
          Obx(() {
            if (controller.totalPages <= 1) return const SizedBox.shrink();
            return Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: controller.currentPage.value > 1
                        ? () => controller.changePage(1)
                        : null,
                    icon: const Icon(Icons.first_page),
                    tooltip: '第一页',
                  ),
                  IconButton(
                    onPressed: controller.currentPage.value > 1
                        ? () => controller
                            .changePage(controller.currentPage.value - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '上一页',
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${controller.currentPage.value} / ${controller.totalPages}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                        controller.currentPage.value < controller.totalPages
                            ? () => controller
                                .changePage(controller.currentPage.value + 1)
                            : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '下一页',
                  ),
                  IconButton(
                    onPressed:
                        controller.currentPage.value < controller.totalPages
                            ? () => controller.changePage(controller.totalPages)
                            : null,
                    icon: const Icon(Icons.last_page),
                    tooltip: '最后一页',
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
