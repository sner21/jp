import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/storage_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/login_dialog.dart';
import '../widgets/import_dialogs.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../controllers/vocabulary_controller.dart';
import '../models/word.dart';
import 'package:hive/hive.dart';
import '../widgets/word_form.dart';
import 'package:uuid/uuid.dart';

class ImportScreen extends StatefulWidget {
  final VocabularyController controller;
  const ImportScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TTSService _ttsService = TTSService();
  late SharedPreferences _prefs;
  Color _themeColor = Colors.blue;
  String _ttsLanguage = 'ja-JP';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeColor = Color(_prefs.getInt('themeColor') ?? Colors.blue.value);
      _ttsLanguage = _prefs.getString('ttsLanguage') ?? 'ja-JP';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt('themeColor', _themeColor.value);
    await _prefs.setString('ttsLanguage', _ttsLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final StorageManager _storageManager =
        StorageManager(Supabase.instance.client);
    final TTSService _ttsService = TTSService();
    final themeService = Provider.of<ThemeService>(context);
    void _handleAuthAction(BuildContext context, bool isLoggedIn,
        {bool isRegister = false}) async {
      if (isLoggedIn) {
        try {
          await _storageManager.syncToLocal();
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已登出，数据已保存到本地')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('登出失败，请稍后重试')),
            );
          }
        }
      } else {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => LoginDialog(isRegister: isRegister),
        );

        if (result == true && context.mounted) {
          try {
            debugPrint('登录成功，准备同步');

            // 显示加载指示器
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              debugPrint('开始调用 syncToCloud');
              await _storageManager.syncToCloud();
              debugPrint('syncToCloud 调用完成');

              // 关闭加载指示器
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              debugPrint('同步过程出错: $e');

              // 关闭加载指示器
              if (context.mounted) {
                Navigator.of(context).pop();
              }

              if (e.toString().contains('云端已有数据') && context.mounted) {
                final syncChoice = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('数据同步'),
                    content: const Text('检测到云端已有数据，请选择同步方式：'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'local'),
                        child: const Text('使用本地数据'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cloud'),
                        child: const Text('使用云端数据'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'cancel'),
                        child: const Text('取消'),
                      ),
                    ],
                  ),
                );

                if (syncChoice == 'local') {
                  await _storageManager.syncToCloud(forceLocal: true);
                } else if (syncChoice == 'cloud') {
                  await _storageManager.syncToLocal();
                }
                // 如果选择 'cancel'，什么都不做
              }
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('登录成功，数据已同步')),
              );
            }
          } catch (e) {
            debugPrint('整体操作失败: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('操作失败: $e')),
              );
            }
          }
        }
      }
    }

    void _showWordDialog({Word? word}) {
      final form =
          word != null ? WordForm.fromWord(word) : WordForm.forNewWord();
      final isEditing = word != null;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isEditing ? '编辑单词' : '添加单词'),
          content: SingleChildScrollView(
            child: form,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  if (form.japaneseController.text.isEmpty ||
                      form.pronunciationController.text.isEmpty ||
                      form.meaningController.text.isEmpty) {
                    throw Exception('请填写必要信息');
                  }
                  final newWord = Word(
                    id: isEditing ? word!.id : const Uuid().v4(),
                    japanese: form.japaneseController.text,
                    pronunciation: form.pronunciationController.text,
                    meaning: form.meaningController.text,
                    category: form.categoryController.text.isEmpty
                        ? null
                        : form.categoryController.text,
                  );

                  final box = await Hive.openBox<Word>('words');
                  await box.put(newWord.id, newWord);

                  if (widget.controller.storageManager.isLoggedIn) {
                    if (isEditing) {
                      await widget.controller.storageManager
                          .updateWord(newWord);
                    } else {
                      await widget.controller.storageManager.addWord(newWord);
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${isEditing ? '更新' : '添加'}成功')),
                    );
                  }

                  setState(() {
                    if (isEditing) {
                      final index = widget.controller.filteredWords
                          .indexWhere((w) => w.id == word.id);
                      if (index != -1) {
                        widget.controller.filteredWords[index] = newWord;
                      }
                    } else {
                      widget.controller.filteredWords.add(newWord);
                    }
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${isEditing ? '更新' : '添加'}失败: $e')),
                    );
                  }
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('单词导入'),
      ),
      body: ListView(
        children: [
          ListTile(
              title: const Text('添加单词'),
              onTap: () {
                _showWordDialog();
              }),
          ListTile(
              title: const Text('文本导入(csv)'),
              onTap: () {
                ImportDialogs.showTextImportDialog(
                    context, widget.controller.importFromText);
              }),
          ListTile(
              title: const Text('文件导入(csv)'),
              onTap: () {
                ImportDialogs.importFromFile(widget.controller.importFromText);
              }),
        ],
      ),
    );
  }
}
