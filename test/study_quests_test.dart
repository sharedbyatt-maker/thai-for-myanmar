import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';
import 'package:thai_for_myanmar/learning/study_quests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;
  setUpAll(() async => repository = await PhraseRepository.load(rootBundle));

  test(
    'new and legacy histories do not fabricate dated lesson completions',
    () {
      final p = LearningProgress.fromJson({
        'schemaVersion': 1,
        'completedLessons': [StudyCatalog.lessons(repository).first.id],
      });
      final q = StudyQuests(repository, p, DateTime(2026, 10, 30));
      expect(q.daily.map((q) => q.current), [0, 0, 0]);
      expect(q.weekly.current, 0);
      expect(q.monthly.current, 0);
      expect(q.earnedMonths, isEmpty);
    },
  );

  test(
    'one lesson counts once per day and persists without duplicating XP',
    () {
      final id = StudyCatalog.lessons(repository).first.id;
      final p = LearningProgress();
      final day = DateTime(2026, 10, 30);
      p.finishSession(lessonId: id, now: day);
      p.finishSession(lessonId: id, now: day);
      p.finishSession(lessonId: 'unknown', now: day);
      final restored = LearningProgress.fromJson(p.toJson());
      expect(StudyQuests(repository, restored, day).daily.last.current, 1);
      expect(
        StudyQuests(
          repository,
          restored,
          DateTime(2026, 10, 31),
        ).daily.last.current,
        0,
      );
      expect(restored.completedLessons, {id, 'unknown'});
      expect(restored.reviewXp, 0);
    },
  );

  test(
    'daily XP goal uses unique successful reviews rather than tap totals',
    () {
      final p = LearningProgress();
      final now = DateTime(2026, 10, 30);
      for (var i = 0; i < 8; i++) {
        p.record('same', LearningMode.meaning, 5, now);
      }
      final q = StudyQuests(repository, p, now);
      expect(q.daily.first.complete, isTrue);
      expect(q.daily.first.shown, 5);
      expect(q.daily[1].current, 5);
      expect(q.daily[1].complete, isFalse);
    },
  );

  test(
    'weekly and monthly activity respect boundaries and ignore future days',
    () {
      final p = LearningProgress();
      for (final d in [
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 30),
        DateTime(2026, 10, 31),
        DateTime(2026, 11, 1),
      ]) {
        p.record('hello', LearningMode.meaning, 5, d);
      }
      final q = StudyQuests(repository, p, DateTime(2026, 10, 30));
      expect(q.weekly.current, 2);
      expect(q.monthly.current, 3);
      final november = StudyQuests(repository, p, DateTime(2026, 11, 2));
      expect(november.weekly.current, 0);
      expect(november.monthly.current, 1);
    },
  );

  test(
    'monthly badge requires twelve actual days and survives serialization',
    () {
      final p = LearningProgress();
      for (var i = 1; i <= 12; i++) {
        p.record('hello', LearningMode.flashcard, 2, DateTime(2026, 10, i));
      }
      expect(
        StudyQuests(repository, p, DateTime(2026, 10, 11)).earnedMonths,
        isEmpty,
      );
      final q = StudyQuests(
        repository,
        LearningProgress.fromJson(p.toJson()),
        DateTime(2026, 11, 1),
      );
      expect(q.earnedMonths, ['2026-10']);
      expect(q.monthly.current, 0);
    },
  );
}
