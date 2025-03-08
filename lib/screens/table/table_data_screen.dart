import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/table_data_controller.dart';

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
          // 性能演示模式下的应急按钮（无论界面多卡都能点击此按钮恢复）
          Obx(() => controller.isPerformanceDemo.value &&
                  !controller.useLazyLoading.value
              ? IconButton(
                  icon: const Icon(Icons.emergency, color: Colors.red),
                  tooltip: '应急恢复按钮 / Emergency Recovery',
                  onPressed: () {
                    // 直接切回懒加载模式
                    controller.useLazyLoading.value = true;
                  },
                )
              : const SizedBox.shrink()),
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
          // 性能演示按钮
          IconButton(
            icon: const Icon(Icons.speed),
            tooltip: '性能演示 / Performance Demo',
            onPressed: () => _showPerformanceDemoDialog(context),
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

        // 性能演示模式
        if (controller.isPerformanceDemo.value) {
          return _buildPerformanceDemoView(context);
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
                  // SQL查询输入框
                  Expanded(
                    child: TextField(
                      controller: controller.searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.code),
                        hintText: '输入SQL查询语句 / Enter SQL query',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          tooltip: '执行查询 / Execute query',
                          onPressed: () => controller.executeCustomQuery(
                              controller.searchController.text),
                        ),
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
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      onSubmitted: controller.executeCustomQuery,
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

  /// 构建性能演示对话框
  void _showPerformanceDemoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性能演示 / Performance Demo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '这将生成10万行数据用于演示Flutter的渲染性能。\n'
              '您可以切换普通渲染和懒加载渲染模式来体验性能差异。',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.yellow[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.yellow[900]),
                      const SizedBox(width: 8),
                      const Text(
                        '警告',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 普通渲染模式会尝试一次性渲染大量数据，将导致严重卡顿\n'
                    '• 如果界面完全无响应，可点击顶部红色"应急恢复"按钮\n'
                    '• 为防止应用崩溃，普通渲染模式最多显示10000行数据',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.generateLargeDataset();
            },
            child: const Text('开始演示 / Start Demo'),
          ),
        ],
      ),
    );
  }

  /// 构建性能演示视图
  Widget _buildPerformanceDemoView(BuildContext context) {
    return Column(
      children: [
        // 演示控制面板
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚀 Flutter 性能优化演示',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '共 ${controller.largeDataset.length} 行数据',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              // 添加说明文字
              Text(
                controller.useLazyLoading.value
                    ? '当前使用懒加载模式，只有可见的项目才会被渲染，滚动应该很流畅'
                    : '当前使用普通渲染模式，所有数据都会一次性渲染，可能会导致严重卡顿',
                style: TextStyle(
                  color: controller.useLazyLoading.value
                      ? Colors.green[700]
                      : Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              // 警告提示
              if (!controller.useLazyLoading.value)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.red[700], size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '警告：如果界面卡死，请点击顶部红色"应急恢复"按钮切回懒加载模式',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 切换渲染模式按钮
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(controller.useLazyLoading.value
                          ? Icons.view_list
                          : Icons.grid_view),
                      label: Text(
                        controller.useLazyLoading.value
                            ? '懒加载模式（ListView.builder）'
                            : '普通渲染模式（直接渲染全部）',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: controller.useLazyLoading.value
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: controller.toggleLazyLoading,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 退出演示按钮
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: '退出演示 / Exit Demo',
                    onPressed: controller.exitPerformanceDemo,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[100],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 数据显示区域
        Expanded(
          child: controller.useLazyLoading.value
              ? _buildLazyLoadingView(context)
              : _buildNormalRenderingView(context),
        ),
      ],
    );
  }

  /// 构建懒加载视图（ListView.builder）
  Widget _buildLazyLoadingView(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        itemCount: controller.largeDataset.length,
        itemBuilder: (context, index) {
          final row = controller.largeDataset[index];
          return ListTile(
            title: Text('行 ${index + 1}'),
            subtitle: Text(
              controller.columns
                  .map((column) => '${column}: ${row[column]}')
                  .join(', '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _showRowDetailsDialog(context, row),
          );
        },
      ),
    );
  }

  /// 构建普通渲染视图（直接渲染全部数据）
  Widget _buildNormalRenderingView(BuildContext context) {
    // 限制一次性渲染的数据量，以防完全卡死
    const int maxRenderedItems = 10000; // 最多只渲染1万行，防止应用完全无响应
    final dataToShow = controller.largeDataset.length > maxRenderedItems
        ? controller.largeDataset.sublist(0, maxRenderedItems)
        : controller.largeDataset;

    return Column(
      children: [
        // 警告提示条
        if (controller.largeDataset.length > maxRenderedItems)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '为防止应用完全卡死，仅显示前 $maxRenderedItems 行数据。'
                    '完整数据共 ${controller.largeDataset.length} 行。'
                    '请使用懒加载模式查看所有数据。',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              ],
            ),
          ),

        // 数据显示区域
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                children: dataToShow.map((row) {
                  return ListTile(
                    title:
                        Text('行 ${controller.largeDataset.indexOf(row) + 1}'),
                    subtitle: Text(
                      controller.columns
                          .map((column) => '${column}: ${row[column]}')
                          .join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _showRowDetailsDialog(context, row),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 显示行详情对话框
  void _showRowDetailsDialog(BuildContext context, Map<String, dynamic> row) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('行详情 / Row Details'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: controller.columns.map((column) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$column: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text('${row[column]}'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭 / Close'),
          ),
        ],
      ),
    );
  }
}
