// Compatibility fields retain the previous MIT SM-2 adapter's stored history.
// Scheduling uses dart-fsrs (MIT); see THIRD_PARTY_NOTICES.md.
import 'package:fsrs/fsrs.dart' as fsrs;

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

class ReviewCard {
  const ReviewCard({
    required this.repetitions,
    required this.ease,
    required this.intervalDays,
    required this.due,
    required this.lastQuality,
    Map<String, dynamic>? memory,
    this.reviewLog = const [],
  }) : _memory = memory;

  factory ReviewCard.initial(DateTime now) => ReviewCard(
    repetitions: 0,
    ease: 2.5,
    intervalDays: 0,
    due: now,
    lastQuality: 5,
  );

  static final _scheduler = fsrs.Scheduler(enableFuzzing: false);
  final int repetitions;
  final double ease;
  final int intervalDays;
  final DateTime due;
  final int lastQuality;
  final Map<String, dynamic>? _memory;
  final List<Map<String, dynamic>> reviewLog;
  bool get usesFsrs => _memory != null;
  bool isDue(DateTime now) => !due.isAfter(now);

  static fsrs.Rating ratingFor(int quality) {
    if (quality < 0 || quality > 5) {
      throw ArgumentError.value(quality, 'quality', 'Must be between 0 and 5');
    }
    return quality < 3
        ? fsrs.Rating.again
        : quality == 3
        ? fsrs.Rating.hard
        : quality == 4
        ? fsrs.Rating.good
        : fsrs.Rating.easy;
  }

  ReviewCard review(int quality, DateTime now) {
    final rating = ratingFor(quality);
    final observed = now.toUtc();
    // Preserve old due dates until the next real review. Do not pretend old
    // SM-2 ease/intervals or unavailable review events are FSRS memory.
    final card = _memory == null
        ? fsrs.Card(cardId: 0, due: observed)
        : fsrs.Card.fromMap(Map<String, dynamic>.from(_memory));
    // A device clock correction must not crash learning or move reviews back.
    final utc = card.lastReview != null && observed.isBefore(card.lastReview!)
        ? card.lastReview!
        : observed;
    final result = _scheduler.reviewCard(card, rating, reviewDateTime: utc);
    final logs = [
      ...reviewLog,
      Map<String, dynamic>.unmodifiable({
        'at': utc.toIso8601String(),
        'rating': rating.value,
      }),
    ];
    return ReviewCard(
      repetitions: quality >= 3 ? repetitions + 1 : 0,
      ease: ease,
      intervalDays: result.card.due.difference(utc).inDays,
      due: result.card.due,
      lastQuality: quality,
      memory: Map.unmodifiable(result.card.toMap()),
      reviewLog: List.unmodifiable(
        logs.skip(logs.length > 8 ? logs.length - 8 : 0),
      ),
    );
  }

  Map<String, Object> toJson() => {
    'repetitions': repetitions,
    'ease': ease,
    'intervalDays': intervalDays,
    'due': due.toIso8601String(),
    'lastQuality': lastQuality,
    'fsrs': ?_memory,
    if (reviewLog.isNotEmpty) 'reviewLog': reviewLog,
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
    final due = DateTime.parse(json['due'] as String);
    Map<String, dynamic>? memory;
    try {
      final raw = Map<String, dynamic>.from(json['fsrs'] as Map);
      raw['stability'] = (raw['stability'] as num).toDouble();
      raw['difficulty'] = (raw['difficulty'] as num).toDouble();
      final card = fsrs.Card.fromMap(raw);
      if (card.stability!.isFinite &&
          card.stability! > 0 &&
          card.stability! < 1e9 &&
          card.difficulty!.isFinite &&
          card.difficulty! >= 1 &&
          card.difficulty! <= 10 &&
          card.lastReview != null &&
          card.lastReview!.isUtc &&
          card.due.isUtc &&
          !card.due.isBefore(card.lastReview!) &&
          card.due.isAtSameMomentAs(due) &&
          (card.state == fsrs.State.review
              ? card.step == null
              : card.step != null && card.step! >= 0 && card.step! <= 1)) {
        memory = Map.unmodifiable(card.toMap());
      }
    } catch (_) {
      // An invalid optional FSRS state must not erase the intact legacy card.
    }
    final logs = <Map<String, dynamic>>[];
    if (memory != null && json['reviewLog'] is List) {
      for (final row
          in (json['reviewLog'] as List).reversed.take(8).toList().reversed) {
        if (row is! Map) continue;
        final at = row['at'] is String ? DateTime.tryParse(row['at']) : null;
        final rating = row['rating'];
        if (at != null &&
            at.isUtc &&
            rating is int &&
            rating >= 1 &&
            rating <= 4) {
          logs.add(
            Map.unmodifiable({'at': at.toIso8601String(), 'rating': rating}),
          );
        }
      }
    }
    return ReviewCard(
      repetitions: repetitions,
      ease: ease,
      intervalDays: interval,
      due: due,
      lastQuality: quality,
      memory: memory,
      reviewLog: List.unmodifiable(logs),
    );
  }
}
