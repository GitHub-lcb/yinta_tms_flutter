import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/download/download_service.dart';
import '../../utils/platform_utils.dart';
import 'download_controller.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPlatform = PlatformUtils.getCurrentPlatform();
    final isWebPlatform = kIsWeb;
    final downloadController = Get.put(DownloadController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('下载应用 / Download Apps'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Obx(() {
        if (downloadController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (downloadController.error.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  downloadController.error.value,
                  style: TextStyle(color: Colors.red[300]),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: downloadController.loadDownloadUrls,
                  child: const Text('重试 / Retry'),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: isWebPlatform
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    ],
                  ),
                )
              : null,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWebPlatform ? 32 : 16,
              vertical: isWebPlatform ? 24 : 8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWebPlatform ? 1200 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isWebPlatform) ...[
                      // Web版本的大标题
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.download_rounded,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '跨平台数据库管理工具',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Cross-Platform Database Management Tool',
                              style: TextStyle(
                                fontSize: 24,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildFeatureChip(context, '简单易用',
                                    'Easy to Use', Icons.touch_app),
                                _buildFeatureChip(context, '跨平台支持',
                                    'Cross Platform', Icons.devices),
                                _buildFeatureChip(context, '实时同步',
                                    'Real-time Sync', Icons.sync),
                                _buildFeatureChip(context, '安全可靠',
                                    'Secure & Reliable', Icons.security),
                              ],
                            ),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ],
                    // 头部说明
                    Card(
                      elevation: isWebPlatform ? 2 : 0,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isWebPlatform ? 24 : 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '选择您的平台 / Choose Your Platform',
                                    style: TextStyle(
                                      fontSize: isWebPlatform ? 20 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (currentPlatform != _Platform.unknown) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '当前平台: ${currentPlatform.name} / Current Platform: ${currentPlatform.name}',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isWebPlatform ? 32 : 16),
                    // Web版本
                    _buildPlatformSection(
                      context,
                      title: 'Web版本 / Web Version',
                      icon: Icons.web,
                      platforms: [
                        _PlatformInfo(
                          name: 'Web App',
                          icon: Icons.language,
                          url:
                              downloadController.getUrlForPlatform('web') ?? '',
                          version: 'v1.0.0',
                          isWebApp: true,
                          isRecommended: currentPlatform == _Platform.web,
                        ),
                      ],
                      isWebPlatform: isWebPlatform,
                    ),
                    SizedBox(height: isWebPlatform ? 32 : 16),
                    // 桌面平台
                    _buildPlatformSection(
                      context,
                      title: '桌面平台 / Desktop Platforms',
                      icon: Icons.desktop_windows,
                      platforms: [
                        _PlatformInfo(
                          name: 'Windows',
                          icon: Icons.window,
                          url:
                              downloadController.getUrlForPlatform('windows') ??
                                  '',
                          version: 'v1.0.0',
                          isRecommended: currentPlatform == _Platform.windows,
                        ),
                        _PlatformInfo(
                          name: 'macOS',
                          icon: Icons.laptop_mac,
                          url: downloadController.getUrlForPlatform('macos') ??
                              '',
                          version: 'v1.0.0',
                          isRecommended: currentPlatform == _Platform.macos,
                        ),
                        _PlatformInfo(
                          name: 'Linux',
                          icon: Icons.laptop,
                          url: downloadController.getUrlForPlatform('linux') ??
                              '',
                          version: 'v1.0.0',
                          isRecommended: currentPlatform == _Platform.linux,
                        ),
                      ],
                      isWebPlatform: isWebPlatform,
                    ),
                    SizedBox(height: isWebPlatform ? 32 : 16),
                    // 移动平台
                    _buildPlatformSection(
                      context,
                      title: '移动平台 / Mobile Platforms',
                      icon: Icons.phone_android,
                      platforms: [
                        _PlatformInfo(
                          name: 'Android',
                          icon: Icons.android,
                          url:
                              downloadController.getUrlForPlatform('android') ??
                                  '',
                          version: 'v1.0.0',
                          isRecommended: currentPlatform == _Platform.android,
                        ),
                        _PlatformInfo(
                          name: 'iOS',
                          icon: Icons.phone_iphone,
                          url:
                              downloadController.getUrlForPlatform('ios') ?? '',
                          version: 'v1.0.0',
                          isRecommended: currentPlatform == _Platform.ios,
                        ),
                      ],
                      isWebPlatform: isWebPlatform,
                    ),
                    if (isWebPlatform) ...[
                      const SizedBox(height: 48),
                      Center(
                        child: Text(
                          '© ${DateTime.now().year} MySQL Client. All rights reserved.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeatureChip(
      BuildContext context, String text, String engText, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$text / $engText',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_PlatformInfo> platforms,
    bool isWebPlatform = false,
  }) {
    return Card(
      elevation: isWebPlatform ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWebPlatform ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: isWebPlatform ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isWebPlatform ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isWebPlatform ? 16 : 12),
            ...platforms.map((platform) => _buildPlatformTile(
                  context,
                  platform,
                  isWebPlatform: isWebPlatform,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformTile(
    BuildContext context,
    _PlatformInfo platform, {
    bool isWebPlatform = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(bottom: isWebPlatform ? 12 : 8),
        decoration: BoxDecoration(
          color: platform.isRecommended
              ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: isWebPlatform
              ? Border.all(
                  color: platform.isRecommended
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Theme.of(context).dividerColor,
                )
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _launchUrl(platform.url),
          child: Padding(
            padding: EdgeInsets.all(isWebPlatform ? 16 : 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWebPlatform ? 10 : 8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    platform.icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: isWebPlatform ? 24 : 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            platform.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWebPlatform ? 16 : 14,
                            ),
                          ),
                          if (platform.isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '推荐 / Recommended',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isWebPlatform ? 13 : 12,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '版本 / Version: ${platform.version}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: isWebPlatform ? 14 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  platform.isWebApp ? Icons.open_in_new : Icons.download,
                  color: platform.isRecommended
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  size: isWebPlatform ? 24 : 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    } else {
      Get.snackbar(
        '错误 / Error',
        '无法打开链接 / Cannot open link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }
}

enum _Platform {
  web,
  windows,
  macos,
  linux,
  android,
  ios,
  unknown;

  String get name {
    switch (this) {
      case _Platform.web:
        return 'Web';
      case _Platform.windows:
        return 'Windows';
      case _Platform.macos:
        return 'macOS';
      case _Platform.linux:
        return 'Linux';
      case _Platform.android:
        return 'Android';
      case _Platform.ios:
        return 'iOS';
      case _Platform.unknown:
        return 'Unknown';
    }
  }
}

class _PlatformInfo {
  final String name;
  final IconData icon;
  final String url;
  final String version;
  final bool isRecommended;
  final bool isWebApp;

  const _PlatformInfo({
    required this.name,
    required this.icon,
    required this.url,
    required this.version,
    this.isRecommended = false,
    this.isWebApp = false,
  });
}
