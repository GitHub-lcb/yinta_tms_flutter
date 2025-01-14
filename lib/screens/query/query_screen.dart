import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/query_controller.dart';
import '../../widgets/sql_editor.dart';

/// SQL查询界面
/// 集成SQL编辑器和查询结果显示，提供一个完整的SQL查询执行环境
class QueryScreen extends GetView<QueryController> {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.code,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'SQL查询 / SQL Query - ${controller.databaseName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // SQL编辑器区域
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SqlEditor(
                onChanged: controller.onQueryChanged,
                onExecute: controller.executeQuery,
                tables: controller.tables,
                columns: controller.columns,
              ),
            ),
          ),
          // 查询结果区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Obx(() {
                  final results = controller.queryResults;
                  if (results.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.code_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '暂无查询结果\nNo query results yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '在编辑器中输入SQL查询语句\nEnter SQL query in the editor',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // 标签页栏
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final result = results[index];
                            final isSelected =
                                index == controller.selectedTabIndex.value;

                            return InkWell(
                              onTap: () => controller.selectTab(index),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 状态图标
                                    Icon(
                                      result.isSuccess
                                          ? Icons.check_circle
                                          : Icons.error,
                                      size: 16,
                                      color: result.isSuccess
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    // SQL预览
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        result.sql,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.grey[700],
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 关闭按钮
                                    InkWell(
                                      onTap: () => controller.closeTab(index),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // 当前选中的查询结果
                      Expanded(
                        child: _buildQueryResult(context,
                            results[controller.selectedTabIndex.value]),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建查询结果显示
  Widget _buildQueryResult(BuildContext context, QueryResult result) {
    if (!result.isSuccess) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red[300],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '查询失败\nQuery Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red[300],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[100]!),
                  ),
                  child: Text(
                    result.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[900],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!result.data.containsKey('columns') ||
        !result.data.containsKey('rows')) {
      return Center(
        child: Text(
          '查询结果格式错误\nInvalid query result format',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 16,
          ),
        ),
      );
    }

    final columns = result.data['columns'] as List;
    final rows = result.data['rows'] as List;

    if (columns.isEmpty) {
      return Center(
        child: Text(
          '查询成功，但没有返回任何列\nQuery successful, but no columns returned',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 16,
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // 工具栏
        SliverToBoxAdapter(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${rows.length} 条记录',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.exportToExcel(),
                    icon: const Icon(Icons.table_chart, size: 18),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green[700],
                      side: BorderSide(color: Colors.green[700]!),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => controller.exportToCsv(),
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[700]!),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // 表格区域
        SliverFillRemaining(
          hasScrollBody: true,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Listener(
              onPointerDown: (event) =>
                  controller.startHorizontalDrag(event.position.dx),
              onPointerMove: (event) =>
                  controller.updateHorizontalDrag(event.position.dx),
              onPointerUp: (event) => controller.endHorizontalDrag(),
              child: SingleChildScrollView(
                controller: controller.horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                    dataRowColor: MaterialStateProperty.resolveWith(
                      (states) => states.contains(MaterialState.hovered)
                          ? Colors.blue[50]
                          : null,
                    ),
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    horizontalMargin: 16,
                    columnSpacing: 32,
                    showBottomBorder: true,
                    columns: columns
                        .map((col) => DataColumn(
                              label: Text(
                                col.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ))
                        .toList(),
                    rows: rows
                        .map((row) => DataRow(
                              cells: (row as List)
                                  .map((value) => DataCell(
                                        Text(
                                          value?.toString() ?? 'NULL',
                                          style: value == null
                                              ? TextStyle(
                                                  color: Colors.grey[400],
                                                  fontStyle: FontStyle.italic,
                                                )
                                              : TextStyle(
                                                  color: Colors.grey[700]),
                                        ),
                                      ))
                                  .toList(),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
