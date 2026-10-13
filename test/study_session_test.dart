import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/screens/study_session_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;
  setUpAll(() async => repository = await PhraseRepository.load(rootBundle));
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<AppState> setup(WidgetTester tester, LearningMode mode) async {
    final state = AppState();
    await state.load();
    final playback = ThaiPlaybackService(
      speechService: SpeechService(voiceLookupWindow: Duration.zero),
      catalog: ThaiAudioCatalog.empty(),
      assetPlayer: _NoopPlayer(),
    );
    addTearDown(playback.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: StudySessionScreen(
          repository: repository,
          appState: state,
          playbackService: playback,
          phrases: [repository.phrases.first],
          mode: mode,
          title: 'လေ့ကျင့်ရန်',
          lessonId: 'test:hello',
        ),
      ),
    );
    return state;
  }

  testWidgets('flashcards record one review and complete the lesson', (
    tester,
  ) async {
    final state = await setup(tester, LearningMode.flashcard);
    expect(find.text(repository.phrases.first.myanmar), findsNothing);
    await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
    await tester.pump();
    expect(find.text(repository.phrases.first.myanmar), findsOneWidget);
    await tester.ensureVisible(find.text('မှတ်မိတယ်'));
    await tester.tap(find.text('မှတ်မိတယ်'));
    await tester.pumpAndSettle();
    expect(state.learning.totalReviews, 1);
    expect(state.learning.completedLessons, contains('test:hello'));
    expect(find.text('ဒီအကြိမ် ပြီးပါပြီ'), findsOneWidget);
  });
  testWidgets('unavailable listening cannot earn progress', (tester) async {
    final state = await setup(tester, LearningMode.listening);
    final correct = find.text(repository.phrases.first.myanmar);
    await tester.ensureVisible(correct);
    await tester.tap(correct);
    await tester.pump();
    expect(state.learning.totalReviews, 0);
    await tester.ensureVisible(find.text('အသံနားထောင်ရန်'));
    await tester.tap(find.text('အသံနားထောင်ရန်'));
    await tester.pumpAndSettle();
    expect(find.text('စာကတ်နဲ့ လေ့ကျင့်မယ်'), findsOneWidget);
    expect(state.learning.totalReviews, 0);
    expect(state.learning.completedSessions, 0);
  });
  testWidgets('study fits landscape with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
    await setup(tester, LearningMode.meaning);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _NoopPlayer implements ThaiAudioAssetPlayer {
  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}
