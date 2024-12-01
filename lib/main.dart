import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/word.dart';
import 'screens/vocabulary_screen.dart';  // 添加这行导入语句
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env_config.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
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
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: const MyApp(),
    ),
  );
}
// 根组件，类似于React的App.js
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // 构造函数，类似于React组件的props

  @override
    // build方法类似于React组件的render()方法
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final pColor = _createMaterialColor(themeService.themeColor);
        
        return MaterialApp(
          title: '生词本',
           // theme类似于前端的全局CSS或主题配置
          theme: ThemeData(
            // 使用橙色作为主色调
            primarySwatch: pColor,
            
            // Material 3 的配色方案
            colorScheme: ColorScheme.fromSeed(
              seedColor: pColor,
              // 可以调整亮度
              brightness: Brightness.light,
            ),

            // AppBar 主题
            appBarTheme: AppBarTheme(
              backgroundColor: pColor,
              foregroundColor: Colors.white,  // 文字和图标用白色
            ),

            // 浮动按钮主题
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: pColor,
              foregroundColor: Colors.white,
            ),

            // 按钮主题
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: pColor,
                foregroundColor: Colors.white,
              ),
            ),

            // 图标主题
            iconTheme: IconThemeData(
              color: pColor,
            ),
          ),
              // home相当于路由的根路径'/'
          home: const HomeScreen(),
        );
      },
    );
  }

  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}
