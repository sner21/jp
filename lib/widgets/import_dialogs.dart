import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImportDialogs {
  static void showTextImportDialog(
      BuildContext context, Function(String) onImport) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '文本导入',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '请粘贴CSV格式的文本：\n'
                  '单词,读音,释义,分类\n'
                  '食べる,たべる,吃,动词\n'
                  '水,みず,水,名词',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: textController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '在此粘贴内容...',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onImport(textController.text);
                    },
                    child: const Text('导入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> importFromFile(Function(String) onImport) async {
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
        onImport(csvString);
      }
    } catch (e) {
      debugPrint('文件导入失败: $e');
      rethrow;
    }
  }
}
