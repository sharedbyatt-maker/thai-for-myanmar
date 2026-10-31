import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/screens/practical_intro_screen.dart';
import 'package:thai_for_myanmar/screens/learn_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;
  late ThaiAudioCatalog catalog;
  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
    catalog = await ThaiAudioCatalog.load(rootBundle);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> show(WidgetTester tester, Finder finder) async {
    final scroll = find.byType(Scrollable).first;
    if (finder.evaluate().isEmpty) {
      tester.state<ScrollableState>(scroll).position.jumpTo(0);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(finder, 160, scrollable: scroll);
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await show(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> token(WidgetTester tester, int index) async {
    final finder = find.byKey(ValueKey('practical-token-$index'));
    await show(tester, finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('all pilot listening lines have exact bundled audio in both styles', () {
    for (final id in [
      'greet_hello',
      'intro_ask_name',
      'intro_name',
      'intro_from_city',
      'intro_myanmar',
      'intro_nice_to_meet',
    ]) {
      final phrase = repository.phrases.singleWhere((p) => p.id == id);
      for (final style in ['male', 'female']) {
        expect(catalog.match(phrase, style), isNotNull, reason: '$id/$style');
      }
    }
  });
  testWidgets(
    'practical lesson is reachable from Learn and exiting does not award completion',
    (tester) async {
      final state = AppState();
      await state.load();
      final service = ThaiPlaybackService(
        speechService: SpeechService(engine: _Unavailable()),
        catalog: catalog,
        assetPlayer: _Player(),
      );
      addTearDown(service.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repository,
              appState: state,
              playbackService: service,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('practical-intro-entry')),
      );
      await tester.tap(find.byKey(const ValueKey('practical-intro-entry')));
      await tester.pumpAndSettle();
      expect(find.byType(PracticalIntroScreen), findsOneWidget);
      await tap(tester, 'စကားလုံးပုံစံကို ကြည့်မယ်');
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('အခု နားမလား?'), findsOneWidget);
      await tap(tester, 'အခု နားမယ်');
      expect(state.learning.practicalChecks, isEmpty);
      expect(state.learning.totalReviews, 0);
      expect(state.learning.completedLessons, isEmpty);
    },
  );

  for (final style in ['male', 'female']) {
    testWidgets(
      '$style practical lesson requires construction and unaided audio; persists separately',
      (tester) async {
        tester.view.physicalSize = style == 'female'
            ? const Size(568, 320)
            : const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        tester.view.platformDispatcher.textScaleFactorTestValue =
            style == 'female' ? 2 : 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(
          tester.view.platformDispatcher.clearTextScaleFactorTestValue,
        );
        final state = AppState();
        await state.load();
        await state.setPoliteStyle(style);
        await state.finishStudySession(lessonId: 'old-lesson');
        final player = _Player();
        final service = ThaiPlaybackService(
          speechService: SpeechService(
            engine: _Unavailable(),
            voiceLookupWindow: Duration.zero,
          ),
          catalog: catalog,
          assetPlayer: player,
        );
        addTearDown(service.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: PracticalIntroScreen(
              repository: repository,
              appState: state,
              playbackService: service,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(tester, 'စကားလုံးပုံစံကို ကြည့်မယ်');
        await tester.scrollUntilVisible(
          find.byType(TextField),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(
          find.byType(TextField),
          style == 'male' ? 'ชื่อ' : 'မေ',
        );
        await tap(tester, 'ကိုယ့်ဝါကျ တည်ဆောက်မယ်');
        for (final i in [0, 1, 2, 3]) {
          await token(tester, i);
        }
        await tap(tester, 'ဝါကျစစ်မယ်');
        expect(find.text('ဆက်သင်မယ်'), findsNothing);
        await tap(tester, 'အစီအစဉ် ပြန်ရွေးမယ်');
        for (final i in [3, 2, 1, 0]) {
          await token(tester, i);
        }
        await tap(tester, 'ဝါကျစစ်မယ်');
        await tap(tester, 'ဆက်သင်မယ်');
        await show(
          tester,
          find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
              )
              .onPressed,
          isNull,
        );
        expect(
          find.text(
            repository.phrases
                .singleWhere((p) => p.id == 'intro_ask_name')
                .thaiFor(style),
          ),
          findsNothing,
        );
        await tap(tester, 'စာသား အကူအညီ ကြည့်မယ်');
        await tap(tester, 'မေးခွန်း နားထောင်မယ်');
        await show(
          tester,
          find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
              )
              .onPressed,
          isNull,
        );
        await tap(tester, 'စာဖျောက်ပြီး ပြန်စမ်းမယ်');
        // Playback failure must never unlock or record a listening pass.
        player.fail = true;
        await tap(tester, 'မေးခွန်း နားထောင်မယ်');
        await show(
          tester,
          find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, 'နာမည်ကို မေးတာ'),
              )
              .onPressed,
          isNull,
        );
        expect(state.learning.totalReviews, 0);
        player.fail = false;
        await tap(tester, 'မေးခွန်း နားထောင်မယ်');
        await tap(tester, 'နာမည်ကို မေးတာ');
        await tap(tester, 'စကားဝိုင်း ဆက်မယ်');
        await tap(tester, 'အကူအညီမပါဘဲ ပြန်ဖြေမယ်');
        for (final i in [2, 3, 0, 1]) {
          await token(tester, i);
        }
        await tap(tester, 'ဝါကျစစ်မယ်');
        expect(find.text('ဆက်သင်မယ်'), findsNothing);
        await tap(tester, 'အစီအစဉ် ပြန်ရွေးမယ်');
        for (final i in [2, 3, 4, 1]) {
          await token(tester, i);
        }
        await tap(tester, 'ဝါကျစစ်မယ်');
        await tap(tester, 'ဆက်သင်မယ်');
        expect(state.learning.practicalChecks, isEmpty);
        await show(tester, find.text('လေ့ကျင့်ပြီးကြောင်း သိမ်းမယ်'));
        final finish = tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'လေ့ကျင့်ပြီးကြောင်း သိမ်းမယ်'),
            )
            .onPressed!;
        finish();
        finish();
        await tester.pumpAndSettle();
        expect(state.learning.totalReviews, 1);
        expect(state.learning.completedLessons, {'old-lesson'});
        expect(state.learning.completedSessions, 1);
        final restored = AppState();
        await restored.load();
        expect(restored.learning.practicalChecks.keys, {
          PracticalIntroScreen.lessonId,
        });
        expect(restored.learning.completedLessons, {'old-lesson'});
        expect(tester.takeException(), isNull);
      },
    );
  }
}

class _Player implements ThaiAudioAssetPlayer {
  bool fail = false;
  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    if (fail) throw Exception('test unavailable');
    onStarted();
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _Unavailable implements SpeechEngine {
  @override
  Future<dynamic> getVoices() async => [];
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
