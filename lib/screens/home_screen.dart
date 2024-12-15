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
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VocabularyController _vocabularyController;
  final StorageManager _storageManager =
      StorageManager(Supabase.instance.client);
  final TTSService _ttsService = TTSService();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _vocabularyController = VocabularyController.getInstance(
      storageManager: _storageManager,
      ttsService: _ttsService,
      setState: setState,
      context: context,
    );
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        try {
          _vocabularyController.storageManager.syncToCloud();
        } catch (e) {
          SnackBar(
            content: Text('同步失败: $e'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: '重试',
              onPressed: () {
                _vocabularyController.storageManager.syncToCloud();
                _vocabularyController.loadWords();
              },
            ),
          );
        }
      }
      _vocabularyController.loadWords();
    });
    _pages = [
      VocabularyScreen(
        controller: _vocabularyController, 
        mode: 1,
      ),
      VocabularyScreen(
        controller: _vocabularyController, 
        mode: 2,
      ),
      const SettingsScreen(),
    ];
  }
  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const WordListScreen(), 
      VocabularyScreen(controller: _vocabularyController),
      const SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(
        index: _vocabularyController.selectedIndex,
        children: _pages,
      ),
      floatingActionButton: Container(
        width: MediaQuery.of(context).size.width / 3,
        height: 50.0,
        margin: const EdgeInsets.only(top: 60),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shadowColor: Colors.grey,
        height: 60.0,
        // elevation: 8.0, // 阴影高度
        // padding: const EdgeInsets.symmetric(horizontal: 0,vertical: 0,), // 内边距
        padding: const EdgeInsets.only(bottom: 0, top: 0), // 内边距
        // clipBehavior: Clip.antiAlias, // 裁剪行为
        shape: null,
        color: Colors.white,
        // notchMargin: -20.0,
        child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_pages.length, (index) {
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
                      color: _vocabularyController.selectedIndex == index
                          ? Theme.of(context).appBarTheme.backgroundColor
                          : Theme.of(context).bannerTheme.backgroundColor,
                    ),
                    child: IconButton(
                      color:
                          _vocabularyController.selectedIndex == index ? Colors.white : Colors.grey,
                      icon: AnimatedScale(
                        scale: _vocabularyController.selectedIndex == index ? 1.2 : 1.0, // 选中时放大1.2倍
                        duration: const Duration(milliseconds: 200), // 动画持续时间
                        curve: Curves.easeInOut, // 动画曲线
                        child: Icon(icon, size: index == 0 ? 32 : 28),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _vocabularyController.selectedIndex = index;
                          _vocabularyController.isListView = index == 0;
                        });
                      },
                    ),
                  ),
                );
              }),
            )),
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
