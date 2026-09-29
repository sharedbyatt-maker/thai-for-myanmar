import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/models/phrase.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  const phrase = Phrase(
    id: 'greet_hello',
    categoryId: 'greetings',
    thai: 'สวัสดีครับ / สวัสดีค่ะ',
    thaiMale: 'สวัสดีครับ',
    thaiFemale: 'สวัสดีค่ะ',
    myanmar: 'မင်္ဂလာပါ။',
    pronunciation: 'စဝတ်ဒီ',
    english: 'Hello.',
    keywords: [],
    tags: [],
  );

  group('ThaiPlaybackService', () {
    test(
      'plays exact male and female assets before asking system TTS',
      () async {
        final player = FakeThaiAudioAssetPlayer();
        final speechEngine = FakeSpeechEngine();
        final service = _service(
          player,
          speechEngine,
          _catalog(
            phrase,
            maleAsset: 'audio/thai/greet_hello_male.mp3',
            femaleAsset: 'audio/thai/greet_hello_female.mp3',
          ),
        );

        expect(
          await service.playThai(phrase, 'male'),
          ThaiPlaybackResult.audioAsset,
        );
        expect(
          await service.playThai(phrase, 'female'),
          ThaiPlaybackResult.audioAsset,
        );
        expect(player.paths, [
          'audio/thai/greet_hello_male.mp3',
          'audio/thai/greet_hello_female.mp3',
        ]);
        expect(speechEngine.spokenTexts, isEmpty);
      },
    );

    test(
      'missing mapping falls back to the selected Thai system voice',
      () async {
        final player = FakeThaiAudioAssetPlayer();
        final speechEngine = FakeSpeechEngine();
        final service = _service(
          player,
          speechEngine,
          ThaiAudioCatalog.empty(),
        );

        expect(
          await service.playThai(phrase, 'female'),
          ThaiPlaybackResult.spoken,
        );
        expect(player.paths, isEmpty);
        expect(speechEngine.spokenTexts, ['สวัสดีค่ะ']);
      },
    );

    test(
      'stale text is skipped rather than playing a mismatched asset',
      () async {
        final player = FakeThaiAudioAssetPlayer();
        final speechEngine = FakeSpeechEngine();
        final catalog = ThaiAudioCatalog.fromJson({
          'schemaVersion': 1,
          'entries': [
            {
              'phraseId': phrase.id,
              'form': 'male',
              'thai': 'สวัสดีครับครับ',
              'asset': 'audio/thai/greet_hello_stale.mp3',
            },
          ],
        });
        final service = _service(player, speechEngine, catalog);

        expect(
          await service.playThai(phrase, 'male'),
          ThaiPlaybackResult.spoken,
        );
        expect(player.paths, isEmpty);
        expect(speechEngine.spokenTexts, ['สวัสดีครับ']);
      },
    );

    test('playback errors use the safe Thai TTS fallback', () async {
      final player = FakeThaiAudioAssetPlayer(fail: true);
      final speechEngine = FakeSpeechEngine();
      final service = _service(
        player,
        speechEngine,
        _catalog(phrase, maleAsset: 'audio/thai/greet_hello_male.mp3'),
      );

      expect(await service.playThai(phrase, 'male'), ThaiPlaybackResult.spoken);
      expect(player.paths, ['audio/thai/greet_hello_male.mp3']);
      expect(speechEngine.spokenTexts, ['สวัสดีครับ']);
    });

    test('never uses an unrelated system voice when no audio exists', () async {
      final player = FakeThaiAudioAssetPlayer();
      final speechEngine = FakeSpeechEngine(
        voices: const [
          {'name': 'English voice', 'locale': 'en-US'},
          {'name': 'Spanish voice', 'locale': 'es-ES'},
        ],
      );
      final service = _service(player, speechEngine, ThaiAudioCatalog.empty());

      expect(
        await service.playThai(phrase, 'female'),
        ThaiPlaybackResult.unavailable,
      );
      expect(speechEngine.spokenTexts, isEmpty);
      expect(service.state, ThaiPlaybackState.unavailable);
    });

    test('a new request stops and replaces an active form', () async {
      final player = FakeThaiAudioAssetPlayer(waitForStop: true);
      final speechEngine = FakeSpeechEngine();
      final service = _service(
        player,
        speechEngine,
        _catalog(
          phrase,
          maleAsset: 'audio/thai/greet_hello_male.mp3',
          femaleAsset: 'audio/thai/greet_hello_female.mp3',
        ),
      );

      final first = service.playThai(phrase, 'male');
      await player.waitForPlayCount(1);
      expect(service.state, ThaiPlaybackState.playing);
      expect(service.isActiveFor(phrase.id, 'male'), isTrue);

      final second = service.playThai(phrase, 'female');
      expect(await first, ThaiPlaybackResult.cancelled);
      await player.waitForPlayCount(2);
      player.finishAll();

      expect(await second, ThaiPlaybackResult.audioAsset);
      expect(player.paths, [
        'audio/thai/greet_hello_male.mp3',
        'audio/thai/greet_hello_female.mp3',
      ]);
      expect(service.state, ThaiPlaybackState.idle);
    });

    test('stop cancels an in-progress playback request', () async {
      final player = FakeThaiAudioAssetPlayer(waitForStop: true);
      final service = _service(
        player,
        FakeSpeechEngine(),
        _catalog(phrase, maleAsset: 'audio/thai/greet_hello_male.mp3'),
      );

      final result = service.playThai(phrase, 'male');
      await player.waitForPlayCount(1);
      await service.stop();

      expect(await result, ThaiPlaybackResult.cancelled);
      expect(service.state, ThaiPlaybackState.idle);
    });
  });
}

