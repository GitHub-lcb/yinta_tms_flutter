import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/query_controller.dart';
import '../../widgets/sql_editor.dart';
import '../../widgets/long_text_cell.dart';

/// SQL查询界面
/// 集成SQL编辑器和查询结果显示，提供一个完整的SQL查询执行环境
class QueryScreen extends GetView<QueryController> {
  const QueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化表控制器
    final controller = Get.put(QueryController());

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
                'SQL查询 / SQL Query - $databaseName',
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
            height: MediaQuery.of(context).size.height * 0.45,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 编辑器标题栏
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SQL编辑器 / SQL Editor',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SQL编辑器
                  Expanded(
                    child: SqlEditor(
                      onChanged: controller.onQueryChanged,
                      onExecute: controller.executeQuery,
                      tables: controller.tables,
                      columns: controller.columns,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 查询结果区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 结果区域标题栏
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          // '查询结果 / Query Results',
                          '查询结果',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Obx(() {
                          final results = controller.queryResults;
                          if (results.isEmpty) return const SizedBox();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${results.length} 条结果 / ${results.length} results',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  // 结果内容区域
                  Expanded(
                    child: Obx(() {
                      final results = controller.queryResults;
                      if (results.isEmpty) {
                        return Center(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.code_outlined,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    '暂无查询结果\nNo query results yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '在编辑器中输入SQL查询语句\nEnter SQL query in the editor',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
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
                                          constraints: const BoxConstraints(
                                              maxWidth: 200),
                                          child: Text(
                                            result.sql,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Theme.of(context)
                                                      .primaryColor
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
                                          onTap: () =>
                                              controller.closeTab(index),
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
                ],
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
    final rows = controller.currentPageData;

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
                // 左侧信息区域
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.totalRecords} 条记录',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 分页大小选择器
                        DropdownButton<int>(
                          isDense: true,
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
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 右侧按钮区域
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () => controller.exportToExcel(),
                          icon: const Icon(Icons.table_chart, size: 18),
                          label: const Text('Excel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[700],
                            side: BorderSide(color: Colors.green[700]!),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 数据表格
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Listener(
              onPointerDown: (event) =>
                  controller.startHorizontalDrag(event.position.dx),
              onPointerMove: (event) =>
                  controller.updateHorizontalDrag(event.position.dx),
              onPointerUp: (_) => controller.endHorizontalDrag(),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: controller.horizontalScrollController,
                physics: const NeverScrollableScrollPhysics(), // 禁用默认滚动，使用自定义拖动
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dataTableTheme: DataTableThemeData(
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey[50]),
                      dataRowColor: MaterialStateProperty.all(Colors.white),
                    ),
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    horizontalMargin: 16,
                    columnSpacing: 32,
                    headingRowHeight: 48,
                    dataRowHeight: 52,
                    columns: columns
                        .map((column) => DataColumn(
                              label: Text(
                                column.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                    rows: rows.map<DataRow>((row) {
                      return DataRow(
                        cells: List<DataCell>.generate(
                          columns.length,
                          (index) {
                            final value = row[index]?.toString() ?? '';
                            // 使用LongTextCell处理长文本
                            return DataCell(
                              value.length > 50
                                  ? LongTextCell(text: value)
                                  : Text(value),
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
        // 分页控件
        if (controller.totalPages > 1)
          SliverToBoxAdapter(
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
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
            ),
          ),
      ],
    );
  }
}
