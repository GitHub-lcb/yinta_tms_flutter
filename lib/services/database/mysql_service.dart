import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../../models/connection_config.dart';
import '../../config/api_config.dart';
import '../../utils/http_utils.dart';
import '../../utils/file_utils.dart';
import 'database_service.dart';

/// MySQL数据库服务类
/// 负责处理与MySQL数据库服务器的所有交互，包括连接管理、查询执行和数据导出等功能
class MySqlService extends GetxService implements DatabaseService {
  /// HTTP客户端实例
  final _dio = HttpUtils.createDio(ApiConfig.baseUrl);

  /// 当前会话的认证令牌
  String? _token;

  /// 测试数据库连接
  /// 尝试连接但不保持连接状态
  ///
  /// 参数:
  /// - [config]: 数据库连接配置信息
  ///
  /// 返回:
  /// 如果连接成功返回true，否则抛出异常
  Future<bool> testConnection(ConnectionConfig config) async {
    try {
      // 使用connect端点测试连接
      final response = await _dio.post('/connect', data: config.toJson());
      if (response.statusCode == 200) {
        // 获取临时token
        final tempToken = response.data['token'];
        // 立即断开连接
        await _dio.post(
          '/disconnect',
          options: Options(
            headers: {'Authorization': 'Bearer $tempToken'},
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      throw HttpUtils.handleError(e);
    }
  }

  /// 连接到MySQL数据库
  ///
  /// 参数:
  /// - [config]: 数据库连接配置信息
  ///
  /// 异常:
  /// 如果连接失败，将抛出异常
  Future<void> connect(ConnectionConfig config) async {
    try {
      final response = await _dio.post('/connect', data: config.toJson());
      _token = response.data['token'];
    } catch (e) {
      throw HttpUtils.handleError(e);
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
        '/disconnect',
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
      throw HttpUtils.handleError(e);
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
        '/databases',
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
      throw HttpUtils.handleError(e);
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
        '/select-database',
        data: {'database': database},
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
    } catch (e) {
      throw HttpUtils.handleError(e);
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
        '/tables',
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
      throw HttpUtils.handleError(e);
    }
  }

  /// 执行SQL查询
  ///
  /// 参数:
  /// - [database]: 数据库名称
  /// - [query]: SQL查询语句
  ///
  /// 返回:
  /// 包含查询结果的Map对象
  ///
  /// 异常:
  /// 如果查询执行失败，将抛出异常
  Future<Map<String, dynamic>> executeQuery(
      String database, String query) async {
    try {
      print('Executing query on database $database: $query');
      final response = await _dio.post(
        '/query',
        data: {
          'database': database,
          'query': query,
        },
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

      // 统一返回格式
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        // 如果是DDL语句的结果
        if (data['affectedRows'] != null) {
          return {
            'columns': ['Affected Rows'],
            'rows': [
              [data['affectedRows']]
            ],
          };
        }
        // 如果是查询结果
        if (data['results'] is List) {
          if (data['results'].isEmpty) {
            return {
              'columns': [],
              'rows': [],
            };
          }
          // 从第一行数据中提取列名
          final firstRow = data['results'][0] as Map<String, dynamic>;
          final allColumns = firstRow.keys.toList();

          // 过滤掉内部字段（以下划线开头的字段）
          final columns = allColumns
              .where((col) => !col.toString().startsWith('_'))
              .toList();

          // 构建行数据
          final rows = (data['results'] as List).map((row) {
            return columns.map((col) => row[col]).toList();
          }).toList();

          return {
            'columns': columns,
            'rows': rows,
          };
        }
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
      throw HttpUtils.handleError(e);
    }
  }

  /// 将查询结果导出为Excel文件
  Future<void> exportToExcel(String query, String filename) async {
    try {
      final response = await _dio.post(
        '/export/excel',
        data: {
          'query': query,
          'filename': filename,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          responseType: ResponseType.bytes,
        ),
      );

      await FileUtils.saveOrShareFile(
        response.data,
        filename,
        allowedExtensions: ['xlsx'],
        dialogTitle: '选择保存位置',
      );
    } catch (e) {
      throw HttpUtils.handleError(e);
    }
  }

  /// 将查询结果导出为CSV文件
  Future<void> exportToCsv(String query, String filename) async {
    try {
      final response = await _dio.post(
        '/export/csv',
        data: {
          'query': query,
          'filename': filename,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          responseType: ResponseType.bytes,
        ),
      );

      await FileUtils.saveOrShareFile(
        response.data,
        filename,
        allowedExtensions: ['csv'],
        dialogTitle: '选择保存位置',
      );
    } catch (e) {
      throw HttpUtils.handleError(e);
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
        '/table-structure',
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
      throw HttpUtils.handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getTableIndexes(
      String database, String table) async {
    try {
      final response = await _dio.get(
        '/table-indexes',
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
      throw HttpUtils.handleError(e);
    }
  }

  Future<void> alterTable(String database, String table, String sql) async {
    try {
      final response = await _dio.post(
        '/alter-table',
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
      throw HttpUtils.handleError(e);
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
        '/table-data',
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
      throw HttpUtils.handleError(e);
    }
  }
}
