import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class VocabularyToolbar extends StatelessWidget {
  final bool isSelectMode;
  final int selectedCount;
  final VoidCallback onToggleSelectMode;
  final VoidCallback onDelete;
  final Function(String) onImport;
  final VoidCallback onLogout;
  final VoidCallback onToggleView;
  final bool isListView;

  const VocabularyToolbar({
    super.key,
    required this.isSelectMode,
    required this.selectedCount,
    required this.onToggleSelectMode,
    required this.onDelete,
    required this.onImport,
    required this.onLogout,
    required this.onToggleView,
    required this.isListView,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(isSelectMode ? Icons.close : Icons.select_all),
          tooltip: isSelectMode ? '退出选择' : '批量选择',
          onPressed: onToggleSelectMode,
        ),
        if (isSelectMode && selectedCount > 0)
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '删除选中项',
            onPressed: onDelete,
          ),
        IconButton(
          icon: Icon(isListView ? Icons.view_agenda : Icons.view_list),
          tooltip: isListView ? '卡片视图' : '列表视图',
          onPressed: onToggleView,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.file_upload),
          onSelected: onImport,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'text',
              child: Text('文本导入'),
            ),
            if (!kIsWeb)
              const PopupMenuItem(
                value: 'file',
                child: Text('文件导入'),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: '退出登录',
          onPressed: onLogout,
        ),
      ],
    );
  }
} 