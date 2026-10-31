import 'dart:math';

import '../data/phrase_repository.dart';
import '../models/phrase.dart';
import 'learning_progress.dart';

class StudyLesson {
  const StudyLesson({
    required this.id,
    required this.category,
    required this.number,
    required this.phrases,
  });
  final String id;
  final PhraseCategory category;
  final int number;
  final List<Phrase> phrases;
}

class TodayStudyPlan {
  const TodayStudyPlan({required this.phrases, required this.reviewCount});

  final List<Phrase> phrases;
  final int reviewCount;
  int get newCount => phrases.length - reviewCount;
}

class StudyCatalog {
  /// A small, predictable deck: overdue flashcards first, then new everyday
  /// phrases in lesson order. Unreviewed cards are not counted as overdue.
  static TodayStudyPlan todayPlan(
    PhraseRepository repository,
    LearningProgress progress,
    DateTime now, {
    int limit = 5,
  }) {
    final reviewedDue =
        repository.phrases.where((phrase) {
          final card = progress.cardFor(phrase.id, LearningMode.flashcard);
          return card != null && card.isDue(now);
        }).toList()..sort((a, b) {
          final left = progress.cardFor(a.id, LearningMode.flashcard)!;
          final right = progress.cardFor(b.id, LearningMode.flashcard)!;
          final comparison = left.due.compareTo(right.due);
          return comparison != 0 ? comparison : a.id.compareTo(b.id);
        });
    final selected = reviewedDue.take(limit).toList();
    final reviewCount = selected.length;
    for (final phrase in repository.phrases) {
      if (selected.length >= limit) break;
      if (phrase.tags.contains('high-risk') ||
          phrase.tags.contains('emergency') ||
          progress.cardFor(phrase.id, LearningMode.flashcard) != null) {
        continue;
      }
      selected.add(phrase);
    }
    return TodayStudyPlan(phrases: selected, reviewCount: reviewCount);
  }

  static List<StudyLesson> lessons(PhraseRepository repository) {
    final result = <StudyLesson>[];
    for (final category in repository.categories) {
      final phrases = repository.inCategory(category.id);
      for (var offset = 0; offset < phrases.length; offset += 5) {
        final group = phrases.skip(offset).take(5).toList(growable: false);
        result.add(
          StudyLesson(
            id: '${category.id}:${group.first.id}',
            category: category,
            number: offset ~/ 5 + 1,
            phrases: group,
          ),
        );
      }
    }
    return result;
  }

  static List<Phrase> select(
    List<Phrase> phrases,
    LearningProgress progress,
    LearningMode mode,
    ReviewFilter filter,
    Set<String> favorites,
    DateTime now, {
    int limit = 10,
    Random? random,
  }) {
    final pool = phrases.where((phrase) {
      final card = progress.cardFor(phrase.id, mode);
      return switch (filter) {
        ReviewFilter.due => progress.isDue(phrase.id, mode, now),
        ReviewFilter.fresh => card == null,
        ReviewFilter.difficult => card != null && card.lastQuality < 4,
        ReviewFilter.favorites => favorites.contains(phrase.id),
        ReviewFilter.all => true,
      };
    }).toList();
    if (filter == ReviewFilter.due) {
      // Revisit due mistakes before introducing new cards.
      pool.sort((a, b) {
        final ca = progress.cardFor(a.id, mode);
        final cb = progress.cardFor(b.id, mode);
        if (ca == null && cb != null) return 1;
        if (ca != null && cb == null) return -1;
        return ca == null ? a.id.compareTo(b.id) : ca.due.compareTo(cb!.due);
      });
    } else {
      pool.shuffle(random ?? Random());
    }
    return pool.take(limit).toList(growable: false);
  }
}
