import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';
import 'storage_interface.dart';

class LocalStorageService implements StorageInterface {
  static const String boxName = 'words';
  
  Future<Box<Word>> get _box async => await Hive.openBox<Word>(boxName);

  @override
  Future<List<Word>> getAllWords() async {
    final box = await _box;
    return box.values.toList();
  }

  @override
  Future<void> addWord(Word word) async {
    final box = await _box;
    await box.put(word.id, word);
  }

  @override
  Future<void> updateWord(Word word) async {
    final box = await _box;
    await box.put(word.id, word);
  }

  @override
  Future<void> deleteWord(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  @override
  Future<List<Word>> searchWords(String query) async {
    final box = await _box;
    return box.values.where((word) => 
      word.japanese.contains(query) ||
      word.pronunciation.contains(query) ||
      word.meaning.contains(query)
    ).toList();
  }

  @override
  Future<List<String>> getAllCategories() async {
    final box = await _box;
    return box.values
        .map((word) => word.category)
        .where((category) => category != null)
        .toSet()
        .cast<String>()
        .toList();
  }

  @override
  Future<List<Word>> getWordsByCategory(String category) async {
    final box = await _box;
    return box.values
        .where((word) => word.category == category)
        .toList();
  }
} 