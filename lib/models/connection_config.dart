/// MySQL数据库连接配置模型类
/// 用于存储和管理数据库连接所需的配置信息
class ConnectionConfig {
  /// 数据库服务器主机地址
  final String host;

  /// 数据库服务器端口号
  final int port;

  /// 数据库用户名
  final String user;

  /// 数据库密码
  final String password;

  /// 构造函数
  /// 创建一个新的数据库连接配置实例
  ///
  /// 参数:
  /// - [host]: 数据库服务器主机地址
  /// - [port]: 数据库服务器端口号
  /// - [user]: 数据库用户名
  /// - [password]: 数据库密码
  ConnectionConfig({
    required this.host,
    required this.port,
    required this.user,
    required this.password,
  });

  /// 将连接配置转换为JSON格式
  /// 用于序列化配置数据，方便网络传输或存储
  ///
  /// 返回:
  /// 包含连接配置信息的Map对象
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'username': user,
      'password': password,
    };
  }
}
