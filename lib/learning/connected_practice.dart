import 'course_catalog.dart';

typedef _Reply = (int prompt, int answer, String instruction);
typedef _Situation = (String line, String instruction);
typedef _Practice = ({
  List<_Reply> replies,
  (int answerPart, int alternateModel, int alternatePart) gap,
  _Situation revisit,
});

/// Guided steps for Units 6–26. The preceding units keep their released steps.
class ConnectedPractice {
  static bool enabled(CourseUnit unit) => _plans.containsKey(unit.id);

  static List<Map<String, dynamic>> steps(
    CourseUnit unit,
    CourseLesson lesson,
  ) {
    final plan = _plans[unit.id]!;
    final original = lesson.steps;
    final models = unit.models;
    final words = original.every(
      (step) => step['kind'] == 'teach' && !models.contains(step['line']),
    );
    final wordOptions = original
        .map((step) => step['line'] as String?)
        .whereType<String>()
        .toList();
    final checkpoint = lesson.id == unit.lessons.last.id;

    Map<String, dynamic> step(
      int base,
      String key,
      Map<String, dynamic> values,
    ) => {...values, 'baseIndex': base, 'pilotKey': 'connected-v1:$key'};

    if (original.singleOrNull?['kind'] == 'dialogue') {
      return [
        for (final (i, reply) in plan.replies.indexed)
          step(0, 'reply-$i', {
            'kind': 'reply',
            'line': models[reply.$2],
            'prompt': models[reply.$1],
            'instruction': reply.$3,
            'options': models,
            if (i == 0) 'original': true,
          }),
      ];
    }

    final (answerPart, alternateModel, alternatePart) = plan.gap;
    return [
      for (final (i, base) in original.indexed) ...[
        if (!checkpoint &&
            base['kind'] == 'build' &&
            base['line'] == models.last)
          step(i, 'substitute', {
            'kind': 'gap',
            'line': models.last,
            'gapIndex': answerPart,
            'gapAlternateLine': models[alternateModel],
            'gapAlternatePart': alternatePart,
            'instruction':
                'ဒီတစ်ခါ အခြေအနေနဲ့ ကိုက်တဲ့ အပိုင်းကို ပြောင်းဖြည့်ပါ',
            'explanation': unit.tips,
          }),
        if (checkpoint && base['kind'] == 'build') ...[
          step(i, 'current-situation', {
            'kind': 'situation',
            'line': models.last,
            'options': models.reversed.toList(),
          }),
          step(i, 'prior-situation', {
            'kind': 'situation',
            'line': plan.revisit.$1,
            'instruction': plan.revisit.$2,
            'options': models,
          }),
        ],
        step(i, 'base-$i', {
          ...base,
          'original': true,
          if (base['kind'] == 'choice') 'contextual': true,
        }),
        if (words && i == original.length - 1 && wordOptions.length >= 2)
          for (final id in {wordOptions.first, wordOptions.last})
            step(i, 'word-$id', {
              'kind': 'choice',
              'line': id,
              'wordPractice': true,
              'options': wordOptions,
            }),
      ],
    ];
  }

