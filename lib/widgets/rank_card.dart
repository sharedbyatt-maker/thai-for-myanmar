import 'package:flutter/material.dart';
import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../learning/learner_rank.dart';

class RankCard extends StatelessWidget {
  const RankCard({
    required this.repository,
    required this.appState,
    this.showBadges = false,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final bool showBadges;
  @override
  Widget build(BuildContext context) {
    final rank = LearnerRank(repository, appState.learning);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${LearnerRank.symbols[rank.level]} ${rank.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${rank.xp} XP • ${rank.completed} သင်ခန်းစာ ပြီး'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: rank.fraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'Rank တိုးတက်မှု',
            ),
            const SizedBox(height: 8),
            Text(
              rank.isMax
                  ? 'လမ်းကြောင်းတစ်ခုလုံး ပြီးပါပြီ 🎉'
                  : 'နောက် Rank အတွက် ${rank.remaining} သင်ခန်းစာ',
            ),
            if (showBadges) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  6,
                  (i) => Chip(
                    avatar: Icon(
                      i <= rank.level
                          ? Icons.verified_rounded
                          : Icons.lock_outline,
                      size: 18,
                    ),
                    label: Text(
                      '${LearnerRank.symbols[i]} ${LearnerRank.names[i]}',
                    ),
                    backgroundColor: i <= rank.level
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'သင်ခန်းစာအသစ်ပြီးလျှင် 20 XP။ မှတ်မိ / မှန်သော စကားစုတစ်ခု 5 XP၊ တစ်နေ့ 50 XP အထိ။ တူညီသောစကားစုကို တစ်နေ့တစ်ကြိမ်သာ ရေတွက်သည်။',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
