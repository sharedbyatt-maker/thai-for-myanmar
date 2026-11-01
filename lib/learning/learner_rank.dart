import '../data/phrase_repository.dart';
import 'learning_progress.dart';
import 'study_catalog.dart';
import 'course_progress.dart';

/// Ranks reflect completed lessons, never language proficiency certification.
class LearnerRank {
  LearnerRank(PhraseRepository repository, LearningProgress progress)
    : _progress = progress {
    final ids = StudyCatalog.lessons(repository).map((l) => l.id).toSet();
    _legacyIds = ids;
    _courseIds =
        repository.course?.units
            .expand((u) => u.lessons)
            .map((l) => l.id)
            .toSet() ??
        {};
    completed =
        progress.completedLessons.intersection(ids).length +
        progress.course.completed.keys.toSet().intersection(_courseIds).length;
    xp = completed * CourseProgress.lessonXp + progress.reviewXp;
  }
  final LearningProgress _progress;
  late final Set<String> _legacyIds, _courseIds;
  int xpOn(DateTime date) {
    final key = dayKey(date);
    final legacy = _progress.completedLessons
        .intersection(_legacyIds)
        .where((id) => _progress.firstLessonDay(id) == key)
        .length;
    final course = _progress.course.completed.entries
        .where(
          (e) => _courseIds.contains(e.key) && dayKey(e.value.toLocal()) == key,
        )
        .length;
    return (legacy + course) * CourseProgress.lessonXp +
        _progress.reviewXpOn(date);
  }

  late final int completed;
  late final int xp;
  static const thresholds = [0, 5, 15, 30, 60, 112];
  static const names = [
    'စတင်သူ',
    'ထိုင်းစကားမိတ်ဆွေ',
    'ပြောရဲသူ',
    'နေ့စဉ်ဘဝလေ့လာသူ',
    'ကြိုးစားသူ',
    'လမ်းကြောင်းအောင်မြင်သူ',
  ];
  static const symbols = ['🌱', '🐘', '🗣️', '🧭', '⭐', '👑'];
  int get level => thresholds.lastIndexWhere((n) => completed >= n);
  bool get isMax => level == thresholds.length - 1;
  String get name => names[level];
  int get remaining => isMax ? 0 : thresholds[level + 1] - completed;
  double get fraction => isMax
      ? 1
      : (completed - thresholds[level]) /
            (thresholds[level + 1] - thresholds[level]);
}
