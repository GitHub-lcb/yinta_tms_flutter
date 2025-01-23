import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../utils/dialog_utils.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// 表结构控制器
/// 负责管理表结构界面的状态和业务逻辑，包括查看和修改表结构、管理索引等功能
class TableStructureController extends GetxController {
  /// MySQL服务实例
  final _mysqlService = Get.find<MySqlService>();

  /// 离线服务实例
  final _offlineService = Get.find<OfflineService>();

  /// 表字段列表
  final columns = <Map<String, dynamic>>[].obs;

  /// 表索引列表
  final indexes = <Map<String, dynamic>>[].obs;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  /// 当前数据库名称
  late final String databaseName;

  /// 当前表名
  late final String tableName;

  /// 获取当前服务实例
  dynamic get _currentService =>
      _offlineService.isConnected ? _offlineService : _mysqlService as dynamic;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据库名和表名
    final args = Get.arguments as Map<String, dynamic>;
    databaseName = args['database'] as String;
    tableName = args['table'] as String;
    loadStructure();
  }

  /// 加载表结构信息
  /// 获取表的字段信息和索引信息
  Future<void> loadStructure() async {
    isLoading.value = true;
    error.value = '';

    try {
      // 获取表字段结构
      final structureResult = await _currentService.getTableStructure(
        databaseName,
        tableName,
      );
      columns.value = structureResult;

      // 获取表索引信息
      final indexesResult = await _currentService.getTableIndexes(
        databaseName,
        tableName,
      );
      indexes.value = indexesResult;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 显示添加字段对话框
  /// 允许用户添加新的表字段
  Future<void> showAddColumnDialog() async {
    // 创建表单控制器
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isNullable = false;
    String? defaultValue;

    // 显示添加字段对话框
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('添加字段 / Add Column'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 字段名输入框
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '字段名 / Field Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入字段名 / Please enter field name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 字段类型输入框
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: '类型 / Type',
                    hintText: 'VARCHAR(255), INT, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入类型 / Please enter type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 是否可空选项
                StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: const Text('可空 / Nullable'),
                      value: isNullable,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => isNullable = value);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // 字段注释输入框
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: '注释 / Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back(result: true);
              }
            },
            child: const Text('添加 / Add'),
          ),
        ],
      ),
    );

    // 如果用户点击了添加按钮
    if (result == true) {
      try {
        // 构建ALTER TABLE SQL语句
        final sql = '''
          ALTER TABLE `$databaseName`.`$tableName`
          ADD COLUMN `${nameController.text}` ${typeController.text}
          ${isNullable ? 'NULL' : 'NOT NULL'}
          ${defaultValue != null ? 'DEFAULT $defaultValue' : ''}
          ${commentController.text.isNotEmpty ? "COMMENT '${commentController.text}'" : ''}
        ''';

        // 执行修改表结构的操作
        await _currentService.alterTable(databaseName, tableName, sql);
        await loadStructure();
        DialogUtils.showSuccess(
          '成功 / Success',
          '字段已添加 / Column added',
        );
      } catch (e) {
        DialogUtils.showError(
          '错误 / Error',
          e.toString(),
        );
      }
    }
  }

  /// 显示编辑字段对话框
  /// 允许用户修改现有的表字段
  ///
  /// 参数:
  /// - [column]: 要编辑的字段信息
  Future<void> showEditColumnDialog(Map<String, dynamic> column) async {
    // 创建表单控制器并设置初始值
    final nameController =
        TextEditingController(text: column['Field']?.toString() ?? '');
    final typeController =
        TextEditingController(text: column['Type']?.toString() ?? '');
    final commentController =
        TextEditingController(text: column['Comment']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool isNullable = column['Null']?.toString() == 'YES';

    // 显示编辑字段对话框
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('编辑字段 / Edit Column'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 字段名输入框
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '字段名 / Field Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入字段名 / Please enter field name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 字段类型输入框
                TextFormField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: '类型 / Type',
                    hintText: 'VARCHAR(255), INT, etc.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入类型 / Please enter type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // 是否可空选项
                StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: const Text('可空 / Nullable'),
                      value: isNullable,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => isNullable = value);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // 字段注释输入框
                TextFormField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: '注释 / Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Get.back(result: true);
              }
            },
            child: const Text('保存 / Save'),
          ),
        ],
      ),
    );

    // 如果用户点击了保存按钮
    if (result == true) {
      try {
        // 构建MODIFY COLUMN SQL语句
        final sql = '''
          ALTER TABLE `$databaseName`.`$tableName`
          MODIFY COLUMN `${nameController.text}` ${typeController.text}
          ${isNullable ? 'NULL' : 'NOT NULL'}
          ${commentController.text.isNotEmpty ? "COMMENT '${commentController.text}'" : ''}
        ''';

        // 执行修改表结构的操作
        await _currentService.alterTable(databaseName, tableName, sql);
        await loadStructure();
        DialogUtils.showSuccess(
          '成功 / Success',
          '字段已更新 / Column updated',
        );
      } catch (e) {
        DialogUtils.showError(
          '错误 / Error',
          e.toString(),
        );
      }
    }
  }

  /// 删除字段
  ///
  /// 参数:
  /// - [column]: 要删除的字段信息
  Future<void> deleteColumn(Map<String, dynamic> column) async {
    try {
      // 构建DROP COLUMN SQL语句
      final sql = '''
        ALTER TABLE `$databaseName`.`$tableName`
        DROP COLUMN `${column['Field']}`
      ''';

      // 执行删除字段操作
      await _currentService.alterTable(databaseName, tableName, sql);
      await loadStructure();
      DialogUtils.showSuccess(
        '成功 / Success',
        '字段已删除 / Column deleted',
      );
    } catch (e) {
      DialogUtils.showError(
        '错误 / Error',
        e.toString(),
      );
    }
  }

  /// 显示删除字段确认对话框
  ///
  /// 参数:
  /// - [column]: 要删除的字段信息
  Future<void> showDeleteColumnDialog(Map<String, dynamic> column) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('确认删除 / Confirm Delete'),
        content: Text(
          '确定要删除字段 "${column['Field']}" 吗？此操作不可撤销。\nAre you sure you want to delete column "${column['Field']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除 / Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteColumn(column);
    }
  }

  /// 显示添加索引对话框
  /// 允许用户添加新的表索引
  Future<void> showAddIndexDialog() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedColumns = <String>[].obs;
    bool isUnique = false;

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('添加索引 / Add Index'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '索引名 / Index Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入索引名 / Please enter index name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('选择列 / Select Columns:'),
                const SizedBox(height: 8),
                Obx(() {
                  return Column(
                    children: columns.map((column) {
                      final fieldName = column['Field'] as String;
                      return CheckboxListTile(
                        title: Text(fieldName),
                        value: selectedColumns.contains(fieldName),
                        onChanged: (checked) {
                          if (checked == true) {
                            selectedColumns.add(fieldName);
                          } else {
                            selectedColumns.remove(fieldName);
                          }
                        },
                      );
                    }).toList(),
                  );
                }),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: const Text('唯一索引 / Unique Index'),
                      value: isUnique,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => isUnique = value);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() &&
                  selectedColumns.isNotEmpty) {
                Get.back(result: true);
              } else if (selectedColumns.isEmpty) {
                DialogUtils.showError(
                  '错误 / Error',
                  '请选择至少一列 / Please select at least one column',
                );
              }
            },
            child: const Text('添加 / Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final sql = '''
          ALTER TABLE `$databaseName`.`$tableName`
          ADD ${isUnique ? 'UNIQUE' : ''} INDEX `${nameController.text}` (${selectedColumns.map((col) => '`$col`').join(', ')})
        ''';

        await _currentService.alterTable(databaseName, tableName, sql);
        await loadStructure();
        DialogUtils.showSuccess(
          '成功 / Success',
          '索引已添加 / Index added',
        );
      } catch (e) {
        DialogUtils.showError(
          '错误 / Error',
          e.toString(),
        );
      }
    }
  }

  /// 显示删除索引对话框
  /// 允许用户删除现有的表索引
  ///
  /// 参数:
  /// - [index]: 要删除的索引信息
  Future<void> showDeleteIndexDialog(Map<String, dynamic> index) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('确认删除 / Confirm Delete'),
        content: Text(
          '确定要删除索引 "${index['Key_name']}" 吗？此操作不可撤销。\nAre you sure you want to delete index "${index['Key_name']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除 / Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final sql = '''
          ALTER TABLE `$databaseName`.`$tableName`
          DROP INDEX `${index['Key_name']}`
        ''';

        await _currentService.alterTable(databaseName, tableName, sql);
        await loadStructure();
        DialogUtils.showSuccess(
          '成功 / Success',
          '索引已删除 / Index deleted',
        );
      } catch (e) {
        DialogUtils.showError(
          '错误 / Error',
          e.toString(),
        );
      }
    }
  }

  /// 显示建表语句对话框
  /// 获取并显示当前表的建表语句
  Future<void> showCreateTableStatement() async {
    try {
      isLoading.value = true;
      error.value = '';

      // 获取建表语句
      final statement = await _currentService.getCreateTableStatement(
        databaseName,
        tableName,
      );

      // 显示对话框
      Get.dialog(
        AlertDialog(
          title: const Text('建表语句 / Create Table Statement'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              child: SelectableText(
                statement,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('复制 / Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: statement));
                DialogUtils.showSuccess(
                  '复制成功 / Copied',
                  '建表语句已复制到剪贴板 / Create table statement copied to clipboard',
                );
                Get.back();
              },
            ),
            TextButton(
              child: const Text('关闭 / Close'),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      );
    } catch (e) {
      error.value = e.toString();
      DialogUtils.showError(
        '获取建表语句失败 / Failed to get create table statement',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
