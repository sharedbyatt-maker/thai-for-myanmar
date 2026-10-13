import 'review_card.dart';

enum LearningMode {
  flashcard,
  meaning,
  reverseMeaning,
  listening,
  matching,
  sentence,
}

enum ReviewFilter { due, fresh, difficult, favorites, all }

String dayKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class LearningProgress {
  final Map<String, ReviewCard> _cards = {};
  final Map<String, int> _activity = {};
  final Set<String> _completedLessons = {};
  int dailyGoal = 10;
  int totalReviews = 0;
  int correctReviews = 0;
  int completedSessions = 0;
  bool onboardingComplete = false;

  Map<String, ReviewCard> get cards => Map.unmodifiable(_cards);
  Map<String, int> get activity => Map.unmodifiable(_activity);
  Set<String> get completedLessons => Set.unmodifiable(_completedLessons);
  Set<String> get reviewedPhraseIds =>
      _cards.keys.map((key) => key.split('::').first).toSet();

  ReviewCard? cardFor(String phraseId, LearningMode mode) =>
      _cards['$phraseId::${mode.name}'];

  int reviewsOn(DateTime date) => _activity[dayKey(date)] ?? 0;

  bool isDue(String phraseId, LearningMode mode, DateTime now) {
    final card = cardFor(phraseId, mode);
    return card == null || !card.due.isAfter(dateOnly(now));
  }

  int streak(DateTime now) {
    var date = dateOnly(now);
    if (reviewsOn(date) == 0) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var count = 0;
    while (reviewsOn(date) > 0) {
      count++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return count;
  }

  void record(String phraseId, LearningMode mode, int quality, DateTime now) {
    if (phraseId.isEmpty || phraseId.contains('::')) {
      throw ArgumentError.value(phraseId, 'phraseId');
    }
    final next = (cardFor(phraseId, mode) ?? ReviewCard.initial(now)).review(
      quality,
      now,
    );
    _cards['$phraseId::${mode.name}'] = next;
    totalReviews++;
    if (quality >= 3) correctReviews++;
    final date = dayKey(now);
    _activity[date] = (_activity[date] ?? 0) + 1;
  }

  void finishSession({String? lessonId}) {
    completedSessions++;
    if (lessonId != null) _completedLessons.add(lessonId);
  }

  Map<String, Object> toJson() => {
    'schemaVersion': 1,
    'cards': _cards.map((key, value) => MapEntry(key, value.toJson())),
    'activity': _activity,
    'completedLessons': _completedLessons.toList()..sort(),
    'dailyGoal': dailyGoal,
    'totalReviews': totalReviews,
    'correctReviews': correctReviews,
    'completedSessions': completedSessions,
    'onboardingComplete': onboardingComplete,
  };

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    final result = LearningProgress();
    if (json['schemaVersion'] != 1) return result;
    final cards = json['cards'];
    if (cards is Map) {
      for (final entry in cards.entries) {
        try {
          final key = entry.key as String;
          final pieces = key.split('::');
          if (pieces.length != 2 ||
              pieces.first.isEmpty ||
              !LearningMode.values.any((mode) => mode.name == pieces.last)) {
            continue;
          }
          result._cards[key] = ReviewCard.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        } catch (_) {
          // Keep intact cards when one persisted record is damaged.
        }
      }
    }
    final activity = json['activity'];
    if (activity is Map) {
      for (final entry in activity.entries) {
        if (entry.key is String && entry.value is int && entry.value > 0) {
          final parsed = DateTime.tryParse(entry.key as String);
          if (parsed != null && dayKey(parsed) == entry.key) {
            result._activity[entry.key as String] = entry.value as int;
          }
        }
      }
    }
    final lessons = json['completedLessons'];
    if (lessons is List) {
      result._completedLessons.addAll(lessons.whereType<String>());
    }
    final goal = json['dailyGoal'];
    if (goal is int && const {5, 10, 20}.contains(goal)) {
      result.dailyGoal = goal;
    }
    int nonNegative(String key) {
      final value = json[key];
      return value is int && value >= 0 ? value : 0;
    }

    result.totalReviews = nonNegative('totalReviews');
    result.correctReviews = nonNegative(
      'correctReviews',
    ).clamp(0, result.totalReviews);
    result.completedSessions = nonNegative('completedSessions');
    result.onboardingComplete = json['onboardingComplete'] == true;
    return result;
  }

  LearningProgress();
}
