import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import '../utils/import_utils.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class VocabularyController {
  static VocabularyController? _instance;
  
  static VocabularyController getInstance({
    required StorageManager storageManager,
    required TTSService ttsService,
    required Function(VoidCallback) setState,
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
  final Function(VoidCallback) setState;
  final BuildContext context;

  List<Word> words = [];
  List<Word> filteredWords = [];
  String? selectedCategory;
  int currentWordIndex = 0;
  bool showMeaning = true;
  bool showJapanese = true;
  bool showPronunciation = true;
  bool isListView = false;
  bool isSelectMode = false;
  final Set<String> selectedWords = {};

  VocabularyController({
    required this.storageManager,
    required this.ttsService,
    required this.setState,
    required this.context,
  });

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
      // 如果选择"全部"，加载所有单词
      await loadWords();
    } else {
      // 如果选择具体分类，筛选该分类的单词
      setState(() {
        filteredWords = words.where((word) => word.category == category).toList();
        currentWordIndex = 0;  // 重置当前单词索引
      });
    }
  }

  Future<void> importFromText(String text) async {
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
      for (final wordId in selectedWords) {
        await box.delete(wordId);
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      }
      
      setState(() {
        isSelectMode = false;
        selectedWords.clear();
      });
      
      await loadWords();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
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