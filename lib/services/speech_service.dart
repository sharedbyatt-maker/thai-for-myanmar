import 'dart:async';

import 'speech_engine.dart';
import 'speech_engine_factory_stub.dart'
    if (dart.library.js_interop) 'speech_engine_factory_web.dart'
    as engine_factory;

export 'speech_engine.dart';

enum SpeechResult { spoken, unavailable, cancelled }

class SpeechService {
  SpeechService({
    SpeechEngine? engine,
    Duration? voiceLookupWindow,
    Duration speechTimeout = const Duration(seconds: 30),
  }) : _engine = engine ?? engine_factory.createPlatformSpeechEngine(),
       _speechTimeout = speechTimeout {
    _voiceLookupWindow =
        voiceLookupWindow ??
        (_engine is SpeechVoiceChangeAware
            ? const Duration(seconds: 3)
            : const Duration(milliseconds: 800));
  }

  static const _voicePollInterval = Duration(milliseconds: 100);

  final SpeechEngine _engine;
  final Duration _speechTimeout;
  late final Duration _voiceLookupWindow;
  Future<void> _queue = Future<void>.value();
  int _generation = 0;
  _SpeechCancellation? _activeCancellation;

  List<Map<String, String>> _lastVoices = const [];
  List<Map<String, String>> _lastThaiVoices = const [];
  Map<String, String>? _selectedThaiVoice;
  int? _initialVoiceCount;
  int _lastVoiceLookupMilliseconds = 0;
  bool _voiceListLoaded = false;
  String _lastFailureReason = 'not_tested';

  /// This snapshot is only shown by the explicit `?tts-debug=1` route.
  Map<String, Object?> get diagnosticSnapshot {
    final engineDetails = _engine is SpeechEngineDiagnosticSource
        ? _engine.diagnosticDetails
        : const <String, Object?>{};
    return {
      ...engineDetails,
      'voiceListLoaded': _voiceListLoaded,
      'initialVoiceCount': _initialVoiceCount,
      'voiceCount': _lastVoices.length,
      'thaiVoices': List<Map<String, String>>.unmodifiable(_lastThaiVoices),
      'selectedThaiVoice': _selectedThaiVoice,
      'voiceLookupMilliseconds': _lastVoiceLookupMilliseconds,
      'lastFailureReason': _lastFailureReason,
    };
  }

  /// Re-enumerates voices and waits only for the configured bounded window.
  Future<Map<String, Object?>> refreshDiagnostics() async {
    try {
      await _findThaiVoice(_SpeechCancellation());
    } catch (_) {
      _lastFailureReason = 'voice_lookup_failed';
    }
    return diagnosticSnapshot;
  }

  Future<SpeechResult> speakThai(String text, {void Function()? onStarted}) {
    final result = Completer<SpeechResult>();
    final generation = _generation;
    _queue = _queue.then((_) async {
      if (generation != _generation) {
        result.complete(SpeechResult.cancelled);
        return;
      }
      final cancellation = _SpeechCancellation();
      _activeCancellation = cancellation;
      try {
        result.complete(
          await _speakThaiNow(
            text,
            cancellation: cancellation,
            onStarted: onStarted,
          ),
        );
      } catch (_) {
        _lastFailureReason = 'speech_service_error';
        result.complete(SpeechResult.unavailable);
      } finally {
        if (identical(_activeCancellation, cancellation)) {
          _activeCancellation = null;
        }
      }
    });
    return result.future;
  }

  Future<SpeechResult> _speakThaiNow(
    String text, {
    required _SpeechCancellation cancellation,
    void Function()? onStarted,
  }) async {
    try {
      if (text.trim().isEmpty) return _unavailable('empty_text');

      final voice = await _findThaiVoice(cancellation);
      if (voice == null) {
        return _unavailable('no_thai_voice_after_bounded_wait');
      }

      final languageResult = await _waitOrCancel(
        _engine.setLanguage('th-TH').timeout(_speechTimeout),
        cancellation,
      );
      if (!_operationDidNotFail(languageResult)) {
        return _unavailable('language_request_rejected');
      }

      final voiceResult = await _waitOrCancel(
        _engine.setVoice(voice).timeout(_speechTimeout),
        cancellation,
      );
      if (!_operationDidNotFail(voiceResult)) {
        return _unavailable('thai_voice_selection_rejected');
      }

      final rateResult = await _waitOrCancel(
        _engine.setSpeechRate(0.43).timeout(_speechTimeout),
        cancellation,
      );
      if (!_operationDidNotFail(rateResult)) {
        return _unavailable('speech_rate_rejected');
      }
      await _waitOrCancel(
        _engine.awaitSpeakCompletion(false).timeout(_speechTimeout),
        cancellation,
      );

      var didStart = false;
      final outcome = Completer<SpeechResult>();
      _engine.setStartHandler(() {
        didStart = true;
        onStarted?.call();
      });
      _engine.setCompletionHandler(() {
        if (!outcome.isCompleted) {
          outcome.complete(
            didStart ? SpeechResult.spoken : SpeechResult.unavailable,
          );
        }
      });
      _engine.setErrorHandler((_) {
        _lastFailureReason = 'speech_error';
        if (!outcome.isCompleted) outcome.complete(SpeechResult.unavailable);
      });

      try {
        if (cancellation.isCancelled) throw const _SpeechCancelled();
        final speakResult = await _waitOrCancel(
          _engine.speak(text).timeout(_speechTimeout),
          cancellation,
        );
        if (_operationExplicitlyFailed(speakResult)) {
          return _unavailable('speech_dispatch_rejected');
        }
        final result = await _waitOrCancel(
          outcome.future.timeout(_speechTimeout),
          cancellation,
        );
        if (result == SpeechResult.spoken) {
          _lastFailureReason = 'speech_started_and_completed';
        } else if (_lastFailureReason != 'speech_error') {
          _lastFailureReason = 'speech_completed_without_start';
        }
        return result;
      } on _SpeechCancelled {
        rethrow;
      } on TimeoutException {
        try {
          await _engine.stop();
        } catch (_) {
          // Stop is best-effort after a missing start/completion callback.
        }
        return _unavailable(
          didStart ? 'speech_completion_timeout' : 'speech_start_timeout',
        );
      } catch (_) {
        return _unavailable('speech_dispatch_error');
      } finally {
        _engine.setStartHandler(() {});
        _engine.setCompletionHandler(() {});
        _engine.setErrorHandler((_) {});
      }
    } on _SpeechCancelled {
      _lastFailureReason = 'cancelled';
      return SpeechResult.cancelled;
    } on TimeoutException {
      return _unavailable('speech_setup_timeout');
    } catch (_) {
      return _unavailable('speech_setup_error');
    }
  }

