import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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
    String? id,
    required this.japanese,
    required this.pronunciation,
    required this.meaning,
    this.isNewWord = false,
    this.category,
  }) : id = id ?? const Uuid().v4();

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as String,
      japanese: json['japanese'] as String,
      pronunciation: json['pronunciation'] as String,
      meaning: json['meaning'] as String,
      category: json['category'] as String?,
      isNewWord: json['is_new_word'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'japanese': japanese,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'category': category,
      'is_new_word': isNewWord,
    };
  }
} 