  static const Map<String, _Practice> _plans = {
    'u06': (
      replies: [
        (0, 1, 'တစ်ယောက်စာအတွက် ရေတစ်ဘူး မှာပါ'),
        (0, 4, 'နှစ်ယောက်အတွက် ရေနှစ်ဘူး ပြောင်းမှာပါ'),
      ],
      gap: (2, 1, 2),
      revisit: (
        'c2_u04_05',
        'ရေမှာပြီးမှ ထမင်းပါ ထပ်လိုချင်ပါတယ်။ ဆိုင်ရှင်ဆီက ထမင်းတောင်းပါ',
      ),
    ),
    'u07': (
      replies: [
        (0, 1, 'ဝယ်သူကို ဘတ်နှစ်ဆယ်လို့ ဖြေပါ'),
        (2, 3, 'ဒီပစ္စည်းက ဈေးမကြီးကြောင်း ပြန်ဖြေပါ'),
      ],
      gap: (0, 1, 0),
      revisit: (
        'c2_u06_05',
        'ဈေးမေးပြီးပြီ။ သူငယ်ချင်းအတွက်ပါ ရေနှစ်ဘူး မှာပါ',
      ),
    ),
    'u08': (
      replies: [
        (0, 1, 'အနီရောင် ရှိကြောင်း ဖြေပါ'),
        (3, 4, 'မိသားစုအတွက် အကြီးကို ရွေးပါ'),
      ],
      gap: (1, 3, 1),
      revisit: ('c2_u07_01', 'အကြီးရွေးပြီးပြီ။ မပေးခင် ဈေးနှုန်းကို မေးပါ'),
    ),
    'u09': (
      replies: [
        (0, 1, 'ငွေသားပေးလို့ရကြောင်း ဖြေပါ'),
        (2, 3, 'အမ်းငွေ ရှိကြောင်း ပြန်ဖြေပါ'),
      ],
      gap: (0, 0, 0),
      revisit: (
        'c2_u08_05',
        'အငယ်နဲ့ အကြီး နှစ်မျိုးရှိပါတယ်။ ငွေမရှင်းခင် အကြီးကို ရွေးပါ',
      ),
    ),
    'u10': (
      replies: [
        (0, 1, 'အိမ်သာ ဒီနေရာမှာရှိကြောင်း ဖြေပါ'),
        (2, 3, 'ဆေးရုံ နီးကြောင်း ပြန်ဖြေပါ'),
      ],
      gap: (0, 0, 0),
      revisit: ('c2_u02_03', 'ရပ်ကွက်အသစ်မှာ သိလာတဲ့သူကို ဘယ်မှာနေသလဲ မေးပါ'),
    ),
    'u11': (
      replies: [
        (0, 1, 'လမ်းမကနေ တည့်တည့်သွားဖို့ ပြောပါ'),
        (0, 4, 'နောက်လမ်းဆုံမှာ ညာဘက်ကွေ့ဖို့ ပြောပါ'),
      ],
      gap: (1, 2, 1),
      revisit: (
        'c2_u10_05',
        'လမ်းဆုံရောက်ပြီ။ ရှာနေတဲ့ဆိုင် ဘယ်မှာရှိလဲ မေးပါ',
      ),
    ),
    'u12': (
      replies: [
        (0, 1, 'ညွှန်ပြထားတဲ့ ဘူတာကို သွားမယ်လို့ ဖြေပါ'),
        (2, 3, 'ဒီနေရာမှာ ဆင်းလို့ရကြောင်း ဖြေပါ'),
      ],
      gap: (1, 1, 1),
      revisit: ('c2_u11_05', 'ယာဉ်မောင်းကို နောက်လမ်းဆုံမှာ ညာကွေ့ဖို့ ပြောပါ'),
    ),
    'u13': (
      replies: [
        (0, 1, 'တနင်္လာနေ့ ချိန်းထားကြောင်း ဖြေပါ'),
        (2, 3, 'မနက် ၉ နာရီလို့ ဖြေပါ'),
      ],
      gap: (1, 3, 0),
      revisit: (
        'c2_u12_05',
        'ချိန်းထားတဲ့နေရာက ဆေးရုံပါ။ ယာဉ်မောင်းကို ဆေးရုံသွားမယ်လို့ ပြောပါ',
      ),
    ),
    'u14': (
      replies: [
        (0, 1, 'ပထမဆုံး တံခါးဖွင့်ဖို့ ညွှန်ကြားပါ'),
        (0, 2, 'အလုပ်ပြီးပြီဆိုတော့ တံခါးပိတ်ဖို့ ညွှန်ကြားပါ'),
      ],
      gap: (0, 3, 0),
      revisit: (
        'c2_u03_03',
        'အလုပ်အသစ်မှာ တာဝန်ရှင်းပြတာ မြန်လွန်းနေပါတယ်။ ဖြည်းဖြည်း ပြောပေးဖို့ တောင်းပါ',
      ),
    ),
    'u15': (
      replies: [
        (0, 1, 'အခုလုပ်ပုံက မှန်ကြောင်း ပြန်ဖြေပါ'),
        (2, 3, 'လုပ်ပြပေးဖို့ သဘောတူပါ'),
      ],
      gap: (1, 0, 0),
      revisit: (
        'c2_u14_03',
        'လုပ်ပုံကို စစ်ပြီးပြီ။ အပြင်မထွက်ခင် တံခါးပိတ်ဖို့ ပြောပါ',
      ),
    ),
    'u16': (
      replies: [
        (0, 1, 'အခုထိ မပြီးသေးကြောင်း ဖြေပါ'),
        (0, 3, 'နောက်တစ်ခေါက် မေးလာတော့ ပြီးပြီလို့ ဖြေပါ'),
      ],
      gap: (1, 2, 1),
      revisit: (
        'c2_u15_01',
        'လုပ်ဖော်ကိုင်ဖက်ကို ကိုယ်လုပ်တဲ့ပုံစံ မှန်မမှန် မေးပါ',
      ),
    ),
    'u17': (
      replies: [
        (0, 1, 'မနက် ၉ နာရီ အလုပ်စကြောင်း ဖြေပါ'),
        (2, 3, 'လေ့ကျင့်နမူနာအရ တစ်နာရီ ဘတ်တစ်ရာလို့ ဖြေပါ'),
      ],
      gap: (0, 0, 0),
      revisit: (
        'c2_u13_03',
        'အလုပ်ပြီးနောက် ချိန်းထားတဲ့ အစည်းအဝေး ဘယ်နှနာရီလဲ မေးပါ',
      ),
    ),
    'u18': (
      replies: [
        (0, 1, 'ဒီနေ့ ခွင့်ယူလို့ရကြောင်း ဖြေပါ'),
        (2, 3, 'နေမကောင်းလို့ ခွင့်ယူကြောင်း ရှင်းပြပါ'),
      ],
      gap: (1, 0, 1),
      revisit: (
        'c2_u17_05',
        'ခွင့်မတောင်းခင် ဒီနေ့ အလုပ်ဆင်းချိန် ဘယ်နှနာရီလဲ မေးပါ',
      ),
    ),
    'u19': (
      replies: [
        (0, 1, 'နမူနာအိမ်ငှားခ ဘတ်သုံးထောင်လို့ ဖြေပါ'),
        (2, 3, 'မနက်ဖြန် ပေးမယ်လို့ ဖြေပါ'),
      ],
      gap: (0, 0, 0),
      revisit: ('c2_u09_05', 'အိမ်ငှားခကို ငွေသားအစား ငွေလွှဲလို့ရမလား မေးပါ'),
    ),
    'u20': (
      replies: [
        (0, 1, 'ရေပိုက်ခေါင်း ပျက်နေကြောင်း ဖြေပါ'),
        (2, 3, 'ပြင်ပေးလို့ရကြောင်း ပြန်ဖြေပါ'),
      ],
      gap: (1, 1, 1),
      revisit: (
        'c2_u19_04',
        'ပြင်ခကို ဘယ်နေ့ပေးမလဲ မေးလာပါတယ်။ မနက်ဖြန်ပေးမယ်လို့ ပြောပါ',
      ),
    ),
    'u21': (
      replies: [
        (0, 1, 'ခေါင်းကိုက်နေကြောင်း ဖြေပါ'),
        (2, 3, 'ဖျားနေကြောင်း ဖြေပါ'),
      ],
      gap: (1, 5, 1),
      revisit: (
        'c2_u18_04',
        'ဆေးခန်းသွားပြီး အလုပ်ကို ဖုန်းဆက်ပါတယ်။ နေမကောင်းလို့ ခွင့်ယူကြောင်း ပြောပါ',
      ),
    ),
    'u22': (
      replies: [
        (0, 1, 'ဆေးဝါးကျွမ်းကျင်သူနဲ့ စကားပြောလို့ရကြောင်း ပြန်ဖြေပါ'),
        (2, 3, 'ဆေးသောက်နည်းကို နားမလည်သေးကြောင်း ဖြေပါ'),
      ],
      gap: (1, 0, 1),
      revisit: (
        'c2_u21_07',
        'ဆေးဝါးကျွမ်းကျင်သူကို ပုစွန်နဲ့ ဓာတ်မတည့်ကြောင်း ပြောပါ',
      ),
    ),
    'u23': (
      replies: [
        (0, 1, 'မိသားစုနဲ့ နေကြောင်း ဖြေပါ'),
        (2, 3, 'မနက် ၆ နာရီ အိပ်ရာနိုးကြောင်း ဖြေပါ'),
      ],
      gap: (0, 2, 0),
      revisit: (
        'c2_u02_04',
        'အတူနေတဲ့သူအကြောင်း ပြောပြီးပြီ။ နေတဲ့နိုင်ငံကို ထိုင်းနိုင်ငံလို့ ဖြေပါ',
      ),
    ),
    'u24': (
      replies: [
        (0, 1, 'လက်ဖက်ရည် ကြိုက်ကြောင်း ဖြေပါ'),
        (2, 3, 'မချိုလို့ ကြိုက်ကြောင်း ဖြေပါ'),
      ],
      gap: (1, 1, 1),
      revisit: (
        'c2_u05_02',
        'လက်ဖက်ရည်အကြောင်း ပြောပြီးပြီ။ ဒီတစ်ခေါက်တော့ ကော်ဖီအေး မှာပါ',
      ),
    ),
    'u25': (
      replies: [
        (0, 1, 'မနက်ဖြန် ဆိုင်သွားမယ်လို့ ဖြေပါ'),
        (2, 3, 'ထိုင်းနိုင်ငံ သွားဖူးကြောင်း ဖြေပါ'),
      ],
      gap: (0, 0, 0),
      revisit: (
        'c2_u13_05',
        'မနက်ဖြန်အစီအစဉ် ပြောနေပါတယ်။ ချိန်းထားတဲ့နေ့ကို မနက်ဖြန်လို့ ပြောပါ',
      ),
    ),
    'u26': (
      replies: [
        (0, 1, 'ဖောင်မှာ နာမည်ဖြည့်ဖို့ ပြောပါ'),
        (2, 3, 'ကောင်တာနံပါတ်တစ်ကို ညွှန်ပြပါ'),
      ],
      gap: (1, 2, 1),
      revisit: (
        'c2_u22_05',
        'ကောင်တာမှာ ပြောပြတာကို မှတ်ထားချင်ပါတယ်။ စာနဲ့ ရေးပေးဖို့ တောင်းပါ',
      ),
    ),
  };
}
