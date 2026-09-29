import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

enum SpeechResult { spoken, unavailable }

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

class SpeechService {
  SpeechService({
    SpeechEngine? engine,
    Duration voiceLookupWindow = const Duration(milliseconds: 800),
    Duration speechTimeout = const Duration(seconds: 30),
  }) : _engine = engine ?? _FlutterTtsSpeechEngine(),
       _voiceLookupWindow = voiceLookupWindow,
       _speechTimeout = speechTimeout;

  final SpeechEngine _engine;
  final Duration _voiceLookupWindow;
  final Duration _speechTimeout;
  Future<void> _queue = Future<void>.value();

  Future<SpeechResult> speakThai(String text) {
    final result = Completer<SpeechResult>();
    _queue = _queue.then((_) async {
      try {
        result.complete(await _speakThaiNow(text));
      } catch (_) {
        result.complete(SpeechResult.unavailable);
      }
    });
    return result.future;
  }

  Future<SpeechResult> _speakThaiNow(String text) async {
    if (text.trim().isEmpty) return SpeechResult.unavailable;

    final voice = await _findThaiVoice();
    if (voice == null) return SpeechResult.unavailable;

    final languageResult = await _engine.setLanguage('th-TH');
    if (!_operationDidNotFail(languageResult)) {
      return SpeechResult.unavailable;
    }

    final voiceResult = await _engine.setVoice(voice);
    if (!_operationDidNotFail(voiceResult)) {
      return SpeechResult.unavailable;
    }

    await _engine.setSpeechRate(0.43);
    // On Web, flutter_tts returns null as soon as the utterance is queued when
    // completion waiting is disabled. We use its start/end/error callbacks
    // instead of treating that queue acknowledgement as proof of speech.
    await _engine.awaitSpeakCompletion(false);

    var didStart = false;
    final outcome = Completer<SpeechResult>();
    _engine.setStartHandler(() {
      didStart = true;
    });
    _engine.setCompletionHandler(() {
      if (!outcome.isCompleted) {
        outcome.complete(
          didStart ? SpeechResult.spoken : SpeechResult.unavailable,
        );
      }
    });
    _engine.setErrorHandler((_) {
      if (!outcome.isCompleted) {
        outcome.complete(SpeechResult.unavailable);
      }
    });

    try {
      final speakResult = await _engine.speak(text);
      if (_operationExplicitlyFailed(speakResult)) {
        return SpeechResult.unavailable;
      }
      return await outcome.future.timeout(_speechTimeout);
    } on TimeoutException {
      try {
        await _engine.stop();
      } catch (_) {
        // Stop is best-effort after a missing start/completion callback.
      }
      return SpeechResult.unavailable;
    } finally {
      _engine.setStartHandler(() {});
      _engine.setCompletionHandler(() {});
      _engine.setErrorHandler((_) {});
    }
  }

  Future<Map<String, String>?> _findThaiVoice() async {
    final lookupWindow = _voiceLookupWindow.isNegative
        ? Duration.zero
        : _voiceLookupWindow;
    final attempts = lookupWindow.inMilliseconds ~/ 100 + 1;

    for (var attempt = 0; attempt < attempts; attempt++) {
      final voices = _voiceMaps(await _engine.getVoices());
      final thaiVoices = voices.where(_isThaiVoice).toList();
      if (thaiVoices.isNotEmpty) {
        thaiVoices.sort((a, b) {
          final aLocale = _normalizeLocale(a['locale']!);
          final bLocale = _normalizeLocale(b['locale']!);
          final localeOrder = _localeRank(aLocale).compareTo(
            _localeRank(bLocale),
          );
          return localeOrder != 0
              ? localeOrder
              : a['name']!.compareTo(b['name']!);
        });
        return thaiVoices.first;
      }

      if (attempt + 1 < attempts) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    return null;
  }

  List<Map<String, String>> _voiceMaps(dynamic rawVoices) {
    if (rawVoices is! Iterable) return const [];
    final voices = <Map<String, String>>[];
    for (final rawVoice in rawVoices) {
      if (rawVoice is! Map) continue;
      final name = rawVoice['name']?.toString().trim() ?? '';
      final locale = rawVoice['locale']?.toString().trim() ?? '';
      if (name.isEmpty || locale.isEmpty) continue;
      voices.add({'name': name, 'locale': locale});
    }
    return voices;
  }

  bool _isThaiVoice(Map<String, String> voice) {
    final locale = _normalizeLocale(voice['locale']!);
    return locale == 'th' || locale == 'th-th' || locale.startsWith('th-th-');
  }

  String _normalizeLocale(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();

  int _localeRank(String locale) => locale == 'th-th' ? 0 : 1;

  bool _operationDidNotFail(Object? result) {
    if (result == null || result == true) return true;
    return result is num && result > 0;
  }

  bool _operationExplicitlyFailed(Object? result) {
    if (result == false) return true;
    return result is num && result <= 0;
  }

  Future<void> stop() async {
    try {
      await _engine.stop();
    } catch (_) {
      // Stopping audio is best-effort when a platform voice is missing.
    }
  }
}

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
