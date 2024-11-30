import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        // onChange事件监听
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
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '登出',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _filteredWords.isEmpty
                ? _buildEmptyState()
                : _buildWordsList(),
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
} 