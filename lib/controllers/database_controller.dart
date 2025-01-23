/// 数据库控制器文件
/// 使用GetX状态管理框架
/// 负责管理数据库列表界面的状态和业务逻辑
/// 实现了在线和离线两种模式的数据库操作

import 'package:get/get.dart';
import '../services/database/mysql_service.dart';
import '../services/database/offline_service.dart';
import '../models/connection_config.dart';

/// 数据库控制器类
/// 继承自GetxController，用于管理数据库相关的状态和业务逻辑
/// 主要功能：
/// 1. 获取和显示数据库列表
/// 2. 处理数据库选择操作
/// 3. 管理数据库连接状态
/// 4. 支持在线/离线模式切换
class DatabaseController extends GetxController {
  /// MySQL服务实例
  /// 通过GetX依赖注入获取
  /// 用于处理在线模式下的数据库操作
  final _mysqlService = Get.find<MySqlService>();

  /// 离线模式服务实例
  /// 通过GetX依赖注入获取
  /// 用于处理离线模式下的数据库操作
  final _offlineService = Get.find<OfflineService>();

  /// 数据库列表
  /// 使用obs使其成为可观察对象
  /// 当列表更新时，UI会自动刷新
  final databases = <String>[].obs;

  /// 加载状态标志
  /// true表示正在加载数据
  /// false表示加载完成或未加载
  final isLoading = false.obs;

  /// 错误信息
  /// 存储加载过程中的错误信息
  /// 空字符串表示没有错误
  final error = ''.obs;

  /// 控制器初始化方法
  /// 在控制器被创建时自动调用
  /// 负责初始化数据和状态
  @override
  void onInit() {
    super.onInit();
    // 初始化时自动加载数据库列表
    loadDatabases();
  }

  /// 加载数据库列表方法
  /// 根据当前模式（在线/离线）获取数据库列表
  /// 更新加载状态和错误信息
  /// 异步操作，返回Future
  Future<void> loadDatabases() async {
    // 设置加载状态为true
    isLoading.value = true;
    // 清空错误信息
    error.value = '';

    try {
      // 根据连接模式选择对应的服务
      final service = _offlineService.isConnected
          ? _offlineService
          : _mysqlService as dynamic;
      // 获取数据库列表
      final dbs = await service.getDatabases();
      // 更新数据库列表
      databases.value = dbs;
    } catch (e) {
      // 捕获并存储错误信息
      error.value = e.toString();
    } finally {
      // 无论成功失败，都将加载状态设为false
      isLoading.value = false;
    }
  }

  /// 选择数据库方法
  /// 当用户选择某个数据库时调用
  /// 使用GetX导航到数据表列表页面
  /// @param database 选中的数据库名称
  void selectDatabase(String database) {
    // 导航到数据表列表页面，并传递选中的数据库名称
    Get.toNamed('/tables', arguments: database);
  }

  /// 断开连接方法
  /// 根据当前模式断开数据库连接
  /// 异步操作，返回Future
  Future<void> disconnect() async {
    // 根据连接模式选择对应的服务
    final service = _offlineService.isConnected
        ? _offlineService
        : _mysqlService as dynamic;
    // 执行断开连接操作
    await service.disconnect();
  }
}
