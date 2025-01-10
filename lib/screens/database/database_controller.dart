import 'package:get/get.dart';
import '../../services/database/mysql_service.dart';

/// 数据库列表控制器
/// 负责管理数据库列表界面的状态和业务逻辑，包括加载数据库列表、选择数据库等功能
class DatabaseController extends GetxController {
  /// MySQL服务实例，用于执行数据库相关操作
  final _mysqlService = Get.find<MySqlService>();

  /// 数据库列表
  final databases = <String>[].obs;

  /// 加载状态标志
  final isLoading = false.obs;

  /// 错误信息
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDatabases();
  }

  /// 加载数据库列表
  /// 从MySQL服务器获取所有可用的数据库
  Future<void> loadDatabases() async {
    isLoading.value = true;
    error.value = '';

    try {
      print('Loading databases...');
      final result = await _mysqlService.getDatabases();
      print('Loaded databases: $result');
      databases.value = result;
    } catch (e) {
      print('Error loading databases: $e');
      error.value = e.toString();
      databases.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// 选择数据库
  /// 切换到指定的数据库并导航到表列表界面
  ///
  /// 参数:
  /// - [database]: 要选择的数据库名称
  Future<void> selectDatabase(String database) async {
    try {
      await _mysqlService.selectDatabase(database);
      Get.toNamed('/tables', arguments: database);
    } catch (e) {
      error.value = e.toString();
    }
  }

  /// 断开数据库连接
  /// 关闭当前的数据库连接
  Future<void> disconnect() async {
    try {
      await _mysqlService.disconnect();
    } catch (e) {
      error.value = e.toString();
    }
  }
}
