import 'package:flutter/material.dart';
import '../models/word.dart';

class WordForm extends StatelessWidget {
  final TextEditingController japaneseController;
  final TextEditingController pronunciationController;
  final TextEditingController meaningController;
  final TextEditingController categoryController;

  const WordForm({
    super.key,
    required this.japaneseController,
    required this.pronunciationController,
    required this.meaningController,
    required this.categoryController,
  });

  // 工厂构造函数，用于编辑现有单词
  factory WordForm.fromWord(Word word) {
    return WordForm(
      japaneseController: TextEditingController(text: word.japanese),
      pronunciationController: TextEditingController(text: word.pronunciation),
      meaningController: TextEditingController(text: word.meaning),
      categoryController: TextEditingController(text: word.category),
    );
  }

  // 工厂构造函数，用于添加新单词
  factory WordForm.forNewWord() {
    return WordForm(
      japaneseController: TextEditingController(),
      pronunciationController: TextEditingController(),
      meaningController: TextEditingController(),
      categoryController: TextEditingController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: japaneseController,
          decoration: const InputDecoration(labelText: '日语'),
        ),
        TextField(
          controller: pronunciationController,
          decoration: const InputDecoration(labelText: '假名'),
        ),
        TextField(
          controller: meaningController,
          decoration: const InputDecoration(labelText: '含义'),
        ),
        TextField(
          controller: categoryController,
          decoration: const InputDecoration(labelText: '分类'),
        ),
      ],
    );
  }
} 