import 'package:audioplayers/audioplayers.dart';

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  void playReactSound() {
    _audioPlayer.play(AssetSource('sounds/react_pop.mp3'));
  }

  void playCommentSound() {
    _audioPlayer.play(AssetSource('sounds/comment_sent.mp3'));
  }

  void playRepostSound() {
    _audioPlayer.play(AssetSource('sounds/repost_chime.mp3'));
  }

  // Call this when the app is closing if needed
  void dispose() {
    _audioPlayer.dispose();
  }
}