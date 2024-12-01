import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tts_service.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TTSService _ttsService = TTSService();
  late SharedPreferences _prefs;
  Color _themeColor = Colors.blue;
  String _ttsLanguage = 'ja-JP';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeColor = Color(_prefs.getInt('themeColor') ?? Colors.blue.value);
      _ttsLanguage = _prefs.getString('ttsLanguage') ?? 'ja-JP';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setInt('themeColor', _themeColor.value);
    await _prefs.setString('ttsLanguage', _ttsLanguage);
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('主题颜色'),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: themeService.themeColor,
                shape: BoxShape.circle,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择主题颜色'),
                  content: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.purple,
                        Colors.orange,
                        Colors.teal,
                      ].map((selectedColor) => InkWell(
                        onTap: () {
                          final themeService = Provider.of<ThemeService>(context, listen: false);
                          themeService.setThemeColor(selectedColor);
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('TTS 语言'),
            subtitle: Text(_ttsLanguage),
            onTap: () async {
              final voices = await _ttsService.getVoices();
              if (!mounted) return;
              
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('选择 TTS 语言'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: voices.map((voice) => ListTile(
                        title: Text(voice),
                        selected: voice == _ttsLanguage,
                        onTap: () {
                          setState(() {
                            _ttsLanguage = voice;
                          });
                          _saveSettings();
                          _ttsService.setLanguage(voice);
                          Navigator.pop(context);
                        },
                      )).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 