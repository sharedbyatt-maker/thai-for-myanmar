// Adapted from Pouple-Tim/Language-Learning-App (MIT, Copyright 2026 Timousss).
// See THIRD_PARTY_NOTICES.md and third_party/licenses/pouple_tim_mit.txt.

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class ReviewCard {
  const ReviewCard({
    required this.repetitions,
    required this.ease,
    required this.intervalDays,
    required this.due,
    required this.lastQuality,
  });

  factory ReviewCard.initial(DateTime now) => ReviewCard(
    repetitions: 0,
    ease: 2.5,
    intervalDays: 0,
    due: dateOnly(now),
    lastQuality: 5,
  );

  final int repetitions;
  final double ease;
  final int intervalDays;
  final DateTime due;
  final int lastQuality;

  ReviewCard review(int quality, DateTime now) {
    if (quality < 0 || quality > 5) {
      throw ArgumentError.value(quality, 'quality', 'Must be between 0 and 5');
    }
    final passed = quality >= 3;
    final interval = !passed
        ? 1
        : repetitions == 0
        ? 1
        : repetitions == 1
        ? 6
        : (intervalDays * ease).round().clamp(1, 36500);
    final nextEase =
        ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    // Construct by calendar date, so DST changes do not shift a review day.
    final today = dateOnly(now);
    return ReviewCard(
      repetitions: passed ? repetitions + 1 : 0,
      ease: nextEase.clamp(1.3, 10),
      intervalDays: interval,
      due: DateTime(today.year, today.month, today.day + interval),
      lastQuality: quality,
    );
  }

  Map<String, Object> toJson() => {
    'repetitions': repetitions,
    'ease': ease,
    'intervalDays': intervalDays,
    'due': due.toIso8601String(),
    'lastQuality': lastQuality,
  };

  factory ReviewCard.fromJson(Map<String, dynamic> json) {
    final ease = (json['ease'] as num).toDouble();
    final repetitions = json['repetitions'] as int;
    final interval = json['intervalDays'] as int;
    final quality = json['lastQuality'] as int;
    if (!ease.isFinite ||
        ease < 1.3 ||
        ease > 10 ||
        repetitions < 0 ||
        interval < 0 ||
        interval > 36500 ||
        quality < 0 ||
        quality > 5) {
      throw const FormatException('Invalid review card');
    }
    return ReviewCard(
      repetitions: repetitions,
      ease: ease,
      intervalDays: interval,
      due: dateOnly(DateTime.parse(json['due'] as String)),
      lastQuality: quality,
    );
  }
}
