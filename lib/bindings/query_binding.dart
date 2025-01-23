import 'package:get/get.dart';
import '../controllers/query_controller.dart';
import '../controllers/query_history_controller.dart';
import '../controllers/query_result_controller.dart';

/// 查询绑定类 - 负责依赖注入管理
class QueryBinding extends Bindings {
  @override
  void dependencies() {
    // 懒加载注入查询控制器
    Get.lazyPut(() => QueryController());
    // 懒加载注入查询历史控制器,并注入其依赖
    Get.lazyPut(() => QueryHistoryController(Get.find()));
    // 懒加载注入查询结果控制器
    Get.lazyPut(() => QueryResultController());
  }
}
