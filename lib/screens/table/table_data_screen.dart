import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'table_data_controller.dart';

/// 表数据界面
/// 显示数据表的内容，支持分页、排序、筛选、搜索、编辑等功能
class TableDataScreen extends GetView<TableDataController> {
  const TableDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.tableName}'),
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
            child: Text(
              controller.error.value,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // 显示空数据提示
        if (controller.data.isEmpty) {
          return const Center(
            child: Text('没有数据 / No data'),
          );
        }

        // 显示数据表格
        return Column(
          children: [
            // 搜索和分页大小选择区域
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // 搜索框
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: '搜索 / Search',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: controller.onSearchChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 每页记录数选择下拉框
                  DropdownButton<int>(
                    value: controller.pageSize.value,
                    items: [10, 20, 50, 100].map((size) {
                      return DropdownMenuItem<int>(
                        value: size,
                        child: Text('$size / 页'),
                      );
                    }).toList(),
                    onChanged: controller.onPageSizeChanged,
                  ),
                ],
              ),
            ),
            // 数据表格区域
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    // 表头列
                    columns: controller.columns.map((column) {
                      return DataColumn(
                        label: Text(column),
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
                            Text(row[column]?.toString() ?? 'NULL'),
                            onTap: () => controller.showEditDialog(row, column),
                          );
                        }).toList(),
                        onLongPress: () => controller.showRowActions(row),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            // 分页控制区域
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 首页按钮
                  IconButton(
                    icon: const Icon(Icons.first_page),
                    onPressed: controller.currentPage.value > 0
                        ? controller.firstPage
                        : null,
                  ),
                  // 上一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: controller.currentPage.value > 0
                        ? controller.previousPage
                        : null,
                  ),
                  // 页码显示
                  Text(
                      '${controller.currentPage.value + 1} / ${controller.totalPages.value}'),
                  // 下一页按钮
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: controller.currentPage.value <
                            controller.totalPages.value - 1
                        ? controller.nextPage
                        : null,
                  ),
                  // 末页按钮
                  IconButton(
                    icon: const Icon(Icons.last_page),
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
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              onTap: () {
                Get.back();
                controller.exportToExcel();
              },
            ),
            // 导出为CSV选项
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV'),
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
