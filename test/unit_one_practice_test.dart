import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/course_catalog.dart';
import 'package:thai_for_myanmar/learning/course_progress.dart';
import 'package:thai_for_myanmar/learning/learner_rank.dart';
import 'package:thai_for_myanmar/learning/review_card.dart';
import 'package:thai_for_myanmar/learning/unit_one_practice.dart';
import 'package:thai_for_myanmar/screens/course_lesson_screen.dart';
import 'package:thai_for_myanmar/screens/learn_screen.dart';
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

  test(
    'all six Unit 1 lessons progress; other units and authored data survive',
    () {
      final before = jsonEncode([for (final u in course.units) u.data]);
      var changed = 0;
      for (final u in course.units) {
        for (final lesson in u.lessons) {
          final steps = UnitOnePractice.steps(u, lesson);
          if (jsonEncode(steps) != jsonEncode(lesson.steps)) {
            changed++;
          } else {
            expect(steps, lesson.steps);
          }
          for (final step in steps) {
            if (step['line'] is String) {
              expect(course.lines, contains(step['line']));
            }
            if (step['prompt'] is String) {
              expect(course.lines, contains(step['prompt']));
            }
          }
        }
      }
      expect(changed, 6);
      expect(jsonEncode([for (final u in course.units) u.data]), before);
      expect(
        UnitOnePractice.steps(
          course.units.first,
          course.units.first.lessons[3],
        ).map((s) => s['kind']),
        ['notice', 'gap', 'build'],
      );
      expect(
        UnitOnePractice.steps(
          course.units.first,
          course.units.first.lessons[4],
        ).map((s) => s['kind']),
        ['reply', 'reply', 'reply'],
      );
    },
  );

  test(
    'old base cursor and new per-turn bookmark resume different correct steps',
    () {
      final lesson = course.units.first.lessons[3];
      final steps = UnitOnePractice.steps(course.units.first, lesson);
      expect(UnitOnePractice.resumeIndex(steps, 1, null), 2); // Original build.
      expect(
        UnitOnePractice.resumeIndex(steps, 1, steps[1]['pilotKey'] as String),
        1,
      );
      expect(UnitOnePractice.resumeIndex(steps, 1, 'obsolete'), 2);
      final dialogue = UnitOnePractice.steps(
        course.units.first,
        course.units.first.lessons[4],
      );
      expect(
        UnitOnePractice.resumeIndex(
          dialogue,
          0,
          dialogue[1]['pilotKey'] as String,
        ),
        1,
      );
    },
  );

  test('every legacy cursor and released pilot bookmark keeps its meaning', () {
    final unit = course.units.first;
    for (final lesson in unit.lessons) {
      final steps = UnitOnePractice.steps(unit, lesson);
      for (var base = 0; base < lesson.steps.length; base++) {
        final restored = steps[UnitOnePractice.resumeIndex(steps, base, null)];
        expect(restored['baseIndex'], base);
        expect(restored['original'], true);
        expect(
          restored['kind'],
          lesson.id.endsWith('l05') ? 'reply' : lesson.steps[base]['kind'],
        );
      }
    }
    final dialogue = UnitOnePractice.steps(unit, unit.lessons[4]);
    expect(
      dialogue[UnitOnePractice.resumeIndex(
        dialogue,
        0,
        'u01-practice-v1:name-reply',
      )]['line'],
      'c2_u01_03',
    );
    final gap = UnitOnePractice.steps(unit, unit.lessons[3]);
    expect(
      gap[UnitOnePractice.resumeIndex(
        gap,
        1,
        'u01-practice-v1:new-name-gap',
      )]['kind'],
      'gap',
    );
  });

  test(
    'optional bookmarks survive serialization, ignore damage and clear on completion',
    () {
      final p = CourseProgress();
      final id = course.units.first.lessons[4].id;
      p.completed['legacy'] = DateTime.utc(2026);
      p.cursors[id] = 0;
      p.stepBookmarks[id] = '${UnitOnePractice.revision}:name-reply';
      var copy = CourseProgress.fromJson(jsonDecode(jsonEncode(p.toJson())));
      expect(copy.stepBookmarks[id], p.stepBookmarks[id]);
      expect(copy.completed, p.completed);
      copy.finish(id, DateTime.now());
      expect(copy.stepBookmarks, isEmpty);
      final raw = p.toJson();
      raw['stepBookmarks'] = {id: 14, 'bad': 'x'};
      copy = CourseProgress.fromJson(raw);
      expect(copy.stepBookmarks, isEmpty);
      expect(copy.completed, p.completed);
      expect(copy.cursors[id], 0);
    },
  );

  Future<void> reveal(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        120,
        maxScrolls: 40,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await Scrollable.ensureVisible(t.element(f), alignment: .5);
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await reveal(t, f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> primary(WidgetTester t) =>
      tap(t, find.byKey(const ValueKey('course-primary')));
  Future<AppState> show(
    WidgetTester t,
    int lesson, {
    double scale = 1,
    bool dark = false,
    bool bundled = false,
    String? style,
  }) async {
    final state = AppState();
    await state.load();
    if (style != null) await state.setPoliteStyle(style);
    final service = ThaiPlaybackService(
      speechService: SpeechService(engine: _Silent()),
      catalog: bundled ? audio : ThaiAudioCatalog.empty(),
      assetPlayer: _Player(),
    );
    addTearDown(service.dispose);
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
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

  for (final style in ['female', 'male']) {
    testWidgets(
      'complete all six lessons in $style without Thai answer reading or invented listening credit',
      (t) async {
        final unit = course.units.first;
        AppState? state;
        for (
          var lessonIndex = 0;
          lessonIndex < unit.lessons.length;
          lessonIndex++
        ) {
          await t.pumpWidget(const SizedBox());
          await t.pumpAndSettle();
          state = await show(t, lessonIndex, style: style);
          final steps = UnitOnePractice.steps(unit, unit.lessons[lessonIndex]);
          for (final step in steps) {
            final kind = step['kind'];
            final line = course.lines[step['line']];
            if (kind == 'choice' || kind == 'reply') {
              final answer = find.byKey(ValueKey('course-option-${line!.id}'));
              await reveal(t, answer);
              expect(t.widget<OutlinedButton>(answer).onPressed, isNull);
              await tap(t, find.byKey(const ValueKey('course-text-mode')));
              await reveal(t, answer);
              // Every answer button is Myanmar, even with Thai display switched off.
              expect(t.widget<OutlinedButton>(answer).child, isA<Text>());
              expect(
                (t.widget<OutlinedButton>(answer).child as Text).data,
                line.myFor(style),
              );
              await tap(t, answer);
              await primary(t);
              await primary(t);
            } else if (kind == 'gap') {
              final part = line!.parts(style)[step['gapIndex'] as int];
              await tap(t, find.byKey(ValueKey('course-option-$part')));
              await primary(t);
              await primary(t);
            } else if (kind == 'build') {
              for (var i = 0; i < line!.parts(style).length; i++) {
                await tap(t, find.byKey(ValueKey('course-part-$i')));
              }
              await primary(t);
              await primary(t);
            } else {
              if (kind == 'reflect') {
                expect(
                  find.byKey(const ValueKey('course-reflection-help')),
                  findsOneWidget,
                );
                expect(find.byType(TextField), findsOneWidget);
              }
              await primary(t);
            }
          }
          expect(find.text('+20 XP'), findsOneWidget);
          expect(state.learning.course.completed.length, lessonIndex + 1);
          expect(LearnerRank(repo, state.learning).xp, (lessonIndex + 1) * 20);
          expect(state.learning.course.memory, isEmpty);
          expect(state.learning.course.stepBookmarks, isEmpty);
          expect(t.takeException(), isNull);
        }
        final restored = AppState();
        await restored.load();
        expect(LearnerRank(repo, restored.learning).xp, 120);
        expect(
          restored.learning.course.events.every(
            (e) => e['listened'] == false && e['assisted'] == true,
          ),
          true,
        );
      },
    );
  }

  testWidgets(
    'dialogue requires audio or explicit text, preserves first wrong attempt, and replay awards zero',
    (t) async {
      for (var pass = 0; pass < 2; pass++) {
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
        final state = await show(t, 4);
        final option = find.byKey(const ValueKey('course-option-c2_u01_01'));
        expect(t.widget<OutlinedButton>(option).onPressed, isNull);
        await tap(t, find.byKey(const ValueKey('course-text-mode')));
        if (pass == 0) {
          await tap(t, find.byKey(const ValueKey('course-option-c2_u01_02')));
          await primary(t);
          expect(
            find
                .byKey(const ValueKey('unit-one-answer-feedback'))
                .hitTestable(),
            findsOneWidget,
          );
          expect(state.learning.course.events.first['correct'], false);
          expect(state.learning.course.completed, isEmpty);
          await primary(t);
        }
        await tap(t, option);
        await primary(t);
        await primary(t);
        expect(find.text('2 / 3'), findsOneWidget);
        await tap(t, find.byKey(const ValueKey('course-text-mode')));
        await tap(t, find.byKey(const ValueKey('course-option-c2_u01_03')));
        await primary(t);
        await primary(t);
        expect(find.text('3 / 3'), findsOneWidget);
        await tap(t, find.byKey(const ValueKey('course-text-mode')));
        await tap(t, find.byKey(const ValueKey('course-option-c2_u01_02')));
        await primary(t);
        await primary(t);
        expect(find.text(pass == 0 ? '+20 XP' : '+0 XP'), findsOneWidget);
        expect(LearnerRank(repo, state.learning).xp, 20);
        expect(state.learning.course.memory, isEmpty);
        expect(
          state.learning.course.events.every((e) => e['assisted'] == true),
          true,
        );
        expect(state.learning.course.stepBookmarks, isEmpty);
        expect(state.learning.completedLessons, isEmpty);
      }
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'listened dialogue prompt cannot become target-utterance or FSRS evidence',
    (t) async {
      final state = await show(t, 4, bundled: true);
      await tap(t, find.byKey(const ValueKey('course-audio-c2_u01_01')));
      await tap(t, find.byKey(const ValueKey('course-option-c2_u01_01')));
      await primary(t);
      final event = state.learning.course.events.single;
      expect(event['prompt'], 'c2_u01_01');
      expect(event['promptListened'], true);
      expect(event['listened'], false);
      expect(event['assisted'], true);
      expect(state.learning.course.memory, isEmpty);
    },
  );

  testWidgets(
    'gap bookmark resumes exactly; old build cursor is not reinterpreted as a new exercise',
    (t) async {
      final state = await show(t, 3);
      await primary(t);
      expect(find.text('2 / 3'), findsOneWidget);
      final line = course.lines['c2_u01_05']!;
      final answer = line.parts(state.politeStyle)[2];
      expect(
        state.learning.course.cursors[course.units.first.lessons[3].id],
        1,
      );
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      final restored = await show(t, 3);
      expect(find.text('2 / 3'), findsOneWidget);
      await tap(t, find.byKey(ValueKey('course-option-$answer')));
      await primary(t);
      await primary(t);
      expect(find.text('3 / 3'), findsOneWidget);
      expect(restored.learning.course.events.single['kind'], 'gap');
      expect(restored.learning.course.events.single['assisted'], true);
      expect(restored.learning.course.memory, isEmpty);
      restored.learning.course.stepBookmarks.clear();
      await restored.saveCourse();
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await show(t, 3);
      expect(find.text('3 / 3'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'resuming turn two with base cursor zero does not prepend fresh due reviews',
    (t) async {
      final state = AppState();
      await state.load();
      final lesson = course.units.first.lessons[4];
      state.learning.course.cursors[lesson.id] = 0;
      state.learning.course.stepBookmarks[lesson.id] =
          '${UnitOnePractice.revision}:name-reply';
      state.learning.course.memory['c2_u01_01'] = ReviewCard.initial(
        DateTime.now(),
      );
      await state.saveCourse();
      final restored = await show(t, 4);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(restored.learning.course.memory.length, 1);
    },
  );

  testWidgets(
    'review cue describes a bookmarked turn as resume even when its base cursor is zero',
    (t) async {
      final state = AppState();
      await state.load();
      final lesson = course.units.first.lessons[4];
      for (final earlier in course.units.first.lessons.take(4)) {
        state.learning.course.finish(earlier.id, DateTime.now());
      }
      state.learning.course.cursors[lesson.id] = 0;
      state.learning.course.stepBookmarks[lesson.id] =
          '${UnitOnePractice.revision}:name-reply';
      state.learning.course.memory['c2_u01_01'] = ReviewCard.initial(
        DateTime.now(),
      );
      final service = ThaiPlaybackService(
        speechService: SpeechService(engine: _Silent()),
        catalog: ThaiAudioCatalog.empty(),
        assetPlayer: _Player(),
      );
      addTearDown(service.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearnScreen(
              repository: repo,
              appState: state,
              playbackService: service,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.textContaining('လက်ရှိ lesson အရင်ဆက်မယ်'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'supported feedback remains usable at 320px 2x text dark=$dark',
      (t) async {
        t.view.physicalSize = const Size(320, 760);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await show(t, 4, scale: 2, dark: dark);
        await tap(t, find.byKey(const ValueKey('course-text-mode')));
        await tap(t, find.byKey(const ValueKey('course-option-c2_u01_02')));
        await primary(t);
        expect(
          find.byKey(const ValueKey('course-primary')).hitTestable(),
          findsOneWidget,
        );
        await tap(t, find.text('ရှင်းပြချက် ကြည့်မယ်'));
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}

class _Player implements ThaiAudioAssetPlayer {
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
