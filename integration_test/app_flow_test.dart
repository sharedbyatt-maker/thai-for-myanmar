import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';
import 'package:thai_for_myanmar/screens/everyday_screen.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

late ThaiAudioCatalog _testCatalog;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
    _testCatalog = await ThaiAudioCatalog.load(rootBundle);
  });

  if (kIsWeb) {
    testWidgets('responsive home and direct search render in Chrome', (
      tester,
    ) async {
      final state = AppState();
      await state.load();
      await state.setThemePreference('light');
      await tester.pumpWidget(
        ThaiForMyanmarApp(
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      );
      await tester.pumpAndSettle();
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect([390, 1280], contains(width.round()));
      expect(
        find.byType(width >= 1000 ? NavigationRail : NavigationBar),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('${width.round()}-home');
      await state.setThemePreference('dark');
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-home-dark');
      await state.setThemePreference('light');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ယူနစ် လမ်းညွှန်'));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-course-unit');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('course-lesson-u01-1')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-course-preview');
      await tester.tap(find.byKey(const ValueKey('course-preview-start')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-course-model');
      await tester.tap(find.byKey(const ValueKey('course-primary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('course-primary')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-course-listening');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-everyday');
      await tester.enterText(
        find.byKey(const ValueKey('everyday-search')),
        'ဗိုက်နာ',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
      await binding.takeScreenshot('${width.round()}-inline-search');
      await tester.enterText(find.byKey(const ValueKey('everyday-search')), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.route_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ဗိုက်နာ');
      await tester.pumpAndSettle();
      expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('${width.round()}-search');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('course-unit-u26')),
        500,
        maxScrolls: 150,
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-path-end');
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.inventory_2_outlined));
      await tester.pumpAndSettle();
      expect(find.text('ဒီလရဲ့ စိန်ခေါ်မှု'), findsOneWidget);
      await binding.takeScreenshot('${width.round()}-quests');
      await tester.scrollUntilVisible(find.text('သင်ခန်းစာ ဆက်သင်မယ်'), 220);
      await tester.pumpAndSettle();
      await tester.tap(find.text('သင်ခန်းစာ ဆက်သင်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_outline_rounded));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-profile');
      await tester.tap(find.byIcon(Icons.replay_rounded));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('${width.round()}-practice');
    });
  }

  testWidgets(
    'course text completion is durable and never becomes listening or league credit',
    (tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final state = AppState();
      await state.load();
      await tester.pumpWidget(
        ThaiForMyanmarApp(
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('course-lesson-u01-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('course-preview-start')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const ValueKey('course-primary')));
        await tester.pumpAndSettle();
      }
      for (final id in ['c2_u01_01', 'c2_u01_02']) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('course-text-mode')),
        );
        await tester.tap(find.byKey(const ValueKey('course-text-mode')));
        await tester.pumpAndSettle();
        final option = find.byKey(ValueKey('course-option-$id'));
        await tester.ensureVisible(option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('course-primary')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('course-primary')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const ValueKey('course-done')), findsOneWidget);
      expect(state.learning.course.completed.length, 1);
      expect(state.learning.course.memory, isEmpty);
      expect(state.learning.completedLessons, isEmpty);
      expect(state.learning.totalReviews, 0);
      await state.saveCourse();
      final restored = AppState();
      await restored.load();
      expect(restored.learning.course.completed.length, 1);
      if (kIsWeb) {
        final width =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;
        await binding.takeScreenshot('${width.round()}-course-text-summary');
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('guided lesson completes and restores local learning progress', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: state,
        playbackService: _playbackService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('legacy-learning-history')),
      500,
      maxScrolls: 150,
    );
    await tester.tap(find.byKey(const ValueKey('legacy-learning-history')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('သင်ခန်းစာ ကြည့်မယ်'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lesson-preview')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('lesson-preview-start')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
    await tester.pump(const Duration(milliseconds: 500));
    final phrases = StudyCatalog.lessons(repository).first.phrases;
    for (var index = 0; index < phrases.length; index++) {
      await tester.ensureVisible(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('အဓိပ္ပာယ်ကြည့်မယ်'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('စမ်းဖြေမယ်'));
      await tester.pumpAndSettle();
      {
        if (kIsWeb) {
          await binding.takeScreenshot(
            '${(tester.view.physicalSize.width / tester.view.devicePixelRatio).round()}-lesson-listening',
          );
        }
        await tester.tap(find.byKey(const ValueKey('guided-audio')));
        await tester.pumpAndSettle();
      }
      final option = find.byKey(ValueKey('guided-option-${phrases[index].id}'));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pump();
      await tester.tap(find.text('အဖြေစစ်မယ်'));
      await tester.pumpAndSettle();
      if (kIsWeb && index == 0) {
        await binding.takeScreenshot(
          '${(tester.view.physicalSize.width / tester.view.devicePixelRatio).round()}-lesson-feedback',
        );
      }
      await tester.tap(
        find.text(index + 1 == phrases.length ? 'ရလဒ်ကြည့်မယ်' : 'နောက်စကားစု'),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('ဒီအကြိမ် ပြီးပါပြီ'), findsOneWidget);
    expect(state.learning.totalReviews, 5);
    expect(state.learning.completedSessions, 1);
    expect(state.learning.completedLessons, hasLength(1));
    expect(
      state.learning.lessonsOn(DateTime.now()),
      contains(state.learning.completedLessons.single),
    );
    expect(find.text('+45 XP'), findsOneWidget);
    await tester.ensureVisible(find.text('နောက်သင်ခန်းစာ ဆက်မယ်'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Await a queued settings save to drain the preceding review snapshots.
    await state.setDailyGoal(10);
    final restored = AppState();
    await restored.load();
    expect(restored.learning.totalReviews, 5);
    expect(restored.learning.reviewXp, 25);
    expect(
      restored.learning.cards.values.every((card) => card.usesFsrs),
      isTrue,
    );
    expect(restored.learning.completedLessons, state.learning.completedLessons);
    await tester.tap(find.text('နောက်သင်ခန်းစာ ဆက်မယ်'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lesson-preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
    await tester.pumpAndSettle();
    expect(find.text('ဒီအကြိမ် ပြီးပါပြီ'), findsNothing);
    expect(find.text('အဓိပ္ပာယ်ကြည့်မယ်'), findsOneWidget);
    expect(state.learning.totalReviews, 5);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scheduled-review')), findsOneWidget);
    expect(find.byKey(const ValueKey('start-scheduled-review')), findsNothing);
    if (kIsWeb) {
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      await binding.takeScreenshot('${width.round()}-scheduled-review');
    }
  });

  testWidgets('Quick Speak searches, displays, and saves a phrase', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final state = AppState();
    await state.load();

    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: state,
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('သင်ယူ'), findsWidgets);

    await tester.tap(find.byIcon(Icons.record_voice_over_outlined));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('ထိုင်းလူမျိုးကို ပြမယ်'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(EverydayScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ထိုင်းလူမျိုးကို ပြမယ်'));
    await tester.pumpAndSettle();
    expect(find.text('အမြန်သုံး'), findsWidgets);
    final emergencyHelp = repository.phrases.singleWhere(
      (phrase) => phrase.id == 'emergency_help',
    );
    expect(
      find.text(emergencyHelp.thaiFor(state.politeStyle)),
      findsAtLeastNWidgets(1),
    );

    await tester.enterText(find.byType(TextField), 'ဗိုက်နာ');
    await _pumpUi(tester);
    expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);

    final stomachResult = find.ancestor(
      of: find.text('ဗိုက်နာနေပါတယ်။'),
      matching: find.byType(ListTile),
    );
    expect(stomachResult, findsOneWidget);
    await tester.tap(stomachResult);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('ปวดท้องค่ะ'), findsWidgets);
    expect(find.textContaining('အသံထွက်'), findsWidgets);

    await tester.tap(find.byTooltip('အကြိုက်ဆုံးအဖြစ် သိမ်းရန်'));
    await _pumpUi(tester);
    expect(state.isFavorite('health_stomach'), isTrue);

    final restored = AppState();
    await restored.load();
    expect(restored.isFavorite('health_stomach'), isTrue);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
}

ThaiPlaybackService _playbackService() => ThaiPlaybackService(
  speechService: SpeechService(),
  catalog: _testCatalog,
  assetPlayer: _NoopAssetPlayer(),
);

class _NoopAssetPlayer implements ThaiAudioAssetPlayer {
  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    onStarted();
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}
