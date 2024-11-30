import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/word.dart';
import 'screens/vocabulary_screen.dart';  // 添加这行导入语句
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env_config.dart';
import 'screens/home_screen.dart';
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
  runApp(const MyApp());
}
// 根组件，类似于React的App.js
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 构造函数，类似于React组件的props

  @override
    // build方法类似于React组件的render()方法
  Widget build(BuildContext context) {
     // 返回MaterialApp，类似于React Router的配置
    return MaterialApp(
      title: '生词本',
       // theme类似于前端的全局CSS或主题配置
      theme: ThemeData(
        // 使用橙色作为主色调
        primarySwatch: Colors.orange,
        
        // Material 3 的配色方案
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          // 可以调整亮度
          brightness: Brightness.light,
        ),

        // AppBar 主题
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,  // 文字和图标用白色
        ),

        // 浮动按钮主题
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),

        // 按钮主题
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),

        // 图标主题
        iconTheme: const IconThemeData(
          color: Colors.orange,
        ),
      ),
          // home相当于路由的根路径'/'
      home: const HomeScreen(),
    );
  }
}
