import 'package:get/get.dart';

class QueryResultController extends GetxController {
  /// 每页显示的记录数
  final pageSize = 50.obs;

  /// 当前页码（从1开始）
  final currentPage = 1.obs;

  /// 总记录数
  final totalRecords = 0.obs;

  /// 所有数据
  final allRows = <dynamic>[].obs;

  /// 当前页的数据
  final currentPageRows = <dynamic>[].obs;

  /// 获取总页数
  int get totalPages => (totalRecords.value / pageSize.value).ceil();

  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取数据
    final args = Get.arguments as Map<String, dynamic>;
    final result = args['data'] as Map<String, dynamic>?;

    if (result != null && result.containsKey('rows')) {
      final rows = result['rows'] as List;
      allRows.value = rows;
      totalRecords.value = rows.length;
      _updateCurrentPageData();
    }
  }

  /// 更新当前页显示的数据
  void _updateCurrentPageData() {
    final start = (currentPage.value - 1) * pageSize.value;
    final end = start + pageSize.value;
    if (start >= allRows.length) {
      currentPageRows.clear();
    } else {
      currentPageRows.value = allRows.sublist(
        start,
        end > allRows.length ? allRows.length : end,
      );
    }
  }

  /// 切换页码
  void changePage(int page) {
    if (page < 1 || page > totalPages) return;
    currentPage.value = page;
    _updateCurrentPageData();
  }

  /// 切换每页显示记录数
  void changePageSize(int size) {
    pageSize.value = size;
    currentPage.value = 1; // 重置到第一页
    _updateCurrentPageData();
  }
}
