/// 对话框工具类文件
/// 提供统一的对话框和提示显示功能
/// 使用GetX的对话框和提示组件
/// 主要功能：
/// 1. 成功/错误/警告/信息提示
/// 2. 确认对话框
/// 3. 统一的样式和交互体验

import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 对话框工具类
/// 提供统一的对话框和提示显示方法
/// 封装了GetX的Snackbar和Dialog组件
/// 统一管理应用的对话框和提示样式
class DialogUtils {
  /// 显示成功提示
  /// 使用绿色背景的Snackbar
  /// 显示在屏幕底部
  /// 自动在700毫秒后消失
  ///
  /// @param title 提示标题
  /// @param message 提示内容
  static void showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      duration: const Duration(milliseconds: 700),
    );
  }

  /// 显示错误提示
  /// 使用红色背景的Snackbar
  /// 显示在屏幕底部
  /// 自动在700毫秒后消失
  ///
  /// @param title 提示标题
  /// @param message 提示内容
  static void showError(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      // duration: const Duration(seconds: 1),
      duration: const Duration(milliseconds: 700),
    );
  }

  /// 显示警告提示
  /// 使用橙色背景的Snackbar
  /// 显示在屏幕底部
  /// 自动在700毫秒后消失
  ///
  /// @param title 提示标题
  /// @param message 提示内容
  static void showWarning(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      duration: const Duration(milliseconds: 700),
    );
  }

  /// 显示普通信息提示
  /// 使用默认背景的Snackbar
  /// 显示在屏幕底部
  /// 自动在700毫秒后消失
  ///
  /// @param title 提示标题
  /// @param message 提示内容
  static void showInfo(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(milliseconds: 700),
    );
  }

  /// 显示确认对话框
  /// 使用AlertDialog显示确认信息
  /// 提供确认和取消两个选项
  /// 支持自定义按钮文本和确认按钮颜色
  ///
  /// @param context BuildContext对象
  /// @param title 对话框标题
  /// @param content 对话框内容
  /// @param confirmText 确认按钮文本（可选）
  /// @param cancelText 取消按钮文本（可选）
  /// @param confirmColor 确认按钮颜色（可选）
  /// @return Future<bool?> 用户选择结果（true表示确认，false表示取消）
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          // 取消按钮
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelText ?? '取消 / Cancel'),
          ),
          // 确认按钮
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText ?? '确认 / Confirm'),
          ),
        ],
      ),
    );
  }
}
