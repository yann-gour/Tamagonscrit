import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  /// Joue un fichier sonore d'asset pour un succès.
  /// [soundPath] peut être au format 'ecole.mp3' ou 'assets/ecole.mp3'.
  static Future<void> playAchievementSound(String soundPath) async {
    try {
      final cleanPath = soundPath.replaceFirst('assets/', '');
      await _player.stop();
      await _player.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('Erreur lors de la lecture du son ($soundPath): $e');
    }
  }
}
