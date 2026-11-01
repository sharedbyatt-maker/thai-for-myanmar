import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/course_progress.dart';
import 'package:thai_for_myanmar/learning/learner_rank.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';
import 'package:thai_for_myanmar/learning/study_quests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repo;
  setUpAll(() async => repo = await PhraseRepository.load(rootBundle));

  test(
    'course rewards combine with existing XP exactly once, ignoring unknown IDs',
    () {
      final p = LearningProgress();
      final date = DateTime(2026, 11, 1);
      final legacy = StudyCatalog.lessons(repo).first.id;
      final course = repo.course!.units.first.lessons.first.id;
      p.record('greet_hello', LearningMode.flashcard, 4, date);
      p.finishSession(lessonId: legacy, now: date);
      expect(LearnerRank(repo, p).xp, 25);
      p.course.finish(course, date);
      p.course.finish(course, date);
      p.course.finish('unknown', date);
      expect(LearnerRank(repo, p).xp, 45);
      expect(LearnerRank(repo, p).completed, 2);
      final copy = LearningProgress.fromJson(p.toJson());
      expect(LearnerRank(repo, copy).xp, 45);
      expect(copy.completedLessons, {legacy});
      expect(copy.totalReviews, 1);
      expect(copy.course.memory, isEmpty);
    },
  );

  test(
    'replay earns no new XP but retains its practice day and lesson quest',
    () {
      final p = LearningProgress();
      final id = repo.course!.units.first.lessons.first.id;
      final first = DateTime(2026, 10, 31);
      final next = DateTime(2026, 11, 1);
      p.course.finish(id, first);
      p.course.finish(id, next);
      p.course.finish(id, next);
      final rank = LearnerRank(repo, p);
      expect(rank.xp, 20);
      expect(rank.xpOn(first), 20);
      expect(rank.xpOn(next), 0);
      expect(p.practiceOn(next), 1);
      expect(p.streak(next), 2);
      expect(StudyQuests(repo, p, next).daily.last.current, 1);
      expect(StudyQuests(repo, p, next).daily[1].current, 0);
    },
  );

  test(
    'actual successful practice survives bounded events without counting completion twice',
    () {
      final p = LearningProgress();
      final id = repo.course!.units.first.lessons.first.id;
      final date = DateTime(2026, 11, 1);
      p.course.recordPractice(id, 'hello', 'choice', date);
      p.course.recordPractice(id, 'hello', 'choice', date);
      p.course.recordPractice(id, 'thanks', 'choice', date);
      p.course.finish(id, date);
      expect(p.practiceOn(date), 2);
      for (var i = 0; i < 650; i++) {
        p.course.event({
          'lesson': id,
          'line': 'x',
          'kind': 'choice',
          'at': date.toIso8601String(),
        });
      }
      final copy = LearningProgress.fromJson(p.toJson());
      expect(copy.course.events.length, 600);
      expect(copy.practiceOn(date), 2);
      expect(copy.streak(date), 1);
      expect(copy.totalReviews, 0);
      expect(copy.reviewXp, 0);
      expect(copy.course.memory, isEmpty);
      expect(StudyQuests(repo, copy, date).daily[1].current, 20);
    },
  );

  test(
    'existing dated course completions recover XP and activity without losing legacy progress',
    () {
      final p = LearningProgress();
      final date = DateTime(2026, 11, 1);
      final id = repo.course!.units.first.lessons.first.id;
      p.record('old', LearningMode.meaning, 4, date);
      final raw = p.toJson();
      raw['courseV2'] = {
        'version': 1,
        'completed': {id: date.toUtc().toIso8601String()},
      };
      final copy = LearningProgress.fromJson(raw);
      expect(LearnerRank(repo, copy).xp, 25);
      expect(copy.practiceOn(date), 2);
      expect(copy.totalReviews, 1);
      expect(copy.course.completed.keys, [id]);
      expect(
        LearnerRank(repo, LearningProgress.fromJson(copy.toJson())).xp,
        25,
      );
    },
  );

  test(
    'legacy replay does not fabricate a second daily completion XP award',
    () {
      final p = LearningProgress();
      final id = StudyCatalog.lessons(repo).first.id;
      final day = DateTime(2026, 10, 31);
      final next = DateTime(2026, 11, 1);
      p.finishSession(lessonId: id, now: day);
      p.finishSession(lessonId: id, now: next);
      expect(LearnerRank(repo, p).xpOn(day), 20);
      expect(LearnerRank(repo, p).xpOn(next), 0);
      expect(LearnerRank(repo, p).xp, 20);
    },
  );

  test('malformed optional activity does not erase existing completions', () {
    final p = CourseProgress.fromJson({
      'version': 1,
      'completed': {'known': '2026-11-01T00:00:00Z'},
      'activity': {
        'broken': ['check|x'],
        '2026-11-01': [null, 9, 'invalid', 'check|l|choice|x'],
      },
    });
    expect(p.completed, contains('known'));
    expect(p.practiceOn(DateTime(2026, 11, 1)), 1);
  });
}
