import 'package:flutter_tts/flutter_tts.dart';

enum SpeechResult { spoken, unavailable }

class SpeechService {
  SpeechService({FlutterTts? engine}) : _engine = engine ?? FlutterTts();

  final FlutterTts _engine;

  Future<SpeechResult> speakThai(String text) async {
    try {
      await _engine.setLanguage('th-TH');
      await _engine.setSpeechRate(0.43);
      await _engine.awaitSpeakCompletion(true);
      final result = await _engine.speak(text);
      if (result == 0 || result == true || result == null) {
        return SpeechResult.spoken;
      }
      return SpeechResult.unavailable;
    } catch (_) {
      return SpeechResult.unavailable;
    }
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Stopping audio is best-effort when a platform voice is missing.
    }
  }
}
