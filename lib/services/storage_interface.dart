import '../models/word.dart';

abstract class StorageInterface {
  Future<List<Word>> getAllWords();
  Future<void> addWord(Word word);
  Future<void> updateWord(Word word);
  Future<void> deleteWord(String? id);
  Future<List<Word>> searchWords(String query);
  Future<List<String>> getAllCategories();
  Future<List<Word>> getWordsByCategory(String category);
} 