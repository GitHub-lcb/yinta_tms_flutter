import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/sql_editor.dart';

class QueryResultScreen extends StatelessWidget {
  const QueryResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building QueryResultScreen...');
    final args = Get.arguments as Map<String, dynamic>;
    print('Arguments received: $args');

    final query = args['query'] as String;
    final result = args['data'] as Map<String, dynamic>?;
    print('Query: $query');
    print('Result: $result');

    if (result == null || !result.containsKey('results')) {
      print('Result is null or has no results, showing no data message');
      return Scaffold(
        appBar: AppBar(
          title: const Text('查询结果 / Query Result'),
        ),
        body: const Center(
          child: Text('没有数据 / No data available'),
        ),
      );
    }

    final resultsList = result['results'] as List;
    List<Map<String, dynamic>> data = [];
    List<String> columnOrder = [];

    if (resultsList.isNotEmpty) {
      final firstRecord = resultsList.first as Map<String, dynamic>;

      // Get column order from the first record
      if (firstRecord.containsKey('__columnOrder')) {
        columnOrder = List<String>.from(firstRecord['__columnOrder'] as List);
      } else {
        columnOrder =
            firstRecord.keys.where((key) => key != '__columnOrder').toList();
      }

      // Process all records
      data = resultsList.map((item) {
        final record = Map<String, dynamic>.from(item as Map);
        record.remove('__columnOrder');
        return record;
      }).toList();
    }

    print('Processed data length: ${data.length}');
    print('Column order: $columnOrder');

    return Scaffold(
      appBar: AppBar(
        title: const Text('查询结果 / Query Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: '导出 / Export',
            onPressed: () => _showExportDialog(context, query),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: SqlEditor(
                initialValue: query,
                readOnly: true,
              ),
            ),
          ),
          const Divider(),
          if (data.isEmpty)
            const Expanded(
              child: Center(
                child: Text('没有数据 / No data available'),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: columnOrder.map((key) {
                      return DataColumn(label: Text(key));
                    }).toList(),
                    rows: data.map((row) {
                      return DataRow(
                        cells: columnOrder.map((key) {
                          final value = row[key];
                          return DataCell(Text(value?.toString() ?? 'NULL'));
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String query) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出 / Export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              onTap: () {
                // TODO: Implement Excel export
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('CSV'),
              onTap: () {
                // TODO: Implement CSV export
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
