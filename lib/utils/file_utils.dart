import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FileUtils {
  /// 保存或分享文件
  /// 在移动平台上使用分享功能，在桌面平台上使用文件选择器保存
  static Future<void> saveOrShareFile(
    List<int> bytes,
    String filename, {
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    // 获取临时目录
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/$filename');

    // 保存到临时文件
    await tempFile.writeAsBytes(bytes);

    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      // 在移动设备上使用分享功能
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: '导出数据',
      );
    } else {
      // 在桌面平台上使用文件选择器
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle ?? '选择保存位置',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? [filename.split('.').last],
      );

      if (outputFile == null) {
        // 用户取消了选择
        return;
      }

      // 保存文件
      final file = File(outputFile);
      await file.writeAsBytes(bytes);

      // 显示成功提示
      Get.snackbar(
        '导出成功',
        '文件已保存到: $outputFile',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        duration: const Duration(seconds: 5),
      );
    }

    // 清理临时文件
    await tempFile.delete();
    await tempDir.delete();
  }
}
