import 'package:flutter/material.dart';

import '../services/app_state.dart';

class LearningDashboard extends StatelessWidget {
  const LearningDashboard({
    required this.appState,
    required this.onPractice,
    required this.onProgress,
    super.key,
  });
  final AppState appState;
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
      return Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ဒီနေ့ရဲ့ သင်ယူမှု',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '$today / $goal ခု လေ့ကျင့်ပြီး • ${progress.streak(now)} ရက် ဆက်တိုက်',
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: (today / goal).clamp(0.0, 1.0)),
              const SizedBox(height: 12),
              if (today >= goal) const Text('ဒီနေ့ရည်မှန်းချက် ပြည့်ပါပြီ။'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onPractice,
                    icon: const Icon(Icons.school),
                    label: const Text('လေ့ကျင့်မယ်'),
                  ),
                  TextButton.icon(
                    onPressed: onProgress,
                    icon: const Icon(Icons.insights),
                    label: const Text('မှတ်တမ်းကြည့်မယ်'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
