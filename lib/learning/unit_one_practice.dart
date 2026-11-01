import 'course_catalog.dart';

/// Unit 1's guided progression. IDs, base cursors and released bookmarks stay stable.
class UnitOnePractice {
  static const revision = 'u01-practice-v1';
  static bool enabled(CourseUnit unit) => unit.id == 'u01';

  static String teachingTip(String id) => switch (id) {
    'c2_u01_01' =>
      'လူသစ်နဲ့ စတွေ့ရင် နှုတ်ဆက်ပါ။ အဆုံးမှာ ယဉ်ကျေးတဲ့ အသုံးအနှုန်း ပါပါတယ်။',
    'c2_u01_02' =>
      'အကူအညီရတဲ့အခါ၊ တစ်ယောက်ယောက်က တစ်ခုခု ပြောပြပေးတဲ့အခါ ကျေးဇူးတင်ပါ။',
    'c2_u01_03' || 'c2_u01_05' => 'ကိုယ်စားပြုစကား → နာမည်က → နာမည် → ယဉ်ကျေးအဆုံးသတ်။ နာမည်နေရာကို ပြောင်းပြီး လူအမျိုးမျိုးအတွက် သုံးနိုင်ပါတယ်။',
    'c2_u01_04' =>
      'တစ်ဖက်လူ → နာမည် → ဘာ → ယဉ်ကျေးအဆုံးသတ် ဆိုတဲ့ အစဉ်နဲ့ နာမည်မေးပါတယ်။',
    _ => '',
  };

  static List<Map<String, dynamic>> steps(
    CourseUnit unit,
    CourseLesson lesson,
  ) {
    final original = lesson.steps;
    if (!enabled(unit)) return original;
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
        {
          'kind': 'reply',
          'line': 'c2_u01_02',
          'prompt': 'c2_u01_03',
          'instruction': 'နာမည်ပြောပြပေးတဲ့အတွက် ဘယ်လို ကျေးဇူးတင်မလဲ',
          'explanation':
              'မေးထားတဲ့ နာမည်ကို ပြောပြပေးတဲ့အတွက် ကျေးဇူးတင်ပါတယ်။',
          'pilotKey': '$revision:thanks-reply',
          'baseIndex': 0,
        },
      ];
    }
    return [
      for (var i = 0; i < original.length; i++) ...[
        if (i == 1 && lesson.id.endsWith('u01-l02'))
          {
            'kind': 'gap',
            'line': original[i]['line'],
            'gapIndex': 1,
            'gapDistractorIndices': [0, 2],
            'instruction': 'နာမည်မပြောခင် သုံးမယ့် အပိုင်းကို ဖြည့်ပါ',
            'explanation':
                'ကိုယ်စားပြုစကားပြီးရင် «နာမည်က»၊ ပြီးမှ နာမည်ကို ဆက်ပါတယ်။',
            'pilotKey': '$revision:name-marker-gap',
            'baseIndex': i,
          },
        if (i == 2 && lesson.id.endsWith('u01-l03'))
          {
            'kind': 'gap',
            'line': original[i]['line'],
            'gapIndex': 2,
            'gapDistractorIndices': [0, 1],
            'instruction': 'နာမည်မေးတဲ့ မေးခွန်းအပိုင်းကို ဖြည့်ပါ',
            'explanation':
                'နာမည်ကို မသိလို့ «ဘာ» ဆိုတဲ့ မေးခွန်းအပိုင်းကို သုံးပါတယ်။',
            'pilotKey': '$revision:question-gap',
            'baseIndex': i,
          },
        if (i == 1 && lesson.id.endsWith('u01-l04'))
          {
            'kind': 'gap',
            'line': original[i]['line'],
            'gapIndex': 2,
            'explanation':
                'ဝါကျပုံစံကို ထိန်းပြီး နမူနာနာမည်အသစ်ကို အစားထိုးထားပါတယ်။',
            'pilotKey': '$revision:new-name-gap',
            'baseIndex': i,
          },
        if (i == 5 && lesson.id.endsWith('u01-l06'))
          {
            'kind': 'reply',
            'line': 'c2_u01_05',
            'prompt': 'c2_u01_04',
            'options': ['c2_u01_03', 'c2_u01_04', 'c2_u01_05'],
            'useNewName': true,
            'instruction': 'အလုပ်ခွင်က လူသစ်နဲ့ မိတ်ဆက်နေပါတယ်။ ဒီတစ်ခါ နမူနာနာမည်အသစ်နဲ့ ပြန်ဖြေပါ',
            'explanation': 'နာမည်မေးတဲ့ စကားက အတူတူပါပဲ။ ပြန်ဖြေရာမှာ ဒီတစ်ခါ သတ်မှတ်ထားတဲ့ နာမည်အသစ်ကို သုံးပါတယ်။',
            'pilotKey': '$revision:workplace-name-reply',
            'baseIndex': i,
          },
        {
          ...original[i],
          if (original[i]['kind'] == 'choice') 'contextual': true,
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
