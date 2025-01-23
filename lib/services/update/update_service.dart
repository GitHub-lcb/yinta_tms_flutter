import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../download/download_service.dart';
import 'package:flutter/foundation.dart';

class UpdateService extends GetxController {
  final RxBool isChecking = false.obs;
  final RxString error = ''.obs;
  final RxString currentVersion = ''.obs;
  final RxString latestVersion = ''.obs;
  final RxBool hasUpdate = false.obs;
  final RxString downloadUrl = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;

  late final DownloadService _downloadService;
  final Dio _dio = Dio();

  @override
  void onInit() {
    super.onInit();
    _downloadService = Get.find<DownloadService>();
    _initCurrentVersion();
  }

  Future<void> _initCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = packageInfo.version;
    } catch (e) {
      error.value = e.toString();
    }
  }

  Future<bool> checkUpdate({bool showError = true}) async {
    if (isChecking.value) return false;

    isChecking.value = true;
    error.value = '';

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion.value = packageInfo.version;

      // 从下载服务获取版本信息
      final urls = await _downloadService.getDownloadUrls();
      final serverVersion = urls['currentVersion'] ?? '';
      latestVersion.value = serverVersion;

      final needUpdate = _compareVersions(packageInfo.version, serverVersion);

      if (needUpdate) {
        hasUpdate.value = true;
        // 根据平台获取下载链接
        String? platformUrl;
        if (GetPlatform.isWeb) {
          platformUrl = urls['web'];
        } else if (GetPlatform.isWindows) {
          platformUrl = urls['windows'];
        } else if (GetPlatform.isMacOS) {
          platformUrl = urls['macos'];
        } else if (GetPlatform.isLinux) {
          platformUrl = urls['linux'];
        } else if (GetPlatform.isAndroid) {
          platformUrl = urls['android'];
        } else if (GetPlatform.isIOS) {
          platformUrl = urls['ios'];
        }

        if (platformUrl != null && platformUrl.isNotEmpty) {
          downloadUrl.value = platformUrl;
        } else {
          throw 'No download URL available for current platform';
        }

        // 显示更新对话框
        if (Get.context != null) {
          Get.dialog(
            AlertDialog(
              title: Text('update_available'.tr),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('current_version'.tr + ': ${currentVersion.value}'),
                      Text('latest_version'.tr + ': ${latestVersion.value}'),
                      Obx(() {
                        if (downloadProgress.value > 0 &&
                            downloadProgress.value < 1) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 16),
                              LinearProgressIndicator(
                                value: downloadProgress.value,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Get.theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(downloadProgress.value * 100).toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Get.theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text('update_later'.tr),
                  onPressed: () => Get.back(),
                ),
                TextButton(
                  child: Text('update_now'.tr),
                  onPressed: downloadProgress.value > 0
                      ? null
                      : () {
                          Get.back();
                          performUpdate();
                        },
                ),
              ],
            ),
            barrierDismissible: false,
          );
        }
      } else if (showError && Get.context != null) {
        Get.snackbar(
          'check_update'.tr,
          'no_update'.tr,
          snackPosition: SnackPosition.TOP,
        );
      }

      return needUpdate;
    } catch (e) {
      error.value = e.toString();
      if (showError && Get.context != null) {
        Get.snackbar(
          'check_update'.tr,
          e.toString(),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
        );
      }
      return false;
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> performUpdate() async {
    if (downloadUrl.value.isEmpty) return;

    try {
      var urlStr = downloadUrl.value;
      // 处理特殊字符
      urlStr = urlStr.replaceAll('~s', 's');
      final url = Uri.parse(urlStr);
      print("Downloading from URL: $url");

      if (GetPlatform.isAndroid && urlStr.toLowerCase().endsWith('.apk')) {
        // 在 Android 上下载 APK 到外部存储
        final directory = await getExternalStorageDirectory();
        if (directory == null) {
          throw 'Cannot access external storage';
        }

        // 创建下载目录
        final downloadDir = Directory('${directory.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }

        final filePath = '${downloadDir.path}/tms_update.apk';
        print("Downloading APK to: $filePath");

        await _dio.download(
          urlStr,
          filePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              downloadProgress.value = received / total;
            }
          },
        );

        // 下载完成后提示用户
        if (Get.context != null) {
          Get.dialog(
            AlertDialog(
              title: Text('download_complete'.tr),
              content: Text('install_update_prompt'.tr),
              actions: [
                TextButton(
                  child: Text('cancel'.tr),
                  onPressed: () => Get.back(),
                ),
                TextButton(
                  child: Text('install'.tr),
                  onPressed: () async {
                    Get.back();
                    // 打开文件进行安装
                    final file = File(filePath);
                    if (await file.exists()) {
                      if (GetPlatform.isAndroid) {
                        try {
                          print("Installing APK from: $filePath");
                          final packageInfo = await PackageInfo.fromPlatform();
                          // 使用 FileProvider URI
                          final uri = Uri.parse(
                              'content://${packageInfo.packageName}.fileprovider/external_files_path/${filePath.split('Download/').last}');
                          print("Installing APK with URI: $uri");

                          final result = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );

                          if (!result) {
                            print("Failed to launch APK installer");
                            throw 'Could not launch APK installer';
                          }
                        } catch (e) {
                          print('Error launching APK: $e');
                          // 如果安装失败，显示详细错误信息
                          if (Get.context != null) {
                            Get.snackbar(
                              'error'.tr,
                              'install_failed'.tr + ': ${e.toString()}',
                              snackPosition: SnackPosition.TOP,
                              backgroundColor: Colors.red.shade100,
                              duration: const Duration(seconds: 5),
                            );
                          }
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            barrierDismissible: false,
          );
        }
      } else {
        // 其他平台使用浏览器打开
        if (await canLaunchUrl(url)) {
          final launched = await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
          if (!launched) {
            throw 'Failed to launch $url';
          }
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      error.value = e.toString();
      if (Get.context != null) {
        Get.snackbar(
          'check_update'.tr,
          'download_error'.tr + ': ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      downloadProgress.value = 0.0;
    }
  }

  bool _compareVersions(String current, String latest) {
    final currentParts = current.split('.');
    final latestParts = latest.split('.');

    for (var i = 0; i < 3; i++) {
      final currentNum = int.parse(currentParts[i]);
      final latestNum = int.parse(latestParts[i]);

      if (latestNum > currentNum) {
        return true;
      } else if (latestNum < currentNum) {
        return false;
      }
    }

    return false;
  }
}
