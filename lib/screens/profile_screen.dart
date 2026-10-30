import 'package:flutter/material.dart';

import '../data/phrase_repository.dart';
import '../services/app_state.dart';
import '../services/thai_playback_service.dart';
import '../widgets/playful_components.dart';
import '../widgets/daily_goal_card.dart';
import '../widgets/rank_card.dart';
import 'favorites_screen.dart';
import 'learning_progress_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.repository,
    required this.appState,
    required this.playbackService,
    super.key,
  });
  final PhraseRepository repository;
  final AppState appState;
  final ThaiPlaybackService playbackService;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: appState,
    builder: (context, _) {
      void open(Widget page) => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ElephantBuddy(size: 120)),
          const SizedBox(height: 12),
          Text(
            appState.learning.totalReviews == 0
                ? 'ဒီနေ့ကနေ စလိုက်ပါ'
                : 'နေ့တိုင်း နည်းနည်း ပိုတတ်လာပြီ',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MetricPill(
                  icon: Icons.local_fire_department,
                  label: '${appState.learning.streak(DateTime.now())} ရက်ဆက်',
                ),
                MetricPill(
                  icon: Icons.check_circle,
                  label: '${appState.learning.totalReviews} ကြိမ် လေ့ကျင့်ပြီး',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RankCard(
            repository: repository,
            appState: appState,
            showBadges: true,
          ),
          const SizedBox(height: 16),
          DailyGoalCard(appState: appState),
          const SizedBox(height: 20),
          Text(
            'နောက်ဆုံး ၇ ရက်',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              spacing: 6,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final now = DateTime.now();
                final day = DateTime(now.year, now.month, now.day - 6 + i);
                final count = appState.learning.reviewsOn(day);
                return SizedBox(
                  width: ((box.maxWidth - 36) / 7).clamp(38, 80),
                  child: Semantics(
                    label: '${day.day}/${day.month} · $count ကြိမ်',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            count > 0
                                ? Icons.check_rounded
                                : Icons.remove_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${day.day}',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 26),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite_rounded),
                  title: const Text('သိမ်းထားတာ'),
                  trailing: Text('${appState.favorites.length}'),
                  onTap: () => open(
                    FavoritesScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.insights_rounded),
                  title: const Text('သင်ယူမှုမှတ်တမ်း'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(
                    LearningProgressScreen(
                      repository: repository,
                      appState: appState,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('ဆက်တင်များ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(
                    SettingsScreen(
                      repository: repository,
                      appState: appState,
                      playbackService: playbackService,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'အကောင့်မလိုပါ။ တိုးတက်မှုကို ဒီစက်မှာ သိမ်းထားပါတယ်။',
            textAlign: TextAlign.center,
          ),
        ],
      );
    },
  );
}
