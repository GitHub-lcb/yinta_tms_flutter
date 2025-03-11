/// MySQL数据库服务文件
/// 实现了DatabaseService接口
/// 负责处理与MySQL数据库服务器的所有交互
/// 使用HTTP API与后端服务通信
/// 主要功能：
/// 1. 数据库连接管理
/// 2. SQL查询执行
/// 3. 数据库和表的元数据获取
/// 4. 数据导出功能

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
/// 继承自GetxService以支持依赖注入
/// 实现DatabaseService接口以确保实现所有必要的数据库操作方法
/// 使用Dio进行HTTP请求
/// 支持JWT token认证
class MySqlService extends GetxService implements DatabaseService {
  /// HTTP客户端实例
  /// 使用Dio库进行HTTP请求
  /// 基础URL配置来自ApiConfig
  final _dio = HttpUtils.createDio(ApiConfig.baseUrl);

  /// 当前会话的认证令牌
  /// 在成功连接数据库后由服务器返回
  /// 用于后续请求的认证
  String? _token;

  /// 测试数据库连接方法
  /// 尝试与数据库建立连接但不保持连接状态
  /// 用于在实际连接前验证连接参数的正确性
  ///
  /// @param config 数据库连接配置信息，包含主机、端口、用户名等
  /// @return Future<bool> 连接测试结果
  /// @throws Exception 当连接测试失败时抛出异常
  Future<bool> testConnection(ConnectionConfig config) async {
    try {
      // 发送连接测试请求
      final response = await _dio.post('/connect', data: config.toJson());
      if (response.statusCode == 200) {
        // 获取临时token
        final tempToken = response.data['token'];
        // 立即断开连接，因为这只是测试
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
      // 转换并抛出格式化的错误信息
      throw HttpUtils.handleError(e);
    }
  }

  /// 连接到MySQL数据库方法
  /// 建立与数据库的持久连接
  /// 成功连接后会获取并保存认证令牌
  ///
  /// @param config 数据库连接配置信息
  /// @throws Exception 当连接失败时抛出异常
  Future<void> connect(ConnectionConfig config) async {
    try {
      // 发送连接请求
      final response = await _dio.post('/connect', data: config.toJson());
      // 保存认证令牌供后续请求使用
      _token = response.data['token'];
    } catch (e) {
      // 转换并抛出格式化的错误信息
      throw HttpUtils.handleError(e);
    }
  }

  /// 断开数据库连接方法
  /// 关闭与数据库的连接并清除认证令牌
  /// 即使请求失败也会清除本地token
  ///
  /// @throws Exception 当断开连接失败时抛出异常
  Future<void> disconnect() async {
    try {
      // 发送断开连接请求
      await _dio.post(
        '/disconnect',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
      // 清除认证令牌
      _token = null;
    } catch (e) {
      if (e is DioException) {
        // 即使请求失败，也要清除token
        _token = null;
        // 如果是因为已经断开连接导致的错误，可以忽略
        if (e.type == DioExceptionType.unknown && e.message == null) {
          return;
        }
      }
      throw HttpUtils.handleError(e);
    }
  }

  /// 获取数据库列表方法
  /// 获取当前用户有权限访问的所有数据库
  ///
  /// @return Future<List<String>> 数据库名称列表
  /// @throws Exception 当获取失败时抛出异常
  Future<List<String>> getDatabases() async {
    try {
      print('Fetching databases with token: $_token');
      // 发送获取数据库列表请求
      final response = await _dio.get(
        '/databases',
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
        ),
      );
      print('Response data: ${response.data}');

      // 处理不同格式的响应数据
      if (response.data is List) {
        // 直接返回数据库列表
        return List<String>.from(response.data);
      } else if (response.data is Map && response.data['databases'] is List) {
        // 从嵌套结构中提取数据库列表
        return List<String>.from(response.data['databases']);
      }
      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      print('Error fetching databases: $e');
      throw HttpUtils.handleError(e);
    }
  }

  /// 选择数据库方法
  /// 切换当前会话的活动数据库
  ///
  /// @param database 要切换到的数据库名称
  /// @throws Exception 当切换失败时抛出异常
  Future<void> selectDatabase(String database) async {
    try {
      // 发送选择数据库请求
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

  /// 获取数据库表列表方法
  /// 获取指定数据库中的所有表
  /// 支持分页获取
  ///
  /// @param database 数据库名称
  /// @param offset 分页起始位置（可选）
  /// @param limit 每页数量（可选）
  /// @return Future<Map<String, dynamic>> 包含表列表和总数的Map
  /// @throws Exception 当获取失败时抛出异常
  Future<Map<String, dynamic>> getTables(String database,
      {int? offset, int? limit}) async {
    try {
      print('Fetching tables for database: $database');
      print('Using token: $_token');

      // 构建查询参数
      final queryParams = {
        'database': database,
        if (offset != null) 'offset': offset.toString(),
        if (limit != null) 'limit': limit.toString(),
      };

      // 发送获取表列表请求
      final response = await _dio.get(
        '/tables',
        queryParameters: queryParams,
        options: Options(
          headers: {'Authorization': 'Bearer $_token'},
          validateStatus: (status) => true, // 接受所有状态码以便调试
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      // 检查响应状态码
      if (response.statusCode != 200) {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.data}');
      }

      // 处理不同格式的响应数据
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['tables'] is List) {
          return {
            'total': data['total'] ?? data['tables'].length,
            'tables': List<String>.from(data['tables']),
          };
        }
      }

      if (response.data is List) {
        final tables = List<String>.from(response.data);
        return {
          'total': tables.length,
          'tables': tables,
        };
      }

      throw Exception('Unexpected response format: ${response.data}');
    } catch (e) {
      // 详细的错误日志记录
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

  /// 执行SQL查询方法
  /// 在指定数据库上执行SQL查询语句
  /// 支持所有类型的SQL语句（SELECT, INSERT, UPDATE, DELETE等）
  ///
  /// @param database 数据库名称
  /// @param query SQL查询语句
  /// @return Future<Map<String, dynamic>> 查询结果
  /// @throws Exception 当查询执行失败时抛出异常
  Future<Map<String, dynamic>> executeQuery(
      String database, String query) async {
    try {
      print('Executing query on database $database: $query');
      // 发送查询执行请求
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

      // 处理错误响应
      if (response.statusCode != 200) {
        if (response.data is Map && response.data['message'] != null) {
          throw Exception(response.data['message']);
        }
        throw Exception('Server returned ${response.statusCode}');
      }

      // 处理DDL语句 (CREATE, ALTER, DROP等)
      final ddlPattern = RegExp(r'^\s*(CREATE|ALTER|DROP|TRUNCATE|RENAME)\s+',
          caseSensitive: false);
      if (ddlPattern.hasMatch(query)) {
        return {
          'columns': ['Result'],
          'rows': [
            ['Query executed successfully']
          ],
        };
      }

      // 检查是否是 SELECT 查询
      final isSelect =
          RegExp(r'^\s*SELECT\s+', caseSensitive: false).hasMatch(query);

      // 如果响应数据是Map类型
      if (response.data is Map<String, dynamic>) {
        final data = response.data;

        // 如果是非SELECT语句且有affectedRows字段
        if (!isSelect && data['affectedRows'] != null) {
          return {
            'columns': ['Affected Rows'],
            'rows': [
              [data['affectedRows']]
            ],
          };
        }

        // 如果有results字段且是列表
        if (data['results'] is List) {
          final results = data['results'] as List;
          if (results.isEmpty) {
            return {
              'columns': [],
              'rows': [],
            };
          }

          // 获取第一行数据来提取字段名
          final firstRow = results.first as Map<String, dynamic>;
          // 过滤掉内部字段（以下划线开头的字段）
          final validFields = firstRow.keys
              .where((field) => !field.toString().startsWith('_'))
              .toList();

          // 构建行数据
          final rows = results.map((row) {
            if (row is Map<String, dynamic>) {
              return validFields.map((field) => row[field]).toList();
            }
            return [];
          }).toList();

          return {
            'columns': validFields,
            'rows': rows,
          };
        }
      }

      // 如果响应数据是列表类型
      if (response.data is List) {
        final results = response.data as List;
        if (results.isEmpty) {
          return {
            'columns': [],
            'rows': [],
          };
        }

        // 获取第一行数据来提取字段名
        final firstRow = results.first as Map<String, dynamic>;
        // 过滤掉内部字段（以下划线开头的字段）
        final validFields = firstRow.keys
            .where((field) => !field.toString().startsWith('_'))
            .toList();

        // 构建行数据
        final rows = results.map((row) {
          if (row is Map<String, dynamic>) {
            return validFields.map((field) => row[field]).toList();
          }
          return [];
        }).toList();

        return {
          'columns': validFields,
          'rows': rows,
        };
      }

      // 如果数据格式无法识别，返回空结果
      return {
        'columns': [],
        'rows': [],
      };
    } catch (e) {
      print('Query execution error: $e');
      throw HttpUtils.handleError(e);
    }
  }

  /// 将查询结果导出为Excel文件
  Future<void> exportToExcel(
    String query,
    String filename, {
    String? mimeType,
  }) async {
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
        mimeType: mimeType,
      );
    } catch (e) {
      throw HttpUtils.handleError(e);
    }
  }

  /// 将查询结果导出为CSV文件
  Future<void> exportToCsv(
    String query,
    String filename, {
    String? mimeType,
  }) async {
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
        mimeType: mimeType,
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

  /// 获取建表语句方法
  /// 获取指定表的建表语句
  ///
  /// @param database 数据库名称
  /// @param table 表名
  /// @return Future<String> 建表语句
  /// @throws Exception 当获取失败时抛出异常
  @override
  Future<String> getCreateTableStatement(String database, String table) async {
    try {
      // 发送请求到新的端点
      final response = await _dio.get(
        '/create-table-statement',
        queryParameters: {
          'database': database,
          'table': table,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $_token',
          },
        ),
      );

      // 检查响应
      if (response.data == null || !response.data.containsKey('statement')) {
        throw Exception('无效的响应数据');
      }

      return response.data['statement'] as String;
    } catch (e) {
      print('获取建表语句失败: $e');
      throw HttpUtils.handleError(e);
    }
  }
}
