import 'package:hive/hive.dart';

part 'word.g.dart';

@HiveType(typeId: 0)
class Word extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  final String japanese;

  @HiveField(2)
  final String pronunciation;

  @HiveField(3)
  final String meaning;

  @HiveField(4)
  final String? category;

  @HiveField(5)
  bool _isNewWord;

  Word({
    this.id,
    required this.japanese,
    required this.pronunciation,
    required this.meaning,
    this.category,
    bool isNewWord = false,
  }) : _isNewWord = isNewWord;

  bool get isNewWord => _isNewWord;

  set isNewWord(bool value) {
    _isNewWord = value;
    save();
  }

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
      isNewWord: isNewWord ?? this._isNewWord,
    );
  }
} 