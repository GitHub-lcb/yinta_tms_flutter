import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/connection_config.dart';
import '../services/database/mysql_service.dart';
import '../services/database/connection_service.dart';
import '../services/database/offline_service.dart';
import '../utils/dialog_utils.dart';

/// 数据库连接控制器
/// 负责管理数据库连接界面的状态和业务逻辑
class ConnectionController extends GetxController {
  /// MySQL服务实例，用于处理数据库连接操作
  final _mysqlService = Get.find<MySqlService>();

  /// 离线模式服务实例
  final _offlineService = Get.put(OfflineService());

  /// 连接配置服务实例，用于管理保存的连接配置
  final _connectionService = Get.find<ConnectionService>();

  /// 表单Key，用于表单验证
  final formKey = GlobalKey<FormState>();

  /// 主机地址输入控制器
  late final TextEditingController hostController;

  /// 端口号输入控制器
  late final TextEditingController portController;

  /// 用户名输入控制器
  late final TextEditingController userController;

  /// 密码输入控制器
  late final TextEditingController passwordController;

  /// 数据库名称输入控制器
  late final TextEditingController databaseController;

  /// 配置名称输入控制器
  late final TextEditingController nameController;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  /// 密码可见性标志
  final isPasswordVisible = false.obs;

  /// 连接状态标志
  final isConnected = false.obs;

  /// 保存的连接配置列表
  final savedConnections = <ConnectionConfig>[].obs;

  /// 是否为离线模式
  final isOfflineMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    _initControllers();
    _loadSavedConnections();
  }

  /// 初始化输入控制器
  /// 设置默认的连接参数值
  void _initControllers() {
    nameController = TextEditingController();
    hostController = TextEditingController(text: 'localhost');
    portController = TextEditingController(text: '3306');
    userController = TextEditingController(text: 'root');
    passwordController = TextEditingController();
    databaseController = TextEditingController();
  }

  /// 加载保存的连接配置
  Future<void> _loadSavedConnections() async {
    await _connectionService.init();
    savedConnections.value = _connectionService.savedConnections;
  }

  /// 重置输入控制器
  /// 将所有输入字段恢复为默认值
  void _resetControllers() {
    nameController.text = '';
    hostController.text = 'localhost';
    portController.text = '3306';
    userController.text = 'root';
    passwordController.text = '';
    databaseController.text = '';
  }

  @override
  void onClose() {
    // 释放输入控制器资源
    nameController.dispose();
    hostController.dispose();
    portController.dispose();
    userController.dispose();
    passwordController.dispose();
    databaseController.dispose();
    super.onClose();
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// 切换离线模式
  void toggleOfflineMode() {
    if (kIsWeb) {
      Get.snackbar(
        '不支持 / Not Supported',
        'Web版本不支持离线模式 / Offline mode is not supported in Web version',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
      return;
    }
    isOfflineMode.value = !isOfflineMode.value;
  }

  /// 创建连接配置对象
  ConnectionConfig _createConfig() {
    return ConnectionConfig(
      name: nameController.text.trim(),
      host: hostController.text.trim(),
      port: int.parse(portController.text.trim()),
      user: userController.text.trim(),
      password: passwordController.text,
      database: databaseController.text.trim().isNotEmpty
          ? databaseController.text.trim()
          : null,
      isOffline: !kIsWeb && isOfflineMode.value,
    );
  }

  /// 测试连接
  /// 测试当前输入的连接配置是否有效
  Future<void> testConnection() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    error.value = '';

    try {
      final config = _createConfig();
      final success = config.isOffline
          ? await _offlineService.testConnection(config)
          : await _mysqlService.testConnection(config);

      if (success) {
        DialogUtils.showSuccess(
          '测试成功 / Test Success',
          '连接测试成功 / Connection test successful',
        );
      }
    } catch (e) {
      error.value = e.toString();
      DialogUtils.showError(
        '测试失败 / Test Failed',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 保存连接配置
  Future<void> saveConnection() async {
    if (!formKey.currentState!.validate()) return;
    if (nameController.text.trim().isEmpty) {
      DialogUtils.showError(
        '错误 / Error',
        '请输入配置名称 / Please enter configuration name',
      );
      return;
    }

    try {
      final config = _createConfig();
      await _connectionService.saveConnection(config);
      await _loadSavedConnections();
      DialogUtils.showSuccess(
        '保存成功 / Save Success',
        '连接配置已保存 / Connection configuration saved',
      );
    } catch (e) {
      DialogUtils.showError(
        '保存失败 / Save Failed',
        e.toString(),
      );
    }
  }

  /// 加载保存的连接配置
  void loadSavedConnection(ConnectionConfig config) {
    nameController.text = config.name;
    hostController.text = config.host;
    portController.text = config.port.toString();
    userController.text = config.user;
    passwordController.text = config.password;
    databaseController.text = config.database ?? '';
  }

  /// 删除保存的连接配置
  Future<void> deleteSavedConnection(String name) async {
    try {
      await _connectionService.deleteConnection(name);
      await _loadSavedConnections();
      DialogUtils.showSuccess(
        '删除成功 / Delete Success',
        '连接配置已删除 / Connection configuration deleted',
      );
    } catch (e) {
      DialogUtils.showError(
        '删除失败 / Delete Failed',
        e.toString(),
      );
    }
  }

  /// 连接到数据库
  /// 验证表单，创建连接配置，并尝试建立连接
  Future<void> connect() async {
    // 验证表单输入
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    error.value = '';

    try {
      final config = _createConfig();

      if (config.isOffline) {
        await _offlineService.connect(config);
      } else {
        await _mysqlService.connect(config);
      }

      isConnected.value = true;

      if (config.database != null) {
        Get.toNamed('/tables', arguments: config.database);
      } else {
        Get.toNamed('/databases');
      }

      DialogUtils.showSuccess(
        '连接成功 / Connected',
        '已连接到数据库 / Connected to database',
      );
    } catch (e) {
      error.value = e.toString();
      DialogUtils.showError(
        '连接失败 / Connection Failed',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 断开数据库连接
  /// 关闭当前的数据库连接并返回上一页
  Future<void> disconnect() async {
    try {
      if (isOfflineMode.value) {
        await _offlineService.disconnect();
      } else {
        await _mysqlService.disconnect();
      }

      DialogUtils.showSuccess(
        '断开连接 / Disconnected',
        '已成功断开连接 / Successfully disconnected',
      );
      Get.back();
    } catch (e) {
      DialogUtils.showError(
        '错误 / Error',
        e.toString(),
      );
    }
  }
}
