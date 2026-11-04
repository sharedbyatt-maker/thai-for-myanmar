import 'course_catalog.dart';
import 'unit_one_practice.dart';

/// Additive practice in Units 2–5; the released Unit 1 overlay is unchanged.
class CoursePractice {
  static const revision = 'u02-u05-practice-v1';
  static const _units = {'u02', 'u03', 'u04', 'u05'};
  static bool enabled(CourseUnit unit) =>
      UnitOnePractice.enabled(unit) || _units.contains(unit.id);

  static String teachingTip(CourseUnit unit, String lineId) =>
      UnitOnePractice.enabled(unit)
      ? UnitOnePractice.teachingTip(lineId)
      : _units.contains(unit.id)
      ? unit.tips
      : '';

  static List<String> reflectionPrompts(CourseUnit unit) => switch (unit.id) {
    'u02' => [
      'လူသစ်ကို ဘယ်ကလာသလဲ မေးပါ။',
      'မြန်မာနိုင်ငံက လာပြီး ထိုင်းနိုင်ငံမှာနေတဲ့ နမူနာလူအဖြစ် ဖြေပါ။',
      'ထိုင်းနိုင်ငံကလာတဲ့ နမူနာလူအဖြစ် နိုင်ငံနာမည် ပြောင်းဖြေပါ။',
    ],
    'u03' => [
      'အလုပ်ညွှန်ကြားချက်ကို နားမလည်ကြောင်း ပြောပါ။',
      'တစ်ဖက်လူက မြန်မြန်ပြောနေလို့ ဖြည်းဖြည်းပြောခိုင်းပါ။',
      'ကြေညာချက်ကို မကြားလိုက်လို့ တစ်ခေါက်ထပ်ပြောခိုင်းပါ။',
    ],
    'u04' => [
      'ဆိုင်မှာ ရေတောင်းပါ။',
      'ဒီတစ်ခါ ရေအစား ထမင်းတောင်းပါ။',
      'လက်ဖက်ရည် ကမ်းလာပေမယ့် မယူချင်ကြောင်း ပြောပါ။',
    ],
    'u05' => [
      'ကော်ဖီအေး မှာပါ။',
      'ဒီတစ်ခါ လက်ဖက်ရည်ပူကို ပြောင်းမှာပါ။',
      'သကြား မထည့်ပေးဖို့ ပြောပါ။',
    ],
    _ => [],
  };

  static Map<String, dynamic> _task(
    CourseUnit unit,
    int base,
    String key,
    Map<String, dynamic> values,
  ) => {...values, 'baseIndex': base, 'pilotKey': '$revision:${unit.id}-$key'};

