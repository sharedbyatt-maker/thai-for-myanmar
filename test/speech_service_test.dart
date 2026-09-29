import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpeechService', () {
    test(
      'missing platform TTS plugin returns a safe unavailable result',
      () async {
        final service = SpeechService(voiceLookupWindow: Duration.zero);
        expect(await service.speakThai('สวัสดี'), SpeechResult.unavailable);
      },
    );

    test(
      'rejects unrelated voices instead of using a default fallback',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'English voice', 'locale': 'en-US'},
            {'name': 'Spanish voice', 'locale': 'es-ES'},
          ],
        );

        final result = await _service(engine).speakThai('สวัสดี');

        expect(result, SpeechResult.unavailable);
        expect(engine.languageRequests, isEmpty);
        expect(engine.selectedVoices, isEmpty);
        expect(engine.spokenTexts, isEmpty);
      },
    );

    test(
      'selects a Thai voice explicitly and reports only completed speech',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'Thai generic', 'locale': 'th'},
            {'name': 'Thai Thailand', 'locale': 'th-TH'},
            {'name': 'Spanish voice', 'locale': 'es-ES'},
          ],
          voiceResult: null,
        );

        final result = await _service(engine).speakThai('สวัสดีค่ะ');

        expect(result, SpeechResult.spoken);
        expect(engine.languageRequests, ['th-TH']);
        expect(engine.selectedVoices, [
          {'name': 'Thai Thailand', 'locale': 'th-TH'},
        ]);
        expect(engine.speechRates, [0.43]);
        expect(engine.awaitCompletionRequests, [false]);
        expect(engine.spokenTexts, ['สวัสดีค่ะ']);
      },
    );

    test('reports the start of verified Thai speech to playback UI', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai voice', 'locale': 'th-TH'},
        ],
      );
      var starts = 0;

      final result = await _service(engine)
          .speakThai('สวัสดีค่ะ', onStarted: () => starts++);

      expect(result, SpeechResult.spoken);
      expect(starts, 1);
    });

    test(
      'accepts a Thai-only locale when the platform omits the region',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'Thai voice', 'locale': 'th'},
          ],
        );

        expect(await _service(engine).speakThai('ครับ'), SpeechResult.spoken);
        expect(engine.selectedVoices.single['locale'], 'th');
      },
    );

    test('normalizes locale case and underscores before matching', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai voice', 'locale': 'TH_th'},
        ],
      );

      expect(await _service(engine).speakThai('สวัสดี'), SpeechResult.spoken);
      expect(engine.selectedVoices.single['locale'], 'TH_th');
    });

    test(
      'accepts genuine Thai region variants but rejects lookalikes',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'English with Thai region', 'locale': 'en-TH'},
            {'name': 'Not Thai', 'locale': 'thx-TH'},
            {'name': 'Thai Singapore', 'locale': 'th-SG'},
          ],
        );

        expect(await _service(engine).speakThai('สวัสดี'), SpeechResult.spoken);
        expect(engine.selectedVoices.single['name'], 'Thai Singapore');
      },
    );

    test('prefers th-TH, then another Thai variant, then bare th', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai base', 'locale': 'th'},
          {'name': 'Thai other region', 'locale': 'th-SG'},
          {'name': 'Thai Thailand', 'locale': 'th-TH'},
        ],
      );

      expect(await _service(engine).speakThai('สวัสดี'), SpeechResult.spoken);
      expect(engine.selectedVoices.single['name'], 'Thai Thailand');
    });

    test(
      'uses another th-* voice ahead of the Thai base-language voice',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'Thai base', 'locale': 'th'},
            {'name': 'Thai Singapore', 'locale': 'th-SG'},
          ],
        );

        expect(await _service(engine).speakThai('สวัสดี'), SpeechResult.spoken);
        expect(engine.selectedVoices.single['name'], 'Thai Singapore');
      },
    );

    test('waits for a late Thai voice after voiceschanged', () async {
      final engine = EventAwareFakeSpeechEngine(voices: const []);
      engine.onVoiceChange = (_, __) async {
        engine.voices = const [
          {'name': 'Late Thai voice', 'locale': 'th-TH'},
        ];
      };
      final service = SpeechService(
        engine: engine,
        voiceLookupWindow: const Duration(milliseconds: 100),
        speechTimeout: const Duration(milliseconds: 200),
      );

      expect(await service.speakThai('สวัสดี'), SpeechResult.spoken);
      expect(engine.voiceChangeWaits, 1);
      expect(engine.selectedVoices.single['name'], 'Late Thai voice');
      expect(service.diagnosticSnapshot['initialVoiceCount'], 0);
      expect(service.diagnosticSnapshot['voiceCount'], 1);
    });

    test(
      'bounds waiting when no Thai voice arrives after voiceschanged',
      () async {
        final engine = EventAwareFakeSpeechEngine(voices: const []);
        engine.onVoiceChange = (timeout, _) async {
          await Future<void>.delayed(timeout);
        };
        final service = SpeechService(
          engine: engine,
          voiceLookupWindow: const Duration(milliseconds: 20),
          speechTimeout: const Duration(milliseconds: 100),
        );
        final stopwatch = Stopwatch()..start();

        expect(await service.speakThai('สวัสดี'), SpeechResult.unavailable);
        expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 250)));
        expect(engine.voiceChangeWaits, 1);
        expect(engine.languageRequests, isEmpty);
        expect(
          service.diagnosticSnapshot['lastFailureReason'],
          'no_thai_voice_after_bounded_wait',
        );
      },
    );

    test('rechecks voices while polling a non-event-aware platform', () async {
      final engine = FakeSpeechEngine(
        voices: const [],
        voiceResponses: const [
          [],
          [
            {'name': 'Late Thai voice', 'locale': 'th-TH'},
          ],
        ],
      );
      final service = SpeechService(
        engine: engine,
        voiceLookupWindow: const Duration(milliseconds: 250),
        speechTimeout: const Duration(milliseconds: 300),
      );

      expect(await service.speakThai('สวัสดี'), SpeechResult.spoken);
      expect(engine.voiceReads, greaterThanOrEqualTo(2));
      expect(engine.selectedVoices.single['name'], 'Late Thai voice');
    });

    test(
      'serializes repeated Play requests without losing either phrase',
      () async {
        final engine = FakeSpeechEngine();
        final service = _service(engine);

        final first = service.speakThai('สวัสดีค่ะ');
        final second = service.speakThai('ขอบคุณค่ะ');

        expect(await first, SpeechResult.spoken);
        expect(await second, SpeechResult.spoken);
        expect(engine.spokenTexts, ['สวัสดีค่ะ', 'ขอบคุณค่ะ']);
      },
    );

    test('does not speak when setLanguage reports failure', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai voice', 'locale': 'th-TH'},
        ],
        languageResult: 0,
      );

      expect(
        await _service(engine).speakThai('สวัสดี'),
        SpeechResult.unavailable,
      );
      expect(engine.selectedVoices, isEmpty);
      expect(engine.spokenTexts, isEmpty);
    });

    test(
      'does not speak when the platform rejects explicit voice selection',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'Thai voice', 'locale': 'th-TH'},
          ],
          voiceResult: 0,
        );

        expect(
          await _service(engine).speakThai('สวัสดี'),
          SpeechResult.unavailable,
        );
        expect(engine.spokenTexts, isEmpty);
      },
    );

    test('times out a hung speech dispatch', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai voice', 'locale': 'th-TH'},
        ],
        hangSpeakCall: true,
        emitStart: false,
        emitCompletion: false,
      );

      expect(
        await _service(
          engine,
          speechTimeout: const Duration(milliseconds: 5),
        ).speakThai('สวัสดี'),
        SpeechResult.unavailable,
      );
    });

    test(
      'Stop cancels a pending voice wait before any utterance is queued',
      () async {
        final engine = EventAwareFakeSpeechEngine(voices: const []);
        engine.onVoiceChange = (timeout, cancelled) async {
          final signal = cancelled ?? Completer<void>().future;
          await Future.any<void>([Future<void>.delayed(timeout), signal]);
        };
        final service = SpeechService(
          engine: engine,
          voiceLookupWindow: const Duration(seconds: 2),
          speechTimeout: const Duration(seconds: 3),
        );
        final pending = service.speakThai('สวัสดี');
        while (engine.voiceChangeWaits == 0) {
          await Future<void>.delayed(Duration.zero);
        }

        await service.stop();

        expect(await pending, SpeechResult.cancelled);
        expect(engine.spokenTexts, isEmpty);
        expect(engine.languageRequests, isEmpty);
      },
    );

    test('Stop cancels an active utterance immediately', () async {
      final engine = FakeSpeechEngine(emitCompletion: false);
      final service = _service(
        engine,
        speechTimeout: const Duration(seconds: 1),
      );
      final pending = service.speakThai('สวัสดี');
      while (engine.spokenTexts.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }

      await service.stop();

      expect(await pending, SpeechResult.cancelled);
      expect(engine.stopCalls, 1);
    });

    test(
      'a null browser queue result is not success without speech callbacks',
      () async {
        final engine = FakeSpeechEngine(
          voices: const [
            {'name': 'Thai voice', 'locale': 'th-TH'},
          ],
          speakResult: null,
          emitStart: false,
          emitCompletion: false,
        );

        expect(
          await _service(
            engine,
            speechTimeout: const Duration(milliseconds: 5),
          ).speakThai('สวัสดี'),
          SpeechResult.unavailable,
        );
      },
    );

    test('speech engine errors return unavailable', () async {
      final engine = FakeSpeechEngine(
        voices: const [
          {'name': 'Thai voice', 'locale': 'th-TH'},
        ],
        emitError: true,
      );

      expect(
        await _service(engine).speakThai('สวัสดี'),
        SpeechResult.unavailable,
      );
    });

    test('empty text does not invoke the speech engine', () async {
      final engine = FakeSpeechEngine();

      expect(await _service(engine).speakThai('  '), SpeechResult.unavailable);
      expect(engine.spokenTexts, isEmpty);
    });
  });
}

