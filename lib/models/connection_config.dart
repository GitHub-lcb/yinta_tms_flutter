/// MySQL数据库连接配置模型类
/// 用于存储和管理数据库连接所需的配置信息
class ConnectionConfig {
  /// 配置名称
  final String name;

  /// 数据库服务器主机地址
  final String host;

  /// 数据库服务器端口号
  final int port;

  /// 数据库用户名
  final String user;

  /// 数据库密码
  final String password;

  /// 数据库名称（可选）
  final String? database;

  /// 是否为离线模式
  final bool isOffline;

  /// 构造函数
  /// 创建一个新的数据库连接配置实例
  ///
  /// 参数:
  /// - [name]: 配置名称
  /// - [host]: 数据库服务器主机地址
  /// - [port]: 数据库服务器端口号
  /// - [user]: 数据库用户名
  /// - [password]: 数据库密码
  /// - [database]: 数据库名称（可选）
  /// - [isOffline]: 是否为离线模式（可选）
  ConnectionConfig({
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    this.database,
    this.isOffline = false,
  });

  /// 将连接配置转换为JSON格式
  /// 用于序列化配置数据，方便网络传输或存储
  ///
  /// 返回:
  /// 包含连接配置信息的Map对象
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'host': host,
      'port': port,
      'username': user,
      'password': password,
    };

    if (database != null) {
      json['database'] = database;
    }

    json['isOffline'] = isOffline;

    return json;
  }

  /// 从JSON对象创建ConnectionConfig实例
  ///
  /// 参数:
  /// - [json]: JSON对象
  ///
  /// 返回:
  /// ConnectionConfig实例
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      user: json['username'] as String,
      password: json['password'] as String,
      database: json['database'] as String?,
      isOffline: json['isOffline'] ?? false,
    );
  }

  /// 创建配置的副本
  ///
  /// 参数:
  /// - [name]: 新的配置名称（可选）
  /// - [host]: 新的主机地址（可选）
  /// - [port]: 新的端口号（可选）
  /// - [user]: 新的用户名（可选）
  /// - [password]: 新的密码（可选）
  /// - [database]: 新的数据库名称（可选）
  ///
  /// 返回:
  /// 新的ConnectionConfig实例
  ConnectionConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
  }) {
    return ConnectionConfig(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
      isOffline: this.isOffline,
    );
  }
}
