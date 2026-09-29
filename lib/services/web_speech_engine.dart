import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'speech_engine.dart';

/// Uses the browser's real Web Speech API and keeps the selected Thai voice
/// attached to each utterance instead of relying on the browser default.
class WebSpeechEngine
    implements
        SpeechEngine,
        SpeechVoiceChangeAware,
        SpeechEngineDiagnosticSource {
  web.SpeechSynthesis? get _synthesis {
    try {
      return web.window.speechSynthesis;
    } catch (_) {
      return null;
    }
  }

  void Function() _startHandler = () {};
  void Function() _completionHandler = () {};
  void Function(dynamic error) _errorHandler = (_) {};
  web.SpeechSynthesisVoice? _selectedVoice;
  double _rate = 1;
  String? _lastVoiceSignature;
  int _voicesChangedEvents = 0;
  String _lastError = '';

  @override
  Map<String, Object?> get diagnosticDetails {
    String userAgent = '';
    String platform = '';
    try {
      userAgent = web.window.navigator.userAgent;
      platform = web.window.navigator.platform;
    } catch (_) {
      // Diagnostics are best-effort and never affect playback.
    }
    final browser = _browserName(userAgent);
    return {
      'browser': browser,
      'userAgent': userAgent,
      'platform': platform,
      'speechSynthesisAvailable': _synthesis != null,
      'voicesChangedEvents': _voicesChangedEvents,
      'engineError': _lastError,
    };
  }

  @override
  Future<dynamic> getVoices() async {
    final voices = _readVoices();
    final voiceData = voices
        .map((voice) => {'name': voice.name, 'locale': voice.lang})
        .toList(growable: false);
    _lastVoiceSignature = _signature(voiceData);
    return voiceData;
  }

  List<web.SpeechSynthesisVoice> _readVoices() {
    try {
      return _synthesis?.getVoices().toDart ?? const [];
    } catch (_) {
      _lastError = 'voice_list_error';
      return const [];
    }
  }

  @override
  Future<void> waitForVoicesChanged(
    Duration timeout, {
    Future<void>? cancelled,
  }) async {
    final synthesis = _synthesis;
    if (timeout <= Duration.zero) return;
    if (synthesis == null) {
      await _waitForTimeoutOrCancel(timeout, cancelled);
      return;
    }

    final completed = Completer<void>();
    final listener = ((web.Event _) {
      _voicesChangedEvents++;
      final voiceData = _readVoices()
          .map((voice) => {'name': voice.name, 'locale': voice.lang})
          .toList(growable: false);
      _lastVoiceSignature = _signature(voiceData);
      if (!completed.isCompleted) completed.complete();
    }).toJS;

    try {
      synthesis.addEventListener('voiceschanged', listener);

      // Close the small race where voices change after getVoices() but before
      // this listener is registered.
      final currentSignature = _signature(
        _readVoices()
            .map((voice) => {'name': voice.name, 'locale': voice.lang})
            .toList(growable: false),
      );
      if (_lastVoiceSignature != null &&
          currentSignature != _lastVoiceSignature &&
          !completed.isCompleted) {
        completed.complete();
      }
      unawaited(
        cancelled?.then((_) {
          if (!completed.isCompleted) completed.complete();
        }),
      );

      Timer? timer;
      try {
        timer = Timer(timeout, () {
          if (!completed.isCompleted) completed.complete();
        });
        await completed.future;
      } finally {
        timer?.cancel();
      }
    } catch (_) {
      _lastError = 'voiceschanged_wait_error';
      await _waitForTimeoutOrCancel(timeout, cancelled);
    } finally {
      try {
        synthesis.removeEventListener('voiceschanged', listener);
      } catch (_) {
        // Removing a listener is best-effort when the API is partial.
      }
    }
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    if (!_isThaiLocale(language)) return 0;
    final hasThaiVoice = _readVoices().any(
      (voice) => _isThaiLocale(voice.lang),
    );
    return hasThaiVoice ? 1 : 0;
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    final name = voice['name'];
    final locale = voice['locale'];
    if (name == null || locale == null || !_isThaiLocale(locale)) return 0;

    for (final available in _readVoices()) {
      if (available.name == name &&
          _normalizeLocale(available.lang) == _normalizeLocale(locale) &&
          _isThaiLocale(available.lang)) {
        _selectedVoice = available;
        return 1;
      }
    }
    _selectedVoice = null;
    return 0;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    if (!rate.isFinite || rate <= 0) return 0;
    _rate = rate;
    return 1;
  }

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> speak(String text) async {
    final synthesis = _synthesis;
    final selected = _selectedVoice;
    if (synthesis == null ||
        selected == null ||
        !_isThaiLocale(selected.lang)) {
      return 0;
    }

    final currentVoice = _readVoices().where(
      (voice) =>
          voice.name == selected.name &&
          _normalizeLocale(voice.lang) == _normalizeLocale(selected.lang) &&
          _isThaiLocale(voice.lang),
    );
    if (currentVoice.isEmpty) {
      _selectedVoice = null;
      return 0;
    }

    try {
      final utterance = web.SpeechSynthesisUtterance(text)
        ..voice = currentVoice.first
        ..lang = currentVoice.first.lang
        ..rate = _rate
        ..onstart = ((web.Event _) => _startHandler()).toJS
        ..onend = ((web.Event _) => _completionHandler()).toJS
        ..onerror = ((web.Event _) {
          _lastError = 'speech_error_event';
          _errorHandler(_lastError);
        }).toJS;
      synthesis.speak(utterance);
      return 1;
    } catch (_) {
      _lastError = 'speech_dispatch_error';
      return 0;
    }
  }

  @override
  Future<dynamic> stop() async {
    try {
      _synthesis?.cancel();
      return 1;
    } catch (_) {
      return 0;
    }
  }

  @override
  void setStartHandler(void Function() handler) {
    _startHandler = handler;
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _completionHandler = handler;
  }

  @override
  void setErrorHandler(void Function(dynamic error) handler) {
    _errorHandler = handler;
  }

  static String _normalizeLocale(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();

  static bool _isThaiLocale(String locale) {
    final parts = _normalizeLocale(locale).split('-');
    return parts.isNotEmpty &&
        parts.first == 'th' &&
        parts.every((part) => RegExp(r'^[a-z0-9]{1,8}$').hasMatch(part));
  }

  static String _signature(List<Map<String, String>> voices) => voices
      .map((voice) => '${voice['name']}\u0000${voice['locale']}')
      .join('\u0001');

  static Future<void> _waitForTimeoutOrCancel(
    Duration timeout,
    Future<void>? cancelled,
  ) async {
    final waits = <Future<void>>[Future<void>.delayed(timeout)];
    if (cancelled != null) waits.add(cancelled);
    await Future.any(waits);
  }

  static String _browserName(String userAgent) {
    if (userAgent.contains('Edg/')) return 'Edge';
    if (userAgent.contains('Firefox/')) return 'Firefox';
    if (userAgent.contains('Chrome/')) return 'Chrome';
    if (userAgent.contains('Safari/')) return 'Safari';
    return userAgent.isEmpty ? 'Unknown' : 'Other';
  }
}
