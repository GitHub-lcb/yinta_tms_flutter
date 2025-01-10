/// SQL查询历史记录模型类
/// 用于记录和管理SQL查询的执行历史信息
class QueryHistory {
  /// SQL查询语句
  final String query;

  /// 查询执行的时间戳
  final DateTime timestamp;

  /// 查询所针对的数据库名称
  final String database;

  /// 查询是否执行成功
  final bool isSuccess;

  /// 查询影响的行数
  final int rowsAffected;

  /// 构造函数
  /// 创建一个新的查询历史记录实例
  ///
  /// 参数:
  /// - [query]: SQL查询语句
  /// - [timestamp]: 查询执行的时间戳
  /// - [database]: 查询所针对的数据库名称
  /// - [isSuccess]: 查询是否执行成功
  /// - [rowsAffected]: 查询影响的行数
  QueryHistory({
    required this.query,
    required this.timestamp,
    required this.database,
    required this.isSuccess,
    required this.rowsAffected,
  });

  /// 将查询历史记录转换为JSON格式
  /// 用于序列化数据，方便存储和传输
  ///
  /// 返回:
  /// 包含查询历史信息的Map对象
  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'database': database,
      'isSuccess': isSuccess,
      'rowsAffected': rowsAffected,
    };
  }

  /// 从JSON格式创建查询历史记录实例
  /// 用于反序列化存储的查询历史数据
  ///
  /// 参数:
  /// - [json]: 包含查询历史信息的Map对象
  ///
  /// 返回:
  /// 新的QueryHistory实例
  factory QueryHistory.fromJson(Map<String, dynamic> json) {
    return QueryHistory(
      query: json['query'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      database: json['database'] as String,
      isSuccess: json['isSuccess'] as bool,
      rowsAffected: json['rowsAffected'] as int,
    );
  }
}
