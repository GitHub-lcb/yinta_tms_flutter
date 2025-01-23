/// 应用程序路由配置文件
/// 使用GetX路由管理系统，实现页面导航和依赖注入
/// 本文件主要功能：
/// 1. 定义所有页面的路由配置
/// 2. 配置页面的依赖绑定
/// 3. 设置初始路由页面
/// 4. 统一管理所有页面的导航逻辑

import 'package:get/get.dart';
import '../screens/connection/connection_screen.dart';
import '../screens/database/database_screen.dart';
import '../screens/table/table_screen.dart';
import '../screens/table/table_data_screen.dart';
import '../screens/table/table_structure_screen.dart';
import '../screens/query/query_screen.dart';
import '../screens/query/query_result_screen.dart';
import '../screens/query/query_history_screen.dart';
import '../screens/download/download_screen.dart';
import '../bindings/query_binding.dart';
import '../bindings/table_binding.dart';

part 'app_routes.dart';

/// 应用程序页面路由配置类
/// 使用GetX的路由管理系统，提供统一的路由注册和管理
/// 采用单例模式设计，通过私有构造函数确保全局唯一实例
class AppPages {
  // 私有构造函数，防止外部实例化
  AppPages._();

  /// 初始路由页面
  /// 应用启动时默认显示的页面
  /// 设置为连接配置页面，用户需要先配置数据库连接
  static const initial = Routes.CONNECTION;

  /// 所有页面路由配置列表
  /// 使用GetPage配置每个页面的路由信息
  /// 包含：
  /// - name: 路由路径
  /// - page: 页面组件构造函数
  /// - binding: 依赖注入绑定（可选）
  static final routes = [
    GetPage(
      name: Routes.CONNECTION,
      page: () => const ConnectionScreen(),
      // 连接配置页面，用于管理数据库连接信息
    ),
    GetPage(
      name: Routes.DATABASES,
      page: () => const DatabaseScreen(),
      // 数据库列表页面，显示所有可用的数据库
    ),
    GetPage(
      name: Routes.TABLES,
      page: () => const TableScreen(),
      // 数据表列表页面，显示选中数据库中的所有表
    ),
    GetPage(
      name: Routes.TABLE_DATA,
      page: () => const TableDataScreen(),
      binding: TableBinding(),
      // 数据表内容页面，显示表中的数据
      // 使用TableBinding注入表格相关的依赖
    ),
    GetPage(
      name: Routes.TABLE_STRUCTURE,
      page: () => const TableStructureScreen(),
      binding: TableBinding(),
      // 数据表结构页面，显示表的结构信息
      // 使用TableBinding注入表格相关的依赖
    ),
    GetPage(
      name: Routes.QUERY,
      page: () => const QueryScreen(),
      binding: QueryBinding(),
      // SQL查询页面，用于执行SQL查询
      // 使用QueryBinding注入查询相关的依赖
    ),
    GetPage(
      name: Routes.QUERY_RESULT,
      page: () => const QueryResultScreen(),
      // 查询结果页面，显示SQL查询的结果
    ),
    GetPage(
      name: Routes.QUERY_HISTORY,
      page: () => const QueryHistoryScreen(),
      binding: QueryBinding(),
      // 查询历史页面，显示历史SQL查询记录
      // 使用QueryBinding注入查询相关的依赖
    ),
    GetPage(
      name: Routes.DOWNLOAD,
      page: () => const DownloadScreen(),
      // 下载页面，用于应用更新下载
    ),
  ];
}
