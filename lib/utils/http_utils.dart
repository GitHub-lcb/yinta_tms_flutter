import 'package:dio/dio.dart';

class HttpUtils {
  /// 处理错误信息
  /// 将各种类型的错误转换为统一的异常格式
  static Exception handleError(dynamic error) {
    if (error is DioException) {
      // 处理网络请求错误
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Exception('连接超时，请检查网络连接');
      }

      if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        return Exception(error.response?.data['message']);
      }

      if (error.type == DioExceptionType.unknown) {
        return Exception('网络连接错误，请检查网络连接');
      }

      return Exception('请求失败: ${error.message}');
    }

    if (error is Exception) {
      return error;
    }

    return Exception('发生未知错误: $error');
  }

  /// 创建一个带有基础配置的Dio实例
  static Dio createDio(String baseUrl) {
    return Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
  }
}
