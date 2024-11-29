class DatabaseService {
  // 使用 Hive 或 SQLite 存储本地数据
  Future<void> saveWord(Word word);
  Future<List<Word>> getDueWords();
  Future<void> updateReviewStatus(String wordId, bool isCorrect);
  Future<List<Word>> getFavoriteWords();
} 