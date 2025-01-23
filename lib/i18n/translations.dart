/// 应用程序翻译文件
/// 使用GetX的国际化支持功能
/// 定义所有需要国际化的文本内容
/// 支持英文(en_US)和简体中文(zh_CN)两种语言

import 'package:get/get.dart';

/// 翻译消息类
/// 继承自GetX的Translations类
/// 提供应用程序所有界面文本的多语言翻译
/// 使用Map结构存储不同语言的键值对
class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        /// 英文翻译
        /// 地区：美国（en_US）
        /// 包含所有需要显示的英文文本
        'en_US': {
          // 连接页面相关翻译
          'tms_connect': 'TMS Connect', // 应用名称
          'host': 'Host', // 主机地址
          'port': 'Port', // 端口号
          'username': 'Username', // 用户名
          'password': 'Password', // 密码
          'database': 'Database', // 数据库
          'connect': 'Connect', // 连接按钮

          // 已保存连接相关翻译
          'saved_connections': 'Saved Connections', // 已保存连接列表

          // 主题切换相关翻译
          'switch_to_light': 'Switch to Light Theme', // 切换到亮色主题
          'switch_to_dark': 'Switch to Dark Theme', // 切换到暗色主题

          // 语言和下载相关翻译
          'language': 'Language', // 语言选择
          'download_apps': 'Download Apps', // 下载应用
          'check_update': 'Check Update', // 检查更新
          'checking_update': 'Checking Update...', // 正在检查更新
          'update_available': 'Update Available', // 有新版本可用
          'current_version': 'Current Version', // 当前版本
          'latest_version': 'Latest Version', // 最新版本
          'update_now': 'Update Now', // 立即更新
          'update_later': 'Update Later', // 稍后更新
          'no_update': 'No Update Available', // 无可用更新
          'download_error': 'Download Error', // 下载错误
          'disconnect': 'Disconnect', // 断开连接

          // 配置相关翻译
          'basic_config': 'Basic Configuration', // 基本配置
          'config_name': 'Configuration Name', // 配置名称
          'authentication': 'Authentication', // 认证信息
          'advanced_options': 'Advanced Options', // 高级选项
          'database_name': 'Database Name (Optional)', // 数据库名称

          // 离线模式相关翻译
          'offline_mode': 'Offline Mode', // 离线模式
          'offline_mode_desc':
              'Direct database connection without backend service', // 离线模式描述
          'offline_mode_web_unavailable':
              'Offline mode is not available on Web', // Web版离线模式不可用提示
          'offline_mode_web_desc':
              'Due to browser security restrictions, Web version can only connect through backend service', // Web版限制说明

          // 操作按钮翻译
          'test': 'Test', // 测试按钮
          'save': 'Save', // 保存按钮

          // 表单验证提示翻译
          'please_enter_host': 'Please enter host', // 主机地址验证
          'please_enter_port': 'Please enter port', // 端口号验证
          'invalid_port': 'Invalid port number', // 无效端口号
          'please_enter_username': 'Please enter username', // 用户名验证

          // 查询相关翻译
          'sql_query': 'Query', // SQL查询

          // 表格相关翻译
          'table_search': 'Search tables',
          'view_full_content': 'View Full Content',
          'full_content': 'Full Content',
          'field_content': 'Field Content',
          'copy': 'Copy',
          'close': 'Close',
          'copied': 'Copied',
          'content_copied': 'Content copied to clipboard',
          'delete': 'Delete',
          'rows_affected': '{count} rows',
          'not_released': 'Not Released',
          'current_platform': 'Current Platform: {platform}',
          'choose_platform': 'Choose Your Platform',
          'web_version': 'Web Version',
          'version': 'Version: {version}',
          'recommended': 'Recommended',
          'structure': 'Structure',
          'download_complete': 'Download Complete',
          'install_update_prompt':
              'The update has been downloaded. Would you like to install it now?',
          'cancel': 'Cancel',
          'install': 'Install',
          'error': 'Error',
          'install_failed': 'Failed to install the update. Please try again.',
        },

        /// 中文翻译
        /// 地区：中国大陆（zh_CN）
        /// 包含所有需要显示的中文文本
        'zh_CN': {
          // 连接页面相关翻译
          'tms_connect': 'TMS 连接', // 应用名称
          'host': '主机', // 主机地址
          'port': '端口', // 端口号
          'username': '用户名', // 用户名
          'password': '密码', // 密码
          'database': '数据库', // 数据库
          'connect': '连接', // 连接按钮

          // 已保存连接相关翻译
          'saved_connections': '已保存连接', // 已保存连接列表

          // 主题切换相关翻译
          'switch_to_light': '切换到亮色主题', // 切换到亮色主题
          'switch_to_dark': '切换到暗色主题', // 切换到暗色主题

          // 语言和下载相关翻译
          'language': '语言', // 语言选择
          'download_apps': '下载应用', // 下载应用
          'check_update': '检查更新', // 检查更新
          'checking_update': '正在检查更新...', // 正在检查更新
          'update_available': '发现新版本', // 有新版本可用
          'current_version': '当前版本', // 当前版本
          'latest_version': '最新版本', // 最新版本
          'update_now': '立即更新', // 立即更新
          'update_later': '稍后更新', // 稍后更新
          'no_update': '已是最新版本', // 无可用更新
          'download_error': '下载错误', // 下载错误
          'disconnect': '断开连接', // 断开连接

          // 配置相关翻译
          'basic_config': '基本配置', // 基本配置
          'config_name': '配置名称', // 配置名称
          'authentication': '认证信息', // 认证信息
          'advanced_options': '高级选项', // 高级选项
          'database_name': '数据库名称（可选）', // 数据库名称

          // 离线模式相关翻译
          'offline_mode': '离线模式', // 离线模式
          'offline_mode_desc': '直接连接数据库，不通过后端服务', // 离线模式描述
          'offline_mode_web_unavailable': '离线模式在Web平台不可用', // Web版离线模式不可用提示
          'offline_mode_web_desc': '由于浏览器安全限制，Web版本只能通过后端服务连接数据库', // Web版限制说明

          // 操作按钮翻译
          'test': '测试', // 测试按钮
          'save': '保存', // 保存按钮

          // 表单验证提示翻译
          'please_enter_host': '请输入主机地址', // 主机地址验证
          'please_enter_port': '请输入端口号', // 端口号验证
          'invalid_port': '端口号无效', // 无效端口号
          'please_enter_username': '请输入用户名', // 用户名验证

          // 查询相关翻译
          'sql_query': '查询', // SQL查询

          // 表格相关翻译
          'table_search': '搜索表',
          'view_full_content': '查看完整内容',
          'full_content': '完整内容',
          'field_content': '字段内容',
          'copy': '复制',
          'close': '关闭',
          'copied': '复制成功',
          'content_copied': '内容已复制到剪贴板',
          'delete': '删除',
          'rows_affected': '{count} 行',
          'not_released': '暂未发布',
          'current_platform': '当前平台: {platform}',
          'choose_platform': '选择您的平台',
          'web_version': 'Web版本',
          'version': '版本: {version}',
          'recommended': '推荐',
          'structure': '结构',
          'download_complete': '下载完成',
          'install_update_prompt': '更新已下载完成，是否立即安装？',
          'cancel': '取消',
          'install': '安装',
          'error': '错误',
          'install_failed': '安装更新失败，请重试。',
        },
      };
}
