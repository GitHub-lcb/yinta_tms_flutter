# Yinta TMS Flutter

跨平台 MySQL 数据库管理工具 / Cross-platform MySQL Database Management Tool

## 项目介绍 / Project Introduction

这是一个基于 Flutter 开发的跨平台数据库管理应用，支持在移动端、桌面端和 Web 端运行。本应用提供了便捷的 MySQL 数据库操作界面，支持表格管理、字段操作和数据查询等功能。

This is a Flutter-based cross-platform database management application that runs on mobile, desktop, and web platforms. It provides a user-friendly interface for MySQL database operations, supporting table management, field operations, and data querying.

## 技术栈 / Tech Stack

- Flutter (跨平台开发框架 / Cross-platform Framework)
- Dart
- State Management: GetX (状态管理 / State Management)
- Database: MySQL (后端数据库 / Backend Database)
- Network: Dio (网络请求 / Network Requests)
- mysql1 (MySQL 连接器 / MySQL Connector)

## 开发环境要求 / Development Environment

- Flutter SDK (3.24.3 或更高版本 / 3.24.3 or higher)
- Dart SDK (3.5.3 或更高版本 / 3.5.3 or higher)
- Android Studio / VS Code
- MySQL Server (5.7 或更高版本 / 5.7 or higher)
- Android SDK (安卓开发 / for Android development)
- Xcode (iOS 开发，仅 macOS / for iOS development, macOS only)

## 主要功能 / Main Features

- 数据库连接管理 / Database Connection Management
  - 支持多数据库配置 / Multiple database configurations
  - 安全的密码存储 / Secure password storage
  
- 数据库操作 / Database Operations
  - 创建/删除数据库 / Create/Delete databases
  - 表格管理 / Table Management
  - 字段操作 / Field Operations
  
- 数据查询功能 / Data Query Features
  - SQL 查询编辑器 / SQL Query Editor
  - 查询结果可视化 / Query Results Visualization
  - 查询历史记录 / Query History
  
- 数据导入导出 / Data Import/Export
  - 支持多种格式 (CSV, SQL) / Multiple formats support
  
- 跨平台支持 / Cross-platform Support
  - Android/iOS 移动端 / Mobile
  - Windows/macOS/Linux 桌面端 / Desktop
  - Web 浏览器访问 / Web Browser Access

## 项目结构 / Project Structure

```
lib/
  ├── main.dart              # 应用入口 / App entry
  ├── screens/               # 页面 / Screens
  │   ├── connection/        # 数据库连接页面 / Database connection pages
  │   ├── query/            # 查询页面 / Query pages
  │   └── table/            # 表格管理页面 / Table management pages
  ├── widgets/              # 组件 / Widgets
  ├── models/              # 数据模型 / Data models
  ├── services/            # 服务 / Services
  │   ├── database/        # 数据库服务 / Database services
  │   └── auth/           # 认证服务 / Authentication services
  ├── utils/              # 工具类 / Utilities
  └── config/             # 配置文件 / Configurations
```

## 主要功能 / Main Features

- 数据库连接管理 / Database Connection Management
- 数据库操作 / Database Operations
- 数据查询功能 / Data Query Features
- 数据导入导出 / Data Import/Export
- 跨平台支持 / Cross-platform Support

## 构建发布 / Build Release

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## 测试 / Testing

运行测试 / Run tests:
```bash
flutter test
```

## 版本历史 / Version History

- v0.1.0: 初始版本 - 基础数据库连接和查询功能 / Initial Release - Basic database connection and query features

## 贡献指南 / Contributing

欢迎提交问题和改进建议。
Contributions, issues, and feature requests are welcome.

## 许可证 / License

MIT License

## 联系方式 / Contact

- Email: support@yinta.com
- Website: https://yinta.com
