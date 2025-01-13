import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/sql.dart';

/// SQL编辑器组件
/// 提供SQL语句的编辑、语法高亮、自动完成等功能
class SqlEditor extends StatefulWidget {
  /// 初始SQL语句
  final String? initialValue;

  /// SQL语句变化回调函数
  final ValueChanged<String>? onChanged;

  /// 执行SQL语句回调函数
  final VoidCallback? onExecute;

  /// 是否只读模式
  final bool readOnly;

  /// 可用的表名列表（用于自动完成）
  final List<String> tables;

  /// 可用的列名列表（用于自动完成）
  final List<String> columns;

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

class _SqlEditorState extends State<SqlEditor> {
  /// 代码编辑器控制器
  late CodeController _codeController;

  /// 自动完成菜单的位置链接
  final LayerLink _layerLink = LayerLink();

  /// 自动完成菜单的覆盖层条目
  OverlayEntry? _overlayEntry;

  /// 编辑器焦点节点
  final FocusNode _focusNode = FocusNode();

  /// 当前正在输入的单词
  String _currentWord = '';

  /// 自动完成建议列表
  List<String> _suggestions = [];

  /// 当前选中的建议项索引
  int _selectedIndex = 0;

  /// SQL关键字样式映射
  /// 用于语法高亮显示不同类型的SQL关键字
  static final Map<String, TextStyle> _keywords = {
    // DML关键字
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

    // DDL关键字
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
    'AND': const TextStyle(color: Colors.red),
    'OR': const TextStyle(color: Colors.red),
    'NOT': const TextStyle(color: Colors.red),
    'IN': const TextStyle(color: Colors.red),
    'LIKE': const TextStyle(color: Colors.red),
    'BETWEEN': const TextStyle(color: Colors.red),
    'IS NULL': const TextStyle(color: Colors.red),
    'IS NOT NULL': const TextStyle(color: Colors.red),

    // 函数关键字
    'COUNT': const TextStyle(color: Colors.teal),
    'SUM': const TextStyle(color: Colors.teal),
    'AVG': const TextStyle(color: Colors.teal),
    'MAX': const TextStyle(color: Colors.teal),
    'MIN': const TextStyle(color: Colors.teal),
    'DISTINCT': const TextStyle(color: Colors.teal),
  };

  /// 额外的SQL关键字列表（仅用于自动完成）
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

  @override
  void initState() {
    super.initState();
    // 初始化代码编辑器控制器
    _codeController = CodeController(
      text: widget.initialValue ?? '',
      language: sql,
      patternMap: {
        r'".*?"': const TextStyle(color: Colors.green),
        r"'.*?'": const TextStyle(color: Colors.green),
        r'\d+': const TextStyle(color: Colors.blue),
        r'--.*': const TextStyle(color: Colors.grey),
        r'/\*.*?\*/': const TextStyle(color: Colors.grey),
        r'`.*?`': const TextStyle(color: Colors.orange),
      },
      stringMap: _keywords,
    );

    // 添加文本变化监听器
    _codeController.addListener(() {
      widget.onChanged?.call(_codeController.text);
      _updateSuggestions();
    });

    // 添加焦点监听器
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    // 释放资源
    _hideOverlay();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 更新自动完成建议列表
  /// 根据当前输入的单词筛选可能的建议
  void _updateSuggestions() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    if (!selection.isValid || selection.start != selection.end) {
      _hideOverlay();
      return;
    }

    // 获取当前正在输入的单词
    final beforeCursor = text.substring(0, selection.start);
    final words = beforeCursor.split(RegExp(r'[\s\n]'));
    _currentWord = words.isEmpty ? '' : words.last.toUpperCase();

    if (_currentWord.isEmpty) {
      _hideOverlay();
      return;
    }

    // 收集所有可能的建议
    final allSuggestions = [
      ..._keywords.keys,
      ..._additionalKeywords,
      ...widget.tables.map((t) => t.toUpperCase()),
      ...widget.columns.map((c) => c.toUpperCase()),
    ];

    // 根据当前单词过滤建议
    _suggestions = allSuggestions
        .where((s) => s.startsWith(_currentWord) && s != _currentWord)
        .toList();

    if (_suggestions.isEmpty) {
      _hideOverlay();
      return;
    }

    _selectedIndex = 0;
    _showOverlay();
  }

