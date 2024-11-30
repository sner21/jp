import 'package:hive/hive.dart';

part 'word.g.dart';

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String japanese;

  @HiveField(2)
  String pronunciation;

  @HiveField(3)
  String meaning;

  @HiveField(4)
  String? category;

  @HiveField(5)
  bool isNewWord;

  Word({
    required this.id,
    required this.japanese,
    required this.pronunciation,
    required this.meaning,
    this.category,
    this.isNewWord = true,
  });

  Word copyWith({
    String? id,
    String? japanese,
    String? pronunciation,
    String? meaning,
    String? category,
    bool? isNewWord,
  }) {
    return Word(
      id: id ?? this.id,
      japanese: japanese ?? this.japanese,
      pronunciation: pronunciation ?? this.pronunciation,
      meaning: meaning ?? this.meaning,
      category: category ?? this.category,
      isNewWord: isNewWord ?? this.isNewWord,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'japanese': japanese,
      'pronunciation': pronunciation,
      'meaning': meaning,
      'category': category,
    };
  }
} 