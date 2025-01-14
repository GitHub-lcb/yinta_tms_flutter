import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';

enum PlatformType {
  web,
  windows,
  macos,
  linux,
  android,
  ios,
  unknown;

  String get name {
    switch (this) {
      case PlatformType.web:
        return 'Web';
      case PlatformType.windows:
        return 'Windows';
      case PlatformType.macos:
        return 'macOS';
      case PlatformType.linux:
        return 'Linux';
      case PlatformType.android:
        return 'Android';
      case PlatformType.ios:
        return 'iOS';
      case PlatformType.unknown:
        return 'Unknown';
    }
  }
}

class PlatformUtils {
  /// 获取当前平台类型
  static PlatformType getCurrentPlatform() {
    if (kIsWeb) return PlatformType.web;
    if (GetPlatform.isWindows) return PlatformType.windows;
    if (GetPlatform.isMacOS) return PlatformType.macos;
    if (GetPlatform.isLinux) return PlatformType.linux;
    if (GetPlatform.isAndroid) return PlatformType.android;
    if (GetPlatform.isIOS) return PlatformType.ios;
    return PlatformType.unknown;
  }

  /// 检查是否是移动平台
  static bool isMobilePlatform() {
    return !kIsWeb && (GetPlatform.isIOS || GetPlatform.isAndroid);
  }

  /// 检查是否是桌面平台
  static bool isDesktopPlatform() {
    return !kIsWeb &&
        (GetPlatform.isWindows || GetPlatform.isMacOS || GetPlatform.isLinux);
  }
}
