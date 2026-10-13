import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thai_for_myanmar/data/phrase_repository.dart';
import 'package:thai_for_myanmar/learning/learning_progress.dart';
import 'package:thai_for_myanmar/learning/sentence_chunks.dart';
import 'package:thai_for_myanmar/learning/study_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PhraseRepository repository;
  setUpAll(() async => repository = await PhraseRepository.load(rootBundle));

  test(
    'the adapted scheduler license is included in the application bundle',
    () async {
      final license = await rootBundle.loadString(
        'third_party/licenses/pouple_tim_mit.txt',
      );
      expect(license, contains('Copyright (c) 2026 Timousss'));
      expect(license, contains('MIT License'));
    },
  );
  test('lessons cover every phrase once in groups of at most five', () {
    final lessons = StudyCatalog.lessons(repository);
    final ids = lessons.expand((l) => l.phrases).map((p) => p.id).toList();
    expect(ids.length, repository.phrases.length);
    expect(ids.toSet().length, ids.length);
    expect(
      lessons.every((l) => l.phrases.isNotEmpty && l.phrases.length <= 5),
      isTrue,
    );
    expect(lessons.map((l) => l.id).toSet().length, lessons.length);
  });
  test('due mistakes precede new cards and modes have separate filters', () {
    final now = DateTime(2026, 10, 13);
    final p = LearningProgress();
    final phrase = repository.phrases.last;
    p.record(phrase.id, LearningMode.meaning, 2, DateTime(2026, 10, 12));
    final due = StudyCatalog.select(
      repository.phrases,
      p,
      LearningMode.meaning,
      ReviewFilter.due,
      {},
      now,
    );
    expect(due.first.id, phrase.id);
    final hard = StudyCatalog.select(
      repository.phrases,
      p,
      LearningMode.meaning,
      ReviewFilter.difficult,
      {},
      now,
    );
    expect(hard.map((p) => p.id), [phrase.id]);
    expect(
      StudyCatalog.select(
        repository.phrases,
        p,
        LearningMode.listening,
        ReviewFilter.difficult,
        {},
        now,
      ),
      isEmpty,
    );
    expect(
      StudyCatalog.select(
        repository.phrases,
        p,
        LearningMode.meaning,
        ReviewFilter.favorites,
        {phrase.id},
        now,
      ).map((p) => p.id),
      [phrase.id],
    );
  });
  test(
    'today deck prioritizes real due reviews and fills with safe new cards',
    () {
      final now = DateTime(2026, 10, 13);
      final progress = LearningProgress();
      final due = repository.phrases.last;
      final later = repository.phrases.first;
      progress.record(
        due.id,
        LearningMode.flashcard,
        2,
        DateTime(2026, 10, 12),
      );
      progress.record(later.id, LearningMode.flashcard, 5, now);

      final plan = StudyCatalog.todayPlan(repository, progress, now);
      expect(plan.phrases, hasLength(5));
      expect(plan.phrases.first.id, due.id);
      expect(plan.reviewCount, 1);
      expect(plan.newCount, 4);
      expect(
        plan.phrases.map((phrase) => phrase.id),
        isNot(contains(later.id)),
      );
      expect(plan.phrases.map((phrase) => phrase.id).toSet(), hasLength(5));
      expect(
        plan.phrases
            .skip(1)
            .every(
              (phrase) =>
                  !phrase.tags.contains('high-risk') &&
                  !phrase.tags.contains('emergency'),
            ),
        isTrue,
      );
      expect(
        StudyCatalog.todayPlan(repository, progress, now, limit: 0).phrases,
        isEmpty,
      );
    },
  );
  test('chunks reconstruct the exact Thai phrase in both polite forms', () {
    for (final style in ['male', 'female']) {
      var count = 0;
      for (final phrase in repository.phrases) {
        final chunks = sentenceChunks(phrase, style);
        if (chunks == null) continue;
        count++;
        expect(chunks.join(), phrase.thaiFor(style));
        expect(chunks.length, greaterThanOrEqualTo(3));
      }
      expect(count, 26);
    }
  });
}
