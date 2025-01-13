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
          // 保存的连接按钮
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: '保存的连接 / Saved Connections',
            onPressed: () => _showSavedConnectionsDialog(context, controller),
          ),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 配置名称输入框
                TextFormField(
                  controller: controller.nameController,
                  decoration: const InputDecoration(
                    labelText: '配置名称 / Configuration Name',
                    hintText: 'My Connection',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                // 数据库名称输入框（可选）
                TextFormField(
                  controller: controller.databaseController,
                  decoration: const InputDecoration(
                    labelText: '数据库名称 / Database Name (Optional)',
                    hintText: 'Enter database name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                // 按钮区域
                Row(
                  children: [
                    // 测试连接按钮
                    Expanded(
                      child: Obx(() {
                        return ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.testConnection,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('测试 / Test'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 16),
                    // 保存配置按钮
                    Expanded(
                      child: Obx(() {
                        return ElevatedButton.icon(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.saveConnection,
                          icon: const Icon(Icons.save),
                          label: const Text('保存 / Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 连接按钮
                Obx(() {
                  return ElevatedButton.icon(
                    onPressed:
                        controller.isLoading.value ? null : controller.connect,
                    icon: const Icon(Icons.power_settings_new),
                    label: controller.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('连接 / Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
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
      ),
    );
  }

  /// 显示保存的连接对话框
  void _showSavedConnectionsDialog(
      BuildContext context, ConnectionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('保存的连接 / Saved Connections'),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (controller.savedConnections.isEmpty) {
              return const Center(
                child: Text('没有保存的连接 / No saved connections'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: controller.savedConnections.length,
              itemBuilder: (context, index) {
                final config = controller.savedConnections[index];
                return ListTile(
                  title: Text(config.name),
                  subtitle: Text(
                    '${config.host}:${config.port} (${config.user})',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          controller.deleteSavedConnection(config.name);
                          if (controller.savedConnections.isEmpty) {
                            Get.back();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          controller.loadSavedConnection(config);
                          Get.back();
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    controller.loadSavedConnection(config);
                    Get.back();
                  },
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('关闭 / Close'),
          ),
        ],
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
