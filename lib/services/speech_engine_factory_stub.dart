import 'package:flutter_tts/flutter_tts.dart';

import 'speech_engine.dart';

SpeechEngine createPlatformSpeechEngine() => _FlutterTtsSpeechEngine();

class _FlutterTtsSpeechEngine implements SpeechEngine {
  _FlutterTtsSpeechEngine() : _tts = FlutterTts();

  final FlutterTts _tts;

  @override
  Future<dynamic> getVoices() => _tts.getVoices;

  @override
  Future<dynamic> setLanguage(String language) => _tts.setLanguage(language);

  @override
  Future<dynamic> setVoice(Map<String, String> voice) => _tts.setVoice(voice);

  @override
  Future<dynamic> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) =>
      _tts.awaitSpeakCompletion(awaitCompletion);

  @override
  Future<dynamic> speak(String text) => _tts.speak(text);

  @override
  Future<dynamic> stop() => _tts.stop();

  @override
  void setStartHandler(void Function() handler) {
    _tts.setStartHandler(handler);
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _tts.setCompletionHandler(handler);
  }

  @override
  void setErrorHandler(void Function(dynamic error) handler) {
    _tts.setErrorHandler(handler);
  }
}