ThaiAudioCatalog _catalog(
  Phrase phrase, {
  String? maleAsset,
  String? femaleAsset,
}) {
  final entries = <Map<String, String>>[];
  if (maleAsset != null) {
    entries.add({
      'phraseId': phrase.id,
      'form': 'male',
      'thai': phrase.thaiMale ?? phrase.thai,
      'asset': maleAsset,
    });
  }
  if (femaleAsset != null) {
    entries.add({
      'phraseId': phrase.id,
      'form': 'female',
      'thai': phrase.thaiFemale ?? phrase.thai,
      'asset': femaleAsset,
    });
  }
  return ThaiAudioCatalog.fromJson({'schemaVersion': 1, 'entries': entries});
}

ThaiPlaybackService _service(
  FakeThaiAudioAssetPlayer player,
  FakeSpeechEngine engine,
  ThaiAudioCatalog catalog,
) {
  return ThaiPlaybackService(
    speechService: SpeechService(
      engine: engine,
      voiceLookupWindow: Duration.zero,
      speechTimeout: const Duration(seconds: 1),
    ),
    catalog: catalog,
    assetPlayer: player,
  );
}

class FakeThaiAudioAssetPlayer implements ThaiAudioAssetPlayer {
  FakeThaiAudioAssetPlayer({this.fail = false, this.waitForStop = false});

  final bool fail;
  final bool waitForStop;
  final List<String> paths = [];
  final List<Completer<void>> _playSignals = [];
  final List<Completer<void>> _pending = [];
  int stopCalls = 0;

  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    paths.add(assetPath);
    final signal = Completer<void>();
    _playSignals.add(signal);
    signal.complete();
    onStarted();
    if (fail) throw StateError('simulated damaged asset');
    if (waitForStop) {
      final playback = Completer<void>();
      _pending.add(playback);
      await playback.future;
    }
  }

  Future<void> waitForPlayCount(int count) async {
    while (_playSignals.length < count) {
      await Future<void>.delayed(Duration.zero);
    }
    await _playSignals[count - 1].future;
  }

  void finishAll() {
    for (final playback in _pending) {
      if (!playback.isCompleted) playback.complete();
    }
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    finishAll();
  }

  @override
  Future<void> dispose() async {}
}

class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine({
    this.voices = const [
      {'name': 'Thai voice', 'locale': 'th-TH'},
    ],
  });

  final dynamic voices;
  final List<String> spokenTexts = [];
  void Function()? _startHandler;
  void Function()? _completionHandler;

  @override
  Future<dynamic> getVoices() async => voices;

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> speak(String text) async {
    spokenTexts.add(text);
    _startHandler?.call();
    _completionHandler?.call();
    return 1;
  }

  @override
  Future<dynamic> stop() async => 1;

  @override
  void setStartHandler(void Function() handler) => _startHandler = handler;

  @override
  void setCompletionHandler(void Function() handler) =>
      _completionHandler = handler;

  @override
  void setErrorHandler(void Function(dynamic error) handler) {}
}
