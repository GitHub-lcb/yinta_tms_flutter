/// 数据库连接配置模型文件
/// 定义了数据库连接所需的所有配置参数
/// 支持序列化和反序列化，方便存储和传输
/// 支持配置的复制和修改
/// 主要功能：
/// 1. 存储数据库连接信息
/// 2. 支持在线和离线两种连接模式
/// 3. 提供配置的序列化和反序列化
/// 4. 支持配置的复制和修改

/// MySQL数据库连接配置模型类
/// 封装了连接MySQL数据库所需的所有参数
/// 提供了配置的序列化、反序列化和复制功能
/// 支持可选的SSL连接和离线模式
class ConnectionConfig {
  /// 配置名称
  /// 用于标识和区分不同的连接配置
  /// 在保存多个连接配置时作为唯一标识符
  final String name;

  /// 数据库服务器主机地址
  /// 可以是IP地址或域名
  /// 例如：localhost, 127.0.0.1, db.example.com
  final String host;

  /// 数据库服务器端口号
  /// MySQL默认端口为3306
  /// 范围：1-65535
  final int port;

  /// 数据库用户名
  /// 用于数据库身份认证
  /// 需要具有适当的数据库访问权限
  final String user;

  /// 数据库密码
  /// 用于数据库身份认证
  /// 注意：在传输和存储时需要注意安全性
  final String password;

  /// 数据库名称（可选）
  /// 指定要连接的默认数据库
  /// 如果不指定，连接后需要手动选择数据库
  final String? database;

  /// 是否为离线模式
  /// true表示直接连接数据库
  /// false表示通过后端服务连接数据库
  final bool isOffline;

  /// 是否使用SSL连接
  /// true表示使用SSL加密连接
  /// false表示使用普通连接
  /// null表示使用默认设置
  final bool? useSSL;

  /// 构造函数
  /// 创建一个新的数据库连接配置实例
  /// 必填参数确保了基本连接信息的完整性
  /// 可选参数提供了额外的连接选项
  ///
  /// @param name 配置名称，用于标识配置
  /// @param host 数据库服务器地址
  /// @param port 数据库服务器端口
  /// @param user 数据库用户名
  /// @param password 数据库密码
  /// @param database 默认数据库名称（可选）
  /// @param isOffline 是否使用离线模式（默认false）
  /// @param useSSL 是否使用SSL连接（可选）
  ConnectionConfig({
    required this.name,
    required this.host,
    required this.port,
    required this.user,
    required this.password,
    this.database,
    this.isOffline = false,
    this.useSSL,
  });

  /// 序列化方法
  /// 将连接配置对象转换为JSON格式
  /// 用于：
  /// 1. 保存配置到本地存储
  /// 2. 通过网络传输配置
  /// 3. 与后端服务通信
  ///
  /// @return Map<String, dynamic> JSON格式的配置数据
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'host': host,
      'port': port,
      'username': user,
      'password': password,
      'useSSL': useSSL,
    };

    // 可选字段，仅在有值时添加
    if (database != null) {
      json['database'] = database;
    }

    // 离线模式标志
    json['isOffline'] = isOffline;

    return json;
  }

  /// 反序列化构造函数
  /// 从JSON数据创建ConnectionConfig实例
  /// 用于：
  /// 1. 从本地存储加载配置
  /// 2. 解析网络请求数据
  /// 3. 转换后端返回的配置数据
  ///
  /// @param json 包含配置信息的Map对象
  /// @return ConnectionConfig 新的配置实例
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      user: json['username'] as String,
      password: json['password'] as String,
      database: json['database'] as String?,
      isOffline: json['isOffline'] ?? false,
      useSSL: json['useSSL'] as bool?,
    );
  }

  /// 复制配置方法
  /// 创建当前配置的副本，可选择性地修改某些属性
  /// 遵循不可变性原则，返回新的配置实例
  /// 用于：
  /// 1. 基于现有配置创建新配置
  /// 2. 修改配置的某些属性
  /// 3. 保持原配置不变
  ///
  /// @param name 新的配置名称
  /// @param host 新的主机地址
  /// @param port 新的端口号
  /// @param user 新的用户名
  /// @param password 新的密码
  /// @param database 新的数据库名称
  /// @param isOffline 新的离线模式设置
  /// @param useSSL 新的SSL连接设置
  /// @return ConnectionConfig 新的配置实例
  ConnectionConfig copyWith({
    String? name,
    String? host,
    int? port,
    String? user,
    String? password,
    String? database,
    bool? isOffline,
    bool? useSSL,
  }) {
    return ConnectionConfig(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      user: user ?? this.user,
      password: password ?? this.password,
      database: database ?? this.database,
      isOffline: isOffline ?? this.isOffline,
      useSSL: useSSL ?? this.useSSL,
    );
  }
}
