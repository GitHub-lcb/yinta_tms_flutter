import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../services/database/mysql_service.dart';
import '../../../services/database/offline_service.dart';
import '../../../services/database/database_service.dart';

class QueryResultScreen extends StatelessWidget {
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
                  Get.snackbar(
                    '导出失败 / Export Failed',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade100,
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
                  Get.snackbar(
                    '导出失败 / Export Failed',
                    e.toString(),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red.shade100,
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
    final rows = result['rows'] as List;

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
              Get.snackbar(
                '复制成功 / Copied',
                'SQL已复制到剪贴板 / SQL copied to clipboard',
                snackPosition: SnackPosition.BOTTOM,
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
                Text(
                  '${rows.length} 条记录 / records',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          // 数据表格区域
          Expanded(
            child: rows.isEmpty
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
                            scrollController.position.pixels - details.delta.dx,
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
                                      (index) => DataCell(
                                        Text(
                                          row[index]?.toString() ?? '',
                                          style: TextStyle(
                                            color: row[index] == null
                                                ? Colors.grey[400]
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
