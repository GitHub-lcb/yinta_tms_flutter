import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'table_structure_controller.dart';

/// 表结构界面
/// 显示和管理数据表的结构信息，包括字段和索引的查看、添加、编辑和删除功能
class TableStructureScreen extends GetView<TableStructureController> {
  const TableStructureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${controller.tableName} 结构 / Structure'),
        elevation: 0,
        actions: [
          // 添加字段按钮
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加字段 / Add Column',
            onPressed: controller.showAddColumnDialog,
          ),
          // 添加索引按钮
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: '添加索引 / Add Index',
            onPressed: controller.showAddIndexDialog,
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
                  onPressed: controller.loadStructure,
                ),
              ],
            ),
          );
        }

        // 显示表结构内容
        return CustomScrollView(
          slivers: [
            // 字段列表标题
            SliverToBoxAdapter(
              child: Container(
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
                    Row(
                      children: [
                        Icon(
                          Icons.table_chart,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '字段 / Columns',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${controller.columns.length} 个字段',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 字段列表
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
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
                        columns: const [
                          DataColumn(
                            label: Text(
                              '字段名\nField',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '类型\nType',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '可空\nNull',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '键\nKey',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '默认值\nDefault',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '注释\nComment',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '操作\nActions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: controller.columns.map((column) {
                          return DataRow(
                            cells: [
                              DataCell(Text(column['Field']?.toString() ?? '')),
                              DataCell(
                                Text(
                                  column['Type']?.toString() ?? '',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  column['Null']?.toString() ?? '',
                                  style: TextStyle(
                                    color: column['Null'] == 'YES'
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  column['Key']?.toString() ?? '',
                                  style: TextStyle(
                                    color:
                                        column['Key']?.toString().isNotEmpty ==
                                                true
                                            ? Colors.blue
                                            : null,
                                    fontWeight:
                                        column['Key']?.toString().isNotEmpty ==
                                                true
                                            ? FontWeight.bold
                                            : null,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  column['Default']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              DataCell(
                                  Text(column['Comment']?.toString() ?? '')),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      tooltip: '编辑 / Edit',
                                      onPressed: () => controller
                                          .showEditColumnDialog(column),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      tooltip: '删除 / Delete',
                                      onPressed: () =>
                                          controller.deleteColumn(column),
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 索引列表标题
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 16),
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
                  children: [
                    Icon(
                      Icons.key,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '索引 / Indexes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.indexes.length} 个索引',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 索引列表
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dataTableTheme: DataTableThemeData(
                          headingRowColor: MaterialStateProperty.all(
                            Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withOpacity(0.1),
                          ),
                          dataRowColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withOpacity(0.05);
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      child: DataTable(
                        columns: const [
                          DataColumn(
                            label: Text(
                              '名称\nName',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '列\nColumns',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '类型\nType',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              '操作\nActions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: controller.indexes.map((index) {
                          final isUnique =
                              index['Non_unique']?.toString() == '0';
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  index['Key_name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  index['Column_name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isUnique)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'UNIQUE',
                                          style: TextStyle(
                                            color: Colors.blue[900],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (isUnique) const SizedBox(width: 8),
                                    Text(index['Index_type']?.toString() ?? ''),
                                  ],
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  tooltip: '删除 / Delete',
                                  onPressed: () =>
                                      controller.showDeleteIndexDialog(index),
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