  static List<Map<String, dynamic>> steps(
    CourseUnit unit,
    CourseLesson lesson,
  ) {
    if (!_units.contains(unit.id)) return UnitOnePractice.steps(unit, lesson);
    final original = lesson.steps;
    final models = unit.models;
    final number = unit.lessons.indexWhere((l) => l.id == lesson.id);
    if (number == 5) {
      final turns = switch (unit.id) {
        'u02' => [
          (
            0,
            1,
            'မူလနိုင်ငံကို မေးလာရင် မြန်မာနိုင်ငံကလာတဲ့ နမူနာလူအဖြစ် ဖြေပါ',
          ),
          (
            2,
            3,
            'လက်ရှိနေရာကို မေးလာရင် ထိုင်းနိုင်ငံမှာနေတဲ့ နမူနာလူအဖြစ် ဖြေပါ',
          ),
          (0, 4, 'ဒီတစ်ခါ ထိုင်းနိုင်ငံကလာတဲ့ နမူနာလူအဖြစ် ပြောင်းဖြေပါ'),
        ],
        'u03' => [
          (0, 1, 'နားလည်မလည် မေးလာပါတယ်။ နားမလည်ကြောင်း ပြန်ဖြေပါ'),
          (
            2,
            3,
            'ဒီတစ်ခါ ကူညီပေးသူနေရာက ဖြေပါ။ ဖြည်းဖြည်းပြောပေးဖို့ တောင်းဆိုတာကို လက်ခံပါ',
          ),
          (4, 3, 'တစ်ခေါက်ထပ်ပြောပေးဖို့ တောင်းဆိုတာကို လက်ခံပါ'),
        ],
        'u04' => [
          (0, 1, 'ဆိုင်က ဘာယူမလဲ မေးလာပါတယ်။ ရေတောင်းပါ'),
          (2, 3, 'လက်ဖက်ရည် ကမ်းလာပါတယ်။ မယူချင်ကြောင်း ပြန်ဖြေပါ'),
          (0, 4, 'ဒီတစ်ခါ ရေအစား ထမင်းတောင်းပါ'),
        ],
        _ => [
          (0, 1, 'ဆိုင်က ပူ/အေး မေးလာပါတယ်။ ကော်ဖီအေး မှာပါ'),
          (2, 3, 'သကြားထည့်မလား မေးလာပါတယ်။ မထည့်ပေးဖို့ ပြောပါ'),
          (0, 4, 'ဒီတစ်ခါ ဆိုင်ရဲ့ကော်ဖီအစား လက်ဖက်ရည်ပူကို ပြောင်းတောင်းပါ'),
        ],
      };
      return [
        for (var i = 0; i < turns.length; i++)
          _task(unit, 0, 'reply-$i', {
            'kind': 'reply',
            'prompt': models[turns[i].$1],
            'line': models[turns[i].$2],
            'instruction': turns[i].$3,
            'explanation': turns[i].$3,
            'options': models,
            if (i == 0) 'original': true,
          }),
      ];
    }
    final gaps = switch (unit.id) {
      'u02' => [2, 2, 2],
      'u03' => [1, 0, 1],
      'u04' => [1, 1, 1],
      _ => [3, 2, 2],
    };
    final variantOptions = switch (unit.id) {
      'u02' => ['c2_w_96d1fa73f6f3', 'c2_w_70450f6834da'],
      'u03' => ['c2_w_2341ccdc2185', 'c2_w_d06eb7887210'],
      'u04' => ['c2_w_f40da9b0d15a', 'c2_w_5634585f91a7'],
      _ => ['c2_w_a36ac9a27aa0', 'c2_w_19eee6e4ebe1'],
    };
    final contexts = switch (unit.id) {
      'u02' => [
        (
          4,
          'နမူနာမိတ်ဆွေဟာ ထိုင်းနိုင်ငံက လာတာပါ။ သူ့မူလနိုင်ငံကို ပြောမယ့်စကား ရွေးပါ',
        ),
        (
          3,
          'မူလနိုင်ငံကို မေးတာမဟုတ်ဘဲ လက်ရှိဘယ်မှာနေသလဲ မေးလာပါတယ်။ ထိုင်းနိုင်ငံမှာနေတဲ့ နမူနာလူအဖြစ် ဖြေပါ',
        ),
      ],
      'u03' => [
        (
          4,
          'ဘတ်စ်ကားကြေညာချက်ကို မကြားလိုက်ပါဘူး။ တစ်ခေါက်ထပ်ပြောပေးဖို့ ဘယ်လို တောင်းမလဲ',
        ),
        (
          2,
          'အလုပ်ညွှန်ကြားချက်က မြန်လွန်းလို့ မလိုက်နိုင်ပါဘူး။ ဖြည်းဖြည်းပြောပေးဖို့ ဘယ်လို တောင်းမလဲ',
        ),
      ],
      'u04' => [
        (
          4,
          'နေ့လယ်စာဆိုင်မှာ ဒီတစ်ခါ ရေမဟုတ်ဘဲ ထမင်းတောင်းချင်ပါတယ်။ ဘယ်လို ပြောမလဲ',
        ),
        (
          3,
          'အိမ်နီးချင်းက လက်ဖက်ရည်ကမ်းလာပါတယ်။ မယူချင်ကြောင်း ဘယ်လို ပြောမလဲ',
        ),
      ],
      _ => [
        (
          4,
          'မနက်က ကော်ဖီအေးမှာခဲ့ပေမယ့် အခု လက်ဖက်ရည်ပူ ပြောင်းမှာချင်ပါတယ်။ ဘယ်လို ပြောမလဲ',
        ),
        (
          3,
          'အခြားဆိုင်မှာ အချိုမပါတဲ့သောက်စရာ မှာချင်ပါတယ်။ သကြားမထည့်ဖို့ ဘယ်လို ပြောမလဲ',
        ),
      ],
    };
    return [
      for (var i = 0; i < original.length; i++) ...[
        if (original[i]['kind'] == 'build' && (number == 2 || number == 4))
          _task(unit, i, 'gap-$i', {
            'kind': 'gap',
            'line': original[i]['line'],
            'gapIndex': number == 4 ? gaps[2] : gaps[i - 2],
            if (number == 4)
              'gapAlternatives': variantOptions
            else
              'gapDistractorIndices': [
                for (var p = 0; p < 3; p++)
                  if (p != gaps[i - 2]) p,
              ],
            'instruction': number == 4
                ? 'အခြေအနေအသစ်နဲ့ ကိုက်တဲ့ အပိုင်းကို ပြောင်းဖြည့်ပါ'
                : 'သင်ထားတဲ့ ဝါကျပုံစံထဲက အပိုင်းတစ်ခု ဖြည့်ပါ',
            'explanation': teachingTip(unit, original[i]['line'] as String),
          }),
        if (number == 6 && original[i]['kind'] == 'build')
          for (var j = 0; j < contexts.length; j++)
            _task(unit, i, 'transfer-$j', {
              'kind': 'situation',
              'line': models[contexts[j].$1],
              'instruction': contexts[j].$2,
              'explanation': teachingTip(unit, models[contexts[j].$1]),
              'options': models,
            }),
        _task(unit, i, 'base-$i', {
          ...original[i],
          'original': true,
          if (original[i]['kind'] == 'choice') 'contextual': true,
        }),
        if (number < 2 && i == original.length - 1)
          for (final id in {original.first['line'], original.last['line']})
            _task(unit, i, 'word-$id', {
              'kind': 'choice',
              'line': id,
              'wordPractice': true,
              'options': unit.data['words'],
            }),
      ],
    ];
  }

  static int resumeIndex(
    List<Map<String, dynamic>> steps,
    int base,
    String? bookmark,
  ) => UnitOnePractice.resumeIndex(steps, base, bookmark);
}
