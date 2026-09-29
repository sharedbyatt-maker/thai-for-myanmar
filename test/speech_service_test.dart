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
    this.languageResult = 1,
    this.voiceResult = 1,
    this.speakResult = 1,
    this.emitStart = true,
    this.emitCompletion = true,
    this.emitError = false,
  });

  final dynamic voices;
  final dynamic languageResult;
  final dynamic voiceResult;
  final dynamic speakResult;
  final bool emitStart;
  final bool emitCompletion;
  final bool emitError;

  final languageRequests = <String>[];
  final selectedVoices = <Map<String, String>>[];
  final speechRates = <double>[];
  final awaitCompletionRequests = <bool>[];
  final spokenTexts = <String>[];
  void Function()? _startHandler;
  void Function()? _completionHandler;
  void Function(dynamic error)? _errorHandler;

  @override
  Future<dynamic> getVoices() async => voices;

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
    if (emitStart) _startHandler?.call();
    if (emitError) {
      _errorHandler?.call(StateError('TTS error'));
    } else if (emitCompletion) {
      _completionHandler?.call();
    }
    return speakResult;
  }

  @override
  Future<dynamic> stop() async => 1;

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
