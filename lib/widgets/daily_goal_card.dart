import 'package:flutter/material.dart';
import '../services/app_state.dart';

class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({required this.appState, super.key});
  final AppState appState;
  Future<void> _chooseGoal(BuildContext context) async {
    final goal = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'နေ့စဉ်ပန်းတိုင်',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...[5, 10, 20].map(
                  (n) => ListTile(
                    title: Text('$n ကြိမ် / ရက်'),
                    trailing: n == appState.learning.dailyGoal
                        ? const Icon(Icons.check_circle_rounded)
                        : null,
                    onTap: () => Navigator.pop(context, n),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (goal != null) await appState.setDailyGoal(goal);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      final done = appState.learning.reviewsOn(DateTime.now());
      final goal = appState.learning.dailyGoal;
      final complete = done >= goal;
      final colors = Theme.of(context).colorScheme;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Semantics(
                label: 'ဒီနေ့ $done / $goal ကြိမ် လေ့ကျင့်ပြီး',
                child: SizedBox.square(
                  dimension: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 56,
                        child: CircularProgressIndicator(
                          value: (done / goal).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor: colors.surfaceContainerHighest,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Icon(
                        complete ? Icons.check_rounded : Icons.bolt_rounded,
                        color: colors.primary,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'ဒီနေ့ ပန်းတိုင်ပြည့်ပြီ!' : 'ဒီနေ့ ပန်းတိုင်',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '$done / $goal ကြိမ်',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'နေ့စဉ်ပန်းတိုင် ပြောင်းရန်',
                onPressed: () => _chooseGoal(context),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
        ),
      );
    },
  );
}
