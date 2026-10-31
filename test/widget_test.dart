import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/app.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/screens/main_shell.dart';
import 'package:thai_for_myanmar/screens/everyday_screen.dart';
import 'package:thai_for_myanmar/screens/learn_screen.dart';
import 'package:thai_for_myanmar/screens/profile_screen.dart';
import 'package:thai_for_myanmar/screens/quick_speak_screen.dart';
import 'package:thai_for_myanmar/screens/phrase_detail_screen.dart';
import 'package:thai_for_myanmar/screens/phrase_issue_screen.dart';
import 'package:thai_for_myanmar/screens/settings_screen.dart';
import 'package:thai_for_myanmar/screens/speech_setup_screen.dart';
import 'package:thai_for_myanmar/screens/study_session_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/widgets/thai_playback_button.dart';
import 'package:thai_for_myanmar/widgets/daily_goal_card.dart';
import 'package:thai_for_myanmar/widgets/rank_card.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/widgets/lesson_preview.dart';
import 'package:thai_for_myanmar/screens/quests_screen.dart';
import 'package:thai_for_myanmar/screens/quiz_screen.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;

  setUpAll(() async {
    repository = await PhraseRepository.load(rootBundle);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'scheduled listening reviews unlock at the exact due time without extra XP',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
      var now = DateTime.utc(2026, 10, 31, 12);
      final state = AppState();
      await state.load();
      final phrase = repository.phrases.first;
      await state.recordReview(phrase.id, LearningMode.flashcard, 4, now: now);
      final xp = state.learning.reviewXp;
      now = now.add(const Duration(minutes: 9));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuizScreen(
              repository: repository,
              appState: state,
              playbackService: _playbackService(),
              clock: () => now,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('scheduled-review')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('start-scheduled-review')),
        findsNothing,
      );
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('start-scheduled-review')),
        findsOneWidget,
      );
      expect(state.learning.reviewXp, xp);
      await tester.ensureVisible(
        find.byKey(const ValueKey('start-scheduled-review')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-scheduled-review')));
      await tester.pumpAndSettle();
      final session = tester.widget<StudySessionScreen>(
        find.byType(StudySessionScreen),
      );
      expect(session.guided, isTrue);
      expect(session.phrases.single.id, phrase.id);
      expect(session.lessonId, isNull);
      expect(state.learning.reviewXp, xp);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'finishing a unit offers a return to the next current lesson without scrolling',
    (tester) async {
      final state = AppState();
      await state.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repository,
              appState: state,
              playbackService: _playbackService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final firstUnit = StudyCatalog.lessons(
        repository,
      ).where((l) => l.category.id == repository.categories.first.id);
      for (final lesson in firstUnit) {
        await state.finishStudySession(lessonId: lesson.id);
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('jump-current-lesson')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('jump-current-lesson')));
      await tester.pumpAndSettle();
      expect(find.text('အပိုင်း 2'), findsOneWidget);
      expect(find.text('ဒီကနေ စမယ်'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Learn puts the path first and opens XP details on demand', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            repository: repository,
            appState: state,
            playbackService: _playbackService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(RankCard), findsNothing);
    expect(find.byType(DailyGoalCard), findsNothing);
    expect(tester.getTopLeft(find.text('ဒီကနေ စမယ်')).dy, lessThan(300));
    await tester.tap(find.byIcon(Icons.bolt_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(RankCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rank badges explain locked goals and XP rules at large text', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: RankCard(
                repository: repository,
                appState: state,
                showBadges: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.widgetWithText(ActionChip, '🐘 ထိုင်းစကားမိတ်ဆွေ'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(find.widgetWithText(ActionChip, '🐘 ထိုင်းစကားမိတ်ဆွေ'));
    await tester.pumpAndSettle();
    expect(find.text('သင်ခန်းစာ 5 ခု ပြီးလျှင် ရရှိမယ်'), findsOneWidget);
    await tester.tap(find.text('သိပါပြီ'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('XP ဘယ်လိုရမလဲ?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('XP ဘယ်လိုရမလဲ?'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Rank သည်'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('home and Quick Speak render at a small, larger-text viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);

    final appState = AppState();
    await appState.load();
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.text('သင်ယူ'), findsWidgets);
    expect(tester.takeException(), isNull);

    final quickSpeakDestination = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.record_voice_over_outlined),
    );
    await tester.tap(quickSpeakDestination);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byType(EverydayScreen), findsOneWidget);
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
    expect(find.byType(QuickSpeakScreen), findsOneWidget);
    expect(find.text('အမြန်သုံး'), findsWidgets);
    final emergencyHelp = repository.phrases.singleWhere(
      (phrase) => phrase.id == 'emergency_help',
    );
    expect(
      find.text(emergencyHelp.thaiFor(appState.politeStyle)),
      findsAtLeastNWidgets(1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'home search reaches results, clears an empty search, and exposes audio',
    (tester) async {
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
      await tester.ensureVisible(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-search')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'no-phrase-matches-this-123',
      );
      await tester.pumpAndSettle();
      expect(find.text('ဒီစကားစုကို မတွေ့ပါဘူး။'), findsOneWidget);
      await tester.tap(find.byTooltip('ဖျက်ရန်'));
      await tester.pumpAndSettle();
      expect(
        find.text('${repository.phrases.length} ခုတွေ့သည်'),
        findsOneWidget,
      );
      expect(find.byType(ThaiPlaybackButton), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('desktop uses six tabs and preserves the selected review mode', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
      hasLength(6),
    );
    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('စာကြောင်းစီ'));
    await tester.pumpAndSettle();
    final selected = tester
        .widget<Card>(find.byKey(const ValueKey('mode-sentence')))
        .color;
    expect(selected, isNotNull);
    await tester.tap(find.byIcon(Icons.route_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.replay_rounded));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Card>(find.byKey(const ValueKey('mode-sentence'))).color,
      selected,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search remains usable with large text and the mobile keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
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
    await tester.ensureVisible(find.byKey(const ValueKey('home-search')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-search')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(find.byType(TextField), 'no-match-123');
    await tester.pumpAndSettle();
    expect(find.text('ဒီစကားစုကို မတွေ့ပါဘူး။'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('ဖျက်ရန်'));
    await tester.pumpAndSettle();
    expect(find.byType(ThaiPlaybackButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme can be selected without blocking navigation', (
    tester,
  ) async {
    final appState = AppState();
    await appState.load();
    await appState.setThemePreference('dark');
    await tester.pumpWidget(
      ThaiForMyanmarApp(
        repository: repository,
        appState: appState,
        playbackService: _playbackService(),
      ),
    );
    await _pumpUi(tester);
    expect(find.byType(MainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home previews a five-card lesson before starting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    await tester.scrollUntilVisible(find.text('သင်ခန်းစာ ကြည့်မယ်'), 250);
    await tester.pumpAndSettle();
    await tester.tap(find.text('သင်ခန်းစာ ကြည့်မယ်'));
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionScreen), findsNothing);
    expect(find.byKey(const ValueKey('lesson-preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
    await tester.pumpAndSettle();
    final session = tester.widget<StudySessionScreen>(
      find.byType(StudySessionScreen),
    );
    expect(session.phrases, hasLength(5));
    expect(find.text(session.phrases.first.pronunciation), findsNothing);
    await tester.tap(find.text('အသံထွက်စာ ကြည့်မယ်'));
    await tester.pumpAndSettle();
    expect(find.text(session.phrases.first.pronunciation), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'path node previews the selected lesson and dismissal earns no progress',
    (tester) async {
      final state = AppState();
      await state.load();
      final lesson = StudyCatalog.lessons(repository)[1];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repository,
              appState: state,
              playbackService: _playbackService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final node = find.byKey(ValueKey('lesson-node-${lesson.id}'));
      await tester.scrollUntilVisible(node, 160);
      await tester.pumpAndSettle();
      await tester.tap(node);
      await tester.pumpAndSettle();
      expect(find.byType(StudySessionScreen), findsNothing);
      final preview = find.byKey(const ValueKey('lesson-preview'));
      expect(
        find.descendant(
          of: preview,
          matching: find.text('သင်ခန်းစာ ${lesson.number}'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: preview,
          matching: find.text('စကားစု ${lesson.phrases.length} ခု'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('ပိတ်မယ်'));
      await tester.pumpAndSettle();
      expect(preview, findsNothing);
      expect(state.learning.totalReviews, 0);
      expect(state.learning.completedLessons, isEmpty);
      await tester.tap(node);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudySessionScreen>(find.byType(StudySessionScreen))
            .lessonId,
        lesson.id,
      );
      expect(state.learning.totalReviews, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed lesson preview offers replay without promising completion XP',
    (tester) async {
      final state = AppState();
      await state.load();
      final lesson = StudyCatalog.lessons(repository).first;
      await state.finishStudySession(lessonId: lesson.id);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repository,
              appState: state,
              playbackService: _playbackService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('lesson-node-${lesson.id}')));
      await tester.pumpAndSettle();
      expect(find.text('သင်ပြီး'), findsOneWidget);
      expect(find.text('+20 XP'), findsNothing);
      expect(find.text('ပြန်လေ့ကျင့်မယ်'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StudySessionScreen>(find.byType(StudySessionScreen))
            .lessonId,
        lesson.id,
      );
      expect(state.learning.completedLessons, {lesson.id});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'lesson preview stays inside a short narrow dark screen with large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 400);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
      final lesson = StudyCatalog.lessons(
        repository,
      ).firstWhere((l) => l.phrases.length < 5);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLessonPreview(
                  context: context,
                  lesson: lesson,
                  completed: false,
                  anchor: const Rect.fromLTWH(290, 365, 25, 25),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byKey(const ValueKey('lesson-preview')));
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(304));
      expect(rect.top, greaterThanOrEqualTo(16));
      expect(rect.bottom, lessThanOrEqualTo(384));
      final start = find.byKey(const ValueKey('lesson-preview-start'));
      await tester.ensureVisible(start);
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lesson-preview')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('topic search changes the actual lesson started', (tester) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearnScreen(
            repository: repository,
            appState: state,
            playbackService: _playbackService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Food');
    await tester.pumpAndSettle();
    await tester.tap(find.text('အစားအသောက်'));
    await tester.pumpAndSettle();
    final path = tester.widget<CustomScrollView>(
      find.byKey(const ValueKey('learning-path')),
    );
    expect(path.controller!.offset, greaterThan(1000));
    expect(path.controller!.position.maxScrollExtent, greaterThan(15000));
    expect(find.textContaining('အစားအသောက်'), findsWidgets);
    // The unit action is already pinned on screen. Forcing ensureVisible on a
    // pinned sliver scrolls to its original position and changes the active unit.
    await tester.tap(find.text('သင်ခန်းစာ ကြည့်မယ်'));
    await tester.pumpAndSettle();
    expect(find.byType(StudySessionScreen), findsNothing);
    expect(find.byKey(const ValueKey('lesson-preview')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lesson-preview-start')));
    await tester.pumpAndSettle();
    final session = tester.widget<StudySessionScreen>(
      find.byType(StudySessionScreen),
    );
    expect(session.phrases.every((p) => p.categoryId == 'food'), isTrue);
    expect(session.lessonId, startsWith('food:'));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('အကြောင်းအရာ ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Daily life');
    await tester.pumpAndSettle();
    await tester.tap(find.text('နေ့စဉ်ဘဝ'));
    await tester.pumpAndSettle();
    expect(path.controller!.offset, greaterThan(15000));
    expect(find.text('နေ့စဉ်ဘဝ'), findsWidgets);

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'scrolling updates the unit banner and current-step button returns home',
    (tester) async {
      final state = AppState();
      await state.load();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repository,
              appState: state,
              playbackService: _playbackService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final path = tester.widget<CustomScrollView>(
        find.byKey(const ValueKey('learning-path')),
      );
      path.controller!.jumpTo(1800);
      await tester.pumpAndSettle();
      expect(find.text('အပိုင်း 1'), findsNothing);
      expect(find.byKey(const ValueKey('jump-current-lesson')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('jump-current-lesson')));
      await tester.pumpAndSettle();
      expect(find.text('အပိုင်း 1'), findsOneWidget);
      expect(path.controller!.offset, lessThan(100));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'quests are reachable from mobile navigation and fit enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
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
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
        hasLength(6),
      );
      await tester.tap(find.byIcon(Icons.inventory_2_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(QuestsScreen), findsOneWidget);
      expect(find.text('ဒီလရဲ့ စိန်ခေါ်မှု'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('သင်ခန်းစာ ဆက်သင်မယ်'), 200);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('သင်ခန်းစာ ဆက်သင်မယ်'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('learning-path')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('visible quests roll over at midnight without another review', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    var now = DateTime(2026, 10, 30, 23, 59);
    await state.recordReview(
      repository.phrases.first.id,
      LearningMode.meaning,
      5,
      now: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestsScreen(
            repository: repository,
            appState: state,
            clock: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 5'), findsOneWidget);
    now = DateTime(2026, 10, 31);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(find.text('0 / 5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('six destinations and the path fit a short desktop window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      find.byKey(
        ValueKey('lesson-node-${StudyCatalog.lessons(repository).first.id}'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Everyday searches inline and filters saved phrases at 320px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EverydayScreen(
            repository: repository,
            appState: state,
            playbackService: _playbackService(),
            onSearch: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('everyday-search')),
      'ဗိုက်နာ',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('အကြိုက်ဆုံးအဖြစ် သိမ်းရန်'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('အကြိုက်ဆုံးအဖြစ် သိမ်းရန်'));
    await tester.pumpAndSettle();
    expect(state.isFavorite('health_stomach'), isTrue);
    await tester.ensureVisible(find.text('သိမ်းထားတာ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('သိမ်းထားတာ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('ဖျက်ရန်'));
    await tester.pumpAndSettle();
    expect(find.text('1 ခုတွေ့သည်'), findsOneWidget);
    expect(find.text('ဗိုက်နာနေပါတယ်။'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily goal changes persist and zero activity is honest', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            repository: repository,
            appState: state,
            playbackService: _playbackService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ဒီနေ့ကနေ စလိုက်ပါ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('နေ့စဉ်ပန်းတိုင် ပြောင်းရန်'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('နေ့စဉ်ပန်းတိုင် ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 ကြိမ် / ရက်'));
    await tester.pumpAndSettle();
    expect(state.learning.dailyGoal, 5);
    expect(find.text('0 / 5 ကြိမ်'), findsOneWidget);
    final restored = AppState();
    await restored.load();
    expect(restored.learning.dailyGoal, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('daily goal picker scrolls in large-text landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.view.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.platformDispatcher.clearTextScaleFactorTestValue);
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(children: [DailyGoalCard(appState: state)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('နေ့စဉ်ပန်းတိုင် ပြောင်းရန်'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('20 ကြိမ် / ရက်'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20 ကြိမ် / ရက်'));
    await tester.pumpAndSettle();
    expect(state.learning.dailyGoal, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phrase correction is saved and clearly marked unsent', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: PhraseDetailScreen(
          phrase: repository.phrases.firstWhere((p) => p.id == 'greet_hello'),
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('ဒီစကားစုမှာ အမှားထောက်ပြရန်'),
      180,
    );
    await tester.tap(find.text('ဒီစကားစုမှာ အမှားထောက်ပြရန်'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseIssueScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'အသံထွက်ကို စစ်ပေးပါ');
    await tester.pump();
    final saveButton = find.widgetWithText(FilledButton, 'စက်ထဲ သိမ်းရန်');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await tester.ensureVisible(find.text('စက်ထဲ သိမ်းရန်'));
    await tester.tap(find.text('စက်ထဲ သိမ်းရန်'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(state.phraseIssues, hasLength(1));
    expect(find.textContaining('Developer ဆီ မပို့ရသေးပါ'), findsOneWidget);
    expect(find.text('အမှားထောက်ပြချက် Copy လုပ်ရန်'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a phrase detail opens practice for that exact phrase', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    final phrase = repository.phrases.first;
    await tester.pumpWidget(
      MaterialApp(
        home: PhraseDetailScreen(
          phrase: phrase,
          repository: repository,
          appState: state,
          playbackService: _playbackService(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('ဒီစကားစုကို လေ့ကျင့်မယ်'));
    await tester.tap(find.text('ဒီစကားစုကို လေ့ကျင့်မယ်'));
    await tester.pumpAndSettle();
    final session = tester.widget<StudySessionScreen>(
      find.byType(StudySessionScreen),
    );
    expect(session.phrases.map((item) => item.id), [phrase.id]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voice test and saved correction list are visible in Settings', (
    tester,
  ) async {
    final state = AppState();
    await state.load();
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(
          appState: state,
          repository: repository,
          playbackService: _playbackService(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('ထိုင်းအသံ စမ်းရန် / ပြင်ဆင်နည်း'));
    await tester.tap(find.text('ထိုင်းအသံ စမ်းရန် / ပြင်ဆင်နည်း'));
    await tester.pumpAndSettle();
    expect(find.byType(SpeechSetupScreen), findsOneWidget);
    expect(find.text('ထိုင်းအသံ စမ်းရန်'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('သိမ်းထားသော အမှားထောက်ပြချက်များ'));
    await tester.tap(find.text('သိမ်းထားသော အမှားထောက်ပြချက်များ'));
    await tester.pumpAndSettle();
    expect(find.byType(SavedPhraseIssuesScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
}

ThaiPlaybackService _playbackService() => ThaiPlaybackService(
  speechService: SpeechService(),
  catalog: ThaiAudioCatalog.empty(),
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
