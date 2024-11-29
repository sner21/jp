import 'package:flutter/material.dart';
import '../models/word.dart';

class AddWordDialog extends StatefulWidget {
  final Word? initialWord;

  const AddWordDialog({super.key, this.initialWord});

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _japaneseController;
  late TextEditingController _pronunciationController;
  late TextEditingController _meaningController;
  late TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    _japaneseController = TextEditingController(text: widget.initialWord?.japanese);
    _pronunciationController = TextEditingController(text: widget.initialWord?.pronunciation);
    _meaningController = TextEditingController(text: widget.initialWord?.meaning);
    _categoryController = TextEditingController(text: widget.initialWord?.category);
  }

  @override
  void dispose() {
    _japaneseController.dispose();
    _pronunciationController.dispose();
    _meaningController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialWord == null ? '添加单词' : '编辑单词'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _japaneseController,
                decoration: const InputDecoration(
                  labelText: '日语（汉字）',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入日语';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _pronunciationController,
                decoration: const InputDecoration(
                  labelText: '假名',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入假名';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  labelText: '中文含义',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入含义';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: '分类（可选）',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final word = Word(
                id: widget.initialWord?.id,
                japanese: _japaneseController.text,
                pronunciation: _pronunciationController.text,
                meaning: _meaningController.text,
                category: _categoryController.text.isEmpty 
                    ? null 
                    : _categoryController.text,
              );
              Navigator.of(context).pop(word);
            }
          },
          child: Text(widget.initialWord == null ? '添加' : '保存'),
        ),
      ],
    );
  }
} 