  /// 显示自动完成菜单
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
            width: 200,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 24),
              child: Material(
                elevation: 4,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Theme.of(context).canvasColor,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return MouseRegion(
                        onEnter: (_) {
                          _selectedIndex = index;
                          setState(() {});
                          _overlayEntry?.markNeedsBuild();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: index == _selectedIndex
                                ? Colors.blue[600]
                                : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            dense: true,
                            selected: index == _selectedIndex,
                            hoverColor: Colors.blue[100],
                            title: Text(
                              suggestion,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: index == _selectedIndex
                                    ? Colors.white
                                    : (_keywords.containsKey(suggestion)
                                        ? _keywords[suggestion]?.color
                                        : null),
                                fontWeight: index == _selectedIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () => _applySuggestion(suggestion),
                          ),
                        ),
                      );
                    },
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
  ///
  /// 参数:
  /// - [suggestion]: 要应用的建议文本
  void _applySuggestion(String suggestion) {
    final text = _codeController.text;
    final selection = _codeController.selection;
    final beforeCursor = text.substring(0, selection.start);
    final afterCursor = text.substring(selection.start);
    final lastWord = beforeCursor.split(RegExp(r'[\s\n]')).last;

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
        case 'Arrow Down':
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
            // 强制覆盖层重建
            _overlayEntry?.markNeedsBuild();
          });
          break;
        case 'Arrow Up':
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _suggestions.length) %
                _suggestions.length;
            // 强制覆盖层重建
            _overlayEntry?.markNeedsBuild();
          });
          break;
        case 'Tab':
        case 'Enter':
          _applySuggestion(_suggestions[_selectedIndex]);
          break;
        case 'Escape':
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
    final keywords = _keywords.keys.toList();
    String formattedSql = sql.toUpperCase();

    // 替换多个空格为单个空格
    formattedSql = formattedSql.replaceAll(RegExp(r'\s+'), ' ');

    // 在关键字前添加换行
    for (final keyword in keywords) {
      formattedSql =
          formattedSql.replaceAll(RegExp(r'\s*\b$keyword\b'), '\n$keyword');
    }

    // 处理嵌套查询和括号的特殊情况
    final lines = formattedSql.split('\n');
    final result = <String>[];
    var indentLevel = 0;
    var inParentheses = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // 计算开闭括号数量
      inParentheses += '('.allMatches(line).length;
      inParentheses -= ')'.allMatches(line).length;

      // 根据括号调整缩进级别
      if (line.startsWith(')')) {
        indentLevel = (indentLevel - 1).clamp(0, 10);
      }

      // 添加适当缩进的行
      if (line.isNotEmpty) {
        result.add('  ' * indentLevel + line);
      }

      // 增加嵌套查询和开括号的缩进级别
      if (line.endsWith('(') || inParentheses > 0) {
        indentLevel = (indentLevel + 1).clamp(0, 10);
      }
    }

    return result.join('\n');
  }

  /// 格式化代码
  /// 尝试格式化当前编辑器中的SQL代码
  void _formatCode() {
    try {
      final formattedSql = _formatSql(_codeController.text);
      _codeController.text = formattedSql;
    } catch (e) {
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 格式化按钮
                IconButton(
                  icon: const Icon(Icons.format_align_left),
                  tooltip: '格式化 / Format',
                  onPressed: _formatCode,
                ),
                const Spacer(),
                // 执行按钮
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('执行 / Execute'),
                  onPressed: widget.onExecute,
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
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 800,
                      child: CodeField(
                        controller: _codeController,
                        readOnly: widget.readOnly,
                        textStyle: const TextStyle(fontFamily: 'monospace'),
                        lineNumberStyle: LineNumberStyle(
                          width: 48,
                          margin: 16,
                          textStyle: TextStyle(color: Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
