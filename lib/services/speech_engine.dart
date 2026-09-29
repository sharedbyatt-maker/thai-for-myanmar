abstract interface class SpeechEngine {
  Future<dynamic> getVoices();
  Future<dynamic> setLanguage(String language);
  Future<dynamic> setVoice(Map<String, String> voice);
  Future<dynamic> setSpeechRate(double rate);
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion);
  Future<dynamic> speak(String text);
  Future<dynamic> stop();
  void setStartHandler(void Function() handler);
  void setCompletionHandler(void Function() handler);
  void setErrorHandler(void Function(dynamic error) handler);
}

/// Optional capability for engines whose voice inventory changes asynchronously.
abstract interface class SpeechVoiceChangeAware {
  /// Waits for a voice-list change or returns when [timeout] elapses.
  Future<void> waitForVoicesChanged(
    Duration timeout, {
    Future<void>? cancelled,
  });
}

/// Optional, local-only details used by the hidden TTS diagnostics page.
abstract interface class SpeechEngineDiagnosticSource {
  Map<String, Object?> get diagnosticDetails;
}
