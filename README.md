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

## 项目结构 / Project Structure

```
lib/
  ├── main.dart                # 应用入口 / App entry
  ├── routes/                  # 路由配置 / Route configurations
  │   ├── app_pages.dart       # 页面路由定义 / Page route definitions
  │   └── app_routes.dart      # 路由常量 / Route constants
  ├── screens/                 # 页面 / Screens
  │   ├── connection/          # 数据库连接页面 / Database connection pages
  │   ├── database/           # 数据库管理页面 / Database management pages
  │   ├── query/              # 查询页面 / Query pages
  │   ├── table/              # 表格管理页面 / Table management pages
  │   └── download/           # 下载页面 / Download pages
  ├── bindings/               # GetX绑定 / GetX bindings
  │   ├── query_binding.dart  # 查询相关绑定 / Query related bindings
  │   └── table_binding.dart  # 表格相关绑定 / Table related bindings
  ├── controllers/            # GetX控制器 / GetX controllers
  │   ├── theme_controller.dart    # 主题控制器 / Theme controller
  │   ├── query_controller.dart    # 查询控制器 / Query controller
  │   └── table_controller.dart    # 表格控制器 / Table controller
  ├── models/                 # 数据模型 / Data models
  ├── services/               # 服务 / Services
  │   ├── database/          # 数据库服务 / Database services
  │   ├── download/          # 下载服务 / Download services
  │   └── query/             # 查询服务 / Query services
  ├── widgets/               # 通用组件 / Common widgets
  ├── utils/                 # 工具类 / Utilities
  ├── i18n/                  # 国际化 / Internationalization
  │   ├── translations.dart  # 翻译文件 / Translation files
  │   └── locale_controller.dart # 语言控制器 / Locale controller
  ├── themes/                # 主题配置 / Theme configurations
  └── config/               # 应用配置 / App configurations
```

## 主要功能 / Main Features

### 数据库连接管理 / Database Connection Management
- 多数据库配置支持 / Multiple database configurations
- 安全的密码存储 / Secure password storage
- 连接池管理 / Connection pool management
- 离线模式支持 / Offline mode support

### 数据库操作 / Database Operations
- 数据库创建与删除 / Create and delete databases
- 表格管理 / Table Management
  - 创建/修改/删除表 / Create/Alter/Drop tables
  - 字段类型支持 / Field type support
  - 索引管理 / Index management
- 数据操作 / Data Operations
  - 批量导入导出 / Bulk import/export
  - 数据编辑 / Data editing
  - 行级操作 / Row-level operations

### 查询功能 / Query Features
- SQL编辑器 / SQL Editor
  - 语法高亮 / Syntax highlighting
  - 自动完成 / Auto-completion
  - 格式化 / Formatting
- 查询历史 / Query History
  - 历史记录管理 / History management
  - 收藏查询 / Favorite queries
- 结果展示 / Results Display
  - 表格视图 / Table view
  - 导出功能 / Export functionality

### 系统功能 / System Features
- 多语言支持 / Multi-language Support
  - 中文 / Chinese
  - 英文 / English
- 主题切换 / Theme Switching
  - 亮色主题 / Light theme
  - 暗色主题 / Dark theme
- 自动更新 / Auto Update
  - 版本检查 / Version check
  - 增量更新 / Incremental update

## 开发指南 / Development Guide

### 环境配置 / Environment Setup
```bash
# 获取依赖 / Get dependencies
flutter pub get

# 运行开发环境 / Run development environment
flutter run
```

### 构建发布 / Build Release

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

#### Windows
```bash
flutter build windows --release
```

#### macOS
```bash
flutter build macos --release
```

#### Linux
```bash
flutter build linux --release
```

#### Web
```bash
flutter build web --release
```

## 测试 / Testing

```bash
# 运行所有测试 / Run all tests
flutter test

# 运行单个测试文件 / Run single test file
flutter test test/widget_test.dart

# 运行带覆盖率的测试 / Run tests with coverage
flutter test --coverage
```

## 版本历史 / Version History

- v0.1.0: 初始版本 / Initial Release
  - 基础数据库连接 / Basic database connection
  - 查询功能 / Query features
  - 表格管理 / Table management

## 贡献指南 / Contributing

1. Fork 项目 / Fork the Project
2. 创建特性分支 / Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. 提交更改 / Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 / Push to the Branch (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request / Open a Pull Request

## 许可证 / License

MIT License - 查看 [LICENSE](LICENSE) 文件了解更多详情。
See [LICENSE](LICENSE) for more information.

## 联系方式 / Contact

- Email: support@yinta.com
- Website: https://yinta.com
- Issues: https://github.com/yinta/tms-flutter/issues
