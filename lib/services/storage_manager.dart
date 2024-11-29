import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import 'storage_interface.dart';

class StorageManager implements StorageInterface {
  final SupabaseClient _supabase;
  Box<Word>? _wordBox;
  bool get isLoggedIn => _supabase.auth.currentUser != null;

  StorageManager(this._supabase);

  Future<void> init() async {
    if (_wordBox == null) {
      _wordBox = await Hive.openBox<Word>('words');
    }
  }

  @override
  Future<List<Word>> getAllWords() async {
    await init();
    
    if (isLoggedIn) {
      try {
        final response = await _supabase
            .from('words')
            .select()
            .eq('user_id', _supabase.auth.currentUser!.id);
        
        return (response as List).map((json) => Word(
              id: json['id'].toString(),
              japanese: json['japanese'],
              pronunciation: json['pronunciation'],
              meaning: json['meaning'],
              category: json['category'],
            )).toList();
      } catch (e) {
        return _wordBox!.values.toList();
      }
    }
    return _wordBox!.values.toList();
  }

  @override
  Future<void> addWord(Word word) async {
    await init();
    
    if (isLoggedIn) {
      final response = await _supabase.from('words').insert({
        'japanese': word.japanese,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'category': word.category,
        'user_id': _supabase.auth.currentUser!.id,
      }).select();
      
      if (response != null && response.isNotEmpty) {
        final newWord = word.copyWith(id: response[0]['id'].toString());
        await _wordBox!.put(newWord.id, newWord);
      }
    } else {
      final newWord = word.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString()
      );
      await _wordBox!.put(newWord.id, newWord);
    }
  }

  @override
  Future<void> updateWord(Word word) async {
    await init();
    if (word.id == null) return;
    
    if (isLoggedIn) {
      await _supabase.from('words').update({
        'japanese': word.japanese,
        'pronunciation': word.pronunciation,
        'meaning': word.meaning,
        'category': word.category,
      }).eq('id', word.id!);
    }
    await _wordBox!.put(word.id, word);
  }

  @override
  Future<void> deleteWord(String? id) async {
    await init();
    if (id == null) return;
    
    if (isLoggedIn) {
      await _supabase.from('words').delete().eq('id', id);
    }
    await _wordBox!.delete(id);
  }

  @override
  Future<List<String>> getAllCategories() async {
    await init();
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
    await init();
    final words = await getAllWords();
    return words.where((word) => word.category == category).toList();
  }

  @override
  Future<List<Word>> searchWords(String query) async {
    await init();
    final allWords = await getAllWords();
    final lowercaseQuery = query.toLowerCase();
    
    return allWords.where((word) {
      return word.japanese.toLowerCase().contains(lowercaseQuery) ||
             word.pronunciation.toLowerCase().contains(lowercaseQuery) ||
             word.meaning.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<void> syncToCloud() async {
    await init();
    if (!isLoggedIn) return;
    
    try {
      final cloudResponse = await _supabase
          .from('words')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      if (cloudResponse.isNotEmpty) {
        throw Exception('云端已有数据，请选择同步方向');
      }

      final localWords = _wordBox!.values.toList();
      for (final word in localWords) {
        final response = await _supabase.from('words').insert({
          'japanese': word.japanese,
          'pronunciation': word.pronunciation,
          'meaning': word.meaning,
          'category': word.category,
          'user_id': _supabase.auth.currentUser!.id,
        }).select();
        
        if (response != null && response.isNotEmpty) {
          final cloudId = response[0]['id'].toString();
          await _wordBox!.delete(word.id);
          await _wordBox!.put(cloudId, word.copyWith(id: cloudId));
        }
      }
    } catch (e) {
      print('Sync to cloud error: $e');
      rethrow;
    }
  }

  Future<void> syncToLocal() async {
    await init();
    if (!isLoggedIn) return;
    
    try {
      final response = await _supabase
          .from('words')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id);
      
      await _wordBox!.clear();
      
      for (final item in response) {
        final word = Word(
          id: item['id'].toString(),
          japanese: item['japanese'],
          pronunciation: item['pronunciation'],
          meaning: item['meaning'],
          category: item['category'],
        );
        await _wordBox!.put(word.id, word);
      }
    } catch (e) {
      print('Sync to local error: $e');
      rethrow;
    }
  }
} 