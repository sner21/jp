import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';

class WordService {
  static const String boxName = 'words';
  
  Future<Box<Word>> get _box async => await Hive.openBox<Word>(boxName);

  // 添加单词
  Future<void> addWord(Word word) async {
    final box = await _box;
    await box.put(word.id, word);
  }

  // 获取所有单词
  Future<List<Word>> getAllWords() async {
    final box = await _box;
    return box.values.toList();
  }

  // 获取指定分类的单词
  Future<List<Word>> getWordsByCategory(String category) async {
    final box = await _box;
    return box.values.where((word) => word.category == category).toList();
  }

  // 搜索单词
  Future<List<Word>> searchWords(String query) async {
    final box = await _box;
    return box.values.where((word) => 
      word.japanese.contains(query) ||
      word.pronunciation.contains(query) ||
      word.meaning.contains(query)
    ).toList();
  }

  // 更新单词
  Future<void> updateWord(Word word) async {
    final box = await _box;
    await box.put(word.id, word);
  }

  // 删除单词
  Future<void> deleteWord(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  // 获取所有分类
  Future<List<String>> getAllCategories() async {
    final box = await _box;
    return box.values
        .map((word) => word.category)
        .where((category) => category != null)
        .toSet()
        .cast<String>()
        .toList();
  }
} 