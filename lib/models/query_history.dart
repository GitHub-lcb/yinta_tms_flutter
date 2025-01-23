/// 查询历史记录模型文件
/// 定义了SQL查询历史记录的数据结构
/// 支持序列化和反序列化，方便存储和检索
/// 记录查询的执行结果和影响
/// 主要功能：
/// 1. 存储SQL查询记录
/// 2. 记录查询执行结果
/// 3. 提供序列化和反序列化
/// 4. 支持查询历史的管理

/// SQL查询历史记录模型类
/// 封装了单条SQL查询的完整信息
/// 包含查询语句、执行时间、结果等信息
/// 用于记录和追踪SQL查询的执行情况
class QueryHistory {
  /// SQL查询语句
  /// 记录实际执行的SQL语句
  /// 可以是SELECT、INSERT、UPDATE、DELETE等任何有效的SQL语句
  final String query;

  /// 查询执行的时间戳
  /// 记录查询执行的具体时间
  /// 用于排序和追踪查询执行的时间线
  final DateTime timestamp;

  /// 查询所针对的数据库名称
  /// 记录查询在哪个数据库上执行
  /// 用于区分不同数据库的查询
  final String database;

  /// 查询是否执行成功
  /// true表示查询成功执行
  /// false表示查询执行失败
  final bool isSuccess;

  /// 查询影响的行数
  /// 对于SELECT语句，表示返回的行数
  /// 对于INSERT/UPDATE/DELETE语句，表示受影响的行数
  final int rowsAffected;

  /// 构造函数
  /// 创建一个新的查询历史记录实例
  /// 所有参数都是必需的，确保记录的完整性
  ///
  /// @param query SQL查询语句
  /// @param timestamp 查询执行时间
  /// @param database 数据库名称
  /// @param isSuccess 是否执行成功
  /// @param rowsAffected 影响的行数
  QueryHistory({
    required this.query,
    required this.timestamp,
    required this.database,
    required this.isSuccess,
    required this.rowsAffected,
  });

  /// 序列化方法
  /// 将查询历史记录转换为JSON格式
  /// 用于：
  /// 1. 保存历史记录到本地存储
  /// 2. 在应用内传递查询信息
  /// 3. 与后端服务通信
  ///
  /// @return Map<String, dynamic> JSON格式的历史记录数据
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(), // 使用ISO 8601格式转换时间戳
      'database': database,
      'isSuccess': isSuccess,
      'rowsAffected': rowsAffected,
    };
  }

  /// 反序列化构造函数
  /// 从JSON数据创建QueryHistory实例
  /// 用于：
  /// 1. 从本地存储加载历史记录
  /// 2. 解析后端返回的历史数据
  /// 3. 在应用内重建查询历史记录
  ///
  /// @param json 包含历史记录信息的Map对象
  /// @return QueryHistory 新的历史记录实例
  factory QueryHistory.fromJson(Map<String, dynamic> json) {
    return QueryHistory(
      query: json['query'] as String,
      timestamp:
          DateTime.parse(json['timestamp'] as String), // 解析ISO 8601格式的时间戳
      database: json['database'] as String,
      isSuccess: json['isSuccess'] as bool,
      rowsAffected: json['rowsAffected'] as int,
    );
  }
}
