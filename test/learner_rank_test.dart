import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/learner_rank.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all rank boundaries, replay and unknown lessons', () async {
    final repo = await PhraseRepository.load(rootBundle);
    final p = LearningProgress();
    final lessons = StudyCatalog.lessons(repo);
    expect(lessons.length, 112);
    p.finishSession(lessonId: 'unknown');
    expect(LearnerRank(repo, p).completed, 0);
    for (var i = 0; i <= lessons.length; i++) {
      final rank = LearnerRank(repo, p);
      expect(rank.level, LearnerRank.thresholds.lastIndexWhere((n) => i >= n));
      expect(rank.xp, i * 20);
      expect(rank.fraction, inInclusiveRange(0, 1));
      if (i < lessons.length) {
        p.finishSession(lessonId: lessons[i].id);
        p.finishSession(lessonId: lessons[i].id);
      }
    }
    expect(LearnerRank(repo, p).isMax, isTrue);
  });
  test('XP is unique per phrase per day, successful only and capped at 50', () {
    final p = LearningProgress();
    final day = DateTime(2026, 10, 30);
    p.record('failed', LearningMode.meaning, 2, day);
    expect(p.reviewXp, 0);
    for (var i = 0; i < 12; i++) {
      p.record('p$i', LearningMode.meaning, 5, day);
      p.record('p$i', LearningMode.listening, 5, day);
    }
    expect(p.reviewXp, 50);
    p.record('p0', LearningMode.meaning, 5, day.add(const Duration(days: 1)));
    expect(p.reviewXp, 55);
    final restored = LearningProgress.fromJson(p.toJson());
    expect(restored.reviewXp, 55);
    restored.record('p0', LearningMode.meaning, 5, day);
    expect(restored.reviewXp, 55);
  });
  test('legacy progress keeps lessons without inventing review XP', () {
    final p = LearningProgress.fromJson({
      'schemaVersion': 1,
      'completedLessons': ['lesson1'],
      'correctReviews': 8,
      'totalReviews': 10,
    });
    p.finishSession(lessonId: 'lesson1');
    expect(p.completedLessons.length, 1);
    expect(p.reviewXp, 0);
  });
}
