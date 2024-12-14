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
  int _selectedIndex = 1; // 当前选中的页面索引

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
    ); // 页面列表
    final List<Widget> _pages = [
      const WordListScreen(), // 单词列表页面
      VocabularyScreen(controller: controller), // 生词本页面
      const SettingsScreen(), // 设置页面
    ];
    print(333);

    return Scaffold(
      body: _pages[_selectedIndex],
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width / 3, // 屏幕宽度的三分之一
        height: 50.0,
        margin: const EdgeInsets.only(top: 60),
        // child: FloatingActionButton(
        //   backgroundColor: _selectedIndex == 0
        //       ? Theme.of(context).bannerTheme.backgroundColor
        //       : Theme.of(context).appBarTheme.backgroundColor,
        //   onPressed: () {
        //     // 中间按钮的点击事件
        //     setState(() {
        //       _selectedIndex = 0; // 例如，切换到第二个页面
        //     });
        //   },
        //   child: const Icon(Icons.book, size: 36), // 更大的图标
        // ),
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
          children: List.generate(_pages.length, (index) {
            // 定义每个页面对应的图标
            IconData icon;
            switch (index) {
              case 0:
                icon = Icons.list;
                break;
              case 1:
                icon = Icons.book;
                break;
              case 2:
                icon = Icons.settings;
                break;
              default:
                icon = Icons.error;
            }

            return Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  color: _selectedIndex == index
                      ? Theme.of(context).appBarTheme.backgroundColor
                      : Theme.of(context).bannerTheme.backgroundColor,
                ),
                child: IconButton(
                  color: _selectedIndex == index ? Colors.white : Colors.grey,
                  icon: AnimatedScale(
                    scale: _selectedIndex == index ? 1.2 : 1.0, // 选中时放大1.2倍
                    duration: const Duration(milliseconds: 200), // 动画持续时间
                    curve: Curves.easeInOut, // 动画曲线
                    child: Icon(icon, size: index == 0 ? 32 : 28),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                ),
              ),
            );
          }),
          // children: <Widget>[
          //   Expanded(
          //     child: Container(
          //       // height: 60.0,
          //       decoration: BoxDecoration(
          //         // 设置圆角
          //         borderRadius: BorderRadius.circular(14.0), // 可以调整数值来改变圆角大小
          //         color: _selectedIndex == 1
          //             ? Theme.of(context).appBarTheme.backgroundColor
          //             : Theme.of(context).bannerTheme.backgroundColor,
          //       ),
          //       child: IconButton(
          //         // constraints: const BoxConstraints(minHeight: 800),
          //         color: _selectedIndex == 1 ? Colors.white : Colors.grey,
          //         icon: const Icon(Icons.list,size: 28),
          //         onPressed: () {
          //           setState(() {
          //             _selectedIndex = 1;
          //           });
          //         },
          //       ),
          //     ),
          //   ),
          //         Expanded(
          //     child: Container(
          //       // height: 60.0,
          //       decoration: BoxDecoration(
          //         // 设置圆角
          //         borderRadius: BorderRadius.circular(14.0), // 可以调整数值来改变圆角大小
          //         color: _selectedIndex == 0
          //             ? Theme.of(context).appBarTheme.backgroundColor
          //             : Theme.of(context).bannerTheme.backgroundColor,
          //       ),
          //       child: IconButton(
          //         // constraints: const BoxConstraints(minHeight: 800),
          //         color: _selectedIndex == 0 ? Colors.white : Colors.grey,
          //         icon: const Icon(Icons.book,size: 32),
          //         onPressed: () {
          //           setState(() {
          //             _selectedIndex = 0;
          //           });
          //         },
          //       ),
          //     ),
          //   ),
          //   Expanded(
          //     child: Container(
          //       // height: 60.0,
          //       decoration: BoxDecoration(
          //         // 设置圆角
          //         borderRadius: BorderRadius.circular(14.0), // 可以调整数值来改变圆角大小
          //         color: _selectedIndex == 2
          //             ? Theme.of(context).appBarTheme.backgroundColor
          //             : Theme.of(context).bannerTheme.backgroundColor,
          //       ),
          //       child: IconButton(
          //         // constraints: const BoxConstraints(minHeight: 800),
          //         color: _selectedIndex == 2 ? Colors.white : Colors.grey,
          //         icon: const Icon(Icons.settings,size: 28),
          //         onPressed: () {
          //           setState(() {
          //             _selectedIndex = 2;
          //           });
          //         },
          //       ),
          //     ),
          //   ),
          // ],
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
