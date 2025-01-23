import 'package:get/get.dart';
import '../controllers/table_data_controller.dart';
import '../controllers/table_structure_controller.dart';

/// 表格绑定类 - 负责表格相关控制器的依赖注入管理
class TableBinding extends Bindings {
  @override
  void dependencies() {
    // 懒加载注入表格数据控制器
    Get.lazyPut(() => TableDataController());
    // 懒加载注入表格结构控制器
    Get.lazyPut(() => TableStructureController());
  }
}
