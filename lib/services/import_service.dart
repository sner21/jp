import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/word.dart';

class ImportService {
  final _uuid = const Uuid();  // 添加UUID生成器

  Future<List<Word>> importFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );

      if (result != null) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes == null) {
          throw Exception('无法读取文件');
        }

        final csvString = utf8.decode(fileBytes);
        print('CSV内容: $csvString');

        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
        print('解析后的行: $rows');

        List<Word> words = [];
        // 跳过标题行
        for (var i = 1; i < rows.length; i++) {
          var row = rows[i];
          if (row.length >= 3) {
            final word = Word(
              id: _uuid.v4(),  // 使用UUID
              japanese: row[0].toString().trim(),
              pronunciation: row[1].toString().trim(),
              meaning: row[2].toString().trim(),
              category: row.length > 3 ? row[3].toString().trim() : null,
            );
            print('创建的单词: ${word.id} - ${word.japanese} - ${word.pronunciation} - ${word.meaning} - ${word.category}');
            words.add(word);
          }
        }

        return words;
      }
    } catch (e) {
      print('导入错误: $e');
      rethrow;
    }
    return [];
  }

  // 添加从文本导入的方法
  List<Word> importFromText(String text) {
    if (text.isEmpty) {
      return [];
    }

    try {
      List<List<dynamic>> rows = const CsvToListConverter().convert(text);
      print('解析后的行: $rows');

      List<Word> words = [];
      // 跳过标题行
      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.length >= 3) {
          final word = Word(
            id: _uuid.v4(),  // 使用UUID
            japanese: row[0].toString().trim(),
            pronunciation: row[1].toString().trim(),
            meaning: row[2].toString().trim(),
            category: row.length > 3 ? row[3].toString().trim() : null,
          );
          print('创建的单词: ${word.id} - ${word.japanese} - ${word.pronunciation} - ${word.meaning} - ${word.category}');
          words.add(word);
        }
      }

      return words;
    } catch (e) {
      print('文本导入错误: $e');
      rethrow;
    }
  }
} 