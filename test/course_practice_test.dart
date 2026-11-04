import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/course_catalog.dart';
import 'package:thai_for_myanmar/learning/course_progress.dart';
import 'package:thai_for_myanmar/learning/course_practice.dart';
import 'package:thai_for_myanmar/learning/learner_rank.dart';
import 'package:thai_for_myanmar/learning/unit_one_practice.dart';
import 'package:thai_for_myanmar/screens/course_lesson_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/services/speech_service.dart';
import 'package:thai_for_myanmar/services/thai_audio_catalog.dart';
import 'package:thai_for_myanmar/services/thai_playback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repo;
  late CourseCatalog course;
  setUpAll(() async {
    repo = await PhraseRepository.load(rootBundle);
    course = repo.course!;
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'only Units 2–5 change; authored content, Unit 1, later units and all old cursors survive',
    () {
      final before = jsonEncode(course.units.map((u) => u.data).toList());
      var changed = 0;
      for (final unit in course.units) {
        for (final lesson in unit.lessons) {
          final steps = CoursePractice.steps(unit, lesson);
          if (unit.id == 'u01' || int.parse(unit.id.substring(1)) > 5) {
            expect(steps, UnitOnePractice.steps(unit, lesson));
            continue;
          }
          changed++;
          expect(steps.map((s) => s['pilotKey']).toSet().length, steps.length);
          for (var base = 0; base < lesson.steps.length; base++) {
            final saved =
                steps[CoursePractice.resumeIndex(steps, base, 'stale')];
            expect(saved['baseIndex'], base);
            expect(saved['original'], true);
            expect(
              saved['kind'],
              lesson.steps[base]['kind'] == 'dialogue'
                  ? 'reply'
                  : lesson.steps[base]['kind'],
            );
          }
          for (final step in steps) {
            for (final id in [
              step['line'],
              step['prompt'],
              ...List<String>.from(step['options'] as List? ?? []),
              ...List<String>.from(step['gapAlternatives'] as List? ?? []),
            ].whereType<String>()) {
              expect(course.lines.containsKey(id), true, reason: id);
            }
            if (step['kind'] == 'gap') {
              for (final style in ['male', 'female']) {
                final parts = course.lines[step['line']]!.parts(style);
                expect(step['gapIndex'], inInclusiveRange(0, parts.length - 1));
                final options = {
                  parts[step['gapIndex'] as int],
                  ...List<String>.from(step['gapAlternatives'] as List? ?? []),
                  for (final i in step['gapDistractorIndices'] as List? ?? [])
                    parts[i as int],
                };
                expect(options.length, greaterThanOrEqualTo(2));
                expect(
                  options
                      .map((id) => course.lines[id]!.myFor(style))
                      .toSet()
                      .length,
                  options.length,
                );
              }
            }
          }
        }
      }
      expect(changed, 28);
      expect(jsonEncode(course.units.map((u) => u.data).toList()), before);
    },
  );

  test(
    'new step bookmarks round trip alongside old Unit 1 data and clear on finish',
    () {
      final progress = CourseProgress();
      progress.stepBookmarks['course-v2.1:u01-l05'] =
          'u01-practice-v1:name-reply';
      for (final unit in course.units.skip(1).take(4)) {
        for (final lesson in unit.lessons) {
          final steps = CoursePractice.steps(unit, lesson);
          for (var i = 0; i < steps.length; i++) {
            expect(
              CoursePractice.resumeIndex(
                steps,
                steps[i]['baseIndex'] as int,
                steps[i]['pilotKey'] as String,
              ),
              i,
            );
          }
        }
        final id = unit.lessons[5].id;
        progress.cursors[id] = 0;
        progress.stepBookmarks[id] =
            CoursePractice.steps(unit, unit.lessons[5])[1]['pilotKey']
                as String;
      }
      final restored = CourseProgress.fromJson(
        jsonDecode(jsonEncode(progress.toJson())),
      );
      expect(restored.stepBookmarks, progress.stepBookmarks);
      final id = course.units[1].lessons[5].id;
      restored.finish(id, DateTime.now());
      expect(restored.stepBookmarks.containsKey(id), false);
      expect(restored.cursors.containsKey(id), false);
      expect(
        restored.stepBookmarks['course-v2.1:u01-l05'],
        'u01-practice-v1:name-reply',
      );
    },
  );

  Future<void> reveal(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) {
      await t.scrollUntilVisible(
        f,
        120,
        maxScrolls: 50,
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

  Future<void> next(WidgetTester t) =>
      tap(t, find.byKey(const ValueKey('course-primary')));
  Future<AppState> open(
    WidgetTester t,
    int unitIndex,
    int lessonIndex, {
    String style = 'female',
    bool dark = false,
    double scale = 1,
  }) async {
    final state = AppState();
    await state.load();
    await state.setPoliteStyle(style);
    final service = ThaiPlaybackService(
      speechService: SpeechService(engine: _Silent()),
      catalog: ThaiAudioCatalog.empty(),
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
          unit: course.units[unitIndex],
          lesson: course.units[unitIndex].lessons[lessonIndex],
          appState: state,
          playbackService: service,
        ),
      ),
    );
    await t.pumpAndSettle();
    return state;
  }

  for (var unitIndex = 1; unitIndex <= 4; unitIndex++) {
    for (final style in ['male', 'female']) {
      testWidgets(
        'Unit ${unitIndex + 1} all seven lessons complete in $style with Myanmar answers and saved XP',
        (t) async {
          final seed = AppState();
          await seed.load();
          for (final unit in course.units.take(unitIndex)) {
            for (final lesson in unit.lessons) {
              seed.learning.course.finish(lesson.id, DateTime.now());
            }
          }
          final baseline = LearnerRank(repo, seed.learning).xp;
          await seed.saveCourse();
          final unit = course.units[unitIndex];
          for (var li = 0; li < unit.lessons.length; li++) {
            await t.pumpWidget(const SizedBox());
            await t.pumpAndSettle();
            final state = await open(t, unitIndex, li, style: style);
            for (final step in CoursePractice.steps(unit, unit.lessons[li])) {
              final kind = step['kind'];
              final line = course.lines[step['line']];
              if (['choice', 'reply', 'situation'].contains(kind)) {
                final answer = find.byKey(
                  ValueKey('course-option-${line!.id}'),
                );
                await reveal(t, answer);
                if (kind != 'situation') {
                  expect(t.widget<OutlinedButton>(answer).onPressed, isNull);
                  await tap(t, find.byKey(const ValueKey('course-text-mode')));
                }
                await reveal(t, answer);
                expect(
                  (t.widget<OutlinedButton>(answer).child as Text).data,
                  line.myFor(style),
                );
                if (step['wordPractice'] == true) {
                  expect(
                    find.byType(OutlinedButton).evaluate().length,
                    greaterThanOrEqualTo(2),
                  );
                }
                await tap(t, answer);
                await next(t);
                await next(t);
              } else if (kind == 'gap') {
                await tap(
                  t,
                  find.byKey(
                    ValueKey(
                      'course-option-${line!.parts(style)[step['gapIndex'] as int]}',
                    ),
                  ),
                );
                await next(t);
                await next(t);
              } else if (kind == 'build') {
                for (var i = 0; i < line!.parts(style).length; i++) {
                  await tap(t, find.byKey(ValueKey('course-part-$i')));
                }
                await next(t);
                await next(t);
              } else {
                if (kind == 'reflect') {
                  await reveal(
                    t,
                    find.byKey(const ValueKey('course-unit-reflection-help')),
                  );
                }
                await next(t);
              }
            }
            expect(find.text('+20 XP'), findsOneWidget);
            expect(
              LearnerRank(repo, state.learning).xp,
              baseline + (li + 1) * 20,
            );
            expect(state.learning.course.memory, isEmpty);
            expect(state.learning.course.stepBookmarks, isEmpty);
            expect(t.takeException(), isNull);
          }
          final restored = AppState();
          await restored.load();
          expect(LearnerRank(repo, restored.learning).xp, baseline + 140);
          expect(
            restored.learning.course.events.every(
              (e) => e['assisted'] == true && e['listened'] == false,
            ),
            true,
          );
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'new situation wrong/retry, resume and feedback at 320px 2x dark=$dark',
      (t) async {
        t.view.physicalSize = const Size(320, 760);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final unit = course.units[4], lesson = unit.lessons.last;
        final steps = CoursePractice.steps(unit, lesson);
        final index = steps.indexWhere((s) => s['kind'] == 'situation');
        final seed = AppState();
        await seed.load();
        seed.learning.course.cursors[lesson.id] =
            steps[index]['baseIndex'] as int;
        seed.learning.course.stepBookmarks[lesson.id] =
            steps[index]['pilotKey'] as String;
        await seed.saveCourse();
        final state = await open(t, 4, 6, dark: dark, scale: 2);
        expect(find.text('${index + 1} / ${steps.length}'), findsOneWidget);
        await tap(t, find.byKey(ValueKey('course-option-${unit.models[1]}')));
        await next(t);
        expect(state.learning.course.events.single['correct'], false);
        await next(t);
        await tap(t, find.byKey(ValueKey('course-option-${unit.models[4]}')));
        await next(t);
        expect(state.learning.course.events.last['firstAttempt'], false);
        expect(state.learning.course.memory, isEmpty);
        expect(
          state.learning.course.events.every(
            (e) => e['listened'] == false && e['assisted'] == true,
          ),
          true,
        );
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
  Future<void> play(String path, {required void Function() onStarted}) async {
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
