import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vocabulary_screen.dart';
import '../widgets/login_dialog.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import '../screens/settings_screen.dart';
import 'word_list_screen.dart';
import 'package:flutter/foundation.dart'; // 添加这行
import 'dart:developer' as developer; // 添加这行
import '../widgets/import_dialogs.dart';
import '../controllers/vocabulary_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageManager _storageManager =
      StorageManager(Supabase.instance.client);
  final TTSService _ttsService = TTSService();

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

  @override
  Widget build(BuildContext context) {
    final controller = VocabularyController.getInstance(
      storageManager: StorageManager(Supabase.instance.client),
      ttsService: TTSService(),
      setState: setState,
      context: context,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slin'),
        actions: [
          PopupMenuButton<String>(
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
              // 添加清理缓存选项
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services),
                    SizedBox(width: 8),
                    Text('清理语音缓存'),
                  ],
                ),
              ),
              // 登录/登出选项
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
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          // 首页卡片
          _buildFeatureCard(
            context,
            '生词本',
            Icons.book,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VocabularyScreen(controller: controller),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            '单词列表',
            Icons.list,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WordListScreen(),
              ),
            ),
          ),
          _buildFeatureCard(
            context,
            '导入',
            Icons.list,
            () => ImportDialogs.showTextImportDialog(
                context, controller.importFromText),
          ),
                    _buildFeatureCard(
            context,
            '设置',
            Icons.settings,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            ),
          ),
          // ... 其他功能卡片
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAuthAction(BuildContext context, bool isLoggedIn, {bool isRegister = false}) async {
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
}
