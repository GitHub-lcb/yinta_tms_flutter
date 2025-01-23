import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;
import 'dialog_utils.dart';

class FileUtils {
  /// 保存或分享文件
  /// 在移动平台上使用分享功能，在桌面平台上使用文件选择器保存，在Web平台上使用浏览器下载
  static Future<void> saveOrShareFile(
    List<int> bytes,
    String filename, {
    List<String>? allowedExtensions,
    String? dialogTitle,
    String? mimeType,
  }) async {
    try {
      if (kIsWeb) {
        // Web平台：使用浏览器的下载功能
        final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = filename;
        html.document.body?.children.add(anchor);

        // 触发下载
        anchor.click();

        // 清理
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        DialogUtils.showSuccess(
          '导出成功 / Export Success',
          '文件正在下载: $filename\nFile is downloading: $filename',
        );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // 桌面平台：使用文件选择器
        String? outputPath = await FilePicker.platform.saveFile(
          dialogTitle: dialogTitle ?? '选择保存位置 / Choose save location',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: allowedExtensions ?? [filename.split('.').last],
          lockParentWindow: true,
        );

        if (outputPath == null) {
          // 用户取消了选择
          return;
        }

        // 确保文件扩展名正确
        if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
          final extension = allowedExtensions.first;
          if (!outputPath.toLowerCase().endsWith('.$extension')) {
            outputPath = '$outputPath.$extension';
          }
        }

        // 保存文件
        final file = File(outputPath);
        await file.writeAsBytes(bytes);

        // 显示成功提示
        DialogUtils.showSuccess(
          '导出成功 / Export Success',
          '文件已保存到: $outputPath\nFile saved to: $outputPath',
        );

        // 打开文件所在目录
        final uri = Uri.file(file.parent.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else {
        // 移动平台：使用系统分享功能
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$filename');
        await tempFile.writeAsBytes(bytes);

        try {
          final result = await Share.shareXFiles(
            [XFile(tempFile.path, mimeType: mimeType)],
            subject: '导出数据 / Export Data',
            text: filename,
          );

          // 检查分享结果
          if (result.status == ShareResultStatus.success) {
            DialogUtils.showSuccess(
              '分享成功 / Share Success',
              '文件已成功分享\nFile shared successfully',
            );
          } else if (result.status == ShareResultStatus.dismissed) {
            DialogUtils.showWarning(
              '分享取消 / Share Cancelled',
              '文件分享已取消\nFile sharing was cancelled',
            );
          }
        } finally {
          // 清理临时文件
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
    } catch (e) {
      DialogUtils.showError(
        '导出失败 / Export Failed',
        '保存文件时出错: ${e.toString()}\nError saving file: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// 获取文件的MIME类型
  static String getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'csv':
        return 'text/csv';
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
