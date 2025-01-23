/// 下载控制器文件
/// 使用GetX状态管理框架
/// 负责管理应用下载链接的获取和管理
/// 支持不同平台的下载地址管理

import 'package:get/get.dart';
import '../services/download/download_service.dart';

/// 下载控制器类
/// 继承自GetxController，用于管理下载相关的状态和业务逻辑
/// 主要功能：
/// 1. 获取各平台的下载链接
/// 2. 管理下载链接的加载状态
/// 3. 提供平台特定的下载地址查询
class DownloadController extends GetxController {
  /// 下载服务实例
  /// 通过GetX依赖注入获取
  /// 用于处理下载链接的获取
  final _downloadService = Get.find<DownloadService>();

  /// 加载状态标志
  /// true表示正在加载数据
  /// false表示加载完成或未加载
  final isLoading = false.obs;

  /// 错误信息
  /// 存储加载过程中的错误信息
  /// 空字符串表示没有错误
  final error = ''.obs;

  /// 下载链接映射表
  /// key为平台名称（小写）
  /// value为对应的下载链接
  final downloadUrls = <String, String>{}.obs;

  /// 控制器初始化方法
  /// 在控制器被创建时自动调用
  /// 负责初始化数据和状态
  @override
  void onInit() {
    super.onInit();
    // 初始化时自动加载下载链接
    loadDownloadUrls();
  }

  /// 加载下载链接方法
  /// 从下载服务获取各平台的下载链接
  /// 更新加载状态和错误信息
  /// 异步操作，返回Future
  Future<void> loadDownloadUrls() async {
    // 设置加载状态为true
    isLoading.value = true;
    // 清空错误信息
    error.value = '';

    try {
      // 获取下载链接
      final urls = await _downloadService.getDownloadUrls();
      // 更新下载链接映射表
      downloadUrls.value = urls;
    } catch (e) {
      // 捕获并存储错误信息
      error.value = e.toString();
    } finally {
      // 无论成功失败，都将加载状态设为false
      isLoading.value = false;
    }
  }

  /// 获取指定平台的下载链接
  /// @param platform 平台名称
  /// @return 返回对应平台的下载链接，如果不存在则返回null
  String? getUrlForPlatform(String platform) {
    return downloadUrls[platform.toLowerCase()];
  }
}
