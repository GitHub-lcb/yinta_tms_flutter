import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/update/update_service.dart';

class UpdateButton extends StatelessWidget {
  const UpdateButton({super.key});

  @override
  Widget build(BuildContext context) {
    final updateService = Get.find<UpdateService>();

    return Obx(() {
      final isChecking = updateService.isChecking.value;
      final error = updateService.error.value;

      return IconButton(
        onPressed: isChecking
            ? null
            : () async {
                final hasUpdate = await updateService.checkUpdate();
                if (!hasUpdate && error.isEmpty) {
                  Get.snackbar(
                    '检查更新',
                    '当前已是最新版本',
                    snackPosition: SnackPosition.TOP,
                  );
                }
              },
        icon: isChecking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.system_update),
        tooltip: '检查更新',
      );
    });
  }
}
