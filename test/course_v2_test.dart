import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/course_catalog.dart';
import 'package:thai_for_myanmar/learning/course_progress.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/screens/learn_screen.dart';
import 'package:thai_for_myanmar/screens/course_lesson_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repo;
  late CourseCatalog course;
  late ThaiAudioCatalog audio;
  setUpAll(() async {
    repo = await PhraseRepository.load(rootBundle);
    course = repo.course!;
    audio = await ThaiAudioCatalog.load(rootBundle);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('unit probes respect day and week boundaries and survive reload', () {
    final progress = CourseProgress();
    final start = DateTime.utc(2026, 10, 1);
    progress.finish(course.units.first.lessons.last.id, start);
    expect(
      course.dueUnitProbe(
        progress,
        start.add(const Duration(hours: 23, minutes: 59)),
      ),
      isNull,
    );
    expect(
      course.dueUnitProbe(
        progress,
        start.add(const Duration(days: 1)),
      )?['probeStage'],
      1,
    );
    progress.probeStages['u01'] = 1;
    final restored = CourseProgress.fromJson(
      jsonDecode(jsonEncode(progress.toJson())),
    );
    expect(
      course.dueUnitProbe(restored, start.add(const Duration(days: 6))),
      isNull,
    );
    expect(
      course.dueUnitProbe(
        restored,
        start.add(const Duration(days: 7)),
      )?['probeStage'],
      2,
    );
    restored.probeStages['u01'] = 2;
    expect(
      course.dueUnitProbe(restored, start.add(const Duration(days: 30))),
      isNull,
    );
  });
  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        140,
        maxScrolls: 40,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> primary(WidgetTester t) =>
      tap(t, find.byKey(const ValueKey('course-primary')));
  Future<AppState> show(
    WidgetTester t, {
    int lesson = 0,
    ThaiAudioCatalog? catalog,
    _Player? player,
  }) async {
    final state = AppState();
    await state.load();
    final service = ThaiPlaybackService(
      speechService: SpeechService(engine: _Silent()),
      catalog: catalog ?? ThaiAudioCatalog.empty(),
      assetPlayer: player ?? _Player(),
    );
    addTearDown(service.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: CourseLessonScreen(
          course: course,
          unit: course.units.first,
          lesson: course.units.first.lessons[lesson],
          appState: state,
          playbackService: service,
        ),
      ),
    );
    await t.pumpAndSettle();
    return state;
  }

  test(
    'all 26 authored units have sequential prerequisites and playable steps',
    () {
      expect(course.units.length, 26);
      expect(course.units.fold(0, (n, u) => n + u.lessons.length), 178);
      final seen = <String>{};
      for (final u in course.units) {
        expect(seen.contains(u.id), false);
        expect(seen.containsAll(u.prerequisites), true);
        seen.add(u.id);
        expect(u.lessons.last.steps.last['kind'], 'reflect');
      }
      final intro = course.lines['c2_u01_03']!;
      expect(intro.thai('male'), 'ผมชื่อเอกครับ');
      expect(audio.match(intro.phrase('male'), 'male'), isNull);
      expect(
        audio.match(course.lines['c2_u01_01']!.phrase('female'), 'female'),
        isNotNull,
      );
    },
  );

  test(
    'course corruption does not destroy legacy history and bounded evidence reloads',
    () {
      final p = LearningProgress();
      p.record('greet_hello', LearningMode.flashcard, 4, DateTime.utc(2026));
      p.finishSession(lessonId: 'legacy');
      final json = p.toJson();
      json['courseV2'] = {'version': 99};
      final restored = LearningProgress.fromJson(
        Map<String, dynamic>.from(json),
      );
      expect(restored.completedLessons, contains('legacy'));
      expect(restored.totalReviews, 1);
      expect(restored.course.completed, isEmpty);
      final c = CourseProgress();
      for (var i = 0; i < 650; i++) {
        c.event({
          'lesson': 'l',
          'line': 'x',
          'kind': 'choice',
          'at': DateTime.utc(2026).toIso8601String(),
          'correct': false,
        });
      }
      c.finish('course-v2.1:u01-l01', DateTime.utc(2026));
      final copy = CourseProgress.fromJson(jsonDecode(jsonEncode(c.toJson())));
      expect(copy.events.length, 600);
      expect(copy.completed.length, 1);
    },
  );

  testWidgets(
    'main path replaces side pilot and locks lessons by prerequisites',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final state = AppState();
      await state.load();
      final service = ThaiPlaybackService(
        speechService: SpeechService(engine: _Silent()),
        catalog: audio,
        assetPlayer: _Player(),
      );
      addTearDown(service.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: LearnScreen(
                repository: repo,
                appState: state,
                playbackService: service,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('practical-intro-entry')), findsNothing);
      await tap(t, find.byKey(const ValueKey('course-continue')));
      await tap(t, find.byKey(const ValueKey('course-lesson-u01-2')));
      expect(find.text('အခြေခံ lesson ကို အရင်လေ့ကျင့်ပါ။'), findsOneWidget);
      expect(find.byType(CourseLessonScreen), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'text completion preserves first wrong evidence without listening or legacy credit',
    (t) async {
      final state = await show(t);
      await primary(t);
      await primary(t);
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('course-option-c2_u01_01')),
            )
            .onPressed,
        isNull,
      );
      await tap(t, find.byKey(const ValueKey('course-text-mode')));
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_02')));
      await primary(t);
      await primary(t);
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_01')));
      await primary(t);
      await primary(t);
      await tap(t, find.byKey(const ValueKey('course-text-mode')));
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_02')));
      await primary(t);
      await primary(t);
      expect(find.byKey(const ValueKey('course-done')), findsOneWidget);
      expect(state.learning.course.completed.length, 1);
      expect(state.learning.completedLessons, isEmpty);
      expect(state.learning.totalReviews, 0);
      expect(state.learning.reviewXp, 0);
      expect(state.learning.course.memory, isEmpty);
      expect(state.learning.course.events.first['correct'], false);
      expect(state.learning.course.events.first['firstAttempt'], true);
      expect(state.learning.course.events[1]['firstAttempt'], false);
      await state.saveCourse();
      final restored = AppState();
      await restored.load();
      expect(restored.learning.course.completed.length, 1);
      expect(restored.learning.course.events.length, 3);
    },
  );

  testWidgets(
    'real completed bundled playback enables Myanmar answers and FSRS; interrupted playback cannot',
    (t) async {
      final player = _Player(wait: true);
      final state = await show(t, catalog: audio, player: player);
      await primary(t);
      await primary(t);
      final play = find.byKey(const ValueKey('course-audio-c2_u01_01'));
      await t.ensureVisible(play);
      await t.tap(play);
      await t.pump();
      expect(
        t
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('course-option-c2_u01_01')),
            )
            .onPressed,
        isNull,
      );
      player.pending!.complete();
      await t.pumpAndSettle();
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_01')));
      await primary(t);
      expect(state.learning.course.memory['c2_u01_01']!.usesFsrs, true);
      expect(state.learning.course.events.single['listened'], true);
      expect(state.learning.course.memory['c2_u01_01']!.intervalDays, 0);
      expect(state.learning.completedLessons, isEmpty);
      await primary(t);
      await state.saveCourse();
      expect(
        state.learning.course.cursors[course.units.first.lessons.first.id],
        3,
      );
      final restored = AppState();
      await restored.load();
      expect(restored.learning.course.memory.length, 1);
    },
  );

  testWidgets(
    'visible transcript remains assisted across steps and cannot grant FSRS',
    (t) async {
      final state = await show(t, catalog: audio);
      await t.tap(find.byTooltip('ထိုင်းစာ ပြ/ဖျောက်'));
      await t.pumpAndSettle();
      await primary(t);
      await primary(t);
      await tap(t, find.byKey(const ValueKey('course-audio-c2_u01_01')));
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_01')));
      await primary(t);
      expect(state.learning.course.events.single['assisted'], true);
      expect(state.learning.course.memory, isEmpty);
    },
  );

  testWidgets('rapid next taps cannot skip an introduction', (t) async {
    final state = await show(t);
    final next = t
        .widget<FilledButton>(find.byKey(const ValueKey('course-primary')))
        .onPressed!;
    next();
    next();
    await t.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    expect(
      state.learning.course.cursors[course.units.first.lessons.first.id],
      1,
    );
    expect(state.learning.course.completed, isEmpty);
  });

  testWidgets('cancelled bundled playback never unlocks a listening answer', (
    t,
  ) async {
    final state = AppState();
    await state.load();
    final player = _Player(wait: true);
    final service = ThaiPlaybackService(
      speechService: SpeechService(engine: _Silent()),
      catalog: audio,
      assetPlayer: player,
    );
    addTearDown(service.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: CourseLessonScreen(
          course: course,
          unit: course.units.first,
          lesson: course.units.first.lessons.first,
          appState: state,
          playbackService: service,
        ),
      ),
    );
    await t.pumpAndSettle();
    await primary(t);
    await primary(t);
    await t.tap(find.byKey(const ValueKey('course-audio-c2_u01_01')));
    await t.pump();
    await service.stop();
    await t.pumpAndSettle();
    expect(
      t
          .widget<OutlinedButton>(
            find.byKey(const ValueKey('course-option-c2_u01_01')),
          )
          .onPressed,
      isNull,
    );
    expect(state.learning.course.memory, isEmpty);
  });

  testWidgets(
    'new named models stay audio-pending and aided construction works at 2x text',
    (t) async {
      t.view.physicalSize = const Size(320, 760);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      t.view.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.platformDispatcher.clearTextScaleFactorTestValue);
      final state = await show(t, lesson: 1, catalog: audio);
      expect(find.text('အသံထည့်ရန် ကျန်'), findsOneWidget);
      await primary(t);
      final model = course.lines['c2_u01_03']!;
      for (var i = 0; i < model.parts('female').length; i++) {
        await tap(t, find.byKey(ValueKey('course-part-$i')));
      }
      await primary(t);
      await primary(t);
      expect(state.learning.course.completed.length, 1);
      expect(state.learning.course.memory, isEmpty);
      expect(state.learning.course.events.single['kind'], 'build');
      expect(state.learning.course.events.single['assisted'], true);
      expect(t.takeException(), isNull);
    },
  );
}

class _Player implements ThaiAudioAssetPlayer {
  _Player({this.wait = false});
  final bool wait;
  Completer<void>? pending;
  @override
  Future<void> play(
    String assetPath, {
    required void Function() onStarted,
  }) async {
    onStarted();
    if (wait) {
      pending = Completer<void>();
      await pending!.future;
    }
  }

  @override
  Future<void> stop() async {
    if (pending != null && !pending!.isCompleted) pending!.complete();
  }

  @override
  Future<void> dispose() async => stop();
}

class _Silent implements SpeechEngine {
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
