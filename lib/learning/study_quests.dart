import '../data/phrase_repository.dart';
import 'learning_progress.dart';
import 'review_card.dart';
import 'study_catalog.dart';

class StudyQuest {
  const StudyQuest(this.id, this.title, this.current, this.target);
  final String id;
  final String title;
  final int current;
  final int target;
  int get shown => current.clamp(0, target);
  double get fraction => (current / target).clamp(0.0, 1.0);
  bool get complete => current >= target;
}

/// Personal goals use this device's calendar, like existing offline progress.
/// They never award competitive League points or duplicate personal XP.
class StudyQuests {
  StudyQuests(
    PhraseRepository repository,
    LearningProgress progress,
    DateTime now,
  ) {
    final today = dateOnly(now);
    final validLessons = StudyCatalog.lessons(
      repository,
    ).map((l) => l.id).toSet();
    daily = [
      StudyQuest(
        'practice',
        'စကားစု ၅ ကြိမ် လေ့ကျင့်ပါ',
        progress.reviewsOn(today),
        5,
      ),
      StudyQuest(
        'xp',
        'လေ့ကျင့်မှု XP ၂၀ မှတ် ရယူပါ',
        progress.reviewXpOn(today),
        20,
      ),
      StudyQuest(
        'lesson',
        'သင်ခန်းစာ ၁ ခု ပြီးအောင်သင်ပါ',
        progress
            .lessonsOn(today)
            .intersection(validLessons)
            .intersection(progress.completedLessons)
            .length,
        1,
      ),
    ];
    final monday = DateTime(
      today.year,
      today.month,
      today.day - today.weekday + 1,
    );
    final active = progress.activity.entries
        .where((e) => e.value > 0)
        .map((e) => DateTime.parse(e.key))
        .where((d) => !d.isAfter(today))
        .toList();
    weekly = StudyQuest(
      'week',
      'ဒီအပတ် ၃ ရက် လေ့ကျင့်ပါ',
      active.where((d) => !d.isBefore(monday)).length,
      3,
    );
    monthly = StudyQuest(
      'month',
      'ဒီလ ၁၂ ရက် လေ့ကျင့်ပါ',
      active
          .where((d) => d.year == today.year && d.month == today.month)
          .length,
      12,
    );
    final months = <String, int>{};
    for (final day in active) {
      final month = dayKey(day).substring(0, 7);
      months[month] = (months[month] ?? 0) + 1;
    }
    earnedMonths =
        (months.entries.where((e) => e.value >= 12).map((e) => e.key).toList()
              ..sort())
            .reversed
            .toList();
    daysLeft = DateTime(today.year, today.month + 1).difference(today).inDays;
  }
  late final List<StudyQuest> daily;
  late final StudyQuest weekly;
  late final StudyQuest monthly;
  late final List<String> earnedMonths;
  late final int daysLeft;
}
