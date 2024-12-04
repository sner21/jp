import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/tts_service.dart';

class WordCardView extends StatelessWidget {
  final Word word;
  final TTSService ttsService;
  final bool showJapanese;
  final bool showPronunciation;
  final bool showMeaning;

  const WordCardView({
    super.key,
    required this.word,
    required this.ttsService,
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
               const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    word.japanese,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  // IconButton(
                  //   icon: const Icon(Icons.volume_up),
                  //   onPressed: () async {
                  //     try {
                  //       await ttsService.speak(word.japanese);
                  //     } catch (e) {
                  //       if (context.mounted) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(content: Text('发音播放失败，请检查网络连接')),
                  //         );
                  //       }
                  //     }
                  //   },
                  //   tooltip: '播放发音',
                  // ),
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
                  // IconButton(
                  //   icon: const Icon(Icons.volume_up),
                  //   onPressed: () async {
                  //     try {
                  //       await ttsService.speak(word.pronunciation);
                  //     } catch (e) {
                  //       if (context.mounted) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           const SnackBar(content: Text('发音播放失败，请检查网络连接')),
                  //         );
                  //       }
                  //     }
                  //   },
                  //   tooltip: '播放发音',
                  // ),
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
            const Spacer(),
            IconButton(
              iconSize: 36,  // 设置图标大小
              icon: const Icon(Icons.volume_up),
              onPressed: () async {
                try {
                  await ttsService.speak(word.pronunciation ?? word.japanese);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('发音播放失败，请检查网络连接')),
                    );
                  }
                }
              },
              tooltip: '播放发音',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
} 