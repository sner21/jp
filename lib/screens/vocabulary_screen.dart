import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
    // 创建状态，类似于React的state初始化
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final StorageManager _storageManager = StorageManager(Supabase.instance.client);
  final TTSService _ttsService = TTSService();
  bool _isTTSAvailable = false;
  
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  String? _selectedCategory;
  
  int _currentWordIndex = 0;
  bool _showMeaning = true;
  bool _showJapanese = true;
  bool _showPronunciation = true;
  bool _isListView = false;  // 添加视图模式标记

  // 添加选择模式和选中项的状态
  bool _isSelectMode = false;
  final Set<String> _selectedWords = {};

  @override
    // 类似于React的componentDidMount
  void initState() {
    super.initState();
    _loadWords();
    _checkTTS();
    // 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _storageManager.syncToCloud();  // 登录时同步数据
      }
      _loadWords();  // 重新加载数据
    });
  }
  // 类似于React中的异步数据加载函数
  Future<void> _loadWords() async {
    if (!mounted) return;  // 添加mounted检查
    
    final words = await _storageManager.getAllWords();
    if (!mounted) return;  // 再次检查mounted
    
    setState(() {
      _words = words;
      _filteredWords = _selectedCategory == null
          ? words
          : words.where((word) => word.category == _selectedCategory).toList();
      if (_currentWordIndex >= _filteredWords.length) {
        _currentWordIndex = _filteredWords.isEmpty ? 0 : _filteredWords.length - 1;
      }
    });
  }
  // 类似于React中的搜索过滤函数
  void _filterWords(String query) async {
    if (query.isEmpty) {
      _loadWords();
    } else {
      final results = await _storageManager.searchWords(query);
      setState(() {
        _filteredWords = results;
        _currentWordIndex = 0;
      });
    }
  }
  // 类似于React的子组件或UI片段
  Widget _buildHeader() {
      // Container类似于div
    return Container(
      padding: const EdgeInsets.all(16.0),
          // decoration类似于CSS样式
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
        // Column类似于flex-direction: column
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildCategoryDropdown(),
        ],
      ),
    );
  }
 // 搜索框组件，类似于React的搜索输入框组件
  Widget _buildSearchBar() {
        // TextField类似于HTML的input
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索单词...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _loadWords();  // 清空搜索时重新加载所有单词
          },
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
        // onChange事监听
      onChanged: _filterWords,
    );
  }
  // 下拉菜单组件，类似于React的Select组件
  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<String>>(
      future: _storageManager.getAllCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final categories = ['全部', ...snapshot.data!];
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
                value: _selectedCategory,
                hint: const Text('选择分类'),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category == '全部' ? null : category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedCategory = value;
                  });
                  if (value == null || value == '全部') {
                    await _loadWords();
                  } else {
                    final words = await _storageManager.getWordsByCategory(value);
                    setState(() {
                      _filteredWords = words;
                      _currentWordIndex = 0;
                    });
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
  // 弹窗组件，类似于React的Modal组件
  void _showAddWordDialog([Word? wordToEdit]) {
    final TextEditingController japaneseController = TextEditingController(text: wordToEdit?.japanese);
    final TextEditingController pronunciationController = TextEditingController(text: wordToEdit?.pronunciation);
    final TextEditingController meaningController = TextEditingController(text: wordToEdit?.meaning);
    final TextEditingController categoryController = TextEditingController(text: wordToEdit?.category);
// showDialog类似于React的Modal.show()
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
                // ... 弹窗内容
          title: Text(wordToEdit == null ? '添加新单词' : '编辑单词'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: japaneseController,
                  decoration: const InputDecoration(labelText: '日语（汉字）'),
                ),
                TextField(
                  controller: pronunciationController,
                  decoration: const InputDecoration(labelText: '假名'),
                ),
                TextField(
                  controller: meaningController,
                  decoration: const InputDecoration(labelText: '中文含义'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: '分类（可选）'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                if (japaneseController.text.isNotEmpty &&
                    pronunciationController.text.isNotEmpty &&
                    meaningController.text.isNotEmpty) {
                  final word = Word(
                    id: wordToEdit?.id ?? DateTime.now().toString(),
                    japanese: japaneseController.text,
                    pronunciation: pronunciationController.text,
                    meaning: meaningController.text,
                    category: categoryController.text.isEmpty ? null : categoryController.text,
                  );

                  if (wordToEdit == null) {
                    await _storageManager.addWord(word);
                  } else {
                    await _storageManager.updateWord(word);
                  }

                  _loadWords();
                  Navigator.pop(context);
                }
              },
              child: Text(wordToEdit == null ? '添加' : '保存'),
            ),
          ],
        );
      },
    );
  }

  void _showWordOptions(Word word) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑'),
              onTap: () {
                Navigator.pop(context);
                _showAddWordDialog(word);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _storageManager.deleteWord(word.id);
                _loadWords();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
  // build方法类似于React的render
  @override
  Widget build(BuildContext context) {
    // Scaffold类似于页面的基础布局容器
    return Scaffold(
      appBar: AppBar(
        title: const Text('生词本'),
        actions: [
          IconButton(
            icon: Icon(_isListView ? Icons.view_carousel : Icons.list),
            tooltip: _isListView ? '卡片视图' : '列表视图',
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '登出',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload),
            onSelected: (value) {
              switch (value) {
                case 'text':
                  _showTextImportDialog();
                  break;
                case 'file':
                  _importFromFile();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'text',
                child: Row(
                  children: [
                    Icon(Icons.paste),
                    SizedBox(width: 8),
                    Text('文本导入'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'file',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('文件导入'),
                  ],
                ),
              ),
            ],
          ),
          // 添加选择模式切换按钮
          IconButton(
            icon: Icon(_isSelectMode ? Icons.close : Icons.select_all),
            tooltip: _isSelectMode ? '退出选择' : '批量选择',
            onPressed: () {
              setState(() {
                _isSelectMode = !_isSelectMode;
                _selectedWords.clear();
              });
            },
          ),
          // 添加删除按钮
          if (_isSelectMode && _selectedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除选中项',
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _filteredWords.isEmpty
                ? _buildEmptyState()
                : _isListView 
                    ? _buildListView()  // 新增列表视图
                    : _buildWordsList(),  // 原有的卡片视图
          ),
        ],
      ),
       // FloatingActionButton类似于固定位置的悬浮按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        '还没有添加生词\n点击右下角按钮添加新单词',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildWordsList() {
    if (_filteredWords.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      children: [
        Expanded(
          child: _buildWordCard(_filteredWords[_currentWordIndex]),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildControlButtons(),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _currentWordIndex > 0 ? _previousWord : null,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChoiceChip(
              label: const Text('汉字'),
              selected: _showJapanese,
              onSelected: (bool selected) {
                setState(() {
                  _showJapanese = selected;
                });
              },
            ),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text('假名'),
              selected: _showPronunciation,
              onSelected: (bool selected) {
                setState(() {
                  _showPronunciation = selected;
                });
              },
            ),
            const SizedBox(width: 10),
            ChoiceChip(
              label: const Text('含义'),
              selected: _showMeaning,
              onSelected: (bool selected) {
                setState(() {
                  _showMeaning = selected;
                });
              },
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: _currentWordIndex < _filteredWords.length - 1 ? _nextWord : null,
        ),
      ],
    );
  }

  void _showWordDetail(Word word) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(word.japanese, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(word.pronunciation, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(word.meaning, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _toggleNewWord(word);
                  Navigator.pop(context);
                },
                child: Text(word.isNewWord ? '从生词本移除' : '添加到生词本'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _nextWord() {
    setState(() {
      if (_currentWordIndex < _filteredWords.length - 1) {
        _currentWordIndex++;
      }
    });
  }

  void _previousWord() {
    setState(() {
      if (_currentWordIndex > 0) {
        _currentWordIndex--;
      }
    });
  }

  Widget _buildWordCard(Word word) {
    return Card(
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 300,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTTSButton(word.pronunciation),
                  IconButton(
                    icon: Icon(
                      word.isNewWord ? Icons.bookmark : Icons.bookmark_border,
                      color: word.isNewWord ? Colors.red : null,
                    ),
                    onPressed: () => _toggleNewWord(word),
                  ),
                ],
              ),
              if (_showJapanese)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.japanese,
                      style: const TextStyle(fontSize: 32),
                    ),
                    _buildTTSButton(word.japanese),
                  ],
                ),
              if (_showJapanese && _showPronunciation)
                const SizedBox(height: 10),
              if (_showPronunciation)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      word.pronunciation,
                      style: const TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                    _buildTTSButton(word.pronunciation),
                  ],
                ),
              if (_showMeaning)
                const SizedBox(height: 20),
              if (_showMeaning)
                Text(
                  word.meaning,
                  style: const TextStyle(fontSize: 24),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleNewWord(Word word) {
    setState(() {
      word.isNewWord = !word.isNewWord;
    });
  }

  Future<void> _checkTTS() async {
    final available = await _ttsService.isAvailable;
    if (mounted) {
      setState(() {
        _isTTSAvailable = available;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登出失败，请稍后试')),
        );
      }
    }
  }

  @override
  void dispose() {
    // 确保在dispose时取消所有可能的异步操作
    _ttsService.stop();
    super.dispose();
  }

  Widget _buildTTSButton(String text) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () async {
        try {
          await _ttsService.speak(text);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('发音播放失败，请检查网络连接')),
            );
          }
        }
      },
      tooltip: '播放发音',
    );
  }

  // 可以在设置页面添加清理缓存的选项
  Future<void> _clearTTSCache() async {
    await _ttsService.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音缓存已清理')),
      );
    }
  }

  // 添加列表视图
  Widget _buildListView() {
    return ListView.builder(
      itemCount: _filteredWords.length,
      itemBuilder: (context, index) {
        final word = _filteredWords[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _isSelectMode ? Checkbox(
              value: _selectedWords.contains(word.id),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedWords.add(word.id);
                  } else {
                    _selectedWords.remove(word.id);
                  }
                });
              },
            ) : null,
            title: Text(word.japanese),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showPronunciation)
                  Text(word.pronunciation),
                Text(word.meaning),
                if (word.category != null)
                  Text('分类: ${word.category}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => _ttsService.speak(word.japanese),
                ),
                if (!_isSelectMode)  // 在非选择模式下显示更多选项按钮
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showWordOptions(word),
                  ),
              ],
            ),
            onTap: _isSelectMode 
              ? () {
                  setState(() {
                    if (_selectedWords.contains(word.id)) {
                      _selectedWords.remove(word.id);
                    } else {
                      _selectedWords.add(word.id);
                    }
                  });
                }
              : () {
                  setState(() {
                    _currentWordIndex = index;
                    _isListView = false;
                  });
                },
          ),
        );
      },
    );
  }

  void _showTextImportDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文本导入'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '请粘贴CSV格式的文本：\n'
              '日语,假名,含义,分类\n'
              '食べる,たべる,吃,动词\n'
              '水,みず,水,名词',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              maxLines: 8,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '在此粘贴内容...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importFromText(textController.text);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes == null) {
          throw Exception('无法读取文件');
        }

        final csvString = utf8.decode(fileBytes);
        _importFromText(csvString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件导入失败: $e')),
        );
      }
    }
  }

  Future<void> _importFromText(String text) async {
    try {
      if (text.isEmpty) {
        throw Exception('内容不能为空');
      }

      debugPrint('开始解析CSV文本: $text');
      
      // 分割文本为行
      List<String> lines = text.split('\n');
      debugPrint('分割后的行: $lines');
      
      // 手动解析CSV
      List<List<String>> rows = lines.map((line) => 
        line.split(',').map((cell) => cell.trim()).toList()
      ).toList();
      
      debugPrint('解析后的行: $rows');
      
      // 转换为Word对象
      List<Word> words = [];
      // 跳过标题行
      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];
        debugPrint('处理行: $row');
        if (row.length >= 3) {
          words.add(Word(
            id: const Uuid().v4(),
            japanese: row[0],
            pronunciation: row[1],
            meaning: row[2],
            category: row.length > 3 ? row[3] : null,
          ));
        }
      }

      if (words.isEmpty) {
        debugPrint('没有解析出有效数据');
        throw Exception('没有有效的数据');
      }

      // 保存到本地
      final box = await Hive.openBox<Word>('words');
      await box.addAll(words);
      
      // 使用专门的导入方法上传到云端
      if (_storageManager.isLoggedIn) {
        await _storageManager.uploadImportedWords(words);
      }
      
      // 重新加载单词列表
      await _loadWords();
      
      // 关闭加载指示器
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 ${words.length} 个单词')),
        );
      }
    } catch (e) {
      debugPrint('导入错误: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  // 添加批量删除方法
  Future<void> _deleteSelected() async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedWords.length} 个单词吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final box = await Hive.openBox<Word>('words');
        // 删除选中的单词
        for (final wordId in _selectedWords) {
          await box.delete(wordId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
        
        // 退出选择模式
        setState(() {
          _isSelectMode = false;
          _selectedWords.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
} 