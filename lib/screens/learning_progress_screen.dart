import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/learning_progress.dart';
import '../services/app_state.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({
    required this.repository,
    required this.appState,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('သင်ယူမှုမှတ်တမ်း')),
    body: AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final progress = appState.learning;
        final now = DateTime.now();
        final validIds = repository.phrases.map((p) => p.id).toSet();
        final reviewed = progress.reviewedPhraseIds.intersection(validIds);
        final accuracy = progress.totalReviews == 0
            ? 0
            : (100 * progress.correctReviews / progress.totalReviews).round();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${progress.streak(now)} ရက် ဆက်တိုက် လေ့ကျင့်ထားတယ်',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'လေ့ကျင့်ဖူးတဲ့ စကားစု ${reviewed.length} / ${validIds.length}',
            ),
            Text('ဖြေဆို / ကိုယ်တိုင်သတ်မှတ်ထားတဲ့ မှန်ကန်မှု $accuracy%'),
            Text(
              'ပြီးဆုံးတဲ့အကြိမ် ${progress.completedSessions} • သင်ခန်းစာ ${progress.completedLessons.length} ခု',
            ),
            const SizedBox(height: 24),
            Text(
              'နောက်ဆုံး ၇ ရက်',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...List.generate(7, (index) {
              final day = DateTime(now.year, now.month, now.day - 6 + index);
              final count = progress.reviewsOn(day);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(width: 65, child: Text('${day.day}/${day.month}')),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (count / progress.dailyGoal).clamp(0.0, 1.0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(width: 42, child: Text('$count ခု')),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Text(
              'အကြောင်းအရာအလိုက်',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ...repository.categories.map((category) {
              final phrases = repository.inCategory(category.id);
              final count = phrases
                  .where((p) => reviewed.contains(p.id))
                  .length;
              final due = phrases
                  .where(
                    (p) =>
                        progress.cardFor(p.id, LearningMode.meaning) != null &&
                        progress.isDue(p.id, LearningMode.meaning, now),
                  )
                  .length;
              return ListTile(
                leading: Text(category.icon),
                title: Text(category.my),
                subtitle: Text(
                  '$count / ${phrases.length} ခု လေ့ကျင့်ဖူး • $due ခု အဓိပ္ပာယ် ပြန်လေ့ကျင့်ရန်',
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'ကြည့်ဖူးခြင်း၊ လေ့ကျင့်ဖူးခြင်းနဲ့ တကယ်ကျွမ်းကျင်မှုက မတူပါ။ စာကတ်ရလဒ်က ကိုယ်တိုင်သတ်မှတ်ထားတဲ့ မှတ်မိမှုဖြစ်ပါတယ်။',
            ),
          ],
        );
      },
    ),
  );
}
