class AudioService {
  Future<void> playAudio(String url);
  Future<void> downloadAudio(String url);
  Future<bool> isAudioDownloaded(String url);
} 