import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../controllers/connection_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../i18n/locale_controller.dart';
import '../../services/update/update_service.dart';

/// 数据库连接界面
/// 提供MySQL数据库连接配置的用户界面，包括主机、端口、用户名和密码的输入表单
class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化连接控制器
    final controller = Get.put(ConnectionController());
    final localeController = Get.find<LocaleController>();
    final updateService = Get.find<UpdateService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('tms_connect'.tr),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GetX<ThemeController>(
            builder: (controller) => IconButton(
              icon: Icon(
                controller.isDarkMode.value
                    ? Icons.light_mode
                    : Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: controller.isDarkMode.value
                  ? 'switch_to_light'.tr
                  : 'switch_to_dark'.tr,
              onPressed: controller.toggleTheme,
            ),
          ),
        ),
        actions: [
          // 语言切换按钮
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: GetX<LocaleController>(
              builder: (controller) => IconButton(
                icon: Text(
                  controller.isEnglish ? '中' : 'En',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                tooltip: 'language'.tr,
                onPressed: controller.toggleLocale,
              ),
            ),
          ),
          // 保存的连接按钮
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmark),
              tooltip: 'saved_connections'.tr,
              onPressed: () => _showSavedConnectionsDialog(context, controller),
            ),
          ),
          // 检查更新按钮
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Obx(() => IconButton(
                  icon: updateService.isChecking.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update),
                  tooltip: updateService.isChecking.value
                      ? 'checking_update'.tr
                      : 'check_update'.tr,
                  onPressed: updateService.isChecking.value
                      ? null
                      : () async {
                          await updateService.checkUpdate();
                        },
                )),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'download_apps'.tr,
            onPressed: () => Get.toNamed('/download'),
          ),
          if (controller.isConnected.value)
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: 'disconnect'.tr,
              onPressed: () => _showDisconnectDialog(context, controller),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 基本配置卡片
                  _buildCard(
                    context,
                    title: 'basic_config'.tr,
                    icon: Icons.settings,
                    children: [
                      // 配置名称输入框
                      _buildTextField(
                        controller: controller.nameController,
                        label: 'config_name'.tr,
                        hint: 'My Connection',
                        icon: Icons.bookmark,
                      ),
                      const SizedBox(height: 16),
                      // 主机地址输入框
                      _buildTextField(
                        controller: controller.hostController,
                        label: 'host'.tr,
                        hint: 'localhost',
                        icon: Icons.computer,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_host'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 端口号输入框
                      _buildTextField(
                        controller: controller.portController,
                        label: 'port'.tr,
                        hint: '3306',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_port'.tr;
                          }
                          final port = int.tryParse(value);
                          if (port == null || port <= 0 || port > 65535) {
                            return 'invalid_port'.tr;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 认证信息卡片
                  _buildCard(
                    context,
                    title: 'authentication'.tr,
                    icon: Icons.security,
                    children: [
                      // 用户名输入框
                      _buildTextField(
                        controller: controller.userController,
                        label: 'username'.tr,
                        hint: 'root',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'please_enter_username'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 密码输入框
                      Obx(() => _buildTextField(
                            controller: controller.passwordController,
                            label: 'password'.tr,
                            icon: Icons.lock,
                            obscureText: !controller.isPasswordVisible.value,
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.isPasswordVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: controller.togglePasswordVisibility,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 高级选项卡片
                  _buildCard(
                    context,
                    // title: 'advanced_options'.tr,
                    // icon: Icons.tune,
                    children: [
                      // 数据库名称输入框
                      _buildTextField(
                        controller: controller.databaseController,
                        label: 'database_name'.tr,
                        hint: 'Enter database name',
                        icon: Icons.storage,
                      ),
                      const SizedBox(height: 16),
                      // 离线模式开关
                      if (!kIsWeb) // 只在非Web平台显示离线模式
                        Obx(() => Container(
                              decoration: BoxDecoration(
                                color: controller.isOfflineMode.value
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: controller.isOfflineMode.value
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: SwitchListTile(
                                title: Text('offline_mode'.tr),
                                subtitle: Text('offline_mode_desc'.tr),
                                value: controller.isOfflineMode.value,
                                onChanged: (value) =>
                                    controller.toggleOfflineMode(),
                              ),
                            ))
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'offline_mode_web_unavailable'.tr,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'offline_mode_web_desc'.tr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 按钮区域
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        // 测试和保存按钮组
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 测试连接按钮
                              Expanded(
                                child: Obx(() {
                                  return _buildButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.testConnection,
                                    icon: Icons.check_circle,
                                    label: 'test'.tr,
                                    color: Colors.green,
                                    height: 48,
                                  );
                                }),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                color: Colors.grey[200],
                              ),
                              // 保存配置按钮
                              Expanded(
                                child: Obx(() {
                                  return _buildButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.saveConnection,
                                    icon: Icons.bookmark,
                                    label: 'save'.tr,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    height: 48,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 连接按钮
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withBlue(255),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Obx(() {
                            return _buildButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.connect,
                              icon: Icons.login,
                              // label: '连接 / Connect',
                              label: 'connect'.tr,
                              color: Colors.white,
                              isLoading: controller.isLoading.value,
                              height: 48,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 错误信息显示区域
                  Obx(() {
                    if (controller.error.value.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              controller.error.value = '';
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.red[700],
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      controller.error.value,
                                      style: TextStyle(
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.close,
                                    color: Colors.red[300],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建卡片组件
  Widget _buildCard(
    BuildContext context, {
    String? title,
    IconData? icon,
    required List<Widget> children,
    EdgeInsets? padding,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  /// 构建输入框组件
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Get.theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Get.theme.colorScheme.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Get.theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red[300]!,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red[300]!,
            width: 2,
          ),
        ),
        prefixIcon: icon != null
            ? Icon(
                icon,
                color: Get.theme.colorScheme.primary,
              )
            : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Get.theme.colorScheme.surface,
      ),
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
    );
  }

  /// 构建按钮组件
  Widget _buildButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isLoading = false,
    double? height,
  }) {
    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    icon,
                    color: onPressed == null ? color.withOpacity(0.5) : color,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null ? color.withOpacity(0.5) : color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示断开连接确认对话框
  void _showDisconnectDialog(
      BuildContext context, ConnectionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(width: 12),
            const Text('断开连接 / Disconnect'),
          ],
        ),
        content: const Text('确定要断开当前连接吗？ / Are you sure to disconnect?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('取消 / Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.disconnect();
            },
            child: const Text(
              '断开 / Disconnect',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示保存的连接对话框
  void _showSavedConnectionsDialog(
      BuildContext context, ConnectionController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.bookmark,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                '保存的连接 / Saved Connections',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (controller.savedConnections.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.bookmark_border,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '没有保存的连接 / No saved connections',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: controller.savedConnections.length,
              itemBuilder: (context, index) {
                final config = controller.savedConnections[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.storage,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      config.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${config.host}:${config.port} (${config.user})',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red[300],
                          ),
                          tooltip: '删除 / Delete',
                          onPressed: () {
                            controller.deleteSavedConnection(config.name);
                            if (controller.savedConnections.isEmpty) {
                              Get.back();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: '编辑 / Edit',
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
                  ),
                );
              },
            );
          }),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
}
