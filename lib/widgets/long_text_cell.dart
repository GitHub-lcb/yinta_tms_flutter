import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/dialog_utils.dart';

class LongTextCell extends StatelessWidget {
  final String text;
  final int maxLength;
  final double maxWidth;

  const LongTextCell({
    super.key,
    required this.text,
    this.maxLength = 50,
    this.maxWidth = 300,
  });

  void _showFullText(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'full_content'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text('copy'.tr),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      DialogUtils.showSuccess(
                        'copied'.tr,
                        'content_copied'.tr,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('close'.tr),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (text.length <= maxLength) {
      return Text(text);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Text(
            '${text.substring(0, maxLength)}...',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.visibility, size: 18),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
          onPressed: () => _showFullText(context),
          tooltip: 'view_full_content'.tr,
        ),
      ],
    );
  }
}
