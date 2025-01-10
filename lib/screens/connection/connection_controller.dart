import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/connection_config.dart';
import '../../services/database/mysql_service.dart';

/// 数据库连接控制器
/// 负责管理数据库连接界面的状态和业务逻辑
class ConnectionController extends GetxController {
  /// MySQL服务实例，用于处理数据库连接操作
  final _mysqlService = Get.find<MySqlService>();

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

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  /// 密码可见性标志
  final isPasswordVisible = false.obs;

  /// 连接状态标志
  final isConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initControllers();
  }

  /// 初始化输入控制器
  /// 设置默认的连接参数值
  void _initControllers() {
    hostController = TextEditingController(text: 'localhost');
    portController = TextEditingController(text: '3306');
    userController = TextEditingController(text: 'root');
    passwordController = TextEditingController();
  }

  /// 重置输入控制器
  /// 将所有输入字段恢复为默认值
  void _resetControllers() {
    hostController.text = 'localhost';
    portController.text = '3306';
    userController.text = 'root';
    passwordController.text = '';
  }

  @override
  void onClose() {
    // 释放输入控制器资源
    hostController.dispose();
    portController.dispose();
    userController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// 切换密码可见性
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// 连接到数据库
  /// 验证表单，创建连接配置，并尝试建立连接
  Future<void> connect() async {
    // 验证表单输入
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    error.value = '';

    try {
      // 创建连接配置
      final config = ConnectionConfig(
        host: hostController.text,
        port: int.parse(portController.text),
        user: userController.text,
        password: passwordController.text,
      );

      // 尝试连接数据库
      await _mysqlService.connect(config);
      isConnected.value = true;
      // 连接成功后跳转到数据库列表页面
      Get.toNamed('/databases');
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 断开数据库连接
  /// 关闭当前的数据库连接并返回上一页
  Future<void> disconnect() async {
    try {
      await _mysqlService.disconnect();
      Get.snackbar(
        '断开连接 / Disconnected',
        '已成功断开连接 / Successfully disconnected',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } catch (e) {
      Get.snackbar(
        '错误 / Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }
}
