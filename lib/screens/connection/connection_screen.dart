import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'connection_controller.dart';

/// 数据库连接界面
/// 提供MySQL数据库连接配置的用户界面，包括主机、端口、用户名和密码的输入表单
class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化连接控制器
    final controller = Get.put(ConnectionController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('MySQL Client'),
        actions: [
          // 根据连接状态显示断开连接按钮
          Obx(() {
            if (controller.isConnected.value) {
              return IconButton(
                icon: const Icon(Icons.logout),
                tooltip: '断开连接 / Disconnect',
                onPressed: () => _showDisconnectDialog(context, controller),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 主机地址输入框
              TextFormField(
                controller: controller.hostController,
                decoration: const InputDecoration(
                  labelText: '主机 / Host',
                  hintText: 'localhost',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入主机地址 / Please enter host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 端口号输入框
              TextFormField(
                controller: controller.portController,
                decoration: const InputDecoration(
                  labelText: '端口 / Port',
                  hintText: '3306',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入端口号 / Please enter port';
                  }
                  final port = int.tryParse(value);
                  if (port == null || port <= 0 || port > 65535) {
                    return '端口号无效 / Invalid port number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 用户名输入框
              TextFormField(
                controller: controller.userController,
                decoration: const InputDecoration(
                  labelText: '用户名 / Username',
                  hintText: 'root',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名 / Please enter username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 密码输入框，带有显示/隐藏密码的切换按钮
              Obx(() {
                return TextFormField(
                  controller: controller.passwordController,
                  decoration: InputDecoration(
                    labelText: '密码 / Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.isPasswordVisible.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                  obscureText: !controller.isPasswordVisible.value,
                );
              }),
              const SizedBox(height: 24),
              // 连接按钮，根据加载状态显示不同的内容
              Obx(() {
                return ElevatedButton(
                  onPressed:
                      controller.isLoading.value ? null : controller.connect,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('连接 / Connect'),
                );
              }),
              const SizedBox(height: 16),
              // 错误信息显示区域
              Obx(() {
                if (controller.error.value.isNotEmpty) {
                  return Text(
                    controller.error.value,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示断开连接确认对话框
  ///
  /// 参数:
  /// - [context]: 构建上下文
  /// - [controller]: 连接控制器实例
  void _showDisconnectDialog(
      BuildContext context, ConnectionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('断开连接 / Disconnect'),
        content: const Text(
          '确定要断开当前连接吗？\nAre you sure you want to disconnect?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.disconnect();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('断开 / Disconnect'),
          ),
        ],
      ),
    );
  }
}
