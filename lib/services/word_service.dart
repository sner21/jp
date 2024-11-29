import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word.dart';

class WordService {
  final SupabaseClient _supabase;

  WordService(this._supabase);

  Future<List<Word>> getAllWords() async {
    final response = await _supabase
        .from('words')
        .select()
        .eq('user_id', _supabase.auth.currentUser?.id)
        .order('created_at');

    return (response as List)
        .map((word) => Word.fromJson(word))
        .toList();
  }

  Future<void> addWord(Word word) async {
    await _supabase.from('words').insert({
      'japanese': word.japanese,
      'pronunciation': word.pronunciation,
      'meaning': word.meaning,
      'category': word.category,
      'user_id': _supabase.auth.currentUser?.id,
    });
  }

  Future<void> updateWord(Word word) async {
    await _supabase
        .from('words')
        .update({
          'japanese': word.japanese,
          'pronunciation': word.pronunciation,
          'meaning': word.meaning,
          'category': word.category,
        })
        .eq('id', word.id)
        .eq('user_id', _supabase.auth.currentUser?.id);
  }

  Future<void> deleteWord(String id) async {
    await _supabase
        .from('words')
        .delete()
        .eq('id', id)
        .eq('user_id', _supabase.auth.currentUser?.id);
  }

  Future<List<Word>> searchWords(String query) async {
    final response = await _supabase
        .from('words')
        .select()
        .eq('user_id', _supabase.auth.currentUser?.id)
        .ilike('japanese', '%' + query + '%')
        .or.ilike('pronunciation', '%' + query + '%')
        .or.ilike('meaning', '%' + query + '%');

    return (response as List)
        .map((word) => Word.fromJson(word))
        .toList();
  }
} 