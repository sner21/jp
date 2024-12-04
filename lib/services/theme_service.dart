import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  late SharedPreferences _prefs;
  Color _themeColor = Colors.orange.shade700;
  // Color _themeColor = Colors.amber.shade800;
  ThemeService() {
    _loadTheme();
  }

  Color get themeColor => _themeColor;

  Future<void> _loadTheme() async {
    _prefs = await SharedPreferences.getInstance();
    final colorValue = _prefs.getInt('themeColor') ?? _themeColor.value;
    _themeColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setThemeColor(Color color) async {
    _themeColor = color;
    await _prefs.setInt('themeColor', color.value);
    notifyListeners();
  }
}
