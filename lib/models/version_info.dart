import 'package:flutter/foundation.dart';

class VersionInfo {
  final String currentVersion;
  final Map<String, String> downloadUrls;

  VersionInfo({
    required this.currentVersion,
    required this.downloadUrls,
  });

  String? get platformDownloadUrl {
    if (kIsWeb) {
      return downloadUrls['web'];
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return downloadUrls['android'];
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return downloadUrls['ios'];
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      return downloadUrls['windows'];
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      return downloadUrls['macos'];
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      return downloadUrls['linux'];
    }
    return null;
  }

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      currentVersion: json['version'] as String,
      downloadUrls: Map<String, String>.from(json['downloadUrls']),
    );
  }
}
