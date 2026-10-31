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
  late ThaiAudioCatalog audioCatalog;
  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
    audioCatalog = await ThaiAudioCatalog.load(rootBundle);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<AppState> setup(
    WidgetTester tester,
    LearningMode mode, {
    int count = 1,
    bool guided = false,
    bool dark = false,
    bool audioAvailable = true,
  }) async {
    final state = AppState();
    await state.load();
    final playback = ThaiPlaybackService(
      speechService: SpeechService(
        engine: _UnavailableEngine(),
        voiceLookupWindow: Duration.zero,
      ),
      catalog: audioAvailable ? audioCatalog : ThaiAudioCatalog.empty(),
      assetPlayer: _NoopPlayer(),
    );
    addTearDown(playback.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? ThemeData.dark() : ThemeData.light(),
        home: StudySessionScreen(
          repository: repository,
          appState: state,
          playbackService: playback,
          phrases: repository.phrases.take(count).toList(),
          mode: mode,
          title: 'လေ့ကျင့်ရန်',
          lessonId: 'test:hello',
          guided: guided,
        ),
      ),
    );
    return state;
  }

  testWidgets(
    'guided lesson requires recall, explains errors and records once',
    (tester) async {
      final state = await setup(tester, LearningMode.flashcard, guided: true);
      await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      expect(state.learning.totalReviews, 0);
      await tester.tap(find.text('စမ်းဖြေမယ်'));
      await tester.pumpAndSettle();
      expect(
        find.text(repository.phrases.first.thaiFor(state.politeStyle)),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('guided-audio')));
      await tester.pumpAndSettle();
      final correctId = repository.phrases.first.id;
      final options = find.byWidgetPredicate(
        (w) =>
            w is OutlinedButton && w.key.toString().contains('guided-option-'),
      );
      final wrong = options
          .evaluate()
          .map((e) => e.widget as OutlinedButton)
          .firstWhere((w) => w.key != ValueKey('guided-option-$correctId'));
      await tester.ensureVisible(find.byKey(wrong.key!));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(wrong.key!));
      await tester.pump();
      await tester.tap(find.text('အဖြေစစ်မယ်'));
      await tester.pumpAndSettle();
      expect(state.learning.totalReviews, 0);
      expect(state.learning.completedSessions, 0);
      expect(find.textContaining('မှတ်ထားပါ'), findsOneWidget);
      await tester.tap(find.text('ပြန်စမ်းမယ်'));
      await tester.pumpAndSettle();
      final correct = find.byKey(ValueKey('guided-option-$correctId'));
      await tester.ensureVisible(correct);
      await tester.pumpAndSettle();
      await tester.tap(correct);
      await tester.pump();
      final check = find.descendant(
        of: find.byKey(const ValueKey('guided-primary')),
        matching: find.byType(FilledButton),
      );
      final onPressed = tester.widget<FilledButton>(check).onPressed!;
      onPressed();
      onPressed();
      await tester.pumpAndSettle();
      expect(state.learning.totalReviews, 1);
      expect(state.learning.completedSessions, 0);
      expect(
        state.learning.cardFor(correctId, LearningMode.flashcard)!.lastQuality,
        3,
      );
      await tester.tap(find.text('ရလဒ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      expect(state.learning.completedSessions, 1);
      expect(state.learning.completedLessons, contains('test:hello'));
      expect(find.text('ပထမအကြိမ်မှန် 0 ခု • သင်ပြီး 1 ခု'), findsOneWidget);
    },
  );

  testWidgets('guided study fits short windows, large text and dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
    await setup(tester, LearningMode.flashcard, guided: true, dark: true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('စမ်းဖြေမယ်'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'guided listening cannot grade unheard audio and offers an explicit text fallback',
    (tester) async {
      final state = await setup(
        tester,
        LearningMode.flashcard,
        count: 3,
        guided: true,
        audioAvailable: false,
      );
      for (var index = 0; index < 3; index++) {
        await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('စမ်းဖြေမယ်'));
        await tester.pumpAndSettle();
        final option = find.byKey(
          ValueKey('guided-option-${repository.phrases[index].id}'),
        );
        {
          expect(tester.widget<OutlinedButton>(option).onPressed, isNull);
          expect(state.learning.totalReviews, index);
          await tester.tap(find.byKey(const ValueKey('guided-audio')));
          await tester.pumpAndSettle();
          expect(find.text('စာနဲ့ ဆက်လေ့ကျင့်မယ်'), findsOneWidget);
          expect(state.learning.totalReviews, 2);
          await tester.ensureVisible(find.text('စာနဲ့ ဆက်လေ့ကျင့်မယ်'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('စာနဲ့ ဆက်လေ့ကျင့်မယ်'));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(option);
        await tester.pumpAndSettle();
        await tester.tap(option);
        await tester.pump();
        await tester.tap(find.text('အဖြေစစ်မယ်'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(index == 2 ? 'ရလဒ်ကြည့်မယ်' : 'နောက်စကားစု'),
        );
        await tester.pumpAndSettle();
      }
      expect(state.learning.totalReviews, 3);
      expect(state.learning.completedSessions, 1);
      expect(
        state.learning.cardFor(
          repository.phrases[2].id,
          LearningMode.listening,
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'leaving an active lesson asks first and cancelling retains the current stage',
    (tester) async {
      final state = await setup(tester, LearningMode.flashcard, guided: true);
      await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(StudySessionScreen));
      await Navigator.of(context).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('ဒီအကြိမ် နားမလား?'), findsOneWidget);
      await tester.tap(find.text('ဆက်သင်မယ်'));
      await tester.pumpAndSettle();
      expect(find.text('စမ်းဖြေမယ်'), findsOneWidget);
      expect(state.learning.completedSessions, 0);
      expect(state.learning.completedLessons, isEmpty);
    },
  );

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
    await tester.scrollUntilVisible(correct, 200);
    await tester.pumpAndSettle();
    await tester.tap(correct);
    await tester.pump();
    expect(state.learning.totalReviews, 0);
    await tester.scrollUntilVisible(find.text('အသံနားထောင်ရန်'), -200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('အသံနားထောင်ရန်'));
    await tester.pumpAndSettle();
    expect(find.text('စာကတ်နဲ့ လေ့ကျင့်မယ်'), findsOneWidget);
    expect(state.learning.totalReviews, 0);
    expect(state.learning.completedSessions, 0);
  });

  testWidgets('reverse meaning practice grades the selected Thai answer', (
    tester,
  ) async {
    final state = await setup(tester, LearningMode.reverseMeaning);
    expect(find.text(repository.phrases.first.myanmar), findsOneWidget);
    expect(find.text('ထိုင်းအသံ နားထောင်ရန်'), findsNothing);
    final answer = find.text(
      repository.phrases.first.thaiFor(state.politeStyle),
    );
    await tester.ensureVisible(answer);
    // Scroll changes need a frame before hit-testing the shuffled answer.
    await tester.pumpAndSettle();
    await tester.tap(answer);
    await tester.pump();
    expect(
      state.learning
          .cardFor(repository.phrases.first.id, LearningMode.reverseMeaning)!
          .lastQuality,
      5,
    );
    expect(state.learning.totalReviews, 1);
  });

  testWidgets('repeated taps cannot grade an unseen flashcard', (tester) async {
    final state = await setup(tester, LearningMode.flashcard, count: 2);
    await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
    await tester.pump();
    final button = find.ancestor(
      of: find.text('မှတ်မိတယ်'),
      matching: find.byType(FilledButton),
    );
    final tap = tester.widget<FilledButton>(button).onPressed!;
    tap();
    tap();
    await tester.pump();
    expect(state.learning.totalReviews, 1);
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

class _UnavailableEngine implements SpeechEngine {
  @override
  Future<dynamic> getVoices() async => const [];
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
