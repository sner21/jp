import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/word.dart';
import '../services/storage_manager.dart';
import '../services/tts_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/word_list_view.dart';
import '../widgets/word_card_view.dart';
import '../widgets/import_dialogs.dart';
import '../controllers/vocabulary_controller.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../widgets/word_form.dart';

class VocabularyScreen extends StatefulWidget {
  final VocabularyController controller;

  const VocabularyScreen({
    super.key,
    required this.controller,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late final PageController _pageController;
  late final _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _pageController = PageController(initialPage: _controller.currentWordIndex);
    _controller.loadWords();
    
    // 监听登录状态变化
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _controller.storageManager.syncToCloud();
      }
      _controller.loadWords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('生词本'),
        actions: [
          //TODO 添加单词
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () => _showWordDialog(),
          // ),
          if (_controller.isListView)IconButton(
            icon: Icon(_controller.isSelectMode ? Icons.close : Icons.select_all),
            tooltip: _controller.isSelectMode ? '退出选择' : '批量选择',
            onPressed: () {
              setState(() {
                _controller.isSelectMode = !_controller.isSelectMode;
                _controller.selectedWords.clear();
              });
            },
          ),
          if (_controller.isSelectMode && _controller.selectedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '删除选中项',
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await _controller.deleteSelected();
                  
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('批量删除成功')),
                  );
                  
                  setState(() {
                    _controller.isSelectMode = false;
                  });
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('批量删除失败: $e')),
                  );
                }
              },
            ),
          IconButton(
            icon: Icon(_controller.isListView ? Icons.view_agenda : Icons.view_list),
            tooltip: _controller.isListView ? '卡片视图' : '列表视图',
            onPressed: () {
              setState(() {
                _controller.isListView = !_controller.isListView;
              });
            },
          ),
                    PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload),
            onSelected: (value) {
              if (value == 'text') {
                ImportDialogs.showTextImportDialog(context, _controller.importFromText);
              } else if (value == 'file') {
                ImportDialogs.importFromFile(_controller.importFromText);
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
          ),
                    IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final categories = await _controller.storageManager.getAllCategories();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择分类'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('全部'),
                          onTap: () async {
                            Navigator.pop(context);
                            final allWords = await _controller.storageManager.getAllWords();
                            setState(() {
                              _controller.filteredWords = allWords;
                              _controller.currentWordIndex = 0;
                            });
                          },
                        ),
                        ...categories.map((category) => ListTile(
                          title: Text(category),
                          onTap: () async {
                            Navigator.pop(context);
                            final categoryWords = await _controller.storageManager.getWordsByCategory(category);
                            setState(() {
                              _controller.filteredWords = categoryWords;
                              _controller.currentWordIndex = 0;
                            });
                          },
                        )),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   tooltip: '退出登录',
          //   onPressed: _controller.logout,
          // ),
        ],
      ),
      body: Column(
        children: [
          Visibility(
            visible: _controller.isListView,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: _buildHeader(),
          ),
          Expanded(
            child: _controller.filteredWords.isEmpty
                ? const Center(child: Text('没有单词'))
                : _controller.isListView 
                    ? WordListView(
                        words: _controller.filteredWords,
                        ttsService: _controller.ttsService,
                        isSelectMode: _controller.isSelectMode,
                        selectedWords: _controller.selectedWords,
                        showPronunciation: _controller.showPronunciation,
                        showWordOptions: _showWordOptions,
                        toggleWordSelection: (String wordId) {
                          setState(() {
                            if (_controller.selectedWords.contains(wordId)) {
                              _controller.selectedWords.remove(wordId);
                            } else {
                              _controller.selectedWords.add(wordId);
                            }
                          });
                        },
                        onWordTap: (int index) {
                          setState(() {
                            _controller.currentWordIndex = index;
                            _controller.isListView = false;
                          });
                        },
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _controller.currentWordIndex = index;
                                });
                              },
                              itemCount: _controller.filteredWords.length,
                              itemBuilder: (context, index) {
                                return WordCardView(
                                  word: _controller.filteredWords[index],
                                  ttsService: _controller.ttsService,
                                  showJapanese: _controller.showJapanese,
                                  showPronunciation: _controller.showPronunciation,
                                  showMeaning: _controller.showMeaning,
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 2,
                                  offset: const Offset(0, -1),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FilterChip(
                                        label: const Text('单词', style: TextStyle(fontSize: 20)),
                                        selected: _controller.showJapanese,
                                        showCheckmark: false, 
                                        onSelected: (value) => setState(() {
                                          _controller.showJapanese = value;
                                        }),
                                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      const SizedBox(width: 16),
                                      FilterChip(
                                        label: const Text('读音', style: TextStyle(fontSize: 20)),
                                        selected: _controller.showPronunciation,
                                        showCheckmark: false,
                                        onSelected: (value) => setState(() {
                                          _controller.showPronunciation = value;
                                        }),
                                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      const SizedBox(width: 16),
                                      FilterChip(
                                        label: const Text('释义', style: TextStyle(fontSize: 20)),
                                        selected: _controller.showMeaning,
                                        showCheckmark: false,
                                        onSelected: (value) => setState(() {
                                          _controller.showMeaning = value;
                                        }),
                                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, size: 28),
                                      onPressed: _controller.currentWordIndex > 0
                                          ? () {
                                              _pageController.previousPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          : null,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                    Text(
                                      '${_controller.currentWordIndex + 1}/${_controller.filteredWords.length}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_forward_ios, size: 28),
                                      onPressed: _controller.currentWordIndex < _controller.filteredWords.length - 1
                                          ? () {
                                              _pageController.nextPage(
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          : null,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showWordDialog(),  // 调用添加单词的方法
        child: const Icon(Icons.add),
        tooltip: '添加单词',
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBar(),
          // const SizedBox(height: 12),
          // _buildCategoryDropdown(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: '搜索单词...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _controller.filterWords(''),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onChanged: _controller.filterWords,
    );
  }

  // Widget _buildCategoryDropdown() {
  //   return FutureBuilder<List<String>>(
  //     future: _controller.storageManager.getAllCategories(),
  //     builder: (context, snapshot) {
  //       final List<String> categories = ['全部', ...(snapshot.data ?? [])];
  //       return Container(
  //         width: double.infinity,
  //         decoration: BoxDecoration(
  //           border: Border.all(color: Colors.grey.shade300),
  //           borderRadius: BorderRadius.circular(10),
  //           color: Colors.grey.shade50,
  //         ),
  //         child: DropdownButtonHideUnderline(
  //           child: ButtonTheme(
  //             alignedDropdown: true,
  //             child: DropdownButton<String>(
  //               value: _controller.selectedCategory,
  //               hint: const Text('选择分类'),
  //               isExpanded: true,
  //               padding: const EdgeInsets.symmetric(horizontal: 12),
  //               items: categories.map((category) => DropdownMenuItem<String>(
  //                 value: category == '全部' ? null : category,
  //                 child: Text(category),
  //               )).toList(),
  //               onChanged: _controller.filterByCategory,
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showWordOptions(Word word) {
    // 保存 BuildContext 的引用
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('编辑'),
            onTap: () {
              Navigator.pop(context);
              _showWordDialog(word: word);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('删除'),
            onTap: () async {
              Navigator.pop(context);
              
              try {
                // 更新本地存储
                final box = await Hive.openBox<Word>('words');
                await box.delete(word.id);
                
                // 如果已登录，同步到云端
                if (_controller.storageManager.isLoggedIn) {
                  await _controller.storageManager.deleteWord(word.id);
                }
                
                // 重新加载单词列表
                await _controller.loadWords();
                
                // 使用保存的 scaffoldMessenger 显示消息
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('删除成功')),
                );
                
                // 更新状态
                if (mounted) {
                  setState(() {});
                }
                
              } catch (e) {
                // 使用保存的 scaffoldMessenger 显示错误消息
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('删除失败: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showWordDialog({Word? word}) {
    final form = word != null ? WordForm.fromWord(word) : WordForm.forNewWord();
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
                  category: form.categoryController.text.isEmpty ? null : form.categoryController.text,
                );

                final box = await Hive.openBox<Word>('words');
                await box.put(newWord.id, newWord);
                
                if (_controller.storageManager.isLoggedIn) {
                  if (isEditing) {
                    await _controller.storageManager.updateWord(newWord);
                  } else {
                    await _controller.storageManager.addWord(newWord);
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
                    final index = _controller.filteredWords.indexWhere((w) => w.id == word.id);
                    if (index != -1) {
                      _controller.filteredWords[index] = newWord;
                    }
                  } else {
                    _controller.filteredWords.add(newWord);
                  }
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${isEditing ? '更新' : '添加'}失败: $e')),
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

  @override
  void dispose() {
    _pageController.dispose();
    _controller.ttsService.stop();
    super.dispose();
  }
} 