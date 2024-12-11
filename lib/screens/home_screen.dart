import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'vocabulary_screen.dart';
import '../widgets/login_dialog.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import '../screens/settings_screen.dart';
import 'word_list_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
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
  int _selectedIndex = 0; // 当前选中的页面索引

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
    // 页面列表
    final List<Widget> _pages = [
      VocabularyScreen(controller: controller), // 生词本页面
      const WordListScreen(), // 单词列表页面
      const SettingsScreen(), // 设置页面
    ];
    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width / 3, // 屏幕宽度的三分之一
        height: 50.0,
        margin: const EdgeInsets.only(top: 60),
        child: FloatingActionButton(
          onPressed: () {
            // 中间按钮的点击事件
            setState(() {
              _selectedIndex = 0; // 例如，切换到第二个页面
            });
          },
          child: const Icon(Icons.book, size: 36), // 更大的图标
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 60.0,
        // elevation: 8.0, // 阴影高度
        // padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 0,), // 内边距
        padding: const EdgeInsets.only(bottom: 0, top: 0), // 内边距
        // clipBehavior: Clip.antiAlias, // 裁剪行为
        shape: null,
        // notchMargin: -20.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              // padding: const EdgeInsets.only(bottom: 2),
              child: IconButton(
                // padding: EdgeInsets.all(10),
                // constraints: const BoxConstraints(),
                color: _selectedIndex == 1
                    ? Theme.of(context).bannerTheme.backgroundColor
                    : Colors.grey,
                icon: const Icon(Icons.list),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
            const Expanded(
              child: SizedBox(), // 自动占据剩余空间
            ),
            Expanded(
              child: IconButton(
                   color: _selectedIndex == 2
                    ? Theme.of(context).bannerTheme.backgroundColor
                    : Colors.grey,
                icon: const Icon(Icons.settings),
                onPressed: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
            ),
          ],
        ),
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
}
