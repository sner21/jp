import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/tts_service.dart';

class WordCard extends StatelessWidget {
  final Word word;
  final TTSService ttsService;
  final VoidCallback onToggleNewWord;
  final bool showJapanese;
  final bool showPronunciation;
  final bool showMeaning;

  const WordCard({
    super.key,
    required this.word,
    required this.ttsService,
    required this.onToggleNewWord,
    required this.showJapanese,
    required this.showPronunciation,
    required this.showMeaning,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showJapanese) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    word.japanese,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  _buildTTSButton(word.japanese),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (showPronunciation) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    word.pronunciation,
                    style: const TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                  _buildTTSButton(word.pronunciation),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (showMeaning)
              Text(
                word.meaning,
                style: const TextStyle(fontSize: 24),
              ),
            if (word.category != null) ...[
              const SizedBox(height: 16),
              Text(
                word.category!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTTSButton(String text) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () async {
        try {
          await ttsService.speak(text);
        } catch (e) {
          // 错误处理可以通过回调传递给父组件
        }
      },
      tooltip: '播放发音',
    );
  }
} 