SpeechService _service(
  FakeSpeechEngine engine, {
  Duration speechTimeout = const Duration(seconds: 1),
}) {
  return SpeechService(
    engine: engine,
    voiceLookupWindow: Duration.zero,
    speechTimeout: speechTimeout,
  );
}

class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine({
    this.voices = const [
      {'name': 'Thai voice', 'locale': 'th-TH'},
    ],
    this.voiceResponses,
    this.languageResult = 1,
    this.voiceResult = 1,
    this.speakResult = 1,
    this.emitStart = true,
    this.emitCompletion = true,
    this.emitError = false,
    this.hangSpeakCall = false,
  });

  dynamic voices;
  final List<dynamic>? voiceResponses;
  final dynamic languageResult;
  final dynamic voiceResult;
  final dynamic speakResult;
  final bool emitStart;
  final bool emitCompletion;
  final bool emitError;
  final bool hangSpeakCall;

  final languageRequests = <String>[];
  final selectedVoices = <Map<String, String>>[];
  final speechRates = <double>[];
  final awaitCompletionRequests = <bool>[];
  final spokenTexts = <String>[];
  int stopCalls = 0;
  int voiceReads = 0;
  void Function()? _startHandler;
  void Function()? _completionHandler;
  void Function(dynamic error)? _errorHandler;

  @override
  Future<dynamic> getVoices() async {
    final responses = voiceResponses;
    final index = voiceReads++;
    if (responses == null || responses.isEmpty) return voices;
    return responses[index < responses.length ? index : responses.length - 1];
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    languageRequests.add(language);
    return languageResult;
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    selectedVoices.add(Map<String, String>.from(voice));
    return voiceResult;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async {
    speechRates.add(rate);
    return 1;
  }

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async {
    awaitCompletionRequests.add(awaitCompletion);
    return 1;
  }

  @override
  Future<dynamic> speak(String text) async {
    spokenTexts.add(text);
    if (hangSpeakCall) return Completer<dynamic>().future;
    if (emitStart) _startHandler?.call();
    if (emitError) {
      _errorHandler?.call(StateError('TTS error'));
    } else if (emitCompletion) {
      _completionHandler?.call();
    }
    return speakResult;
  }

  @override
  Future<dynamic> stop() async {
    stopCalls++;
    return 1;
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
}

class EventAwareFakeSpeechEngine extends FakeSpeechEngine
    implements SpeechVoiceChangeAware {
  EventAwareFakeSpeechEngine({super.voices});

  int voiceChangeWaits = 0;
  Future<void> Function(Duration timeout, Future<void>? cancelled)?
  onVoiceChange;

  @override
  Future<void> waitForVoicesChanged(
    Duration timeout, {
    Future<void>? cancelled,
  }) async {
    voiceChangeWaits++;
    await onVoiceChange?.call(timeout, cancelled);
  }
}
