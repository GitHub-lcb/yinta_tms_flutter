import 'package:get/get.dart';
import '../../services/database/mysql_service.dart';
import '../../services/database/offline_service.dart';
import '../../models/connection_config.dart';

/// 数据库控制器
/// 负责管理数据库列表界面的状态和业务逻辑
class DatabaseController extends GetxController {
  /// MySQL服务实例
  final _mysqlService = Get.find<MySqlService>();

  /// 离线模式服务实例
  final _offlineService = Get.find<OfflineService>();

  /// 数据库列表
  final databases = <String>[].obs;

  /// 加载状态
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDatabases();
  }

  /// 加载数据库列表
  Future<void> loadDatabases() async {
    isLoading.value = true;
    error.value = '';

    try {
      final service = _offlineService.isConnected
          ? _offlineService
          : _mysqlService as dynamic;
      final dbs = await service.getDatabases();
      databases.value = dbs;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 选择数据库
  void selectDatabase(String database) {
    Get.toNamed('/tables', arguments: database);
  }

  /// 断开连接
  Future<void> disconnect() async {
    final service = _offlineService.isConnected
        ? _offlineService
        : _mysqlService as dynamic;
    await service.disconnect();
  }
}
