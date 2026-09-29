import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/models/phrase.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';
import 'package:thai_for_myanmar/widgets/thai_playback_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button shows loading and playing states and can stop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final appState = AppState();
    await appState.load();
    final player = WaitingThaiAssetPlayer();
    final playbackService = ThaiPlaybackService(
      speechService: SpeechService(
        engine: NoopSpeechEngine(),
        voiceLookupWindow: Duration.zero,
      ),
      catalog: _catalog(),
      assetPlayer: player,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ThaiPlaybackButton(
              phrase: _phrase,
              appState: appState,
              playbackService: playbackService,
              label: 'အသံထွက်',
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('အသံထွက်'));
    await tester.pump();
    expect(find.text('ဖွင့်နေသည်'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    player.releaseInitialStop();
    await tester.pump();
    await tester.pump();
    expect(find.text('အသံရပ်ရန်'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.tap(find.text('အသံရပ်ရန်'));
    await tester.pumpAndSettle();
    expect(find.text('အသံထွက်'), findsOneWidget);
    expect(playbackService.state, ThaiPlaybackState.idle);
    expect(tester.takeException(), isNull);
  });
}

const _phrase = Phrase(
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

ThaiAudioCatalog _catalog() => ThaiAudioCatalog.fromJson({
  'schemaVersion': 1,
  'entries': [
    {
      'phraseId': _phrase.id,
      'form': 'female',
      'thai': _phrase.thaiFemale,
      'asset': 'audio/thai/greet_hello_female.mp3',
    },
  ],
});

class WaitingThaiAssetPlayer implements ThaiAudioAssetPlayer {
  final _initialStop = Completer<void>();
  Completer<void>? _playback;

  void releaseInitialStop() => _initialStop.complete();

  @override
  Future<void> play(String assetPath, {required void Function() onStarted}) async {
    _playback = Completer<void>();
    onStarted();
    await _playback!.future;
  }

  @override
  Future<void> stop() async {
    if (!_initialStop.isCompleted) {
      await _initialStop.future;
      return;
    }
    final playback = _playback;
    if (playback != null && !playback.isCompleted) playback.complete();
  }

  @override
  Future<void> dispose() async {}
}

class NoopSpeechEngine implements SpeechEngine {
  @override
  Future<dynamic> getVoices() async => const [
    {'name': 'Thai voice', 'locale': 'th-TH'},
  ];

  @override
  Future<dynamic> setLanguage(String language) async => 1;

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async => 1;

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async => 1;

  @override
  Future<dynamic> speak(String text) async => 1;

  @override
  Future<dynamic> stop() async => 1;

  @override
  void setStartHandler(void Function() handler) {}

  @override
  void setCompletionHandler(void Function() handler) {}

  @override
  void setErrorHandler(void Function(dynamic error) handler) {}
}
