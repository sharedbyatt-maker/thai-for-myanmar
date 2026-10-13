import 'package:flutter/material.dart';

import '../learning/study_catalog.dart';
import '../services/app_state.dart';

class LearningDashboard extends StatelessWidget {
  const LearningDashboard({
    required this.appState,
    required this.plan,
    required this.onPractice,
    required this.onProgress,
    super.key,
  });
  final AppState appState;
  final TodayStudyPlan plan;
  final VoidCallback onPractice;
  final VoidCallback onProgress;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      final progress = appState.learning;
      final now = DateTime.now();
      final today = progress.reviewsOn(now);
      final goal = progress.dailyGoal;
      final colors = Theme.of(context).colorScheme;
      return Card(
        color: colors.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ဒီနေ့ ၅ စကားစု',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                plan.phrases.isEmpty
                    ? 'လက်ရှိအတွက် လေ့ကျင့်စရာ မကျန်တော့ပါ။'
                    : '${plan.reviewCount} ခု ပြန်ကြည့် • ${plan.newCount} ခု အသစ်',
              ),
              const SizedBox(height: 8),
              Text(
                '$today / $goal ခု လေ့ကျင့်ပြီး • ${progress.streak(now)} ရက် ဆက်တိုက်',
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: (today / goal).clamp(0.0, 1.0)),
              const SizedBox(height: 12),
              if (today >= goal) const Text('ဒီနေ့ရည်မှန်းချက် ပြည့်ပါပြီ။'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: plan.phrases.isEmpty ? null : onPractice,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('အခု စလေ့ကျင့်မယ်'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onProgress,
                  icon: const Icon(Icons.insights_rounded),
                  label: const Text('သင်ယူမှုမှတ်တမ်း'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
