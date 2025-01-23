import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/theme_controller.dart';
import '../../i18n/locale_controller.dart';
import '../../services/database/connection_service.dart';
import '../../services/database/mysql_service.dart';
import '../../services/database/offline_service.dart';
import '../../services/download/download_service.dart';
import '../../services/query/query_history_service.dart';
import '../../services/update/update_service.dart';

/// 服务初始化器
/// 负责管理所有服务的初始化和注册
class ServiceInitializer {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    Get.put(prefs);

    // 控制器注册
    Get.put(ThemeController(prefs));
    Get.put(LocaleController());

    // 服务注册
    Get.put(MySqlService());
    Get.put(OfflineService());
    Get.put(QueryHistoryService(prefs));
    Get.put(ConnectionService());
    Get.put(DownloadService());
    Get.put(UpdateService());

    // 延迟检查更新，等待应用完全初始化
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final updateService = Get.find<UpdateService>();
      final hasUpdate = await updateService.checkUpdate();
      if (hasUpdate) {
        Get.dialog(
          AlertDialog(
            title: const Text('发现新版本'),
            content: const Text('是否立即更新到最新版本？'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('稍后再说'),
              ),
              ElevatedButton(
                onPressed: () {
                  Get.back();
                  updateService.performUpdate();
                },
                child: const Text('立即更新'),
              ),
            ],
          ),
        );
      }
    });
  }
}
