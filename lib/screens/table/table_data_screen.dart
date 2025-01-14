import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'table_data_controller.dart';

/// 表数据界面
/// 显示数据表的内容，支持分页、排序、筛选、搜索、编辑等功能
class TableDataScreen extends GetView<TableDataController> {
  const TableDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.tableName}'),
        elevation: 0,
        actions: [
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出 / Export',
            onPressed: () => _showExportDialog(context),
          ),
          // 筛选按钮
          IconButton(
            icon: const Icon(Icons.filter_alt),
            tooltip: '筛选 / Filter',
            onPressed: () => controller.showFilterDialog(),
          ),
          // 添加记录按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加 / Add',
            onPressed: () => controller.showAddDialog(),
          ),
          // 查看表结构按钮
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: '表结构 / Table Structure',
            onPressed: () => Get.toNamed(
              '/table-structure',
              arguments: {
                'database': controller.databaseName,
                'table': controller.tableName,
              },
            ),
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
                  onPressed: controller.loadData,
                ),
              ],
            ),
          );
        }

        // 显示空数据提示
        if (controller.data.isEmpty) {
          return Center(
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
                  '没有数据 / No data',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 显示数据表格
        return Column(
          children: [
            // 搜索和分页大小选择区域
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
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: '搜索 / Search',
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
                  const SizedBox(width: 16),
                  // 每页记录数选择下拉框
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: controller.pageSize.value,
                        items: [10, 20, 50, 100].map((size) {
                          return DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size / 页'),
                          );
                        }).toList(),
                        onChanged: controller.onPageSizeChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 数据表格区域
            Expanded(
              child: Card(
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
                              dataRowColor: MaterialStateProperty.resolveWith(
                                (states) {
                                  if (states.contains(MaterialState.hovered)) {
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
                            // 表头列
                            columns: controller.columns.map((column) {
                              return DataColumn(
                                label: Text(
                                  column,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                onSort: (columnIndex, ascending) {
                                  controller.onSort(column, ascending);
                                },
                              );
                            }).toList(),
                            // 数据行
                            rows: controller.data.map((row) {
                              return DataRow(
                                cells: controller.columns.map((column) {
                                  return DataCell(
                                    Text(
                                      row[column]?.toString() ?? 'NULL',
                                      style: TextStyle(
                                        color: row[column] == null
                                            ? Colors.grey[500]
                                            : null,
                                        fontStyle: row[column] == null
                                            ? FontStyle.italic
                                            : null,
                                      ),
                                    ),
                                    onTap: () =>
                                        controller.showEditDialog(row, column),
                                  );
                                }).toList(),
                                onLongPress: () =>
                                    controller.showRowActions(row),
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

            // 分页控制区域
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
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
                  // 首页按钮
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    tooltip: '首页 / First Page',
                    onPressed: controller.currentPage.value > 0
                        ? controller.firstPage
                        : null,
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '上一页 / Previous Page',
                    onPressed: controller.currentPage.value > 0
                        ? controller.previousPage
                        : null,
                  ),
                  // 页码显示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.currentPage.value + 1} / ${controller.totalPages.value}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // 下一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '下一页 / Next Page',
                    onPressed: controller.currentPage.value <
                            controller.totalPages.value - 1
                        ? controller.nextPage
                        : null,
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
                    tooltip: '末页 / Last Page',
                    onPressed: controller.currentPage.value <
                            controller.totalPages.value - 1
                        ? controller.lastPage
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// 显示导出对话框
  /// 提供Excel和CSV两种导出格式选项
  ///
  /// 参数:
  /// - [context]: 构建上下文
  void _showExportDialog(BuildContext context) {
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
              onTap: () {
                Get.back();
                controller.exportToExcel();
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
              onTap: () {
                Get.back();
                controller.exportToCsv();
              },
            ),
          ],
        ),
      ),
    );
  }
}
