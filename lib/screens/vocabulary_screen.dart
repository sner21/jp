import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_service.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  final WordService _wordService = WordService();
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  String? _selectedCategory;
  
  int _currentWordIndex = 0;
  bool _showMeaning = true;
  bool _showJapanese = true;
  bool _showPronunciation = true;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await _wordService.getAllWords();
    setState(() {
      _words = words;
      _filteredWords = words;
      _currentWordIndex = 0;
    });
  }

  void _filterWords(String query) async {
    if (query.isEmpty) {
      _loadWords();
    } else {
      final results = await _wordService.searchWords(query);
      setState(() {
        _filteredWords = results;
        _currentWordIndex = 0;
      });
    }
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
      onChanged: _filterWords,
    );
  }

  Widget _buildCategoryDropdown() {
    return FutureBuilder<List<String>>(
      future: _wordService.getAllCategories(),
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
                icon: const Icon(Icons.arrow_drop_down),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category == '全部' ? null : category,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: _selectedCategory == category 
                            ? Colors.blue 
                            : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedCategory = value;
                  });
                  if (value == null || value == '全部') {
                    _loadWords();
                  } else {
                    final words = await _wordService.getWordsByCategory(value);
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

  void _showAddWordDialog([Word? wordToEdit]) {
    final TextEditingController japaneseController = TextEditingController(text: wordToEdit?.japanese);
    final TextEditingController pronunciationController = TextEditingController(text: wordToEdit?.pronunciation);
    final TextEditingController meaningController = TextEditingController(text: wordToEdit?.meaning);
    final TextEditingController categoryController = TextEditingController(text: wordToEdit?.category);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                    await _wordService.addWord(word);
                  } else {
                    await _wordService.updateWord(word);
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
                await _wordService.deleteWord(word.id);
                _loadWords();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生词本'),
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                Text(
                  word.japanese,
                  style: const TextStyle(fontSize: 32),
                ),
              if (_showJapanese && _showPronunciation)
                const SizedBox(height: 10),
              if (_showPronunciation)
                Text(
                  word.pronunciation,
                  style: const TextStyle(fontSize: 24, color: Colors.grey),
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
} 