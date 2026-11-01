import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/course_catalog.dart';
import '../learning/course_progress.dart';
import '../learning/learner_rank.dart';
import '../learning/learning_progress.dart';
import '../services/app_state.dart';
import '../screens/learning_progress_screen.dart';
import 'daily_goal_card.dart';
import 'rank_card.dart';

void showLearningDetails(BuildContext context, Widget child) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

/// The same actual progress feeds the mobile strip, desktop rail and Profile.
class LearnStatsStrip extends StatelessWidget {
  const LearnStatsStrip({
    required this.repository,
    required this.appState,
    this.compact = true,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final p = appState.learning;
    final rank = LearnerRank(repository, p);
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.local_fire_department_rounded,
            value: '${p.streak(DateTime.now())}',
            label: 'ရက်ဆက်',
            color: Colors.deepOrange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => LearningProgressScreen(
                  repository: repository,
                  appState: appState,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _Metric(
            key: const ValueKey('learn-total-xp'),
            icon: Icons.bolt_rounded,
            value: '${rank.xp}',
            label: 'စုစုပေါင်း XP',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => showLearningDetails(
              context,
              RankCard(
                repository: repository,
                appState: appState,
                showBadges: true,
              ),
            ),
          ),
        ),
        Expanded(
          child: _Metric(
            key: const ValueKey('learn-today-goal'),
            icon: compact
                ? Icons.flag_rounded
                : Icons.workspace_premium_rounded,
            value: compact
                ? '${p.practiceOn(DateTime.now())}/${p.dailyGoal}'
                : '${rank.completed}',
            label: compact ? 'ဒီနေ့ ပန်းတိုင်' : 'သင်ခန်းစာပြီး',
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => showLearningDetails(
              context,
              compact
                  ? DailyGoalCard(appState: appState)
                  : RankCard(
                      repository: repository,
                      appState: appState,
                      showBadges: true,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String value, label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label $value',
    onTap: onTap,
    child: ExcludeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Color.lerp(color, Colors.white, .3)
                    : color,
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class LearnSupportRail extends StatelessWidget {
  const LearnSupportRail({
    required this.repository,
    required this.appState,
    required this.unit,
    required this.lesson,
    required this.continueLesson,
    required this.openReview,
    required this.openHistory,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final CourseUnit unit;
  final CourseLesson lesson;
  final void Function(BuildContext) continueLesson;
  final VoidCallback openReview, openHistory;
  @override
  Widget build(BuildContext context) {
    final p = appState.learning;
    final rank = LearnerRank(repository, p);
    final now = DateTime.now();
    final due = repository.phrases
        .where(
          (phrase) =>
              p.cardFor(phrase.id, LearningMode.flashcard)?.isDue(now) ?? false,
        )
        .length;
    final courseDue = p.course.memory.values.where((c) => c.isDue(now)).length;
    final completed = p.course.completed.containsKey(lesson.id);
    final colors = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('learn-support-rail'),
      padding: const EdgeInsets.fromLTRB(0, 12, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LearnStatsStrip(
              repository: repository,
              appState: appState,
              compact: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        DailyGoalCard(appState: appState),
        const SizedBox(height: 16),
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showLearningDetails(
              context,
              RankCard(
                repository: repository,
                appState: appState,
                showBadges: true,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ကိုယ်ပိုင် Rank',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${LearnerRank.symbols[rank.level]} ${rank.name}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: rank.fraction),
                  const SizedBox(height: 8),
                  Text(
                    rank.isMax
                        ? 'အမြင့်ဆုံး ကြိုးစားမှု Rank ရောက်ပါပြီ'
                        : 'နောက် Rank အတွက် ${rank.remaining} သင်ခန်းစာ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('learn-review-shortcut'),
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('စကားစု ပြန်လေ့ကျင့်မယ်'),
                subtitle: Text('ပြန်လေ့ကျင့်ရန် $due ခု'),
                trailing: const Icon(Icons.chevron_right),
                onTap: openReview,
              ),
              if (courseDue > 0)
                Builder(
                  builder: (anchor) => ListTile(
                    leading: const Icon(Icons.hearing_rounded),
                    title: Text('သင်ရိုး ပြန်လေ့ကျင့်ရန် $courseDue ခု'),
                    onTap: () => continueLesson(anchor),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: colors.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ဆက်သင်မယ့် သင်ခန်းစာ',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  lesson.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  completed
                      ? 'ပြန်လေ့ကျင့်မှု · +0 XP'
                      : 'ပထမဆုံးပြီးလျှင် +${CourseProgress.lessonXp} XP',
                ),
                const SizedBox(height: 14),
                Builder(
                  builder: (anchor) => FilledButton.icon(
                    key: const ValueKey('learn-next-lesson'),
                    onPressed: () => continueLesson(anchor),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('ဆက်သင်မယ်'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: openHistory,
          icon: const Icon(Icons.history_rounded),
          label: const Text('အရင်သင်ခန်းစာ မှတ်တမ်းများ'),
        ),
      ],
    );
  }
}
