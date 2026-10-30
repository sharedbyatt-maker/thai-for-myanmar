import '../data/phrase_repository.dart';
import 'learning_progress.dart';
import 'study_catalog.dart';

/// Ranks reflect completed lessons, never language proficiency certification.
class LearnerRank {
  LearnerRank(PhraseRepository repository, LearningProgress progress) {
    final ids = StudyCatalog.lessons(repository).map((l) => l.id).toSet();
    completed = progress.completedLessons.intersection(ids).length;
    xp = completed * 20 + progress.reviewXp;
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
