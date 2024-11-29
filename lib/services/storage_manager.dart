import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import 'storage_interface.dart';

class StorageManager implements StorageInterface {
  final SupabaseClient _supabase;
  late Box<Word> _wordBox;
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  StorageManager(this._supabase) {
    _initHive();
  }

  Future<void> _initHive() async {
    await Hive.openBox<Word>('words').then((box) async {
      // 可选：迁移现有数据
      for (var word in box.values) {
        final updatedWord = word.copyWith(isNewWord: false);
        await box.put(word.id, updatedWord);
      }
    });
  }

  @override
  Future<List<String>> getAllCategories() async {
    final words = await getAllWords();
    return words
        .map((word) => word.category)
        .where((category) => category != null)
        .map((category) => category!)
        .toSet()
        .toList();
  }

  @override
  Future<List<Word>> getWordsByCategory(String category) async {
    final words = await getAllWords();
    return words.where((word) => word.category == category).toList();
  }

  @override
  Future<List<Word>> searchWords(String query) async {
    final allWords = await getAllWords();
    final lowercaseQuery = query.toLowerCase();
    
    return allWords.where((word) {
      return word.japanese.toLowerCase().contains(lowercaseQuery) ||
             word.pronunciation.toLowerCase().contains(lowercaseQuery) ||
             word.meaning.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<List<Word>> getAllWords() async {
    if (isLoggedIn) {
      try {
        final response = await _supabase
            .from('words')
            .select()
            .eq('user_id', _supabase.auth.currentUser!.id);
        
        return (response as List)
            .map((json) => Word(
                  id: json['id'],
                  japanese: json['japanese'],
                  pronunciation: json['pronunciation'],
                  meaning: json['meaning'],
                  category: json['category'],
                ))
            .toList();
      } catch (e) {
        print('Error loading from Supabase: $e');
        return [];
      }
    } else {
      return _wordBox.values.toList();
    }
  }

  Future<void> addWord(Word word) async {
    if (isLoggedIn) {
      final response = await _supabase.from('words').insert({
        'japanese': word.japanese,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'category': word.category,
        'user_id': _supabase.auth.currentUser!.id,
      }).select();
      
      if (response != null && response.isNotEmpty) {
        final newWord = word.copyWith(id: response[0]['id']);
        await _wordBox.put(newWord.id, newWord);
      }
    } else {
      final newWord = word.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString()
      );
      await _wordBox.put(newWord.id, newWord);
    }
  }

  @override
  Future<void> updateWord(Word word) async {
    if (word.id == null) return;
    
    if (isLoggedIn) {
      await _supabase.from('words').update({
        'japanese': word.japanese,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'category': word.category,
      }).eq('id', word.id!);
    } else {
      await _wordBox.put(word.id, word);
    }
  }

  @override
  Future<void> deleteWord(String? id) async {
    if (id == null) return;
    
    if (isLoggedIn) {
      await _supabase.from('words').delete().eq('id', id);
    } else {
      await _wordBox.delete(id);
    }
  }

  // 添加数据同步方法
  Future<void> syncToCloud() async {
    if (!isLoggedIn) return;

    final localWords = _wordBox.values.toList();
    for (final word in localWords) {
      await _supabase.from('words').insert({
        'japanese': word.japanese,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'category': word.category,
        'user_id': _supabase.auth.currentUser!.id,
      });
    }
    
    // 清空本地数据
    await _wordBox.clear();
  }

  // 添加从云端同步到本地的方法
  Future<void> syncToLocal() async {
    if (isLoggedIn) return;

    final cloudWords = await getAllWords();
    await _wordBox.clear();
    for (final word in cloudWords) {
      await _wordBox.put(word.id, word);
    }
  }
} 