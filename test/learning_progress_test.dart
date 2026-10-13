import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/learning/review_card.dart';

void main() {
  test('successful reviews advance intervals, failure resets them', () {
    final day = DateTime(2026, 10, 13);
    final first = ReviewCard.initial(day).review(5, day);
    final second = first.review(5, DateTime(2026, 10, 14));
    final third = second.review(5, DateTime(2026, 10, 20));
    expect(first.intervalDays, 1);
    expect(second.intervalDays, 6);
    expect(third.intervalDays, greaterThan(6));
    final failed = third.review(2, DateTime(2026, 11, 5));
    expect(failed.repetitions, 0);
    expect(failed.intervalDays, 1);
    expect(failed.due, DateTime(2026, 11, 6));
    expect(() => first.review(6, day), throwsArgumentError);
  });
  test('streak allows yesterday but breaks after a missed day', () {
    final p = LearningProgress();
    p.record('hello', LearningMode.meaning, 5, DateTime(2026, 10, 11));
    p.record('hello', LearningMode.meaning, 5, DateTime(2026, 10, 12));
    expect(p.streak(DateTime(2026, 10, 13)), 2);
    expect(p.streak(DateTime(2026, 10, 14)), 0);
    p.record('hello', LearningMode.meaning, 2, DateTime(2026, 10, 13));
    expect(p.streak(DateTime(2026, 10, 13)), 3);
    expect(p.correctReviews, 2);
    expect(p.totalReviews, 3);
  });
  test('different learning modes persist independently', () {
    final p = LearningProgress();
    final now = DateTime(2026, 10, 13);
    p.record('hello', LearningMode.meaning, 5, now);
    p.record('hello', LearningMode.listening, 2, now);
    p.dailyGoal = 20;
    p.onboardingComplete = true;
    p.finishSession(lessonId: 'greetings:greet_hello');
    final restored = LearningProgress.fromJson(p.toJson());
    expect(restored.cardFor('hello', LearningMode.meaning)!.lastQuality, 5);
    expect(restored.cardFor('hello', LearningMode.listening)!.lastQuality, 2);
    expect(restored.reviewedPhraseIds, {'hello'});
    expect(restored.completedLessons, {'greetings:greet_hello'});
    expect(restored.reviewsOn(now), 2);
    expect(restored.dailyGoal, 20);
    expect(restored.onboardingComplete, isTrue);
  });
  test('one damaged card does not erase intact learning history', () {
    final p = LearningProgress();
    p.record('hello', LearningMode.meaning, 5, DateTime(2026, 10, 13));
    final json = p.toJson();
    final cards = json['cards'] as Map;
    cards['bad::meaning'] = {'ease': 'broken'};
    final restored = LearningProgress.fromJson(json);
    expect(restored.cardFor('hello', LearningMode.meaning), isNotNull);
    expect(restored.cardFor('bad', LearningMode.meaning), isNull);
  });
}
