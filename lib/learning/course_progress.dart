import 'review_card.dart';

/// Practice completion and listening evidence never imply speaking mastery.
class CourseProgress {
  final Map<String, DateTime> completed = {};
  final Map<String, int> cursors = {};
  final Map<String, ReviewCard> memory = {};
  final Map<String, int> probeStages = {};
  final List<Map<String, dynamic>> events = [];

  void event(Map<String, dynamic> value) {
    events.add(Map.unmodifiable(value));
    if (events.length > 600) events.removeRange(0, events.length - 600);
  }

  void finish(String id, DateTime now) {
    completed.putIfAbsent(id, () => now.toUtc());
    cursors.remove(id);
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'completed': completed.map((k, v) => MapEntry(k, v.toIso8601String())),
    'cursors': cursors,
    'probeStages': probeStages,
    'memory': memory.map((k, v) => MapEntry(k, v.toJson())),
    'events': events,
  };

  static CourseProgress fromJson(Object? raw) {
    final result = CourseProgress();
    if (raw is! Map || raw['version'] != 1) return result;
    if (raw['completed'] case final Map rows) {
      for (final row in rows.entries) {
        final date = DateTime.tryParse('${row.value}');
        if (row.key is String && date != null) {
          result.completed[row.key] = date.toUtc();
        }
      }
    }
    if (raw['cursors'] case final Map rows) {
      for (final row in rows.entries) {
        if (row.key is String &&
            row.value is int &&
            row.value >= 0 &&
            row.value < 300) {
          result.cursors[row.key] = row.value;
        }
      }
    }
    if (raw['probeStages'] case final Map rows) {
      for (final row in rows.entries) {
        if (row.key is String &&
            row.value is int &&
            row.value >= 0 &&
            row.value <= 2) {
          result.probeStages[row.key] = row.value;
        }
      }
    }
    if (raw['memory'] case final Map rows) {
      for (final row in rows.entries) {
        try {
          if (row.key is String && row.value is Map) {
            result.memory[row.key] = ReviewCard.fromJson(
              Map<String, dynamic>.from(row.value),
            );
          }
        } catch (_) {
          // A damaged course card must not erase legacy or other course records.
        }
      }
    }
    if (raw['events'] case final List rows) {
      for (final row in rows.reversed.take(600).toList().reversed) {
        if (row is Map &&
            row['lesson'] is String &&
            row['line'] is String &&
            row['kind'] is String &&
            row['at'] is String) {
          result.event({
            for (final entry in row.entries)
              if (entry.key is String) entry.key as String: entry.value,
          });
        }
      }
    }
    return result;
  }
}
