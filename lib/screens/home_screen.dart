import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vocabulary_screen.dart';
import '../widgets/login_dialog.dart';
import '../services/storage_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日语学习助手'),
        actions: [
          _buildAuthButton(context),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.book),
              label: const Text('生词本'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VocabularyScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(BuildContext context) {
    final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
    
    return TextButton.icon(
      icon: Icon(
        isLoggedIn ? Icons.logout : Icons.login,
        color: Colors.white,
      ),
      label: Text(
        isLoggedIn ? '登出' : '登录',
        style: const TextStyle(color: Colors.white),
      ),
      onPressed: () => _handleAuthAction(context, isLoggedIn),
    );
  }

  void _handleAuthAction(BuildContext context, bool isLoggedIn) async {
    final storageManager = StorageManager(Supabase.instance.client);
    
    if (isLoggedIn) {
      try {
        await storageManager.syncToLocal();
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
        builder: (context) => const LoginDialog(),
      );
      
      if (result == true && context.mounted) {
        try {
          await storageManager.syncToCloud();
        } catch (e) {
          if (e.toString().contains('云端已有数据')) {
            if (context.mounted) {
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
                  ],
                ),
              );

              if (syncChoice == 'local') {
                await storageManager.syncToCloud();
              } else if (syncChoice == 'cloud') {
                await storageManager.syncToLocal();
              }
            }
          }
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('登录成功，数据已同步')),
          );
        }
      }
    }
  }
} 