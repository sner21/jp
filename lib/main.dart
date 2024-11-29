import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/word.dart';
import 'screens/vocabulary_screen.dart';  // 添加这行导入语句
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env_config.dart';
// 类似于React的入口文件index.js
void main() async {
    // 确保Flutter初始化完成，类似于等待DOM加载完成
  WidgetsFlutterBinding.ensureInitialized();
    // 加载环境变量
  await EnvConfig.load();
    // 初始化Hive数据库，类似于初始化LocalStorage
  await Hive.initFlutter();
    // 注册数据模型，类似于定义TypeScript接口
  Hive.registerAdapter(WordAdapter());
   // 打开数据库，类似于连接数据库
  await Hive.openBox<Word>('words');
    // 初始化 Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
    // 类似于React的ReactDOM.render()
  runApp(const LanguageLearningApp());
}
// 根组件，类似于React的App.js
class LanguageLearningApp extends StatelessWidget {
  const LanguageLearningApp({super.key}); // 构造函数，类似于React组件的props

  @override
    // build方法类似于React组件的render()方法
  Widget build(BuildContext context) {
     // 返回MaterialApp，类似于React Router的配置
    return MaterialApp(
      title: '语言学习助手 ',
       // theme类似于前端的全局CSS或主题配置
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
          // home相当于路由的根路径'/'
      home: const HomePage(),
    );
  }
}
// HomePage组件，类似于前端的一个页面组件
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
        // Scaffold类似于前端的页面布局容器
    return Scaffold(
       // AppBar类似于前端的导航栏组件
      appBar: AppBar(
        title: const Text('日语学习 z'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
                    // mainAxisAlignment类似于CSS的justify-content

          mainAxisAlignment: MainAxisAlignment.center,
                // 调用自定义组件方法
          children: [
            _buildMenuButton(
              context,
              '单词学习 ',
              Icons.book,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VocabularyScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 自定义组件方法，类似于React的函数式组件
  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,  // VoidCallback类似于前端的()=>void
  ) {
        // SizedBox类似于CSS的width和height设置
    return SizedBox(
      width: double.infinity, // 类似于CSS的width: 100%
        // ElevatedButton类似于HTML的<button>元素
      child: ElevatedButton.icon(
        onPressed: onPressed,  // 类似于onClick事件处理
        icon: Icon(icon),
        label: Text(title),
             // style类似于CSS样式
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
