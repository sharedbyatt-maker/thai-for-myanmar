import 'course_catalog.dart';

/// An additive Unit 1 pilot. Authored lesson IDs and completion XP stay stable.
class UnitOnePractice {
  static const revision = 'u01-practice-v1';
  static bool enabled(CourseUnit unit) => unit.id == 'u01';

  static List<Map<String, dynamic>> steps(
    CourseUnit unit,
    CourseLesson lesson,
  ) {
    final original = lesson.steps;
    if (!enabled(unit) ||
        !['course-v2.1:u01-l04', 'course-v2.1:u01-l05'].contains(lesson.id)) {
      return original;
    }
    if (lesson.id.endsWith('u01-l05')) {
      return [
        {
          'kind': 'reply',
          'line': 'c2_u01_01',
          'prompt': 'c2_u01_01',
          'instruction': 'ပြန်နှုတ်ဆက်မယ့် စကားကို ရွေးပါ',
          'explanation': 'တစ်ဖက်လူက နှုတ်ဆက်လာတာမို့ ပြန်နှုတ်ဆက်ပါတယ်။',
          'pilotKey': '$revision:greeting-reply',
          'baseIndex': 0,
          'original': true,
        },
        {
          'kind': 'reply',
          'line': 'c2_u01_03',
          'prompt': 'c2_u01_04',
          'instruction': 'နမူနာနာမည်နဲ့ ပြန်ဖြေမယ့် စကား ရွေးပါ',
          'explanation': 'နာမည်မေးလာတဲ့အခါ ကိုယ့်နာမည်ကို ပြန်ပြောပါတယ်။',
          'pilotKey': '$revision:name-reply',
          'baseIndex': 0,
        },
      ];
    }
    return [
      for (var i = 0; i < original.length; i++) ...[
        if (i == 1)
          {
            'kind': 'gap',
            'line': original[i]['line'],
            'gapIndex': 2,
            'explanation':
                'ဝါကျပုံစံကို ထိန်းပြီး နမူနာနာမည်အသစ်ကို အစားထိုးထားပါတယ်။',
            'pilotKey': '$revision:new-name-gap',
            'baseIndex': i,
          },
        {
          ...original[i],
          'baseIndex': i,
          'original': true,
          'pilotKey': '$revision:base-$i',
        },
      ],
    ];
  }

  /// Old integer cursors resume at the original step, not an inserted exercise.
  /// Unknown/stale bookmarks fall back to that same compatible base cursor.
  static int resumeIndex(
    List<Map<String, dynamic>> steps,
    int base,
    String? bookmark,
  ) {
    final saved = steps.indexWhere(
      (s) => s['pilotKey'] == bookmark && bookmark != null,
    );
    if (saved >= 0) return saved;
    final original = steps.indexWhere(
      (s) => s['baseIndex'] == base && s['original'] == true,
    );
    return original >= 0 ? original : base.clamp(0, steps.length - 1);
  }
}
