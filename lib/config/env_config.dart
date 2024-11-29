import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => 
      dotenv.env['SUPABASE_URL'] ?? 
      const String.fromEnvironment('SUPABASE_URL');
      
  static String get supabaseAnonKey => 
      dotenv.env['SUPABASE_ANON_KEY'] ?? 
      const String.fromEnvironment('SUPABASE_ANON_KEY');
  
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      print('Warning: .env file not found. Using environment variables.');
    }
  }
} 