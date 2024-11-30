import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';

class TTSService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentText;
  bool _isPlaying = false;
  final Map<String, String> _cache = {}; // 内存缓存
  static const int _maxCacheSize = 100; // 最大缓存数量

  // 生成缓存key
  String _getCacheKey(String text, String languageCode) {
    final bytes = utf8.encode('$text:$languageCode');
    return md5.convert(bytes).toString();
  }

  // 获取缓存目录
  Future<Directory> get _cacheDir async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/tts_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create();
    }
    return cacheDir;
  }

  // 清理旧缓存
  Future<void> _cleanOldCache() async {
    try {
      final dir = await _cacheDir;
      final files = await dir.list().toList();
      if (files.length > _maxCacheSize) {
        // 按修改时间排序
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        // 删除旧文件
        for (var i = 0; i < files.length - _maxCacheSize; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      print('Cache cleaning error: $e');
    }
  }

  String _detectLanguage(String text) {
    final hiragana = RegExp(r'[\u3040-\u309F]');
    final katakana = RegExp(r'[\u30A0-\u30FF]');
    final kanji = RegExp(r'[\u4E00-\u9FAF]');
    final english = RegExp(r'[a-zA-Z]');

    if (hiragana.hasMatch(text) || katakana.hasMatch(text) || kanji.hasMatch(text)) {
      return 'ja';
    } else if (english.hasMatch(text)) {
      return 'en';
    }
    return 'ja';
  }

  Future<void> speak(String text) async {
    try {
      if (_isPlaying && text == _currentText) {
        await stop();
        return;
      }

      _currentText = text;
      _isPlaying = true;

      final languageCode = _detectLanguage(text);
      final cacheKey = _getCacheKey(text, languageCode);
      final cacheDir = await _cacheDir;
      final cachePath = '${cacheDir.path}/$cacheKey.mp3';

      File audioFile;
      
      // 检查缓存
      if (_cache.containsKey(cacheKey) && await File(cachePath).exists()) {
        print('Using cached audio');
        audioFile = File(cachePath);
      } else {
        print('Downloading new audio');
        final url = Uri.parse(
          'https://translate.google.com/translate_tts?ie=UTF-8'
          '&q=${Uri.encodeComponent(text)}'
          '&tl=$languageCode'
          '&client=tw-ob'
        );
        
        final response = await http.get(url, headers: {
          'User-Agent': 'Mozilla/5.0',
          'Referer': 'https://translate.google.com'
        });
        
        if (response.statusCode == 200) {
          // 保存到缓存
          audioFile = File(cachePath);
          await audioFile.writeAsBytes(response.bodyBytes);
          _cache[cacheKey] = cachePath;
          
          // 清理旧缓存
          await _cleanOldCache();
        } else {
          throw Exception('Failed to get audio: ${response.statusCode}');
        }
      }

      // 播放音频
      await _audioPlayer.play(DeviceFileSource(audioFile.path));
      
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
      });
    } catch (e) {
      _isPlaying = false;
      print('TTS error: $e');
      rethrow;
    }
  }

  Future<void> clearCache() async {
    try {
      final dir = await _cacheDir;
      await dir.delete(recursive: true);
      _cache.clear();
    } catch (e) {
      print('Cache clearing error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  // 添加 isAvailable 检查方法
  Future<bool> get isAvailable async {
    try {
      // 检查缓存目录是否可用
      await _cacheDir;
      
      // 测试网络连接和服务可用性
      final testUrl = Uri.parse(
        'https://translate.google.com/translate_tts?ie=UTF-8'
        '&q=${Uri.encodeComponent("test")}'
        '&tl=en'
        '&client=tw-ob'
      );
      
      final response = await http.get(testUrl, headers: {
        'User-Agent': 'Mozilla/5.0',
        'Referer': 'https://translate.google.com'
      });
      
      return response.statusCode == 200;
    } catch (e) {
      print('TTS availability check error: $e');
      return false;
    }
  }
} 
