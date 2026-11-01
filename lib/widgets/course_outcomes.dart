import 'package:flutter/material.dart';

import '../learning/course_insights.dart';

/// Outcomes describe practice evidence, including supported/text practice.
class CourseOutcomes extends StatelessWidget {
  const CourseOutcomes({required this.insights, super.key});
  final CourseInsights insights;

  @override
  Widget build(BuildContext context) {
    final units = insights.practicedUnits;
    return Card(
      key: const ValueKey('course-outcomes'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'သင်ယူမှု ခရီးစဉ်',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.flag_rounded, size: 18),
                  label: Text('ယူနစ် ${units.length} လေ့ကျင့်ပြီး'),
                ),
                Chip(
                  avatar: const Icon(Icons.update_rounded, size: 18),
                  label: Text('ပြန်စမ်းပြီး ${insights.delayedUnits} ယူနစ်'),
                ),
                if (insights.dueItems > 0)
                  Chip(
                    avatar: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text('${insights.dueItems} ခု ပြန်စမ်းရန်'),
                  ),
              ],
            ),
            ExpansionTile(
              key: const ValueKey('course-practiced-topics'),
              tilePadding: EdgeInsets.zero,
              title: Text(
                units.isEmpty ? 'အသေးစိတ်' : 'လေ့ကျင့်ခဲ့တဲ့ အကြောင်းအရာများ',
              ),
              children: [
                if (units.isEmpty)
                  const Text(
                    'ယူနစ်တစ်ခု ပြီးတဲ့အခါ လေ့ကျင့်ခဲ့တဲ့ အကြောင်းအရာတွေ ဒီမှာ ပြပါမယ်။',
                  ),
                for (final unit in units)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.task_alt_rounded),
                    title: Text(unit.goal),
                    subtitle: Text(
                      '${unit.title} · ${insights.unitStatus(unit)}',
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'စာသားအကူအညီပါသော လေ့ကျင့်မှုလည်း ပါဝင်ပါတယ်။ စကားပြောကျွမ်းကျင်မှု အတည်ပြုချက် မဟုတ်ပါ။',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CourseReviewCue extends StatelessWidget {
  const CourseReviewCue({
    required this.count,
    required this.resuming,
    required this.onPressed,
    super.key,
  });
  final int count;
  final bool resuming;
  final void Function(BuildContext) onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('course-review-cue'),
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Builder(
      builder: (anchor) => OutlinedButton.icon(
        onPressed: () => onPressed(anchor),
        icon: const Icon(Icons.refresh_rounded),
        label: Text(
          resuming
              ? 'ပြန်စမ်းရန် $count ခု · လက်ရှိ lesson အရင်ဆက်မယ်'
              : 'ပြန်စမ်းရန် $count ခု · ဆက်သင်ရင်း လေ့ကျင့်မယ်',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
