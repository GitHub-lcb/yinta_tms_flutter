import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/sql.dart';

class SqlEditor extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onExecute;
  final bool readOnly;
  final List<String> tables;
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
  late CodeController _codeController;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();
  String _currentWord = '';
  List<String> _suggestions = [];
  int _selectedIndex = 0;

  // SQL keywords for syntax highlighting and autocomplete
  static final Map<String, TextStyle> _keywords = {
    // DML
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

    // DDL
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

    // Joins
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

    // Operators
    'AND': const TextStyle(color: Colors.red),
    'OR': const TextStyle(color: Colors.red),
    'NOT': const TextStyle(color: Colors.red),
    'IN': const TextStyle(color: Colors.red),
    'LIKE': const TextStyle(color: Colors.red),
    'BETWEEN': const TextStyle(color: Colors.red),
    'IS NULL': const TextStyle(color: Colors.red),
    'IS NOT NULL': const TextStyle(color: Colors.red),

    // Functions
    'COUNT': const TextStyle(color: Colors.teal),
    'SUM': const TextStyle(color: Colors.teal),
    'AVG': const TextStyle(color: Colors.teal),
    'MAX': const TextStyle(color: Colors.teal),
    'MIN': const TextStyle(color: Colors.teal),
    'DISTINCT': const TextStyle(color: Colors.teal),
  };

  // Additional SQL keywords for autocomplete only
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

    _codeController.addListener(() {
      widget.onChanged?.call(_codeController.text);
      _updateSuggestions();
    });

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSuggestions() {
    final text = _codeController.text;
    final selection = _codeController.selection;
    if (!selection.isValid || selection.start != selection.end) {
      _hideOverlay();
      return;
    }

    // Get the current word being typed
    final beforeCursor = text.substring(0, selection.start);
    final words = beforeCursor.split(RegExp(r'[\s\n]'));
    _currentWord = words.isEmpty ? '' : words.last.toUpperCase();

    if (_currentWord.isEmpty) {
      _hideOverlay();
      return;
    }

    // Collect all possible suggestions
    final allSuggestions = [
      ..._keywords.keys,
      ..._additionalKeywords,
      ...widget.tables.map((t) => t.toUpperCase()),
      ...widget.columns.map((c) => c.toUpperCase()),
    ];

    // Filter suggestions based on current word
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

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

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

  void _handleKeyEvent(RawKeyEvent event) {
    if (_overlayEntry == null) return;

    if (event is RawKeyDownEvent) {
      switch (event.logicalKey.keyLabel) {
        case 'Arrow Down':
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
            // Force overlay to rebuild
            _overlayEntry?.markNeedsBuild();
          });
          break;
        case 'Arrow Up':
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _suggestions.length) %
                _suggestions.length;
            // Force overlay to rebuild
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

  String _formatSql(String sql) {
    final keywords = _keywords.keys.toList();
    String formattedSql = sql.toUpperCase();

    // Replace multiple spaces with a single space
    formattedSql = formattedSql.replaceAll(RegExp(r'\s+'), ' ');

    // Add newlines before keywords
    for (final keyword in keywords) {
      formattedSql =
          formattedSql.replaceAll(RegExp(r'\s*\b$keyword\b'), '\n$keyword');
    }

    // Special handling for nested queries and parentheses
    final lines = formattedSql.split('\n');
    final result = <String>[];
    var indentLevel = 0;
    var inParentheses = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Count opening and closing parentheses
      inParentheses += '('.allMatches(line).length;
      inParentheses -= ')'.allMatches(line).length;

      // Adjust indent level based on parentheses
      if (line.startsWith(')')) {
        indentLevel = (indentLevel - 1).clamp(0, 10);
      }

      // Add the line with proper indentation
      if (line.isNotEmpty) {
        result.add('  ' * indentLevel + line);
      }

      // Increase indent level for nested queries and opening parentheses
      if (line.endsWith('(') || inParentheses > 0) {
        indentLevel = (indentLevel + 1).clamp(0, 10);
      }
    }

    return result.join('\n');
  }

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
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.format_align_left),
                  tooltip: '格式化 / Format',
                  onPressed: _formatCode,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('执行 / Execute'),
                  onPressed: widget.onExecute,
                ),
              ],
            ),
          ),
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
