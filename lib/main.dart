/// MySQL客户端应用程序的主入口文件
/// 该文件负责初始化应用程序，配置依赖注入，设置路由系统

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/connection/connection_screen.dart';
import 'screens/database/database_screen.dart';
import 'screens/query/query_history_controller.dart';
import 'screens/table/table_screen.dart';
import 'screens/table/table_data_screen.dart';
import 'screens/table/table_data_controller.dart';
import 'screens/query/query_result_screen.dart';
import 'screens/query/query_history_screen.dart';
import 'services/database/mysql_service.dart';
import 'services/query/query_history_service.dart';
import 'screens/table/table_structure_screen.dart';
import 'screens/table/table_structure_controller.dart';

/// 应用程序的入口函数
/// 负责初始化Flutter绑定、设置依赖注入和启动应用
void main() async {
  // 确保Flutter绑定初始化，这对于调用平台通道和使用插件是必需的
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化SharedPreferences实例，用于本地数据持久化存储
  final prefs = await SharedPreferences.getInstance();

  // 使用Get依赖注入系统注册全局服务
  // 注册MySQL服务，用于处理数据库连接和操作
  Get.put(MySqlService());
  // 注册查询历史服务，用于管理SQL查询历史记录
  Get.put(QueryHistoryService(prefs));

  // 启动应用程序
  runApp(const MyApp());
}

/// 应用程序的根Widget
/// 配置应用的主题、路由和全局设置
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用GetMaterialApp替代MaterialApp，以支持Get库的路由管理和依赖注入功能
    return GetMaterialApp(
      // 移除调试标签
      debugShowCheckedModeBanner: false,
      // 应用标题
      title: 'MySQL Client',
      // 配置应用主题
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // 设置初始路由
      initialRoute: '/',
      // 定义应用的路由表
      getPages: [
        // 连接配置页面路由
        GetPage(name: '/', page: () => const ConnectionScreen()),
        // 数据库列表页面路由
        GetPage(name: '/databases', page: () => const DatabaseScreen()),
        // 数据表列表页面路由
        GetPage(name: '/tables', page: () => const TableScreen()),
        // 表数据页面路由，包含控制器绑定
        GetPage(
          name: '/table-data',
          page: () => const TableDataScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => TableDataController());
          }),
        ),
        // 查询结果页面路由
        GetPage(name: '/query-result', page: () => const QueryResultScreen()),
        // 查询历史页面路由，包含控制器绑定
        GetPage(
          name: '/query-history',
          page: () => const QueryHistoryScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => QueryHistoryController(Get.find()));
          }),
        ),
        // 表结构页面路由，包含控制器绑定
        GetPage(
          name: '/table-structure',
          page: () => const TableStructureScreen(),
          binding: BindingsBuilder(() {
            Get.lazyPut(() => TableStructureController());
          }),
        ),
      ],
    );
  }
}
