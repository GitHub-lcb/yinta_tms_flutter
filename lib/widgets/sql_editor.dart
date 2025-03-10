/// SQL编辑器组件文件
/// 提供功能丰富的SQL代码编辑器
/// 基于code_text_field和highlight包实现
/// 主要功能：
/// 1. SQL语法高亮显示
/// 2. 智能代码提示和自动完成
/// 3. 支持SQL格式化
/// 4. 支持快捷键操作
/// 5. 支持表名和列名自动完成

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/sql.dart';

/// SQL编辑器组件类
/// 提供可视化的SQL编辑功能
/// 支持语法高亮、代码提示和自动完成
/// 可配置为只读模式
///
/// 特性：
/// 1. 支持SQL语法高亮显示
/// 2. 提供智能代码提示和自动完成
/// 3. 支持表名和列名自动补全
/// 4. 集成快捷键操作
/// 5. 可配置只读模式
class SqlEditor extends StatefulWidget {
  /// 初始SQL语句
  /// 编辑器启动时显示的SQL代码
  /// 如果为null则显示空编辑器
  final String? initialValue;

  /// SQL语句变化回调函数
  /// 当编辑器内容发生变化时调用
  /// 用于实时获取编辑器的内容
  final ValueChanged<String>? onChanged;

  /// 执行SQL语句回调函数
  /// 当用户触发执行操作时调用（如按下F5）
  /// 用于实现SQL语句的执行功能
  final VoidCallback? onExecute;

  /// 是否为只读模式
  /// true表示用户不能编辑内容
  /// false表示用户可以自由编辑
  final bool readOnly;

  /// 可用的表名列表
  /// 用于自动完成功能
  /// 当用户输入时提供表名建议
  final List<String> tables;

  /// 可用的列名列表
  /// 用于自动完成功能
  /// 当用户输入时提供列名建议
  final List<String> columns;

  /// 构造函数
  /// 创建一个新的SQL编辑器实例
  ///
  /// @param key Widget的键
  /// @param initialValue 初始SQL语句
  /// @param onChanged 内容变化回调
  /// @param onExecute 执行回调
  /// @param readOnly 是否只读
  /// @param tables 表名列表
  /// @param columns 列名列表
  const SqlEditor({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onExecute,
    this.readOnly = false,
    this.tables = const [],
    this.columns = const [],
  });

  @override
  State<SqlEditor> createState() => _SqlEditorState();
}

/// SQL编辑器状态类
/// 管理编辑器的内部状态和行为
/// 实现编辑器的核心功能
/// 处理用户输入和自动完成
class _SqlEditorState extends State<SqlEditor> {
  /// 代码编辑器控制器
  /// 管理编辑器的文本内容和选择
  /// 处理文本变化和光标移动
  late CodeController _codeController;

  /// 自动完成菜单的位置链接
  /// 用于将自动完成菜单定位到正确的位置
  /// 跟随光标位置移动
  final LayerLink _layerLink = LayerLink();

  /// 自动完成菜单的覆盖层
  /// 显示自动完成建议列表
  /// 当不需要时为null
  OverlayEntry? _overlayEntry;

  /// 编辑器焦点节点
  /// 管理编辑器的键盘焦点
  /// 用于控制自动完成菜单的显示和隐藏
  final FocusNode _focusNode = FocusNode();

  /// 当前正在输入的单词
  /// 用于自动完成功能
  /// 根据此值筛选建议列表
  String _currentWord = '';

  /// 自动完成建议列表
  /// 包含当前可用的自动完成选项
  /// 根据用户输入动态更新
  List<String> _suggestions = [];

  /// 当前选中的建议项索引
  /// 在自动完成列表中当前高亮的项
  /// 用于键盘导航
  int _selectedIndex = 0;

