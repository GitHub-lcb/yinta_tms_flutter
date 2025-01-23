/// 应用程序路由常量定义文件
/// 作为app_pages.dart的一部分，使用part指令实现文件拆分
/// 定义所有路由路径的静态常量，方便统一管理和引用
/// 使用抽象类和私有构造函数确保不会被实例化

part of 'app_pages.dart';

/// 应用程序路由常量定义类
/// 包含所有页面的路由路径常量
/// 使用抽象类防止实例化
/// 所有路由路径都定义为静态常量，便于全局访问
abstract class Routes {
  // 私有构造函数，确保类不会被实例化
  Routes._();

  /// 连接配置页面路由
  /// 作为应用的根路由 '/'
  /// 用户首次进入应用时显示的页面
  static const CONNECTION = '/';

  /// 数据库列表页面路由
  /// 显示当前连接下可用的所有数据库
  /// 用户可以在此选择要操作的数据库
  static const DATABASES = '/databases';

  /// 数据表列表页面路由
  /// 显示选中数据库中的所有数据表
  /// 提供表的基本信息和操作入口
  static const TABLES = '/tables';

  /// 数据表内容页面路由
  /// 显示选中表的数据内容
  /// 支持数据的查看、筛选和编辑功能
  static const TABLE_DATA = '/table-data';

  /// 数据表结构页面路由
  /// 显示表的结构信息，如字段定义、索引等
  /// 支持表结构的查看和修改
  static const TABLE_STRUCTURE = '/table-structure';

  /// SQL查询页面路由
  /// 提供SQL查询编辑器界面
  /// 支持SQL语句的编写和执行
  static const QUERY = '/query';

  /// 查询结果页面路由
  /// 显示SQL查询的执行结果
  /// 支持结果数据的查看和导出
  static const QUERY_RESULT = '/query-result';

  /// 查询历史页面路由
  /// 显示用户的SQL查询历史记录
  /// 支持历史记录的查看和重新执行
  static const QUERY_HISTORY = '/query-history';

  /// 下载页面路由
  /// 提供应用更新下载功能
  /// 显示下载进度和版本信息
  static const DOWNLOAD = '/download';
}
