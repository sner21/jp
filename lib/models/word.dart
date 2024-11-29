import 'package:hive/hive.dart';

part 'word.g.dart';

@HiveType(typeId: 0)
class Word {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String japanese;

  @HiveField(2)
  final String pronunciation;

  @HiveField(3)
  final String meaning;

  @HiveField(4)
  bool isNewWord;

  @HiveField(5)
  String? category;

  Word({
    required this.id,
    required this.japanese,
    required this.pronunciation,
    required this.meaning,
    this.isNewWord = false,
    this.category,
  });
} 