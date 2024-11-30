import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/tts_service.dart';

class WordListView extends StatelessWidget {
  final List<Word> words;
  final TTSService ttsService;
  final bool isSelectMode;
  final Set<String> selectedWords;
  final bool showPronunciation;
  final Function(Word) showWordOptions;
  final Function(String) toggleWordSelection;
  final Function(int) onWordTap;

  const WordListView({
    super.key,
    required this.words,
    required this.ttsService,
    required this.isSelectMode,
    required this.selectedWords,
    required this.showPronunciation,
    required this.showWordOptions,
    required this.toggleWordSelection,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: words.length,
      itemBuilder: (context, index) {
        final word = words[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: isSelectMode ? Checkbox(
              value: selectedWords.contains(word.id),
              onChanged: (bool? value) {
                toggleWordSelection(word.id);
              },
            ) : null,
            title: Text(word.japanese),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showPronunciation)
                  Text(word.pronunciation),
                Text(word.meaning),
                if (word.category != null)
                  Text('分类: ${word.category}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () => ttsService.speak(word.japanese),
                ),
                if (!isSelectMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => showWordOptions(word),
                  ),
              ],
            ),
            onTap: isSelectMode 
              ? () => toggleWordSelection(word.id)
              : () => onWordTap(index),
          ),
        );
      },
    );
  }
} 