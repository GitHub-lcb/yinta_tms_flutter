/// HTTP工具类文件
/// 提供HTTP请求相关的工具方法
/// 使用Dio库进行网络请求
/// 主要功能：
/// 1. 统一的错误处理
/// 2. HTTP客户端配置
/// 3. 网络请求异常转换

import 'package:dio/dio.dart';

/// HTTP工具类
/// 提供HTTP请求相关的静态工具方法
/// 封装了错误处理和客户端配置的通用功能
class HttpUtils {
  /// 统一的错误处理方法
  /// 将不同类型的错误转换为统一的异常格式
  /// 支持处理：
  /// 1. Dio网络请求异常
  /// 2. 标准Dart异常
  /// 3. 其他未知错误
  ///
  /// @param error 需要处理的错误对象
  /// @return Exception 统一格式的异常对象
  static Exception handleError(dynamic error) {
    if (error is DioException) {
      // 处理Dio网络请求错误
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        // 处理超时错误
        return Exception('连接超时，请检查网络连接');
      }

      // 处理服务器返回的错误信息
      if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        return Exception(error.response?.data['message']);
      }

      // 处理网络连接错误
      if (error.type == DioExceptionType.unknown) {
        return Exception('网络连接错误，请检查网络连接');
      }

      // 处理其他Dio错误
      return Exception('请求失败: ${error.message}');
    }

    // 处理标准异常
    if (error is Exception) {
      return error;
    }

    // 处理未知错误
    return Exception('发生未知错误: $error');
  }

  /// 创建Dio实例的工厂方法
  /// 配置基础的HTTP客户端参数
  /// 包括：
  /// 1. 基础URL
  /// 2. 超时设置
  /// 3. 请求配置
  ///
  /// @param baseUrl API的基础URL
  /// @return Dio 配置好的Dio实例
  static Dio createDio(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      // 连接超时时间
      connectTimeout: const Duration(seconds: 30),
      // 接收超时时间
      receiveTimeout: const Duration(seconds: 30),
      // 发送超时时间
      sendTimeout: const Duration(seconds: 30),
    ));
  }
}