  Future<Map<String, String>?> _findThaiVoice(
    _SpeechCancellation cancellation,
  ) async {
    final lookupWindow = _voiceLookupWindow.isNegative
        ? Duration.zero
        : _voiceLookupWindow;
    final stopwatch = Stopwatch()..start();
    _initialVoiceCount = null;
    _selectedThaiVoice = null;
    _lastThaiVoices = const [];
    _voiceListLoaded = false;

    try {
      while (true) {
        if (cancellation.isCancelled) throw const _SpeechCancelled();
        final voices = _voiceMaps(
          await _waitOrCancel(
            _engine.getVoices().timeout(_voiceReadTimeout),
            cancellation,
          ),
        );
        _voiceListLoaded = true;
        _initialVoiceCount ??= voices.length;
        _lastVoices = voices;

        final thaiVoices = voices.where(_isThaiVoice).toList();
        _lastThaiVoices = thaiVoices;
        if (thaiVoices.isNotEmpty) {
          thaiVoices.sort((a, b) {
            final aLocale = _normalizeLocale(a['locale']!);
            final bLocale = _normalizeLocale(b['locale']!);
            final localeOrder = _localeRank(
              aLocale,
            ).compareTo(_localeRank(bLocale));
            return localeOrder != 0
                ? localeOrder
                : a['name']!.compareTo(b['name']!);
          });
          _selectedThaiVoice = thaiVoices.first;
          _lastFailureReason = 'thai_voice_selected';
          return _selectedThaiVoice;
        }

        final remaining = lookupWindow - stopwatch.elapsed;
        if (remaining <= Duration.zero) break;

        if (_engine case final SpeechVoiceChangeAware eventAware) {
          try {
            await _waitOrCancel(
              eventAware
                  .waitForVoicesChanged(
                    remaining,
                    cancelled: cancellation.future,
                  )
                  .timeout(remaining + const Duration(milliseconds: 100)),
              cancellation,
            );
          } on TimeoutException {
            // The lookup window is bounded even if a platform event is lost.
          }
        } else {
          await _waitOrCancel(
            Future<void>.delayed(
              remaining < _voicePollInterval ? remaining : _voicePollInterval,
            ),
            cancellation,
          );
        }
      }
      _lastFailureReason = 'no_thai_voice_after_bounded_wait';
      return null;
    } finally {
      _lastVoiceLookupMilliseconds = stopwatch.elapsedMilliseconds;
    }
  }

  Duration get _voiceReadTimeout {
    final boundedLookup = _voiceLookupWindow + const Duration(seconds: 1);
    return boundedLookup < _speechTimeout ? boundedLookup : _speechTimeout;
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

  bool _isThaiVoice(Map<String, String> voice) =>
      _isThaiLocale(voice['locale']!);

  bool _isThaiLocale(String locale) {
    final parts = _normalizeLocale(locale).split('-');
    return parts.isNotEmpty &&
        parts.first == 'th' &&
        parts.every((part) => RegExp(r'^[a-z0-9]{1,8}$').hasMatch(part));
  }

  String _normalizeLocale(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();

  int _localeRank(String locale) {
    if (locale == 'th-th') return 0;
    if (locale == 'th') return 2;
    return 1;
  }

  bool _operationDidNotFail(Object? result) {
    if (result == null || result == true) return true;
    return result is num && result > 0;
  }

  bool _operationExplicitlyFailed(Object? result) {
    if (result == false) return true;
    return result is num && result <= 0;
  }

  SpeechResult _unavailable(String reason) {
    _lastFailureReason = reason;
    return SpeechResult.unavailable;
  }

  Future<void> stop() async {
    _generation++;
    _activeCancellation?.cancel();
    try {
      await _engine.stop();
    } catch (_) {
      // Stopping is best-effort when a platform voice is missing.
    }
  }

  Future<T> _waitOrCancel<T>(
    Future<T> operation,
    _SpeechCancellation cancellation,
  ) {
    if (cancellation.isCancelled) {
      return Future<T>.error(const _SpeechCancelled());
    }
    return Future.any<T>([
      operation,
      cancellation.future.then<T>((_) => throw const _SpeechCancelled()),
    ]);
  }
}

class _SpeechCancellation {
  final _completer = Completer<void>();

  Future<void> get future => _completer.future;
  bool get isCancelled => _completer.isCompleted;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

class _SpeechCancelled implements Exception {
  const _SpeechCancelled();
}
