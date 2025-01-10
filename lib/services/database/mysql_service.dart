import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/connection_config.dart';

/// MySQL数据库服务类
/// 负责处理与MySQL数据库服务器的所有交互，包括连接管理、查询执行和数据导出等功能
class MySqlService {
  /// HTTP客户端实例
  final _dio = Dio();

  /// API服务器基础URL
  final String baseUrl = 'http://192.168.51.10:3000/api';

  /// 当前会话的认证令牌
  String? _token;

  /// 连接到MySQL数据库
  ///
  /// 参数:
  /// - [config]: 数据库连接配置信息
  ///
  /// 异常:
  /// 如果连接失败，将抛出异常
  Future<void> connect(ConnectionConfig config) async {
    try {
      final response =
          await _dio.post('$baseUrl/connect', data: config.toJson());
      _token = response.data['token'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 断开与MySQL数据库的连接
  ///
  /// 异常:
  /// 如果断开连接失败，将抛出异常
  /// 注意：即使请求失败，也会清除本地token
  Future<void> disconnect() async {
    try {
      await _dio.post(
        '$baseUrl/disconnect',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
      _token = null;
    } catch (e) {
      if (e is DioException) {
        // 即使请求失败，也清除token
        _token = null;
        // 如果是因为已经断开连接导致的错误，我们可以忽略它
        if (e.type == DioExceptionType.unknown && e.message == null) {
          return;
        }
      }
      throw _handleError(e);
    }
  }

  /// 获取所有数据库列表
  ///
  /// 返回:
  /// 数据库名称列表
  ///
  /// 异常:
  /// 如果获取失败，将抛出异常
  Future<List<String>> getDatabases() async {
    try {
      print('Fetching databases with token: $_token');
      final response = await _dio.get(
        '$baseUrl/databases',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
      print('Response data: ${response.data}');
      if (response.data is List) {
        return List<String>.from(response.data);
      } else if (response.data is Map && response.data['databases'] is List) {
        return List<String>.from(response.data['databases']);
      }
      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      print('Error fetching databases: $e');
      throw _handleError(e);
    }
  }

  /// 选择要使用的数据库
  ///
  /// 参数:
  /// - [database]: 要选择的数据库名称
  ///
  /// 异常:
  /// 如果选择失败，将抛出异常
  Future<void> selectDatabase(String database) async {
    try {
      await _dio.post(
        '$baseUrl/select-database',
        data: {'database': database},
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取指定数据库中的所有表
  ///
  /// 参数:
  /// - [database]: 数据库名称
  ///
  /// 返回:
  /// 表名列表
  ///
  /// 异常:
  /// 如果获取失败，将抛出异常
  Future<List<String>> getTables(String database) async {
    try {
      print('Fetching tables for database: $database');
      print('Using token: $_token');

      final response = await _dio.get(
        '$baseUrl/tables',
        queryParameters: {'database': database},
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true, // 接受所有状态码以便调试
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode != 200) {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.data}');
      }

      if (response.data is Map && response.data['tables'] is List) {
        return List<String>.from(response.data['tables']);
      } else if (response.data is List) {
        return List<String>.from(response.data);
      }
      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      print('Error in getTables: $e');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print('DioError response: ${e.response?.data}');
        print('DioError stacktrace: ${e.stackTrace}');
      }
      throw _handleError(e);
    }
  }

  /// 执行SQL查询
  ///
  /// 参数:
  /// - [query]: SQL查询语句
  ///
  /// 返回:
  /// 包含查询结果的Map对象
  ///
  /// 异常:
  /// 如果查询执行失败，将抛出异常
  Future<Map<String, dynamic>> executeQuery(String query) async {
    try {
      print('Executing query: $query');
      final response = await _dio.post(
        '$baseUrl/query',
        data: {'query': query},
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true,
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode != 200) {
        if (response.data is Map && response.data['message'] != null) {
          throw Exception(response.data['message']);
        }
        throw Exception(
            'Server returned ${response.statusCode}: ${response.data}');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      print('Error executing query: $e');
      if (e is DioException) {
        print('DioError type: ${e.type}');
        print('DioError message: ${e.message}');
        print('DioError response: ${e.response?.data}');
        print('DioError stacktrace: ${e.stackTrace}');
      }
      throw _handleError(e);
    }
  }

  /// 将查询结果导出为Excel文件
  ///
  /// 参数:
  /// - [query]: SQL查询语句
  /// - [filename]: 导出文件名
  ///
  /// 异常:
  /// 如果导出失败，将抛出异常
  Future<void> exportToExcel(String query, String filename) async {
    try {
      final response = await _dio.post(
        '$baseUrl/export/excel',
        data: {
          'query': query,
          'filename': filename,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          responseType: ResponseType.bytes,
        ),
      );

      // 从Content-Disposition头部获取文件名
      final contentDisposition = response.headers.value('content-disposition');
      String downloadFilename = filename;
      if (contentDisposition != null) {
        final match = RegExp('filename=(.+)').firstMatch(contentDisposition);
        if (match != null) {
          downloadFilename = Uri.decodeComponent(match.group(1)!);
        }
      }

      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$downloadFilename';

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      print('File saved to: $filePath');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 将查询结果导出为CSV文件
  ///
  /// 参数:
  /// - [query]: SQL查询语句
  /// - [filename]: 导出文件名
  ///
  /// 异常:
  /// 如果导出失败，将抛出异常
  Future<void> exportToCsv(String query, String filename) async {
    try {
      final response = await _dio.post(
        '$baseUrl/export/csv',
        data: {
          'query': query,
          'filename': filename,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          responseType: ResponseType.bytes,
        ),
      );

      // 从Content-Disposition头部获取文件名
      final contentDisposition = response.headers.value('content-disposition');
      String downloadFilename = filename;
      if (contentDisposition != null) {
        final match = RegExp('filename=(.+)').firstMatch(contentDisposition);
        if (match != null) {
          downloadFilename = Uri.decodeComponent(match.group(1)!);
        }
      }

      // 获取应用文档目录
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$downloadFilename';

      // 写入文件
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      print('File saved to: $filePath');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取表结构信息
  ///
  /// 参数:
  /// - [database]: 数据库名称
  /// - [table]: 表名
  ///
  /// 返回:
  /// 包含表结构信息的Map列表
  ///
  /// 异常:
  /// 如果获取失败，将抛出异常
  Future<List<Map<String, dynamic>>> getTableStructure(
      String database, String table) async {
    try {
      final response = await _dio.get(
        '$baseUrl/table-structure',
        queryParameters: {
          'database': database,
          'table': table,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            response.data['message'] ?? 'Failed to get table structure');
      }

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['columns'] is List) {
        return List<Map<String, dynamic>>.from(response.data['columns']);
      }
      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table) async {
    try {
      final response = await _dio.get(
        '$baseUrl/table-indexes',
        queryParameters: {
          'database': database,
          'table': table,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            response.data['message'] ?? 'Failed to get table indexes');
      }

      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data['indexes'] is List) {
        return List<Map<String, dynamic>>.from(response.data['indexes']);
      }
      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> alterTable(String database, String table, String sql) async {
    try {
      final response = await _dio.post(
        '$baseUrl/alter-table',
        data: {
          'database': database,
          'table': table,
          'alterSql': sql,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to alter table');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 获取表的数据
  ///
  /// 参数:
  /// - [database]: 数据库名称
  /// - [table]: 表名
  /// - [page]: 页码，从1开始
  /// - [pageSize]: 每页记录数
  /// - [orderBy]: 排序字段
  /// - [orderDirection]: 排序方向（asc或desc）
  ///
  /// 返回:
  /// 包含表数据和分页信息的Map对象
  ///
  /// 异常:
  /// 如果获取失败，将抛出异常
  Future<Map<String, dynamic>> getTableData(
    String database,
    String table, {
    int page = 1,
    int pageSize = 10,
    String? orderBy,
    String? orderDirection,
  }) async {
    try {
      final response = await _dio.get(
        '$baseUrl/table-data',
        queryParameters: {
          'database': database,
          'table': table,
          'page': page,
          'pageSize': pageSize,
          if (orderBy != null) 'orderBy': orderBy,
          if (orderDirection != null) 'orderDirection': orderDirection,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.data}');
      }

      if (response.data is Map) {
        return response.data as Map<String, dynamic>;
      }

      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      print('Error getting table data: $e');
      throw _handleError(e);
    }
  }

  /// 处理错误信息
  /// 将各种类型的错误转换为统一的异常格式
  ///
  /// 参数:
  /// - [error]: 原始错误对象
  ///
  /// 返回:
  /// 格式化后的异常对象
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      // 处理网络请求错误
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Exception('连接超时，请检查网络连接');
      }

      if (error.response?.data is Map &&
          error.response?.data['message'] != null) {
        return Exception(error.response?.data['message']);
      }

      if (error.type == DioExceptionType.unknown) {
        return Exception('网络连接错误，请检查网络连接');
      }

      return Exception('请求失败: ${error.message}');
    }

    if (error is Exception) {
      return error;
    }

    return Exception('发生未知错误: $error');
  }
}
