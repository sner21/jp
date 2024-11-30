import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/word_list_view.dart';
import '../widgets/word_card_view.dart';
import '../widgets/import_dialogs.dart';
import '../controllers/vocabulary_controller.dart';

class VocabularyScreen extends StatefulWidget {
  final VocabularyController controller;

  const VocabularyScreen({
    super.key,
    required this.controller,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late final _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.loadWords();
    
    // 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _controller.storageManager.syncToCloud();
      }
      _controller.loadWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生词本'),
        actions: [
          IconButton(
            icon: Icon(_controller.isSelectMode ? Icons.close : Icons.select_all),
            tooltip: _controller.isSelectMode ? '退出选择' : '批量选择',
            onPressed: () {
              setState(() {
                _controller.isSelectMode = !_controller.isSelectMode;
                _controller.selectedWords.clear();
              });
            },
          ),
          if (_controller.isSelectMode && _controller.selectedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除选中项',
              onPressed: _controller.deleteSelected,
            ),
          IconButton(
            icon: Icon(_controller.isListView ? Icons.view_agenda : Icons.view_list),
            tooltip: _controller.isListView ? '卡片视图' : '列表视图',
            onPressed: () {
              setState(() {
                _controller.isListView = !_controller.isListView;
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload),
            onSelected: (value) {
              if (value == 'text') {
                ImportDialogs.showTextImportDialog(context, _controller.importFromText);
              } else if (value == 'file') {
                ImportDialogs.importFromFile(_controller.importFromText);
              }
            },
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
            onPressed: _controller.logout,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _controller.filteredWords.isEmpty
                ? const Center(child: Text('没有单词'))
                : _controller.isListView 
                    ? WordListView(
                        words: _controller.filteredWords,
                        ttsService: _controller.ttsService,
                        isSelectMode: _controller.isSelectMode,
                        selectedWords: _controller.selectedWords,
                        showPronunciation: _controller.showPronunciation,
                        showWordOptions: _showWordOptions,
                        toggleWordSelection: (String wordId) {
                          setState(() {
                            if (_controller.selectedWords.contains(wordId)) {
                              _controller.selectedWords.remove(wordId);
                            } else {
                              _controller.selectedWords.add(wordId);
                            }
                          });
                        },
                        onWordTap: (int index) {
                          setState(() {
                            _controller.currentWordIndex = index;
                            _controller.isListView = false;
                          });
                        },
                      )
                    : WordCardView(
                        word: _controller.filteredWords[_controller.currentWordIndex],
                        ttsService: _controller.ttsService,
                        showJapanese: _controller.showJapanese,
                        showPronunciation: _controller.showPronunciation,
                        showMeaning: _controller.showMeaning,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索单词...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _controller.filterWords(''),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onChanged: _controller.filterWords,
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<String>>(
      future: _controller.storageManager.getAllCategories(),
      builder: (context, snapshot) {
        final List<String> categories = ['全部', ...(snapshot.data ?? [])];
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade50,
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: _controller.selectedCategory,
                hint: const Text('选择分类'),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: categories.map((category) => DropdownMenuItem<String>(
                  value: category == '全部' ? null : category,
                  child: Text(category),
                )).toList(),
                onChanged: _controller.filterByCategory,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWordOptions(Word word) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              // TODO: 实现编辑功能
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('删除'),
            onTap: () async {
              Navigator.pop(context);
              // TODO: 实现删除功能
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.ttsService.stop();
    super.dispose();
  }
} 