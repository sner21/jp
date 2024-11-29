import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class TTSService {
  final FlutterTts? _flutterTts = kIsWeb ? null : FlutterTts();
  
  TTSService() {
    if (!kIsWeb) {
      _initTTS();
    }
  }

  Future<void> _initTTS() async {
    if (kIsWeb) return;
    
    try {
      await _flutterTts?.setLanguage('ja-JP');
      await _flutterTts?.setVolume(1.0);
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setPitch(1.0);
    } catch (e) {
      print('TTS init error: $e');
    }
  }

  Future<bool> get isLanguageAvailable async {
    if (kIsWeb) return false;
    
    try {
      final List<dynamic>? languages = await _flutterTts?.getLanguages;
      return languages?.contains('ja-JP') ?? false;
    } catch (e) {
      print('TTS Language check error: $e');
      return false;
    }
  }

  Future<void> speak(String text) async {
    if (kIsWeb) return;
    
    try {
      await _flutterTts?.speak(text);
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    
    try {
      await _flutterTts?.stop();
    } catch (e) {
      print('TTS Stop error: $e');
    }
  }

  // 简化的设置方法
  Future<void> setVolume(double volume) async {
    if (kIsWeb) return;
    await _flutterTts?.setVolume(volume);
  }

  Future<void> setSpeechRate(double rate) async {
    if (kIsWeb) return;
    await _flutterTts?.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    if (kIsWeb) return;
    await _flutterTts?.setPitch(pitch);
  }
} 