import 'package:flutter/foundation.dart';
import '../models/word.dart';
import 'package:uuid/uuid.dart';

class ImportUtils {
  static Future<List<Word>> parseCSVText(String text) async {
    try {
      if (text.isEmpty) {
        throw Exception('内容不能为空');
      }

      debugPrint('开始解析CSV文本: $text');
      
      List<String> lines = text.split('\n');
      debugPrint('分割后的行: $lines');
      
      List<List<String>> rows = lines.map((line) => 
        line.split(',').map((cell) => cell.trim()).toList()
      ).toList();
      
      debugPrint('解析后的行: $rows');
      
      List<Word> words = [];
      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];
        debugPrint('处理行: $row');
        if (row.length >= 3) {
          words.add(Word(
            id: const Uuid().v4(),
            japanese: row[0],
            pronunciation: row[1],
            meaning: row[2],
            category: row.length > 3 ? row[3] : null,
          ));
        }
      }

      if (words.isEmpty) {
        debugPrint('没有解析出有效数据');
        throw Exception('没有有效的数据');
      }

      return words;
    } catch (e) {
      debugPrint('解析错误: $e');
      rethrow;
    }
  }
} 