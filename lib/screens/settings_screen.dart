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

class SettingsScreen extends StatefulWidget {
  final VocabularyController controller;
  const SettingsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

    Future<void> _clearTTSCache() async {
      try {
        await _ttsService.clearCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('语音缓存已清理')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('清理缓存失败')),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        // actions: [
        //   PopupMenuButton<String>(
        //     onSelected: (value) async {
        //       switch (value) {
        //         case 'clear_cache':
        //           await _clearTTSCache();
        //           break;
        //         case 'register':
        //           _handleAuthAction(context, false, isRegister: true);
        //           break;
        //         case 'login':
        //           _handleAuthAction(context, false);
        //           break;
        //         case 'logout':
        //           _handleAuthAction(context, true);
        //           break;
        //       }
        //     },
        //     itemBuilder: (context) => [
        //       if (!_storageManager.isLoggedIn) ...[
        //         const PopupMenuItem(
        //           value: 'register',
        //           child: Row(
        //             children: [
        //               Icon(Icons.person_add),
        //               SizedBox(width: 8),
        //               Text('注册'),
        //             ],
        //           ),
        //         ),
        //         const PopupMenuItem(
        //           value: 'login',
        //           child: Row(
        //             children: [
        //               Icon(Icons.login),
        //               SizedBox(width: 8),
        //               Text('登录'),
        //             ],
        //           ),
        //         ),
        //       ] else
        //         const PopupMenuItem(
        //           value: 'logout',
        //           child: Row(
        //             children: [
        //               Icon(Icons.logout),
        //               SizedBox(width: 8),
        //               Text('退出登录'),
        //             ],
        //           ),
        //         ),
        //     ],
        //   ),
        // ],
      ),
      body: ListView(
        children: [
          PopupMenuButton<String>(
            child: ListTile(
              title: Text(_storageManager.isLoggedIn?'注销':"未登录"),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'clear_cache':
                  await _clearTTSCache();
                  break;
                case 'register':
                  _handleAuthAction(context, false, isRegister: true);
                  break;
                case 'login':
                  _handleAuthAction(context, false);
                  break;
                case 'logout':
                  _handleAuthAction(context, true);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (!_storageManager.isLoggedIn) ...[
                const PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('注册'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'login',
                  child: Row(
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 8),
                      Text('登录'),
                    ],
                  ),
                ),
              ] else
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('退出登录'),
                    ],
                  ),
                ),
            ],
          ),
          ListTile(
            title: const Text('主题颜色'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeService.themeColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择主题颜色'),
                  content: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.purple,
                        Colors.amber,
                        Colors.orange,
                        Colors.orange.shade700,
                        Colors.teal,
                      ]
                          .map((selectedColor) => InkWell(
                                onTap: () {
                                  final themeService =
                                      Provider.of<ThemeService>(context,
                                          listen: false);
                                  themeService.setThemeColor(selectedColor);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            style: const ButtonStyle(
              alignment: Alignment.centerLeft,
            ),
            // icon: const Icon(Icons.file_upload),
            onSelected: (value) {
              if (value == 'text') {
                ImportDialogs.showTextImportDialog(
                    context, widget.controller.importFromText);
              } else if (value == 'file') {
                ImportDialogs.importFromFile(widget.controller.importFromText);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'text',
                child: Text('文本导入'),
              ),
              if (!kIsWeb)
                const PopupMenuItem(
                  value: 'file',
                  child: Text('文件导入'),
                ),
            ],
            child: const ListTile(
              title: Text('导入数据'),
            ),
          ),
          ListTile(
            title: const Text('TTS 语言'),
            subtitle: Text(_ttsLanguage),
            onTap: () async {
              final voices = await _ttsService.getVoices();
              if (!mounted) return;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择 TTS 语言'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: voices
                          .map((voice) => ListTile(
                                title: Text(voice),
                                selected: voice == _ttsLanguage,
                                onTap: () {
                                  setState(() {
                                    _ttsLanguage = voice;
                                  });
                                  _saveSettings();
                                  _ttsService.setLanguage(voice);
                                  Navigator.pop(context);
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('缓存清理'),
            // trailing: Container(
            //   width: 24,
            //   height: 24,
            //   decoration: BoxDecoration(
            //     color: themeService.themeColor,
            //     shape: BoxShape.circle,
            //   ),
            // ),
            onTap: () {
              _clearTTSCache();
            },
          ),
        ],
      ),
    );
  }
}
