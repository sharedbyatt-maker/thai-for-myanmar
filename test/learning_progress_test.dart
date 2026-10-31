import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/learning/review_card.dart';

void main() {
  test(
    'FSRS advances successful reviews and relearns failures within minutes',
    () {
      final day = DateTime(2026, 10, 13);
      final first = ReviewCard.initial(day).review(5, day);
      final second = first.review(5, first.due);
      final third = second.review(5, second.due);
      expect(first.usesFsrs, isTrue);
      expect(first.intervalDays, greaterThan(1));
      expect(second.intervalDays, greaterThan(first.intervalDays));
      expect(third.intervalDays, greaterThan(second.intervalDays));
      final failed = third.review(2, third.due);
      expect(failed.repetitions, 0);
      expect(failed.intervalDays, 0);
      expect(failed.due, third.due.add(const Duration(minutes: 10)));
      expect(() => first.review(6, day), throwsArgumentError);
    },
  );
  test('legacy due dates and counters survive until a real FSRS review', () {
    final due = DateTime(2026, 11, 4);
    final card = ReviewCard.fromJson({
      'repetitions': 7,
      'ease': 2.8,
      'intervalDays': 30,
      'due': due.toIso8601String(),
      'lastQuality': 4,
    });
    expect(card.due, due);
    expect(card.repetitions, 7);
    expect(card.usesFsrs, isFalse);
    expect(card.reviewLog, isEmpty);
    expect(card.isDue(due.subtract(const Duration(seconds: 1))), isFalse);
    final next = card.review(4, due);
    expect(next.repetitions, 8);
    expect(next.usesFsrs, isTrue);
    expect(next.reviewLog, hasLength(1));
  });
  test(
    'minute due times compare instants across time zones and survive JSON',
    () {
      final now = DateTime.parse('2026-10-31T12:00:00+07:00');
      final p = LearningProgress()
        ..record('hello', LearningMode.flashcard, 2, now);
      final card = p.cardFor('hello', LearningMode.flashcard)!;
      expect(card.due, now.toUtc().add(const Duration(minutes: 1)));
      expect(p.isDue('hello', LearningMode.flashcard, now), isFalse);
      final restored = LearningProgress.fromJson(p.toJson());
      expect(restored.isDue('hello', LearningMode.flashcard, card.due), isTrue);
      final copy = restored.cardFor('hello', LearningMode.flashcard)!;
      expect(copy.usesFsrs, isTrue);
      expect(
        copy.review(4, copy.due).toJson(),
        card.review(4, card.due).toJson(),
      );
    },
  );
  test('corrupt optional FSRS memory falls back without deleting the card', () {
    final card = ReviewCard.initial(
      DateTime.utc(2026, 10, 31),
    ).review(5, DateTime.utc(2026, 10, 31));
    final json = card.toJson();
    json['fsrs'] = {
      ...(json['fsrs'] as Map).cast<String, dynamic>(),
      'difficulty': double.nan,
    };
    final restored = ReviewCard.fromJson(json);
    expect(restored.due, card.due);
    expect(restored.usesFsrs, isFalse);
    expect(restored.repetitions, card.repetitions);
  });
  test('logs are bounded and device clock regression remains usable', () {
    var now = DateTime.utc(2026, 10, 31);
    var card = ReviewCard.initial(now);
    for (var i = 0; i < 20; i++) {
      card = card.review(4, now);
      now = now.add(const Duration(minutes: 10));
    }
    expect(card.reviewLog, hasLength(8));
    final next = card.review(4, DateTime.utc(2026, 10, 30));
    expect(next.due.isAfter(now.subtract(const Duration(minutes: 10))), isTrue);
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
