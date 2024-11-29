import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import 'storage_interface.dart';
import 'local_storage_service.dart';
import 'remote_storage_service.dart';

class StorageManager implements StorageInterface {
  final LocalStorageService _localStorage;
  final RemoteStorageService _remoteStorage;
  final SupabaseClient _supabase;

  StorageManager(this._supabase)
      : _localStorage = LocalStorageService(),
        _remoteStorage = RemoteStorageService(_supabase);

  bool get isLoggedIn => _supabase.auth.currentUser != null;

  StorageInterface get _currentStorage =>
      isLoggedIn ? _remoteStorage : _localStorage;

  // 同步本地和远程数据
  Future<void> syncData() async {
    if (isLoggedIn) {
      // 获取本地数据
      final localWords = await _localStorage.getAllWords();
      if (localWords.isNotEmpty) {
        // 上传到远程
        for (var word in localWords) {
          await _remoteStorage.addWord(word);
        }
        // 清除本地数据
        for (var word in localWords) {
          await _localStorage.deleteWord(word.id);
        }
      }
    }
  }

  @override
  Future<List<Word>> getAllWords() => _currentStorage.getAllWords();

  @override
  Future<void> addWord(Word word) => _currentStorage.addWord(word);

  @override
  Future<void> updateWord(Word word) => _currentStorage.updateWord(word);

  @override
  Future<void> deleteWord(String id) => _currentStorage.deleteWord(id);

  @override
  Future<List<Word>> searchWords(String query) =>
      _currentStorage.searchWords(query);

  @override
  Future<List<String>> getAllCategories() =>
      _currentStorage.getAllCategories();

  @override
  Future<List<Word>> getWordsByCategory(String category) =>
      _currentStorage.getWordsByCategory(category);
} 