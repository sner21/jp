import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';
import 'storage_interface.dart';

class RemoteStorageService implements StorageInterface {
  final SupabaseClient _supabase;

  RemoteStorageService(this._supabase);

  String get _userId {
    final id = _supabase.auth.currentUser?.id;
    if (id == null) throw Exception('User not logged in');
    return id;
  }

  bool get _isLoggedIn => _supabase.auth.currentUser != null;

  @override
  Future<List<Word>> getAllWords() async {
    if (!_isLoggedIn) return [];
    
    try {
      final response = await _supabase
          .from('words')
          .select()
          .eq('user_id', _userId)
          .order('created_at');

      return (response as List)
          .map((word) => Word.fromJson(word as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting words: $e');
      return [];
    }
  }

  @override
  Future<void> addWord(Word word) async {
    if (!_isLoggedIn) return;
    
    try {
      await _supabase.from('words').insert({
        ...word.toJson(),
        'user_id': _userId,
      });
    } catch (e) {
      print('Error adding word: $e');
    }
  }

  @override
  Future<void> updateWord(Word word) async {
    if (!_isLoggedIn) return;
    
    try {
      await _supabase
          .from('words')
          .update(word.toJson())
          .eq('id', word.id)
          .eq('user_id', _userId);
    } catch (e) {
      print('Error updating word: $e');
    }
  }

  @override
  Future<void> deleteWord(String id) async {
    if (!_isLoggedIn) return;
    
    try {
      await _supabase
          .from('words')
          .delete()
          .eq('id', id)
          .eq('user_id', _userId);
    } catch (e) {
      print('Error deleting word: $e');
    }
  }

  @override
  Future<List<Word>> searchWords(String query) async {
    if (!_isLoggedIn) return [];
    
    try {
      final response = await _supabase
          .from('words')
          .select()
          .eq('user_id', _userId)
          .or('japanese.ilike.%$query%,pronunciation.ilike.%$query%,meaning.ilike.%$query%');

      return (response as List)
          .map((word) => Word.fromJson(word as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching words: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getAllCategories() async {
    if (!_isLoggedIn) return [];
    
    try {
      final response = await _supabase
          .from('words')
          .select('category')
          .eq('user_id', _userId)
          .not('category', 'is', null);

      return (response as List)
          .map((item) => item['category'] as String)
          .toSet()
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  @override
  Future<List<Word>> getWordsByCategory(String category) async {
    if (!_isLoggedIn) return [];
    
    try {
      final response = await _supabase
          .from('words')
          .select()
          .eq('user_id', _userId)
          .eq('category', category)
          .order('created_at');

      return (response as List)
          .map((word) => Word.fromJson(word as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting words by category: $e');
      return [];
    }
  }
} 