import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../learning/study_quests.dart';
import '../services/app_state.dart';
import '../widgets/playful_components.dart';

class QuestsScreen extends StatelessWidget {
  const QuestsScreen({
    required this.repository,
    required this.appState,
    this.onLearn,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final VoidCallback? onLearn;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      final quests = StudyQuests(repository, appState.learning, DateTime.now());
      final colors = Theme.of(context).colorScheme;
      return ListView(
        key: const ValueKey('quests-page'),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B43CB), Color(0xFF4740A0)],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ဒီလရဲ့ စိန်ခေါ်မှု',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElephantBuddy(size: 64),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ကျန်ချိန် ${quests.daysLeft} ရက်',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Icon(
                      quests.monthly.complete
                          ? Icons.workspace_premium_rounded
                          : Icons.shield_rounded,
                      color: const Color(0xFFFFD47A),
                      size: 68,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  quests.monthly.complete
                      ? 'ဒီလရဲ့ ဆုတံဆိပ် ရပါပြီ!'
                      : quests.monthly.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: quests.monthly.fraction,
                  minHeight: 10,
                  color: const Color(0xFFFFCD62),
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 8),
                Text(
                  '${quests.monthly.shown} / ${quests.monthly.target} ရက်',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'ဒီနေ့ရဲ့ ရည်မှန်းချက်',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...quests.daily.map((q) => _QuestCard(quest: q)),
          const SizedBox(height: 18),
          Text('ဒီအပတ်', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _QuestCard(quest: quests.weekly),
          if (quests.earnedMonths.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'ရရှိထားတဲ့ လစဉ်ဆုတံဆိပ်',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: quests.earnedMonths
                  .map(
                    (m) => Chip(
                      avatar: Icon(
                        Icons.workspace_premium_rounded,
                        color: colors.primary,
                      ),
                      label: Text(m),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (onLearn != null) ...[
            const SizedBox(height: 24),
            LiftButton(label: 'သင်ခန်းစာ ဆက်သင်မယ်', onPressed: onLearn),
          ],
        ],
      );
    },
  );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest});
  final StudyQuest quest;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final icon = switch (quest.id) {
      'xp' => Icons.bolt_rounded,
      'lesson' => Icons.menu_book_rounded,
      'week' => Icons.calendar_month_rounded,
      _ => Icons.track_changes_rounded,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                quest.complete ? Icons.check_rounded : icon,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: quest.fraction, minHeight: 8),
                  const SizedBox(height: 8),
                  Text(
                    quest.complete
                        ? 'ပြီးပါပြီ ✓'
                        : '${quest.shown} / ${quest.target}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
