import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../config/api_config.dart';

class DownloadService extends GetxService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
  ));

  // 获取所有平台的下载地址
  Future<Map<String, String>> getDownloadUrls() async {
    try {
      final response = await _dio.get('/downloads');
      if (response.statusCode == 200) {
        return Map<String, String>.from(response.data);
      }
      throw Exception('Failed to load download URLs');
    } catch (e) {
      throw Exception('Failed to load download URLs: $e');
    }
  }
}
