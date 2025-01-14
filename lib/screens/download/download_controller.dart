import 'package:get/get.dart';
import '../../services/download/download_service.dart';

class DownloadController extends GetxController {
  final _downloadService = Get.find<DownloadService>();

  final isLoading = false.obs;
  final error = ''.obs;
  final downloadUrls = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadDownloadUrls();
  }

  Future<void> loadDownloadUrls() async {
    isLoading.value = true;
    error.value = '';

    try {
      final urls = await _downloadService.getDownloadUrls();
      downloadUrls.value = urls;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  String? getUrlForPlatform(String platform) {
    return downloadUrls[platform.toLowerCase()];
  }
}
