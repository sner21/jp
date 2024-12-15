import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import '../utils/import_utils.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VocabularyController {
  late final PageController pageController;
  
  static VocabularyController? _instance;
  
  static VocabularyController getInstance({
    required StorageManager storageManager,
    required TTSService ttsService,
    required Function setState,
    required BuildContext context,
  }) {
    _instance ??= VocabularyController(
      storageManager: storageManager,
      ttsService: ttsService,
      setState: setState,
      context: context,
    );
    return _instance!;
  }

  final StorageManager storageManager;
  final TTSService ttsService;
  final Function setState;
  final BuildContext context;

  List<Word> words = [];
  List<Word> filteredWords = [];
  String? selectedCategory;
  int currentWordIndex = 0;
  bool showMeaning = true;
  bool showJapanese = true;
  bool showPronunciation = true;
  bool isListView = false;
  int selectedIndex = 1;
  bool isSelectMode = false;
  final Set<String> selectedWords = {};
  VocabularyController({
    required this.storageManager,
    required this.ttsService,
    required this.setState,
    required this.context,
  }) {
    pageController = PageController(initialPage: currentWordIndex);
  }
  
  void dispose() {
    pageController.dispose();
  }

  Future<void> loadWords() async {
    final loadedWords = await storageManager.getAllWords();
    setState(() {
      words = loadedWords;
      filteredWords = selectedCategory == null
          ? loadedWords
          : loadedWords.where((word) => word.category == selectedCategory).toList();
      if (currentWordIndex >= filteredWords.length) {
        currentWordIndex = filteredWords.isEmpty ? 0 : filteredWords.length - 1;
      }
    });
  }

  Future<void> filterWords(String query) async {
    if (query.isEmpty) {
      loadWords();
    } else {
      final results = await storageManager.searchWords(query);
      setState(() {
        filteredWords = results;
        currentWordIndex = 0;
      });
    }
  }

  Future<void> filterByCategory(String? category) async {
    setState(() {
      selectedCategory = category;
    });
    
    if (category == null) {
      await loadWords();
    } else {
      setState(() {
        filteredWords = words.where((word) => word.category == category).toList();
        currentWordIndex = 0; 
      });
    }
  }

  Future<void> importFromText(String text) async {
    try {
      if (text.isEmpty) {
        throw Exception('内容不能为空');
      }

      debugPrint('开始解析CSV文本: $text');
      
      List<String> lines = text.split('\n');
      debugPrint('分割后的行: $lines');
      
      List<List<String>> rows = lines.map((line) => 
        line.split(',').map((cell) => cell.trim()).toList()
      ).toList();
      
      debugPrint('解析后的行: $rows');
      
      List<Word> words = [];
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

      final box = await Hive.openBox<Word>('words');
      await box.addAll(words);
      
      if (storageManager.isLoggedIn) {
        await storageManager.uploadImportedWords(words);
      }
      
      await loadWords();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 ${words.length} 个单词')),
        );
      }
    } catch (e) {
      debugPrint('导入错误: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> deleteSelected() async {
    try {
      final box = await Hive.openBox<Word>('words');
      
      final List<Future<void>> deleteFutures = selectedWords.map((wordId) async {
        await box.delete(wordId);
        if (storageManager.isLoggedIn) {
          await storageManager.deleteWord(wordId);
        }
      }).toList();
      await Future.wait(deleteFutures);
      selectedWords.clear();
      isSelectMode = false;
      await loadWords();
    } catch (e) {
      print('批量删除失败: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登出失败，请稍后试')),
        );
      }
    }
  }
} 