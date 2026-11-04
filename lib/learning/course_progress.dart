import 'review_card.dart';

/// Practice completion and listening evidence never imply speaking mastery.
class CourseProgress {
  static const lessonXp = 20;
  final Map<String, DateTime> completed = {};
  final Map<String, Set<String>> _activity = {};
  final Map<String, int> cursors = {};
  // Optional runtime-step bookmark; legacy integer cursors remain meaningful.
  final Map<String, String> stepBookmarks = {};
  final Map<String, ReviewCard> memory = {};
  final Map<String, int> probeStages = {};
  final List<Map<String, dynamic>> events = [];

  void event(Map<String, dynamic> value) {
    events.add(Map.unmodifiable(value));
    if (events.length > 600) events.removeRange(0, events.length - 600);
  }

  void finish(String id, DateTime now) {
    completed.putIfAbsent(id, () => now.toUtc());
    _activity.putIfAbsent(_day(now), () => {}).add('lesson|$id');
    cursors.remove(id);
    stepBookmarks.remove(id);
  }

  static String _day(DateTime now) {
    final d = now.toLocal();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void recordPractice(String lesson, String line, String kind, DateTime now) =>
      _activity
          .putIfAbsent(_day(now), () => {})
          .add('check|$lesson|$kind|$line');

  static int _count(Set<String> rows) {
    final checks = rows.where((v) => v.startsWith('check|')).toSet();
    final checkedLessons = checks.map((v) => v.split('|')[1]).toSet();
    return checks.length +
        rows
            .where(
              (v) =>
                  v.startsWith('lesson|') &&
                  !checkedLessons.contains(v.substring(7)),
            )
            .length;
  }

  Map<String, int> get activity =>
      _activity.map((k, v) => MapEntry(k, _count(v)));
  int practiceOn(DateTime now) => _count(_activity[_day(now)] ?? {});
  Set<String> lessonsOn(DateTime now) => (_activity[_day(now)] ?? <String>{})
      .where((v) => v.startsWith('lesson|'))
      .map((v) => v.substring(7))
      .toSet();

  Map<String, dynamic> toJson() => {
    'version': 1,
    'completed': completed.map((k, v) => MapEntry(k, v.toIso8601String())),
    'activity': _activity.map((k, v) => MapEntry(k, v.toList()..sort())),
    'cursors': cursors,
    'stepBookmarks': stepBookmarks,
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
    if (raw['activity'] case final Map rows) {
      for (final row in rows.entries) {
        if (row.key is! String || row.value is! List) continue;
        final date = DateTime.tryParse(row.key as String);
        if (date == null || _day(date) != row.key) continue;
        result._activity[row.key as String] = (row.value as List)
            .whereType<String>()
            .where(
              (v) =>
                  (v.startsWith('lesson|') && v.split('|').length == 2) ||
                  (v.startsWith('check|') && v.split('|').length == 4),
            )
            .toSet();
      }
    } else {
      // Existing dated completions retain their actual practice day.
      for (final row in result.completed.entries) {
        result._activity
            .putIfAbsent(_day(row.value), () => {})
            .add('lesson|${row.key}');
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
    if (raw['stepBookmarks'] case final Map rows) {
      for (final row in rows.entries) {
        if (row.key is String &&
            row.value is String &&
            ((row.value as String).startsWith('u01-practice-v1:') ||
                (row.value as String).startsWith('u02-u05-practice-v1:')) &&
            (row.value as String).length < 100) {
          result.stepBookmarks[row.key as String] = row.value as String;
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
