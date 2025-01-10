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
                Text(
                  controller.error.value,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadStructure,
                  child: const Text('重试 / Retry'),
                ),
              ],
            ),
          );
        }

        // 显示表结构内容
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 字段列表标题
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '字段 / Columns',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 字段列表表格
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('字段名\nField')),
                    DataColumn(label: Text('类型\nType')),
                    DataColumn(label: Text('可空\nNull')),
                    DataColumn(label: Text('键\nKey')),
                    DataColumn(label: Text('默认值\nDefault')),
                    DataColumn(label: Text('注释\nComment')),
                    DataColumn(label: Text('操作\nActions')),
                  ],
                  rows: controller.columns.map((column) {
                    return DataRow(
                      cells: [
                        DataCell(Text(column['Field']?.toString() ?? '')),
                        DataCell(Text(column['Type']?.toString() ?? '')),
                        DataCell(Text(column['Null']?.toString() ?? '')),
                        DataCell(Text(column['Key']?.toString() ?? '')),
                        DataCell(Text(column['Default']?.toString() ?? '')),
                        DataCell(Text(column['Comment']?.toString() ?? '')),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 编辑字段按钮
                              IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: '编辑 / Edit',
                                onPressed: () =>
                                    controller.showEditColumnDialog(column),
                              ),
                              // 删除字段按钮
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: '删除 / Delete',
                                onPressed: () =>
                                    controller.showDeleteColumnDialog(column),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              // 索引列表标题
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '索引 / Indexes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 索引列表表格
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('名称\nName')),
                    DataColumn(label: Text('列\nColumns')),
                    DataColumn(label: Text('类型\nType')),
                    DataColumn(label: Text('操作\nActions')),
                  ],
                  rows: controller.indexes.map((index) {
                    return DataRow(
                      cells: [
                        DataCell(Text(index['Key_name']?.toString() ?? '')),
                        DataCell(Text(index['Column_name']?.toString() ?? '')),
                        DataCell(Text(index['Index_type']?.toString() ?? '')),
                        DataCell(
                          // 删除索引按钮
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: '删除 / Delete',
                            onPressed: () =>
                                controller.showDeleteIndexDialog(index),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
