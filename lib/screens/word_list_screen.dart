import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final StorageManager _storageManager =
      StorageManager(Supabase.instance.client);
  final TTSService _ttsService = TTSService();
  List<Word> _words = [];
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final words = await _storageManager.getAllWords();
      setState(() {
        _words = words;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载单词失败')),
        );
      }
    }
  }

  void _filterWords(String query) async {
    if (query.isEmpty) {
      _loadWords();
    } else {
      final filteredWords = await _storageManager.searchWords(query);
      setState(() {
        _words = filteredWords;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单词列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final categories = await _storageManager.getAllCategories();
              if (!mounted) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择分类'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('全部'),
                          selected: _selectedCategory == null,
                          onTap: () {
                            setState(() {
                              _selectedCategory = null;
                            });
                            _loadWords();
                            Navigator.pop(context);
                          },
                        ),
                        ...categories.map((category) => ListTile(
                              title: Text(category),
                              selected: _selectedCategory == category,
                              onTap: () async {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                final words = await _storageManager
                                    .getWordsByCategory(category);
                                setState(() {
                                  _words = words;
                                });
                                Navigator.pop(context);
                              },
                            )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索单词...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterWords('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: _filterWords,
            ),
          ),
          if (_selectedCategory != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                label: Text(_selectedCategory!),
                onDeleted: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                  _loadWords();
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _words.length,
              itemBuilder: (context, index) {
                final word = _words[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(word.japanese),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.pronunciation),
                        Text(word.meaning),
                        if (word.category != null) Text('分类: ${word.category}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _ttsService.speak(word.japanese),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
