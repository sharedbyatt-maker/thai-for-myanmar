import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/course_catalog.dart';
import 'package:thai_for_myanmar/learning/course_insights.dart';
import 'package:thai_for_myanmar/learning/course_progress.dart';
import 'package:thai_for_myanmar/learning/review_card.dart';
import 'package:thai_for_myanmar/screens/quests_screen.dart';
import 'package:thai_for_myanmar/services/app_state.dart';
import 'package:thai_for_myanmar/widgets/course_outcomes.dart';

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
    'outcomes require all lessons and never turn a probe or XP into mastery',
    () {
      final p = CourseProgress();
      final now = DateTime(2026, 11, 1);
      final unit = course.units.first;
      p.finish(unit.lessons.last.id, now);
      p.probeStages[unit.id] = 1;
      var info = CourseInsights(course, p, now);
      expect(info.practicedUnits, isEmpty);
      expect(info.delayedUnits, 0);
      for (final l in unit.lessons) {
        p.finish(l.id, now);
      }
      final before = p.toJson().toString();
      info = CourseInsights(course, p, now.add(const Duration(days: 7)));
      expect(info.practicedUnits.map((u) => u.id), [unit.id]);
      expect(info.delayedUnits, 1);
      expect(info.completedIn(unit), unit.lessons.length);
      expect(info.unitStatus(unit), contains('၁ ကြိမ်'));
      expect(p.toJson().toString(), before);
      expect(p.memory, isEmpty);
    },
  );

  test(
    'review cue uses known due cards and real delayed probes after reload',
    () {
      final p = CourseProgress();
      final now = DateTime.utc(2026, 11, 1);
      final unit = course.units.first;
      for (final l in unit.lessons) {
        p.finish(l.id, now);
      }
      p.memory[course.lines.keys.first] = ReviewCard.initial(now);
      p.memory['unknown'] = ReviewCard.initial(now);
      p.memory[course.lines.keys.last] = ReviewCard.initial(
        now.add(const Duration(days: 30)),
      );
      final copy = CourseProgress.fromJson(p.toJson());
      expect(CourseInsights(course, copy, now).dueItems, 1);
      expect(
        CourseInsights(course, copy, now.add(const Duration(days: 1))).dueItems,
        2,
      );
      copy.probeStages[unit.id] = 2;
      expect(
        CourseInsights(course, copy, now.add(const Duration(days: 8))).dueItems,
        1,
      );
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'outcomes stay honest and readable at 320px 2x text dark=$dark',
      (t) async {
        t.view.physicalSize = const Size(320, 760);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final p = CourseProgress();
        final now = DateTime.now();
        for (final l in course.units.first.lessons) {
          p.finish(l.id, now);
        }
        p.probeStages[course.units.first.id] = 1;
        await t.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: CourseOutcomes(
                    insights: CourseInsights(course, p, now),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.ensureVisible(
          find.byKey(const ValueKey('course-practiced-topics')),
        );
        await t.tap(find.byKey(const ValueKey('course-practiced-topics')));
        await t.pumpAndSettle();
        expect(find.text(course.units.first.goal), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'quest completion summary follows real activity and creates no reward',
    (t) async {
      final state = AppState();
      await state.load();
      final now = DateTime.now();
      final lesson = course.units.first.lessons.first.id;
      for (var i = 0; i < 5; i++) {
        state.learning.course.recordPractice(lesson, 'line$i', 'build', now);
      }
      state.learning.course.finish(lesson, now);
      final before = state.learning.toJson().toString();
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuestsScreen(
              repository: repo,
              appState: state,
              clock: () => now,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('daily-quest-summary')),
        250,
      );
      expect(find.text('ဒီနေ့ 3 / 3 ပြီး'), findsOneWidget);
      expect(state.learning.toJson().toString(), before);
      expect(state.learning.reviewXp, 0);
      await t.pumpWidget(const SizedBox());
    },
  );
}