  /// SQL关键字样式映射
  /// 定义不同类型SQL关键字的显示样式
  /// 用于实现语法高亮
  static final Map<String, TextStyle> _keywords = {
    // DML关键字 - 数据操作语言
    // 用于数据查询和修改的关键字
    'SELECT':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'INSERT':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'UPDATE':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'DELETE':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'FROM': const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'WHERE': const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'GROUP BY':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'ORDER BY':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'HAVING':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'LIMIT': const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'OFFSET':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'INTO': const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'VALUES':
        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
    'SET': const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),

    // DDL关键字 - 数据定义语言
    // 用于数据库结构定义的关键字
    'CREATE': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'ALTER': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'DROP': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'TRUNCATE':
        const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'TABLE': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'INDEX': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'VIEW': const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
    'DATABASE':
        const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),

    // 连接关键字
    // 用于表连接操作的关键字
    'JOIN': const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'INNER JOIN':
        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'LEFT JOIN':
        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'RIGHT JOIN':
        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'FULL JOIN':
        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'CROSS JOIN':
        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
    'ON': const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),

    // 运算符关键字
    // 用于条件判断和逻辑运算的关键字
    'AND': const TextStyle(color: Colors.red),
    'OR': const TextStyle(color: Colors.red),
    'NOT': const TextStyle(color: Colors.red),
    'IN': const TextStyle(color: Colors.red),
    'LIKE': const TextStyle(color: Colors.red),
    'BETWEEN': const TextStyle(color: Colors.red),
    'IS NULL': const TextStyle(color: Colors.red),
    'IS NOT NULL': const TextStyle(color: Colors.red),

    // 函数关键字
    // 用于聚合和计算的函数关键字
    'COUNT': const TextStyle(color: Colors.teal),
    'SUM': const TextStyle(color: Colors.teal),
    'AVG': const TextStyle(color: Colors.teal),
    'MAX': const TextStyle(color: Colors.teal),
    'MIN': const TextStyle(color: Colors.teal),
    'DISTINCT': const TextStyle(color: Colors.teal),
  };

  /// 额外的SQL关键字列表
  /// 仅用于自动完成功能
  /// 包含一些常用但不需要特殊样式的SQL关键字
  static const List<String> _additionalKeywords = [
    'AS',
    'ASC',
    'DESC',
    'CASE',
    'WHEN',
    'THEN',
    'ELSE',
    'END',
    'UNION',
    'ALL',
    'ANY',
    'EXISTS',
    'HAVING',
    'IN',
    'IS',
    'NULL',
    'UNIQUE',
    'PRIMARY KEY',
    'FOREIGN KEY',
    'REFERENCES',
    'CASCADE',
    'RESTRICT',
    'DEFAULT',
    'AUTO_INCREMENT',
  ];

  /// 初始化方法
  /// 在组件创建时调用
  /// 设置编辑器的初始状态和事件监听器
  @override
  void initState() {
    super.initState();
    // 初始化代码编辑器控制器
    _codeController = CodeController(
      text: widget.initialValue ?? '',
      language: sql,
      // 配置正则表达式匹配的样式
      patternMap: {
        r'".*?"': const TextStyle(color: Color(0xFF98C379)), // 双引号字符串
        r"'.*?'": const TextStyle(color: Color(0xFF98C379)), // 单引号字符串
        r'\d+': const TextStyle(color: Color(0xFF61AFEF)), // 数字
        r'--.*': const TextStyle(color: Color(0xFF5C6370)), // 单行注释
        r'/\*.*?\*/': const TextStyle(color: Color(0xFF5C6370)), // 多行注释
        r'`.*?`': const TextStyle(color: Color(0xFFE5C07B)), // 反引号标识符
      },
      // 配置关键字样式
      stringMap: {
        // DML关键字
        'SELECT': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'INSERT': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'UPDATE': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'DELETE': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'FROM': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'WHERE': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'GROUP BY': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'ORDER BY': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'HAVING': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'LIMIT': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'OFFSET': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'INTO': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'VALUES': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),
        'SET': const TextStyle(
            color: Color(0xFFC678DD), fontWeight: FontWeight.bold),

        // DDL关键字
        'CREATE': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'ALTER': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'DROP': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'TRUNCATE': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'TABLE': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'INDEX': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'VIEW': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),
        'DATABASE': const TextStyle(
            color: Color(0xFF61AFEF), fontWeight: FontWeight.bold),

        // 连接关键字
        'JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'INNER JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'LEFT JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'RIGHT JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'FULL JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'CROSS JOIN': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),
        'ON': const TextStyle(
            color: Color(0xFFE5C07B), fontWeight: FontWeight.bold),

        // 运算符关键字
        'AND': const TextStyle(color: Color(0xFFE06C75)),
        'OR': const TextStyle(color: Color(0xFFE06C75)),
        'NOT': const TextStyle(color: Color(0xFFE06C75)),
        'IN': const TextStyle(color: Color(0xFFE06C75)),
        'LIKE': const TextStyle(color: Color(0xFFE06C75)),
        'BETWEEN': const TextStyle(color: Color(0xFFE06C75)),
        'IS NULL': const TextStyle(color: Color(0xFFE06C75)),
        'IS NOT NULL': const TextStyle(color: Color(0xFFE06C75)),

        // 函数关键字
        'COUNT': const TextStyle(color: Color(0xFF98C379)),
        'SUM': const TextStyle(color: Color(0xFF98C379)),
        'AVG': const TextStyle(color: Color(0xFF98C379)),
        'MAX': const TextStyle(color: Color(0xFF98C379)),
        'MIN': const TextStyle(color: Color(0xFF98C379)),
        'DISTINCT': const TextStyle(color: Color(0xFF98C379)),
      },
    );

    // 添加文本变化监听器
    _codeController.addListener(() {
      // 调用外部回调
      widget.onChanged?.call(_codeController.text);
      // 更新自动完成建议
      _updateSuggestions();
    });

    // 添加焦点监听器
    _focusNode.addListener(() {
      // 失去焦点时隐藏自动完成菜单
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  /// 资源释放方法
  /// 在组件销毁时调用
  /// 清理所有使用的资源
  @override
  void dispose() {
    // 隐藏自动完成菜单
    _hideOverlay();
    // 释放控制器
    _codeController.dispose();
    // 释放焦点节点
    _focusNode.dispose();
    super.dispose();
  }

  /// 更新自动完成建议列表
  /// 根据当前输入的内容筛选可能的建议
  /// 处理自动完成菜单的显示和隐藏
  void _updateSuggestions() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    // 检查选择是否有效
    if (!selection.isValid || selection.start != selection.end) {
      _hideOverlay();
      return;
    }

    // 获取当前正在输入的单词
    final beforeCursor = text.substring(0, selection.start);
    final words = beforeCursor.split(RegExp(r'[\s\n]'));
    _currentWord = words.isEmpty ? '' : words.last.toUpperCase();

    // 如果没有输入内容，隐藏自动完成菜单
    if (_currentWord.isEmpty) {
      _hideOverlay();
      return;
    }

    // 收集所有可能的建议
    final allSuggestions = [
      ..._keywords.keys, // SQL关键字
      ..._additionalKeywords, // 额外关键字
      ...widget.tables.map((t) => t.toUpperCase()), // 表名
      ...widget.columns.map((c) => c.toUpperCase()), // 列名
    ];

    // 根据当前输入筛选建议
    _suggestions = allSuggestions
        .where((s) => s.startsWith(_currentWord) && s != _currentWord)
        .toList();

    // 如果没有建议，隐藏自动完成菜单
    if (_suggestions.isEmpty) {
      _hideOverlay();
      return;
    }

    // 重置选中项索引
    _selectedIndex = 0;

    // 显示或更新自动完成菜单
    if (_overlayEntry == null) {
      _showOverlay();
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// 显示自动完成菜单
  /// 在编辑器下方显示建议列表
  void _showOverlay() {
    _hideOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height,
            width: 300,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Material(
                elevation: 8,
                color: const Color(0xFF282C34),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF3E4451)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 标题栏
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF21252B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Color(0xFFABB2BF),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '代码提示 / Code Suggestions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${_suggestions.length} 个建议',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11,
                                  fontFamily: 'JetBrainsMono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 建议列表
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            final isKeyword = _keywords.containsKey(suggestion);
                            return MouseRegion(
                              onEnter: (_) {
                                _selectedIndex = index;
                                setState(() {});
                                _overlayEntry?.markNeedsBuild();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: index == _selectedIndex
                                      ? const Color(0xFF2C313A)
                                      : null,
                                ),
                                child: ListTile(
                                  dense: true,
                                  minLeadingWidth: 32,
                                  horizontalTitleGap: 8,
                                  leading: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: (isKeyword
                                              ? const Color(0xFFC678DD)
                                              : const Color(0xFF61AFEF))
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      isKeyword
                                          ? Icons.code
                                          : Icons.table_chart,
                                      size: 14,
                                      color: isKeyword
                                          ? const Color(0xFFC678DD)
                                          : const Color(0xFF61AFEF),
                                    ),
                                  ),
                                  title: Text(
                                    suggestion,
                                    style: TextStyle(
                                      fontFamily: 'JetBrainsMono',
                                      fontSize: 13,
                                      height: 1.4,
                                      color: index == _selectedIndex
                                          ? Colors.white
                                          : const Color(0xFFABB2BF),
                                      fontWeight: index == _selectedIndex
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      isKeyword
                                          ? 'SQL关键字 / Keyword'
                                          : '表名/字段 / Table/Column',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.2,
                                        color: Colors.white.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                                  trailing: index == _selectedIndex
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Enter',
                                            style: TextStyle(
                                              color: Color(0xFFABB2BF),
                                              fontSize: 11,
                                              fontFamily: 'JetBrainsMono',
                                            ),
                                          ),
                                        )
                                      : null,
                                  onTap: () => _applySuggestion(suggestion),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // 底部提示
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF21252B),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard,
                              size: 14,
                              color: Colors.white.withOpacity(0.4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '↑↓ 选择  |  Enter 确认  |  Esc 关闭',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// 隐藏自动完成菜单
  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 应用选中的自动完成建议
  /// 将选中的建议文本插入到当前光标位置
  ///
  /// 参数:
  /// - [suggestion]: 要应用的建议文本
  void _applySuggestion(String suggestion) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final beforeCursor = text.substring(0, selection.start);
    final afterCursor = text.substring(selection.start);
    final lastWord = beforeCursor.split(RegExp(r'[\s\n]')).last;

    // 替换当前单词为建议文本
    final newText =
        beforeCursor.substring(0, beforeCursor.length - lastWord.length) +
            suggestion +
            afterCursor;

    _codeController.text = newText;
    final newPosition = selection.start - lastWord.length + suggestion.length;
    _codeController.selection = TextSelection.collapsed(offset: newPosition);

    _hideOverlay();
  }

  /// 处理键盘事件
  /// 处理上下键选择建议、Tab和Enter键应用建议、Esc键关闭建议菜单
  ///
  /// 参数:
  /// - [event]: 键盘事件对象
  void _handleKeyEvent(RawKeyEvent event) {
    if (_overlayEntry == null) return;

    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Down': // 向下键选择下一个建议
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
            _overlayEntry?.markNeedsBuild();
          });
          break;
        case 'Arrow Up': // 向上键选择上一个建议
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _suggestions.length) %
                _suggestions.length;
            _overlayEntry?.markNeedsBuild();
          });
          break;
        case 'Tab': // Tab键应用建议
        case 'Enter': // Enter键应用建议
          _applySuggestion(_suggestions[_selectedIndex]);
          break;
        case 'Escape': // Esc键关闭建议菜单
          _hideOverlay();
          break;
      }
    }
  }

  /// 格式化SQL语句
  /// 对SQL语句进行美化，添加适当的换行和缩进
  ///
  /// 参数:
  /// - [sql]: 要格式化的SQL语句
  ///
  /// 返回:
  /// 格式化后的SQL语句
  String _formatSql(String sql) {
    // 主要关键字列表
    final mainKeywords = [
      'SELECT',
      'FROM',
      'WHERE',
      'GROUP BY',
      'ORDER BY',
      'HAVING',
      'LIMIT',
      'INSERT INTO',
      'UPDATE',
      'DELETE FROM',
      'CREATE TABLE',
      'ALTER TABLE',
      'DROP TABLE',
      'LEFT JOIN',
      'RIGHT JOIN',
      'INNER JOIN',
      'FULL JOIN',
      'CROSS JOIN',
      'UNION',
      'VALUES',
      'SET'
    ];

    // 子句关键字列表
    final clauseKeywords = [
      'ON',
      'AND',
      'OR',
      'WHEN',
      'THEN',
      'ELSE',
      'END',
      'CASE',
      'NOT',
      'IN',
      'LIKE',
      'BETWEEN',
      'IS NULL',
      'IS NOT NULL',
      'COUNT',
      'SUM',
      'AVG',
      'MAX',
      'MIN',
      'DISTINCT',
      'AS'
    ];

    // 预处理SQL语句
    String formattedSql = sql.trim();

    // 统一空白字符
    formattedSql = formattedSql.replaceAll(RegExp(r'\s+'), ' ');

    // 处理运算符前后的空格
    formattedSql = formattedSql
        .replaceAll('=', ' = ')
        .replaceAll('>', ' > ')
        .replaceAll('<', ' < ')
        .replaceAll('>=', ' >= ')
        .replaceAll('<=', ' <= ')
        .replaceAll('<>', ' <> ')
        .replaceAll('!=', ' != ');

    // 处理括号和逗号
    formattedSql = formattedSql
        .replaceAll('(', ' ( ')
        .replaceAll(')', ' ) ')
        .replaceAll(',', ', ');

    // 分割SQL语句
    List<String> tokens = formattedSql
        .split(' ')
        .where((t) => t.trim().isNotEmpty)
        .map((t) => t.trim())
        .toList();

    StringBuffer result = StringBuffer();
    int indentLevel = 0;
    bool newLine = true;
    String? lastToken;

    // 逐个处理token进行格式化
    for (int i = 0; i < tokens.length; i++) {
      String token = tokens[i];
      String upperToken = token.toUpperCase();

      // 检查是否是主要关键字
      bool isMainKeyword = mainKeywords.contains(upperToken);
      if (i < tokens.length - 1 &&
          mainKeywords
              .contains('${upperToken} ${tokens[i + 1].toUpperCase()}')) {
        isMainKeyword = true;
        token = '$token ${tokens[++i]}'.toUpperCase();
      } else if (mainKeywords.contains(upperToken)) {
        token = upperToken;
      }

      // 处理SELECT后的字段列表
      if (upperToken == 'SELECT') {
        result.write('$token\n');
        indentLevel++;
        newLine = true;
        continue;
      }

      // 处理FROM和其他主要关键字
      if (isMainKeyword && upperToken != 'SELECT') {
        if (upperToken == 'FROM') {
          indentLevel--;
        }
        if (!newLine) result.write('\n');
        result.write('$token');
        newLine = false;
        continue;
      }

      // 处理字段和其他内容
      if (newLine) {
        result.write('${'\t' * indentLevel}$token');
        newLine = false;
      } else {
        if (token == ',') {
          result.write('$token\n');
          newLine = true;
        } else if (lastToken == ',') {
          result.write('${'\t' * indentLevel}$token');
        } else {
          result.write(' $token');
        }
      }

      lastToken = token;
    }

    return result.toString();
  }

  /// 格式化代码
  /// 尝试格式化当前编辑器中的SQL代码
  void _formatCode() {
    try {
      final formattedSql = _formatSql(_codeController.text);
      _codeController.text = formattedSql;
    } catch (e) {
      // 显示格式化失败提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('格式化失败：$e\nFormat failed: $e'),
          backgroundColor: Colors.red[100],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏区域
        if (!widget.readOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF21252B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // 格式化按钮
                Tooltip(
                  message: '格式化SQL / Format SQL',
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C313C),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.format_align_left,
                        color: Color(0xFF98C379),
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                      ),
                      onPressed: _formatCode,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 快捷操作按钮组
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildQuickActionButton(context, 'SELECT', '选择数据'),
                      _buildQuickActionButton(context, 'INSERT', '插入数据'),
                      _buildQuickActionButton(context, 'UPDATE', '更新数据'),
                      _buildQuickActionButton(context, 'DELETE', '删除数据'),
                    ],
                  ),
                ),
                const Spacer(),
                // 执行按钮
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF98C379).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 22),
                    label: const Text(
                      '执行 / Execute',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF98C379),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: widget.onExecute,
                  ),
                ),
              ],
            ),
          ),
        // 代码编辑器区域
        Expanded(
          child: CompositedTransformTarget(
            link: _layerLink,
            child: RawKeyboardListener(
              focusNode: _focusNode,
              onKey: _handleKeyEvent,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF282C34),
                ),
                child: Stack(
                  children: [
                    // 编辑器背景网格
                    Positioned.fill(
                      child: CustomPaint(
                        painter: GridPainter(),
                      ),
                    ),
                    // 代码编辑器
                    CodeField(
                      controller: _codeController,
                      readOnly: widget.readOnly,
                      textStyle: const TextStyle(
                        fontFamily: 'JetBrainsMono',
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 0.5,
                        color: Color(0xFFABB2BF),
                      ),
                      lineNumberStyle: LineNumberStyle(
                        width: 58,
                        margin: 16,
                        textStyle: const TextStyle(
                          color: Color(0xFF495162),
                          fontSize: 12,
                          fontFamily: 'JetBrainsMono',
                        ),
                        background: const Color(0xFF1D2026),
                      ),
                      background: Colors.transparent,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.transparent,
                          width: 0,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      cursorColor: const Color(0xFF61AFEF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建快捷操作按钮
  Widget _buildQuickActionButton(
      BuildContext context, String text, String tooltip) {
    // 不同按钮不同颜色
    Color getButtonColor() {
      switch (text) {
        case 'SELECT':
          return const Color(0xFFC678DD);
        case 'INSERT':
          return const Color(0xFF98C379);
        case 'UPDATE':
          return const Color(0xFF61AFEF);
        case 'DELETE':
          return const Color(0xFFE06C75);
        default:
          return const Color(0xFFABB2BF);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: getButtonColor().withOpacity(0.3),
              width: 1,
            ),
          ),
          child: TextButton(
            onPressed: () => _insertTemplate(text),
            style: TextButton.styleFrom(
              backgroundColor: getButtonColor().withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: getButtonColor(),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 插入SQL模板
  void _insertTemplate(String type) {
    String template = '';
    switch (type) {
      case 'SELECT':
        template = 'SELECT * FROM table_name\nWHERE condition;';
        break;
      case 'INSERT':
        template =
            'INSERT INTO table_name (column1, column2)\nVALUES (value1, value2);';
        break;
      case 'UPDATE':
        template = 'UPDATE table_name\nSET column1 = value1\nWHERE condition;';
        break;
      case 'DELETE':
        template = 'DELETE FROM table_name\nWHERE condition;';
        break;
    }

    if (template.isNotEmpty) {
      final currentPosition = _codeController.selection.start;
      final text = _codeController.text;
      final newText = text.substring(0, currentPosition) +
          template +
          text.substring(currentPosition);
      _codeController.text = newText;
      _codeController.selection =
          TextSelection.collapsed(offset: currentPosition + template.length);
    }
  }
}

// 添加网格背景绘制器
/// 编辑器背景网格绘制器
/// 在编辑器背景上绘制微妙的网格线
/// 增强编辑器的视觉深度
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C313A).withOpacity(0.3)
      ..strokeWidth = 0.5;

    // 绘制水平线
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制垂直线
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
